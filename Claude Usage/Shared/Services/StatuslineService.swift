import Foundation

/// Service for managing Claude Code statusline configuration.
/// This service handles installation, configuration, and management of the statusline feature
/// for Claude Code terminal integration.
///
/// Security: Credentials are stored in a protected file (~/.claude/.credentials) with 0600 permissions.
/// Only the file owner can read/write. No secrets are embedded in scripts.
class StatuslineService {
    static let shared = StatuslineService()

    private init() {}

    // MARK: - Credentials File

    /// Path to the protected credentials file
    private var credentialsFileURL: URL {
        Constants.ClaudePaths.claudeDirectory.appendingPathComponent(".credentials")
    }

    /// Writes credentials to a protected file with 0600 permissions
    private func writeCredentialsFile(sessionKey: String, organizationId: String) throws {
        let claudeDir = Constants.ClaudePaths.claudeDirectory

        if !FileManager.default.fileExists(atPath: claudeDir.path) {
            try FileManager.default.createDirectory(at: claudeDir, withIntermediateDirectories: true)
        }

        // Format: SESSION_KEY=xxx\nORGANIZATION_ID=xxx
        let content = """
        SESSION_KEY=\(sessionKey)
        ORGANIZATION_ID=\(organizationId)
        """

        try content.write(to: credentialsFileURL, atomically: true, encoding: .utf8)

        // Set restrictive permissions: owner read/write only (0600)
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o600],
            ofItemAtPath: credentialsFileURL.path
        )

        LoggingService.shared.log("Credentials written to protected file with 0600 permissions")
    }

    /// Removes the credentials file
    private func removeCredentialsFile() throws {
        if FileManager.default.fileExists(atPath: credentialsFileURL.path) {
            try FileManager.default.removeItem(at: credentialsFileURL)
            LoggingService.shared.log("Removed credentials file")
        }
    }

    // MARK: - Swift Script

    /// Swift script that fetches Claude usage data from the API.
    /// Reads credentials from protected file at runtime - no embedded secrets.
    private let swiftScript = """
#!/usr/bin/env swift

import Foundation

// Read credentials from protected file
func readCredentials() -> (sessionKey: String, orgId: String)? {
    let credentialsPath = NSString(string: "~/.claude/.credentials").expandingTildeInPath

    guard let content = try? String(contentsOfFile: credentialsPath, encoding: .utf8) else {
        return nil
    }

    var sessionKey: String?
    var orgId: String?

    for line in content.components(separatedBy: .newlines) {
        let parts = line.split(separator: "=", maxSplits: 1)
        guard parts.count == 2 else { continue }

        let key = String(parts[0]).trimmingCharacters(in: .whitespaces)
        let value = String(parts[1]).trimmingCharacters(in: .whitespaces)

        switch key {
        case "SESSION_KEY":
            sessionKey = value
        case "ORGANIZATION_ID":
            orgId = value
        default:
            break
        }
    }

    guard let sk = sessionKey, !sk.isEmpty,
          let oid = orgId, !oid.isEmpty else {
        return nil
    }

    return (sk, oid)
}

func fetchUsageData(sessionKey: String, orgId: String) async throws -> (utilization: Int, resetsAt: String?) {
    // Validate org ID doesn't contain path traversal
    guard !orgId.contains(".."), !orgId.contains("/") else {
        throw NSError(domain: "ClaudeAPI", code: 5, userInfo: [NSLocalizedDescriptionKey: "Invalid organization ID"])
    }

    guard let url = URL(string: "https://claude.ai/api/organizations/\\(orgId)/usage") else {
        throw NSError(domain: "ClaudeAPI", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
    }

    var request = URLRequest(url: url)
    request.setValue("sessionKey=\\(sessionKey)", forHTTPHeaderField: "Cookie")
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.httpMethod = "GET"
    request.timeoutInterval = 10

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse,
          httpResponse.statusCode == 200 else {
        throw NSError(domain: "ClaudeAPI", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch usage"])
    }

    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
       let fiveHour = json["five_hour"] as? [String: Any],
       let utilization = fiveHour["utilization"] as? Int {
        let resetsAt = fiveHour["resets_at"] as? String
        return (utilization, resetsAt)
    }

    throw NSError(domain: "ClaudeAPI", code: 4, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])
}

// Main execution
Task {
    guard let credentials = readCredentials() else {
        print("ERROR:NO_CREDENTIALS")
        exit(1)
    }

    do {
        let (utilization, resetsAt) = try await fetchUsageData(
            sessionKey: credentials.sessionKey,
            orgId: credentials.orgId
        )

        // Output format: UTILIZATION|RESETS_AT
        if let resets = resetsAt {
            print("\\(utilization)|\\(resets)")
        } else {
            print("\\(utilization)|")
        }
        exit(0)
    } catch {
        print("ERROR:\\(error.localizedDescription)")
        exit(1)
    }
}

// Keep script alive while async Task executes
RunLoop.main.run()
"""

    /// Placeholder script for when statusline is disabled
    private let placeholderScript = """
#!/usr/bin/env swift

import Foundation

// Statusline disabled - no credentials available
print("ERROR:NO_CREDENTIALS")
exit(1)
"""

    // MARK: - Bash Script

    /// Bash script that builds the statusline display.
    private let bashScript = """
#!/bin/bash
config_file="$HOME/.claude/statusline-config.txt"
if [ -f "$config_file" ]; then
  # Validate config file contains only expected variable assignments
  if grep -qE '^[A-Z_]+=' "$config_file" && ! grep -qE '[;&|`$()]' "$config_file"; then
    source "$config_file"
  fi
  show_dir=${SHOW_DIRECTORY:-1}
  show_branch=${SHOW_BRANCH:-1}
  show_usage=${SHOW_USAGE:-1}
  show_bar=${SHOW_PROGRESS_BAR:-1}
  show_reset=${SHOW_RESET_TIME:-1}
  use_24h=${USE_24_HOUR_TIME:-0}
  show_usage_label=${SHOW_USAGE_LABEL:-1}
  show_reset_label=${SHOW_RESET_LABEL:-1}
  color_mode=${COLOR_MODE:-colored}
  single_color=${SINGLE_COLOR:-#00BFFF}
else
  show_dir=1
  show_branch=1
  show_usage=1
  show_bar=1
  show_reset=1
  use_24h=0
  show_usage_label=1
  show_reset_label=1
  color_mode="colored"
  single_color="#00BFFF"
fi

# Validate hex color format (security: prevent injection)
if ! [[ "$single_color" =~ ^#[0-9A-Fa-f]{6}$ ]]; then
  single_color="#00BFFF"
fi

input=$(cat)
current_dir_path=$(echo "$input" | grep -o '"current_dir":"[^"]*"' | sed 's/"current_dir":"//;s/"$//')
current_dir=$(basename "$current_dir_path")

# Function to convert hex color to ANSI escape code
hex_to_ansi() {
  local hex=$1
  hex=${hex#\\#}

  local r=$((16#${hex:0:2}))
  local g=$((16#${hex:2:2}))
  local b=$((16#${hex:4:2}))

  printf '\\033[38;2;%d;%d;%dm' "$r" "$g" "$b"
}

# Set colors based on mode
RESET=$'\\033[0m'

if [ "$color_mode" = "monochrome" ]; then
  BLUE=""
  GREEN=""
  GRAY=""
  YELLOW=""
  LEVEL_1=""
  LEVEL_2=""
  LEVEL_3=""
  LEVEL_4=""
  LEVEL_5=""
  LEVEL_6=""
  LEVEL_7=""
  LEVEL_8=""
  LEVEL_9=""
  LEVEL_10=""
elif [ "$color_mode" = "singleColor" ]; then
  single_ansi=$(hex_to_ansi "$single_color")
  BLUE=$single_ansi
  GREEN=$single_ansi
  GRAY=$single_ansi
  YELLOW=$single_ansi
  LEVEL_1=$single_ansi
  LEVEL_2=$single_ansi
  LEVEL_3=$single_ansi
  LEVEL_4=$single_ansi
  LEVEL_5=$single_ansi
  LEVEL_6=$single_ansi
  LEVEL_7=$single_ansi
  LEVEL_8=$single_ansi
  LEVEL_9=$single_ansi
  LEVEL_10=$single_ansi
else
  BLUE=$'\\033[0;34m'
  GREEN=$'\\033[0;32m'
  GRAY=$'\\033[0;90m'
  YELLOW=$'\\033[0;33m'

  LEVEL_1=$'\\033[38;5;22m'
  LEVEL_2=$'\\033[38;5;28m'
  LEVEL_3=$'\\033[38;5;34m'
  LEVEL_4=$'\\033[38;5;100m'
  LEVEL_5=$'\\033[38;5;142m'
  LEVEL_6=$'\\033[38;5;178m'
  LEVEL_7=$'\\033[38;5;172m'
  LEVEL_8=$'\\033[38;5;166m'
  LEVEL_9=$'\\033[38;5;160m'
  LEVEL_10=$'\\033[38;5;124m'
fi

dir_text=""
if [ "$show_dir" = "1" ]; then
  dir_text="${BLUE}${current_dir}${RESET}"
fi

branch_text=""
if [ "$show_branch" = "1" ]; then
  if git rev-parse --git-dir > /dev/null 2>&1; then
    branch=$(git branch --show-current 2>/dev/null)
    [ -n "$branch" ] && branch_text="${GREEN}⎇ ${branch}${RESET}"
  fi
fi

usage_text=""
if [ "$show_usage" = "1" ]; then
  swift_result=$(swift "$HOME/.claude/fetch-claude-usage.swift" 2>/dev/null)

  if [ $? -eq 0 ] && [ -n "$swift_result" ]; then
    utilization=$(echo "$swift_result" | cut -d'|' -f1)
    resets_at=$(echo "$swift_result" | cut -d'|' -f2)

    if [ -n "$utilization" ] && [ "$utilization" != "ERROR" ]; then
      if [ "$utilization" -le 10 ]; then
        usage_color="$LEVEL_1"
      elif [ "$utilization" -le 20 ]; then
        usage_color="$LEVEL_2"
      elif [ "$utilization" -le 30 ]; then
        usage_color="$LEVEL_3"
      elif [ "$utilization" -le 40 ]; then
        usage_color="$LEVEL_4"
      elif [ "$utilization" -le 50 ]; then
        usage_color="$LEVEL_5"
      elif [ "$utilization" -le 60 ]; then
        usage_color="$LEVEL_6"
      elif [ "$utilization" -le 70 ]; then
        usage_color="$LEVEL_7"
      elif [ "$utilization" -le 80 ]; then
        usage_color="$LEVEL_8"
      elif [ "$utilization" -le 90 ]; then
        usage_color="$LEVEL_9"
      else
        usage_color="$LEVEL_10"
      fi

      if [ "$show_bar" = "1" ]; then
        if [ "$utilization" -eq 0 ]; then
          filled_blocks=0
        elif [ "$utilization" -eq 100 ]; then
          filled_blocks=10
        else
          filled_blocks=$(( (utilization * 10 + 50) / 100 ))
        fi
        [ "$filled_blocks" -lt 0 ] && filled_blocks=0
        [ "$filled_blocks" -gt 10 ] && filled_blocks=10
        empty_blocks=$((10 - filled_blocks))

        progress_bar=" "
        i=0
        while [ $i -lt $filled_blocks ]; do
          progress_bar="${progress_bar}▓"
          i=$((i + 1))
        done
        i=0
        while [ $i -lt $empty_blocks ]; do
          progress_bar="${progress_bar}░"
          i=$((i + 1))
        done
      else
        progress_bar=""
      fi

      reset_time_display=""
      if [ "$show_reset" = "1" ] && [ -n "$resets_at" ] && [ "$resets_at" != "null" ]; then
        iso_time=$(echo "$resets_at" | sed 's/\\.[0-9]*Z$//')
        epoch=$(date -ju -f "%Y-%m-%dT%H:%M:%S" "$iso_time" "+%s" 2>/dev/null)

        if [ -n "$epoch" ]; then
          seconds_part=$((epoch % 60))
          if [ "$seconds_part" -ge 30 ]; then
            epoch=$((epoch + (60 - seconds_part)))
          else
            epoch=$((epoch - seconds_part))
          fi

          if [ "$use_24h" = "1" ]; then
            reset_time=$(date -r "$epoch" "+%H:%M" 2>/dev/null)
          else
            reset_time=$(date -r "$epoch" "+%I:%M %p" 2>/dev/null)
          fi
          if [ "$show_reset_label" = "1" ]; then
            [ -n "$reset_time" ] && reset_time_display=$(printf " → Reset: %s" "$reset_time")
          else
            [ -n "$reset_time" ] && reset_time_display=$(printf " → %s" "$reset_time")
          fi
        fi
      fi

      if [ "$show_usage_label" = "1" ]; then
        usage_text="${usage_color}Usage: ${utilization}%${progress_bar}${reset_time_display}${RESET}"
      else
        usage_text="${usage_color}${utilization}%${progress_bar}${reset_time_display}${RESET}"
      fi
    else
      if [ "$show_usage_label" = "1" ]; then
        usage_text="${YELLOW}Usage: ~${RESET}"
      else
        usage_text="${YELLOW}~${RESET}"
      fi
    fi
  else
    if [ "$show_usage_label" = "1" ]; then
      usage_text="${YELLOW}Usage: ~${RESET}"
    else
      usage_text="${YELLOW}~${RESET}"
    fi
  fi
fi

output=""
separator="${GRAY} │ ${RESET}"

[ -n "$dir_text" ] && output="${dir_text}"

if [ -n "$branch_text" ]; then
  [ -n "$output" ] && output="${output}${separator}"
  output="${output}${branch_text}"
fi

if [ -n "$usage_text" ]; then
  [ -n "$output" ] && output="${output}${separator}"
  output="${output}${usage_text}"
fi

printf "%s\\n" "$output"
"""

    // MARK: - Installation

    /// Installs statusline scripts and optionally writes credentials to protected file
    func installScripts(withCredentials: Bool = false) throws {
        let claudeDir = Constants.ClaudePaths.claudeDirectory

        if !FileManager.default.fileExists(atPath: claudeDir.path) {
            try FileManager.default.createDirectory(at: claudeDir, withIntermediateDirectories: true)
        }

        // Install Swift script
        let swiftDestination = claudeDir.appendingPathComponent("fetch-claude-usage.swift")
        let scriptContent: String

        if withCredentials {
            guard let activeProfile = ProfileManager.shared.activeProfile else {
                throw StatuslineError.noActiveProfile
            }

            guard let sessionKey = activeProfile.claudeSessionKey else {
                throw StatuslineError.sessionKeyNotFound
            }

            guard let organizationId = activeProfile.organizationId else {
                throw StatuslineError.organizationNotConfigured
            }

            // Write credentials to protected file
            try writeCredentialsFile(sessionKey: sessionKey, organizationId: organizationId)
            scriptContent = swiftScript
            LoggingService.shared.log("Installed statusline with credentials for profile '\(activeProfile.name)'")
        } else {
            scriptContent = placeholderScript
            LoggingService.shared.log("Installed placeholder statusline script")
        }

        try scriptContent.write(to: swiftDestination, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o755],
            ofItemAtPath: swiftDestination.path
        )

        // Install bash script
        let bashDestination = claudeDir.appendingPathComponent("statusline-command.sh")
        try bashScript.write(to: bashDestination, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o755],
            ofItemAtPath: bashDestination.path
        )

        LoggingService.shared.log("Scripts installed to: \(claudeDir.path)")
    }

    /// Removes credentials file (disables statusline)
    func removeCredentials() throws {
        try removeCredentialsFile()

        // Replace script with placeholder
        let swiftDestination = Constants.ClaudePaths.claudeDirectory
            .appendingPathComponent("fetch-claude-usage.swift")
        try placeholderScript.write(to: swiftDestination, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o755],
            ofItemAtPath: swiftDestination.path
        )
    }

    // MARK: - Configuration

    /// Validates that a hex color string is in the correct format
    private func isValidHexColor(_ hex: String) -> Bool {
        let pattern = "^#[0-9A-Fa-f]{6}$"
        return hex.range(of: pattern, options: .regularExpression) != nil
    }

    func updateConfiguration(
        showDirectory: Bool,
        showBranch: Bool,
        showUsage: Bool,
        showProgressBar: Bool,
        showResetTime: Bool,
        use24HourTime: Bool = false,
        showUsageLabel: Bool = true,
        showResetLabel: Bool = true,
        colorMode: StatuslineColorMode = .colored,
        singleColorHex: String = "#00BFFF"
    ) throws {
        // Validate hex color to prevent injection
        let safeColorHex: String
        if isValidHexColor(singleColorHex) {
            safeColorHex = singleColorHex
        } else {
            LoggingService.shared.logError("Invalid hex color format: \(singleColorHex), using default")
            safeColorHex = "#00BFFF"
        }

        let configPath = Constants.ClaudePaths.claudeDirectory
            .appendingPathComponent("statusline-config.txt")

        let colorModeString: String
        switch colorMode {
        case .colored:
            colorModeString = "colored"
        case .monochrome:
            colorModeString = "monochrome"
        case .singleColor:
            colorModeString = "singleColor"
        }

        let config = """
SHOW_DIRECTORY=\(showDirectory ? "1" : "0")
SHOW_BRANCH=\(showBranch ? "1" : "0")
SHOW_USAGE=\(showUsage ? "1" : "0")
SHOW_PROGRESS_BAR=\(showProgressBar ? "1" : "0")
SHOW_RESET_TIME=\(showResetTime ? "1" : "0")
USE_24_HOUR_TIME=\(use24HourTime ? "1" : "0")
SHOW_USAGE_LABEL=\(showUsageLabel ? "1" : "0")
SHOW_RESET_LABEL=\(showResetLabel ? "1" : "0")
COLOR_MODE=\(colorModeString)
SINGLE_COLOR=\(safeColorHex)
"""

        try config.write(to: configPath, atomically: true, encoding: .utf8)
        LoggingService.shared.log("Config written to: \(configPath.path)")
    }

    /// Enables or disables statusline in Claude Code settings.json
    func updateClaudeCodeSettings(enabled: Bool) throws {
        let settingsPath = Constants.ClaudePaths.claudeDirectory
            .appendingPathComponent("settings.json")

        let homeDir = Constants.ClaudePaths.homeDirectory.path
        let commandPath = "\(homeDir)/.claude/statusline-command.sh"

        if enabled {
            // Install scripts with credentials
            try installScripts(withCredentials: true)

            // Update settings.json
            var settings: [String: Any] = [:]

            if FileManager.default.fileExists(atPath: settingsPath.path) {
                let existingData = try Data(contentsOf: settingsPath)
                if let existing = try JSONSerialization.jsonObject(with: existingData) as? [String: Any] {
                    settings = existing
                }
            }

            settings["statusLine"] = [
                "type": "command",
                "command": "bash \(commandPath)"
            ]

            let jsonData = try JSONSerialization.data(withJSONObject: settings, options: .prettyPrinted)
            try jsonData.write(to: settingsPath)
        } else {
            // Remove credentials
            try removeCredentials()

            // Update settings.json
            if FileManager.default.fileExists(atPath: settingsPath.path) {
                let existingData = try Data(contentsOf: settingsPath)
                if var settings = try JSONSerialization.jsonObject(with: existingData) as? [String: Any] {
                    settings.removeValue(forKey: "statusLine")

                    let jsonData = try JSONSerialization.data(withJSONObject: settings, options: .prettyPrinted)
                    try jsonData.write(to: settingsPath)
                }
            }
        }
    }

    // MARK: - Status

    var isInstalled: Bool {
        let swiftScript = Constants.ClaudePaths.claudeDirectory
            .appendingPathComponent("fetch-claude-usage.swift")

        let bashScript = Constants.ClaudePaths.claudeDirectory
            .appendingPathComponent("statusline-command.sh")

        return FileManager.default.fileExists(atPath: swiftScript.path) &&
               FileManager.default.fileExists(atPath: bashScript.path)
    }

    /// Updates scripts only if already installed
    func updateScriptsIfInstalled() throws {
        guard isInstalled else { return }
        try installScripts(withCredentials: true)
    }

    /// Checks if active profile has a valid session key
    func hasValidSessionKey() -> Bool {
        guard let activeProfile = ProfileManager.shared.activeProfile,
              let key = activeProfile.claudeSessionKey else {
            return false
        }

        let validator = SessionKeyValidator()
        return validator.isValid(key)
    }

    /// Checks if credentials file exists
    func hasCredentialsFile() -> Bool {
        return FileManager.default.fileExists(atPath: credentialsFileURL.path)
    }
}

// MARK: - StatuslineError

enum StatuslineError: Error, LocalizedError {
    case noActiveProfile
    case sessionKeyNotFound
    case organizationNotConfigured
    case invalidHexColor

    var errorDescription: String? {
        switch self {
        case .noActiveProfile:
            return "No active profile found. Please create or select a profile first."
        case .sessionKeyNotFound:
            return "Session key not found in active profile. Please configure your session key first."
        case .organizationNotConfigured:
            return "Organization not configured in active profile. Please select an organization in the app settings."
        case .invalidHexColor:
            return "Invalid hex color format. Please use format #RRGGBB."
        }
    }
}
