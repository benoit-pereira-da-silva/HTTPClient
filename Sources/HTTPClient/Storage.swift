//
//  Storage.swift
//  HTTPClient
//
//  Created by Benoit Pereira da silva on 16/12/2018.
//

import Foundation
#if !USE_EMBEDDED_MODULES
import Globals
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
public class Storage{

    // The associated credentials
    var credentials: Credentials?

    // The singleton instance
    static let shared: Storage = Storage()

    /// Saves the default account in the UserDefaults.standard
    /// And the associated password in the KeyChain
    ///
    /// - Parameter client: the concerned HTTPClient that defines the associated Identity server URL
    /// - Throws: KeychainError.noCredentials if there is no credentials.
    /// - Throws: KeychainError.unhandledError(...) on key chain access errors.
    public func save(for client: HTTPClient) throws {
        #if !os(Linux)
        guard let credentials: Credentials = self.credentials else{
            throw KeychainError.noCredentials
        }
        UserDefaults.standard.set(credentials.account, forKey: "defaultAccount@" + client.context.authenticationServerBaseURL.absoluteString)

        let query: CFDictionary =  [ kSecClass as String: kSecClassInternetPassword,
                                     kSecAttrAccount as String: credentials.account,
                                     kSecAttrServer as String: client.context.authenticationServerBaseURL.absoluteString,
                                     kSecValueData as String:  credentials.password.data(using: String.Encoding.utf8)!] as CFDictionary
        let status = SecItemAdd(query,  nil)
        guard status == errSecSuccess else { throw KeychainError.unhandledError(status: status) }
        #endif
    }


    /// Loads the default account password from the keychain
    /// Take the credentials account or the saved account to try to access to the password
    ///
    /// - Parameter client: the concerned HTTPClient that defines the associated Identity server URL
    /// - Throws: KeychainError.noCredentials if there is neither a credential nor an account in the UserDefaults.
    /// - Throws: KeychainError.unhandledError(...) on key chain access errors.
    public func load(for client: HTTPClient) throws  {
        #if !os(Linux)
        guard let account : String = self.credentials?.account ?? UserDefaults.standard.string(forKey:"defaultAccount@" + client.context.authenticationServerBaseURL.absoluteString) else{
            throw KeychainError.noCredentials
        }
        let query: CFDictionary = [ kSecClass as String: kSecClassInternetPassword,
                                    kSecAttrServer as String: client.context.authenticationServerBaseURL.absoluteString,
                                    kSecAttrAccount as String: account,
                                    kSecReturnData as String : kCFBooleanTrue,
                                    kSecMatchLimit as String : kSecMatchLimitOne ] as CFDictionary
        var result: AnyObject?
        let code: OSStatus = withUnsafeMutablePointer(to: &result) {
            SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
        }
        guard let data:Data = result as? Data , let password: String =  String(data: data, encoding: .utf8)else{
            throw KeychainError.unhandledError(status: code)
        }
        self.credentials?.password = password
        #endif
    }


    /// Deletes the stored credentials from UserDefaults and the Keychain
    ///
    /// - Parameter client: the concerned HTTPClient that defines the associated Identity server URL
    /// - Throws: KeychainError.noCredentials if there is neither a credential nor an account in the UserDefaults.
    /// - Throws: KeychainError.unhandledError(...) on key chain deletion errors.
    public func delete(for client: HTTPClient) throws{
        #if !os(Linux)
        guard let account : String = self.credentials?.account ?? UserDefaults.standard.string(forKey:"defaultAccount@" + client.context.authenticationServerBaseURL.absoluteString) else{
            throw KeychainError.noCredentials
        }
        UserDefaults.standard.removeObject(forKey: "account@" + client.context.authenticationServerBaseURL.absoluteString)
        let query: CFDictionary = [ kSecClass as String: kSecClassInternetPassword,
                                    kSecAttrServer as String: client.context.authenticationServerBaseURL.absoluteString,
                                    kSecAttrAccount as String: account] as CFDictionary

        let status = SecItemDelete(query)
        guard status == errSecSuccess else { throw KeychainError.unhandledError(status: status) }
        #endif
    }
}

