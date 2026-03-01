//
//  SettingsView.swift
//  AryaLog
//
//  Caregiver management and app settings
//

import SwiftUI
import CoreData
import CloudKit
import UIKit

// MARK: - Language

enum AppLanguage: String, CaseIterable {
    case system = ""
    case english = "en"
    case chinese = "zh-Hans"

    var displayName: String {
        switch self {
        case .system:  return String(localized: "System Default")
        case .english: return "English"
        case .chinese: return "简体中文"
        }
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Caregiver.createdAt, ascending: true)],
        animation: .default
    )
    private var caregivers: FetchedResults<Caregiver>

    @AppStorage("selectedLanguage") private var selectedLanguage: String = ""
    @State private var showingEditName = false
    @State private var showingRestartAlert = false
    @State private var isPreparingShare = false
    @State private var shareError: String?
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
                Section {
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

                    Button(action: openShareController) {
                        if isPreparingShare {
                            HStack(spacing: 8) {
                                ProgressView()
                                Text("Share with Caregiver")
                            }
                        } else {
                            Label("Share with Caregiver", systemImage: "person.badge.plus")
                        }
                    }
                    .disabled(isPreparingShare)
                } header: {
                    Text("Caregivers")
                } footer: {
                    Text("Share your baby's care data with other caregivers using iCloud. Each caregiver signs in with their own Apple ID.")
                }

                // Language section
                Section("Language") {
                    Picker("Language", selection: $selectedLanguage) {
                        ForEach(AppLanguage.allCases, id: \.rawValue) { lang in
                            Text(lang.displayName).tag(lang.rawValue)
                        }
                    }
                    .onChange(of: selectedLanguage) { _, newValue in
                        if newValue.isEmpty {
                            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
                        } else {
                            UserDefaults.standard.set([newValue], forKey: "AppleLanguages")
                        }
                        showingRestartAlert = true
                    }
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
            .alert(String(localized: "Restart Required"), isPresented: $showingRestartAlert) {
                Button(String(localized: "OK"), role: .cancel) {}
            } message: {
                Text("Please restart the app to apply the language change.")
            }
            .alert("Sharing Unavailable", isPresented: Binding(
                get: { shareError != nil },
                set: { if !$0 { shareError = nil } }
            )) {
                Button("OK", role: .cancel) { shareError = nil }
            } message: {
                Text(shareError ?? "")
            }
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
        }
    }

    private func openShareController() {
        guard let caregiver = currentCaregiver else { return }
        isPreparingShare = true
        Task {
            defer { isPreparingShare = false }
            do {
                let controller = try await ShareController.shared.makeSharingController(
                    for: caregiver
                ) { error in
                    // UIKit automatically dismisses UICloudSharingController when any
                    // delegate callback fires — we only need to surface errors here.
                    if let error = error {
                        if let ckError = error as? CKError {
                            shareError = "\(error.localizedDescription)\n\n(CKError \(ckError.code.rawValue))"
                        } else {
                            shareError = error.localizedDescription
                        }
                    }
                }
                // UICloudSharingController must be presented directly by a UIViewController.
                // Embedding it in a SwiftUI sheet via UIViewControllerRepresentable makes it
                // a child view controller rather than a modal presentation, which prevents
                // the preparation handler from being called (causing a permanent loading state).
                guard
                    let scene = UIApplication.shared.connectedScenes
                        .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
                    let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController
                else { return }
                var top = root
                while let presented = top.presentedViewController { top = presented }
                top.present(controller, animated: true)
            } catch {
                if let ckError = error as? CKError {
                    shareError = "\(error.localizedDescription)\n\n(CKError \(ckError.code.rawValue))"
                } else {
                    shareError = error.localizedDescription
                }
                print("Failed to prepare share: \(error)")
            }
        }
    }
}

// MARK: - Edit Name Sheet

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

// MARK: - Supporting Views

struct BulletPoint: View {
    let text: LocalizedStringKey

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .foregroundStyle(.pink)
            Text(text)
        }
        .font(.body)
    }
}

// MARK: - Export Data View

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
            let actType = log.wrappedActivityType
            let left = actType == .breastfeeding ? "\(log.leftDuration)" : ""
            let right = actType == .breastfeeding ? "\(log.rightDuration)" : ""
            let volume = actType == .formula ? "\(log.volumeML)" : ""
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
