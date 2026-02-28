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

    /// Creates or fetches the CKShare for the caregiver, then returns a ready-to-present
    /// UICloudSharingController using the non-deprecated `init(share:container:)`.
    func makeSharingController(
        for caregiver: Caregiver,
        onDone: @escaping () -> Void
    ) async throws -> UICloudSharingController {
        let persistentContainer = PersistenceController.shared.container

        // Fetch an existing share, or create a new one.
        let share: CKShare
        if let existingShare = (try? persistentContainer.fetchShares(
            matching: [caregiver.objectID]
        ))?[caregiver.objectID] {
            share = existingShare
        } else {
            let (_, newShare, _) = try await persistentContainer.share([caregiver], to: nil)
            newShare[CKShare.SystemFieldKey.title] = "AryaLog Baby Care" as CKRecordValue
            share = newShare
        }

        let delegate = Delegate(onDone: { [weak self] in
            self?.activeDelegate = nil
            onDone()
        })
        activeDelegate = delegate

        let controller = UICloudSharingController(share: share, container: ckContainer)
        controller.availablePermissions = [.allowReadWrite, .allowPrivate]
        controller.delegate = delegate
        return controller
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
