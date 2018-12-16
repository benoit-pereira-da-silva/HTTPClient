//
//  MPConnect.swift
//  mp
//
//  Created by Benoit Pereira da silva on 16/12/2018.
//

import Foundation
import Globals
import Tolerance

struct AuthResponse: Codable {
    var access_token:String
}

public enum MPConnectError: Error {
    case voidData
    case invalidComponents(components:URLComponents)
    case invalidURL(url:URL)
    case httpContextIsInvalid
    case invalidHTTPStatus(code:Int, message:String)
    case authenticationDidFail
    case tokenRefreshDidFail
    case securityFailure
}


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

public struct CallDescriptor{
    var baseURL:URL
    var method:HTTPMethod
    var argumentEncoding:ArgumentsEncoding
}

public protocol StringRecipient{
    func didReceiveStringResponse(string:String)
}


public extension Notification {

    public struct MPConnect {
        static let authenticationIsRequired:Notification.Name = Notification.Name(rawValue: "tv.MP.authenticationIsRequired")
    }
}


import Foundation

public struct Credentials:Codable  {
    var email:String
    var password:String
}






public class HTTPClient{

    static let shared: HTTPClient = HTTPClient()

    public var accessToken: String = ""

    public var lastAuthAttempt:Date?

    public var lastRefreshAttempt:Date?

    /// Authenticate to MP's Connect MAT system
    ///
    /// - Parameters:
    ///   - email: the email
    ///   - password: the password
    ///   - didSucceed: the success closure
    ///   - didFail: the failure closure
    public func authenticate(email:String, password: String, authDidSucceed: @escaping (_ message: String) -> (),  authDidFail: @escaping (_ error: Error ,_ message: String) -> ()) {
        do{
            let login: CallDescriptor = ServicesContext.login
            let request: URLRequest = try self.requestFrom(url: login.baseURL, arguments: ["email":email, "password": password], argumentsEncoding: login.argumentEncoding ,method:login.method)
            self.lastAuthAttempt = Date()
            self.call(request: request, resultType: AuthResponse.self, didSucceed: { (r) in
                self.accessToken = r.access_token
                authDidSucceed(NSLocalizedString("Successful authentication", comment: "Successful authentication"))
            }, didFail: authDidFail)
        }catch{
            authDidFail(error, "")
        }
    }


    /// Authenticate to MP's Connect MAT system
    ///
    /// - Parameters:
    ///   - email: the email
    ///   - password: the password
    ///   - didSucceed: the success closure
    ///   - didFail: the failure closure
    public func refresh(refreshDidSucceed: @escaping (_ message: String) -> (),  refreshDidFail: @escaping (_ error: Error ,_ message: String) -> ()) {
        do{
            if self.accessToken != ""{
                // The token can't be refreshed
                refreshDidFail(MPConnectError.tokenRefreshDidFail, "")
            }else{
                let refreshToken: CallDescriptor = ServicesContext.refreshToken
                let request: URLRequest = try self.requestFrom(url: refreshToken.baseURL, arguments: nil, argumentsEncoding: refreshToken.argumentEncoding,method:refreshToken.method)
                self.lastRefreshAttempt = Date()
                self.call(request: request, resultType: AuthResponse.self, didSucceed: { (r) in
                    self.accessToken = r.access_token
                    refreshDidSucceed(NSLocalizedString("Successful authentication", comment: "Successful authentication"))
                }, didFail: refreshDidFail)
            }
        }catch{
            refreshDidFail(error, "")
        }
    }


    /// Proceed to logOut
    ///
    /// - Parameters:
    ///   - didSucceed: the success closure
    ///   - didFail: the failure closure
    public func logout(didSucceed: @escaping (_ message: String) -> (), didFail: @escaping (_ error: Error ,_ message: String) -> ()){
        do{
            let logout:CallDescriptor = ServicesContext.logout
            var request: URLRequest = try HTTPClient.shared.requestFrom(url: logout.baseURL, arguments: nil, argumentsEncoding: logout.argumentEncoding,method:logout.method)
            request.setValue("Bearer \(self.accessToken)", forHTTPHeaderField: "Authorization")
            self.call(request: request, resultType: String.self, didSucceed: { (r) in
                self.accessToken = ""
                self.lastAuthAttempt = nil
                self.lastRefreshAttempt = nil
                didSucceed(NSLocalizedString("Successful deconnection", comment: "Successful deconnection"))
            }, didFail: didFail)
        }catch{
            didFail(error, "")
        }
    }



    /// Returns the request for a given route with the Token
    ///
    /// - Parameters:
    ///   - route: e.g '/user/me'
    ///   - arguments: a dictionary to be passed
    ///   - arguemtsEncoding; queryString or body
    ///   - method: the HTTP method
    /// - Returns: the request with the authorization token
    /// - Throws:  on URL & request issue
    public func authorizedRequest(route:String, arguments: Dictionary<String,String>?, argumentsEncoding: ArgumentsEncoding = .queryString, method: HTTPMethod = HTTPMethod.GET) throws -> URLRequest{
        let route:URL = ServicesContext.apiServerBaseURL.appendingPathComponent(route)
        var request: URLRequest = try self.requestFrom(url: route, arguments: arguments, argumentsEncoding: argumentsEncoding, method: method)
        request.setValue("Bearer \(self.accessToken)", forHTTPHeaderField: "Authorization")
        return request
    }

    /// Returns an url request from an URL
    ///
    /// - Parameters:
    ///   - url: the url
    ///   - arguments: the arguments as a dictionary
    /// - Returns: the Request
    public func requestFrom(url:URL, arguments: Dictionary<String,String>?,argumentsEncoding: ArgumentsEncoding = .queryString, method: HTTPMethod = HTTPMethod.GET) throws-> URLRequest{

        switch argumentsEncoding {
        case .queryString:

            guard var components : URLComponents = URLComponents(url: url , resolvingAgainstBaseURL: false) else{
                throw MPConnectError.invalidURL(url: url)
            }
            if let queryItems:Dictionary<String,String> = arguments{
                components.queryItems = [URLQueryItem]()
                for (k,v) in queryItems{
                    components.queryItems?.append(URLQueryItem(name: k, value: v))
                }
            }
            guard let url:URL = components.url else {
                throw MPConnectError.invalidComponents(components: components)
            }
            var request: URLRequest =  URLRequest(url: url)
            request.httpMethod = method.rawValue
            return request
        case .httpBody(let encoding):
            var request: URLRequest =  URLRequest(url: url)
            if let arguments:Dictionary<String,String> = arguments{
                switch encoding{
                case .form:
                    let pairs: [String] = arguments.map { (entry) -> String in
                        let key:String = entry.key.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) ?? ""
                        let value:String = entry.value.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) ?? ""
                        return "\(key)=\(value)"
                    }
                    request.httpBody = pairs.joined(separator: "&").data(using: .utf8)
                    request.setValue("application/x-www-form-urlencoded;charset=utf-8", forHTTPHeaderField: "Content-Type")
                case .json:
                    let json:Data = try JSONEncoder().encode(arguments)
                    request.httpBody = json
                    request.setValue("application/json;charset=utf-8", forHTTPHeaderField: "Content-Type")
                }
            }
            request.httpMethod = method.rawValue
            return request
        }
    }



    /// Invoke generic request facility
    /// You can use resultType: String.self
    ///
    /// - Parameters:
    ///   - request: the request
    ///   - resultType: the generic result type
    ///   - didSucceed: the success closure
    ///   - didFail: the failure closure
    public func call<T:Codable>(request:URLRequest, resultType: T.Type, didSucceed: @escaping (T) -> (), didFail: @escaping (_ error: Error ,_ message: String) -> ()){
        //log("\(request.httpMethod?.uppercased() ?? "" ) \(request.url!) \(String(data: request.httpBody!, encoding: .utf8))")
        let task = URLSession.shared.dataTask(with: request){ (data, response, error) in
            syncOnMain {
                guard let httpURLResponse = response as? HTTPURLResponse else{
                    didFail(MPConnectError.httpContextIsInvalid, NSLocalizedString("The response is not a HTTP response.", comment: "The response is not a HTTP response."))
                    return
                }
                if [401,403].contains(httpURLResponse.statusCode) {
                    if request.url != ServicesContext.login.baseURL && request.url != ServicesContext.refreshToken.baseURL{
                        self.refresh(refreshDidSucceed: { (_) in
                            self.call(request: request, resultType: resultType , didSucceed: didSucceed, didFail: didFail)
                        }, refreshDidFail: { (_, _) in
                            if ServicesContext.REDUCED_SECURITY_MODE{
                                // In critical context we should never store the credentials
                                if let credentials : Credentials = Storage.shared.credentials{
                                    self.authenticate(email: credentials.email, password: credentials.password, authDidSucceed: { (_) in
                                        self.call(request: request, resultType: resultType, didSucceed: didSucceed, didFail: didFail)
                                    }, authDidFail: { (_, _) in
                                        didFail(MPConnectError.authenticationDidFail, NSLocalizedString("Authentication did fail", comment: "Authentication did fail"))
                                    })
                                }else{
                                    didFail(MPConnectError.authenticationDidFail, NSLocalizedString("Credentials are not available", comment: "Credentials are not available"))
                                    // You can observe this notification and prompt to auth
                                    NotificationCenter.default.post(name: Notification.MPConnect.authenticationIsRequired, object: nil)
                                }
                            }else{
                                didFail(MPConnectError.tokenRefreshDidFail,NSLocalizedString("Token refresh did fail", comment: "Token refresh did fail"))
                                // You can observe this notification and prompt to auth
                                NotificationCenter.default.post(name: Notification.MPConnect.authenticationIsRequired, object: nil)
                            }
                        })
                    }else{
                        // It is a refresh token or a login call
                        // There is nothing to do
                        didFail(MPConnectError.securityFailure,"")
                    }
                }else{
                    guard 200...299 ~= httpURLResponse.statusCode else{
                        // Todo give a relevent message
                        didFail(MPConnectError.invalidHTTPStatus(code: httpURLResponse.statusCode, message: ""), NSLocalizedString("Invalid", comment: "Invalid."))
                        return
                    }
                    if let data = data{
                        do{
                            if resultType == String.self{
                                let string = String(data: data, encoding: .utf8)
                                didSucceed(string as! T)
                            }else{
                                let o:T = try JSONCoder.decode(resultType, from: data)
                                didSucceed(o)
                            }
                        }catch{
                            didFail(error, NSLocalizedString("Deserialization did fail", comment: "Deserialization did fail"))
                        }
                    }else{
                        didFail(MPConnectError.voidData, NSLocalizedString("Void data", comment: "Void data"))
                    }
                }


            }
        }
        task.resume()
    }


    /// Invoke generic request facility
    /// Returns generic Array
    ///
    /// - Parameters:
    ///   - request: the request
    ///   - resultType: the generic result Array<T> type
    ///   - didSucceed: the success closure
    ///   - didFail: the failure closure
    public func call<T:Codable>(request:URLRequest,resultType: [T].Type, didSucceed: @escaping ([T]) -> (), didFail: @escaping (_ error: Error ,_ message: String) -> ()){
        //log(request.url)
        let task = URLSession.shared.dataTask(with: request){ (data, response, error) in
            syncOnMain {
                guard let httpURLResponse = response as? HTTPURLResponse else{
                    didFail(MPConnectError.httpContextIsInvalid, NSLocalizedString("The response is not a HTTP response.", comment: "The response is not a HTTP response."))
                    return
                }
                if [401,403].contains(httpURLResponse.statusCode) {
                    if request.url != ServicesContext.login.baseURL && request.url != ServicesContext.refreshToken.baseURL{
                        self.refresh(refreshDidSucceed: { (_) in
                            self.call(request: request, resultType: resultType , didSucceed: didSucceed, didFail: didFail)
                        }, refreshDidFail: { (_, _) in
                            if ServicesContext.REDUCED_SECURITY_MODE{
                                // In critical context we should never store the credentials
                                if let credentials : Credentials = Storage.shared.credentials{
                                    self.authenticate(email: credentials.email, password: credentials.password, authDidSucceed: { (_) in
                                        self.call(request: request, resultType: resultType, didSucceed: didSucceed, didFail: didFail)
                                    }, authDidFail: { (_, _) in
                                        didFail(MPConnectError.authenticationDidFail, NSLocalizedString("Authentication did fail", comment: "Authentication did fail"))
                                    })
                                }else{
                                    didFail(MPConnectError.authenticationDidFail, NSLocalizedString("Credentials are not available", comment: "Credentials are not available"))
                                    // You can observe this notification and prompt to auth
                                    NotificationCenter.default.post(name: Notification.MPConnect.authenticationIsRequired, object: nil)
                                }
                            }else{
                                didFail(MPConnectError.tokenRefreshDidFail,NSLocalizedString("Token refresh did fail", comment: "Token refresh did fail"))
                                // You can observe this notification and prompt to auth
                                NotificationCenter.default.post(name: Notification.MPConnect.authenticationIsRequired, object: nil)
                            }
                        })
                    }else{
                        // It is a refresh token or a login call
                        // There is nothing to do
                        didFail(MPConnectError.securityFailure,"")
                    }
                }else{

                    guard 200...299 ~= httpURLResponse.statusCode else{
                        // Todo give a relevent message
                        didFail(MPConnectError.invalidHTTPStatus(code: httpURLResponse.statusCode, message: ""), NSLocalizedString("Invalid", comment: "Invalid."))
                        return
                    }
                    if let data = data{
                        do{
                            let o:[T] = try JSONCoder.decode([T].self, from: data)
                            didSucceed(o)
                        }catch{
                            didFail(error, NSLocalizedString("Deserialization did fail", comment: "Deserialization did fail"))
                        }
                    }else{
                        didFail(MPConnectError.voidData, NSLocalizedString("Void data", comment: "Void data"))
                    }
                }
            }
        }
        task.resume()
    }


    // MARK: - String Recipient

    func displayStringResultOf<T:Codable >(request:URLRequest,resultType: T.Type, recipient:StringRecipient){
        doCatchLog ({
            HTTPClient.shared.call(request: request, resultType:resultType, didSucceed: { (result) in
                do{
                    if resultType == String.self{
                        recipient.didReceiveStringResponse(string:result as! String)
                    }else{
                        JSONCoder.encoder = JSON.prettyEncoder
                        let data: Data = try JSONCoder.encode(result)
                        if let jsonString:String = String(data: data, encoding: String.Encoding.utf8){
                            recipient.didReceiveStringResponse(string: jsonString)
                        }else{
                            recipient.didReceiveStringResponse(string: NSLocalizedString("Void response", comment: "Void response"))
                        }
                    }
                }catch{
                    recipient.didReceiveStringResponse(string: "\(error)")
                }
            }, didFail: { (error, message) in
                recipient.didReceiveStringResponse(string: "\(error) \(message) ")
            })
        })
    }

}
