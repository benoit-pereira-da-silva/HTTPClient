//
//  Storage.swift
//  HTTPClient
//
//  Created by Benoit Pereira da silva on 16/12/2018.
//

import Foundation
#if !USE_EMBEDDED_MODULES
import Globals
import HMAC
#endif
import Security


enum KeychainError: Error {
    case unexpectedPasswordData
    case unhandledError(status: OSStatus)
    case noCredentials
}

// The Storage uses:
// 1. UserDefaults.standard to store the default account
// 2. the Keychain to store the password
public struct Storage{


    fileprivate static func _accountKeyFor(_ client:HTTPClient)->String{
        return "\(client.context.credentials.account)_\(client.context.authenticationServerBaseURL.absoluteString)".md5
    }

    /// Saves the default account in the UserDefaults.standard
    /// And the associated password in the KeyChain
    ///
    /// - Parameter client: the concerned HTTPClient that defines the associated Identity server URL
    /// - Throws: KeychainError.noCredentials if there is no credentials.
    /// - Throws: KeychainError.unhandledError(...) on key chain access errors.
    public static func save(_ client: HTTPClient) throws {
        #if !os(Linux)
        let credentials: Credentials = client.context.credentials
        guard credentials.isNotVoid else{ throw KeychainError.noCredentials }
        UserDefaults.standard.set(credentials.account, forKey: self._accountKeyFor(client))

        let query: CFDictionary =  [ kSecClass as String: kSecClassInternetPassword,
                                     kSecAttrAccount as String: credentials.account,
                                     kSecAttrServer as String: client.context.authenticationServerBaseURL.absoluteString,
                                     kSecValueData as String:  credentials.password.data(using: String.Encoding.utf8)!] as CFDictionary
        var status = SecItemAdd(query,  nil)
        if status == errSecDuplicateItem{
            doCatchLog({ try self.delete(client)})
            status = SecItemAdd(query,  nil)
        }
        guard status == errSecSuccess else { throw KeychainError.unhandledError(status: status) }
        #endif
    }


    /// Loads the default account password from the keychain
    /// Take the credentials account or the saved account to try to access to the password
    ///
    /// - Parameter client: the concerned HTTPClient that defines the associated Identity server URL
    /// - Throws: KeychainError.noCredentials if there is neither a credential nor an account in the UserDefaults.
    /// - Throws: KeychainError.unhandledError(...) on key chain access errors.
    public static func load(_ client: HTTPClient) throws  {
        #if !os(Linux)
        var credentials: Credentials = client.context.credentials
        if credentials.account.count == 0 {
             credentials.account =? UserDefaults.standard.string(forKey: self._accountKeyFor(client))
        }
        guard credentials.isNotVoid else{ throw KeychainError.noCredentials }
        let query: CFDictionary = [ kSecClass as String: kSecClassInternetPassword,
                                    kSecAttrServer as String: client.context.authenticationServerBaseURL.absoluteString,
                                    kSecAttrAccount as String: credentials.account,
                                    kSecReturnData as String : true,
                                    kSecMatchLimit as String : kSecMatchLimitOne ] as CFDictionary
        var result: AnyObject?
        let code: OSStatus = withUnsafeMutablePointer(to: &result) {
            SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
        }
        guard let data:Data = result as? Data , let _: String =  String(data: data, encoding: .utf8) else{
            throw KeychainError.unhandledError(status: code)
        }
        #endif
    }


    /// Deletes the stored credentials from UserDefaults and the Keychain
    ///
    /// - Parameter client: the concerned HTTPClient that defines the associated Identity server URL
    /// - Throws: KeychainError.noCredentials if there is neither a credential nor an account in the UserDefaults.
    /// - Throws: KeychainError.unhandledError(...) on key chain deletion errors.
    public static func delete(_ client: HTTPClient) throws{
        #if !os(Linux)
        let credentials: Credentials = client.context.credentials
        guard credentials.isNotVoid else{ throw KeychainError.noCredentials }
        UserDefaults.standard.removeObject(forKey: self._accountKeyFor(client))
        let query: CFDictionary = [ kSecClass as String: kSecClassInternetPassword,
                                    kSecAttrServer as String: client.context.authenticationServerBaseURL.absoluteString,
                                    kSecAttrAccount as String: credentials.account] as CFDictionary

        let status = SecItemDelete(query)
        guard status == errSecSuccess else { throw KeychainError.unhandledError(status: status) }
        #endif
    }
}

