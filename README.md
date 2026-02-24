# AryaLog

A baby care tracking app for iOS built with SwiftUI, Core Data, and CloudKit. Log feeding sessions, pumping, sleep, and diaper changes, view statistics, and sync data across devices and caregivers via iCloud.

## Features

- **Breastfeeding tracking** — Log left/right side durations with quick-select presets and fine-tune controls
- **Formula tracking** — Log volume in mL with preset amounts and a slider for precise entry
- **Expressed breast milk (EBM) tracking** — Log volume fed to baby from pumped/stored milk
- **Pumping tracking** — Log the volume of breast milk pumped by mom
- **Sleep & wake tracking** — Record sleep and wake-up events with warnings for overlapping sleep sessions
- **Diaper tracking** — Log pee, poop, or combined pee & poop diaper changes
- **Event timeline** — Vertical time-axis visualization showing all events plotted at their actual times throughout the day, with time-gap indicators
- **Statistics & charts** — Daily and weekly summaries with bar charts for all activity types (powered by Swift Charts)
- **Multi-caregiver support** — Multiple caregivers can share and contribute to the same care log
- **CloudKit sync** — Data syncs automatically across devices signed into the same iCloud account, with sharing support for different Apple IDs
- **Simplified Chinese support** — Full zh-Hans localization with an in-app language picker
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

On first launch, you'll be prompted to enter your name as the primary caregiver. After setup, the app opens to the Timeline tab.

## Architecture

```
AryaLog/
├── AryaLogApp.swift              # App entry point, setup flow, tab navigation
├── Localizable.xcstrings         # String catalog (en + zh-Hans)
├── Models/
│   ├── ActivityType.swift         # Activity type enum (breastfeeding, formula, EBM, pumping, sleep, wakeUp, pee, poop, peePoop)
│   ├── Caregiver+CoreData.swift   # Caregiver entity helpers & fetch requests
│   ├── FeedingLog+CoreData.swift  # FeedingLog entity helpers & statistics
│   └── AryaLog.xcdatamodeld      # Core Data model
├── Services/
│   ├── PersistenceController.swift # Core Data + CloudKit stack
│   └── ShareController.swift       # CloudKit sharing logic
├── ViewModels/
│   ├── HomeViewModel.swift         # Home screen data (unused tab, kept for reference)
│   └── StatsViewModel.swift        # Statistics & chart data
└── Views/
    ├── TimelineView.swift          # Vertical event timeline visualization
    ├── StatsView.swift             # Charts and daily/weekly summaries
    ├── SettingsView.swift          # Profile, caregivers, language, export, sharing guide
    ├── BreastfeedingFormView.swift  # Breastfeeding entry form
    ├── FormulaFormView.swift        # Formula entry form
    ├── EBMFormView.swift            # Expressed breast milk entry form
    ├── PumpingFormView.swift        # Pumping entry form
    └── SimpleEventFormView.swift    # Simple event form (sleep, wake, pee, poop, pee & poop)
```

### Data Model

| Entity | Key Attributes |
|--------|---------------|
| **Caregiver** | `id` (UUID), `name` (String), `isCurrentUser` (Bool), `createdAt` (Date) |
| **FeedingLog** | `id` (UUID), `activityType` (String), `startTime` (Date), `leftDuration` (Int16), `rightDuration` (Int16), `volumeML` (Int16), `notes` (String) |

A Caregiver has many FeedingLogs (cascade delete). A FeedingLog belongs to one Caregiver (nullify on delete).

`volumeML` is used by formula, EBM, and pumping activity types. `leftDuration` / `rightDuration` are used by breastfeeding.

### CloudKit Integration

The app uses `NSPersistentCloudKitContainer` to sync Core Data with iCloud automatically. Configuration:

- **Container ID:** `iCloud.com.AryaLog.AryaLog`
- **Background mode:** Remote notifications (for silent push sync)
- **Merge policy:** Property-level object trump (last write wins per field)
- **History tracking:** Enabled for conflict resolution

### Localization

The app ships with English (source language) and Simplified Chinese (zh-Hans). All user-facing strings are stored in `Localizable.xcstrings` (Xcode string catalog format). The language can be changed inside the app via **Settings → Language** without leaving the app (requires restart to apply).

## App Tabs

| Tab | Description |
|-----|-------------|
| **Timeline** | Vertical time-axis with all events plotted at their actual times, date picker to browse days, time-gap indicators, tap to edit, long-press to delete |
| **Stats** | Date picker, daily stats grid, weekly bar charts for all activity types, weekly totals |
| **Settings** | Edit profile, manage caregivers, language selection, CloudKit sharing guide, CSV data export, app info |

## License

*Add license here*
