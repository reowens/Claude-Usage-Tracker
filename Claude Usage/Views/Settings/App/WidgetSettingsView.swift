//
//  WidgetSettingsView.swift
//  Claude Usage - Widget Appearance Settings
//
//  Configure desktop widget appearance including glass/standard styles
//  and content customization
//

import SwiftUI
import WidgetKit

/// Widget appearance and style settings
struct WidgetSettingsView: View {
    @State private var selectedStyle: WidgetStyle = SharedDataStore.shared.loadWidgetStyle()
    @State private var selectedSmallMetric: SmallWidgetMetric = SharedDataStore.shared.loadSmallWidgetMetric()
    @State private var selectedMediumLayout: MediumWidgetLayout = SharedDataStore.shared.loadMediumWidgetLayout()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.section) {
                // Page Header
                SettingsPageHeader(
                    title: "Widgets",
                    subtitle: "Customize the appearance and content of your desktop widgets"
                )

                // Appearance Style Selection
                SettingsSectionCard(
                    title: "Appearance Style",
                    subtitle: "Choose how your widgets look on the desktop"
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

                // Small Widget Content
                SettingsSectionCard(
                    title: "Small Widget Content",
                    subtitle: "Choose which metric to display in small widgets"
                ) {
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
                }

                // Medium Widget Layout
                SettingsSectionCard(
                    title: "Medium Widget Layout",
                    subtitle: "Choose which two metrics to display side by side"
                ) {
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

    private func refreshWidgets() {
        if #available(macOS 14.0, *) {
            WidgetCenter.shared.reloadAllTimelines()
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

// MARK: - Preview

#Preview {
    WidgetSettingsView()
        .frame(width: 520, height: 800)
}
