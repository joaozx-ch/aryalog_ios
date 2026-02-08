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

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .breastfeeding:
            return "Breastfeeding"
        case .formula:
            return "Formula"
        }
    }

    var icon: String {
        switch self {
        case .breastfeeding:
            return "drop.fill"
        case .formula:
            return "cup.and.saucer.fill"
        }
    }

    var color: Color {
        switch self {
        case .breastfeeding:
            return .pink
        case .formula:
            return .blue
        }
    }

    var description: String {
        switch self {
        case .breastfeeding:
            return "Track breastfeeding sessions with left and right side durations"
        case .formula:
            return "Track formula feeding with volume in mL"
        }
    }
}
