# Security Fixes Roadmap

This document tracks security improvements identified during the January 2026 security audit.

## Overview

| Issue | Severity | Status | Approach |
|-------|----------|--------|----------|
| #1 Session key embedded in script | CRITICAL | ✅ Complete | Protected credentials file (0600 permissions) |
| #2 Credentials in plaintext JSON | HIGH | ✅ Complete | Per-profile Keychain storage |
| #3 Shell injection via config sourcing | MEDIUM | ✅ Complete | Hex color validation + bash validation |
| #4 Organization ID not validated | LOW | ✅ Complete | Add format validation |
| #5 Pretty-printed JSON in ProfileStore | LOW | ✅ Complete | Remove `.prettyPrinted` |

---

## Issue #1: Session Key Embedded in Statusline Script ✅ COMPLETE

### Original Problem
- `StatuslineService.swift` generated a Swift script with session key embedded as a string literal
- Script written to `~/.claude/fetch-claude-usage.swift` with 755 permissions
- **Risk:** Any local process could read the session key from the file

### Solution Implemented: Protected Credentials File

Instead of embedding credentials in the script, we now use a protected credentials file with strict permissions (0600 - owner read/write only).

**Key Changes:**
- Credentials stored in `~/.claude/.credentials` with 0600 permissions
- Swift script reads credentials at runtime (no embedded secrets)
- Hidden file for additional obscurity

### ~~Original Proposal: Signed Helper Binary + Shared Keychain~~

*This approach was abandoned due to Xcode target configuration complexity.*

#### Architecture

```
CURRENT (insecure):
┌─────────────────┐     ┌──────────────────────────────┐
│ Main App        │────▶│ fetch-claude-usage.swift     │
│ (writes script) │     │ Contains: sessionKey="sk-..." │
└─────────────────┘     └──────────────────────────────┘
                                    │
                                    ▼ (755 - world readable)
                              ~/.claude/fetch-claude-usage.swift

PROPOSED (secure):
┌─────────────────┐     ┌──────────────────────────────┐
│ Main App        │────▶│ Shared Keychain Access Group │
│ (saves to KC)   │     │ Session key encrypted        │
└─────────────────┘     └──────────────────────────────┘
                                    │
        ┌───────────────────────────┘
        ▼
┌─────────────────────────┐
│ claude-usage-helper     │ (signed binary, reads from Keychain)
│ - Reads session key     │
│ - Fetches usage API     │
│ - Outputs result        │
└─────────────────────────┘
        │
        ▼
┌─────────────────────────┐
│ statusline-command.sh   │ (calls helper binary)
└─────────────────────────┘
```

#### Implementation Steps

##### Step 1: Create Shared Keychain Access Group

1. Create entitlements file for shared access group
2. Update main app entitlements:
   ```xml
   <key>keychain-access-groups</key>
   <array>
       <string>$(TeamIdentifierPrefix)com.claudeusagetracker.shared</string>
   </array>
   ```

##### Step 2: Update KeychainService

1. Modify `KeychainService.swift` to store session keys in shared access group
2. Add migration logic for existing keys (move from app-only to shared group)
3. Ensure both read and write use the shared group

##### Step 3: Create Helper Binary Target

1. Add new **Command Line Tool** target in Xcode: `claude-usage-helper`
2. Target settings:
   - Language: Swift
   - Bundle ID: `com.claudeusagetracker.helper`
   - Signed with same Team ID as main app
3. Add same shared Keychain entitlement to helper

##### Step 4: Implement Helper Binary

```swift
// claude-usage-helper/main.swift
import Foundation
import Security

// 1. Read session key from shared Keychain
// 2. Read org ID from shared Keychain (or config file)
// 3. Fetch usage from Claude API
// 4. Output: "UTILIZATION|RESETS_AT" or "ERROR:message"
```

##### Step 5: Update StatuslineService

1. Remove `generateSwiftScript()` function entirely
2. Update `installScripts()` to:
   - Copy helper binary from app bundle to `~/.claude/claude-usage-helper`
   - Set permissions to 755 (executable)
   - No longer write session key to any file
3. Update bash script to call helper binary instead of Swift script

##### Step 6: Update Bash Script

```bash
# OLD:
swift_result=$(swift "$HOME/.claude/fetch-claude-usage.swift" 2>/dev/null)

# NEW:
swift_result=$("$HOME/.claude/claude-usage-helper" 2>/dev/null)
```

##### Step 7: Handle Organization ID

Options:
- **Option A:** Store org ID in Keychain too (alongside session key)
- **Option B:** Store org ID in config file (not sensitive, just an identifier)

Recommendation: Option A - keep all credentials in Keychain for consistency.

#### Files to Modify

| File | Changes |
|------|---------|
| `Claude Usage.xcodeproj` | Add helper target |
| `Claude Usage.entitlements` | Add shared keychain group |
| `claude-usage-helper.entitlements` | New file, shared keychain group |
| `KeychainService.swift` | Use shared access group |
| `StatuslineService.swift` | Remove script generation, copy binary instead |
| `StatuslineService.swift` | Update bash script template |

#### Testing Checklist

- [ ] Helper binary can read from Keychain when signed
- [ ] Helper binary fails gracefully when key not found
- [ ] Main app can write to shared Keychain group
- [ ] Main app can read from shared Keychain group
- [ ] Statusline displays correctly after changes
- [ ] Existing users' keys migrate properly
- [ ] Fresh install works correctly
- [ ] Keychain prompt appears only once (if at all)

---

## Issue #2: Credentials in Plaintext JSON (ProfileStore) ✅ COMPLETE

### Original Problem
- `ProfileStore.swift` saved profiles as JSON to UserDefaults
- Credentials stored directly in Profile struct:
  - `claudeSessionKey`
  - `apiSessionKey`
  - `cliCredentialsJSON`
- **Risk:** Credentials visible in plaintext in UserDefaults plist file

### Solution Implemented: Per-Profile Keychain Storage

Credentials are now stored in macOS Keychain with per-profile keys, completely separate from the JSON profile data.

**Key Changes:**

1. **KeychainService** - Added per-profile credential methods:
   - `saveProfileCredential(_:type:profileId:)` - Save credential to Keychain
   - `loadProfileCredential(type:profileId:)` - Load credential from Keychain
   - `deleteProfileCredential(type:profileId:)` - Delete credential from Keychain
   - `deleteAllProfileCredentials(profileId:)` - Delete all credentials for a profile
   - Keychain service format: `com.claudeusagetracker.profile.{UUID}.{credential-type}`

2. **ProfileStore** - Updated to use Keychain for credentials:
   - `saveProfiles()` extracts credentials and saves to Keychain, then saves sanitized profile (no credentials) to JSON
   - `loadProfiles()` loads profile from JSON, then loads credentials from Keychain
   - Automatic migration: On load, if legacy credentials exist in JSON, they're migrated to Keychain and cleared from JSON

3. **Profile struct** - Unchanged (maintains API compatibility)
   - Credentials are populated in memory after loading from Keychain
   - Non-sensitive data (organizationId, apiOrganizationId) remains in JSON

**Files Modified:**
- `KeychainService.swift` - Added `ProfileCredentialType` enum and per-profile methods
- `ProfileStore.swift` - Updated save/load to use Keychain for credentials

**Migration:**
- Automatic one-time migration on first load after update
- Legacy credentials in JSON are copied to Keychain, then JSON is re-saved without credentials
- No user action required

---

## Issue #3: Shell Injection via Config Sourcing

### Current State
- `statusline-config.txt` is sourced directly in bash script
- Hex color value written without validation
- Malicious color value could execute arbitrary commands

### Location
- [StatuslineService.swift:452-463](Claude%20Usage/Shared/Services/StatuslineService.swift#L452-L463) (config write)
- [StatuslineService.swift:117-118](Claude%20Usage/Shared/Services/StatuslineService.swift#L117-L118) (bash source)

### Solution

Add strict hex color validation before writing to config file.

#### Implementation

```swift
// Add to StatuslineService or create HexColorValidator

private func isValidHexColor(_ hex: String) -> Bool {
    let pattern = "^#[0-9A-Fa-f]{6}$"
    return hex.range(of: pattern, options: .regularExpression) != nil
}

func updateConfiguration(..., singleColorHex: String = "#00BFFF") throws {
    // Validate hex color
    guard isValidHexColor(singleColorHex) else {
        throw StatuslineError.invalidColorFormat
    }
    // ... rest of function
}
```

#### Alternative: Quote Variables in Bash

Also update bash script to quote variables when used:

```bash
# BEFORE:
single_ansi=$(hex_to_ansi "$single_color")

# AFTER (belt and suspenders):
if [[ "$single_color" =~ ^#[0-9A-Fa-f]{6}$ ]]; then
    single_ansi=$(hex_to_ansi "$single_color")
else
    single_color="#00BFFF"  # Fallback to default
    single_ansi=$(hex_to_ansi "$single_color")
fi
```

---

## Issue #4: Organization ID Not Validated ✅ COMPLETE

### Original Problem
- Organization ID from API response used directly in URL path
- No validation before embedding in URL
- Potential for path traversal attacks

### Solution Implemented

Added `isValidPathSegment()` validation to URLBuilder and validation in ClaudeAPIService.

**Changes:**
1. Added `URLBuilder.isValidPathSegment()` method that validates:
   - Non-empty, max 128 chars
   - Only alphanumeric, hyphens, underscores
   - No path traversal characters (`..`, `/`, `\\`)

2. Added validation in `ClaudeAPIService.swift`:
   - `fetchUsageData()` validates org ID before URL construction
   - `sendInitializationMessage()` validates org ID before URL construction

**Files Modified:**
- `URLBuilder.swift` - Added `isValidPathSegment()` and `appendingValidatedPathSegment()`
- `ClaudeAPIService.swift` - Added org ID validation checks

---

## Issue #5: Pretty-Printed JSON in ProfileStore ✅ COMPLETE

### Original Problem
```swift
encoder.outputFormatting = .prettyPrinted // For debugging
```
Pretty-printed JSON makes stored data more human-readable, which could aid attackers.

### Solution Implemented

Wrapped pretty printing in `#if DEBUG` conditional compilation.

```swift
#if DEBUG
encoder.outputFormatting = .prettyPrinted // Only in debug builds
#endif
```

**File Modified:** `ProfileStore.swift:34`

---

## Implementation Order

1. ✅ **Issue #1** (Critical) - Protected credentials file (0600 permissions)
2. ✅ **Issue #2** (High) - Per-profile Keychain storage
3. ✅ **Issue #3** (Medium) - Hex color validation
4. ✅ **Issue #5** (Low) - Remove pretty printing
5. ✅ **Issue #4** (Low) - Org ID validation

**All security fixes are now complete.**

---

## Notes

- All changes maintain backward compatibility during migration
- Existing users' credentials are automatically migrated to Keychain on first app launch
- Migration is transparent - no user action required
- Credentials are stored in app-scoped Keychain (no user prompts)
