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
        // showing "Copy Link". Passing `existingShare` (which may be nil) lets
        // NSPersistentCloudKitContainer re-save a broken share rather than duplicate it.
        let controller = UICloudSharingController { [ckContainer] _, preparationCompletionHandler in
            Task {
                do {
                    let (_, share, _) = try await persistentContainer.share(
                        [caregiver], to: existingShare
                    )
                    share[CKShare.SystemFieldKey.title] = "AryaLog Baby Care" as CKRecordValue
                    await MainActor.run {
                        preparationCompletionHandler(share, ckContainer, nil)
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
