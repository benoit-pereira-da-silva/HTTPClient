//
//  ServicesContext.shared.swift
//  HTTPClient
//
//  Created by Benoit Pereira da silva on 16/12/2018.
//

import Foundation

public class ServicesContext{

    public var useReducedSecurityMode: Bool = false

    public static let shared: ServicesContext = ServicesContext()

    public lazy var identityServerBaseURL: URL =  URL(string: "https://id.bartlebys.org")!

    public lazy var apiServerBaseURL: URL =  URL(string: "https://id.bartlebys.org")!

    public lazy var login:CallDescriptor = CallDescriptor(baseURL:self.identityServerBaseURL.appendingPathComponent("/login"),
                                                          method:.POST,
                                                          argumentEncoding:.httpBody(type:.form))


    // There is no arguments currently to encode so we set Query string by default
    public lazy var logout:CallDescriptor = CallDescriptor(baseURL:self.identityServerBaseURL.appendingPathComponent("/token"),
                                                           method:.DELETE,
                                                           argumentEncoding:.queryString)

    // There is no arguments currently to encode so we set Query string by default
    public lazy var refreshToken:CallDescriptor = CallDescriptor(baseURL:self.identityServerBaseURL.appendingPathComponent("/refresh"),
                                                                 method:.GET,
                                                                 argumentEncoding:.queryString)


}
