//
//  AppShortcuts.swift
//  Claude Usage
//
//  Shortcuts integration for Claude Usage app
//

import AppIntents

@available(macOS 14.0, *)
struct ClaudeUsageShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ViewUsageIntent(),
            phrases: [
                "Show my \(.applicationName) usage",
                "Check \(.applicationName)",
                "How much \(.applicationName) have I used",
                "\(.applicationName) usage status"
            ],
            shortTitle: "View Usage",
            systemImageName: "chart.bar.fill"
        )

        AppShortcut(
            intent: RefreshUsageIntent(),
            phrases: [
                "Refresh \(.applicationName)",
                "Update \(.applicationName) usage",
                "Sync \(.applicationName)"
            ],
            shortTitle: "Refresh",
            systemImageName: "arrow.clockwise"
        )

        AppShortcut(
            intent: QuickUsageCheckIntent(),
            phrases: [
                "Quick \(.applicationName) check",
                "\(.applicationName) session status"
            ],
            shortTitle: "Quick Check",
            systemImageName: "bolt.fill"
        )
    }
}
