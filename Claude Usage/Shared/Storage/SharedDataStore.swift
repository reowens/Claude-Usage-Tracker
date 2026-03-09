//
//  SharedDataStore.swift
//  Claude Usage
//
//  Created by Claude Code on 2026-01-10.
//

import Foundation

/// Manages app-wide settings that are shared across all profiles
class SharedDataStore {
    static let shared = SharedDataStore()

    private let defaults: UserDefaults

    private enum Keys {
        // Language & Localization
        static let languageCode = "selectedLanguageCode"

        // Statusline Configuration
        static let statuslineShowModel = "statuslineShowModel"
        static let statuslineShowDirectory = "statuslineShowDirectory"
        static let statuslineShowBranch = "statuslineShowBranch"
        static let statuslineShowContext = "statuslineShowContext"
        static let statuslineContextAsTokens = "statuslineContextAsTokens"
        static let statuslineShowUsage = "statuslineShowUsage"
        static let statuslineShowProgressBar = "statuslineShowProgressBar"
        static let statuslineShowPaceMarker = "statuslineShowPaceMarker"
        static let statuslineShowResetTime = "statuslineShowResetTime"
        static let statuslineUse24HourTime = "statuslineUse24HourTime"
        static let statuslineShowUsageLabel = "statuslineShowUsageLabel"
        static let statuslineShowResetLabel = "statuslineShowResetLabel"
        static let statuslineColorMode = "statuslineColorMode"
        static let statuslineSingleColorHex = "statuslineSingleColorHex"
        static let statuslineShowProfile = "statuslineShowProfile"

        // Widget Settings
        static let smallWidgetMetric = "smallWidgetMetric"
        static let mediumWidgetLeftMetric = "mediumWidgetLeftMetric"
        static let mediumWidgetRightMetric = "mediumWidgetRightMetric"
        static let widgetColorMode = "widgetColorMode"
        static let widgetSingleColorHex = "widgetSingleColorHex"
        static let extraUsageDisplayFormat = "extraUsageDisplayFormat"

        // Setup State
        static let hasCompletedSetup = "hasCompletedSetup"
        static let hasShownWizardOnce = "hasShownWizardOnce"

        // GitHub Star Tracking
        static let firstLaunchDate = "firstLaunchDate"
        static let lastGitHubStarPromptDate = "lastGitHubStarPromptDate"
        static let hasStarredGitHub = "hasStarredGitHub"
        static let neverShowGitHubPrompt = "neverShowGitHubPrompt"

        // Feedback Prompt Tracking
        static let lastFeedbackPromptDate = "lastFeedbackPromptDate"
        static let hasSubmittedFeedback = "hasSubmittedFeedback"
        static let neverShowFeedbackPrompt = "neverShowFeedbackPrompt"

        // Debug Settings
        static let debugAPILoggingEnabled = "debugAPILoggingEnabled"

        // Keyboard Shortcuts
        static let shortcutTogglePopover = "shortcutTogglePopover"
        static let shortcutRefresh = "shortcutRefresh"
        static let shortcutOpenSettings = "shortcutOpenSettings"
        static let shortcutNextProfile = "shortcutNextProfile"

        // Auto-Switch Profile
        static let autoSwitchProfileEnabled = "autoSwitchProfileEnabled"
    }

    init() {
        // Use App Groups UserDefaults for sharing data with widgets
        if let groupDefaults = UserDefaults(suiteName: Constants.appGroupIdentifier) {
            self.defaults = groupDefaults
            LoggingService.shared.log("SharedDataStore: Using App Groups shared container")
        } else {
            self.defaults = UserDefaults.standard
            LoggingService.shared.log("SharedDataStore: Fallback to standard app container (App Groups unavailable)")
        }
    }

    // MARK: - Language & Localization

    func saveLanguageCode(_ code: String) {
        defaults.set(code, forKey: Keys.languageCode)
    }

    func loadLanguageCode() -> String? {
        return defaults.string(forKey: Keys.languageCode)
    }

    // MARK: - Statusline Configuration

    func saveStatuslineShowModel(_ show: Bool) {
        defaults.set(show, forKey: Keys.statuslineShowModel)
    }

    func loadStatuslineShowModel() -> Bool {
        if defaults.object(forKey: Keys.statuslineShowModel) == nil {
            return true  // Default to true (checked)
        }
        return defaults.bool(forKey: Keys.statuslineShowModel)
    }

    func saveStatuslineShowDirectory(_ show: Bool) {
        defaults.set(show, forKey: Keys.statuslineShowDirectory)
    }

    func loadStatuslineShowDirectory() -> Bool {
        if defaults.object(forKey: Keys.statuslineShowDirectory) == nil {
            return true
        }
        return defaults.bool(forKey: Keys.statuslineShowDirectory)
    }

    func saveStatuslineShowBranch(_ show: Bool) {
        defaults.set(show, forKey: Keys.statuslineShowBranch)
    }

    func loadStatuslineShowBranch() -> Bool {
        if defaults.object(forKey: Keys.statuslineShowBranch) == nil {
            return true
        }
        return defaults.bool(forKey: Keys.statuslineShowBranch)
    }

    func saveStatuslineShowUsage(_ show: Bool) {
        defaults.set(show, forKey: Keys.statuslineShowUsage)
    }

    func loadStatuslineShowUsage() -> Bool {
        if defaults.object(forKey: Keys.statuslineShowUsage) == nil {
            return true
        }
        return defaults.bool(forKey: Keys.statuslineShowUsage)
    }

    func saveStatuslineShowProgressBar(_ show: Bool) {
        defaults.set(show, forKey: Keys.statuslineShowProgressBar)
    }

    func loadStatuslineShowProgressBar() -> Bool {
        if defaults.object(forKey: Keys.statuslineShowProgressBar) == nil {
            return true
        }
        return defaults.bool(forKey: Keys.statuslineShowProgressBar)
    }

    func saveStatuslineShowPaceMarker(_ show: Bool) {
        defaults.set(show, forKey: Keys.statuslineShowPaceMarker)
    }

    func loadStatuslineShowPaceMarker() -> Bool {
        if defaults.object(forKey: Keys.statuslineShowPaceMarker) == nil {
            return true
        }
        return defaults.bool(forKey: Keys.statuslineShowPaceMarker)
    }

    func saveStatuslineShowResetTime(_ show: Bool) {
        defaults.set(show, forKey: Keys.statuslineShowResetTime)
    }

    func loadStatuslineShowResetTime() -> Bool {
        if defaults.object(forKey: Keys.statuslineShowResetTime) == nil {
            return true
        }
        return defaults.bool(forKey: Keys.statuslineShowResetTime)
    }

    func saveStatuslineUse24HourTime(_ use24Hour: Bool) {
        defaults.set(use24Hour, forKey: Keys.statuslineUse24HourTime)
    }

    func loadStatuslineUse24HourTime() -> Bool {
        if defaults.object(forKey: Keys.statuslineUse24HourTime) == nil {
            return false  // Default to 12-hour (matches system default)
        }
        return defaults.bool(forKey: Keys.statuslineUse24HourTime)
    }

    func saveStatuslineShowUsageLabel(_ show: Bool) {
        defaults.set(show, forKey: Keys.statuslineShowUsageLabel)
    }

    func loadStatuslineShowUsageLabel() -> Bool {
        if defaults.object(forKey: Keys.statuslineShowUsageLabel) == nil {
            return true  // Default to showing labels
        }
        return defaults.bool(forKey: Keys.statuslineShowUsageLabel)
    }

    func saveStatuslineShowResetLabel(_ show: Bool) {
        defaults.set(show, forKey: Keys.statuslineShowResetLabel)
    }

    func loadStatuslineShowResetLabel() -> Bool {
        if defaults.object(forKey: Keys.statuslineShowResetLabel) == nil {
            return true  // Default to showing labels
        }
        return defaults.bool(forKey: Keys.statuslineShowResetLabel)
    }

    func saveStatuslineColorMode(_ mode: StatuslineColorMode) {
        defaults.set(mode.rawValue, forKey: Keys.statuslineColorMode)
    }

    func loadStatuslineColorMode() -> StatuslineColorMode {
        guard let rawValue = defaults.string(forKey: Keys.statuslineColorMode),
              let mode = StatuslineColorMode(rawValue: rawValue) else {
            return .colored  // Default to colored
        }
        return mode
    }

    func saveStatuslineSingleColorHex(_ hex: String) {
        defaults.set(hex, forKey: Keys.statuslineSingleColorHex)
    }

    func loadStatuslineSingleColorHex() -> String {
        return defaults.string(forKey: Keys.statuslineSingleColorHex) ?? "#00BFFF"  // Default cyan
    }

    func saveStatuslineShowContext(_ show: Bool) {
        defaults.set(show, forKey: Keys.statuslineShowContext)
    }

    func loadStatuslineShowContext() -> Bool {
        if defaults.object(forKey: Keys.statuslineShowContext) == nil {
            return true  // Default to true (checked)
        }
        return defaults.bool(forKey: Keys.statuslineShowContext)
    }

    func saveStatuslineContextAsTokens(_ asTokens: Bool) {
        defaults.set(asTokens, forKey: Keys.statuslineContextAsTokens)
    }

    func loadStatuslineContextAsTokens() -> Bool {
        if defaults.object(forKey: Keys.statuslineContextAsTokens) == nil {
            return false  // Default to false (percentage)
        }
        return defaults.bool(forKey: Keys.statuslineContextAsTokens)
    }

    func saveStatuslineShowProfile(_ show: Bool) {
        defaults.set(show, forKey: Keys.statuslineShowProfile)
    }

    func loadStatuslineShowProfile() -> Bool {
        if defaults.object(forKey: Keys.statuslineShowProfile) == nil {
            return false  // Default to false (new feature)
        }
        return defaults.bool(forKey: Keys.statuslineShowProfile)
    }

    // MARK: - Widget Settings

    func saveSmallWidgetMetric(_ metric: SmallWidgetMetric) {
        defaults.set(metric.rawValue, forKey: Keys.smallWidgetMetric)
        defaults.synchronize()  // Force sync before widget reads
        // Also write to file for reliable cross-process sync
        saveWidgetSettingsToFile()
    }

    func loadSmallWidgetMetric() -> SmallWidgetMetric {
        guard let rawValue = defaults.string(forKey: Keys.smallWidgetMetric),
              let metric = SmallWidgetMetric(rawValue: rawValue) else {
            return .session  // Default to session
        }
        return metric
    }

    func saveMediumWidgetLeftMetric(_ metric: SmallWidgetMetric) {
        defaults.set(metric.rawValue, forKey: Keys.mediumWidgetLeftMetric)
        defaults.synchronize()  // Force sync before widget reads
        saveWidgetSettingsToFile()
    }

    func loadMediumWidgetLeftMetric() -> SmallWidgetMetric {
        guard let rawValue = defaults.string(forKey: Keys.mediumWidgetLeftMetric),
              let metric = SmallWidgetMetric(rawValue: rawValue) else {
            return .session  // Default left metric
        }
        return metric
    }

    func saveMediumWidgetRightMetric(_ metric: SmallWidgetMetric) {
        defaults.set(metric.rawValue, forKey: Keys.mediumWidgetRightMetric)
        defaults.synchronize()  // Force sync before widget reads
        saveWidgetSettingsToFile()
    }

    func loadMediumWidgetRightMetric() -> SmallWidgetMetric {
        guard let rawValue = defaults.string(forKey: Keys.mediumWidgetRightMetric),
              let metric = SmallWidgetMetric(rawValue: rawValue) else {
            return .weekly  // Default right metric
        }
        return metric
    }

    func saveWidgetColorMode(_ mode: WidgetColorMode) {
        defaults.set(mode.rawValue, forKey: Keys.widgetColorMode)
        defaults.synchronize()  // Force sync before widget reads
        // Also write to file for reliable cross-process sync
        saveWidgetSettingsToFile()
    }

    func loadWidgetColorMode() -> WidgetColorMode {
        guard let rawValue = defaults.string(forKey: Keys.widgetColorMode),
              let mode = WidgetColorMode(rawValue: rawValue) else {
            return .multiColor  // Default to threshold-based colors
        }
        return mode
    }

    func saveWidgetSingleColorHex(_ hex: String) {
        defaults.set(hex, forKey: Keys.widgetSingleColorHex)
        defaults.synchronize()  // Force sync before widget reads
        // Also write to file for reliable cross-process sync
        saveWidgetSettingsToFile()
    }

    func loadWidgetSingleColorHex() -> String {
        return defaults.string(forKey: Keys.widgetSingleColorHex) ?? "#00BFFF"  // Default cyan
    }

    func saveExtraUsageDisplayFormat(_ format: ExtraUsageDisplayFormat) {
        defaults.set(format.rawValue, forKey: Keys.extraUsageDisplayFormat)
        defaults.synchronize()  // Force sync before widget reads
        // Also write to file for reliable cross-process sync
        saveWidgetSettingsToFile()
    }

    func loadExtraUsageDisplayFormat() -> ExtraUsageDisplayFormat {
        guard let rawValue = defaults.string(forKey: Keys.extraUsageDisplayFormat),
              let format = ExtraUsageDisplayFormat(rawValue: rawValue) else {
            return .percentage  // Default to showing percentage
        }
        return format
    }

    // MARK: - Widget Settings File Storage

    /// Structure for widget settings file (reliable cross-process sync)
    private struct WidgetSettingsFile: Codable {
        let colorMode: String
        let singleColorHex: String
        let extraUsageFormat: String
        let smallMetric: String
        let mediumLeftMetric: String
        let mediumRightMetric: String
    }

    /// Saves all widget settings to a file for reliable cross-process sync
    private func saveWidgetSettingsToFile() {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Constants.appGroupIdentifier) else {
            LoggingService.shared.log("SharedDataStore: Cannot save widget settings - no group container")
            return
        }

        let settings = WidgetSettingsFile(
            colorMode: loadWidgetColorMode().rawValue,
            singleColorHex: loadWidgetSingleColorHex(),
            extraUsageFormat: loadExtraUsageDisplayFormat().rawValue,
            smallMetric: loadSmallWidgetMetric().rawValue,
            mediumLeftMetric: loadMediumWidgetLeftMetric().rawValue,
            mediumRightMetric: loadMediumWidgetRightMetric().rawValue
        )

        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(settings)
            let fileURL = containerURL.appendingPathComponent("widgetSettings.json")
            try data.write(to: fileURL)
            LoggingService.shared.log("SharedDataStore: Saved widget settings to file")
        } catch {
            LoggingService.shared.log("SharedDataStore: Failed to save widget settings: \(error)")
        }
    }

    // MARK: - Setup State

    func saveHasCompletedSetup(_ completed: Bool) {
        defaults.set(completed, forKey: Keys.hasCompletedSetup)
    }

    func hasCompletedSetup() -> Bool {
        // Check if flag is set
        if defaults.bool(forKey: Keys.hasCompletedSetup) {
            return true
        }

        // Also check if session key file exists as fallback (legacy)
        let sessionKeyPath = Constants.ClaudePaths.homeDirectory
            .appendingPathComponent(".claude-session-key")

        if FileManager.default.fileExists(atPath: sessionKeyPath.path) {
            // Auto-mark as complete if session key exists
            saveHasCompletedSetup(true)
            return true
        }

        return false
    }

    func hasShownWizardOnce() -> Bool {
        return defaults.bool(forKey: Keys.hasShownWizardOnce)
    }

    func markWizardShown() {
        defaults.set(true, forKey: Keys.hasShownWizardOnce)
    }

    // MARK: - GitHub Star Prompt Tracking

    func saveFirstLaunchDate(_ date: Date) {
        defaults.set(date, forKey: Keys.firstLaunchDate)
    }

    func loadFirstLaunchDate() -> Date? {
        return defaults.object(forKey: Keys.firstLaunchDate) as? Date
    }

    func saveLastGitHubStarPromptDate(_ date: Date) {
        defaults.set(date, forKey: Keys.lastGitHubStarPromptDate)
    }

    func loadLastGitHubStarPromptDate() -> Date? {
        return defaults.object(forKey: Keys.lastGitHubStarPromptDate) as? Date
    }

    func saveHasStarredGitHub(_ starred: Bool) {
        defaults.set(starred, forKey: Keys.hasStarredGitHub)
    }

    func loadHasStarredGitHub() -> Bool {
        return defaults.bool(forKey: Keys.hasStarredGitHub)
    }

    func saveNeverShowGitHubPrompt(_ neverShow: Bool) {
        defaults.set(neverShow, forKey: Keys.neverShowGitHubPrompt)
    }

    func loadNeverShowGitHubPrompt() -> Bool {
        return defaults.bool(forKey: Keys.neverShowGitHubPrompt)
    }

    func shouldShowGitHubStarPrompt() -> Bool {
        // Don't show if user said "don't ask again"
        if loadNeverShowGitHubPrompt() {
            return false
        }

        // Don't show if user already starred
        if loadHasStarredGitHub() {
            return false
        }

        let now = Date()

        // Check if we have a first launch date
        guard let firstLaunch = loadFirstLaunchDate() else {
            // If no first launch date, save it now and don't show prompt yet
            saveFirstLaunchDate(now)
            return false
        }

        // Check if it's been at least 1 day since first launch
        let timeSinceFirstLaunch = now.timeIntervalSince(firstLaunch)
        if timeSinceFirstLaunch < Constants.GitHubPromptTiming.initialDelay {
            return false
        }

        // Check if we've ever shown the prompt before
        guard let lastPrompt = loadLastGitHubStarPromptDate() else {
            // Never shown before, and it's been 1+ days since first launch
            return true
        }

        // Has been shown before - check if enough time has passed for a reminder
        let timeSinceLastPrompt = now.timeIntervalSince(lastPrompt)
        return timeSinceLastPrompt >= Constants.GitHubPromptTiming.reminderInterval
    }

    // MARK: - Feedback Prompt Tracking

    func saveLastFeedbackPromptDate(_ date: Date) {
        defaults.set(date, forKey: Keys.lastFeedbackPromptDate)
    }

    func loadLastFeedbackPromptDate() -> Date? {
        return defaults.object(forKey: Keys.lastFeedbackPromptDate) as? Date
    }

    func saveHasSubmittedFeedback(_ submitted: Bool) {
        defaults.set(submitted, forKey: Keys.hasSubmittedFeedback)
    }

    func loadHasSubmittedFeedback() -> Bool {
        return defaults.bool(forKey: Keys.hasSubmittedFeedback)
    }

    func saveNeverShowFeedbackPrompt(_ neverShow: Bool) {
        defaults.set(neverShow, forKey: Keys.neverShowFeedbackPrompt)
    }

    func loadNeverShowFeedbackPrompt() -> Bool {
        return defaults.bool(forKey: Keys.neverShowFeedbackPrompt)
    }

    func shouldShowFeedbackPrompt() -> Bool {
        if loadNeverShowFeedbackPrompt() { return false }
        if loadHasSubmittedFeedback() { return false }

        guard let firstLaunch = loadFirstLaunchDate() else { return false }

        let now = Date()
        let timeSinceFirstLaunch = now.timeIntervalSince(firstLaunch)
        if timeSinceFirstLaunch < Constants.FeedbackPromptTiming.initialDelay {
            return false
        }

        guard let lastPrompt = loadLastFeedbackPromptDate() else {
            return true
        }

        let timeSinceLastPrompt = now.timeIntervalSince(lastPrompt)
        return timeSinceLastPrompt >= Constants.FeedbackPromptTiming.reminderInterval
    }

    func resetFeedbackPromptForTesting() {
        defaults.removeObject(forKey: Keys.lastFeedbackPromptDate)
        defaults.removeObject(forKey: Keys.hasSubmittedFeedback)
        defaults.removeObject(forKey: Keys.neverShowFeedbackPrompt)
    }

    // MARK: - Debug Settings

    func saveDebugAPILoggingEnabled(_ enabled: Bool) {
        defaults.set(enabled, forKey: Keys.debugAPILoggingEnabled)
    }

    func loadDebugAPILoggingEnabled() -> Bool {
        return defaults.bool(forKey: Keys.debugAPILoggingEnabled)
    }

    // MARK: - Keyboard Shortcuts

    private func shortcutKey(for action: ShortcutAction) -> String {
        switch action {
        case .togglePopover: return Keys.shortcutTogglePopover
        case .refresh: return Keys.shortcutRefresh
        case .openSettings: return Keys.shortcutOpenSettings
        case .nextProfile: return Keys.shortcutNextProfile
        }
    }

    func saveShortcut(_ combo: KeyCombo?, for action: ShortcutAction) {
        let key = shortcutKey(for: action)
        if let combo = combo {
            if let data = try? JSONEncoder().encode(combo) {
                defaults.set(data, forKey: key)
            }
        } else {
            defaults.removeObject(forKey: key)
        }
    }

    func loadShortcut(for action: ShortcutAction) -> KeyCombo? {
        let key = shortcutKey(for: action)
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(KeyCombo.self, from: data)
    }

    // MARK: - Auto-Switch Profile

    func saveAutoSwitchProfileEnabled(_ enabled: Bool) {
        defaults.set(enabled, forKey: Keys.autoSwitchProfileEnabled)
    }

    func loadAutoSwitchProfileEnabled() -> Bool {
        return defaults.bool(forKey: Keys.autoSwitchProfileEnabled)
    }

    // MARK: - Testing Helpers

    func resetGitHubStarPromptForTesting() {
        defaults.removeObject(forKey: Keys.firstLaunchDate)
        defaults.removeObject(forKey: Keys.lastGitHubStarPromptDate)
        defaults.removeObject(forKey: Keys.hasStarredGitHub)
        defaults.removeObject(forKey: Keys.neverShowGitHubPrompt)
    }
}
