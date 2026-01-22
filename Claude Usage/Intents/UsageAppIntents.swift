//
//  UsageAppIntents.swift
//  Claude Usage
//
//  App Intents for Control Center integration (macOS 26+) and Shortcuts
//

import AppIntents
import SwiftUI

// MARK: - View Usage Intent

/// Shows current Claude usage in a dialog or returns it for Shortcuts
@available(macOS 14.0, *)
struct ViewUsageIntent: AppIntent {
    static var title: LocalizedStringResource = "View Claude Usage"
    static var description = IntentDescription("Shows your current Claude AI usage statistics")

    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let usage = await loadCurrentUsage()

        if let usage = usage {
            let message = """
            Session: \(Int(usage.sessionPercentage))%
            Weekly: \(Int(usage.weeklyPercentage))%
            Opus: \(Int(usage.opusPercentage))%
            """
            return .result(dialog: IntentDialog(stringLiteral: message))
        } else {
            return .result(dialog: "No usage data available. Open Claude Usage app to sync.")
        }
    }

    private func loadCurrentUsage() async -> UsageSnapshot? {
        await MainActor.run {
            guard let defaults = UserDefaults(suiteName: "group.claude-usage"),
                  let data = defaults.data(forKey: "claudeUsageData") else {
                return nil
            }

            do {
                let decoder = JSONDecoder()
                let usage = try decoder.decode(IntentUsageData.self, from: data)
                return UsageSnapshot(
                    sessionPercentage: usage.sessionPercentage,
                    weeklyPercentage: usage.weeklyPercentage,
                    opusPercentage: usage.opusWeeklyPercentage
                )
            } catch {
                return nil
            }
        }
    }
}

// MARK: - Refresh Usage Intent

/// Triggers a usage data refresh
@available(macOS 14.0, *)
struct RefreshUsageIntent: AppIntent {
    static var title: LocalizedStringResource = "Refresh Claude Usage"
    static var description = IntentDescription("Refreshes your Claude AI usage data from the server")

    static var openAppWhenRun: Bool = true  // Opens app to trigger refresh

    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Post notification to trigger refresh in main app
        await MainActor.run {
            NotificationCenter.default.post(name: .refreshUsageFromIntent, object: nil)
        }

        return .result(dialog: "Refreshing usage data...")
    }
}

// MARK: - Open Settings Intent

/// Opens the Claude Usage settings window
@available(macOS 14.0, *)
struct OpenSettingsIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Claude Usage Settings"
    static var description = IntentDescription("Opens the Claude Usage settings window")

    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            NotificationCenter.default.post(name: .openSettingsFromIntent, object: nil)
        }

        return .result()
    }
}

// MARK: - Quick Check Intent (Control Center optimized)

/// Quick usage check optimized for Control Center display
@available(macOS 14.0, *)
struct QuickUsageCheckIntent: AppIntent {
    static var title: LocalizedStringResource = "Claude Usage Quick Check"
    static var description = IntentDescription("Quick check of your Claude session usage")

    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let usage = await loadSessionUsage()

        if let percentage = usage {
            let emoji = percentage < 50 ? "🟢" : (percentage < 80 ? "🟡" : "🔴")
            return .result(dialog: IntentDialog(stringLiteral: "\(emoji) Session: \(Int(percentage))%"))
        } else {
            return .result(dialog: "⚪ No data")
        }
    }

    private func loadSessionUsage() async -> Double? {
        await MainActor.run {
            guard let defaults = UserDefaults(suiteName: "group.claude-usage"),
                  let data = defaults.data(forKey: "claudeUsageData") else {
                return nil
            }

            do {
                let decoder = JSONDecoder()
                let usage = try decoder.decode(IntentUsageData.self, from: data)
                return usage.sessionPercentage
            } catch {
                return nil
            }
        }
    }
}

// MARK: - Supporting Types

struct UsageSnapshot {
    let sessionPercentage: Double
    let weeklyPercentage: Double
    let opusPercentage: Double
}

/// Minimal usage data for intent decoding
private struct IntentUsageData: Codable, Sendable {
    let sessionPercentage: Double
    let weeklyPercentage: Double
    let opusWeeklyPercentage: Double
}

// MARK: - Notification Names

extension Notification.Name {
    static let refreshUsageFromIntent = Notification.Name("refreshUsageFromIntent")
    static let openSettingsFromIntent = Notification.Name("openSettingsFromIntent")
}
