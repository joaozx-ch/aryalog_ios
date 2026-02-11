//
//  StatsViewModel.swift
//  AryaLog
//
//  ViewModel for the Stats screen
//

import Foundation
import CoreData
import Combine

@MainActor
class StatsViewModel: ObservableObject {
    @Published var selectedDate: Date = Date()
    @Published var dailyBreastfeedingData: [DailyData] = []
    @Published var dailyFormulaData: [DailyData] = []
    @Published var dailySleepData: [DailyData] = []
    @Published var dailyDiaperData: [DailyData] = []

    private let viewContext: NSManagedObjectContext

    struct DailyData: Identifiable {
        let id = UUID()
        let date: Date
        let value: Double

        var dayLabel: String {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE"
            return formatter.string(from: date)
        }
    }

    init(context: NSManagedObjectContext) {
        self.viewContext = context
        loadWeekData()
    }

    func loadWeekData() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        var breastfeedingData: [DailyData] = []
        var formulaData: [DailyData] = []
        var sleepData: [DailyData] = []
        var diaperData: [DailyData] = []

        for dayOffset in (0..<7).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }

            let breastfeedingMinutes = FeedingLog.totalBreastfeedingMinutes(for: date, in: viewContext)
            let formulaML = FeedingLog.totalFormulaML(for: date, in: viewContext)
            let sleepCount = FeedingLog.countForType(.sleep, for: date, in: viewContext)
            let diaperCount = FeedingLog.countForType(.pee, for: date, in: viewContext)
                + FeedingLog.countForType(.poop, for: date, in: viewContext)

            breastfeedingData.append(DailyData(date: date, value: Double(breastfeedingMinutes)))
            formulaData.append(DailyData(date: date, value: Double(formulaML)))
            sleepData.append(DailyData(date: date, value: Double(sleepCount)))
            diaperData.append(DailyData(date: date, value: Double(diaperCount)))
        }

        self.dailyBreastfeedingData = breastfeedingData
        self.dailyFormulaData = formulaData
        self.dailySleepData = sleepData
        self.dailyDiaperData = diaperData
    }

    func refresh() {
        loadWeekData()
    }

    // Stats for selected date
    var selectedDateBreastfeedingMinutes: Int {
        FeedingLog.totalBreastfeedingMinutes(for: selectedDate, in: viewContext)
    }

    var selectedDateFormulaML: Int {
        FeedingLog.totalFormulaML(for: selectedDate, in: viewContext)
    }

    var selectedDateSleepCount: Int {
        FeedingLog.countForType(.sleep, for: selectedDate, in: viewContext)
    }

    var selectedDateDiaperCount: Int {
        FeedingLog.countForType(.pee, for: selectedDate, in: viewContext)
            + FeedingLog.countForType(.poop, for: selectedDate, in: viewContext)
    }

    var selectedDateLogs: [FeedingLog] {
        FeedingLog.fetchForDate(selectedDate, in: viewContext)
    }

    var selectedDateLogCount: Int {
        selectedDateLogs.count
    }

    // Weekly totals
    var weeklyBreastfeedingTotal: Int {
        Int(dailyBreastfeedingData.reduce(0) { $0 + $1.value })
    }

    var weeklyFormulaTotal: Int {
        Int(dailyFormulaData.reduce(0) { $0 + $1.value })
    }

    var weeklySleepTotal: Int {
        Int(dailySleepData.reduce(0) { $0 + $1.value })
    }

    var weeklyDiaperTotal: Int {
        Int(dailyDiaperData.reduce(0) { $0 + $1.value })
    }

    var weeklyLogCount: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let weekAgo = calendar.date(byAdding: .day, value: -6, to: today) else { return 0 }

        let logs = FeedingLog.fetchForDateRange(from: weekAgo, to: Date(), in: viewContext)
        return logs.count
    }
}
