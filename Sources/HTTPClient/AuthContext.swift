//
//  AuthContext.swift
//  HTTPClient
//
//  Created by Benoit Pereira da silva on 17/12/2018.
//


import Foundation


public struct AuthDescriptors: Codable{

    public var loginDescriptor: RequestDescriptor

    public var logoutDescriptor: RequestDescriptor

    public var refreshDescriptor: RequestDescriptor?

    public init(login:RequestDescriptor, logout:RequestDescriptor, refresh: RequestDescriptor) {
        self.loginDescriptor = login
        self.logoutDescriptor = logout
        self.refreshDescriptor = refresh
    }
}

public struct AuthContext: Codable{

    // Defines the key to submit the account identifier on Authentication
    public var accountKey:String = "email"

    // Defines the key to submit the password on Authentication
    public var passwordKey:String = "password"

    // Defines the key used to extract the access token on Authentication
    public var retrieveTokenKey:String = "access_token"

    // If set to true the engine accepts to store the credentials on the client (using Apple's KeyChain)
    public var useReducedSecurityMode: Bool = false

    //URLs

    public var authenticationServerBaseURL: URL

    public var apiServerBaseURL: URL

    // The call descriptors
    public var loginDescriptor: RequestDescriptor

    public var logoutDescriptor: RequestDescriptor

    public var refreshTokenDescriptor: RequestDescriptor?

    public init(identityServerBaseURL: URL, apiServerBaseURL:URL, descriptors: AuthDescriptors ) {
        self.authenticationServerBaseURL = identityServerBaseURL
        self.apiServerBaseURL = apiServerBaseURL
        self.loginDescriptor = descriptors.loginDescriptor
        self.logoutDescriptor = descriptors.logoutDescriptor
        self.refreshTokenDescriptor = descriptors.refreshDescriptor
    }
}
