//
//  ProfileStore.swift
//  Claude Usage
//
//  Created by Claude Code on 2026-01-07.
//

import Foundation

/// Manages storage and retrieval of profiles and profile-related data
/// Security: Credentials are stored in Keychain, not in UserDefaults JSON
class ProfileStore {
    static let shared = ProfileStore()

    private let defaults: UserDefaults
    private let keychainService = KeychainService.shared

    private enum Keys {
        static let profiles = "profiles_v3"
        static let activeProfileId = "activeProfileId"
        static let displayMode = "profileDisplayMode"
        static let credentialsMigrated = "credentialsMigratedToKeychain"
    }

    init() {
        // Use standard UserDefaults (app container)
        self.defaults = UserDefaults.standard
        LoggingService.shared.log("ProfileStore: Using standard app container storage")
    }

    // MARK: - Profile Management

    /// Saves profiles to storage
    /// Credentials are extracted and stored in Keychain separately
    func saveProfiles(_ profiles: [Profile]) {
        do {
            // Save credentials to Keychain for each profile
            for profile in profiles {
                saveCredentialsToKeychain(for: profile)
            }

            // Create profiles without credentials for JSON storage
            var sanitizedProfiles = profiles
            for i in sanitizedProfiles.indices {
                sanitizedProfiles[i].claudeSessionKey = nil
                sanitizedProfiles[i].apiSessionKey = nil
                sanitizedProfiles[i].cliCredentialsJSON = nil
            }

            let encoder = JSONEncoder()
            #if DEBUG
            encoder.outputFormatting = .prettyPrinted // Only in debug builds
            #endif
            let data = try encoder.encode(sanitizedProfiles)
            defaults.set(data, forKey: Keys.profiles)

            // Verify save
            if let savedData = defaults.data(forKey: Keys.profiles) {
                LoggingService.shared.log("ProfileStore: Saved \(profiles.count) profiles (\(savedData.count) bytes, credentials in Keychain)")
            } else {
                LoggingService.shared.logError("ProfileStore: Failed to verify save!")
            }
        } catch {
            LoggingService.shared.logStorageError("saveProfiles", error: error)
        }
    }

    /// Loads profiles from storage
    /// Credentials are loaded from Keychain and populated into profiles
    func loadProfiles() -> [Profile] {
        guard let data = defaults.data(forKey: Keys.profiles) else {
            LoggingService.shared.log("ProfileStore: No profiles found in storage")
            return []
        }

        do {
            var profiles = try JSONDecoder().decode([Profile].self, from: data)

            // Check for legacy credentials and migrate if needed
            var needsResave = false
            for i in profiles.indices {
                if migrateCredentialsIfNeeded(for: &profiles[i]) {
                    needsResave = true
                }
                // Load credentials from Keychain
                loadCredentialsFromKeychain(for: &profiles[i])
            }

            // If we migrated any credentials, resave to clear them from JSON
            if needsResave {
                LoggingService.shared.log("ProfileStore: Resaving profiles after credential migration")
                saveProfiles(profiles)
            }

            LoggingService.shared.log("ProfileStore: Loaded \(profiles.count) profiles from storage")
            return profiles
        } catch {
            LoggingService.shared.logStorageError("loadProfiles", error: error)
            LoggingService.shared.logError("ProfileStore: Failed to decode profiles, returning empty array")
            return []
        }
    }

    func saveActiveProfileId(_ id: UUID) {
        defaults.set(id.uuidString, forKey: Keys.activeProfileId)
    }

    func loadActiveProfileId() -> UUID? {
        guard let uuidString = defaults.string(forKey: Keys.activeProfileId) else {
            return nil
        }
        return UUID(uuidString: uuidString)
    }

    func saveDisplayMode(_ mode: ProfileDisplayMode) {
        defaults.set(mode.rawValue, forKey: Keys.displayMode)
    }

    func loadDisplayMode() -> ProfileDisplayMode {
        guard let rawValue = defaults.string(forKey: Keys.displayMode),
              let mode = ProfileDisplayMode(rawValue: rawValue) else {
            return .single
        }
        return mode
    }

    // MARK: - Credential Helpers

    /// Saves credentials for a profile (updates Keychain and profile store)
    func saveProfileCredentials(_ profileId: UUID, credentials: ProfileCredentials) throws {
        var profiles = loadProfiles()
        guard let index = profiles.firstIndex(where: { $0.id == profileId }) else {
            throw NSError(domain: "ProfileStore", code: 404, userInfo: [NSLocalizedDescriptionKey: "Profile not found"])
        }

        // Update credentials in memory (will be saved to Keychain by saveProfiles)
        profiles[index].claudeSessionKey = credentials.claudeSessionKey
        profiles[index].organizationId = credentials.organizationId
        profiles[index].apiSessionKey = credentials.apiSessionKey
        profiles[index].apiOrganizationId = credentials.apiOrganizationId
        profiles[index].cliCredentialsJSON = credentials.cliCredentialsJSON

        saveProfiles(profiles)
    }

    /// Loads credentials for a profile (from Keychain)
    func loadProfileCredentials(_ profileId: UUID) throws -> ProfileCredentials {
        let profiles = loadProfiles()
        guard let profile = profiles.first(where: { $0.id == profileId }) else {
            throw NSError(domain: "ProfileStore", code: 404, userInfo: [NSLocalizedDescriptionKey: "Profile not found"])
        }

        return ProfileCredentials(
            claudeSessionKey: profile.claudeSessionKey,
            organizationId: profile.organizationId,
            apiSessionKey: profile.apiSessionKey,
            apiOrganizationId: profile.apiOrganizationId,
            cliCredentialsJSON: profile.cliCredentialsJSON
        )
    }

    /// Deletes all credentials for a profile from Keychain
    func deleteProfileCredentials(_ profileId: UUID) {
        keychainService.deleteAllProfileCredentials(profileId: profileId)
    }

    // MARK: - Private Keychain Helpers

    /// Saves credentials from a profile to Keychain
    private func saveCredentialsToKeychain(for profile: Profile) {
        do {
            if let claudeKey = profile.claudeSessionKey {
                try keychainService.saveProfileCredential(claudeKey, type: .claudeSessionKey, profileId: profile.id)
            }
            if let apiKey = profile.apiSessionKey {
                try keychainService.saveProfileCredential(apiKey, type: .apiSessionKey, profileId: profile.id)
            }
            if let cliJSON = profile.cliCredentialsJSON {
                try keychainService.saveProfileCredential(cliJSON, type: .cliCredentialsJSON, profileId: profile.id)
            }
        } catch {
            LoggingService.shared.logError("ProfileStore: Failed to save credentials to Keychain for profile \(profile.id): \(error)")
        }
    }

    /// Loads credentials from Keychain into a profile
    private func loadCredentialsFromKeychain(for profile: inout Profile) {
        do {
            profile.claudeSessionKey = try keychainService.loadProfileCredential(type: .claudeSessionKey, profileId: profile.id)
            profile.apiSessionKey = try keychainService.loadProfileCredential(type: .apiSessionKey, profileId: profile.id)
            profile.cliCredentialsJSON = try keychainService.loadProfileCredential(type: .cliCredentialsJSON, profileId: profile.id)
        } catch {
            LoggingService.shared.logError("ProfileStore: Failed to load credentials from Keychain for profile \(profile.id): \(error)")
        }
    }

    /// Migrates credentials from JSON storage to Keychain (one-time migration)
    /// Returns true if migration was performed
    private func migrateCredentialsIfNeeded(for profile: inout Profile) -> Bool {
        var migrated = false

        // Check if profile has credentials in JSON that need migration
        if let claudeKey = profile.claudeSessionKey, !claudeKey.isEmpty {
            do {
                // Check if already in Keychain
                if try keychainService.loadProfileCredential(type: .claudeSessionKey, profileId: profile.id) == nil {
                    try keychainService.saveProfileCredential(claudeKey, type: .claudeSessionKey, profileId: profile.id)
                    LoggingService.shared.log("ProfileStore: Migrated claudeSessionKey to Keychain for profile \(profile.id)")
                    migrated = true
                }
            } catch {
                LoggingService.shared.logError("ProfileStore: Failed to migrate claudeSessionKey: \(error)")
            }
        }

        if let apiKey = profile.apiSessionKey, !apiKey.isEmpty {
            do {
                if try keychainService.loadProfileCredential(type: .apiSessionKey, profileId: profile.id) == nil {
                    try keychainService.saveProfileCredential(apiKey, type: .apiSessionKey, profileId: profile.id)
                    LoggingService.shared.log("ProfileStore: Migrated apiSessionKey to Keychain for profile \(profile.id)")
                    migrated = true
                }
            } catch {
                LoggingService.shared.logError("ProfileStore: Failed to migrate apiSessionKey: \(error)")
            }
        }

        if let cliJSON = profile.cliCredentialsJSON, !cliJSON.isEmpty {
            do {
                if try keychainService.loadProfileCredential(type: .cliCredentialsJSON, profileId: profile.id) == nil {
                    try keychainService.saveProfileCredential(cliJSON, type: .cliCredentialsJSON, profileId: profile.id)
                    LoggingService.shared.log("ProfileStore: Migrated cliCredentialsJSON to Keychain for profile \(profile.id)")
                    migrated = true
                }
            } catch {
                LoggingService.shared.logError("ProfileStore: Failed to migrate cliCredentialsJSON: \(error)")
            }
        }

        return migrated
    }
}
