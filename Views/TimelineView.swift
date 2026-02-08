//
//  TimelineView.swift
//  AryaLog
//
//  Vertical event timeline placed along a time axis
//

import SwiftUI
import CoreData

struct TimelineView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @State private var selectedDate = Date()
    @State private var showingBreastfeedingForm = false
    @State private var showingFormulaForm = false
    @State private var selectedLog: FeedingLog?
    @State private var showingEditSheet = false

    private let axisX: CGFloat = 40
    private let hourHeight: CGFloat = 80

    private var logsForDay: [FeedingLog] {
        FeedingLog.fetchForDate(selectedDate, in: viewContext)
            .sorted { ($0.startTime ?? .distantPast) < ($1.startTime ?? .distantPast) }
    }

    private var hourRange: ClosedRange<Int> {
        let calendar = Calendar.current
        let hours = logsForDay.map { calendar.component(.hour, from: $0.wrappedStartTime) }
        guard let minH = hours.min(), let maxH = hours.max() else {
            return 6...22
        }
        return max(minH - 1, 0)...min(maxH + 1, 23)
    }

    private var totalAxisHeight: CGFloat {
        CGFloat(hourRange.count) * hourHeight
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Date picker
                datePickerHeader

                if logsForDay.isEmpty {
                    Spacer()
                    ContentUnavailableView(
                        "No Feeding Logs",
                        systemImage: "list.bullet",
                        description: Text("No events on this day")
                    )
                    Spacer()
                } else {
                    // Day summary
                    daySummaryBar

                    // Timeline axis
                    ScrollView {
                        ZStack(alignment: .topLeading) {
                            // Vertical axis line
                            axisLine

                            // Hour markers
                            hourMarkers

                            // Event nodes
                            eventNodes
                        }
                        .frame(width: nil, height: totalAxisHeight)
                        .padding(.trailing, 16)
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("Timeline")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button(action: { showingBreastfeedingForm = true }) {
                            Label("Breastfeeding", systemImage: "drop.fill")
                        }
                        Button(action: { showingFormulaForm = true }) {
                            Label("Formula", systemImage: "cup.and.saucer.fill")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingBreastfeedingForm) {
                BreastfeedingFormView {
                    // trigger refresh by toggling date
                    let d = selectedDate
                    selectedDate = d
                }
            }
            .sheet(isPresented: $showingFormulaForm) {
                FormulaFormView {
                    let d = selectedDate
                    selectedDate = d
                }
            }
            .sheet(isPresented: $showingEditSheet) {
                if let log = selectedLog {
                    EditFeedingLogView(log: log)
                }
            }
        }
    }

    // MARK: - Date Picker

    private var datePickerHeader: some View {
        DatePicker(
            "Date",
            selection: $selectedDate,
            in: ...Date(),
            displayedComponents: .date
        )
        .datePickerStyle(.compact)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    // MARK: - Day Summary

    private var daySummaryBar: some View {
        let bfMinutes = logsForDay
            .filter { $0.wrappedActivityType == .breastfeeding }
            .reduce(0) { $0 + Int($1.totalDuration) }
        let formulaML = logsForDay
            .filter { $0.wrappedActivityType == .formula }
            .reduce(0) { $0 + Int($1.volumeML) }

        return HStack(spacing: 12) {
            Label("\(logsForDay.count) feedings", systemImage: "list.bullet")
            if bfMinutes > 0 {
                Label("\(bfMinutes) min", systemImage: "drop.fill")
                    .foregroundStyle(.pink)
            }
            if formulaML > 0 {
                Label("\(formulaML) mL", systemImage: "cup.and.saucer.fill")
                    .foregroundStyle(.blue)
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal)
        .padding(.bottom, 4)
    }

    // MARK: - Axis

    private var axisLine: some View {
        Rectangle()
            .fill(Color(.systemGray4))
            .frame(width: 2, height: totalAxisHeight)
            .offset(x: axisX - 1)
    }

    private var hourMarkers: some View {
        ForEach(Array(hourRange), id: \.self) { hour in
            let y = yOffset(forHour: hour)
            HStack(spacing: 0) {
                Text(hourLabel(hour))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .frame(width: axisX - 8, alignment: .trailing)

                // Tick mark
                Rectangle()
                    .fill(Color(.systemGray4))
                    .frame(width: 8, height: 1)
            }
            .offset(y: y - 6) // center text on tick
        }
    }

    // MARK: - Events

    private var eventNodes: some View {
        ForEach(logsForDay) { log in
            let y = yPosition(for: log.wrappedStartTime)
            let color = log.wrappedActivityType.color

            HStack(spacing: 0) {
                // Spacer to axis position
                Spacer()
                    .frame(width: axisX - 6)

                // Dot on axis
                Circle()
                    .fill(color)
                    .frame(width: 12, height: 12)
                    .shadow(color: color.opacity(0.4), radius: 3, x: 0, y: 1)

                // Connector line
                Rectangle()
                    .fill(color.opacity(0.4))
                    .frame(width: 12, height: 2)

                // Event card
                TimelineEventCard(log: log)
                    .onTapGesture {
                        selectedLog = log
                        showingEditSheet = true
                    }
                    .contextMenu {
                        Button(role: .destructive) {
                            deleteLog(log)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
            .offset(y: y - 6) // center dot vertically
        }
    }

    // MARK: - Helpers

    private func yOffset(forHour hour: Int) -> CGFloat {
        CGFloat(hour - hourRange.lowerBound) * hourHeight
    }

    private func yPosition(for date: Date) -> CGFloat {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let fractionalHour = Double(hour) + Double(minute) / 60.0
        return CGFloat(fractionalHour - Double(hourRange.lowerBound)) * hourHeight
    }

    private func hourLabel(_ hour: Int) -> String {
        let h = hour % 12 == 0 ? 12 : hour % 12
        let suffix = hour < 12 ? "AM" : "PM"
        return "\(h) \(suffix)"
    }

    private func deleteLog(_ log: FeedingLog) {
        viewContext.delete(log)
        do {
            try viewContext.save()
        } catch {
            print("Failed to delete log: \(error)")
        }
    }
}

// MARK: - Event Card

struct TimelineEventCard: View {
    let log: FeedingLog

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: log.wrappedActivityType.icon)
                .font(.title3)
                .foregroundStyle(log.wrappedActivityType.color)
                .frame(width: 32, height: 32)
                .background(log.wrappedActivityType.color.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(log.wrappedActivityType.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(log.summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(log.wrappedStartTime, style: .time)
                    .font(.caption)
                    .fontWeight(.medium)
                if let caregiver = log.caregiver {
                    Text(caregiver.wrappedName)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 1)
    }
}

struct EditFeedingLogView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    let log: FeedingLog

    @State private var startTime: Date
    @State private var leftDuration: Int
    @State private var rightDuration: Int
    @State private var volumeML: Int
    @State private var notes: String

    init(log: FeedingLog) {
        self.log = log
        _startTime = State(initialValue: log.wrappedStartTime)
        _leftDuration = State(initialValue: Int(log.leftDuration))
        _rightDuration = State(initialValue: Int(log.rightDuration))
        _volumeML = State(initialValue: Int(log.volumeML))
        _notes = State(initialValue: log.wrappedNotes)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Time") {
                    DatePicker("Start Time", selection: $startTime)
                }

                if log.wrappedActivityType == .breastfeeding {
                    Section("Duration") {
                        Stepper("Left: \(leftDuration) min", value: $leftDuration, in: 0...60)
                        Stepper("Right: \(rightDuration) min", value: $rightDuration, in: 0...60)
                    }
                } else {
                    Section("Amount") {
                        Stepper("\(volumeML) mL", value: $volumeML, in: 0...500, step: 10)
                    }
                }

                Section("Notes") {
                    TextField("Optional notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section {
                    Button("Delete Log", role: .destructive) {
                        viewContext.delete(log)
                        try? viewContext.save()
                        dismiss()
                    }
                }
            }
            .navigationTitle("Edit \(log.wrappedActivityType.displayName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                }
            }
        }
    }

    private func saveChanges() {
        log.startTime = startTime
        log.leftDuration = Int16(leftDuration)
        log.rightDuration = Int16(rightDuration)
        log.volumeML = Int16(volumeML)
        log.notes = notes.isEmpty ? nil : notes

        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Failed to save changes: \(error)")
        }
    }
}

#Preview {
    TimelineView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
