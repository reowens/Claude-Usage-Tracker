//
//  LargeWidgetView.swift
//  Claude Usage Widget
//
//  Large widget showing full dashboard with session, weekly, opus, and API usage
//

import SwiftUI
import WidgetKit

struct LargeWidgetView: View {
    let entry: UsageEntry
    let style: WidgetAppearanceStyle

    var body: some View {
        if let usage = entry.usage {
            VStack(spacing: WidgetDesign.Spacing.sectionSpacing) {
                // Header
                HStack {
                    Image(systemName: "sparkles")
                        .font(.system(size: WidgetDesign.Typography.headerTitle))
                        .foregroundColor(.purple)
                    Text("Claude Usage")
                        .font(.system(size: 15, weight: .semibold))
                    Spacer()
                    Text(lastUpdatedText(usage.lastUpdated))
                        .font(.system(size: WidgetDesign.Typography.timestamp))
                        .foregroundColor(secondaryTextColor)
                }

                Divider()
                    .background(dividerColor)

                // Main metrics grid - optimized for ~364x364 widget
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: WidgetDesign.Spacing.cardSpacing),
                    GridItem(.flexible(), spacing: WidgetDesign.Spacing.cardSpacing)
                ], spacing: WidgetDesign.Spacing.cardSpacing) {
                    // Session Usage
                    MetricTile(
                        title: "Session",
                        percentage: usage.sessionPercentage,
                        statusLevel: usage.statusLevel,
                        subtitle: WidgetDateFormatter.shortTimeString(from: usage.sessionResetTime),
                        icon: "clock.fill",
                        style: style
                    )

                    // Weekly Usage
                    MetricTile(
                        title: "Weekly",
                        percentage: usage.weeklyPercentage,
                        statusLevel: usage.weeklyStatusLevel,
                        subtitle: WidgetDateFormatter.shortTimeString(from: usage.weeklyResetTime),
                        icon: "calendar",
                        style: style
                    )

                    // Opus Usage
                    MetricTile(
                        title: "Opus",
                        percentage: usage.opusPercentage,
                        statusLevel: statusLevel(for: usage.opusPercentage),
                        subtitle: WidgetDateFormatter.shortTimeString(from: usage.weeklyResetTime),
                        icon: "star.fill",
                        style: style
                    )

                    // Sonnet Usage
                    MetricTile(
                        title: "Sonnet",
                        percentage: usage.sonnetPercentage,
                        statusLevel: statusLevel(for: usage.sonnetPercentage),
                        subtitle: WidgetDateFormatter.shortTimeString(from: usage.weeklyResetTime),
                        icon: "bolt.fill",
                        style: style
                    )
                }

                // API Usage (if available)
                if let apiUsage = entry.apiUsage {
                    Divider()
                        .background(dividerColor)

                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Image(systemName: "creditcard.fill")
                                    .font(.system(size: WidgetDesign.Typography.iconSmall))
                                    .foregroundColor(.blue)
                                Text("API Credits")
                                    .font(.system(size: WidgetDesign.Typography.iconMedium, weight: .medium))
                                    .foregroundColor(secondaryTextColor)
                            }

                            Text("\(apiUsage.formattedUsed) / \(apiUsage.formattedTotal)")
                                .font(.system(size: 15, weight: .semibold))
                        }

                        Spacer()

                        // API progress ring
                        ZStack {
                            Circle()
                                .stroke(ringBackgroundColor, lineWidth: 5)

                            Circle()
                                .trim(from: 0, to: min(apiUsage.usagePercentage / 100, 1.0))
                                .stroke(Color.blue, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                                .rotationEffect(.degrees(-90))

                            Text("\(Int(apiUsage.usagePercentage))%")
                                .font(.system(size: WidgetDesign.Typography.iconMedium, weight: .bold, design: .rounded))
                        }
                        .frame(width: 48, height: 48)
                    }
                }
            }
            .padding(WidgetDesign.Spacing.outerPadding)
        } else {
            noDataView
        }
    }

    // MARK: - Style-dependent colors

    private var secondaryTextColor: Color {
        switch style {
        case .glass:
            return Color.primary.opacity(WidgetDesign.Colors.glassSecondaryText)
        case .standard:
            return Color.secondary
        }
    }

    private var dividerColor: Color {
        switch style {
        case .glass:
            return Color.primary.opacity(WidgetDesign.Colors.glassDivider)
        case .standard:
            return Color.gray.opacity(WidgetDesign.Colors.standardDivider)
        }
    }

    private var ringBackgroundColor: Color {
        switch style {
        case .glass:
            return Color.primary.opacity(WidgetDesign.Colors.glassProgressBg)
        case .standard:
            return Color.gray.opacity(WidgetDesign.Colors.standardProgressBg)
        }
    }

    private var noDataView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: WidgetDesign.NoData.iconLarge))
                .foregroundColor(secondaryTextColor)

            Text("No Usage Data")
                .font(.system(size: WidgetDesign.NoData.titleLarge, weight: .semibold))
                .foregroundColor(.primary)

            Text("Open the Claude Usage app to sync your data and enable widget display.")
                .font(.system(size: WidgetDesign.NoData.subtitleLarge))
                .foregroundColor(secondaryTextColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
        .padding(WidgetDesign.Spacing.outerPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func lastUpdatedText(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return "Updated \(formatter.localizedString(for: date, relativeTo: Date()))"
    }

    private func statusLevel(for percentage: Double) -> WidgetStatusLevel {
        switch percentage {
        case 0..<50:
            return .safe
        case 50..<80:
            return .moderate
        default:
            return .critical
        }
    }
}

struct MetricTile: View {
    let title: String
    let percentage: Double
    let statusLevel: WidgetStatusLevel
    let subtitle: String
    let icon: String
    let style: WidgetAppearanceStyle

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: WidgetDesign.Typography.iconSmall))
                    .foregroundColor(statusColor)
                Text(title)
                    .font(.system(size: WidgetDesign.Typography.iconMedium, weight: .medium))
                    .foregroundColor(secondaryTextColor)
            }

            Text("\(Int(percentage))%")
                .font(.system(size: WidgetDesign.Typography.percentageMedium, weight: .bold, design: .rounded))
                .foregroundColor(statusColor)

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(progressBackgroundColor)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(statusColor)
                        .frame(width: geometry.size.width * min(percentage / 100, 1.0))
                }
            }
            .frame(height: WidgetDesign.Spacing.progressHeight)

            Text(subtitle)
                .font(.system(size: WidgetDesign.Typography.timestamp))
                .foregroundColor(secondaryTextColor)
        }
        .padding(WidgetDesign.Spacing.cardPadding)
        .background(tileBackgroundColor)
        .cornerRadius(WidgetDesign.Spacing.cardCornerRadius)
    }

    // MARK: - Style-dependent colors

    private var tileBackgroundColor: Color {
        switch style {
        case .glass:
            return Color.primary.opacity(WidgetDesign.Colors.glassCardBg)
        case .standard:
            return Color.gray.opacity(WidgetDesign.Colors.standardCardBg)
        }
    }

    private var progressBackgroundColor: Color {
        switch style {
        case .glass:
            return Color.primary.opacity(WidgetDesign.Colors.glassProgressBg)
        case .standard:
            return Color.gray.opacity(WidgetDesign.Colors.standardProgressBg)
        }
    }

    private var secondaryTextColor: Color {
        switch style {
        case .glass:
            return Color.primary.opacity(WidgetDesign.Colors.glassSecondaryText)
        case .standard:
            return Color.secondary
        }
    }

    private var statusColor: Color {
        switch statusLevel {
        case .safe:
            return .green
        case .moderate:
            return .orange
        case .critical:
            return .red
        }
    }
}
