//
//  Keychain.swift
//  PurePKG
//
//  Created by Lrdsnow on 6/9/24.
//

import Foundation
import AuthenticationServices

class Keychain {
    public static func update(_ data: Data, service: String, account: String) {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ] as CFDictionary
        
        let updatedData = [kSecValueData: data] as CFDictionary
        SecItemUpdate(query, updatedData)
    }
    
    public static func save(_ data: Data, service: String, account: String) {
        let query = [
            kSecValueData: data,
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ] as CFDictionary
        
        let saveStatus = SecItemAdd(query, nil)
        
        if saveStatus != errSecSuccess {
            print("Error: \(saveStatus)")
        }
        
        if saveStatus == errSecDuplicateItem {
            update(data, service: service, account: account)
        }
    }
    
    public static func read(service: String, account: String) -> Data? {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecReturnData: true
        ] as CFDictionary
        
        var result: AnyObject?
        SecItemCopyMatching(query, &result)
        return result as? Data
    }
    
    public static func delete(service: String, account: String) {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ] as CFDictionary
        
        SecItemDelete(query)
    }
}
