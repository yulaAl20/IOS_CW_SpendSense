//
//  Keychainservice.swift
//  SpendSense
//
//  Created by COBSCCOMP242P-066 on 2026-04-16.
//

import Foundation
import Security

final class KeychainService {
    static let shared = KeychainService()
    private let service = "com.spendsense.app"
    private init() {}

    func saveCredentials(uid: String, email: String) {
        saveItem(key: "biometric_uid",   value: uid)
        saveItem(key: "biometric_email", value: email)
    }

    func loadUID()   -> String? { loadItem(key: "biometric_uid") }
    func loadEmail() -> String? { loadItem(key: "biometric_email") }

    func clearCredentials() {
        deleteItem(key: "biometric_uid")
        deleteItem(key: "biometric_email")
    }

    private func saveItem(key: String, value: String) {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String:   data
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    private func loadItem(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String:  true,
            kSecMatchLimit as String:  kSecMatchLimitOne
        ]
        var result: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &result)
        guard let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func deleteItem(key: String) {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}
