//
//  Request.swift
//
//  Created by Sharjeel Ahmad on 19/06/2018.
//  Copyright © 2018 Sharjeel Ahmad. All rights reserved.
//

import Foundation


class Request: NSObject {
    let urlRequest: URLRequest
    
    init(request: URLRequest) {
        self.urlRequest = request
        super.init()
    }
    
    /// Execute the request and return json
    ///
    /// - Parameter completionHandler: will be executed with json and/or error
    func json(completionHandler: @escaping JSONHandler) {
        response { (data, response, error) in
            let result = API.handleJSONResponse(data: data, response: response, error: error)
            completionHandler(result.0, response, result.1)
        }
    }
    /// Execute the request and return response data
    ///
    /// - Parameter completionHandler: will be executed with data and error error
    func data(completionHandler: @escaping DataHandler) {
        response { (data, response, error) in
            let result = API.handleResponse(data: data, response: response, error: error)
            completionHandler(result.0, response, result.1)
        }
    }
    /// Execute the request and return URLResponse
    ///
    /// - Parameter completionHandler: will be executed with raw data, response and error
    func response(completionHandler: @escaping ResponseHandler) {
        // run the request
        let task = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            NetworkActivityManager.show()
            DispatchQueue.main.async {
                if let data = data, let str = String(data: data, encoding: .utf8) {
                    //loggingPrint("data \(str) error \(String(describing: error))")
                }
                completionHandler(data, response as? HTTPURLResponse, error)
            }
        }
        NetworkActivityManager.hide()
        task.resume()
    }
}

/// This is the Request protocol you may implement as enum
/// or as a classic class object for each kind of request.
public protocol Requester {
    
    /// Relative path of the endpoint we want to call (ie. `/users/login`)
    var path            : String                { get }
    
}

















