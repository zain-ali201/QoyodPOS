//
//  Environment.swift
//
//  Created by Sharjeel Ahmad on 19/06/2018.
//  Copyright © 2018 Sharjeel Ahmad. All rights reserved.
//

import Foundation


/// An environment represents a set of values that all the network calls would include. Such as a base url
struct Environment {
    
    /// The Base URL scheme+host for the environment
    var apiPath: String
    
    /// The set of params that would go with every request
    var params: [String: Any]
    
    /// Determines the content type of the environment params. Use plainText if it is necessary to pass the environment parameters as url query rather than json in a post request *Note: if the content type of a request is `plainText` the environment params will also respect that. 
    var contentType: RequestContentType = .json
    /// The set of header values
    var headers: [String: String]
    
    init(apiPath: String = "", params: [String: Any] = [:], headers: [String: String] = [:]) {
        self.apiPath = apiPath
        self.params = params
        self.headers = headers
    }
}
