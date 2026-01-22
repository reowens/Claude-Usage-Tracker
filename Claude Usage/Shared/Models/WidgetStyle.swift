//
//  WidgetStyle.swift
//  Claude Usage
//
//  Widget appearance style options
//

import Foundation

/// Widget appearance style
enum WidgetStyle: String, Codable, CaseIterable {
    /// Standard opaque background
    case standard = "standard"

    /// Glass/translucent style with vibrancy
    case glass = "glass"

    var displayName: String {
        switch self {
        case .standard:
            return "Standard"
        case .glass:
            return "Glass"
        }
    }

    var description: String {
        switch self {
        case .standard:
            return "Classic solid background"
        case .glass:
            return "Translucent with desktop blur"
        }
    }
}

// MARK: - Small Widget Metric

/// Small widget metric selection - determines which single metric is displayed
enum SmallWidgetMetric: String, Codable, CaseIterable {
    case session = "session"
    case weekly = "weekly"
    case opus = "opus"
    case sonnet = "sonnet"

    var displayName: String {
        switch self {
        case .session:
            return "Session"
        case .weekly:
            return "Weekly"
        case .opus:
            return "Opus"
        case .sonnet:
            return "Sonnet"
        }
    }

    var icon: String {
        switch self {
        case .session:
            return "clock.fill"
        case .weekly:
            return "calendar"
        case .opus:
            return "star.fill"
        case .sonnet:
            return "bolt.fill"
        }
    }
}

// MARK: - Medium Widget Layout

/// Medium widget metric pair selection - determines which two metrics are displayed side by side
enum MediumWidgetLayout: String, Codable, CaseIterable {
    case sessionWeekly = "session_weekly"
    case sessionOpus = "session_opus"
    case sessionSonnet = "session_sonnet"
    case weeklyOpus = "weekly_opus"
    case weeklySonnet = "weekly_sonnet"
    case opusSonnet = "opus_sonnet"

    var displayName: String {
        switch self {
        case .sessionWeekly:
            return "Session + Weekly"
        case .sessionOpus:
            return "Session + Opus"
        case .sessionSonnet:
            return "Session + Sonnet"
        case .weeklyOpus:
            return "Weekly + Opus"
        case .weeklySonnet:
            return "Weekly + Sonnet"
        case .opusSonnet:
            return "Opus + Sonnet"
        }
    }

    var leftMetric: SmallWidgetMetric {
        switch self {
        case .sessionWeekly, .sessionOpus, .sessionSonnet:
            return .session
        case .weeklyOpus, .weeklySonnet:
            return .weekly
        case .opusSonnet:
            return .opus
        }
    }

    var rightMetric: SmallWidgetMetric {
        switch self {
        case .sessionWeekly:
            return .weekly
        case .sessionOpus, .weeklyOpus:
            return .opus
        case .sessionSonnet, .weeklySonnet, .opusSonnet:
            return .sonnet
        }
    }
}
