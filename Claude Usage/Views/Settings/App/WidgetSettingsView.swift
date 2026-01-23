//
//  WidgetSettingsView.swift
//  Claude Usage - Widget Appearance Settings
//
//  Configure desktop widget appearance including glass/standard styles
//  and content customization
//

import SwiftUI
import WidgetKit

// MARK: - Widget Preview Design Tokens

/// Design tokens for widget previews (mirrors WidgetDesign in widget extension)
private enum PreviewDesign {
    enum Typography {
        static let percentageLarge: CGFloat = 28
        static let percentageMedium: CGFloat = 26
        static let headerTitle: CGFloat = 14
        static let cardTitle: CGFloat = 13
        static let subtitle: CGFloat = 11
        static let timestamp: CGFloat = 10
        static let iconSmall: CGFloat = 11
        static let iconMedium: CGFloat = 12
    }

    enum Spacing {
        static let outerPadding: CGFloat = 8
        static let cardPadding: CGFloat = 10
        static let cardCornerRadius: CGFloat = 10
        static let progressHeight: CGFloat = 8
        static let sectionSpacing: CGFloat = 10
        static let cardSpacing: CGFloat = 10
    }

    enum Ring {
        static let lineWidth: CGFloat = 8
        static let size: CGFloat = 80  // Scaled down for preview
    }

    enum Colors {
        static let glassCardBg: Double = 0.06
        static let glassProgressBg: Double = 0.12
        static let glassSecondaryText: Double = 0.6
        static let standardCardBg: Double = 0.08
        static let standardProgressBg: Double = 0.2
    }
}

/// Widget appearance and style settings
struct WidgetSettingsView: View {
    @State private var selectedStyle: WidgetStyle = SharedDataStore.shared.loadWidgetStyle()
    @State private var selectedSmallMetric: SmallWidgetMetric = SharedDataStore.shared.loadSmallWidgetMetric()
    @State private var selectedMediumLayout: MediumWidgetLayout = SharedDataStore.shared.loadMediumWidgetLayout()
    @State private var selectedColorMode: WidgetColorMode = SharedDataStore.shared.loadWidgetColorMode()
    @State private var singleColor: Color = Color(hex: SharedDataStore.shared.loadWidgetSingleColorHex()) ?? .cyan
    @State private var extraUsageFormat: ExtraUsageDisplayFormat = SharedDataStore.shared.loadExtraUsageDisplayFormat()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.section) {
                // Page Header
                SettingsPageHeader(
                    title: "Widgets",
                    subtitle: "Customize the appearance and content of your desktop widgets"
                )

                // Appearance & Colors - Two cards side by side
                HStack(alignment: .top, spacing: DesignTokens.Spacing.gridSpacing) {
                    // Left: Appearance Style
                    SettingsSectionCard(
                        title: "Appearance Style",
                        subtitle: "Choose how your widgets look"
                    ) {
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.cardPadding) {
                            ForEach(WidgetStyle.allCases, id: \.self) { style in
                                StyleOptionRow(
                                    style: style,
                                    isSelected: selectedStyle == style,
                                    onSelect: {
                                        selectedStyle = style
                                        saveStyle(style)
                                    }
                                )
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)

                    // Right: Widget Colors
                    SettingsSectionCard(
                        title: "Widget Colors",
                        subtitle: "Choose color display mode"
                    ) {
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
                            ForEach([WidgetColorMode.multiColor, .monochrome, .singleColor], id: \.self) { mode in
                                Button {
                                    selectedColorMode = mode
                                    saveColorMode(mode)
                                } label: {
                                    HStack {
                                        Image(systemName: selectedColorMode == mode ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(selectedColorMode == mode ? .accentColor : .secondary)

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

                            // Conditional ColorPicker for single-color mode
                            if selectedColorMode == .singleColor {
                                HStack {
                                    Spacer().frame(width: 20)

                                    ColorPicker("Choose Color", selection: Binding(
                                        get: { singleColor },
                                        set: { newColor in
                                            singleColor = newColor
                                            SharedDataStore.shared.saveWidgetSingleColorHex(newColor.toHex() ?? "#00BFFF")
                                            refreshWidgets()
                                        }
                                    ))
                                    .labelsHidden()

                                    Text("Custom widget color")
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

                // Small Widget Content - Preview on left, options on right
                SettingsSectionCard(
                    title: "Small Widget",
                    subtitle: "Choose which metric to display"
                ) {
                    HStack(alignment: .top, spacing: 16) {
                        // Live preview on left
                        SmallWidgetPreview(
                            style: selectedStyle,
                            metric: selectedSmallMetric,
                            colorMode: selectedColorMode,
                            customColor: singleColor
                        )

                        // Options on right
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(SmallWidgetMetric.allCases, id: \.self) { metric in
                                MetricOptionRow(
                                    metric: metric,
                                    isSelected: selectedSmallMetric == metric,
                                    onSelect: {
                                        selectedSmallMetric = metric
                                        saveSmallMetric(metric)
                                    }
                                )
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                // Medium Widget Layout - Preview above, options below
                SettingsSectionCard(
                    title: "Medium Widget",
                    subtitle: "Choose which two metrics to display"
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        // Live preview centered above
                        MediumWidgetPreview(
                            style: selectedStyle,
                            layout: selectedMediumLayout,
                            colorMode: selectedColorMode,
                            customColor: singleColor
                        )
                        .frame(maxWidth: .infinity)

                        // Options below
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(MediumWidgetLayout.allCases, id: \.self) { layout in
                                LayoutOptionRow(
                                    layout: layout,
                                    isSelected: selectedMediumLayout == layout,
                                    onSelect: {
                                        selectedMediumLayout = layout
                                        saveMediumLayout(layout)
                                    }
                                )
                            }
                        }
                    }
                }

                // Extra Usage Display Format
                SettingsSectionCard(
                    title: "Extra Usage Format",
                    subtitle: "Choose how to display cost-based usage"
                ) {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach([ExtraUsageDisplayFormat.percentage, .currency, .both], id: \.self) { format in
                            Button {
                                extraUsageFormat = format
                                saveExtraUsageFormat(format)
                            } label: {
                                HStack {
                                    Image(systemName: extraUsageFormat == format ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(extraUsageFormat == format ? .accentColor : .secondary)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(format.displayName)
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(.primary)

                                        Text(format.description)
                                            .font(.system(size: 11))
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()
                                }
                                .padding(.vertical, 6)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Widget Info
                SettingsSectionCard(
                    title: "About Widgets",
                    subtitle: "How to add widgets to your desktop"
                ) {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
                        InfoRow(
                            icon: "plus.rectangle.on.rectangle",
                            title: "Add Widget",
                            description: "Right-click on your desktop and select \"Edit Widgets\" to add Claude Usage widgets"
                        )

                        Divider()

                        InfoRow(
                            icon: "square.resize",
                            title: "Widget Sizes",
                            description: "Available in small (single metric), medium (two metrics), and large (full dashboard) sizes"
                        )

                        Divider()

                        InfoRow(
                            icon: "arrow.clockwise",
                            title: "Refresh Rate",
                            description: "Widgets update automatically every 15 minutes, or when you open the app"
                        )
                    }
                }

                Spacer()
            }
            .padding()
        }
    }

    // MARK: - Save Methods

    private func saveStyle(_ style: WidgetStyle) {
        SharedDataStore.shared.saveWidgetStyle(style)
        refreshWidgets()
        LoggingService.shared.log("Widget style changed to: \(style.displayName)")
    }

    private func saveSmallMetric(_ metric: SmallWidgetMetric) {
        SharedDataStore.shared.saveSmallWidgetMetric(metric)
        refreshWidgets()
        LoggingService.shared.log("Small widget metric changed to: \(metric.displayName)")
    }

    private func saveMediumLayout(_ layout: MediumWidgetLayout) {
        SharedDataStore.shared.saveMediumWidgetLayout(layout)
        refreshWidgets()
        LoggingService.shared.log("Medium widget layout changed to: \(layout.displayName)")
    }

    private func saveColorMode(_ mode: WidgetColorMode) {
        SharedDataStore.shared.saveWidgetColorMode(mode)
        refreshWidgets()
        LoggingService.shared.log("Widget color mode changed to: \(mode.displayName)")
    }

    private func saveExtraUsageFormat(_ format: ExtraUsageDisplayFormat) {
        SharedDataStore.shared.saveExtraUsageDisplayFormat(format)
        refreshWidgets()
        LoggingService.shared.log("Extra usage format changed to: \(format.displayName)")
    }

    private func iconColorForMode(_ mode: WidgetColorMode) -> Color {
        switch mode {
        case .multiColor:
            return .purple
        case .monochrome:
            return .primary
        case .singleColor:
            return singleColor
        }
    }

    private func refreshWidgets() {
        if #available(macOS 14.0, *) {
            // Small delay to ensure UserDefaults sync propagates across processes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
    }
}

// MARK: - Style Option Row

private struct StyleOptionRow: View {
    let style: WidgetStyle
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Style preview icon
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(previewBackground)
                        .frame(width: 48, height: 48)

                    Image(systemName: previewIcon)
                        .font(.system(size: 20))
                        .foregroundColor(previewIconColor)
                }

                // Style info
                VStack(alignment: .leading, spacing: 2) {
                    Text(style.displayName)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)

                    Text(style.description)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
                    .foregroundColor(isSelected ? .accentColor : .secondary.opacity(0.5))
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(isSelected ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var previewBackground: Color {
        switch style {
        case .standard:
            return Color.gray.opacity(0.15)
        case .glass:
            return Color.blue.opacity(0.08)
        }
    }

    private var previewIcon: String {
        switch style {
        case .standard:
            return "square.fill"
        case .glass:
            return "square.on.square.dashed"
        }
    }

    private var previewIconColor: Color {
        switch style {
        case .standard:
            return .secondary
        case .glass:
            return .blue
        }
    }
}

// MARK: - Metric Option Row (Compact)

private struct MetricOptionRow: View {
    let metric: SmallWidgetMetric
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 10) {
                Image(systemName: metric.icon)
                    .font(.system(size: 14))
                    .foregroundColor(metricColor)
                    .frame(width: 20)

                Text(metric.displayName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16))
                    .foregroundColor(isSelected ? .accentColor : .secondary.opacity(0.5))
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }

    private var metricColor: Color {
        switch metric {
        case .session:
            return .green
        case .weekly:
            return .blue
        case .opus:
            return .purple
        case .sonnet:
            return .orange
        case .extra:
            return .cyan
        }
    }
}

// MARK: - Layout Option Row (Compact)

private struct LayoutOptionRow: View {
    let layout: MediumWidgetLayout
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 10) {
                // Compact metric pair indicator (colored dots)
                HStack(spacing: 4) {
                    Circle()
                        .fill(metricColor(for: layout.leftMetric))
                        .frame(width: 10, height: 10)
                    Circle()
                        .fill(metricColor(for: layout.rightMetric))
                        .frame(width: 10, height: 10)
                }
                .frame(width: 28)

                Text(layout.displayName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16))
                    .foregroundColor(isSelected ? .accentColor : .secondary.opacity(0.5))
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }

    private func metricColor(for metric: SmallWidgetMetric) -> Color {
        switch metric {
        case .session:
            return .green
        case .weekly:
            return .blue
        case .opus:
            return .purple
        case .sonnet:
            return .orange
        case .extra:
            return .cyan
        }
    }
}

// MARK: - Info Row

private struct InfoRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.accentColor)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)

                Text(description)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Small Widget Preview

private struct SmallWidgetPreview: View {
    let style: WidgetStyle
    let metric: SmallWidgetMetric
    let colorMode: WidgetColorMode
    let customColor: Color

    // Sample preview data
    private let previewPercentage: Double = 45.0
    private let previewResetTime = Date().addingTimeInterval(3600 * 2)  // 2 hours from now

    var body: some View {
        VStack(spacing: 10) {
            // Circular progress indicator
            ZStack {
                Circle()
                    .stroke(ringBackgroundColor, lineWidth: 8)

                Circle()
                    .trim(from: 0, to: previewPercentage / 100)
                    .stroke(
                        statusColor,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 0) {
                    Text("\(Int(previewPercentage))%")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(statusColor)

                    Text(metric.displayName)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(secondaryTextColor)
                }
            }
            .frame(width: 100, height: 100)

            // Reset time
            Text(formatResetTime(previewResetTime))
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(secondaryTextColor)
                .lineLimit(1)
        }
        .padding(12)
        .frame(width: 155, height: 155)  // Close to actual macOS small widget size
        .background(previewBackground)
        .cornerRadius(20)
    }

    private var ringBackgroundColor: Color {
        switch style {
        case .glass:
            return Color.primary.opacity(PreviewDesign.Colors.glassProgressBg)
        case .standard:
            return Color.gray.opacity(PreviewDesign.Colors.standardProgressBg)
        }
    }

    private var secondaryTextColor: Color {
        switch style {
        case .glass:
            return Color.primary.opacity(PreviewDesign.Colors.glassSecondaryText)
        case .standard:
            return Color.secondary
        }
    }

    private var statusColor: Color {
        colorForUsage(previewPercentage, mode: colorMode, customColor: customColor)
    }

    private var previewBackground: some View {
        Group {
            switch style {
            case .glass:
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            case .standard:
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(NSColor.windowBackgroundColor).opacity(0.8))
            }
        }
    }

    private func formatResetTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "'Resets Today' h:mma"
        return formatter.string(from: date.roundedToNearestMinute())
    }
}

// MARK: - Medium Widget Preview

private struct MediumWidgetPreview: View {
    let style: WidgetStyle
    let layout: MediumWidgetLayout
    let colorMode: WidgetColorMode
    let customColor: Color

    var body: some View {
        VStack(spacing: 10) {
            // Header row
            HStack {
                Image(systemName: "sparkles")
                    .font(.system(size: 12))
                    .foregroundColor(.purple)
                Text("Claude Usage")
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                Text("Updated 5m ago")
                    .font(.system(size: 10))
                    .foregroundColor(secondaryTextColor)
            }

            // Usage cards
            HStack(spacing: 10) {
                PreviewUsageCard(
                    metric: layout.leftMetric,
                    percentage: percentageFor(layout.leftMetric),
                    style: style,
                    colorMode: colorMode,
                    customColor: customColor
                )
                PreviewUsageCard(
                    metric: layout.rightMetric,
                    percentage: percentageFor(layout.rightMetric),
                    style: style,
                    colorMode: colorMode,
                    customColor: customColor
                )
            }
        }
        .padding(12)
        .frame(width: 329, height: 155)  // Actual macOS medium widget size
        .background(previewBackground)
        .cornerRadius(20)
    }

    private func percentageFor(_ metric: SmallWidgetMetric) -> Double {
        switch metric {
        case .session: return 45.0
        case .weekly: return 32.0
        case .opus: return 28.0
        case .sonnet: return 35.0
        case .extra: return 22.5
        }
    }

    private var secondaryTextColor: Color {
        switch style {
        case .glass:
            return Color.primary.opacity(PreviewDesign.Colors.glassSecondaryText)
        case .standard:
            return Color.secondary
        }
    }

    private var previewBackground: some View {
        Group {
            switch style {
            case .glass:
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            case .standard:
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(NSColor.windowBackgroundColor).opacity(0.8))
            }
        }
    }
}

// MARK: - Preview Usage Card

private struct PreviewUsageCard: View {
    let metric: SmallWidgetMetric
    let percentage: Double
    let style: WidgetStyle
    let colorMode: WidgetColorMode
    let customColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with icon
            HStack(spacing: 4) {
                Image(systemName: metric.icon)
                    .font(.system(size: 11))
                    .foregroundColor(statusColor)
                Text(metric.displayName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(secondaryTextColor)
            }

            // Percentage
            Text("\(Int(percentage))%")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundColor(statusColor)

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(progressBackgroundColor)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(statusColor)
                        .frame(width: geometry.size.width * (percentage / 100))
                }
            }
            .frame(height: 8)

            // Reset time
            Text("Resets Today 4PM")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(secondaryTextColor)
                .lineLimit(1)
        }
        .padding(10)
        .background(cardBackgroundColor)
        .cornerRadius(10)
        .frame(maxWidth: .infinity)
    }

    private var cardBackgroundColor: Color {
        switch style {
        case .glass:
            return Color.primary.opacity(PreviewDesign.Colors.glassCardBg)
        case .standard:
            return Color.gray.opacity(PreviewDesign.Colors.standardCardBg)
        }
    }

    private var progressBackgroundColor: Color {
        switch style {
        case .glass:
            return Color.primary.opacity(PreviewDesign.Colors.glassProgressBg)
        case .standard:
            return Color.gray.opacity(PreviewDesign.Colors.standardProgressBg)
        }
    }

    private var secondaryTextColor: Color {
        switch style {
        case .glass:
            return Color.primary.opacity(PreviewDesign.Colors.glassSecondaryText)
        case .standard:
            return Color.secondary
        }
    }

    private var statusColor: Color {
        colorForUsage(percentage, mode: colorMode, customColor: customColor)
    }
}

// MARK: - Color Helpers

/// Returns color for usage percentage based on color mode
private func colorForUsage(_ percentage: Double, mode: WidgetColorMode, customColor: Color) -> Color {
    switch mode {
    case .multiColor:
        // Threshold-based colors (like menu bar)
        switch percentage {
        case 90...:
            return SettingsColors.usageCritical  // Red
        case 75..<90:
            return SettingsColors.usageHigh      // Orange
        case 50..<75:
            return SettingsColors.usageMedium    // Yellow
        default:
            return SettingsColors.usageLow       // Green
        }
    case .monochrome:
        return .primary  // Adaptive to system theme
    case .singleColor:
        return customColor
    }
}

// MARK: - Preview

#Preview {
    WidgetSettingsView()
        .frame(width: 520, height: 900)
}
