//
//  PersistenceController.swift
//  AryaLog
//
//  Core Data + CloudKit stack with shared-database support
//

import CoreData
import CloudKit

struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext

        // Create sample caregiver
        let caregiver = Caregiver(context: viewContext)
        caregiver.id = UUID()
        caregiver.name = "Preview User"
        caregiver.isCurrentUser = true
        caregiver.createdAt = Date()

        // Create sample feeding logs
        for i in 0..<5 {
            let log = FeedingLog(context: viewContext)
            log.id = UUID()
            log.activityType = i % 2 == 0 ? ActivityType.breastfeeding.rawValue : ActivityType.formula.rawValue
            log.startTime = Calendar.current.date(byAdding: .hour, value: -i * 3, to: Date())
            log.leftDuration = i % 2 == 0 ? Int16.random(in: 5...15) : 0
            log.rightDuration = i % 2 == 0 ? Int16.random(in: 5...15) : 0
            log.volumeML = i % 2 == 0 ? 0 : Int16.random(in: 60...180)
            log.createdAt = Date()
            log.caregiver = caregiver
        }

        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentCloudKitContainer

    // MARK: - Init

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "AryaLog")

        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        } else {
            let storeDirectory = NSPersistentContainer.defaultDirectoryURL()

            // Private store — your own data, synced via the private CloudKit database
            let privateStoreURL = storeDirectory.appendingPathComponent("AryaLog.sqlite")
            let privateDescription = NSPersistentStoreDescription(url: privateStoreURL)
            let privateOptions = NSPersistentCloudKitContainerOptions(
                containerIdentifier: "iCloud.com.AryaLog.AryaLog"
            )
            // privateOptions.databaseScope defaults to .private — no change needed
            privateDescription.cloudKitContainerOptions = privateOptions
            privateDescription.setOption(
                true as NSNumber,
                forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey
            )
            privateDescription.setOption(
                true as NSNumber,
                forKey: NSPersistentHistoryTrackingKey
            )

            // Shared store — data shared to you by other iCloud accounts
            let sharedStoreURL = storeDirectory.appendingPathComponent("AryaLogShared.sqlite")
            let sharedDescription = NSPersistentStoreDescription(url: sharedStoreURL)
            let sharedOptions = NSPersistentCloudKitContainerOptions(
                containerIdentifier: "iCloud.com.AryaLog.AryaLog"
            )
            sharedOptions.databaseScope = .shared
            sharedDescription.cloudKitContainerOptions = sharedOptions
            sharedDescription.setOption(
                true as NSNumber,
                forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey
            )
            sharedDescription.setOption(
                true as NSNumber,
                forKey: NSPersistentHistoryTrackingKey
            )

            container.persistentStoreDescriptions = [privateDescription, sharedDescription]
        }

        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        do {
            try container.viewContext.setQueryGenerationFrom(.current)
        } catch {
            fatalError("Failed to pin viewContext to the current generation: \(error)")
        }
    }

    // MARK: - Shared Store Reference

    /// The persistent store that receives data shared by other iCloud accounts.
    var sharedPersistentStore: NSPersistentStore? {
        container.persistentStoreCoordinator.persistentStores.first {
            $0.url?.lastPathComponent == "AryaLogShared.sqlite"
        }
    }

    // MARK: - Saving

    func save() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                print("Unresolved error saving context: \(nsError), \(nsError.userInfo)")
            }
        }
    }

    // MARK: - Sharing Helpers

    /// Returns true if the object has been shared (has an active CKShare).
    func isShared(object: NSManagedObject) -> Bool {
        (try? container.fetchShares(matching: [object.objectID]))?[object.objectID] != nil
    }

    /// Returns the existing CKShare for an object, or nil if not shared.
    func share(for object: NSManagedObject) -> CKShare? {
        (try? container.fetchShares(matching: [object.objectID]))?[object.objectID]
    }

    /// Returns true if the current user is the owner of the share, or the object is unshared.
    func isOwner(of object: NSManagedObject) -> Bool {
        guard let share = share(for: object) else { return true }
        return share.currentUserParticipant?.role == .owner
    }

    /// Accepts incoming share invitations and stores them in the shared persistent store.
    func acceptShareInvitations(from metadata: [CKShareMetadata]) {
        guard let sharedStore = sharedPersistentStore else {
            print("Shared persistent store not available — cannot accept share.")
            return
        }
        container.acceptShareInvitations(from: metadata, into: sharedStore) { _, error in
            if let error = error {
                print("Failed to accept share invitation: \(error)")
            }
        }
    }
}
