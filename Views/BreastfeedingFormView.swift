//
//  BreastfeedingFormView.swift
//  AryaLog
//
//  Breastfeeding entry form with left/right duration pickers
//

import SwiftUI
import CoreData

struct BreastfeedingFormView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @State private var startTime = Date()
    @State private var leftDuration: Int = 0
    @State private var rightDuration: Int = 0
    @State private var notes: String = ""

    var onSave: (() -> Void)?

    init(onSave: (() -> Void)? = nil) {
        self.onSave = onSave
    }

    var totalDuration: Int {
        leftDuration + rightDuration
    }

    var isValid: Bool {
        totalDuration > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "drop.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(.pink)
                            Text("Breastfeeding")
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }

                Section("Time") {
                    DatePicker("Start Time", selection: $startTime)
                }

                Section("Duration") {
                    DurationPicker(label: "Left Side", value: $leftDuration, color: .pink)
                    DurationPicker(label: "Right Side", value: $rightDuration, color: .pink)

                    HStack {
                        Text("Total Duration")
                            .fontWeight(.medium)
                        Spacer()
                        Text("\(totalDuration) min")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Notes (Optional)") {
                    TextField("Add notes...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Log Breastfeeding")
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
                    .disabled(!isValid)
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
        log.activityType = ActivityType.breastfeeding.rawValue
        log.startTime = startTime
        log.leftDuration = Int16(leftDuration)
        log.rightDuration = Int16(rightDuration)
        log.volumeML = 0
        log.notes = notes.isEmpty ? nil : notes
        log.createdAt = Date()
        log.caregiver = caregiver

        do {
            try viewContext.save()
            onSave?()
            dismiss()
        } catch {
            print("Failed to save breastfeeding log: \(error)")
        }
    }
}

struct DurationPicker: View {
    let label: String
    @Binding var value: Int
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(label)
                Spacer()
                Text("\(value) min")
                    .fontWeight(.medium)
                    .foregroundStyle(color)
            }

            HStack(spacing: 16) {
                ForEach([5, 10, 15, 20], id: \.self) { preset in
                    Button(action: { value = preset }) {
                        Text("\(preset)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .frame(width: 44, height: 36)
                            .background(value == preset ? color : Color(.systemGray5))
                            .foregroundStyle(value == preset ? .white : .primary)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                HStack(spacing: 12) {
                    Button(action: { if value > 0 { value -= 1 } }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(value > 0 ? color : .gray)
                    }
                    .buttonStyle(.plain)
                    .disabled(value == 0)

                    Button(action: { if value < 60 { value += 1 } }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(value < 60 ? color : .gray)
                    }
                    .buttonStyle(.plain)
                    .disabled(value >= 60)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    BreastfeedingFormView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
