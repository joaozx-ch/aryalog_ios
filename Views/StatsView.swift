//
//  StatsView.swift
//  AryaLog
//
//  Charts and daily summaries for feeding statistics
//

import SwiftUI
import Charts
import CoreData

struct StatsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: StatsViewModel

    init() {
        _viewModel = StateObject(wrappedValue: StatsViewModel(context: PersistenceController.shared.container.viewContext))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Date picker
                    datePicker

                    // Daily summary card
                    dailySummaryCard

                    // Weekly breastfeeding chart
                    breastfeedingChartCard

                    // Weekly formula chart
                    formulaChartCard

                    // Weekly EBM chart
                    ebmChartCard

                    // Weekly pumping chart
                    pumpingChartCard

                    // Weekly sleep chart
                    sleepChartCard

                    // Weekly diaper chart
                    diaperChartCard

                    // Weekly summary
                    weeklySummaryCard
                }
                .padding()
            }
            .navigationTitle("Statistics")
            .refreshable {
                viewModel.refresh()
            }
            .onAppear {
                viewModel.refresh()
            }
        }
    }

    private var datePicker: some View {
        DatePicker(
            "Select Date",
            selection: $viewModel.selectedDate,
            in: ...Date(),
            displayedComponents: .date
        )
        .datePickerStyle(.compact)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private var dailySummaryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Daily Summary")
                .font(.headline)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                DailyStat(
                    icon: "drop.fill",
                    label: "Breastfeeding",
                    value: "\(viewModel.selectedDateBreastfeedingMinutes) min",
                    color: .pink
                )

                DailyStat(
                    icon: "cup.and.saucer.fill",
                    label: "Formula",
                    value: "\(viewModel.selectedDateFormulaML) mL",
                    color: .blue
                )

                DailyStat(
                    icon: "drop.fill",
                    label: "EBM",
                    value: "\(viewModel.selectedDateEBMML) mL",
                    color: .cyan
                )

                DailyStat(
                    icon: "arrow.up.heart.fill",
                    label: "Pumping",
                    value: "\(viewModel.selectedDatePumpingML) mL",
                    color: .purple
                )

                DailyStat(
                    icon: "moon.fill",
                    label: "Sleeps",
                    value: "\(viewModel.selectedDateSleepCount)",
                    color: .indigo
                )

                DailyStat(
                    icon: "drop.triangle.fill",
                    label: "Diapers",
                    value: "\(viewModel.selectedDateDiaperCount)",
                    color: .yellow
                )

                DailyStat(
                    icon: "number",
                    label: "Total Logs",
                    value: "\(viewModel.selectedDateLogCount)",
                    color: .green
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private var breastfeedingChartCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "drop.fill")
                    .foregroundStyle(.pink)
                Text("Breastfeeding (minutes)")
                    .font(.headline)
            }

            if viewModel.dailyBreastfeedingData.allSatisfy({ $0.value == 0 }) {
                EmptyChartView(message: "No breastfeeding data this week")
            } else {
                Chart(viewModel.dailyBreastfeedingData) { data in
                    BarMark(
                        x: .value("Day", data.dayLabel),
                        y: .value("Minutes", data.value)
                    )
                    .foregroundStyle(.pink.gradient)
                    .cornerRadius(4)
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private var formulaChartCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "cup.and.saucer.fill")
                    .foregroundStyle(.blue)
                Text("Formula (mL)")
                    .font(.headline)
            }

            if viewModel.dailyFormulaData.allSatisfy({ $0.value == 0 }) {
                EmptyChartView(message: "No formula data this week")
            } else {
                Chart(viewModel.dailyFormulaData) { data in
                    BarMark(
                        x: .value("Day", data.dayLabel),
                        y: .value("mL", data.value)
                    )
                    .foregroundStyle(.blue.gradient)
                    .cornerRadius(4)
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private var ebmChartCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "drop.fill")
                    .foregroundStyle(.cyan)
                Text("EBM (mL)")
                    .font(.headline)
            }

            if viewModel.dailyEBMData.allSatisfy({ $0.value == 0 }) {
                EmptyChartView(message: "No EBM data this week")
            } else {
                Chart(viewModel.dailyEBMData) { data in
                    BarMark(
                        x: .value("Day", data.dayLabel),
                        y: .value("mL", data.value)
                    )
                    .foregroundStyle(.cyan.gradient)
                    .cornerRadius(4)
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private var pumpingChartCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "arrow.up.heart.fill")
                    .foregroundStyle(.purple)
                Text("Pumping (mL)")
                    .font(.headline)
            }

            if viewModel.dailyPumpingData.allSatisfy({ $0.value == 0 }) {
                EmptyChartView(message: "No pumping data this week")
            } else {
                Chart(viewModel.dailyPumpingData) { data in
                    BarMark(
                        x: .value("Day", data.dayLabel),
                        y: .value("mL", data.value)
                    )
                    .foregroundStyle(.purple.gradient)
                    .cornerRadius(4)
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private var sleepChartCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "moon.fill")
                    .foregroundStyle(.indigo)
                Text("Sleep (count)")
                    .font(.headline)
            }

            if viewModel.dailySleepData.allSatisfy({ $0.value == 0 }) {
                EmptyChartView(message: "No sleep data this week")
            } else {
                Chart(viewModel.dailySleepData) { data in
                    BarMark(
                        x: .value("Day", data.dayLabel),
                        y: .value("Count", data.value)
                    )
                    .foregroundStyle(.indigo.gradient)
                    .cornerRadius(4)
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private var diaperChartCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "drop.triangle.fill")
                    .foregroundStyle(.yellow)
                Text("Diapers (count)")
                    .font(.headline)
            }

            if viewModel.dailyDiaperData.allSatisfy({ $0.value == 0 }) {
                EmptyChartView(message: "No diaper data this week")
            } else {
                Chart(viewModel.dailyDiaperData) { data in
                    BarMark(
                        x: .value("Day", data.dayLabel),
                        y: .value("Count", data.value)
                    )
                    .foregroundStyle(.yellow.gradient)
                    .cornerRadius(4)
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private var weeklySummaryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Weekly Totals")
                .font(.headline)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                WeeklyStat(
                    label: "Breastfeeding",
                    value: formatMinutes(viewModel.weeklyBreastfeedingTotal),
                    color: .pink
                )

                WeeklyStat(
                    label: "Formula",
                    value: "\(viewModel.weeklyFormulaTotal) mL",
                    color: .blue
                )

                WeeklyStat(
                    label: "EBM",
                    value: "\(viewModel.weeklyEBMTotal) mL",
                    color: .cyan
                )

                WeeklyStat(
                    label: "Pumping",
                    value: "\(viewModel.weeklyPumpingTotal) mL",
                    color: .purple
                )

                WeeklyStat(
                    label: "Sleeps",
                    value: "\(viewModel.weeklySleepTotal)",
                    color: .indigo
                )

                WeeklyStat(
                    label: "Diapers",
                    value: "\(viewModel.weeklyDiaperTotal)",
                    color: .yellow
                )

                WeeklyStat(
                    label: "Total Logs",
                    value: "\(viewModel.weeklyLogCount)",
                    color: .green
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private func formatMinutes(_ minutes: Int) -> String {
        if minutes >= 60 {
            let hours = minutes / 60
            let mins = minutes % 60
            return String(localized: "\(hours)h \(mins)m")
        }
        return String(localized: "\(minutes) min")
    }
}

struct DailyStat: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(value)
                .font(.headline)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct WeeklyStat: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .foregroundStyle(color)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

struct EmptyChartView: View {
    let message: String

    var body: some View {
        VStack {
            Image(systemName: "chart.bar")
                .font(.largeTitle)
                .foregroundStyle(.tertiary)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    StatsView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
