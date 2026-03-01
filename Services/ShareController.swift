//
//  ShareController.swift
//  AryaLog
//
//  Builds and manages UICloudSharingController instances for cross-account CloudKit sharing.
//

import Foundation
import CloudKit
import CoreData
import UIKit

/// Provides UICloudSharingController instances ready to present in a SwiftUI sheet.
class ShareController: NSObject {
    static let shared = ShareController()

    private let ckContainer = CKContainer(identifier: "iCloud.com.AryaLog.AryaLog")

    /// Retains the delegate for the lifetime of the active sharing session,
    /// because UICloudSharingController.delegate is weak.
    private var activeDelegate: Delegate?

    // MARK: - Account Status

    func checkAccountStatus() async -> CKAccountStatus {
        do {
            return try await ckContainer.accountStatus()
        } catch {
            print("Failed to check account status: \(error)")
            return .couldNotDetermine
        }
    }

    // MARK: - Building the Sharing Controller

    /// Returns a UICloudSharingController for the given caregiver.
    ///
    /// - For an **existing share** (the caregiver's record already has a CKShare in CloudKit),
    ///   uses `init(share:container:)` — the share has a server-assigned URL, so this is correct.
    /// - For a **new share**, uses `init(preparationHandler:)` so UIKit triggers the CloudKit
    ///   save inside the controller and waits for the server-assigned URL before displaying
    ///   "Copy Link". This is the only correct approach when using NSPersistentCloudKitContainer,
    ///   because `share(_:to:)` returns a CKShare before CloudKit responds with a URL, making
    ///   `init(share:container:)` unusable for freshly created shares (it would produce an empty link).
    ///   `init(preparationHandler:)` is deprecated in iOS 16 but has no non-deprecated equivalent
    ///   for this use case; it remains fully functional.
    func makeSharingController(
        for caregiver: Caregiver,
        onDone: @escaping (Error?) -> Void
    ) async throws -> UICloudSharingController {
        // Verify iCloud is available before doing any CloudKit work.
        let accountStatus = try await ckContainer.accountStatus()
        guard accountStatus == .available else {
            throw SharingError.iCloudUnavailable(accountStatus)
        }

        let persistentContainer = PersistenceController.shared.container

        let delegate = Delegate(
            onDone: { [weak self] in
                self?.activeDelegate = nil
                onDone(nil)
            },
            onError: { [weak self] error in
                self?.activeDelegate = nil
                onDone(error)
            }
        )
        activeDelegate = delegate

        // PATH A: Existing share that already has a server-assigned URL — use the
        // non-deprecated init. Guard on url != nil: a previous failed attempt may have
        // left a CKShare in Core Data with no URL, which would produce an empty link.
        let existingShare = (try? persistentContainer.fetchShares(
            matching: [caregiver.objectID]
        ))?[caregiver.objectID]

        if let existingShare, existingShare.url != nil {
            let controller = UICloudSharingController(share: existingShare, container: ckContainer)
            controller.availablePermissions = [.allowReadWrite, .allowPrivate]
            controller.delegate = delegate
            return controller
        }

        // PATH B: New share, or an existing share whose URL is still nil — use the
        // preparation handler so UIKit waits for CloudKit to assign the URL before
        // showing "Copy Link".
        //
        // IMPORTANT: If a previous share attempt left a local CKShare with url == nil,
        // calling share(_:to:nil) again would throw because Apple's API forbids passing
        // objects that are already associated with a share alongside a nil share parameter.
        // In that case we skip share(_:to:) and save the existing CKShare directly to
        // CloudKit to obtain the server-assigned URL.
        let controller = UICloudSharingController { [ckContainer, existingShare] _, preparationCompletionHandler in
            Task {
                do {
                    let shareToSave: CKShare
                    if let existingShare {
                        // The caregiver already has a local CKShare (url == nil from a
                        // previous failed attempt). Calling share(_:to:nil) again would
                        // fail. Save the existing share record directly to CloudKit instead.
                        existingShare[CKShare.SystemFieldKey.title] = "AryaLog Baby Care" as CKRecordValue
                        shareToSave = existingShare
                    } else {
                        // No existing share — create a fresh one.
                        // NSPersistentCloudKitContainer.share(_:to:) creates the CKShare
                        // locally and schedules a background CloudKit sync, but returns
                        // before the server responds — so share.url is nil here. We save
                        // directly to CloudKit to force a round-trip and get the URL.
                        let (_, newShare, _) = try await persistentContainer.share(
                            [caregiver], to: nil
                        )
                        newShare[CKShare.SystemFieldKey.title] = "AryaLog Baby Care" as CKRecordValue
                        shareToSave = newShare
                    }

                    let savedRecord = try await ckContainer.privateCloudDatabase.save(shareToSave)
                    let shareWithURL = (savedRecord as? CKShare) ?? shareToSave

                    await MainActor.run {
                        preparationCompletionHandler(shareWithURL, ckContainer, nil)
                    }
                } catch let ckError as CKError where ckError.code == .serverRecordChanged {
                    // The background CloudKit sync raced the explicit save and already
                    // pushed the share. Use the server record, which has the URL.
                    if let serverRecord = ckError.serverRecord as? CKShare, serverRecord.url != nil {
                        await MainActor.run {
                            preparationCompletionHandler(serverRecord, ckContainer, nil)
                        }
                    } else {
                        print("Share preparation failed (serverRecordChanged, no URL): \(ckError)")
                        await MainActor.run {
                            preparationCompletionHandler(nil, ckContainer, ckError)
                        }
                    }
                } catch {
                    print("Share preparation failed: \(error)")
                    await MainActor.run {
                        preparationCompletionHandler(nil, ckContainer, error)
                    }
                }
            }
        }
        controller.availablePermissions = [.allowReadWrite, .allowPrivate]
        controller.delegate = delegate
        return controller
    }

    // MARK: - Errors

    enum SharingError: LocalizedError {
        case iCloudUnavailable(CKAccountStatus)

        var errorDescription: String? {
            switch self {
            case .iCloudUnavailable(let status):
                switch status {
                case .noAccount:
                    return "No iCloud account is signed in. Go to Settings → [your name] and sign in to iCloud, then try again."
                case .restricted:
                    return "iCloud access is restricted on this device (e.g. by Screen Time or MDM). Sharing requires an active iCloud account."
                case .temporarilyUnavailable:
                    return "iCloud is temporarily unavailable. Please try again in a moment."
                default:
                    return "iCloud is not available (status \(status.rawValue)). Please check your iCloud settings and try again."
                }
            }
        }
    }

    // MARK: - Delegate

    /// Thin UICloudSharingControllerDelegate that calls back when the user is done.
    class Delegate: NSObject, UICloudSharingControllerDelegate {
        private let onDone: () -> Void
        private let onError: (Error) -> Void

        init(onDone: @escaping () -> Void, onError: @escaping (Error) -> Void) {
            self.onDone = onDone
            self.onError = onError
        }

        func itemTitle(for csc: UICloudSharingController) -> String? {
            "AryaLog Baby Care"
        }

        func cloudSharingController(
            _ csc: UICloudSharingController,
            failedToSaveShareWithError error: Error
        ) {
            print("Failed to save share: \(error)")
            onError(error)
        }

        func cloudSharingControllerDidSaveShare(_ csc: UICloudSharingController) {
            onDone()
        }

        func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) {
            onDone()
        }
    }
}
