//
//  HTTPClient.swift
//  HTTPClient
//
//  Created by Benoit Pereira da silva on 16/12/2018.
//

import Foundation
#if !USE_EMBEDDED_MODULES
import Globals
import Tolerance
#endif


public enum HTTPClientError: Error {
    case voidData
    case invalidComponents(components: URLComponents)
    case invalidURL(url: URL)
    case httpContextIsInvalid
    case invalidHTTPStatus(code: Int, message: String)
    case authenticationDidFail
    case tokenRefreshIsNotSupported
    case tokenRefreshDidFail
    case missingTokenKey(key: String)
    case securityFailure
}


public protocol StringRecipient{
    func didReceiveStringResponse(string:String)
}


public extension Notification {
    public struct Auth {
        static let authenticationIsRequired:Notification.Name = Notification.Name(rawValue: "com.pereira-da-silva.authenticationIsRequired")
    }
}


open class HTTPClient{

    public var context: AuthContext

    public var accessToken: String = ""

    public var lastAuthAttempt:Date?

    public var lastRefreshAttempt:Date?

    required public init (context: AuthContext){
        self.context = context
        doCatchLog({ () -> () in try Storage.load(self) })
    }

    /// Authenticate to Bearer token Providers
    ///
    /// - Parameters:
    ///   - account: the account
    ///   - password: the password
    ///   - didSucceed: the success closure
    ///   - didFail: the failure closure
    open func authenticate(account:String,
                           password: String,
                           authDidSucceed: @escaping (_ message: String) -> (),
                           authDidFail: @escaping (_ error: Error ,_ message: String) -> ()) {
        do{
            let login: RequestDescriptor = self.context.loginDescriptor
            // @todo to be generalized
            let request: URLRequest = try self.requestFrom(url: login.baseURL,
                                                           arguments: [self.context.accountKey:account, self.context.passwordKey: password],
                                                           argumentsEncoding: login.argumentsEncoding ,
                                                           method:login.method)
            self.lastAuthAttempt = Date()
            self.call(request: request, resultType: Dictionary<String,String>.self, didSucceed: { (r) in
                // We use a dynamic approach to be able to change the token extraction logic easily
                if let token:String = r[self.context.retrieveTokenKey]{
                    self.accessToken = token
                    if self.context.useReducedSecurityMode{
                        doCatchLog({try Storage.save(self) })
                    }
                    authDidSucceed(NSLocalizedString("Successful authentication", comment: "Successful authentication"))
                }else{
                    authDidFail(HTTPClientError.missingTokenKey(key: self.context.retrieveTokenKey),"response: \(r)")
                }

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
    open func refresh(refreshDidSucceed: @escaping (_ message: String) -> (),
                      refreshDidFail: @escaping (_ error: Error ,_ message: String) -> ()) {
        do{
            if self.accessToken != ""{
                // The token can't be refreshed
                refreshDidFail(HTTPClientError.tokenRefreshDidFail, "")
            }else{
                if let refreshToken: RequestDescriptor = self.context.refreshTokenDescriptor{
                    let request: URLRequest = try self.requestFrom(url: refreshToken.baseURL,
                                                                   arguments: nil,
                                                                   argumentsEncoding: refreshToken.argumentsEncoding,
                                                                   method:refreshToken.method)
                    self.lastRefreshAttempt = Date()
                    self.call(request: request, resultType: Dictionary<String,String>.self, didSucceed: { (r) in
                        // We use a dynamic approach to be able to change the token extraction logic easily
                        if let token:String = r[self.context.retrieveTokenKey]{
                            self.accessToken = token
                            refreshDidSucceed(NSLocalizedString("Successful token refresh", comment: "Successful token refresh"))
                        }else{
                            refreshDidFail(HTTPClientError.missingTokenKey(key: self.context.retrieveTokenKey),"response: \(r)")
                        }
                    }, didFail: refreshDidFail)
                }else{
                    refreshDidFail(HTTPClientError.tokenRefreshIsNotSupported, "")
                }
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
    open func logout(didSucceed: @escaping (_ message: String) -> (),
                     didFail: @escaping (_ error: Error ,_ message: String) -> ()){
        do{
            let logout:RequestDescriptor =  self.context.logoutDescriptor
            var request: URLRequest = try self.requestFrom(url: logout.baseURL,
                                                           arguments: nil,
                                                           argumentsEncoding: logout.argumentsEncoding
                ,method:logout.method)
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
    open func authorizedRequest(route:String,
                                arguments: Dictionary<String,String>?,
                                argumentsEncoding: ArgumentsEncoding = .queryString,
                                method: HTTPMethod = HTTPMethod.GET) throws -> URLRequest{

        let route:URL = self.context.apiServerBaseURL.appendingPathComponent(route)
        var request: URLRequest = try self.requestFrom(url: route,
                                                       arguments: arguments,
                                                       argumentsEncoding: argumentsEncoding,
                                                       method: method)
        request.setValue("Bearer \(self.accessToken)", forHTTPHeaderField: "Authorization")
        return request
    }

    /// Returns an url request from an URL
    ///
    /// - Parameters:
    ///   - url: the url
    ///   - arguments: the arguments as a dictionary
    /// - Returns: the Request
    open func requestFrom(url:URL,
                          arguments: Dictionary<String,String>?,
                          argumentsEncoding: ArgumentsEncoding = .queryString,
                          method: HTTPMethod = HTTPMethod.GET) throws-> URLRequest{

        switch argumentsEncoding {
        case .queryString:

            guard var components : URLComponents = URLComponents(url: url , resolvingAgainstBaseURL: false) else{
                throw HTTPClientError.invalidURL(url: url)
            }
            if let queryItems:Dictionary<String,String> = arguments{
                components.queryItems = [URLQueryItem]()
                for (k,v) in queryItems{
                    components.queryItems?.append(URLQueryItem(name: k, value: v))
                }
            }
            guard let url:URL = components.url else {
                throw HTTPClientError.invalidComponents(components: components)
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
    ///
    /// - Parameters:
    ///   - request: the request
    ///   - resultType: the generic result type
    ///   - didSucceed: the success closure
    ///   - didFail: the failure closure
    open func call<T:Codable>(request:URLRequest,
                                    resultType: T.Type,
                                    didSucceed: @escaping (T) -> (),
                                    didFail: @escaping (_ error: Error ,_ message: String) -> ()){
        //log("\(request.httpMethod?.uppercased() ?? "" ) \(request.url!) \(String(data: request.httpBody!, encoding: .utf8))")
        let task = URLSession.shared.dataTask(with: request){ (data, response, error) in
            syncOnMain {
                guard let httpURLResponse = response as? HTTPURLResponse else{
                    didFail(HTTPClientError.httpContextIsInvalid, NSLocalizedString("The response is not a HTTP response.", comment: "The response is not a HTTP response."))
                    return
                }
                if [401,403].contains(httpURLResponse.statusCode) {
                    if request.url != self.context.loginDescriptor.baseURL && request.url != self.context.refreshTokenDescriptor?.baseURL{
                        self.refresh(refreshDidSucceed: { (_) in
                            self.call(request: request, resultType: resultType , didSucceed: didSucceed, didFail: didFail)
                        }, refreshDidFail: { (_, _) in
                            if self.context.useReducedSecurityMode{
                                // In critical context we should never store the credentials
                                if self.context.credentials.isNotVoid{
                                    self.authenticate(account: self.context.credentials.account, password: self.context.credentials.password, authDidSucceed: { (_) in
                                        self.call(request: request, resultType: resultType, didSucceed: didSucceed, didFail: didFail)
                                    }, authDidFail: { (_, _) in
                                        didFail(HTTPClientError.authenticationDidFail, NSLocalizedString("Authentication did fail", comment: "Authentication did fail"))
                                    })
                                }else{
                                    didFail(HTTPClientError.authenticationDidFail, NSLocalizedString("Credentials are void", comment: "Credentials are void"))
                                    // You can observe this notification and prompt to auth
                                    NotificationCenter.default.post(name: Notification.Auth.authenticationIsRequired, object: nil)
                                }
                            }else{
                                didFail(HTTPClientError.tokenRefreshDidFail,NSLocalizedString("Token refresh did fail", comment: "Token refresh did fail"))
                                // You can observe this notification and prompt to auth
                                NotificationCenter.default.post(name: Notification.Auth.authenticationIsRequired, object: nil)
                            }
                        })
                    }else{
                        // It is a refresh token or a login call
                        // There is nothing to do
                        didFail(HTTPClientError.securityFailure,"")
                    }
                }else{
                    guard 200...299 ~= httpURLResponse.statusCode else{
                        // Todo give a relevent message
                        didFail(HTTPClientError.invalidHTTPStatus(code: httpURLResponse.statusCode, message: ""), NSLocalizedString("Invalid", comment: "Invalid."))
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
                        didFail(HTTPClientError.voidData, NSLocalizedString("Void data", comment: "Void data"))
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
    open func call<T:Codable>(request:URLRequest,
                              resultType: [T].Type,
                              didSucceed: @escaping ([T]) -> (),
                              didFail: @escaping (_ error: Error ,_ message: String) -> ()){
        //log(request.url)
        let task = URLSession.shared.dataTask(with: request){ (data, response, error) in
            syncOnMain {
                guard let httpURLResponse = response as? HTTPURLResponse else{
                    didFail(HTTPClientError.httpContextIsInvalid, NSLocalizedString("The response is not a HTTP response.", comment: "The response is not a HTTP response."))
                    return
                }
                if [401,403].contains(httpURLResponse.statusCode) {
                    if request.url != self.context.loginDescriptor.baseURL && request.url != self.context.refreshTokenDescriptor?.baseURL{
                        self.refresh(refreshDidSucceed: { (_) in
                            self.call(request: request, resultType: resultType , didSucceed: didSucceed, didFail: didFail)
                        }, refreshDidFail: { (_, _) in
                            if self.context.useReducedSecurityMode{
                                // In critical context we should never store the credentials
                                if self.context.credentials.isNotVoid{
                                    self.authenticate(account:  self.context.credentials.account, password:  self.context.credentials.password, authDidSucceed: { (_) in
                                        self.call(request: request, resultType: resultType, didSucceed: didSucceed, didFail: didFail)
                                    }, authDidFail: { (_, _) in
                                        didFail(HTTPClientError.authenticationDidFail, NSLocalizedString("Authentication did fail", comment: "Authentication did fail"))
                                    })
                                }else{
                                    didFail(HTTPClientError.authenticationDidFail, NSLocalizedString("Credentials are void", comment: "Credentials are void"))
                                    // You can observe this notification and prompt to auth
                                    NotificationCenter.default.post(name: Notification.Auth.authenticationIsRequired, object: nil)
                                }
                            }else{
                                didFail(HTTPClientError.tokenRefreshDidFail,NSLocalizedString("Token refresh did fail", comment: "Token refresh did fail"))
                                // You can observe this notification and prompt to auth
                                NotificationCenter.default.post(name: Notification.Auth.authenticationIsRequired, object: nil)
                            }
                        })
                    }else{
                        // It is a refresh token or a login call
                        // There is nothing to do
                        didFail(HTTPClientError.securityFailure,"")
                    }
                }else{

                    guard 200...299 ~= httpURLResponse.statusCode else{
                        // Todo give a relevent message
                        didFail(HTTPClientError.invalidHTTPStatus(code: httpURLResponse.statusCode, message: ""), NSLocalizedString("Invalid", comment: "Invalid."))
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
                        didFail(HTTPClientError.voidData, NSLocalizedString("Void data", comment: "Void data"))
                    }
                }
            }
        }
        task.resume()
    }

    // MARK: - String Recipient

    open func displayStringResultOf<T:Codable >(request:URLRequest,resultType: T.Type, recipient:StringRecipient){
        doCatchLog ({
            self.call(request: request, resultType:resultType, didSucceed: { (result) in
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
