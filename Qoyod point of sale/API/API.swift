//
//  API.swift
//
//  Created by Sharjeel Ahmad on 19/06/2018.
//  Copyright © 2018 Sharjeel Ahmad. All rights reserved.
//

import UIKit

typealias DataHandler = (Data?, HTTPURLResponse?, Error?) -> Void
typealias JSONHandler = (Any?, HTTPURLResponse?, Error?) -> Void
typealias ResponseHandler = (Data?, HTTPURLResponse?, Error?) -> Void

public enum HTTPMethod: String {
    case options = "OPTIONS"
    case get     = "GET"
    case head    = "HEAD"
    case post    = "POST"
    case put     = "PUT"
    case patch   = "PATCH"
    case delete  = "DELETE"
    case trace   = "TRACE"
    case connect = "CONNECT"
}

public enum MimeType: String {
    case png = "image/jpeg"
}

public enum RequestContentType: String {
    case plainText = "text/plain"
    case json = "application/json"
    case formData = "multipart/form-data"
}

public enum APIError: Error {
    case noData
    case noURL
    case invalid
    case generic(Int)
}

extension APIError: LocalizedError {
    public var localizedDescription: String {
        switch self {
        case .noData:
            return languageBundle!.localizedString(forKey: "No data", value: "", table: nil)
        case .noURL:
            return languageBundle!.localizedString(forKey: "The provided URL is incorrect", value: "", table: nil)
        case .invalid:
            return languageBundle!.localizedString(forKey: "The response is invalid", value: "", table: nil)
        case .generic(let code):
            return languageBundle!.localizedString(forKey: "An error occurred. Error code", value: "", table: nil) + " \(NumberFormatter.localizedString(from: code as NSNumber, number: .none))"
        }
    }
    
    public var errorDescription: String? {
        return localizedDescription
    }
}

class API: NSObject {
    static var environment: Environment?
    private static let contentTypeKey = "Content-Type"
    
    static func post(_ path: String, baseUrl:String? = nil ,params: [String: Any]? = nil, data: Data? = nil, mimeType: MimeType = .png, contentType: RequestContentType = .json, cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy) -> Request {
        return self.request(baseUrl ,path: path, params: params, data: data, mimeType: mimeType, method: .post, contentType: contentType, cachePolicy: cachePolicy)
    }
    static func get(_ path: String, baseUrl:String? = nil ,params: [String: Any]? = nil, contentType: RequestContentType = .plainText, cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy) -> Request {
        return self.request(baseUrl ,path: path, params: params, method: .get, contentType: contentType, cachePolicy: cachePolicy)
    }
    static func put(_ path: String, baseUrl:String? = nil,  params: [String: Any]? = nil, contentType: RequestContentType = .plainText, cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy) -> Request {
        return self.request(baseUrl ,path: path, params: params, method: .put, contentType: contentType, cachePolicy: cachePolicy)
    }
    
    static func request(_ baseUrl:String?, path: String, params: [String: Any]? = nil, data: Data? = nil, mimeType: MimeType = .png, headers: [String: String]? = nil, method: HTTPMethod = .get, contentType: RequestContentType = .plainText, cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy) -> Request {
        guard let environment = environment else {
            fatalError("Environment must be defined")
        }
        var urlString = environment.apiPath + path
        if let baseUrl = baseUrl {
            urlString = baseUrl + path
        }
        
        var paramsToUse = [String: Any]()
        let envParams = environment.params
        let environmentParamsAsJson = environment.contentType == .json
        if environmentParamsAsJson {
            paramsToUse += envParams
        }
        if let params = params {
            
            paramsToUse += params
        }
        
        var headersToUse = [String: String]()
        headersToUse += environment.headers
        if let headers = headers {
            headersToUse += headers
        }
        //loggingPrint("Request params \(paramsToUse)")
        var body: Data?
        switch contentType {
        case .json:
            // create json body
            print(paramsToUse)
            body = try? JSONSerialization.data(withJSONObject: paramsToUse, options: [])
            let envParams = environment.params
            if !environmentParamsAsJson {
                var paramsString = ""
                for (key, value) in envParams {
                    guard let val = "\(value)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
                        continue
                    }
                    guard let keyEnc = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
                        continue
                    }
                    if paramsString.count > 0 {
                        paramsString.append("&")
                    } else {
                        paramsString.append("?")
                    }
                    paramsString.append(keyEnc)
                    paramsString.append("=")
                    // append the value
                    paramsString.append(val)
                }
                // append this into params
                urlString.append(paramsString)
//                print(urlString)
            }
        case .plainText:
            if method == .post
            {
                var postData = Data()
                // add the contents of the form data
                for (key, value) in paramsToUse {
                    var paramString = ""
                    
                    if postData.count > 0 {
                        paramString += "&"
                    }
                    
                    paramString += "\(key)=\(value)"
                    postData += paramString.data(using: String.Encoding.utf8)!
                }
                
                body = postData
                
            }else {
                var paramsString = ""
                for (key, value) in paramsToUse {
                    guard let val = "\(value)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
                        continue
                    }
                    guard let keyEnc = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
                        continue
                    }
                    if paramsString.count > 0 {
                        paramsString.append("&")
                    } else {
                        paramsString.append("?")
                    }
                    paramsString.append(keyEnc)
                    paramsString.append("=")
                    // append the value
                    paramsString.append(val)
                }
                // append this into params
                urlString.append(paramsString)
                print(urlString)
            }
        case .formData: //TODO: Change to support multiple images.
            var formParams:[String:Any] = [:]
            
            if let params = params {
                for (key,value) in params {
                    if let value = value as? String {
                        formParams[key] = value
                    }else if let value = value as? [UIImage] {
                        for (i , image) in value.enumerated() {
                            if let imageData = UIImageJPEGRepresentation(image, 0.7) {
                                formParams["imagesData[\(i)]"] = imageData
                            }
                        }
                    }
                }
            }
            
            if let data = data {
                formParams["image"] = data
            }
            
            let boundary = "----WebKitFormBoundary7MA4YWxkTrZu0gW"
            
            headersToUse["Content-Type"] = "\(contentType.rawValue); boundary=\(boundary)"
            
            body = createMultipartBody(parameters: formParams, boundary: boundary, mimeType: mimeType.rawValue)
            
        }
        
        guard let url = URL(string: urlString) else {
            fatalError("Invalid url")
        }
        
        //loggingPrint("Request url \(url)")

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.cachePolicy = cachePolicy
        if contentType != .formData {
            request.setValue(contentType.rawValue, forHTTPHeaderField: contentTypeKey)
        }
        for (key, value) in headersToUse {
            request.setValue(value, forHTTPHeaderField: key)
        }
        if let body = body {
            // add the body to request
            request.httpBody = body
            request.timeoutInterval = 10.0
        }
         
        return Request(request: request)
    }
    
    private static func createMultipartBody(parameters: [String: Any],
                                            boundary: String,
                                            mimeType: String) -> Data {
        let body = NSMutableData()
        
        let boundaryPrefix = "--\(boundary)\r\n"
        
        for (key, value) in parameters {
            if let value = value as? String{
                body.appendString(boundaryPrefix)
                body.appendString("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
                body.appendString("\(value)\r\n")
            }else if let value = value as? Data {
                body.appendString(boundaryPrefix)
                body.appendString("Content-Disposition: form-data; name=\"\(key)\"; filename=\"image.png\"\r\n")
                body.appendString("Content-Type: \(mimeType)\r\n\r\n")
                body.append(value)
                body.appendString("\r\n")
            }
            
            body.appendString("--".appending(boundary.appending("--")))
        }
        
        return body as Data
    }
    
    internal static func handleResponse(data: Data?, response: URLResponse?, error: Error?) -> (Data?, Error?) {
        if let error = error {
            return (nil, error)
        }
        
        guard let data = data else {
            return (nil, APIError.noData)
        }
        
        guard let response = response as? HTTPURLResponse else {
            return (data, error ?? APIError.invalid)
        }
        
        if 200...299 ~= response.statusCode {
            // success
        } else {
            // falure
            return (data, error ?? APIError.generic(response.statusCode))
        }
        
        return (data, nil)
    }
    
    internal static func handleJSONResponse(data: Data?, response: URLResponse?, error: Error?) -> (Any?, Error?) {
        //loggingPrint("error \(String(describing: error))")
        if let error = error {
            return (nil, error)
        }
        
        guard let data = data else {
            return (nil, APIError.noData)
        }
        //loggingPrint("Data: \(String(describing: String(data: data, encoding: .utf8))))")
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            //loggingPrint("json \(json)")
            guard let response = response as? HTTPURLResponse else {
                return (json, error ?? APIError.invalid)
            }
            
            if 200...299 ~= response.statusCode {
                // success
            } else {
                // falure
                return (json, error ?? APIError.generic(response.statusCode))
            }
            
            return (json, nil)
        } catch {
            return (nil, error)
        }
    }
}

extension NSMutableData {
    func appendString(_ string: String) {
        let data = string.data(using: String.Encoding.utf8, allowLossyConversion: false)
        append(data!)
    }
}
