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
    @Published var todaySleepCount: Int = 0
    @Published var todayDiaperCount: Int = 0
    @Published var lastLogTime: Date?

    private let viewContext: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.viewContext = context
        refresh()
    }

    func refresh() {
        let today = Date()
        recentLogs = FeedingLog.fetchRecent(limit: 5, in: viewContext)
        todayBreastfeedingMinutes = FeedingLog.totalBreastfeedingMinutes(for: today, in: viewContext)
        todayFormulaML = FeedingLog.totalFormulaML(for: today, in: viewContext)
        todaySleepCount = FeedingLog.countForType(.sleep, for: today, in: viewContext)
        todayDiaperCount = FeedingLog.countForType(.pee, for: today, in: viewContext)
            + FeedingLog.countForType(.poop, for: today, in: viewContext)
        lastLogTime = recentLogs.first?.wrappedStartTime
    }

    var timeSinceLastLog: String {
        guard let lastTime = lastLogTime else {
            return String(localized: "No logs yet")
        }

        let interval = Date().timeIntervalSince(lastTime)
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60

        if hours > 0 {
            return String(localized: "\(hours)h \(minutes)m ago")
        } else {
            return String(localized: "\(minutes)m ago")
        }
    }

    func getCurrentCaregiver() -> Caregiver? {
        return Caregiver.fetchCurrentUser(in: viewContext)
    }
}
