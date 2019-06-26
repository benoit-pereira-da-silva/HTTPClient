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

    // The associated credentials
    var credentials: Credentials = Credentials(account: "", password: "")

    // Defines the key to submit the account identifier on Authentication
    public var accountKey:String = "account"

    // Defines the key to submit the password on Authentication
    public var passwordKey:String = "password"

    // Defines
    public var groupKey:String = "group"


    // Defines the key used to extract the access token on Authentication
    public var retrieveTokenKey:String = "access_token"

    // If set to true the engine accepts to store the credentials on the client (using Apple's KeyChain)
    public var useReducedSecurityMode: Bool = false

    //URLs

    public var authenticationServerBaseURL: URL

    // The call descriptors
    public var loginDescriptor: RequestDescriptor

    public var logoutDescriptor: RequestDescriptor

    public var refreshTokenDescriptor: RequestDescriptor?

    public init(identityServerBaseURL: URL, descriptors: AuthDescriptors ) {
        self.authenticationServerBaseURL = identityServerBaseURL
        self.loginDescriptor = descriptors.loginDescriptor
        self.logoutDescriptor = descriptors.logoutDescriptor
        self.refreshTokenDescriptor = descriptors.refreshDescriptor
    }

    public static var `default` : AuthContext{

        let defaultIDServerURL : URL = URL(string: "https://your-id-server.com")!
        let login:RequestDescriptor = RequestDescriptor(baseURL:defaultIDServerURL.appendingPathComponent("/login"),
                                                        method:.POST,
                                                        argumentsEncoding:.httpBody(type:.form))

        // There is no arguments currently to encode so we set Query string by default
        let logout:RequestDescriptor = RequestDescriptor(baseURL:defaultIDServerURL.appendingPathComponent("/token"),
                                                         method:.DELETE,
                                                         argumentsEncoding:.queryString)

        // There is no arguments currently to encode so we set Query string by default
        let refresh:RequestDescriptor = RequestDescriptor(baseURL:defaultIDServerURL.appendingPathComponent("/refresh"),
                                                          method:.GET,
                                                          argumentsEncoding:.queryString)

        let descriptors:AuthDescriptors = AuthDescriptors(login: login, logout: logout, refresh: refresh)

        return AuthContext.init(identityServerBaseURL: defaultIDServerURL, descriptors:descriptors )

    }
}
