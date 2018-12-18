//
//  HTTPCallDescriptor.swift
//  HTTPClient
//
//  Created by Benoit Pereira da silva on 16/12/2018.
//

import Foundation

public enum HTTPMethod: String, Codable{
    case GET
    case POST
    case DELETE
    case PATCH
    case PUT
}

public enum ArgumentsEncoding:Codable{

    case queryString
    case httpBody(type:HTTPBodyEncoding)

    // MARK: - Codable

    enum CodingKeys: String, CodingKey{
        case encodingType
        case encodingArgument
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let encodingTypeString: String = try values.decode(String.self, forKey: .encodingType)
        if encodingTypeString == "httpBody",
            let bodyEncoding: HTTPBodyEncoding = HTTPBodyEncoding(rawValue: encodingTypeString){
            self = .httpBody(type: bodyEncoding)
        }else {
            self = .queryString
        }
    }

    public  func encode(to encoder: Encoder) throws{
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .queryString:
            try container.encode("queryString", forKey: .encodingType)
            try container.encode("", forKey: .encodingArgument)
        case .httpBody(let bodyEncoding):
            try container.encode("httpBody", forKey: .encodingType)
            try container.encode(bodyEncoding.rawValue, forKey: .encodingArgument)
        }
    }
}

public enum HTTPBodyEncoding:String, Codable{
    case form
    case json
}

public struct RequestDescriptor: Codable{

    public var baseURL: URL
    public var method: HTTPMethod
    public var argumentsEncoding: ArgumentsEncoding


    public init (baseURL: URL, method: HTTPMethod, argumentEncoding: ArgumentsEncoding){
        self.baseURL = baseURL
        self.method = method
        self.argumentsEncoding = argumentEncoding
    }
}

