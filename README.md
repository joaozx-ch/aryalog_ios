# AryaLog

A baby care tracking app for iOS built with SwiftUI, Core Data, and CloudKit. Log breastfeeding sessions and formula feedings, view statistics, and sync data across devices and caregivers via iCloud.

## Features

- **Breastfeeding tracking** — Log left/right side durations with quick-select presets and fine-tune controls
- **Formula tracking** — Log volume in mL with preset amounts and a slider for precise entry
- **Event timeline** — Vertical time-axis visualization showing feeding events plotted at their actual times throughout the day
- **Statistics & charts** — Daily and weekly summaries with bar charts for breastfeeding minutes and formula volume (powered by Swift Charts)
- **Multi-caregiver support** — Multiple caregivers can share and contribute to the same feeding log
- **CloudKit sync** — Data syncs automatically across devices signed into the same iCloud account, with sharing support for different Apple IDs
- **CSV export** — Export all feeding data as a CSV file for external use

## Screenshots

*Add screenshots here*

## Requirements

- iOS 18.0+
- Xcode 16+
- Apple Developer account (for CloudKit features)

## Getting Started

1. Clone the repository:
   ```bash
   git clone https://github.com/your-username/AryaLog.git
   cd AryaLog
   ```

2. Open the project in Xcode:
   ```bash
   open AryaLog.xcodeproj
   ```

3. Select your development team in **Signing & Capabilities**.

4. Build and run on a simulator or device.

On first launch, you'll be prompted to enter your name as the primary caregiver. After setup, the app opens to the Home tab.

## Architecture

```
AryaLog/
├── AryaLogApp.swift              # App entry point, setup flow, tab navigation
├── Models/
│   ├── ActivityType.swift         # Breastfeeding / Formula enum
│   ├── Caregiver+CoreData.swift   # Caregiver entity helpers & fetch requests
│   ├── FeedingLog+CoreData.swift  # FeedingLog entity helpers & statistics
│   └── AryaLog.xcdatamodeld      # Core Data model
├── Services/
│   ├── PersistenceController.swift # Core Data + CloudKit stack
│   └── ShareController.swift       # CloudKit sharing logic
├── ViewModels/
│   ├── HomeViewModel.swift         # Home screen data
│   └── StatsViewModel.swift        # Statistics & chart data
└── Views/
    ├── HomeView.swift              # Dashboard with quick-add and recent activity
    ├── TimelineView.swift          # Vertical event timeline visualization
    ├── StatsView.swift             # Charts and daily/weekly summaries
    ├── SettingsView.swift          # Profile, caregivers, export, sharing guide
    ├── BreastfeedingFormView.swift  # Breastfeeding entry form
    └── FormulaFormView.swift        # Formula entry form
```

### Data Model

| Entity | Key Attributes |
|--------|---------------|
| **Caregiver** | `id` (UUID), `name` (String), `isCurrentUser` (Bool), `createdAt` (Date) |
| **FeedingLog** | `id` (UUID), `activityType` (String), `startTime` (Date), `leftDuration` (Int16), `rightDuration` (Int16), `volumeML` (Int16), `notes` (String) |

A Caregiver has many FeedingLogs (cascade delete). A FeedingLog belongs to one Caregiver (nullify on delete).

### CloudKit Integration

The app uses `NSPersistentCloudKitContainer` to sync Core Data with iCloud automatically. Configuration:

- **Container ID:** `iCloud.com.AryaLog.AryaLog`
- **Background mode:** Remote notifications (for silent push sync)
- **Merge policy:** Property-level object trump (last write wins per field)
- **History tracking:** Enabled for conflict resolution

## App Tabs

| Tab | Description |
|-----|-------------|
| **Home** | Today's summary (breastfeeding minutes, formula mL, time since last feeding), quick-add buttons, recent activity feed |
| **Timeline** | Vertical time-axis with events plotted at their actual times, date picker to browse days, tap to edit, long-press to delete |
| **Stats** | Date picker, daily stats, weekly bar charts for breastfeeding and formula, weekly totals |
| **Settings** | Edit profile, manage caregivers, CloudKit sharing guide, CSV data export, app info |

## License

*Add license here*
