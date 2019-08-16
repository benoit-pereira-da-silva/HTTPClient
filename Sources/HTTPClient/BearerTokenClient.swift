//
//  BearerTokenClient.swift
//  GridEditor
//
//  Created by Benoit Pereira da silva on 02/08/2019.
//  Copyright © 2019 The Playlist. All rights reserved.
//

import Foundation

open class BearerTokenClient: HTTPClient {

    // Just inject the token in the "Authorization Header"
    override open func requestFrom( url: URL,
                                    arguments: Dictionary<String, String>?,
                                    argumentsEncoding: ArgumentsEncoding = .queryString,
                                    method: HTTPMethod = HTTPMethod.GET) throws -> URLRequest {
        var request: URLRequest =  try super.requestFrom( url: url,
                                                          arguments: arguments,
                                                          argumentsEncoding: argumentsEncoding,
                                                          method: method)
        request.setValue("Bearer \(self.accessToken)", forHTTPHeaderField: "Authorization")
        return request
    }



    /// Returns an url request from an URL and a codable Object
    /// The object is passed in the body as a JSON payload
    ///
    /// - Parameters:
    ///   - url: the url
    ///   - arguments: the arguments as a dictionary
    /// - Returns: the Request
    override open func requestWithCodableObjectFrom<T:Codable & Tolerant>(url: URL,
                                                      object: T,
                                                      method: HTTPMethod = HTTPMethod.GET) throws-> URLRequest{
        var request: URLRequest =  try super.requestWithCodableObjectFrom(url: url,
                                                                          object: object,
                                                                          method: method)
        request.setValue("Bearer \(self.accessToken)", forHTTPHeaderField: "Authorization")
        return request
    }
}
