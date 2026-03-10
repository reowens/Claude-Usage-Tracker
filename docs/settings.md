# Widget Settings Pane Overhaul + Pace Marker Settings

## Problem Statement

1. **Widget settings pane is outdated** — uses its own `PreviewDesign` tokens instead of
   the app-wide `DesignTokens` system. Previews don't match real widget appearance (e.g.,
   no pace marker dots, different sizing). The ClaudeCodeView and MenuBarSettingsView have
   been updated to the new styling but WidgetSettingsView hasn't.

2. **No pace marker settings for widgets** — the widget pace dots are always-on with no
   user control. Menu bar has `showPaceMarker` and `usePaceColoring` toggles but widgets
   have nothing.

3. **Pace marker color is fixed** — uses the 6-tier adaptive spectrum (green→purple) with
   no option to use a custom color or match the widget's color mode. Menu bar has separate
   `usePaceColoring` toggle that falls back to the foreground color when off, but there's
   no equivalent for widgets.

## Scope

### A. Widget Settings Styling Refresh

Bring WidgetSettingsView in line with ClaudeCodeView / MenuBarSettingsView:

- Replace `PreviewDesign` enum with app-wide `DesignTokens`
- Use `SettingsSectionCard`, `SettingsPageHeader`, `SettingToggle` components
- Use proper card styling (DesignTokens.Colors.cardBackground, cardBorder, etc.)
- Update widget previews to render identically to real widgets:
  - Show pace marker dots at current elapsed position
  - Use actual widget design tokens (WidgetDesign) for preview sizing
  - Match real widget card backgrounds (Color.white.opacity(0.05))

### B. Widget Pace Marker Settings

New settings to add to the widget settings pane:

| Setting | Type | Default | Storage Key | Description |
|---------|------|---------|-------------|-------------|
| Show pace marker | Bool | true | `widgetShowPaceMarker` | Enable/disable the pace dot on rings and bars |
| Pace marker color mode | Enum | adaptive | `widgetPaceColorMode` | `adaptive` (6-tier spectrum) or `matchWidget` (uses widget color mode) |

When `matchWidget` is selected:
- multiColor widget → pace dot uses the same threshold color as the progress fill
- monochrome widget → pace dot uses `.primary`
- singleColor widget → pace dot uses the user's custom color

### C. Unified Pace Marker Settings Audit

Current pace settings across the app:

| Location | Settings | Stored In |
|----------|----------|-----------|
| Appearance (single profile) | showTimeMarker, showPaceMarker, usePaceColoring | MenuBarIconConfiguration (profile JSON) |
| Manage Profiles (multi-profile) | showTimeMarker, showPaceMarker, usePaceColoring | MultiProfileDisplayConfig (profile JSON) |
| Claude Code (statusline) | showPaceMarker | SharedDataStore (UserDefaults) |
| Widget settings | *nothing yet* | — |

Proposed unified model:
- Menu bar settings stay as-is (profile-specific, stored in icon config)
- Widget pace settings are app-wide (not profile-specific), stored in SharedDataStore
  and synced to widget via `widgetSettings.json`
- Claude Code pace settings stay as-is (app-wide, SharedDataStore)

No settings consolidation needed — each surface (menu bar, widget, terminal) has
independent pace controls, which makes sense since they're different rendering contexts.

## Data Flow

### Widget Settings Save Path
```
WidgetSettingsView → SharedDataStore.saveWidgetShowPaceMarker(bool)
                   → SharedDataStore.saveWidgetPaceColorMode(enum)
                   → saveWidgetSettingsToFile()  (includes new keys in widgetSettings.json)
                   → WidgetCenter.shared.reloadAllTimelines()
```

### Widget Read Path
```
WidgetDataProvider.loadWidgetShowPaceMarker() → tries file, falls back to UserDefaults
WidgetDataProvider.loadWidgetPaceColorMode()  → tries file, falls back to UserDefaults
```

### Widget View Rendering
```
ClaudeUsageWidget (timeline provider)
  → reads showPaceMarker + paceColorMode from WidgetDataProvider
  → passes to UsageEntry
  → SmallWidgetView / MediumWidgetView / LargeWidgetView conditionally render pace dots
  → pace dot color = adaptive ? paceData.pace.color : colorForUsage(mode, ...)
```

## Files to Modify

### Main App
1. `Claude Usage/Views/Settings/App/WidgetSettingsView.swift` — full styling refresh +
   new pace marker section + updated previews
2. `Claude Usage/Shared/Storage/SharedDataStore.swift` — add save/load for
   `widgetShowPaceMarker` and `widgetPaceColorMode`
3. `Claude Usage/Shared/Models/WidgetStyle.swift` — add `WidgetPaceColorMode` enum

### Widget Extension
4. `Claude Usage Widget/WidgetDataProvider.swift` — add load methods for pace settings,
   add `WidgetPaceColorMode` mirror enum, update `WidgetSettingsFile` struct
5. `Claude Usage Widget/ClaudeUsageWidget.swift` — add pace settings to `UsageEntry`,
   load from WidgetDataProvider in timeline provider
6. `Claude Usage Widget/WidgetViews/SmallWidgetView.swift` — respect showPaceMarker +
   paceColorMode
7. `Claude Usage Widget/WidgetViews/MediumWidgetView.swift` — same
8. `Claude Usage Widget/WidgetViews/LargeWidgetView.swift` — same

### Localization
9. 9x `Localizable.strings` — new keys for pace marker settings labels

## Preview Accuracy Checklist

The widget previews in settings must match real widget rendering:

- [ ] Small preview: circular ring with pace dot on circumference
- [ ] Medium preview: dual cards with progress bars + pace dots on bottom edge
- [ ] Large preview: 2x2 grid with progress bars + pace dots (if feasible in preview)
- [ ] Preview respects showPaceMarker toggle (dot appears/disappears)
- [ ] Preview respects paceColorMode (dot color changes)
- [ ] Preview respects widget color mode (fill colors match)
- [ ] Preview card background matches real widget (0.05 opacity white)

## Open Questions

1. Should the large widget preview be added to settings? Currently only small and medium
   have previews. Large might be too big for the settings pane.

2. Should pace marker color mode be a simple toggle ("Use adaptive colors" on/off) instead
   of a picker? Two options is simpler than an enum.

3. Should the widget preview show real usage data or sample data? Currently it loads real
   data with sample fallback — this is good but the pace dot needs a plausible elapsed
   fraction for the preview.

## Bug Fix: ColorModeSelector color circle mispositioned

In `MenuBarSettingsView` (Appearance section), the color circle next to the "Single Color"
button in the `ColorModeSelector` component is mispositioned. Investigate and fix the
layout in `Claude Usage/Views/Settings/Components/ColorModeSelector.swift`. The color
picker (28x28 circle) may need alignment or spacing adjustment relative to the mode buttons.

**File:** `Claude Usage/Views/Settings/Components/ColorModeSelector.swift`

## Implementation Order

1. Fix ColorModeSelector color circle positioning bug
2. Add new enums and storage methods (WidgetStyle, SharedDataStore, WidgetDataProvider)
3. Wire pace settings through UsageEntry and widget views
4. Restyle WidgetSettingsView with DesignTokens
5. Add pace marker settings section
6. Update widget previews to show pace dots
7. Add localization keys
8. Test all 3 widget sizes + settings sync
