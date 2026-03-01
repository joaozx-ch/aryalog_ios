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
    /// All CloudKit work (share creation + server save to obtain the URL) is done
    /// here before the controller is returned. This replaces the old approach of
    /// using `init(preparationHandler:)`, which deferred the work until the user
    /// tapped a share destination inside Messages — with no timeout — causing the
    /// share link to spin indefinitely.
    ///
    /// Once the share has a server-assigned URL we use `init(share:container:)`,
    /// the non-deprecated initialiser, which works reliably with Messages.
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

        // Do all CloudKit work upfront — the caller already shows a loading spinner.
        let share = try await resolveShare(for: caregiver, in: persistentContainer)

        let controller = UICloudSharingController(share: share, container: ckContainer)
        controller.availablePermissions = [.allowReadWrite, .allowPrivate]
        controller.delegate = delegate
        return controller
    }

    // MARK: - Share Resolution

    /// Ensures the caregiver's CKShare exists in CloudKit and carries a server-assigned URL.
    ///
    /// Three cases are handled:
    ///
    /// **Case 1 — share with URL already exists:**
    /// Return it directly; nothing more to do.
    ///
    /// **Case 2 — share exists locally but URL is nil:**
    /// A previous attempt created the CKShare locally but failed before CloudKit
    /// responded. Calling `share(_:to:nil)` again would throw because the objects
    /// are already associated with a share. Instead, save the existing CKShare
    /// directly to CloudKit to obtain the URL.
    ///
    /// **Case 3 — no share exists:**
    /// Create a fresh share via `share(_:to:nil)`, then save it to CloudKit.
    private func resolveShare(
        for caregiver: Caregiver,
        in persistentContainer: NSPersistentCloudKitContainer
    ) async throws -> CKShare {
        let existingShare = (try? persistentContainer.fetchShares(
            matching: [caregiver.objectID]
        ))?[caregiver.objectID]

        // Case 1: ready to use immediately.
        if let existingShare, existingShare.url != nil {
            return existingShare
        }

        // Cases 2 & 3: build the CKShare record that needs pushing.
        let shareToSave: CKShare
        if let existingShare {
            // Case 2: reuse the existing local record.
            existingShare[CKShare.SystemFieldKey.title] = "AryaLog Baby Care" as CKRecordValue
            shareToSave = existingShare
        } else {
            // Case 3: ask NSPersistentCloudKitContainer to create a fresh share.
            // The returned CKShare is local-only at this point (url == nil);
            // the server assigns the URL after the save below.
            let (_, newShare, _) = try await persistentContainer.share([caregiver], to: nil)
            newShare[CKShare.SystemFieldKey.title] = "AryaLog Baby Care" as CKRecordValue
            shareToSave = newShare
        }

        // Push to CloudKit to get the server-assigned URL.
        do {
            let savedRecord = try await ckContainer.privateCloudDatabase.save(shareToSave)
            guard let savedShare = savedRecord as? CKShare, savedShare.url != nil else {
                throw SharingError.noShareURL
            }
            return savedShare
        } catch let ckError as CKError where ckError.code == .serverRecordChanged {
            // The background CloudKit sync beat our explicit save.
            // The server record has the authoritative URL.
            if let serverRecord = ckError.serverRecord as? CKShare, serverRecord.url != nil {
                return serverRecord
            }
            throw ckError
        }
    }

    // MARK: - Errors

    enum SharingError: LocalizedError {
        case iCloudUnavailable(CKAccountStatus)
        case noShareURL

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
            case .noShareURL:
                return "Failed to generate a sharing link. Please try again."
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
