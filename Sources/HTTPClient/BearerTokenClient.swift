//
//  BearerTokenClient.swift
//  HTTPClient
//
//  Created by Benoit Pereira da silva on 02/08/2019.
//

import Foundation

// Overrides a bunch of functions to inject the token in the Authorization Header.
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


    // Just inject the token in the "Authorization Header"
    override open func requestWithObjectInBody<T:Codable & Tolerant>(url: URL,
                                                      object: T,
                                                      method: HTTPMethod = HTTPMethod.GET) throws-> URLRequest{
        var request: URLRequest =  try super.requestWithObjectInBody(url: url,
                                                                          object: object,
                                                                          method: method)
        request.setValue("Bearer \(self.accessToken)", forHTTPHeaderField: "Authorization")
        return request
    }
}
