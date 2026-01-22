//
//  WidgetDataProvider.swift
//  Claude Usage Widget
//
//  Provides data access to the widget from App Groups shared storage
//

import Foundation

/// Lightweight usage data structure for widget display
struct WidgetUsageData: Codable {
    let sessionPercentage: Double
    let sessionResetTime: Date
    let weeklyPercentage: Double
    let weeklyResetTime: Date
    let opusPercentage: Double
    let sonnetPercentage: Double
    let lastUpdated: Date

    var statusLevel: WidgetStatusLevel {
        switch sessionPercentage {
        case 0..<50:
            return .safe
        case 50..<80:
            return .moderate
        default:
            return .critical
        }
    }

    var weeklyStatusLevel: WidgetStatusLevel {
        switch weeklyPercentage {
        case 0..<50:
            return .safe
        case 50..<80:
            return .moderate
        default:
            return .critical
        }
    }

    static var preview: WidgetUsageData {
        WidgetUsageData(
            sessionPercentage: 45.0,
            sessionResetTime: Date().addingTimeInterval(3600),
            weeklyPercentage: 32.0,
            weeklyResetTime: Date().addingTimeInterval(86400 * 3),
            opusPercentage: 28.0,
            sonnetPercentage: 35.0,
            lastUpdated: Date()
        )
    }
}

/// Lightweight API usage data for widget display
struct WidgetAPIUsageData: Codable {
    let usedAmount: Double
    let totalCredits: Double
    let usagePercentage: Double
    let currency: String
    let resetsAt: Date

    var formattedUsed: String {
        formatCurrency(usedAmount)
    }

    var formattedTotal: String {
        formatCurrency(totalCredits)
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: amount)) ?? "\(currency) \(String(format: "%.2f", amount))"
    }

    static var preview: WidgetAPIUsageData {
        WidgetAPIUsageData(
            usedAmount: 12.50,
            totalCredits: 100.00,
            usagePercentage: 12.5,
            currency: "USD",
            resetsAt: Date().addingTimeInterval(86400 * 14)
        )
    }
}

enum WidgetStatusLevel {
    case safe
    case moderate
    case critical
}

/// Widget appearance style (mirrors main app's WidgetStyle)
enum WidgetAppearanceStyle: String {
    case standard = "standard"
    case glass = "glass"
}

/// Widget small metric selection (mirrors main app's SmallWidgetMetric)
enum WidgetSmallMetric: String {
    case session = "session"
    case weekly = "weekly"
    case opus = "opus"
    case sonnet = "sonnet"

    var displayName: String {
        switch self {
        case .session: return "Session"
        case .weekly: return "Weekly"
        case .opus: return "Opus"
        case .sonnet: return "Sonnet"
        }
    }

    var icon: String {
        switch self {
        case .session: return "clock.fill"
        case .weekly: return "calendar"
        case .opus: return "star.fill"
        case .sonnet: return "bolt.fill"
        }
    }
}

/// Widget medium layout selection (mirrors main app's MediumWidgetLayout)
enum WidgetMediumLayout: String {
    case sessionWeekly = "session_weekly"
    case sessionOpus = "session_opus"
    case sessionSonnet = "session_sonnet"
    case weeklyOpus = "weekly_opus"
    case weeklySonnet = "weekly_sonnet"
    case opusSonnet = "opus_sonnet"

    var leftMetric: WidgetSmallMetric {
        switch self {
        case .sessionWeekly, .sessionOpus, .sessionSonnet: return .session
        case .weeklyOpus, .weeklySonnet: return .weekly
        case .opusSonnet: return .opus
        }
    }

    var rightMetric: WidgetSmallMetric {
        switch self {
        case .sessionWeekly: return .weekly
        case .sessionOpus, .weeklyOpus: return .opus
        case .sessionSonnet, .weeklySonnet, .opusSonnet: return .sonnet
        }
    }
}

// MARK: - Widget Date Formatter

/// Helper for formatting dates in widgets (matches menu bar format)
enum WidgetDateFormatter {
    /// Formats reset time with prefix (e.g., "Resets Today 3:59pm")
    static func resetTimeString(from date: Date, prefix: String = "Resets ") -> String {
        return "\(prefix)\(exactTime(from: date))"
    }

    /// Formats time as short string for tiles (no prefix)
    static func shortTimeString(from date: Date) -> String {
        return exactTime(from: date)
    }

    private static func exactTime(from date: Date) -> String {
        let calendar = Calendar.current
        let formatter = DateFormatter()

        if calendar.isDateInToday(date) {
            formatter.dateFormat = "'Today' h:mma"
        } else if calendar.isDateInTomorrow(date) {
            formatter.dateFormat = "'Tomorrow' h:mma"
        } else {
            formatter.dateFormat = "MMM d, h:mma"
        }

        return formatter.string(from: date)
    }
}

// MARK: - Widget Design Tokens

/// Centralized design tokens for consistent widget styling per Apple HIG
enum WidgetDesign {
    enum Typography {
        static let percentageLarge: CGFloat = 28    // Primary percentage display
        static let percentageMedium: CGFloat = 26   // Card percentages
        static let headerTitle: CGFloat = 14        // Widget header
        static let cardTitle: CGFloat = 13          // Section/card titles
        static let subtitle: CGFloat = 11           // Secondary text
        static let timestamp: CGFloat = 10          // Last updated text
        static let iconSmall: CGFloat = 11          // Card icons
        static let iconMedium: CGFloat = 12         // Header icons
    }

    enum Spacing {
        static let outerPadding: CGFloat = 8        // All widget outer padding
        static let cardPadding: CGFloat = 10        // Internal card padding
        static let cardCornerRadius: CGFloat = 10   // Card corners
        static let progressHeight: CGFloat = 8     // Progress bar height
        static let sectionSpacing: CGFloat = 10     // Between sections
        static let cardSpacing: CGFloat = 10        // Between cards
    }

    enum Ring {
        static let lineWidth: CGFloat = 8           // Circular progress ring
        static let size: CGFloat = 100              // Ring diameter (small widget)
    }

    enum Colors {
        // Glass style opacities
        static let glassCardBg: Double = 0.06
        static let glassProgressBg: Double = 0.12
        static let glassSecondaryText: Double = 0.6
        static let glassDivider: Double = 0.15

        // Standard style opacities
        static let standardCardBg: Double = 0.08
        static let standardProgressBg: Double = 0.2
        static let standardDivider: Double = 0.3
    }

    enum NoData {
        // Icon sizes per widget size
        static let iconSmall: CGFloat = 32
        static let iconMedium: CGFloat = 36
        static let iconLarge: CGFloat = 48

        // Title font sizes
        static let titleSmall: CGFloat = 13
        static let titleMedium: CGFloat = 14
        static let titleLarge: CGFloat = 18

        // Subtitle font sizes
        static let subtitleSmall: CGFloat = 10
        static let subtitleMedium: CGFloat = 11
        static let subtitleLarge: CGFloat = 13
    }
}

/// Data provider that reads from App Groups shared storage
class WidgetDataProvider {
    static let shared = WidgetDataProvider()

    private let appGroupIdentifier = "group.claude-usage"
    private let defaults: UserDefaults?
    private let decoder = JSONDecoder()

    private init() {
        self.defaults = UserDefaults(suiteName: appGroupIdentifier)
    }

    /// Gets the Group Container URL
    private var groupContainerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)
    }

    /// Loads usage data from shared storage
    func loadUsage() -> WidgetUsageData? {
        // Try file-based storage first
        if let data = loadFromFile(filename: "claudeUsageData.json") {
            print("Widget: Found file data (\(data.count) bytes)")
            if let usage = decodeUsage(from: data) {
                print("Widget: Successfully decoded usage from file")
                return usage
            } else {
                print("Widget: Failed to decode usage from file")
            }
        } else {
            print("Widget: No file data found at container path: \(groupContainerURL?.path ?? "nil")")
        }

        // Fall back to UserDefaults
        if let defaults = defaults,
           let data = defaults.data(forKey: "claudeUsageData") {
            print("Widget: Found UserDefaults data (\(data.count) bytes)")
            if let usage = decodeUsage(from: data) {
                print("Widget: Successfully decoded usage from UserDefaults")
                return usage
            } else {
                print("Widget: Failed to decode usage from UserDefaults")
            }
        } else {
            print("Widget: No UserDefaults data found (defaults nil: \(defaults == nil))")
        }

        print("Widget: Returning nil - no data available")
        return nil
    }

    /// Loads data from a file in the group container
    private func loadFromFile(filename: String) -> Data? {
        guard let containerURL = groupContainerURL else { return nil }
        let fileURL = containerURL.appendingPathComponent(filename)
        return try? Data(contentsOf: fileURL)
    }

    /// Decodes ClaudeUsage data
    private func decodeUsage(from data: Data) -> WidgetUsageData? {
        do {
            let fullUsage = try decoder.decode(ClaudeUsageCompat.self, from: data)
            return WidgetUsageData(
                sessionPercentage: fullUsage.sessionPercentage,
                sessionResetTime: fullUsage.sessionResetTime,
                weeklyPercentage: fullUsage.weeklyPercentage,
                weeklyResetTime: fullUsage.weeklyResetTime,
                opusPercentage: fullUsage.opusWeeklyPercentage,
                sonnetPercentage: fullUsage.sonnetWeeklyPercentage,
                lastUpdated: fullUsage.lastUpdated
            )
        } catch {
            print("Widget: Decode error: \(error)")
            return nil
        }
    }

    /// Loads API usage data from shared storage
    func loadAPIUsage() -> WidgetAPIUsageData? {
        guard let defaults = defaults,
              let data = defaults.data(forKey: "apiUsageData") else {
            return nil
        }

        do {
            let apiUsage = try decoder.decode(APIUsageCompat.self, from: data)
            let usedAmount = Double(apiUsage.currentSpendCents) / 100.0
            let remainingAmount = Double(apiUsage.prepaidCreditsCents) / 100.0
            let totalCredits = usedAmount + remainingAmount
            let usagePercentage = totalCredits > 0 ? (usedAmount / totalCredits) * 100.0 : 0

            return WidgetAPIUsageData(
                usedAmount: usedAmount,
                totalCredits: totalCredits,
                usagePercentage: usagePercentage,
                currency: apiUsage.currency,
                resetsAt: apiUsage.resetsAt
            )
        } catch {
            return nil
        }
    }

    /// Loads widget appearance style from shared storage
    func loadWidgetStyle() -> WidgetAppearanceStyle {
        guard let defaults = defaults,
              let rawValue = defaults.string(forKey: "widgetStyle"),
              let style = WidgetAppearanceStyle(rawValue: rawValue) else {
            return .standard
        }
        return style
    }

    /// Loads small widget metric preference from shared storage
    func loadSmallWidgetMetric() -> WidgetSmallMetric {
        guard let defaults = defaults,
              let rawValue = defaults.string(forKey: "smallWidgetMetric"),
              let metric = WidgetSmallMetric(rawValue: rawValue) else {
            return .session  // Default to session
        }
        return metric
    }

    /// Loads medium widget layout preference from shared storage
    func loadMediumWidgetLayout() -> WidgetMediumLayout {
        guard let defaults = defaults,
              let rawValue = defaults.string(forKey: "mediumWidgetLayout"),
              let layout = WidgetMediumLayout(rawValue: rawValue) else {
            return .sessionWeekly  // Default to session + weekly
        }
        return layout
    }
}

// MARK: - Compatibility Models (for decoding main app data)

/// Compatibility struct for decoding ClaudeUsage from main app
/// Must match ALL fields from ClaudeUsage.swift for proper decoding
private struct ClaudeUsageCompat: Codable {
    // Session data
    let sessionTokensUsed: Int
    let sessionLimit: Int
    let sessionPercentage: Double
    let sessionResetTime: Date

    // Weekly data (all models)
    let weeklyTokensUsed: Int
    let weeklyLimit: Int
    let weeklyPercentage: Double
    let weeklyResetTime: Date

    // Weekly data (Opus only)
    let opusWeeklyTokensUsed: Int
    let opusWeeklyPercentage: Double

    // Weekly data (Sonnet only)
    let sonnetWeeklyTokensUsed: Int
    let sonnetWeeklyPercentage: Double
    let sonnetWeeklyResetTime: Date?

    // Extra usage data
    let costUsed: Double?
    let costLimit: Double?
    let costCurrency: String?

    // Metadata
    let lastUpdated: Date
    let userTimezone: TimeZone
}

/// Compatibility struct for decoding APIUsage from main app
private struct APIUsageCompat: Codable {
    let currentSpendCents: Int
    let resetsAt: Date
    let prepaidCreditsCents: Int
    let currency: String
}
