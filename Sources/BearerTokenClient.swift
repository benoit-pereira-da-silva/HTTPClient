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

}
