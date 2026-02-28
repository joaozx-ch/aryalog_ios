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
class ShareController: NSObject, ObservableObject {
    static let shared = ShareController()

    private let ckContainer = CKContainer(identifier: "iCloud.com.AryaLog.AryaLog")

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

    /// Returns a configured UICloudSharingController for the given caregiver.
    /// If the caregiver is already shared it returns a management controller; otherwise
    /// it returns a new-share controller that creates the share on demand.
    func makeSharingController(
        for caregiver: Caregiver,
        onDone: @escaping () -> Void
    ) -> UICloudSharingController {
        let persistentContainer = PersistenceController.shared.container

        // Reuse existing share if one already exists for this caregiver.
        if let existingShare = (try? persistentContainer.fetchShares(
            matching: [caregiver.objectID]
        ))?[caregiver.objectID] {
            let controller = UICloudSharingController(
                share: existingShare,
                container: ckContainer
            )
            controller.availablePermissions = [.allowReadWrite, .allowPrivate]
            controller.delegate = Delegate(onDone: onDone)
            return controller
        }

        // Create a new share via the preparation handler.
        let controller = UICloudSharingController { [weak self] _, completion in
            guard self != nil else { return }
            Task {
                do {
                    let (_, share, container) = try await persistentContainer.share(
                        [caregiver],
                        to: nil
                    )
                    share[CKShare.SystemFieldKey.title] = "AryaLog Baby Care" as CKRecordValue
                    completion(share, container, nil)
                } catch {
                    print("Failed to create CloudKit share: \(error)")
                    completion(nil, nil, error)
                }
            }
        }
        controller.availablePermissions = [.allowReadWrite, .allowPrivate]
        controller.delegate = Delegate(onDone: onDone)
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
