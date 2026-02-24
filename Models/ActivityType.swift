//
//  ActivityType.swift
//  AryaLog
//
//  Activity type enum for feeding logs
//

import SwiftUI

enum ActivityType: String, CaseIterable, Identifiable {
    case breastfeeding = "breastfeeding"
    case formula = "formula"
    case sleep = "sleep"
    case wakeUp = "wakeUp"
    case pee = "pee"
    case poop = "poop"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .breastfeeding: return String(localized: "activity.breastfeeding", defaultValue: "Breastfeeding")
        case .formula:       return String(localized: "activity.formula",       defaultValue: "Formula")
        case .sleep:         return String(localized: "activity.sleep",         defaultValue: "Sleep")
        case .wakeUp:        return String(localized: "activity.wakeUp",        defaultValue: "Wake Up")
        case .pee:           return String(localized: "activity.pee",           defaultValue: "Pee")
        case .poop:          return String(localized: "activity.poop",          defaultValue: "Poop")
        }
    }

    var icon: String {
        switch self {
        case .breastfeeding: return "drop.fill"
        case .formula: return "cup.and.saucer.fill"
        case .sleep: return "moon.fill"
        case .wakeUp: return "sun.max.fill"
        case .pee: return "drop.triangle.fill"
        case .poop: return "leaf.fill"
        }
    }

    var color: Color {
        switch self {
        case .breastfeeding: return .pink
        case .formula: return .blue
        case .sleep: return .indigo
        case .wakeUp: return .orange
        case .pee: return .yellow
        case .poop: return .brown
        }
    }

    var description: String {
        switch self {
        case .breastfeeding: return String(localized: "activity.desc.breastfeeding", defaultValue: "Track breastfeeding sessions with left and right side durations")
        case .formula:       return String(localized: "activity.desc.formula",       defaultValue: "Track formula feeding with volume in mL")
        case .sleep:         return String(localized: "activity.desc.sleep",         defaultValue: "Record when baby falls asleep")
        case .wakeUp:        return String(localized: "activity.desc.wakeUp",        defaultValue: "Record when baby wakes up")
        case .pee:           return String(localized: "activity.desc.pee",           defaultValue: "Record a pee diaper change")
        case .poop:          return String(localized: "activity.desc.poop",          defaultValue: "Record a poop diaper change")
        }
    }

    var isSimpleEvent: Bool {
        switch self {
        case .sleep, .wakeUp, .pee, .poop: return true
        default: return false
        }
    }
}
