//
//  HomeView.swift
//  AryaLog
//
//  Main screen with quick-add buttons and recent activity
//

import SwiftUI
import CoreData

struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: HomeViewModel
    @State private var showingBreastfeedingForm = false
    @State private var showingFormulaForm = false
    @State private var showingSimpleEventType: ActivityType?

    init() {
        // Initialize with a temporary context, will be replaced in onAppear
        _viewModel = StateObject(wrappedValue: HomeViewModel(context: PersistenceController.shared.container.viewContext))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Quick Stats Card
                    quickStatsCard

                    // Quick Add Buttons
                    quickAddSection

                    // Recent Activity
                    recentActivitySection
                }
                .padding()
            }
            .navigationTitle("AryaLog")
            .refreshable {
                viewModel.refresh()
            }
            .sheet(isPresented: $showingBreastfeedingForm) {
                BreastfeedingFormView {
                    viewModel.refresh()
                }
            }
            .sheet(isPresented: $showingFormulaForm) {
                FormulaFormView {
                    viewModel.refresh()
                }
            }
            .sheet(item: $showingSimpleEventType) { type in
                SimpleEventFormView(activityType: type) {
                    viewModel.refresh()
                }
            }
            .onAppear {
                viewModel.refresh()
            }
        }
    }

    private var quickStatsCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Today's Summary")
                    .font(.headline)
                Spacer()
                Text(viewModel.timeSinceLastLog)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                StatBox(
                    icon: "drop.fill",
                    value: "\(viewModel.todayBreastfeedingMinutes)m",
                    label: "Breastfeeding",
                    color: .pink
                )

                StatBox(
                    icon: "cup.and.saucer.fill",
                    value: "\(viewModel.todayFormulaML) mL",
                    label: "Formula",
                    color: .blue
                )

                StatBox(
                    icon: "moon.fill",
                    value: "\(viewModel.todaySleepCount)",
                    label: "Sleeps",
                    color: .indigo
                )

                StatBox(
                    icon: "drop.triangle.fill",
                    value: "\(viewModel.todayDiaperCount)",
                    label: "Diapers",
                    color: .yellow
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }

    private var quickAddSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Add")
                .font(.headline)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                QuickAddButton(
                    title: "Breast",
                    icon: "drop.fill",
                    color: .pink
                ) {
                    showingBreastfeedingForm = true
                }

                QuickAddButton(
                    title: "Formula",
                    icon: "cup.and.saucer.fill",
                    color: .blue
                ) {
                    showingFormulaForm = true
                }

                QuickAddButton(
                    title: "Sleep",
                    icon: "moon.fill",
                    color: .indigo
                ) {
                    showingSimpleEventType = .sleep
                }

                QuickAddButton(
                    title: "Wake Up",
                    icon: "sun.max.fill",
                    color: .orange
                ) {
                    showingSimpleEventType = .wakeUp
                }

                QuickAddButton(
                    title: "Pee",
                    icon: "drop.triangle.fill",
                    color: .yellow
                ) {
                    showingSimpleEventType = .pee
                }

                QuickAddButton(
                    title: "Poop",
                    icon: "leaf.fill",
                    color: .brown
                ) {
                    showingSimpleEventType = .poop
                }
            }
        }
    }

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Activity")
                    .font(.headline)
                Spacer()
                NavigationLink(destination: TimelineView()) {
                    Text("See All")
                        .font(.subheadline)
                        .foregroundStyle(.pink)
                }
            }

            if viewModel.recentLogs.isEmpty {
                EmptyStateView(
                    icon: "tray",
                    message: "No logs yet",
                    submessage: "Tap a button above to add your first entry"
                )
            } else {
                ForEach(viewModel.recentLogs) { log in
                    FeedingLogRow(log: log)
                }
            }
        }
    }
}

struct StatBox: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
            }
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct QuickAddButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .foregroundStyle(.white)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

struct FeedingLogRow: View {
    let log: FeedingLog

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: log.wrappedActivityType.icon)
                .font(.title2)
                .foregroundStyle(log.wrappedActivityType.color)
                .frame(width: 44, height: 44)
                .background(log.wrappedActivityType.color.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(log.wrappedActivityType.displayName)
                    .font(.headline)
                Text(log.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(log.wrappedStartTime, style: .time)
                    .font(.subheadline)
                if let caregiver = log.caregiver {
                    Text(caregiver.wrappedName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 1)
    }
}

struct EmptyStateView: View {
    let icon: String
    let message: String
    let submessage: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text(message)
                .font(.headline)
            Text(submessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}

#Preview {
    HomeView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
