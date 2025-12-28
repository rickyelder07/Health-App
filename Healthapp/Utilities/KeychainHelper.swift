//
//  KeychainHelper.swift
//  Health App
//
//  Helper for securely storing sensitive data in Keychain
//

import Foundation
import Combine
import Security

/// Helper class for Keychain operations
class KeychainHelper {
    
    static let shared = KeychainHelper()
    
    private init() {}
    
    /// Save data to Keychain
    /// - Parameters:
    ///   - data: Data to save
    ///   - key: Unique key identifier
    /// - Returns: Success status
    @discardableResult
    func save(_ data: Data, forKey key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]
        
        // Delete any existing item
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    /// Save string to Keychain
    /// - Parameters:
    ///   - string: String to save
    ///   - key: Unique key identifier
    /// - Returns: Success status
    @discardableResult
    func save(_ string: String, forKey key: String) -> Bool {
        guard let data = string.data(using: .utf8) else { return false }
        return save(data, forKey: key)
    }
    
    /// Retrieve data from Keychain
    /// - Parameter key: Unique key identifier
    /// - Returns: Retrieved data, or nil if not found
    func getData(forKey key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else { return nil }
        return result as? Data
    }
    
    /// Retrieve string from Keychain
    /// - Parameter key: Unique key identifier
    /// - Returns: Retrieved string, or nil if not found
    func getString(forKey key: String) -> String? {
        guard let data = getData(forKey: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    /// Delete item from Keychain
    /// - Parameter key: Unique key identifier
    /// - Returns: Success status
    @discardableResult
    func delete(forKey key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess
    }
    
    /// Clear all keychain items for this app
    @discardableResult
    func clearAll() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess
    }
}

/// Keychain keys used in the app
extension KeychainHelper {
    enum Keys {
        static let supabaseAccessToken = "supabase_access_token"
        static let supabaseRefreshToken = "supabase_refresh_token"
        static let stravaAccessToken = "strava_access_token"
        static let stravaRefreshToken = "strava_refresh_token"
    }
}

