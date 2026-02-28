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
        onDone: @escaping () -> Void
    ) async throws -> UICloudSharingController {
        // Verify iCloud is available before doing any CloudKit work.
        let accountStatus = try await ckContainer.accountStatus()
        guard accountStatus == .available else {
            throw SharingError.iCloudUnavailable(accountStatus)
        }

        let persistentContainer = PersistenceController.shared.container

        let delegate = Delegate(onDone: { [weak self] in
            self?.activeDelegate = nil
            onDone()
        })
        activeDelegate = delegate

        // PATH A: Existing share — already has a server-assigned URL.
        if let existingShare = (try? persistentContainer.fetchShares(
            matching: [caregiver.objectID]
        ))?[caregiver.objectID] {
            let controller = UICloudSharingController(share: existingShare, container: ckContainer)
            controller.availablePermissions = [.allowReadWrite, .allowPrivate]
            controller.delegate = delegate
            return controller
        }

        // PATH B: New share — use the preparation handler so UIKit waits for the URL.
        let controller = UICloudSharingController { [ckContainer] preparationCompletionHandler in
            Task {
                do {
                    let (_, newShare, _) = try await persistentContainer.share(
                        [caregiver], to: nil
                    )
                    newShare[CKShare.SystemFieldKey.title] = "AryaLog Baby Care" as CKRecordValue
                    await MainActor.run {
                        preparationCompletionHandler(newShare, ckContainer, nil)
                    }
                } catch {
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

        init(onDone: @escaping () -> Void) {
            self.onDone = onDone
        }

        func itemTitle(for csc: UICloudSharingController) -> String? {
            "AryaLog Baby Care"
        }

        func cloudSharingController(
            _ csc: UICloudSharingController,
            failedToSaveShareWithError error: Error
        ) {
            print("Failed to save share: \(error)")
            onDone()
        }

        func cloudSharingControllerDidSaveShare(_ csc: UICloudSharingController) {
            onDone()
        }

        func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) {
            onDone()
        }
    }
}
