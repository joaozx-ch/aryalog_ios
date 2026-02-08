//
//  HomeViewModel.swift
//  AryaLog
//
//  ViewModel for the Home screen
//

import Foundation
import CoreData
import Combine

@MainActor
class HomeViewModel: ObservableObject {
    @Published var recentLogs: [FeedingLog] = []
    @Published var todayBreastfeedingMinutes: Int = 0
    @Published var todayFormulaML: Int = 0
    @Published var lastFeedingTime: Date?

    private let viewContext: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.viewContext = context
        refresh()
    }

    func refresh() {
        recentLogs = FeedingLog.fetchRecent(limit: 5, in: viewContext)
        todayBreastfeedingMinutes = FeedingLog.totalBreastfeedingMinutes(for: Date(), in: viewContext)
        todayFormulaML = FeedingLog.totalFormulaML(for: Date(), in: viewContext)
        lastFeedingTime = recentLogs.first?.wrappedStartTime
    }

    var timeSinceLastFeeding: String {
        guard let lastTime = lastFeedingTime else {
            return "No feedings yet"
        }

        let interval = Date().timeIntervalSince(lastTime)
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m ago"
        } else {
            return "\(minutes)m ago"
        }
    }

    func getCurrentCaregiver() -> Caregiver? {
        return Caregiver.fetchCurrentUser(in: viewContext)
    }
}
