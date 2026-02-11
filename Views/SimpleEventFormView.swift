//
//  SimpleEventFormView.swift
//  AryaLog
//
//  Shared form for simple timestamp-based events (Sleep, Wake Up, Pee, Poop)
//

import SwiftUI
import CoreData

struct SimpleEventFormView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    let activityType: ActivityType

    @State private var startTime = Date()
    @State private var notes: String = ""

    var onSave: (() -> Void)?

    init(activityType: ActivityType, onSave: (() -> Void)? = nil) {
        self.activityType = activityType
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: activityType.icon)
                                .font(.system(size: 48))
                                .foregroundStyle(activityType.color)
                            Text(activityType.displayName)
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }

                Section("Time") {
                    DatePicker("Time", selection: $startTime)
                }

                Section("Notes (Optional)") {
                    TextField("Add notes...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Log \(activityType.displayName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveLog()
                    }
                }
            }
        }
    }

    private func saveLog() {
        guard let caregiver = Caregiver.fetchCurrentUser(in: viewContext) else {
            print("No current caregiver found")
            return
        }

        let log = FeedingLog(context: viewContext)
        log.id = UUID()
        log.activityType = activityType.rawValue
        log.startTime = startTime
        log.leftDuration = 0
        log.rightDuration = 0
        log.volumeML = 0
        log.notes = notes.isEmpty ? nil : notes
        log.createdAt = Date()
        log.caregiver = caregiver

        do {
            try viewContext.save()
            onSave?()
            dismiss()
        } catch {
            print("Failed to save \(activityType.displayName) log: \(error)")
        }
    }
}

#Preview {
    SimpleEventFormView(activityType: .sleep)
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
