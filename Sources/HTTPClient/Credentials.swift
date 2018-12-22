//
//  Credentials.swift
//  HTTPClient
//
//  Created by Benoit Pereira da silva on 17/12/2018.
//


import Foundation

public struct Credentials: Codable  {

    public var account: String
    public var password: String

    public init (account: String, password: String ) {
        self.account = account
        self.password = password
    }

    var isNotVoid:Bool {return self.account.count > 0 && self.password.count > 0}

    
    // MARK: - Codable

    enum CodingKeys: String, CodingKey{
        case account
        // Never save the password
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.account = try values.decode(String.self, forKey: Credentials.CodingKeys.account)
        self.password = "" // Do not allow to load or save passwords
    }

    public  func encode(to encoder: Encoder) throws{
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.account, forKey: .account)
        // Do not allow to save passwords
    }
}
