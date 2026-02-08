//
//  FormulaFormView.swift
//  AryaLog
//
//  Formula feeding entry form with volume picker
//

import SwiftUI
import CoreData

struct FormulaFormView: View {
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
                            Image(systemName: "cup.and.saucer.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(.blue)
                            Text("Formula")
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
                    VolumePicker(value: $volumeML)
                }

                Section("Notes (Optional)") {
                    TextField("Add notes...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Log Formula")
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
        log.activityType = ActivityType.formula.rawValue
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
            print("Failed to save formula log: \(error)")
        }
    }
}

struct VolumePicker: View {
    @Binding var value: Int

    let presets = [30, 60, 90, 120, 150, 180]

    var body: some View {
        VStack(spacing: 16) {
            // Current value display
            HStack {
                Text("Volume")
                Spacer()
                Text("\(value) mL")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.blue)
            }

            // Preset buttons
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                ForEach(presets, id: \.self) { preset in
                    Button(action: { value = preset }) {
                        Text("\(preset) mL")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(value == preset ? Color.blue : Color(.systemGray5))
                            .foregroundStyle(value == preset ? .white : .primary)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
            }

            // Fine-tune controls
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

            // Slider for precise control
            Slider(value: Binding(
                get: { Double(value) },
                set: { value = Int($0) }
            ), in: 10...300, step: 5)
            .tint(.blue)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    FormulaFormView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
