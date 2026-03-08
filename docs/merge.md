# Merge Plan: reowens/fork + upstream v3.0.0

**Date:** 2026-03-08
**Status:** Pre-planning complete — ready for plan mode
**Branch strategy:** Merge upstream/main into fork (not rebase)

---

## Background

Our fork (`reowens/claude-usage-tracker`) diverged from upstream (`hamed-elfayome/Claude-Usage-Tracker`) at commit `66d8899` (v2.3.0, "Merge pull request #91").

Upstream shipped v3.0.0 with 62 commits of refactoring and new features, then closed all open PRs — including ours — without merging. Upstream v3.0.0 does **NOT** include our widget or color mode features.

| | Fork (ours) | Upstream (v3.0.0) |
|---|---|---|
| Commits since divergence | 3 | 62 |
| Files changed | 39 | 69 |
| Lines added | 4,325 | 10,576 |
| Lines deleted | 243 | 807 |

### Our 3 commits
1. `112a562` — macOS desktop widgets (WidgetKit extension, 3 sizes, App Groups)
2. `905b3d6` — Widget customization (settings, data sync, color modes)
3. `7fc37e6` — Color mode support (multi-color, monochrome, single color for menu bar + widgets)

### Upstream v3.0.0 highlights (features we don't have)
- Global keyboard shortcuts
- Usage history tracking with interactive charts
- Pace-aware coloring for progress indicators
- Time-elapsed markers on progress bars
- Percentage display style for multi-profile
- Borderless settings window with vibrancy
- In-app feedback prompt
- Network logging / debug view
- Mobile app "Coming Soon" placeholder
- Chinese (zh-ch) localization
- Support view
- PR template

---

## File Classification

### 16 files changed in BOTH fork and upstream (conflict zone)

| File | Fork changes | Upstream changes | Conflict severity |
|---|---|---|---|
| `MenuBarIconRenderer.swift` | +70/-21 (colorMode signatures) | +276/-28 (pace coloring, time markers) | **CRITICAL** |
| `PopoverContentView.swift` | +121/-37 (color mode passing) | +450/-398 (complete rewrite) | **CRITICAL** |
| `MenuBarIconConfig.swift` | +75/-8 (MenuBarColorMode enum) | +43/-2 (percentage style, paceColoring) | **HIGH** |
| `SettingsView.swift` | +31/-11 (menubar/widget tabs) | +344/-15 (vibrancy redesign) | **HIGH** |
| `ClaudeCodeView.swift` | +353/-35 (widget/color settings) | +172/-111 (model/context options) | **HIGH** |
| `StatuslineService.swift` | +156 (color mode bash vars) | +161 (model/context/profile vars) | **MEDIUM** |
| `SharedDataStore.swift` | +202/-3 (App Groups, widget keys) | +152 (shortcuts, feedback keys) | **MEDIUM** |
| `MenuBarManager.swift` | +29/-9 (colorMode params) | +603/-35 (massive additions) | **MEDIUM** |
| `ProfileManager.swift` | +131/-20 (widget sync, WidgetKit) | +11 (history cleanup) | **LOW** |
| `Constants.swift` | +16 (appGroupIdentifier) | +misc (weeklyWindow, feedback) | **LOW** |
| `ManageProfilesView.swift` | additive | additive | **LOW** |
| `AppearanceSettingsView.swift` | additive | additive | **LOW** |
| `StatusBarUIManager.swift` | small | small | **LOW** |
| `WindowCoordinator.swift` | small | small | **LOW** |
| `Localizable.strings (en)` | additive | additive | **LOW** |
| `project.pbxproj` | +215 (widget target) | version bump, zh-ch locale | **VERIFY IN XCODE** |

### 23 files unique to our fork (zero conflict risk)

All cleanly additive — no upstream counterpart:

**Widget Extension (13 files):**
- `Claude Usage Widget/ClaudeUsageWidget.swift`
- `Claude Usage Widget/ClaudeUsageWidgetBundle.swift`
- `Claude Usage Widget/WidgetDataProvider.swift` (703 lines)
- `Claude Usage Widget/WidgetViews/SmallWidgetView.swift`
- `Claude Usage Widget/WidgetViews/MediumWidgetView.swift`
- `Claude Usage Widget/WidgetViews/LargeWidgetView.swift`
- `Claude Usage Widget/Extensions/Color+Extensions.swift`
- `Claude Usage Widget/Info.plist`
- `Claude Usage Widget/Assets.xcassets/*` (4 files)
- `Claude Usage Widget/Claude Usage Widget.entitlements`

**App files (10 files):**
- `Claude Usage WidgetExtension.entitlements`
- `Claude Usage/Claude UsageRelease.entitlements` (App Groups added)
- `Claude Usage/ClaudeUsageTracker.entitlements` (App Groups added)
- `Claude Usage/Shared/Extensions/Color+Extensions.swift`
- `Claude Usage/Shared/Extensions/Date+Extensions.swift`
- `Claude Usage/Shared/Models/WidgetStyle.swift`
- `Claude Usage/Shared/Storage/DataStore.swift`
- `Claude Usage/Views/Settings/App/WidgetSettingsView.swift` (729 lines)
- `Claude Usage/Views/Settings/Components/ColorModeSelector.swift`
- `Claude Usage/Views/Settings/Profile/MenuBarSettingsView.swift`

### 53 files unique to upstream (zero conflict risk)

New features, localizations, views, and refactoring that we don't have and will inherit cleanly.

---

## Core Semantic Conflict: Color Mode Architecture

This is the fundamental divergence that makes this merge non-trivial.

**Our fork** replaced the simple `monochromeMode: Bool` with a richer system:
```swift
enum MenuBarColorMode: String, Codable {
    case multiColor    // status-based green/orange/red
    case monochrome    // system-adaptive grayscale
    case singleColor   // user-picked custom color
}
```

**Upstream** kept `monochromeMode: Bool` and built new features on top of it:
- Pace-aware coloring (generates colors based on usage pace)
- Time-elapsed markers (fraction-based progress indicators)
- Percentage display style

Every rendering function in `MenuBarIconRenderer.swift` has this collision:
- **Our version:** `colorMode: MenuBarColorMode, singleColorHex: String`
- **Upstream version:** `monochromeMode: Bool, showTimeMarker: Bool, usePaceColoring: Bool`

---

## Pace Coloring Integration Design

### How upstream's pace coloring works

Pace coloring is a **status level calculation enhancement**, not a rendering change. It lives in `UsageStatusCalculator.calculateStatus()`:

```swift
// Standard: color based on raw percentage (50% used = moderate)
// Pace-aware: color based on PROJECTED end-of-period usage
//   - If 25% used and 50% of time elapsed → projected = 50% → safe
//   - If 25% used and 10% of time elapsed → projected = 250% → critical

static func calculateStatus(
    usedPercentage: Double,
    showRemaining: Bool,
    elapsedFraction: Double? = nil   // nil = standard, non-nil = pace-aware
) -> UsageStatusLevel {
    if let t = elapsedFraction, t >= 0.15, t < 1.0, u > 0 {
        let projected = u / t
        switch projected {
        case ..<0.75:     return .safe
        case 0.75..<0.95: return .moderate
        default:          return .critical
        }
    }
    // ... falls through to standard thresholds
}
```

The pace data flows through `getMetricData()` in the renderer:
```swift
let sessionElapsed: Double? = usePaceColoring
    ? UsageStatusCalculator.elapsedFraction(
        resetTime: usage.sessionResetTime,
        duration: Constants.sessionWindow,
        showRemaining: false
    )
    : nil
let statusLevel = UsageStatusCalculator.calculateStatus(
    usedPercentage: usedPercentage,
    showRemaining: showRemaining,
    elapsedFraction: sessionElapsed   // pace-aware when enabled
)
```

**Key insight:** Pace coloring affects `statusLevel` (safe/moderate/critical), NOT the rendering pipeline. The status level is then passed to `getColorForStatusLevel()` or our `getColorForMode()`.

### How our color mode system works

Our `getColorForMode()` routes the color decision:
```swift
private func getColorForMode(
    _ colorMode: MenuBarColorMode,
    statusLevel: UsageStatusLevel,
    singleColorHex: String,
    isDarkMode: Bool
) -> NSColor {
    switch colorMode {
    case .multiColor:
        return getColorForStatusLevel(statusLevel)  // green/orange/red
    case .monochrome:
        return menuBarForegroundColor(isDarkMode: isDarkMode)  // grayscale
    case .singleColor:
        return NSColor(hex: singleColorHex) ?? NSColor.systemBlue  // user's pick
    }
}
```

### Integration: Pace coloring feeds into color mode

These two systems are **orthogonal** and compose naturally:

```
                    ┌─────────────────┐
                    │  Usage Data     │
                    │  (percentage,   │
                    │   reset time)   │
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │ Pace Coloring   │  ← usePaceColoring toggle
                    │ (adjusts        │
                    │  statusLevel)   │
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │ Color Mode      │  ← colorMode enum
                    │ Router          │
                    └──┬──────┬───┬───┘
                       │      │   │
              multiColor  mono  singleColor
                  │       │       │
              ┌───▼───┐   │   ┌───▼───┐
              │green/ │   │   │user's │
              │orange/│   │   │custom │
              │red    │   │   │color  │
              └───────┘   │   └───────┘
                    ┌─────▼─────┐
                    │ grayscale │
                    └───────────┘
```

**Behavior per color mode with pace coloring enabled:**

| Color Mode | Pace Coloring Effect |
|---|---|
| **multiColor** | Full effect — status level changes green/orange/red based on projected pace instead of raw percentage |
| **monochrome** | No visible effect — monochrome ignores status level entirely, always renders grayscale |
| **singleColor** | No visible effect — single color ignores status level, always renders user's chosen color |

This is correct behavior: pace coloring is a "smarter" way to determine urgency, which only matters when colors are used to convey urgency (multiColor mode).

### Menu Bar Implementation

Merge `getMetricData()` to accept `usePaceColoring` (from upstream), then pass the resulting `statusLevel` through our `getColorForMode()` (from fork):

```swift
// MERGED getMetricData - adds pace coloring from upstream
private func getMetricData(
    metricType: MenuBarMetricType,
    config: MetricIconConfig,
    usage: ClaudeUsage,
    apiUsage: APIUsage?,
    showRemaining: Bool,
    usePaceColoring: Bool = true        // UPSTREAM: pace toggle
) -> MetricData {
    // ... upstream's pace-aware status calculation ...
    let sessionElapsed: Double? = usePaceColoring
        ? UsageStatusCalculator.elapsedFraction(...)
        : nil
    let statusLevel = UsageStatusCalculator.calculateStatus(
        usedPercentage: usedPercentage,
        showRemaining: showRemaining,
        elapsedFraction: sessionElapsed
    )
    // statusLevel now reflects pace when enabled
    return MetricData(percentage: ..., statusLevel: statusLevel, ...)
}

// MERGED rendering - combines fork's color mode with upstream's time markers
private func createBatteryStyle(
    metricType: MenuBarMetricType,
    metricData: MetricData,             // statusLevel already pace-adjusted
    isDarkMode: Bool,
    colorMode: MenuBarColorMode,        // FORK: replaces monochromeMode
    singleColorHex: String,             // FORK: custom color
    showIconName: Bool,
    showNextSessionTime: Bool,
    usage: ClaudeUsage,
    timeMarkerFraction: CGFloat? = nil  // UPSTREAM: time elapsed tick
) -> NSImage {
    // Color decision uses fork's routing with pace-adjusted status
    let fillColor = getColorForMode(colorMode,
        statusLevel: metricData.statusLevel,  // pace-aware when enabled
        singleColorHex: singleColorHex,
        isDarkMode: isDarkMode)

    // Time marker tick from upstream (independent of color mode)
    if let fraction = timeMarkerFraction {
        // ... draw tick mark ...
        drawTimeMarkerTick(tickPath, isDarkMode: isDarkMode)
    }
}
```

### Time Marker: The Pace Line (OPEN — finalize during merge)

> **Status:** Design direction established, details TBD during implementation.
> Upstream's code is available locally via `git show upstream/main:...` (fetched).
> Final decisions on glow, brightness, exact behavior to be made when we're
> hands-on in `MenuBarIconRenderer.swift` and can see both versions in context.

Upstream draws the time marker as a plain 1.5pt line in `menuBarForegroundColor` — it blends with text/outlines. We're going to make it better.

**Design direction: The pace line always shows pace urgency color, regardless of color mode.**

The pace line is the ONE element that breaks color mode rules. It always tells you
"are you burning through your quota too fast?" through color — even when everything
else is monochrome or a single flat color.

**Core principle across all styles:**

| Color Mode | Fill Color | Pace Line Color |
|---|---|---|
| multiColor | status-based (green/orange/red) | pace status — brightened to pop above fill |
| monochrome | grayscale | pace status — **the one splash of color** |
| singleColor | user's hex | pace status — urgency info the flat color can't show |

### Candidate Styles: Menu Bar (review during implementation)

We'll implement several of these and visually compare. The menu bar is ~22px tall and
these icons are tiny — what looks good in theory may not work at this scale.

#### Style A: Colored Tick (baseline)
Upstream's current approach, but colored by pace status instead of foreground color.

```swift
private func drawPaceLine(_ path: NSBezierPath, paceStatus: UsageStatusLevel) {
    paceLineColor(for: paceStatus).setStroke()
    path.lineWidth = 1.5
    path.lineCapStyle = .butt
    path.stroke()
}
```
- Pros: Simple, clean, minimal. Guaranteed to look fine at any size.
- Cons: Might be too subtle — a 1.5pt colored line on a 10pt bar.

#### Style B: Glow Line
Two-pass: wider translucent halo + sharp inner core. Soft luminous quality.

```swift
private func drawPaceLine(_ path: NSBezierPath, paceStatus: UsageStatusLevel) {
    let color = paceLineColor(for: paceStatus)
    // Outer glow
    color.withAlphaComponent(0.35).setStroke()
    path.lineWidth = 3.5
    path.stroke()
    // Inner core
    color.setStroke()
    path.lineWidth = 1.5
    path.lineCapStyle = .butt
    path.stroke()
}
```
- Pros: Eye-catching, the glow makes it pop on dark menu bars. On monochrome bars the green/red halo is striking.
- Cons: At 10px bar height, 3.5pt glow might bleed. Could look muddy on light menu bars.
- Question: Does the glow work on the concentric ring style? Radial glow could look cool or messy.

#### Style C: Notch / Edge Mark
Short tick at top and bottom edges of the bar, not spanning the full height. Like a gauge notch.

```swift
// Top notch + bottom notch, leaving the middle open
let notchHeight: CGFloat = 3.0
// Top
topPath.move(to: NSPoint(x: tickX, y: barY + barHeight))
topPath.line(to: NSPoint(x: tickX, y: barY + barHeight - notchHeight))
// Bottom
bottomPath.move(to: NSPoint(x: tickX, y: barY))
bottomPath.line(to: NSPoint(x: tickX, y: barY + notchHeight))
```
- Pros: Less intrusive, doesn't cover the fill. Feels more like a precision instrument marking.
- Cons: Might be too small to see at menu bar scale.
- For concentric rings: could be inner/outer notch marks on the ring.

#### Style D: Fill Color Shift
No line at all. Instead, the fill changes shade at the pace position — lighter/brighter
before the marker, darker/dimmer after (or vice versa).

```swift
// Split the fill at pace position
let beforeWidth = fillWidth * min(pacePosition / percentage, 1.0)
let afterWidth = fillWidth - beforeWidth
// Draw brighter fill before pace marker
brighterColor.setFill()
drawFillRect(x: start, width: beforeWidth)
// Draw standard fill after
standardColor.setFill()
drawFillRect(x: start + beforeWidth, width: afterWidth)
```
- Pros: No overlay needed, inherently clean. Shows pace as a zone boundary. On monochrome bars: subtle brightness gradient split.
- Cons: Hard to spot the exact boundary. Less "at a glance" than a line. Implementation complexity in every style function.

#### Style E: Diamond / Dot Marker
Small diamond or circle sitting on the bar edge at the pace position.

```swift
let dotSize: CGFloat = 4.0
let dotRect = NSRect(x: tickX - dotSize/2, y: barY + barHeight - 1, width: dotSize, height: dotSize)
let dot = NSBezierPath(ovalIn: dotRect)
paceLineColor(for: paceStatus).setFill()
dot.fill()
```
- Pros: Distinctive, doesn't interfere with the bar fill. Like a pin on a timeline.
- Cons: May look odd on battery style (circle sitting on top of battery). Works better on progress bars.
- For concentric rings: small dot on the ring circumference — could be very nice.

#### Style F: Bright Line + Contrasting Cap
Full-height line (like A) but with a small colored triangle/arrow cap at the top pointing down.

```swift
// Line
color.setStroke()
path.lineWidth = 1.5
path.stroke()
// Small triangle cap at top
let triangle = NSBezierPath()
triangle.move(to: NSPoint(x: tickX - 2, y: barY + barHeight + 1))
triangle.line(to: NSPoint(x: tickX + 2, y: barY + barHeight + 1))
triangle.line(to: NSPoint(x: tickX, y: barY + barHeight - 1))
triangle.close()
color.setFill()
triangle.fill()
```
- Pros: The cap catches the eye even when the line is thin. Clear directional indicator.
- Cons: Adds height above the bar. Menu bar space is tight.

### Candidate Styles: Concentric Rings (special consideration)

The concentric ring style is different — it's circular, not linear. Pace line options:

| Style | How it renders on rings | Notes |
|---|---|---|
| Radial tick (A/B) | Short line crossing the ring arc outward, like a clock tick mark | Upstream's current approach. Works well. |
| Dot on arc (E) | Small colored dot sitting on the ring at the pace angle | Like a watch complication. Clean. |
| Arc segment highlight | A small bright arc segment around the pace angle | Like a glowing section of the ring. Could be beautiful or cluttered. |
| Ring color shift (D) | Ring fill changes brightness at the pace angle | Subtle. Hard to spot on a 24px icon. |

### Candidate Styles: Terminal (review during implementation)

#### Style T-A: Pipe Character `│`
```
Usage: 45% ▓▓▓▓▓│░░░░ → Reset: 3:00 PM
```
- Pros: Clean, widely supported, clearly distinct from fill/empty blocks.
- Cons: Takes one block position, so bar is effectively 9 blocks + marker.

#### Style T-B: Thin Bar `▏`
```
Usage: 45% ▓▓▓▓▓▏░░░░ → Reset: 3:00 PM
```
- Pros: Thinner, feels like a more subtle gauge mark.
- Cons: May not render in all terminal fonts. Could be invisible in some configurations.

#### Style T-C: Triangle Pointer `▶` or `◆`
```
Usage: 45% ▓▓▓▓▓◆░░░░ → Reset: 3:00 PM
```
- Pros: Very distinctive shape. Impossible to miss.
- Cons: Might feel heavy/cluttered in a compact statusline.

#### Style T-D: Color Boundary (no special character)
```
Usage: 45% ▓▓▓▓▓░░░░░ → Reset: 3:00 PM
         ^^^^^ ^^^^^
         green  red    (color changes at pace position)
```
- Pros: No extra character. Fill blocks before pace = one color, after = another.
- Cons: Requires colored mode to work. Useless in monochrome. Harder to spot exact position.

#### Style T-E: Overlay on fill (marker replaces fill/empty at position)
```
Usage: 45% ▓▓▓▓▓│░░░░ → Reset: 3:00 PM   (when fill > pace)
Usage: 30% ▓▓▓│░░░░░░ → Reset: 3:00 PM   (when fill < pace — you're fine)
Usage: 80% ▓▓▓▓▓▓▓▓│░ → Reset: 3:00 PM   (fill >> pace — danger)
```
The visual gap between `▓` fill edge and `│` pace position tells the story:
- Fill well before marker → you're ahead of pace (good)
- Fill at marker → exactly on pace
- Fill past marker → burning too fast (danger)

This is probably the most informative layout — the spatial relationship between
the fill and the marker is the entire point.

### Design Review Process

During the merge, when we reach `MenuBarIconRenderer.swift`:

1. **Implement Style A** (colored tick) first — it's the minimal change from upstream
2. **Build and screenshot** each color mode (multiColor, monochrome, singleColor) at all icon styles
3. **Implement Style B** (glow) as alternative, screenshot again
4. **Compare side-by-side** — decide what looks best at actual menu bar scale
5. **Try 1-2 more** if neither A nor B feels right
6. **Same process for terminal** in StatuslineService — try T-A and T-E, compare in actual terminal

The key constraint is **size** — menu bar icons are tiny. Some designs that look great
in a mockup will be unreadable at 22px height. We won't know until we see them rendered.

### Implementation Details (shared across all styles)

Regardless of which style wins, these changes are needed:

**`drawTimeMarkerTick` → `drawPaceLine` signature change:**
```swift
// BEFORE (upstream):
private func drawTimeMarkerTick(_ path: NSBezierPath, isDarkMode: Bool)

// AFTER (merged — accepts pace status for coloring):
private func drawPaceLine(_ path: NSBezierPath, paceStatus: UsageStatusLevel)
```

**Pace status computation (alongside existing timeMarkerFraction):**
```swift
let paceStatus: UsageStatusLevel? = globalConfig.showTimeMarker
    ? UsageStatusCalculator.calculateStatus(
        usedPercentage: rawUsedPercentage,
        showRemaining: false,
        elapsedFraction: UsageStatusCalculator.elapsedFraction(
            resetTime: ..., duration: ..., showRemaining: false
        )
    )
    : nil
```

**Brightness boost helper (used by all colored styles):**
```swift
private func paceLineColor(for statusLevel: UsageStatusLevel) -> NSColor {
    let baseColor = getColorForStatusLevel(statusLevel)
    guard let hsb = baseColor.usingColorSpace(.sRGB) else { return baseColor }
    return NSColor(
        hue: hsb.hueComponent,
        saturation: min(hsb.saturationComponent * 1.2, 1.0),
        brightness: min(hsb.brightnessComponent + 0.2, 1.0),
        alpha: 1.0
    )
}
```

**`usePaceColoring` toggle interaction:**

| Setting | Fill Color | Pace Line |
|---|---|---|
| `usePaceColoring: true` | pace-adjusted status | pace status (bright) |
| `usePaceColoring: false` | raw percentage status | pace status (bright) — **still shows pace** |

The pace line is independent of `usePaceColoring`. That toggle affects fills only.
`showTimeMarker` controls whether the pace line appears at all.

### Terminal Statusline: Pace Line in the Progress Bar

**Current state:** The terminal progress bar is a simple fill:
```
Usage: 45% ▓▓▓▓▓░░░░░ → Reset: 3:00 PM
```

**Proposed enhancement:** Add a pace marker character in the progress bar AND pace-aware coloring:

```
Usage: 45% ▓▓▓▓▓│░░░░ → Reset: 3:00 PM
              ↑ pace marker (colored independently)
```

The `│` character sits at the "where you should be" position. It's colored with the pace status color — even in monochrome mode.

**Bash implementation:**

```bash
# New config variables
use_pace_coloring=$USE_PACE_COLORING
show_pace_marker=$SHOW_PACE_MARKER

# Calculate pace data (reused for both coloring and marker)
pace_status=""  # safe, moderate, critical
pace_position=-1

if [ -n "$resets_at" ] && [ "$resets_at" != "null" ]; then
    iso_time=$(echo "$resets_at" | sed 's/\\.[0-9]*Z$//')
    reset_epoch=$(date -ju -f "%Y-%m-%dT%H:%M:%S" "$iso_time" "+%s" 2>/dev/null)
    now_epoch=$(date +%s)

    if [ -n "$reset_epoch" ] && [ "$reset_epoch" -gt "$now_epoch" ]; then
        session_duration=18000  # 5 hours
        remaining=$((reset_epoch - now_epoch))
        elapsed=$((session_duration - remaining))
        min_elapsed=$((session_duration * 15 / 100))

        # Pace marker position (0-10 scale for progress bar)
        if [ "$elapsed" -gt 0 ]; then
            pace_position=$(( (elapsed * 10 + session_duration / 2) / session_duration ))
            [ "$pace_position" -gt 10 ] && pace_position=10
        fi

        # Pace status for coloring
        if [ "$elapsed" -ge "$min_elapsed" ] && [ "$utilization" -gt 0 ]; then
            projected=$((utilization * session_duration / elapsed))
            if [ "$projected" -lt 75 ]; then
                pace_status="safe"
            elif [ "$projected" -lt 95 ]; then
                pace_status="moderate"
            else
                pace_status="critical"
            fi
        fi
    fi
fi

# Determine pace marker color (ALWAYS colored, even in monochrome mode)
case "$pace_status" in
    safe)     pace_color="$GREEN_BRIGHT" ;;       # bright green
    moderate) pace_color="$YELLOW_BRIGHT" ;;      # bright yellow/amber
    critical) pace_color="$RED_BRIGHT" ;;         # bright red
    *)        pace_color="$GRAY" ;;               # no data = subtle
esac

# Build progress bar with pace marker
if [ "$show_bar" = "1" ]; then
    progress_bar=" "
    i=0
    while [ $i -lt 10 ]; do
        if [ "$show_pace_marker" = "1" ] && [ "$i" -eq "$pace_position" ]; then
            # Pace marker — always in pace color regardless of color_mode
            progress_bar="${progress_bar}${pace_color}│${RESET}"
        elif [ $i -lt $filled_blocks ]; then
            progress_bar="${progress_bar}▓"
        else
            progress_bar="${progress_bar}░"
        fi
        i=$((i + 1))
    done
fi
```

**Terminal visual examples:**

```
# Monochrome mode + pace marker (the killer combo):
Usage: 45% ▓▓▓▓▓│░░░░ → Reset: 3:00 PM
(everything grey except │ is green = you're fine)

# Monochrome, burning too fast:
Usage: 80% ▓▓▓▓▓▓▓▓│░ → Reset: 3:00 PM
(everything grey except │ is RED at position 3 = danger, you used 80% but only 30% of time passed)

# Colored mode + pace marker:
Usage: 45% ▓▓▓▓▓│░░░░ → Reset: 3:00 PM
(bar is gradient-colored, │ is bright green = on pace)

# Single color + pace marker:
Usage: 45% ▓▓▓▓▓│░░░░ → Reset: 3:00 PM
(bar is user's blue, │ is bright green = pace info that flat color can't show)
```

**Bright ANSI colors for pace line:**

```bash
# Standard colors for fills (existing)
GREEN="\033[38;5;34m"
YELLOW="\033[38;5;214m"

# Bright/bold variants for pace line (new)
GREEN_BRIGHT="\033[1;38;5;46m"    # bold bright green
YELLOW_BRIGHT="\033[1;38;5;220m"  # bold bright amber
RED_BRIGHT="\033[1;38;5;196m"     # bold bright red
```

Using 256-color codes with bold gives the pace marker a noticeably brighter appearance than surrounding fills.

**Color mode interaction in terminal:**

| Mode | Fill Colors | Pace Marker `│` | Effect |
|---|---|---|---|
| `colored` | 10-level gradient | pace status (bright) | marker pops brighter than fill |
| `monochrome` | no colors (grey) | pace status (bright) | **one splash of color on greyscale** |
| `singleColor` | user's hex everywhere | pace status (bright) | pace info breaks through flat color |

The pace marker is the terminal equivalent of the menu bar pace line — it always carries urgency info regardless of the color mode choice.

> **Note:** Terminal pace line details (character choice, exact ANSI codes, interaction with
> existing progress bar rendering) are TBD during implementation. The design direction is
> established; specifics to be finalized when we're in `StatuslineService.swift` resolving
> the bash template merge.

### New Config Variables for StatuslineService

```swift
func updateConfiguration(
    // ... existing fork params ...
    colorMode: StatuslineColorMode = .colored,
    singleColorHex: String = "#00BFFF",
    // ... existing upstream params ...
    showModel: Bool = true,
    showContext: Bool = false,
    contextAsTokens: Bool = false,
    showProfile: Bool = false,
    profileName: String = "",
    // NEW:
    usePaceColoring: Bool = true,         // pace-aware terminal fill colors
    showPaceMarker: Bool = true           // show │ pace position in progress bar
) throws
```

Config file adds:
```bash
USE_PACE_COLORING=1
SHOW_PACE_MARKER=1
```

Note: `SHOW_PACE_MARKER` is independent of `USE_PACE_COLORING`. You can show the pace position marker without changing fill colors, or change fill colors without showing the marker. But the marker itself is ALWAYS colored by pace status — that's the whole point.

### Widget Pace Coloring

Widgets already consume `statusLevel` through `WidgetDataProvider`. When pace coloring is enabled in the app, the `statusLevel` stored in shared data will already be pace-adjusted. Widgets inherit pace coloring automatically — no widget-side changes needed beyond ensuring the status level is computed with pace data before being written to the shared container.

---

## Merge Strategy

### Why merge, not rebase
- Rebase replays 3 commits individually → conflicts hit 3 times
- Merge resolves everything in one pass
- Our branch is published to `origin/main` — rebase rewrites public history

### Why not re-implement from scratch
- 4,325 lines across 39 files including entire WidgetKit extension
- App Groups plumbing, 3 widget views, data provider, color infrastructure
- Too much work to redo; merge preserves it

---

## Execution Plan

### Phase 0: Safety Net

```bash
git branch pre-merge-backup
git tag v2.3.0-fork-features
```

This preserves the working v2 fork state. We can always return here.

### Phase 1: Create merge branch & start merge

```bash
git checkout -b merge/upstream-v3
git merge upstream/main --no-commit
```

Work on a dedicated branch. Don't touch `main` until verified.

### Phase 2: Resolve Conflicts (ordered by difficulty)

#### Pass 1 — Easy (accept both sides)

1. **`WindowCoordinator.swift`** — Small overlap, accept both
2. **`Localizable.strings`** — Additive from both sides
3. **`ManageProfilesView.swift`** — Additive from both sides
4. **`AppearanceSettingsView.swift`** — Additive from both sides
5. **`StatusBarUIManager.swift`** — Small changes from both sides

#### Pass 2 — Medium (merge both feature sets)

6. **`SharedDataStore.swift`** — Keep our App Groups `init()` + widget keys. Keep upstream's feedback/shortcuts/history keys. Both are additive.
7. **`Constants.swift`** — Keep our `appGroupIdentifier`. Keep upstream's `weeklyWindow`, `FeedbackPromptTiming`. Verify no identifier clashes.
8. **`ProfileManager.swift`** — Keep our `import WidgetKit` and widget sync. Keep upstream's history cleanup. Different code regions.
9. **`StatuslineService.swift`** — Both added config variables to the bash template. Keep all variables from both sides. Test the generated bash script output.

#### Pass 3 — Hard (semantic merge required)

10. **`MenuBarIconConfig.swift`** — The data model crux:
    - Keep our `MenuBarColorMode` enum (replaces `monochromeMode: Bool`)
    - Keep our `singleColorHex` field
    - Add upstream's `showTimeMarker`, `usePaceColoring` fields
    - Add upstream's `percentage` case to `MultiProfileIconStyle`
    - Keep our backwards-compatible decoder for legacy `monochromeMode`

11. **`ClaudeCodeView.swift`** — Take upstream's v3 layout as base, add back our color mode selector controls and widget settings sections.

12. **`SettingsView.swift`** — Take upstream's vibrancy redesign as base, add our `.menuBar` and `.widgets` cases to `SettingsSection` enum and navigation.

#### Pass 4 — Critical (function-level merge)

13. **`PopoverContentView.swift`** — Upstream rewrote 398 lines. Take upstream's version, re-apply our `colorMode`/`singleColorHex` parameter passing where upstream uses `monochromeMode`.

14. **`MenuBarIconRenderer.swift`** — Hardest file:
    - Take upstream's version as base (more new code: pace coloring, time markers)
    - Apply `monochromeMode → colorMode + singleColorHex` to all function signatures
    - Port our `getColorForMode()` helper
    - Integrate pace coloring with color mode (pace coloring generates status levels → feed into `getColorForMode`)
    - **Pace line design review** — see Phase 2.5 below

15. **`MenuBarManager.swift`** — Auto-merged but likely broken. Search for remaining `monochromeMode` references and replace with `colorMode`/`singleColorHex` calls.

### Phase 2.5: Pace Line Design Review

After the renderer compiles with merged color mode + pace coloring, but before
finalizing the pace line style:

1. **Implement Style A** (colored tick) — minimal change, swap `isDarkMode` for `paceStatus` in `drawPaceLine`
2. **Build, run, screenshot** all 3 color modes x all icon styles (battery, progress, concentric, compact)
3. **Implement Style B** (glow line) — two-pass drawing
4. **Build, run, screenshot** same matrix
5. **Compare** — pick the winner, or try a third option (notch, dot, etc.)
6. **Repeat for terminal** — try T-A (pipe `│`) and T-E (overlay) in actual terminal, compare
7. **User reviews** screenshots and picks final style

This is an iterative visual design step. Can't be fully pre-planned — we need to
see it at actual pixel scale.

#### Pass 5 — Xcode project

16. **`project.pbxproj`** — Likely auto-merges but MUST verify in Xcode:
    - Widget extension target exists and builds
    - All file references valid (no red/missing files)
    - App Groups capability on both targets
    - Version number: decide on `3.1.0` or `3.0.0-widgets`

### Phase 3: Post-Merge Verification

#### Build checks
- [ ] Main app target builds with zero errors
- [ ] Widget extension target builds with zero errors
- [ ] No warnings related to our changes

#### Functional checks
- [ ] Color modes work: multi-color (green/orange/red by status)
- [ ] Color modes work: monochrome (adapts to light/dark)
- [ ] Color modes work: single color (custom picker)
- [ ] Small widget displays single metric correctly
- [ ] Medium widget displays two metrics correctly
- [ ] Large widget displays full dashboard correctly
- [ ] Widget data syncs from app via App Groups
- [ ] Widget color mode syncs with app settings

#### Upstream feature checks
- [ ] Keyboard shortcuts work
- [ ] Usage history / charts display
- [ ] Pace coloring integrates with our color modes
- [ ] Time-elapsed markers render correctly
- [ ] Percentage display style works
- [ ] Settings window vibrancy/borderless design intact
- [ ] New localizations present

### Phase 4: Commit & Merge to Main

```bash
git add -A
git commit -m "merge: Integrate upstream v3.0.0 with widget and color mode features"
git checkout main
git merge merge/upstream-v3
```

---

## Risk Register

| Risk | Impact | Mitigation |
|---|---|---|
| `project.pbxproj` merge breaks Xcode | Can't build at all | Verify immediately in Xcode; manual fix if needed |
| `monochromeMode` references survive in auto-merged files | Runtime crashes or wrong colors | `grep -r monochromeMode` post-merge, fix all references |
| Pace coloring incompatible with color mode enum | Visual bugs in menu bar | Test all 3 color modes with pace coloring on/off |
| App Groups identifier mismatch | Widgets can't read app data | Verify entitlements match `Constants.appGroupIdentifier` |
| StatuslineService bash script breaks | CLI statusline output wrong | Inspect generated `~/.claude/statusline-config.txt` |
| Widget target missing file references | Widget extension won't build | Open in Xcode, verify no red files in navigator |

---

## Code-Level Conflict Details

### 1. MenuBarIconConfig.swift — The Data Model Foundation

This file must be resolved FIRST because every other conflict depends on it.

**Base (66d8899):**
```swift
struct MenuBarIconConfiguration: Codable, Equatable {
    var monochromeMode: Bool
    var showIconNames: Bool
    var showRemainingPercentage: Bool
    var metrics: [MetricIconConfig]
}
```

**Fork (HEAD):**
```swift
struct MenuBarIconConfiguration: Codable, Equatable {
    var colorMode: MenuBarColorMode        // replaced monochromeMode
    var singleColorHex: String             // NEW: custom hex color
    var showIconNames: Bool
    var showRemainingPercentage: Bool
    var metrics: [MetricIconConfig]
}
```

**Upstream:**
```swift
struct MenuBarIconConfiguration: Codable, Equatable {
    var monochromeMode: Bool               // kept as-is
    var showIconNames: Bool
    var showRemainingPercentage: Bool
    var showTimeMarker: Bool               // NEW: time elapsed marker
    var usePaceColoring: Bool              // NEW: pace-aware colors
    var metrics: [MetricIconConfig]
}
```

**Merged target:**
```swift
struct MenuBarIconConfiguration: Codable, Equatable {
    var colorMode: MenuBarColorMode        // FORK: enum replaces bool
    var singleColorHex: String             // FORK: custom color
    var showIconNames: Bool
    var showRemainingPercentage: Bool
    var showTimeMarker: Bool               // UPSTREAM: time marker
    var usePaceColoring: Bool              // UPSTREAM: pace coloring
    var metrics: [MetricIconConfig]
}
```

Also: `MultiProfileIconStyle` — fork has 3 cases, upstream adds `.percentage` (4th case). Keep all 4.
Also: `MultiProfileDisplayConfig` — fork has 4 props, upstream adds `showTimeMarker` + `usePaceColoring`. Keep all 6.
Keep fork's backwards-compatible decoder that migrates `monochromeMode` → `colorMode`.

### 2. MenuBarIconRenderer.swift — Function Signature Collision

Every rendering function has this pattern:

**Fork signature:**
```swift
func createBatteryStyle(..., colorMode: MenuBarColorMode, singleColorHex: String, ...) -> NSImage
```

**Upstream signature:**
```swift
func createBatteryStyle(..., monochromeMode: Bool, ...) -> NSImage
// (showTimeMarker/usePaceColoring read from globalConfig)
```

**Resolution:** Take upstream's function bodies (pace coloring logic, time markers), apply fork's signature transformation (`monochromeMode` → `colorMode + singleColorHex`). Port fork's `getColorForMode()` helper which routes color decisions through the enum.

Affected functions (all need signature + body merge):
- `createImage()` (primary dispatcher)
- `createBatteryStyle()`
- `createProgressBarStyle()`
- `createPercentageOnlyStyle()`
- `createIconWithBarStyle()`
- `createCompactStyle()`
- `createConcentricIcon()`
- `createConcentricIconWithLabel()`

### 3. PopoverContentView.swift — Complete Rewrite

**Fork (1061 lines):** Component-based architecture with SmartHeader, SmartUsageDashboard, ContextualInsights, SmartFooter. Passes `colorMode`/`singleColorHex` through component props.

**Upstream:** Even larger. Adds `VisualEffectBackground` (NSViewRepresentable wrapping NSVisualEffectView) for proper vibrancy. Different component composition and parameter passing. Still uses `monochromeMode`.

**Resolution:**
- Keep upstream's `VisualEffectBackground` infrastructure (more robust)
- Keep fork's component organization where possible
- Update all component signatures: `monochromeMode` → `colorMode + singleColorHex`

### 4. SettingsView.swift — Complete Redesign

**Fork (450 lines):** Added `.menuBar` and `.widgets` to `SettingsSection` enum + switch cases.

**Upstream (770 lines):** Complete redesign adding:
- `SettingsBackground` NSViewRepresentable
- `SidebarVisualEffect` NSViewRepresentable
- `BorderlessSettingsWindow` NSWindow subclass
- `SettingsWindowBuilder` enum
- Changed default section from `.general` to `.appearance`

**Resolution:** Take upstream's full redesign as base. Add fork's `.menuBar` and `.widgets` enum cases + their switch handlers (`MenuBarSettingsView()`, `WidgetSettingsView()`).

### 5. StatuslineService.swift — Bash Template Variable Collision

**Fork's bash config variables:**
```bash
USE_24_HOUR_TIME, SHOW_USAGE_LABEL, SHOW_RESET_LABEL,
COLOR_MODE, SINGLE_COLOR
```
Plus `hex_to_ansi()` bash function for color conversion.

**Upstream's bash config variables:**
```bash
SHOW_MODEL, SHOW_CONTEXT, CONTEXT_AS_TOKENS,
SHOW_PROFILE, PROFILE_NAME
```

**Resolution:** Union of all variables. Merge `updateConfiguration()` function signature to accept all parameters from both sides. Write complete config file with all variables. Port fork's `hex_to_ansi()` function alongside upstream's display logic.

### 6. SharedDataStore.swift — Additive Keys (Clean Merge)

No real conflict. Both sides added different `Keys` and methods:
- **Fork:** App Groups `init()`, widget keys (`widgetColorMode`, `smallWidgetMetric`, etc.), `saveWidgetSettingsToFile()`
- **Upstream:** Feedback keys (`lastFeedbackPromptDate`, `hasSubmittedFeedback`), shortcut keys, auto-switch profile methods

Resolution: Keep fork's App Groups init. Union all keys. Keep both method sections.

### 7. ClaudeCodeView.swift — Layout Architecture Conflict

**Fork (543 lines):** Two-column layout. Left: "Display Components" with raw `Toggle()` views. Right: "Statusline Colors" with `ColorModeSelector`. Uses `@ObservedObject ProfileManager.shared`.

**Upstream (321 lines):** Single-card layout with `SettingToggle` component wrapper. Has `Apply` button. Different state vars (`showModel`, `showContext` instead of `colorMode`, `singleColor`).

**Resolution:**
1. Merge state variables (union of both sets)
2. Use upstream's `SettingToggle` component style (cleaner)
3. Keep fork's `ProfileManager` reference (needed for widget sync)
4. Add upstream's `Apply` button
5. Add fork's color mode controls as a separate "Appearance" section within upstream's layout

### 8. MenuBarManager.swift — Parameter Changes + New Features (Clean Merge)

Fork makes 4 targeted changes: `monochromeMode` → `colorMode`/`singleColorHex` in `MenuBarIconConfiguration` init calls.

Upstream adds 568 lines: error tracking properties, history tracking, wake/screen observers, feedback window, shortcuts setup, auto-switch tracking, improved auto-refresh with tolerance.

These don't overlap. Apply fork's 4 parameter changes on top of upstream's expanded codebase. Verify no `monochromeMode` references remain.

### 9. Constants.swift — Direct Value Conflicts

Three direct conflicts:

| Constant | Fork | Upstream | Decision |
|---|---|---|---|
| `appGroupIdentifier` | `"group.claude-usage"` | `"group.com.claudeusagetracker.shared"` | Use upstream's (proper reverse-domain). Check widget entitlements match. |
| `homeDirectory` | `getpwuid()` syscall | `ProcessInfo.environment["HOME"]` + FileManager fallback | Use upstream's (handles sandboxed envs) |
| `settingsWindow` | `NSSize(width: 720, height: 600)` | `NSSize(width: 720, height: 750)` | Use upstream's (more room for new UI) |

Also: upstream adds `CLAUDE_CONFIG_DIR` env var check for `claudeDirectory`, `credentialsFile` property, `weeklyWindow` constant, `FeedbackPromptTiming` enum. Keep all.

**WARNING:** If widget entitlements currently use `"group.claude-usage"`, must update them to match upstream's identifier or widgets won't sync.

### 10. ProfileManager.swift — Widget Sync + History Cleanup (Clean Merge)

Fork adds: `import WidgetKit`, `syncExistingDataToWidget()` called in loadProfiles/deleteProfile/activateProfile, `updateMultiProfileConfig()`.

Upstream adds: `UsageHistoryService.shared.deleteHistory(for: id)` in deleteProfile, `DispatchQueue.main.async` wrapper in `toggleProfileSelection()`.

No overlap. Combine: upstream's deleteProfile with fork's `syncExistingDataToWidget()` call at end. Use upstream's async wrapper pattern. Keep fork's widget sync methods.

---

## Merge Dependency Order

Files must be resolved in this order due to type/API dependencies:

```
1. MenuBarIconConfig.swift          (defines MenuBarColorMode enum + merged struct)
   ↓
2. MenuBarIconRenderer.swift        (uses MenuBarColorMode in all function signatures)
   ↓
3. MenuBarManager.swift             (calls renderer with merged config)
   ↓
4. PopoverContentView.swift         (passes color mode to UI components)
   ↓
5. Constants.swift                  (appGroupIdentifier for widget sync)
   ↓
6. SharedDataStore.swift            (keys + App Groups init)
   ↓
7. ProfileManager.swift             (widget sync calls)
   ↓
8. StatuslineService.swift          (bash template + updateConfiguration)
   ↓
9. ClaudeCodeView.swift             (settings UI calling statusline service)
   ↓
10. SettingsView.swift              (navigation structure)
```

---

## Post-Merge Grep Checklist

After resolving all conflicts, run these to catch stale references:

```bash
# Must find ZERO matches (all should be migrated to colorMode)
grep -r "monochromeMode" "Claude Usage/" --include="*.swift"

# Must find matches (our enum is used everywhere)
grep -r "MenuBarColorMode" "Claude Usage/" --include="*.swift"

# Must find matches in both app and widget targets
grep -r "group\." "Claude Usage" --include="*.entitlements"

# Verify consistent App Groups identifier
grep -r "appGroupIdentifier\|group\." "Claude Usage/" --include="*.swift" --include="*.entitlements"
```

---

## Estimated Effort

| Phase | Time estimate |
|---|---|
| Phase 0: Safety | 2 min |
| Phase 1: Start merge | 2 min |
| Phase 2 Pass 1-2: Easy/Medium conflicts | 30 min |
| Phase 2 Pass 3-4: Hard/Critical conflicts | 2-3 hours |
| Phase 2.5: Pace line design review | 1-2 hours (iterative, build/screenshot/compare) |
| Phase 2 Pass 5: Xcode project verification | 15 min |
| Phase 3: Post-merge verification | 30 min |
| **Total** | **~5-6 hours** |

---

## Decision Points

| # | Question | Decision |
|---|---|---|
| 1 | Version number | **v3.1.0** |
| 2 | Pace coloring + color modes | **Integrated** — pace coloring feeds into status level calculation, color mode routes the output. Pace only visually matters in multiColor mode. Added to terminal statusline too. See "Pace Coloring Integration Design" above. |
| 3 | README/CHANGELOG | **Deferred** to end of merge |
| 4 | PR back to upstream | **Undecided** — revisit after merge is verified |
