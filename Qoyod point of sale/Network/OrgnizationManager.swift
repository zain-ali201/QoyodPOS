//
//  OrganizationManager.swift
//  BenefitNet
//
//  Created by Apple on 23/04/2018.
//  Copyright © 2018 Inova Care. All rights reserved.
//

import UIKit

typealias GetOrgnizationsHander = (Any?, Error?) -> ()
typealias SetOrgnizationHander = (String?, Error?) -> ()

class OrganizationManager {
    static let shared = OrganizationManager()
    
    func setOrganization(identifier:String ,completionHandler:@escaping SetOrgnizationHander) {
        var params:[String:Any] = [:]
        params["tenant"] = ["identifier_name" : identifier]
        API.post(NetworkConfig.Endpoint.setOrganization, params:params , contentType: .json).json { (json, response, error) in
            if let error = error {
                completionHandler(nil, error)
            }else {
                if let json = json as? [String:Any] {
                    if let message = json.string(for: "message") {
                        if message != "Please select the Organization." {
                            if let orgId = json.string(for: "tenant_identfier"),
                                let orgName = json.string(for: "organization_name"),
                                let logo = json.string(for: "logo"),
                                let locationId = json.string(for: "location_id"),
                                let location = json["location"] as? [String:Any],
                                let orgIdentifier = json.string(for: "organization_identifier") {
                                
                                UserDefaults.standard.set(orgId, forKey: UserDefaults.Key.identifier)
                                UserDefaults.standard.set(logo, forKey: UserDefaults.Key.orgLogo)
                                UserDefaults.standard.set(orgName, forKey: UserDefaults.Key.orgName)
                                if  let currency = json["currency"] as? [String:Any],
                                    let curSymbol = currency["currency_symbol"] as? String {
                                    UserDefaults.standard.set(curSymbol, forKey: UserDefaults.Key.orgCurrencySymbol)
                                }
                                UserDefaults.standard.set(orgIdentifier, forKey: UserDefaults.Key.orgIdentifier)
                                UserDefaults.standard.set(locationId, forKey: UserDefaults.Key.orgLocationId)
                                UserDefaults.standard.set(location["account_id"] ?? "", forKey: UserDefaults.Key.orgAccountId)
                                
                                var vatNumber = ""
                                if let vn = json["vat_number"] as? String {
                                    vatNumber = vn
                                }
                                UserDefaults.standard.set(vatNumber, forKey: UserDefaults.Key.orgVatNo)
                                
                                API.environment?.params["identifier"] = orgId
                                
                                UserDefaults.standard.synchronize() //save defaults
                                completionHandler(message, nil)
                            }else {
                               completionHandler(nil, NetworkError.unknown)
                            }
                        }
                    }
                }else {
                    completionHandler(nil, NetworkError.unknown)
                }
            }
        }
            
    }
    
    func getOrganizations(completionHandler: @escaping GetOrgnizationsHander) {
        let request = API.get(NetworkConfig.Endpoint.getOrganizations)
        request.data { (data, response, error) in
            if let error = error {
                completionHandler(nil, error)
            }else {
                if let data = data {
                    do {
                        let json = try JSONSerialization.jsonObject(with: data, options: [])
                        
                        if let json = json as? [String: Any]{
                            if let message = json.string(for: "message") {
                                if message != "Please select the Organization." {
                                    if let orgId = json.string(for: "organization"),
                                        let orgName = json.string(for: "organization_name"),
                                        let logo = json.string(for: "logo"),
                                        let locationId = json.string(for: "location_id"),
                                        let orgIdentifier = json.string(for: "organization_identifier") {
                                     
                                        UserDefaults.standard.set(orgId, forKey: UserDefaults.Key.identifier)
                                        UserDefaults.standard.set(logo, forKey: UserDefaults.Key.orgLogo)
                                        UserDefaults.standard.set(orgName, forKey: UserDefaults.Key.orgName)
                                        UserDefaults.standard.set(orgIdentifier, forKey: UserDefaults.Key.orgIdentifier)
                                        UserDefaults.standard.set(locationId, forKey: UserDefaults.Key.orgLocationId)
                                        
                                        if let location = json["location"] as? [String:Any] {
                                            UserDefaults.standard.set(location["account_id"] ?? "", forKey: UserDefaults.Key.orgAccountId)
                                        }
                                        
                                        var vatNumber = ""
                                        if let vn = json["vat_number"] as? String {
                                            vatNumber = vn
                                        }
                                        UserDefaults.standard.set(vatNumber, forKey: UserDefaults.Key.orgVatNo)
                                        
                                        if  let currency = json["currency"] as? [String:Any],
                                            let curSymbol = currency["currency_symbol"] as? String {
                                            UserDefaults.standard.set(curSymbol, forKey: UserDefaults.Key.orgCurrencySymbol)
                                        }
                                        API.environment?.params["identifier"] = orgId
                                        
                                        UserDefaults.standard.synchronize() //save defaults
                                        completionHandler(message, nil)
                                    }else {
                                        completionHandler(nil, NetworkError.unknown)
                                    }
                                }else {
                                    do {
                                        let decoder = JSONDecoder()
                                        let organizations = try decoder.decode(OrganizationResponse.self, from: data)
                                        completionHandler(organizations.organizations, nil)
                                    } catch {
                                        completionHandler(nil, error)
                                    }
                                }
                            }
                        }else {
                            completionHandler(nil, NetworkError.unknown)
                        }
                        
                    } catch {
                        completionHandler(nil, error)
                    }
                }
            }
        }
    }
}

class OrganizationResponse: Codable {
    var message: String
    var organizations: [Organization]
}

class Organization: Codable {
    var id: Int
    var identifier: String
    var organization_name: String
    var organization_email: String?
    var organization_contact_number: String?
    var status: String
    var payment_status: String
    var payment_mode: String
    var plan_type: String?
    var limit_of_api_call: Int
    var limit_of_invoice: Int
    var subscription_due_date: String
    var sbs_subscription_plan_id: Int
    var created_at: String
    var updated_at: String
    var api_key: String?
}
