//
//  AuthContext.swift
//  HTTPClient
//
//  Created by Benoit Pereira da silva on 17/12/2018.
//

import Foundation

public struct AuthDescriptors {

    public var loginDescriptor: HTTPCallDescriptor

    public var logoutDescriptor: HTTPCallDescriptor

    public var refreshDescriptor: HTTPCallDescriptor?

    init(login:HTTPCallDescriptor, logout:HTTPCallDescriptor, refresh: HTTPCallDescriptor) {
        self.loginDescriptor = login
        self.logoutDescriptor = logout
        self.refreshDescriptor = refresh
    }
}

public struct AuthContext{

    // Defines the key to submit the account identifier on Authentication
    public var accountKey:String = "email"

    // Defines the key to submit the password on Authentication
    public var passwordKey:String = "password"

    // Defines the key used to extract the access token on Authentication
    public var retrieveTokenKey:String = "access_token"

    // If set to true the engine accepts to store the credentials on the client.
    public var useReducedSecurityMode: Bool = false

    //URLs

    public var identityServerBaseURL: URL

    public var apiServerBaseURL: URL

    // The call descriptors
    public var loginDescriptor: HTTPCallDescriptor

    public var logoutDescriptor: HTTPCallDescriptor

    public var refreshTokenDescriptor: HTTPCallDescriptor?

    public init(identityServerBaseURL: URL, apiServerBaseURL:URL, descriptors: AuthDescriptors ) {
        self.identityServerBaseURL = identityServerBaseURL
        self.apiServerBaseURL = apiServerBaseURL
        self.loginDescriptor = descriptors.loginDescriptor
        self.logoutDescriptor = descriptors.logoutDescriptor
        self.refreshTokenDescriptor = descriptors.refreshDescriptor
    }

}


public extension Notification {

    public struct Auth {
        static let authenticationIsRequired:Notification.Name = Notification.Name(rawValue: "com.pereira-da-silva.authenticationIsRequired")
    }
}

