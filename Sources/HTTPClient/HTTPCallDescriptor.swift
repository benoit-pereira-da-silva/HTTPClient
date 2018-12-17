//
//  HTTPCallDescriptor.swift
//  HTTPClient
//
//  Created by Benoit Pereira da silva on 16/12/2018.
//

import Foundation

public enum HTTPMethod: String{
    case GET
    case POST
    case DELETE
    case PATCH
    case PUT
}

public enum ArgumentsEncoding{
    case queryString
    case httpBody(type:HTTPBodyEncoding)
}

public enum HTTPBodyEncoding{
    case form
    case json
}

public struct HTTPCallDescriptor{
    var baseURL: URL
    var method: HTTPMethod
    var argumentEncoding: ArgumentsEncoding
}

