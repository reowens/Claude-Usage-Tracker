//
//  MediumWidgetView.swift
//  Claude Usage Widget
//
//  Medium widget showing configurable metric pair with progress bars
//

import SwiftUI
import WidgetKit

struct MediumWidgetView: View {
    let entry: UsageEntry
    let style: WidgetAppearanceStyle

    var body: some View {
        if let usage = entry.usage {
            VStack(spacing: WidgetDesign.Spacing.sectionSpacing) {
                // Header row (per Apple HIG - medium widgets should have headers)
                HStack {
                    Image(systemName: "sparkles")
                        .font(.system(size: WidgetDesign.Typography.iconMedium))
                        .foregroundColor(.purple)
                    Text("Claude Usage")
                        .font(.system(size: WidgetDesign.Typography.headerTitle, weight: .semibold))
                    Spacer()
                    Text(lastUpdatedText(usage.lastUpdated))
                        .font(.system(size: WidgetDesign.Typography.timestamp))
                        .foregroundColor(secondaryTextColor)
                }

                // Usage cards with configurable layout
                HStack(spacing: WidgetDesign.Spacing.cardSpacing) {
                    // Left card based on layout selection
                    UsageCard(
                        metric: entry.mediumLayout.leftMetric,
                        usage: usage,
                        style: style
                    )

                    // Right card based on layout selection
                    UsageCard(
                        metric: entry.mediumLayout.rightMetric,
                        usage: usage,
                        style: style
                    )
                }
            }
            .padding(WidgetDesign.Spacing.outerPadding)
        } else {
            noDataView
        }
    }

    // MARK: - Helper Methods

    private func lastUpdatedText(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return "Updated \(formatter.localizedString(for: date, relativeTo: Date()))"
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

    private var noDataView: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: WidgetDesign.NoData.iconMedium))
                .foregroundColor(secondaryTextColor)

            Text("No Data Available")
                .font(.system(size: WidgetDesign.NoData.titleMedium, weight: .medium))
                .foregroundColor(secondaryTextColor)

            Text("Open Claude Usage app to sync data")
                .font(.system(size: WidgetDesign.NoData.subtitleMedium))
                .foregroundColor(secondaryTextColor)
                .multilineTextAlignment(.center)
        }
        .padding(WidgetDesign.Spacing.outerPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Usage Card (Configurable)

struct UsageCard: View {
    let metric: WidgetSmallMetric
    let usage: WidgetUsageData
    let style: WidgetAppearanceStyle

    private var metricData: MetricDisplayData {
        getMetricData(for: metric, usage: usage)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with icon
            HStack {
                Image(systemName: metric.icon)
                    .font(.system(size: WidgetDesign.Typography.iconSmall))
                    .foregroundColor(statusColor)
                Text(metric.displayName)
                    .font(.system(size: WidgetDesign.Typography.cardTitle, weight: .medium))
                    .foregroundColor(secondaryTextColor)
                Spacer()
            }

            // Percentage
            Text("\(Int(metricData.percentage))%")
                .font(.system(size: WidgetDesign.Typography.percentageMedium, weight: .bold, design: .rounded))
                .foregroundColor(statusColor)

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(progressBackgroundColor)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(statusColor)
                        .frame(width: geometry.size.width * min(metricData.percentage / 100, 1.0))
                }
            }
            .frame(height: WidgetDesign.Spacing.progressHeight)

            // Reset time (exact format matching menu bar)
            Text(WidgetDateFormatter.resetTimeString(from: metricData.resetTime))
                .font(.system(size: WidgetDesign.Typography.timestamp, weight: .medium))
                .foregroundColor(secondaryTextColor)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(WidgetDesign.Spacing.cardPadding)
        .background(cardBackgroundColor)
        .cornerRadius(WidgetDesign.Spacing.cardCornerRadius)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Metric Data Helper

    private struct MetricDisplayData {
        let percentage: Double
        let resetTime: Date
        let status: WidgetStatusLevel
    }

    private func getMetricData(for metric: WidgetSmallMetric, usage: WidgetUsageData) -> MetricDisplayData {
        switch metric {
        case .session:
            return MetricDisplayData(
                percentage: usage.sessionPercentage,
                resetTime: usage.sessionResetTime,
                status: usage.statusLevel
            )
        case .weekly:
            return MetricDisplayData(
                percentage: usage.weeklyPercentage,
                resetTime: usage.weeklyResetTime,
                status: usage.weeklyStatusLevel
            )
        case .opus:
            return MetricDisplayData(
                percentage: usage.opusPercentage,
                resetTime: usage.weeklyResetTime,
                status: statusLevel(for: usage.opusPercentage)
            )
        case .sonnet:
            return MetricDisplayData(
                percentage: usage.sonnetPercentage,
                resetTime: usage.weeklyResetTime,
                status: statusLevel(for: usage.sonnetPercentage)
            )
        }
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

    // MARK: - Style-dependent colors

    private var cardBackgroundColor: Color {
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
        switch metricData.status {
        case .safe:
            return .green
        case .moderate:
            return .orange
        case .critical:
            return .red
        }
    }
}
