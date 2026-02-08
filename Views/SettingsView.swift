//
//  SettingsView.swift
//  AryaLog
//
//  Caregiver management and app settings
//

import SwiftUI
import CoreData

struct SettingsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Caregiver.createdAt, ascending: true)],
        animation: .default
    )
    private var caregivers: FetchedResults<Caregiver>

    @State private var showingShareSheet = false
    @State private var showingEditName = false
    @State private var editingCaregiver: Caregiver?
    @State private var newName = ""

    var currentCaregiver: Caregiver? {
        caregivers.first { $0.isCurrentUser }
    }

    var body: some View {
        NavigationStack {
            List {
                // Current user section
                Section("Your Profile") {
                    if let caregiver = currentCaregiver {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .font(.largeTitle)
                                .foregroundStyle(.pink)

                            VStack(alignment: .leading) {
                                Text(caregiver.wrappedName)
                                    .font(.headline)
                                Text("Current User")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Button("Edit") {
                                editingCaregiver = caregiver
                                newName = caregiver.wrappedName
                                showingEditName = true
                            }
                            .font(.subheadline)
                        }
                    }
                }

                // Caregivers section
                Section("Caregivers") {
                    ForEach(caregivers) { caregiver in
                        HStack {
                            Image(systemName: caregiver.isCurrentUser ? "person.fill" : "person")
                                .foregroundStyle(caregiver.isCurrentUser ? .pink : .secondary)

                            Text(caregiver.wrappedName)

                            Spacer()

                            if caregiver.isCurrentUser {
                                Text("You")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    Button(action: { showingShareSheet = true }) {
                        Label("Invite Caregiver", systemImage: "person.badge.plus")
                    }
                }

                // CloudKit sharing section
                Section {
                    NavigationLink(destination: CloudKitSharingGuideView()) {
                        Label("CloudKit Sharing", systemImage: "icloud")
                    }
                } header: {
                    Text("Data Sync")
                } footer: {
                    Text("Share your baby's feeding data with other caregivers using iCloud.")
                }

                // About section
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }

                    Link(destination: URL(string: "https://www.apple.com/legal/privacy/")!) {
                        HStack {
                            Text("Privacy Policy")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Data management
                Section("Data") {
                    NavigationLink(destination: ExportDataView()) {
                        Label("Export Data", systemImage: "square.and.arrow.up")
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingEditName) {
                EditNameSheet(
                    name: $newName,
                    onSave: {
                        if let caregiver = editingCaregiver {
                            caregiver.name = newName
                            try? viewContext.save()
                        }
                        showingEditName = false
                    },
                    onCancel: {
                        showingEditName = false
                    }
                )
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareInviteView()
            }
        }
    }
}

struct EditNameSheet: View {
    @Binding var name: String
    let onSave: () -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Your Name") {
                    TextField("Name", text: $name)
                        .textContentType(.name)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: onSave)
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

struct ShareInviteView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.pink)

                Text("Invite Caregiver")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Share your baby's feeding data with other caregivers using iCloud sharing.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                VStack(alignment: .leading, spacing: 16) {
                    InstructionRow(number: 1, text: "Enable iCloud in Settings")
                    InstructionRow(number: 2, text: "Go to CloudKit Sharing")
                    InstructionRow(number: 3, text: "Create a share link")
                    InstructionRow(number: 4, text: "Send to other caregivers")
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Spacer()

                Button(action: { dismiss() }) {
                    Text("Got It")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.pink)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

struct InstructionRow: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Text("\(number)")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(Color.pink)
                .clipShape(Circle())

            Text(text)
                .font(.body)
        }
    }
}

struct CloudKitSharingGuideView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("How CloudKit Sharing Works")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("AryaLog uses iCloud to sync feeding data between all caregivers. This requires an active Apple ID and iCloud account.")
                        .foregroundStyle(.secondary)
                }

                Divider()

                VStack(alignment: .leading, spacing: 16) {
                    SectionHeader(icon: "1.circle.fill", title: "Requirements")

                    BulletPoint(text: "Active Apple ID on all devices")
                    BulletPoint(text: "iCloud enabled in device Settings")
                    BulletPoint(text: "AryaLog granted iCloud access")
                }

                VStack(alignment: .leading, spacing: 16) {
                    SectionHeader(icon: "2.circle.fill", title: "Creating a Share")

                    Text("The share functionality is built into the app. Data syncs automatically between devices signed into the same iCloud account.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 16) {
                    SectionHeader(icon: "3.circle.fill", title: "Sharing with Others")

                    Text("To share with other caregivers who have different Apple IDs, you'll need to use CloudKit's sharing APIs. This is configured in the ShareController.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 16) {
                    SectionHeader(icon: "info.circle.fill", title: "Note")

                    Text("Full CloudKit sharing requires an Apple Developer account and proper CloudKit container configuration. The current implementation syncs data for the same iCloud account across devices.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
        }
        .navigationTitle("CloudKit Sharing")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SectionHeader: View {
    let icon: String
    let title: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(.pink)
            Text(title)
                .font(.headline)
        }
    }
}

struct BulletPoint: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .foregroundStyle(.pink)
            Text(text)
        }
        .font(.body)
    }
}

struct ExportDataView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var exportText = ""
    @State private var showingShareSheet = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Export your feeding logs as a CSV file.")
                .foregroundStyle(.secondary)

            Button(action: generateExport) {
                Label("Generate Export", systemImage: "doc.text")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.pink)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            if !exportText.isEmpty {
                ScrollView {
                    Text(exportText)
                        .font(.system(.caption, design: .monospaced))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                Button(action: { showingShareSheet = true }) {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray5))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Export Data")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: [exportText])
        }
    }

    private func generateExport() {
        let logs = FeedingLog.fetchAll(in: viewContext)

        var csv = "Date,Time,Type,Left (min),Right (min),Volume (mL),Caregiver,Notes\n"

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"

        for log in logs {
            let date = dateFormatter.string(from: log.wrappedStartTime)
            let time = timeFormatter.string(from: log.wrappedStartTime)
            let type = log.wrappedActivityType.displayName
            let left = log.wrappedActivityType == .breastfeeding ? "\(log.leftDuration)" : ""
            let right = log.wrappedActivityType == .breastfeeding ? "\(log.rightDuration)" : ""
            let volume = log.wrappedActivityType == .formula ? "\(log.volumeML)" : ""
            let caregiver = log.caregiver?.wrappedName ?? ""
            let notes = log.wrappedNotes.replacingOccurrences(of: ",", with: ";")

            csv += "\(date),\(time),\(type),\(left),\(right),\(volume),\(caregiver),\(notes)\n"
        }

        exportText = csv
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    SettingsView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
