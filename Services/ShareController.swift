//
//  ShareController.swift
//  AryaLog
//
//  CloudKit sharing logic for multi-caregiver support
//

import Foundation
import CloudKit
import Combine
import CoreData
import UIKit

class ShareController: ObservableObject {
    static let shared = ShareController()

    private let container: CKContainer
    private let privateDatabase: CKDatabase

    @Published var isSharing = false
    @Published var shareError: Error?

    init() {
        container = CKContainer(identifier: "iCloud.com.AryaLog.AryaLog")
        privateDatabase = container.privateCloudDatabase
    }

    // MARK: - Account Status

    func checkAccountStatus() async -> CKAccountStatus {
        do {
            return try await container.accountStatus()
        } catch {
            print("Failed to check account status: \(error)")
            return .couldNotDetermine
        }
    }

    // MARK: - Creating a Share

    /// Creates a CKShare for sharing data with other caregivers
    /// Note: This requires the Core Data objects to be configured with NSPersistentCloudKitContainer
    func createShare(for persistentStore: NSPersistentStore, in container: NSPersistentCloudKitContainer) async throws -> CKShare {
        // Create a share for the persistent store
        let (_, share, _) = try await container.share([], to: nil)

        // Configure share permissions
        share[CKShare.SystemFieldKey.title] = "AryaLog Shared Data" as CKRecordValue
        share.publicPermission = CKShare.ParticipantPermission.none

        return share
    }

    // MARK: - Sharing UI

    /// Presents the CloudKit sharing controller
    func presentShareController(share: CKShare, from viewController: UIViewController) {
        let sharingController = UICloudSharingController(share: share, container: container)
        sharingController.availablePermissions = [.allowReadWrite, .allowPrivate]
        sharingController.delegate = ShareControllerDelegate.shared

        viewController.present(sharingController, animated: true)
    }

    // MARK: - Accepting Shares

    /// Handles an incoming share URL
    func acceptShare(from url: URL) async throws {
        let metadata = try await container.shareMetadata(for: url)
        try await container.accept(metadata)
    }

    // MARK: - Fetching Shares

    /// Fetches all active shares
    func fetchShares() async throws -> [CKShare] {
        let zone = CKRecordZone(zoneName: "com.apple.coredata.cloudkit.zone")

        let query = CKQuery(recordType: "cloudkit.share", predicate: NSPredicate(value: true))

        let (results, _) = try await privateDatabase.records(
            matching: query,
            inZoneWith: zone.zoneID
        )

        return results.compactMap { result in
            switch result.1 {
            case .success(let record):
                return record as? CKShare
            case .failure:
                return nil
            }
        }
    }

    // MARK: - Managing Participants

    /// Fetches participants for a share
    func fetchParticipants(for share: CKShare) -> [CKShare.Participant] {
        return share.participants
    }

    /// Removes a participant from a share
    func removeParticipant(_ participant: CKShare.Participant, from share: CKShare) async throws {
        share.removeParticipant(participant)

        try await privateDatabase.save(share)
    }
}

// MARK: - UICloudSharingControllerDelegate

class ShareControllerDelegate: NSObject, UICloudSharingControllerDelegate {
    static let shared = ShareControllerDelegate()

    func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
        print("Failed to save share: \(error)")
    }

    func itemTitle(for csc: UICloudSharingController) -> String? {
        return "AryaLog Feeding Data"
    }

    func itemThumbnailData(for csc: UICloudSharingController) -> Data? {
        // Return thumbnail data if desired
        return nil
    }

    func cloudSharingControllerDidSaveShare(_ csc: UICloudSharingController) {
        print("Share saved successfully")
    }

    func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) {
        print("Sharing stopped")
    }
}

// MARK: - Share URL Handler

extension ShareController {
    /// Call this from SceneDelegate or AppDelegate when the app receives a share URL
    static func handleIncomingShare(url: URL) {
        Task {
            do {
                try await ShareController.shared.acceptShare(from: url)
                print("Successfully accepted share")
            } catch {
                print("Failed to accept share: \(error)")
            }
        }
    }
}
