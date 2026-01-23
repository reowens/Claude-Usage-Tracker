//
//  KeychainService.swift
//  Claude Usage
//
//  Created by Claude Code on 2025-12-28.
//

import Foundation
import Security

/// Service for secure storage and retrieval of sensitive data using macOS Keychain
class KeychainService {
    static let shared = KeychainService()

    /// Shared keychain access group for helper binary access
    /// Format: TeamID.bundleIdentifier
    private let sharedAccessGroup = "7GSPYYN5X8.com.claudeusagetracker.shared"

    private init() {}

    /// Keychain item identifiers
    enum KeychainKey: String {
        case apiSessionKey = "com.claudeusagetracker.api-session-key"
        case claudeSessionKey = "com.claudeusagetracker.claude-session-key"
        case organizationId = "com.claudeusagetracker.organization-id"

        var service: String {
            return rawValue
        }

        var account: String {
            return "session-key"
        }

        /// Whether this key should be stored in the shared access group
        /// NOTE: Disabled - shared access group was planned for helper binary but abandoned
        /// All keys now use app-scoped storage (no access group = invisible to user)
        var useSharedAccessGroup: Bool {
            return false  // Shared access group not in use
        }
    }

    // MARK: - Public Methods

    /// Saves a string value to the Keychain
    /// - Parameters:
    ///   - value: The string value to save
    ///   - key: The keychain key identifier
    /// - Throws: KeychainError if save fails
    func save(_ value: String, for key: KeychainKey) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.invalidData
        }

        // Build base query
        var updateQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: key.service,
            kSecAttrAccount as String: key.account
        ]

        // Add shared access group if this key needs it
        if key.useSharedAccessGroup {
            updateQuery[kSecAttrAccessGroup as String] = sharedAccessGroup
        }

        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]

        let updateStatus = SecItemUpdate(updateQuery as CFDictionary, attributes as CFDictionary)

        if updateStatus == errSecSuccess {
            LoggingService.shared.log("Keychain: Updated \(key.service)")
            return
        }

        // If update fails because item doesn't exist, add new item
        if updateStatus == errSecItemNotFound {
            // Create access control that doesn't require password
            var accessControlError: Unmanaged<CFError>?
            guard let accessControl = SecAccessControlCreateWithFlags(
                kCFAllocatorDefault,
                kSecAttrAccessibleWhenUnlocked,
                [],
                &accessControlError
            ) else {
                if let error = accessControlError?.takeRetainedValue() {
                    LoggingService.shared.log("Failed to create access control: \(error)")
                }
                throw KeychainError.saveFailed(status: errSecParam)
            }

            var addQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: key.service,
                kSecAttrAccount as String: key.account,
                kSecValueData as String: data,
                kSecAttrAccessControl as String: accessControl,
                kSecAttrSynchronizable as String: false
            ]

            // Add shared access group if this key needs it
            if key.useSharedAccessGroup {
                addQuery[kSecAttrAccessGroup as String] = sharedAccessGroup
            }

            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)

            if addStatus == errSecSuccess {
                LoggingService.shared.log("Keychain: Added \(key.service)\(key.useSharedAccessGroup ? " (shared)" : "")")
                return
            } else {
                throw KeychainError.saveFailed(status: addStatus)
            }
        } else {
            throw KeychainError.saveFailed(status: updateStatus)
        }
    }

    /// Loads a string value from the Keychain
    /// - Parameter key: The keychain key identifier
    /// - Returns: The stored string value, or nil if not found
    /// - Throws: KeychainError if load fails (other than item not found)
    func load(for key: KeychainKey) throws -> String? {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: key.service,
            kSecAttrAccount as String: key.account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        // Add shared access group if this key needs it
        if key.useSharedAccessGroup {
            query[kSecAttrAccessGroup as String] = sharedAccessGroup
        }

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecSuccess {
            guard let data = result as? Data,
                  let value = String(data: data, encoding: .utf8) else {
                throw KeychainError.invalidData
            }
            LoggingService.shared.log("Keychain: Loaded \(key.service)")
            return value
        } else if status == errSecItemNotFound {
            LoggingService.shared.log("Keychain: Item not found \(key.service)")
            return nil
        } else {
            throw KeychainError.loadFailed(status: status)
        }
    }

    /// Deletes a value from the Keychain
    /// - Parameter key: The keychain key identifier
    /// - Throws: KeychainError if delete fails (ignores item not found)
    func delete(for key: KeychainKey) throws {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: key.service,
            kSecAttrAccount as String: key.account
        ]

        // Add shared access group if this key needs it
        if key.useSharedAccessGroup {
            query[kSecAttrAccessGroup as String] = sharedAccessGroup
        }

        let status = SecItemDelete(query as CFDictionary)

        if status == errSecSuccess {
            LoggingService.shared.log("Keychain: Deleted \(key.service)")
        } else if status == errSecItemNotFound {
            // Item not found is not an error for delete
            LoggingService.shared.log("Keychain: Item not found for deletion \(key.service)")
        } else {
            throw KeychainError.deleteFailed(status: status)
        }
    }

    /// Checks if a value exists in the Keychain
    /// - Parameter key: The keychain key identifier
    /// - Returns: true if the item exists, false otherwise
    func exists(for key: KeychainKey) -> Bool {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: key.service,
            kSecAttrAccount as String: key.account,
            kSecReturnData as String: false
        ]

        // Add shared access group if this key needs it
        if key.useSharedAccessGroup {
            query[kSecAttrAccessGroup as String] = sharedAccessGroup
        }

        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    // MARK: - Migration

    /// Migrates a keychain item from non-shared to shared access group.
    /// This is needed when upgrading from older versions that stored keys without access groups.
    /// - Parameter key: The keychain key to migrate
    /// - Returns: true if migration was performed, false if no migration needed
    @discardableResult
    func migrateToSharedAccessGroup(for key: KeychainKey) -> Bool {
        guard key.useSharedAccessGroup else {
            return false // Key doesn't need shared access
        }

        // Check if key already exists in shared group
        if exists(for: key) {
            return false // Already migrated
        }

        // Try to load from non-shared (legacy) location
        let legacyQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: key.service,
            kSecAttrAccount as String: key.account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
            // No access group = app-specific storage
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(legacyQuery as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return false // No legacy item found
        }

        // Save to shared group
        do {
            try save(value, for: key)
            LoggingService.shared.log("Keychain: Migrated \(key.service) to shared access group")

            // Delete legacy item
            let deleteQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: key.service,
                kSecAttrAccount as String: key.account
            ]
            SecItemDelete(deleteQuery as CFDictionary)

            return true
        } catch {
            LoggingService.shared.logError("Keychain: Failed to migrate \(key.service): \(error)")
            return false
        }
    }

    /// Migrates all applicable keys to shared access group
    func migrateAllToSharedAccessGroup() {
        migrateToSharedAccessGroup(for: .claudeSessionKey)
        // organizationId is new, no migration needed
    }
}

// MARK: - KeychainError

enum KeychainError: Error, LocalizedError {
    case invalidData
    case saveFailed(status: OSStatus)
    case loadFailed(status: OSStatus)
    case deleteFailed(status: OSStatus)

    var errorDescription: String? {
        switch self {
        case .invalidData:
            return "Invalid data format for Keychain storage"
        case .saveFailed(let status):
            return "Failed to save to Keychain (status: \(status))"
        case .loadFailed(let status):
            return "Failed to load from Keychain (status: \(status))"
        case .deleteFailed(let status):
            return "Failed to delete from Keychain (status: \(status))"
        }
    }
}
