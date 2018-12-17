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


enum KeychainError: Error {
    case noPassword
    case unexpectedPasswordData
    case unhandledError(status: OSStatus)
}

open class Storage{

    var credentials: Credentials?

    static let shared: Storage = Storage()

    init() {}


    public func save(for client: HTTPClient) throws {
        #if !os(Linux)
        guard let credentials: Credentials = self.credentials else{
            return
        }
        let query: [String: Any] = [ kSecClass as String: kSecClassInternetPassword,
                                     kSecAttrAccount as String: credentials.account,
                                     kSecAttrServer as String: client.context.identityServerBaseURL.absoluteString,
                                     kSecValueData as String:  credentials.password.data(using: String.Encoding.utf8)!]
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw KeychainError.unhandledError(status: status) }
        #endif
    }

    public func load() throws{
        #if !os(Linux)
        //@todo sve the credentials
        #endif
    }
}
