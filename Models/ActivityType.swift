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
    case expressedBreastMilk = "expressedBreastMilk"
    case pumping = "pumping"
    case sleep = "sleep"
    case wakeUp = "wakeUp"
    case pee = "pee"
    case poop = "poop"
    case peePoop = "peePoop"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .breastfeeding:      return String(localized: "activity.breastfeeding",      defaultValue: "Breastfeeding")
        case .formula:            return String(localized: "activity.formula",             defaultValue: "Formula")
        case .expressedBreastMilk:return String(localized: "activity.ebm",                defaultValue: "Expressed Breast Milk")
        case .pumping:            return String(localized: "activity.pumping",             defaultValue: "Pumping")
        case .sleep:              return String(localized: "activity.sleep",               defaultValue: "Sleep")
        case .wakeUp:             return String(localized: "activity.wakeUp",              defaultValue: "Wake Up")
        case .pee:                return String(localized: "activity.pee",                 defaultValue: "Pee")
        case .poop:               return String(localized: "activity.poop",                defaultValue: "Poop")
        case .peePoop:            return String(localized: "activity.peePoop",             defaultValue: "Pee & Poop")
        }
    }

    var icon: String {
        switch self {
        case .breastfeeding:       return "drop.fill"
        case .formula:             return "cup.and.saucer.fill"
        case .expressedBreastMilk: return "drop.fill"
        case .pumping:             return "arrow.up.heart.fill"
        case .sleep:               return "moon.fill"
        case .wakeUp:              return "sun.max.fill"
        case .pee:                 return "drop.triangle.fill"
        case .poop:                return "leaf.fill"
        case .peePoop:             return "drop.triangle.fill"
        }
    }

    var color: Color {
        switch self {
        case .breastfeeding:       return .pink
        case .formula:             return .blue
        case .expressedBreastMilk: return .cyan
        case .pumping:             return .purple
        case .sleep:               return .indigo
        case .wakeUp:              return .orange
        case .pee:                 return .yellow
        case .poop:                return .brown
        case .peePoop:             return .teal
        }
    }

    var description: String {
        switch self {
        case .breastfeeding:       return String(localized: "activity.desc.breastfeeding", defaultValue: "Track breastfeeding sessions with left and right side durations")
        case .formula:             return String(localized: "activity.desc.formula",        defaultValue: "Track formula feeding with volume in mL")
        case .expressedBreastMilk: return String(localized: "activity.desc.ebm",           defaultValue: "Track expressed breast milk feeding with volume in mL")
        case .pumping:             return String(localized: "activity.desc.pumping",        defaultValue: "Record breast milk pumping with volume in mL")
        case .sleep:               return String(localized: "activity.desc.sleep",          defaultValue: "Record when baby falls asleep")
        case .wakeUp:              return String(localized: "activity.desc.wakeUp",         defaultValue: "Record when baby wakes up")
        case .pee:                 return String(localized: "activity.desc.pee",            defaultValue: "Record a pee diaper change")
        case .poop:                return String(localized: "activity.desc.poop",           defaultValue: "Record a poop diaper change")
        case .peePoop:             return String(localized: "activity.desc.peePoop",        defaultValue: "Record a diaper change with both pee and poop")
        }
    }

    var isSimpleEvent: Bool {
        switch self {
        case .sleep, .wakeUp, .pee, .poop, .peePoop: return true
        default: return false
        }
    }
}
