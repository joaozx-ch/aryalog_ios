//
//  FeedingLog+CoreData.swift
//  AryaLog
//
//  FeedingLog entity helpers
//

import Foundation
import CoreData

extension FeedingLog {

    // MARK: - Convenience Properties

    var wrappedActivityType: ActivityType {
        ActivityType(rawValue: activityType ?? "") ?? .breastfeeding
    }

    var wrappedStartTime: Date {
        startTime ?? Date()
    }

    var wrappedCreatedAt: Date {
        createdAt ?? Date()
    }

    var wrappedNotes: String {
        notes ?? ""
    }

    var totalDuration: Int16 {
        leftDuration + rightDuration
    }

    var formattedDuration: String {
        let total = Int(totalDuration)
        if total >= 60 {
            let hours = total / 60
            let minutes = total % 60
            return "\(hours)h \(minutes)m"
        }
        return "\(total)m"
    }

    var formattedVolume: String {
        "\(volumeML) mL"
    }

    var summary: String {
        switch wrappedActivityType {
        case .breastfeeding:
            var parts: [String] = []
            if leftDuration > 0 {
                parts.append("L: \(leftDuration)m")
            }
            if rightDuration > 0 {
                parts.append("R: \(rightDuration)m")
            }
            return parts.isEmpty ? "No duration" : parts.joined(separator: ", ")
        case .formula:
            return formattedVolume
        case .sleep:
            return wrappedNotes.isEmpty ? "Fell asleep" : wrappedNotes
        case .wakeUp:
            return wrappedNotes.isEmpty ? "Woke up" : wrappedNotes
        case .pee:
            return wrappedNotes.isEmpty ? "Pee" : wrappedNotes
        case .poop:
            return wrappedNotes.isEmpty ? "Poop" : wrappedNotes
        }
    }

    // MARK: - Fetch Requests

    static func fetchAll(in context: NSManagedObjectContext) -> [FeedingLog] {
        let request: NSFetchRequest<FeedingLog> = FeedingLog.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \FeedingLog.startTime, ascending: false)]

        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch feeding logs: \(error)")
            return []
        }
    }

    static func fetchForDate(_ date: Date, in context: NSManagedObjectContext) -> [FeedingLog] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let request: NSFetchRequest<FeedingLog> = FeedingLog.fetchRequest()
        request.predicate = NSPredicate(format: "startTime >= %@ AND startTime < %@", startOfDay as NSDate, endOfDay as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \FeedingLog.startTime, ascending: false)]

        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch feeding logs for date: \(error)")
            return []
        }
    }

    static func fetchRecent(limit: Int = 10, in context: NSManagedObjectContext) -> [FeedingLog] {
        let request: NSFetchRequest<FeedingLog> = FeedingLog.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \FeedingLog.startTime, ascending: false)]
        request.fetchLimit = limit

        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch recent feeding logs: \(error)")
            return []
        }
    }

    static func fetchForDateRange(from startDate: Date, to endDate: Date, in context: NSManagedObjectContext) -> [FeedingLog] {
        let request: NSFetchRequest<FeedingLog> = FeedingLog.fetchRequest()
        request.predicate = NSPredicate(format: "startTime >= %@ AND startTime <= %@", startDate as NSDate, endDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \FeedingLog.startTime, ascending: false)]

        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch feeding logs for date range: \(error)")
            return []
        }
    }

    // MARK: - Statistics

    static func totalBreastfeedingMinutes(for date: Date, in context: NSManagedObjectContext) -> Int {
        let logs = fetchForDate(date, in: context)
        return logs
            .filter { $0.wrappedActivityType == .breastfeeding }
            .reduce(0) { $0 + Int($1.totalDuration) }
    }

    static func totalFormulaML(for date: Date, in context: NSManagedObjectContext) -> Int {
        let logs = fetchForDate(date, in: context)
        return logs
            .filter { $0.wrappedActivityType == .formula }
            .reduce(0) { $0 + Int($1.volumeML) }
    }

    static func countForType(_ type: ActivityType, for date: Date, in context: NSManagedObjectContext) -> Int {
        let logs = fetchForDate(date, in: context)
        return logs.filter { $0.wrappedActivityType == type }.count
    }
}
