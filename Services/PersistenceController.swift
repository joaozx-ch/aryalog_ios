//
//  PersistenceController.swift
//  AryaLog
//
//  Core Data + CloudKit stack
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

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "AryaLog")

        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        } else {
            // Configure CloudKit
            guard let description = container.persistentStoreDescriptions.first else {
                fatalError("Failed to retrieve a persistent store description.")
            }

            // Enable CloudKit sync
            description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
                containerIdentifier: "iCloud.com.AryaLog.AryaLog"
            )

            // Enable remote change notifications
            description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

            // Enable persistent history tracking
            description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        }

        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        // Pin the viewContext to the current generation token
        do {
            try container.viewContext.setQueryGenerationFrom(.current)
        } catch {
            fatalError("Failed to pin viewContext to the current generation: \(error)")
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
}
