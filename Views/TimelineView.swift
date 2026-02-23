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
    @State private var showingSimpleEventType: ActivityType?
    @State private var selectedLog: FeedingLog?
    @State private var showingEditSheet = false

    private var logsForDay: [FeedingLog] {
        FeedingLog.fetchForDate(selectedDate, in: viewContext)
            .sorted { ($0.startTime ?? .distantPast) < ($1.startTime ?? .distantPast) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Date picker
                datePickerHeader

                if logsForDay.isEmpty {
                    Spacer()
                    ContentUnavailableView(
                        "No Logs",
                        systemImage: "list.bullet",
                        description: Text("No events on this day")
                    )
                    Spacer()
                } else {
                    // Day summary
                    daySummaryBar

                    // Timeline
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(logsForDay.enumerated()), id: \.element.id) { index, log in
                                // Time gap indicator between events
                                if index > 0 {
                                    timeGapView(from: logsForDay[index - 1], to: log)
                                }

                                // Event row
                                TimelineRow(log: log, isFirst: index == 0, isLast: index == logsForDay.count - 1, showWarning: needsSleepWarning(at: index, in: logsForDay)) {
                                    selectedLog = log
                                    showingEditSheet = true
                                } onDelete: {
                                    deleteLog(log)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("Timeline")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Section("Feeding") {
                            Button(action: { showingBreastfeedingForm = true }) {
                                Label("Breastfeeding", systemImage: "drop.fill")
                            }
                            Button(action: { showingFormulaForm = true }) {
                                Label("Formula", systemImage: "cup.and.saucer.fill")
                            }
                        }
                        Section("Sleep") {
                            Button(action: { showingSimpleEventType = .sleep }) {
                                Label("Sleep", systemImage: "moon.fill")
                            }
                            Button(action: { showingSimpleEventType = .wakeUp }) {
                                Label("Wake Up", systemImage: "sun.max.fill")
                            }
                        }
                        Section("Diaper") {
                            Button(action: { showingSimpleEventType = .pee }) {
                                Label("Pee", systemImage: "drop.triangle.fill")
                            }
                            Button(action: { showingSimpleEventType = .poop }) {
                                Label("Poop", systemImage: "leaf.fill")
                            }
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingBreastfeedingForm) {
                BreastfeedingFormView {
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
            .sheet(item: $showingSimpleEventType) { type in
                SimpleEventFormView(activityType: type) {
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
        let sleepCount = logsForDay.filter { $0.wrappedActivityType == .sleep }.count
        let diaperCount = logsForDay.filter { $0.wrappedActivityType == .pee || $0.wrappedActivityType == .poop }.count

        return HStack(spacing: 12) {
            Label("\(logsForDay.count) events", systemImage: "list.bullet")
            if bfMinutes > 0 {
                Label("\(bfMinutes) min", systemImage: "drop.fill")
                    .foregroundStyle(.pink)
            }
            if formulaML > 0 {
                Label("\(formulaML) mL", systemImage: "cup.and.saucer.fill")
                    .foregroundStyle(.blue)
            }
            if sleepCount > 0 {
                Label("\(sleepCount)", systemImage: "moon.fill")
                    .foregroundStyle(.indigo)
            }
            if diaperCount > 0 {
                Label("\(diaperCount)", systemImage: "drop.triangle.fill")
                    .foregroundStyle(.yellow)
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal)
        .padding(.bottom, 4)
    }

    // MARK: - Time Gap

    private func timeGapView(from prev: FeedingLog, to next: FeedingLog) -> some View {
        let interval = next.wrappedStartTime.timeIntervalSince(prev.wrappedStartTime)
        let minutes = Int(interval) / 60

        return HStack(spacing: 0) {
            // Vertical line segment aligned with the timeline axis
            Rectangle()
                .fill(Color(.systemGray4))
                .frame(width: 2)
                .frame(maxHeight: .infinity)
                .padding(.leading, 5)

            if minutes >= 5 {
                Text(formatGap(minutes))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.leading, 16)
            }

            Spacer()
        }
        .frame(height: gapHeight(minutes: minutes))
    }

    private func gapHeight(minutes: Int) -> CGFloat {
        if minutes < 5 { return 4 }
        if minutes < 30 { return 20 }
        if minutes < 60 { return 28 }
        return 36
    }

    private func formatGap(_ minutes: Int) -> String {
        if minutes >= 60 {
            let h = minutes / 60
            let m = minutes % 60
            return m > 0 ? "\(h)h \(m)m" : "\(h)h"
        }
        return "\(minutes)m"
    }

    // MARK: - Sleep Warning

    private func needsSleepWarning(at index: Int, in logs: [FeedingLog]) -> Bool {
        let log = logs[index]
        guard log.wrappedActivityType != .wakeUp else { return false }
        for i in stride(from: index - 1, through: 0, by: -1) {
            let prevType = logs[i].wrappedActivityType
            if prevType == .wakeUp { return false }
            if prevType == .sleep { return true }
        }
        return false
    }

    // MARK: - Helpers

    private func deleteLog(_ log: FeedingLog) {
        viewContext.delete(log)
        do {
            try viewContext.save()
        } catch {
            print("Failed to delete log: \(error)")
        }
    }
}

// MARK: - Timeline Row

struct TimelineRow: View {
    let log: FeedingLog
    let isFirst: Bool
    let isLast: Bool
    let showWarning: Bool
    let onTap: () -> Void
    let onDelete: () -> Void

    private let dotSize: CGFloat = 12

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            // Dot on the axis
            Circle()
                .fill(log.wrappedActivityType.color)
                .frame(width: dotSize, height: dotSize)
                .shadow(color: log.wrappedActivityType.color.opacity(0.4), radius: 3, x: 0, y: 1)

            // Event card
            TimelineEventCard(log: log, showWarning: showWarning)
                .onTapGesture(perform: onTap)
                .contextMenu {
                    Button(role: .destructive, action: onDelete) {
                        Label("Delete", systemImage: "trash")
                    }
                }
        }
    }
}

// MARK: - Event Card

struct TimelineEventCard: View {
    let log: FeedingLog
    let showWarning: Bool

    var body: some View {
        HStack(spacing: 10) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: log.wrappedActivityType.icon)
                    .font(.title3)
                    .foregroundStyle(log.wrappedActivityType.color)
                    .frame(width: 32, height: 32)
                    .background(log.wrappedActivityType.color.opacity(0.12))
                    .clipShape(Circle())
                if showWarning {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.orange)
                        .background(Color(.systemBackground).clipShape(Circle()))
                        .offset(x: 6, y: -6)
                }
            }

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
                } else if log.wrappedActivityType == .formula {
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
