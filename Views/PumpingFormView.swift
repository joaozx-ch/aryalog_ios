//
//  PumpingFormView.swift
//  AryaLog
//
//  Breast milk pumping entry form with volume picker
//

import SwiftUI
import CoreData

struct PumpingFormView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @State private var startTime = Date()
    @State private var volumeML: Int = 60
    @State private var notes: String = ""

    var onSave: (() -> Void)?

    init(onSave: (() -> Void)? = nil) {
        self.onSave = onSave
    }

    var isValid: Bool {
        volumeML > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "arrow.up.heart.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(.purple)
                            Text("Pumping")
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

                Section("Amount") {
                    PumpingVolumePicker(value: $volumeML)
                }

                Section("Notes (Optional)") {
                    TextField("Add notes...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Log Pumping")
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
        guard let caregiver = Caregiver.fetchCurrentUser(in: viewContext) else { return }

        let log = FeedingLog(context: viewContext)
        log.id = UUID()
        log.activityType = ActivityType.pumping.rawValue
        log.startTime = startTime
        log.leftDuration = 0
        log.rightDuration = 0
        log.volumeML = Int16(volumeML)
        log.notes = notes.isEmpty ? nil : notes
        log.createdAt = Date()
        log.caregiver = caregiver

        do {
            try viewContext.save()
            onSave?()
            dismiss()
        } catch {
            print("Failed to save pumping log: \(error)")
        }
    }
}

struct PumpingVolumePicker: View {
    @Binding var value: Int

    let presets = [30, 60, 90, 120, 150, 180]

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Volume")
                Spacer()
                Text("\(value) mL")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.purple)
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                ForEach(presets, id: \.self) { preset in
                    Button(action: { value = preset }) {
                        Text("\(preset) mL")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(value == preset ? Color.purple : Color(.systemGray5))
                            .foregroundStyle(value == preset ? .white : .primary)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack(spacing: 20) {
                Button(action: { if value >= 10 { value -= 10 } }) {
                    HStack {
                        Image(systemName: "minus")
                        Text("10")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color(.systemGray5))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(value < 10)

                Spacer()

                Button(action: { if value <= 490 { value += 10 } }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("10")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color(.systemGray5))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(value > 490)
            }

            Slider(value: Binding(
                get: { Double(value) },
                set: { value = Int($0) }
            ), in: 10...300, step: 5)
            .tint(.purple)
        }
        .padding(.vertical, 8)
    }
}
