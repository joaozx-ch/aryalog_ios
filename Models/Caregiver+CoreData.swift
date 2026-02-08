//
//  Caregiver+CoreData.swift
//  AryaLog
//
//  Caregiver entity helpers
//

import Foundation
import CoreData

extension Caregiver {

    // MARK: - Convenience Properties

    var wrappedName: String {
        name ?? "Unknown"
    }

    var wrappedCreatedAt: Date {
        createdAt ?? Date()
    }

    var feedingLogsArray: [FeedingLog] {
        let set = feedingLogs as? Set<FeedingLog> ?? []
        return set.sorted { ($0.startTime ?? Date()) > ($1.startTime ?? Date()) }
    }

    // MARK: - Fetch Requests

    static func fetchCurrentUser(in context: NSManagedObjectContext) -> Caregiver? {
        let request: NSFetchRequest<Caregiver> = Caregiver.fetchRequest()
        request.predicate = NSPredicate(format: "isCurrentUser == YES")
        request.fetchLimit = 1

        do {
            let results = try context.fetch(request)
            return results.first
        } catch {
            print("Failed to fetch current user: \(error)")
            return nil
        }
    }

    static func fetchAll(in context: NSManagedObjectContext) -> [Caregiver] {
        let request: NSFetchRequest<Caregiver> = Caregiver.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Caregiver.createdAt, ascending: true)]

        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch caregivers: \(error)")
            return []
        }
    }

    static func findByID(_ id: UUID, in context: NSManagedObjectContext) -> Caregiver? {
        let request: NSFetchRequest<Caregiver> = Caregiver.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1

        do {
            let results = try context.fetch(request)
            return results.first
        } catch {
            print("Failed to find caregiver by ID: \(error)")
            return nil
        }
    }
}
