//
//  AryaLogApp.swift
//  AryaLog
//
//  iOS Childcare Record-Keeping App
//

import SwiftUI
import CoreData
import CloudKit

// MARK: - App Delegate

/// Handles system-level events that cannot be intercepted in SwiftUI,
/// most importantly accepting incoming CloudKit share invitations.
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShareMetadata
    ) {
        PersistenceController.shared.acceptShareInvitations(from: [cloudKitShareMetadata])
    }
}

// MARK: - App

@main
struct AryaLogApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    let persistenceController = PersistenceController.shared

    init() {
        let savedLanguage = UserDefaults.standard.string(forKey: "selectedLanguage") ?? ""
        if !savedLanguage.isEmpty {
            UserDefaults.standard.set([savedLanguage], forKey: "AppleLanguages")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

// MARK: - Content View

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @AppStorage("hasCompletedSetup") private var hasCompletedSetup = false
    @AppStorage("currentCaregiverID") private var currentCaregiverID: String = ""

    var body: some View {
        if hasCompletedSetup {
            MainTabView()
        } else {
            SetupView(hasCompletedSetup: $hasCompletedSetup, currentCaregiverID: $currentCaregiverID)
        }
    }
}

// MARK: - Setup View

struct SetupView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var hasCompletedSetup: Bool
    @Binding var currentCaregiverID: String
    @State private var caregiverName = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "heart.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.pink)

                Text("Welcome to AryaLog")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Track your baby's care activities")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Name")
                        .font(.headline)

                    TextField("Enter your name", text: $caregiverName)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.name)
                }
                .padding(.horizontal, 32)
                .padding(.top, 32)

                Spacer()

                Button(action: createCaregiver) {
                    Text("Get Started")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(caregiverName.isEmpty ? Color.gray : Color.pink)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(caregiverName.isEmpty)
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
        }
    }

    private func createCaregiver() {
        let caregiver = Caregiver(context: viewContext)
        caregiver.id = UUID()
        caregiver.name = caregiverName.trimmingCharacters(in: .whitespacesAndNewlines)
        caregiver.isCurrentUser = true
        caregiver.createdAt = Date()

        do {
            try viewContext.save()
            currentCaregiverID = caregiver.id?.uuidString ?? ""
            hasCompletedSetup = true
        } catch {
            print("Failed to save caregiver: \(error)")
        }
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    var body: some View {
        TabView {
            TimelineView()
                .tabItem {
                    Label("Timeline", systemImage: "list.bullet")
                }

            StatsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .tint(.pink)
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
