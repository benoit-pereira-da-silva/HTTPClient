//
//  ServicesContext.swift
//  HTTPClient
//
//  Created by Benoit Pereira da silva on 16/12/2018.
//

import Foundation

public struct ServicesContext{

    public static let REDUCED_SECURITY_MODE: Bool = true

    public struct Defaults {
        var email:String = ""
        var password:String = ""
    }

    public static var defaults: Defaults = Defaults()

    public static var identityServerBaseURL: URL  = URL(string: "https://your-identity-server.com")!

    public static var apiServerBaseURL: URL {
        return self.identityServerBaseURL
    }

    public static var login:CallDescriptor{
        return CallDescriptor(baseURL:ServicesContext.identityServerBaseURL.appendingPathComponent("/login"), method:.POST, argumentEncoding:.httpBody(type:.form))
    }

    public static var logout:CallDescriptor{
        // There is no arguments currently to encode so we set Query string by default
        return CallDescriptor(baseURL:ServicesContext.identityServerBaseURL.appendingPathComponent("/token"), method:.DELETE, argumentEncoding:.queryString)
    }

    public static var refreshToken:CallDescriptor{
        // There is no arguments currently to encode so we set Query string by default
        return CallDescriptor(baseURL:ServicesContext.identityServerBaseURL.appendingPathComponent("/refresh"), method:.GET, argumentEncoding:.queryString)
    }

}
