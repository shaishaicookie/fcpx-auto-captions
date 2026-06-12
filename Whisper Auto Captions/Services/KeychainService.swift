//
//  KeychainService.swift
//  Whisper Auto Captions
//
//  Secure storage for API keys using macOS Keychain
//

import Foundation
import Security

/// Service for securely storing and retrieving sensitive data using macOS Keychain
enum KeychainService {
    // MARK: - Constants
    private static let serviceName = "com.whisper-auto-captions"

    enum KeychainKey: String {
        case geminiApiKey = "gemini_api_key"
    }

    // MARK: - Public Methods

    /// Save a value to the Keychain
    /// - Parameters:
    ///   - value: The string value to store
    ///   - key: The key to associate with the value
    /// - Returns: True if successful, false otherwise
    @discardableResult
    static func save(_ value: String, for key: KeychainKey) -> Bool {
        guard let data = value.data(using: .utf8) else {
            return false
        }

        // First try to delete any existing item
        delete(key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key.rawValue,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    /// Retrieve a value from the Keychain
    /// - Parameter key: The key to look up
    /// - Returns: The stored string value, or nil if not found
    static func retrieve(_ key: KeychainKey) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }

        return string
    }

    /// Delete a value from the Keychain
    /// - Parameter key: The key to delete
    /// - Returns: True if successful or item didn't exist, false on error
    @discardableResult
    static func delete(_ key: KeychainKey) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key.rawValue
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    /// Check if a key exists in the Keychain
    /// - Parameter key: The key to check
    /// - Returns: True if the key exists
    static func exists(_ key: KeychainKey) -> Bool {
        return retrieve(key) != nil
    }
}
