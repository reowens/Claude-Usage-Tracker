//
//  ClaudeUsageWidget.swift
//  Claude Usage Widget
//
//  Main widget configuration and timeline provider
//

import WidgetKit
import SwiftUI

struct ClaudeUsageWidget: Widget {
    let kind: String = "ClaudeUsageWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: UsageTimelineProvider()) { entry in
            ClaudeUsageWidgetEntryView(entry: entry)
                .widgetContainerBackground(style: entry.style)
        }
        .configurationDisplayName("Claude Usage")
        .description("Monitor your Claude AI usage at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Container Background Extension

extension View {
    @ViewBuilder
    func widgetContainerBackground(style: WidgetAppearanceStyle) -> some View {
        switch style {
        case .glass:
            // Glass style: balanced translucency with blur
            self.containerBackground(.regularMaterial, for: .widget)
        case .standard:
            // Standard style: solid background
            self.containerBackground(.fill.tertiary, for: .widget)
        }
    }
}

struct UsageTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> UsageEntry {
        UsageEntry(date: Date(), usage: nil, apiUsage: nil, style: .standard)
    }

    func getSnapshot(in context: Context, completion: @escaping (UsageEntry) -> Void) {
        let provider = WidgetDataProvider.shared
        let entry = UsageEntry(
            date: Date(),
            usage: provider.loadUsage(),
            apiUsage: provider.loadAPIUsage(),
            style: provider.loadWidgetStyle(),
            smallMetric: provider.loadSmallWidgetMetric(),
            mediumLayout: provider.loadMediumWidgetLayout()
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<UsageEntry>) -> Void) {
        let currentDate = Date()
        let provider = WidgetDataProvider.shared
        let entry = UsageEntry(
            date: currentDate,
            usage: provider.loadUsage(),
            apiUsage: provider.loadAPIUsage(),
            style: provider.loadWidgetStyle(),
            smallMetric: provider.loadSmallWidgetMetric(),
            mediumLayout: provider.loadMediumWidgetLayout()
        )

        // Refresh every 15 minutes
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate) ?? currentDate.addingTimeInterval(900)
        let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
        completion(timeline)
    }
}

struct UsageEntry: TimelineEntry {
    let date: Date
    let usage: WidgetUsageData?
    let apiUsage: WidgetAPIUsageData?
    let style: WidgetAppearanceStyle
    let smallMetric: WidgetSmallMetric
    let mediumLayout: WidgetMediumLayout

    init(
        date: Date,
        usage: WidgetUsageData?,
        apiUsage: WidgetAPIUsageData?,
        style: WidgetAppearanceStyle = .standard,
        smallMetric: WidgetSmallMetric = .session,
        mediumLayout: WidgetMediumLayout = .sessionWeekly
    ) {
        self.date = date
        self.usage = usage
        self.apiUsage = apiUsage
        self.style = style
        self.smallMetric = smallMetric
        self.mediumLayout = mediumLayout
    }
}

struct ClaudeUsageWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: UsageEntry

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                SmallWidgetView(entry: entry, style: entry.style)
            case .systemMedium:
                MediumWidgetView(entry: entry, style: entry.style)
            case .systemLarge:
                LargeWidgetView(entry: entry, style: entry.style)
            default:
                SmallWidgetView(entry: entry, style: entry.style)
            }
        }
    }
}

#Preview(as: .systemSmall) {
    ClaudeUsageWidget()
} timeline: {
    UsageEntry(date: .now, usage: .preview, apiUsage: .preview)
}

#Preview(as: .systemMedium) {
    ClaudeUsageWidget()
} timeline: {
    UsageEntry(date: .now, usage: .preview, apiUsage: .preview)
}

#Preview(as: .systemLarge) {
    ClaudeUsageWidget()
} timeline: {
    UsageEntry(date: .now, usage: .preview, apiUsage: .preview)
}
