//
//  ClaudeCodeView.swift
//  Claude Usage - Claude Code Statusline Integration
//
//  Created by Claude Code on 2025-12-20.
//

import SwiftUI

/// Claude Code statusline integration settings
struct ClaudeCodeView: View {
    @ObservedObject private var profileManager = ProfileManager.shared

    // Component visibility settings
    @State private var showModel: Bool = SharedDataStore.shared.loadStatuslineShowModel()
    @State private var showDirectory: Bool = SharedDataStore.shared.loadStatuslineShowDirectory()
    @State private var showBranch: Bool = SharedDataStore.shared.loadStatuslineShowBranch()
    @State private var showContext: Bool = SharedDataStore.shared.loadStatuslineShowContext()
    @State private var contextAsTokens: Bool = SharedDataStore.shared.loadStatuslineContextAsTokens()
    @State private var showUsage: Bool = SharedDataStore.shared.loadStatuslineShowUsage()
    @State private var showProgressBar: Bool = SharedDataStore.shared.loadStatuslineShowProgressBar()
    @State private var showPaceMarker: Bool = SharedDataStore.shared.loadStatuslineShowPaceMarker()
    @State private var showResetTime: Bool = SharedDataStore.shared.loadStatuslineShowResetTime()
    @State private var showProfile: Bool = SharedDataStore.shared.loadStatuslineShowProfile()
    @State private var use24HourTime: Bool = SharedDataStore.shared.loadStatuslineUse24HourTime()
    @State private var showUsageLabel: Bool = SharedDataStore.shared.loadStatuslineShowUsageLabel()
    @State private var showResetLabel: Bool = SharedDataStore.shared.loadStatuslineShowResetLabel()

    // Appearance settings
    @State private var colorMode: StatuslineColorMode = SharedDataStore.shared.loadStatuslineColorMode()
    @State private var singleColor: Color = Color(hex: SharedDataStore.shared.loadStatuslineSingleColorHex()) ?? .cyan

    // Status feedback
    @State private var statusMessage: String?
    @State private var isSuccess: Bool = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.section) {
                // Page Header
                SettingsPageHeader(
                    title: "claudecode.title".localized,
                    subtitle: "claudecode.subtitle".localized
                )

                // Preview Card
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
                    HStack {
                        Label("claudecode.preview_label".localized, systemImage: "eye.fill")
                            .font(DesignTokens.Typography.sectionTitle)
                            .foregroundColor(.primary)

                        Spacer()

                        Text("ui.updates_realtime".localized)
                            .font(DesignTokens.Typography.caption)
                            .foregroundColor(.secondary)
                    }

                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
                        previewView
                            .padding(DesignTokens.Spacing.medium)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: DesignTokens.Radius.small)
                                    .fill(previewBackgroundColor)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: DesignTokens.Radius.small)
                                            .strokeBorder(previewBorderColor, lineWidth: 1)
                                    )
                            )

                        Text("claudecode.preview_description".localized)
                            .font(DesignTokens.Typography.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(DesignTokens.Spacing.cardPadding)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.card)
                        .fill(DesignTokens.Colors.cardBackground)
                )

                // Two-column layout: Components | Colors
                HStack(alignment: .top, spacing: 16) {
                    // Left: Display Components
                    SettingsSectionCard(
                        title: "ui.display_components".localized,
                        subtitle: "Choose which elements to display"
                    ) {
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
                            SettingToggle(
                                title: "claudecode.component_directory".localized,
                                isOn: $showDirectory
                            )

                            SettingToggle(
                                title: "claudecode.component_branch".localized,
                                isOn: $showBranch
                            )

                            SettingToggle(
                                title: "claudecode.component_model".localized,
                                isOn: $showModel
                            )

                            SettingToggle(
                                title: "claudecode.component_profile".localized,
                                isOn: $showProfile
                            )

                            // Context with sub-option
                            VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
                                SettingToggle(
                                    title: "claudecode.component_context".localized,
                                    isOn: $showContext
                                )

                                if showContext {
                                    SettingToggle(
                                        title: "claudecode.component_context_tokens".localized,
                                        description: "claudecode.context_info".localized,
                                        isOn: $contextAsTokens
                                    )
                                    .padding(.leading, DesignTokens.Spacing.cardPadding)
                                }
                            }

                            // Usage with sub-options
                            VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
                                SettingToggle(
                                    title: "claudecode.component_usage".localized,
                                    isOn: $showUsage
                                )

                                if showUsage {
                                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
                                        SettingToggle(
                                            title: "claudecode.component_progressbar".localized,
                                            isOn: $showProgressBar
                                        )

                                        if showProgressBar {
                                            SettingToggle(
                                                title: "claudecode.component_pace_marker".localized,
                                                description: "claudecode.pace_marker_info".localized,
                                                isOn: $showPaceMarker
                                            )
                                            .padding(.leading, DesignTokens.Spacing.cardPadding)
                                        }

                                        SettingToggle(
                                            title: "claudecode.component_resettime".localized,
                                            isOn: $showResetTime
                                        )

                                        if showResetTime {
                                            SettingToggle(
                                                title: "24-hour time format",
                                                isOn: $use24HourTime
                                            )
                                            .padding(.leading, DesignTokens.Spacing.cardPadding)
                                        }

                                        Divider()

                                        SettingToggle(
                                            title: "Show \"Usage:\" label",
                                            isOn: $showUsageLabel
                                        )

                                        if showResetTime {
                                            SettingToggle(
                                                title: "Show \"Reset:\" label",
                                                isOn: $showResetLabel
                                            )
                                        }
                                    }
                                    .padding(.leading, DesignTokens.Spacing.cardPadding)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)

                    // Right: Color Mode Settings
                    SettingsSectionCard(
                        title: "Statusline Colors",
                        subtitle: "Choose color display mode"
                    ) {
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
                            ForEach([StatuslineColorMode.colored, .monochrome, .singleColor], id: \.self) { mode in
                                Button {
                                    colorMode = mode
                                    SharedDataStore.shared.saveStatuslineColorMode(mode)
                                } label: {
                                    HStack {
                                        Image(systemName: colorMode == mode ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(colorMode == mode ? .accentColor : .secondary)

                                        Image(systemName: mode.icon)
                                            .font(.system(size: 14))
                                            .foregroundColor(iconColorForMode(mode))
                                            .frame(width: 20)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(mode.displayName)
                                                .font(DesignTokens.Typography.body)
                                                .foregroundColor(.primary)

                                            Text(mode.description)
                                                .font(DesignTokens.Typography.caption)
                                                .foregroundColor(.secondary)
                                        }

                                        Spacer()
                                    }
                                    .padding(.vertical, 6)
                                }
                                .buttonStyle(.plain)
                            }

                            if colorMode == .singleColor {
                                HStack {
                                    Spacer().frame(width: 20)

                                    ColorPicker("Choose Color", selection: Binding(
                                        get: { singleColor },
                                        set: { newColor in
                                            singleColor = newColor
                                            SharedDataStore.shared.saveStatuslineSingleColorHex(newColor.toHex() ?? "#00BFFF")
                                        }
                                    ))
                                    .labelsHidden()

                                    Text("Custom statusline color")
                                        .font(DesignTokens.Typography.caption)
                                        .foregroundColor(.secondary)

                                    Spacer()
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }

                // Action buttons + status
                SettingsSectionCard(title: "") {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
                        HStack(spacing: DesignTokens.Spacing.small) {
                            Button(action: applyConfiguration) {
                                Text("claudecode.button_apply".localized)
                                    .font(DesignTokens.Typography.body)
                                    .frame(minWidth: 70)
                            }
                            .buttonStyle(.borderedProminent)

                            Button(action: resetConfiguration) {
                                Text("claudecode.button_reset".localized)
                                    .font(DesignTokens.Typography.body)
                                    .frame(minWidth: 70)
                            }
                            .buttonStyle(.bordered)
                        }

                        if let message = statusMessage {
                            HStack(spacing: DesignTokens.Spacing.iconText) {
                                Image(systemName: isSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(isSuccess ? DesignTokens.Colors.success : DesignTokens.Colors.error)

                                Text(message)
                                    .font(DesignTokens.Typography.caption)

                                Spacer()

                                Button(action: { statusMessage = nil }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(DesignTokens.Spacing.small)
                            .background(
                                RoundedRectangle(cornerRadius: DesignTokens.Radius.tiny)
                                    .fill((isSuccess ? Color.green : Color.red).opacity(0.08))
                            )
                        }

                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.extraSmall) {
                            Text("claudecode.requirement_sessionkey".localized)
                                .font(DesignTokens.Typography.caption)
                                .foregroundColor(.secondary)

                            Text("claudecode.requirement_restart".localized)
                                .font(DesignTokens.Typography.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer()
            }
            .padding()
        }
    }

    // MARK: - Computed Properties

    /// Color used for preview based on selected color mode (from Menu Bar Settings)
    private var previewColor: Color {
        let colorMode = SharedDataStore.shared.loadStatuslineColorMode()
        switch colorMode {
        case .colored:
            return .accentColor
        case .monochrome:
            return .primary
        case .singleColor:
            let hex = SharedDataStore.shared.loadStatuslineSingleColorHex()
            return Color(hex: hex) ?? .cyan
        }
    }

    /// Background color for preview card
    private var previewBackgroundColor: Color {
        let colorMode = SharedDataStore.shared.loadStatuslineColorMode()
        switch colorMode {
        case .colored:
            return Color.purple.opacity(0.05)
        case .monochrome:
            return previewColor.opacity(0.05)
        case .singleColor:
            return previewColor.opacity(0.05)
        }
    }

    /// Border color for preview card
    private var previewBorderColor: Color {
        let colorMode = SharedDataStore.shared.loadStatuslineColorMode()
        switch colorMode {
        case .colored:
            return Color.purple.opacity(0.2)
        case .monochrome:
            return previewColor.opacity(0.2)
        case .singleColor:
            return previewColor.opacity(0.2)
        }
    }

    /// Preview view showing statusline with appropriate colors
    @ViewBuilder
    private var previewView: some View {
        let colorMode = SharedDataStore.shared.loadStatuslineColorMode()

        if colorMode == .colored {
            // Multi-color preview - each element gets its own color
            multiColorPreview
        } else {
            // Single color preview (monochrome or single color)
            Text(generatePreview())
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(previewColor)
                .lineLimit(1)
                .truncationMode(.tail)
        }
    }

    /// Multi-color preview showing each element in different colors
    private var multiColorPreview: some View {
        let usage = profileManager.activeProfile?.claudeUsage
        let percentage = usage != nil ? Int(usage!.sessionPercentage) : 29
        let usageColor = colorForPercentage(Double(percentage))

        return HStack(spacing: 0) {
            if showDirectory {
                Text("claude-usage")
                    .foregroundColor(.cyan)
                if showBranch || showModel || showProfile || showContext || showUsage {
                    Text(" │ ").foregroundColor(.secondary)
                }
            }

            if showBranch {
                Text("⎇ main")
                    .foregroundColor(.green)
                if showModel || showProfile || showContext || showUsage {
                    Text(" │ ").foregroundColor(.secondary)
                }
            }

            if showModel {
                Text("Opus")
                    .foregroundColor(.purple)
                if showProfile || showContext || showUsage {
                    Text(" │ ").foregroundColor(.secondary)
                }
            }

            if showProfile {
                let name = ProfileManager.shared.activeProfile?.name ?? "Profile"
                Text(name)
                    .foregroundColor(.orange)
                if showContext || showUsage {
                    Text(" │ ").foregroundColor(.secondary)
                }
            }

            if showContext {
                if contextAsTokens {
                    Text("Ctx: 96K")
                        .foregroundColor(.blue)
                } else {
                    Text("Ctx: 48%")
                        .foregroundColor(.blue)
                }
                if showUsage {
                    Text(" │ ").foregroundColor(.secondary)
                }
            }

            if showUsage {
                let usagePrefix = showUsageLabel ? "Usage: " : ""
                Text(usagePrefix + "\(percentage)%")
                    .foregroundColor(usageColor)

                if showProgressBar {
                    let filledBlocks = max(0, min(10, (percentage + 5) / 10))
                    let emptyBlocks = 10 - filledBlocks
                    let bar = String(repeating: "▓", count: filledBlocks) + String(repeating: "░", count: emptyBlocks)
                    Text(" \(bar)")
                        .foregroundColor(usageColor)
                }

                if showResetTime {
                    let resetTimeString = formatResetTime(usage?.sessionResetTime)
                    let resetPrefix = showResetLabel ? " → Reset: " : " → "
                    Text(resetPrefix + resetTimeString)
                        .foregroundColor(usageColor)
                }
            }

            if !showDirectory && !showBranch && !showModel && !showProfile && !showContext && !showUsage {
                Text("claudecode.preview_no_components".localized)
                    .foregroundColor(.secondary)
            }
        }
        .font(.system(size: 11, design: .monospaced))
        .lineLimit(1)
        .truncationMode(.tail)
    }

    /// Returns the appropriate color for usage percentage based on thresholds
    private func colorForPercentage(_ percentage: Double) -> Color {
        switch percentage {
        case 0..<50:
            return SettingsColors.usageLow       // Green
        case 50..<80:
            return SettingsColors.usageHigh      // Orange
        default: // 80%+
            return SettingsColors.usageCritical  // Red
        }
    }

    /// Formats reset time for preview display
    /// Rounds to nearest minute to prevent display flickering
    private func formatResetTime(_ date: Date?) -> String {
        guard let date = date else {
            return "--:--"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = use24HourTime ? "HH:mm" : "h:mm a"
        return formatter.string(from: date.roundedToNearestMinute())
    }

    /// Returns the appropriate icon color for each color mode
    private func iconColorForMode(_ mode: StatuslineColorMode) -> Color {
        switch mode {
        case .colored:
            return .purple
        case .monochrome:
            return .primary
        case .singleColor:
            return singleColor
        }
    }

    // MARK: - Actions

    /// Applies the current configuration to Claude Code statusline.
    /// Installs scripts, updates config file, and enables statusline in settings.json.
    private func applyConfiguration() {
        // Validate: at least one component must be selected
        guard showModel || showDirectory || showBranch || showContext || showUsage || showProfile else {
            statusMessage = "claudecode.error_no_components".localized
            isSuccess = false
            return
        }

        // Validate: session key must be configured
        guard StatuslineService.shared.hasValidSessionKey() else {
            statusMessage = "claudecode.error_no_sessionkey".localized
            isSuccess = false
            return
        }

        // Load color settings from SharedDataStore (configured in Menu Bar Settings)
        let colorMode = SharedDataStore.shared.loadStatuslineColorMode()
        let singleColorHex = SharedDataStore.shared.loadStatuslineSingleColorHex()

        // Save user preferences
        SharedDataStore.shared.saveStatuslineShowModel(showModel)
        SharedDataStore.shared.saveStatuslineShowDirectory(showDirectory)
        SharedDataStore.shared.saveStatuslineShowBranch(showBranch)
        SharedDataStore.shared.saveStatuslineShowContext(showContext)
        SharedDataStore.shared.saveStatuslineContextAsTokens(contextAsTokens)
        SharedDataStore.shared.saveStatuslineShowUsage(showUsage)
        SharedDataStore.shared.saveStatuslineShowProgressBar(showProgressBar)
        SharedDataStore.shared.saveStatuslineShowPaceMarker(showPaceMarker)
        SharedDataStore.shared.saveStatuslineShowResetTime(showResetTime)
        SharedDataStore.shared.saveStatuslineShowProfile(showProfile)
        SharedDataStore.shared.saveStatuslineUse24HourTime(use24HourTime)
        SharedDataStore.shared.saveStatuslineShowUsageLabel(showUsageLabel)
        SharedDataStore.shared.saveStatuslineShowResetLabel(showResetLabel)

        do {
            // Install scripts to ~/.claude/
            try StatuslineService.shared.installScripts()

            // Write configuration file
            let profileName = ProfileManager.shared.activeProfile?.name ?? ""
            try StatuslineService.shared.updateConfiguration(
                showModel: showModel,
                showDirectory: showDirectory,
                showBranch: showBranch,
                showContext: showContext,
                contextAsTokens: contextAsTokens,
                showUsage: showUsage,
                showProgressBar: showProgressBar,
                showPaceMarker: showPaceMarker,
                showResetTime: showResetTime,
                use24HourTime: use24HourTime,
                showUsageLabel: showUsageLabel,
                showResetLabel: showResetLabel,
                colorMode: colorMode,
                singleColorHex: singleColorHex,
                showProfile: showProfile,
                profileName: profileName
            )

            // Update Claude CLI settings.json
            try StatuslineService.shared.updateClaudeCodeSettings(enabled: true)

            statusMessage = "claudecode.success_applied".localized
            isSuccess = true
        } catch {
            statusMessage = "error.generic".localized(with: error.localizedDescription)
            isSuccess = false
        }
    }

    /// Disables the statusline by removing it from Claude CLI settings.json.
    private func resetConfiguration() {
        do {
            try StatuslineService.shared.updateClaudeCodeSettings(enabled: false)
            statusMessage = "claudecode.success_disabled".localized
            isSuccess = true
        } catch {
            statusMessage = "error.generic".localized(with: error.localizedDescription)
            isSuccess = false
        }
    }

    /// Generates a preview of what the statusline will look like based on current selections.
    private func generatePreview() -> String {
        var parts: [String] = []

        if showDirectory {
            parts.append("claude-usage")
        }

        if showBranch {
            parts.append("⎇ main")
        }

        if showModel {
            parts.append("Opus")
        }

        if showProfile {
            let name = ProfileManager.shared.activeProfile?.name ?? "Profile"
            parts.append(name)
        }

        if showContext {
            if contextAsTokens {
                parts.append("Ctx: 96K")
            } else {
                parts.append("Ctx: 48%")
            }
        }

        if showUsage {
            // Use real usage data if available
            let usage = profileManager.activeProfile?.claudeUsage
            let percentage = usage != nil ? Int(usage!.sessionPercentage) : 29

            var usageText = showUsageLabel ? "Usage: \(percentage)%" : "\(percentage)%"

            if showProgressBar {
                let filledBlocks = max(0, min(10, (percentage + 5) / 10))
                let emptyBlocks = 10 - filledBlocks
                let bar = String(repeating: "▓", count: filledBlocks) + String(repeating: "░", count: emptyBlocks)
                usageText += " \(bar)"
            }

            if showResetTime {
                if let resetTime = usage?.sessionResetTime {
                    let formatter = DateFormatter()
                    formatter.dateFormat = use24HourTime ? "HH:mm" : "h:mm a"
                    let resetPrefix = showResetLabel ? " → Reset: " : " → "
                    usageText += "\(resetPrefix)\(formatter.string(from: resetTime.roundedToNearestMinute()))"
                } else {
                    let resetPrefix = showResetLabel ? " → Reset: " : " → "
                    usageText += "\(resetPrefix)--:--"
                }
            }

            parts.append(usageText)
        }

        return parts.isEmpty ? "claudecode.preview_no_components".localized : parts.joined(separator: " │ ")
    }
}

// MARK: - Previews

#Preview {
    ClaudeCodeView()
        .frame(width: 520, height: 600)
}
