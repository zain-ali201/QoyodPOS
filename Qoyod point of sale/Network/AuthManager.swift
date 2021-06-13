//
//  AuthManager.swift
//  Qoyod
//
//  Created by Apple on 16/04/2018.
//  Copyright © 2018 Inova Care. All rights reserved.
//

import UIKit

typealias AuthHandler = (Bool, Error?) -> ()
typealias statusHandler = (String, Error?) -> ()

class AuthManager {
    static let shared = AuthManager()
    
    func setPinCode(pinCode:String ,completionHandler:@escaping AuthHandler) {
        var params:[String:Any] = [:]
        params["user"] = ["identification_number" : pinCode]
        API.post(NetworkConfig.Endpoint.updatePin, params:params , contentType: .json).json { (json, response, error) in
            if let error = error {
                completionHandler(false, error)
            }else {
                if let json = json as? [String:Any] {
                    if let message = json.string(for: "message") {
                        if message == "Successfully updated." {
                            let pinCode = json.int(for: "four_digit_number")
                            
                            UserDefaults.standard.set(pinCode, forKey: UserDefaults.Key.pinCode)
                            UserDefaults.standard.synchronize()
                            
                            completionHandler(true,nil)
                        }
                    }
                }else {
                    completionHandler(false, NetworkError.unknown)
                }
            }
        }
    }
    
    func checkUserStatus(completionHandler:@escaping statusHandler)
    {
        var params:[String:String] = [:]
        params["email"] = UserDefaults.standard.string(forKey: UserDefaults.Key.username)
        params["tenant"] = UserDefaults.standard.string(forKey: UserDefaults.Key.orgIdentifier)
        params["identifier"] = UserDefaults.standard.string(forKey: UserDefaults.Key.identifier)
        params["pin_code"] = UserDefaults.standard.string(forKey: UserDefaults.Key.pinCode)
        params["auth_token"] = UserDefaults.standard.string(forKey: UserDefaults.Key.token)
        
        let request = API.get(NetworkConfig.Endpoint.userStatus, params:params)
        request.data { (data, response, error) in
            if let _ = error
            {
                completionHandler("", error)
            }
            else
            {
                if let data = data {
                    do {
                        let dict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]

                        if dict != nil
                        {
                            completionHandler((dict!["status"] as! NSString) as String, error)
                        }
                    } catch {
                        completionHandler("", error)
                    }
                }
            }
        }
    }
    
    func login(withUsername username: String, password: String , completionHandler: @escaping AuthHandler)
    {
        var params:[String:Any] = [:]
        params["user"] = ["email" : username , "password" : password ]
        API.post(NetworkConfig.Endpoint.login, params:params , contentType: .json).json { (json, resoonse, error) in
            if let error = error {
                if let json = json as? [String: Any], let message = json["message"] as? String {
                    completionHandler(false, NetworkError.message(message))
                } else {
                    completionHandler(false, error)
                }
            }else {
                if let json = json as? [String: Any] {
                    
                    if let message = json.string(for: "message")
                    {
                        if message == "Successfully logged in."
                        {
                            if let user = json["user"] as? [String : Any] , let token = user["authentication_token"] as? String
                            {
                                UserDefaults.standard.set(false, forKey: UserDefaults.Key.isLoggedIn)
                                UserDefaults.standard.set(username, forKey: UserDefaults.Key.username)
                                UserDefaults.standard.set(token, forKey: UserDefaults.Key.token)
                                KeychainService.savePassword(service: Constant.service , account: Constant.account, data: password)
                                // add the token in api
                                API.environment?.params["auth_token"] = token
                                
                                let pinCode = user["identification_number"]
                                
                                if pinCode != nil && !(pinCode is NSNull)
                                {
                                    UserDefaults.standard.set(user["identification_number"], forKey: UserDefaults.Key.pinCode)
                                    UserDefaults.standard.synchronize()
                                }
                                
                                completionHandler(true, nil)
                            }
                            else
                            {
                                completionHandler(false, NetworkError.unknown)
                            }
                        }
                        else
                        {
                            completionHandler(false, NetworkError.message(message))
                        }
                    }
                    else
                    {
                        completionHandler(false, NetworkError.unknown)
                    }
                }
            }
        }
    }
    
    func logout(completionHandler:@escaping AuthHandler) {
        API.get(NetworkConfig.Endpoint.logout).json { (json, response, error) in
            if let error = error {
                if let json = json as? [String: Any], let message = json["message"] as? String {
                    completionHandler(false, NetworkError.message(message))
                } else {
                    completionHandler(false, error)
                }
            }else {
                if let json = json as? [String:Any] {
                    
                    if let _ = json.string(for: "message") {
                        
                        let domain = Bundle.main.bundleIdentifier!
                        UserDefaults.standard.removePersistentDomain(forName: domain)
                        UserDefaults.standard.synchronize()
                        API.environment?.headers["Access token"] = nil
                        
                        completionHandler(true , nil)
                    }else {
                        completionHandler(false, nil)
                    }
                }
            }
        }
    }
}
