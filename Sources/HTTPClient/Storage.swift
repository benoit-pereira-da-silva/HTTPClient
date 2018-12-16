//
//  Storage.swift
//  HTTPClient
//
//  Created by Benoit Pereira da silva on 16/12/2018.
//

import Foundation
import Globals

public class Storage: Codable{

    var credentials:Credentials?

    static let shared: Storage = Storage()

    init() {
        self.credentials = Credentials(email:ServicesContext.defaults.email, password:ServicesContext.defaults.password)
    }


    public func save() throws {
        let jsonData:Data = try JSONEncoder().encode(self)
        UserDefaults.standard.setValue(jsonData, forKey: "storage")
    }

    public func load() throws{
        if let jsonData:Data = UserDefaults.standard.data(forKey: "storage"){
            let storage: Storage = try JSONDecoder().decode(Storage.self, from: jsonData)
            if ServicesContext.REDUCED_SECURITY_MODE{
                self.credentials = storage.credentials
            }
        }
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey{
        case credentials = "credentials"
    }

    required public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        if ServicesContext.REDUCED_SECURITY_MODE{
            self.credentials = try values.decodeIfPresent(Credentials.self, forKey: .credentials)
        }else{
            self.credentials = nil
        }
    }

    public func encode(to encoder: Encoder) throws{
        var container = encoder.container(keyedBy: CodingKeys.self)
        if ServicesContext.REDUCED_SECURITY_MODE{
            try container.encode(self.credentials, forKey: .credentials)
        }else{
            try container.encode(Credentials(email:"",password:""), forKey: .credentials)
        }
    }

}
