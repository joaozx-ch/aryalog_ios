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
        case .breastfeeding: return "Breastfeeding"
        case .formula: return "Formula"
        case .sleep: return "Sleep"
        case .wakeUp: return "Wake Up"
        case .pee: return "Pee"
        case .poop: return "Poop"
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
        case .breastfeeding: return "Track breastfeeding sessions with left and right side durations"
        case .formula: return "Track formula feeding with volume in mL"
        case .sleep: return "Record when baby falls asleep"
        case .wakeUp: return "Record when baby wakes up"
        case .pee: return "Record a pee diaper change"
        case .poop: return "Record a poop diaper change"
        }
    }

    var isSimpleEvent: Bool {
        switch self {
        case .sleep, .wakeUp, .pee, .poop: return true
        default: return false
        }
    }
}
