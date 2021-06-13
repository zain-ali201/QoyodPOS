//
//  OrganizationManager.swift
//  BenefitNet
//
//  Created by Sharjeel on 23/05/2018.
//  Copyright © 2018 Inova Care. All rights reserved.
//

import UIKit

typealias GetContactsHander = ([Contact]?, Error?) -> ()
typealias AddContactsHander = (String?, Error?) -> ()

class CustomerManager {
    static let shared = CustomerManager()
    
    func getContacts(getCached:Bool = true, completionHandler: @escaping GetContactsHander) {
        var params:[String:String] = [:]
        params["date"] = "0"
        
        let request = API.get(NetworkConfig.Endpoint.contacts, params:params)
        request.data { (data, response, error) in
            if let _ = error {
                completionHandler(nil, error)
            }else {
                if let data = data {
                    do {
                        let decoder = JSONDecoder()
                        let contacts = try decoder.decode(Contacts.self, from: data)
                        UserDefaults.standard.set(data, forKey: "contact")
                        UserDefaults.standard.synchronize()
                        completionHandler(contacts.contact, nil)
                    } catch {
                        completionHandler(nil, error)
                    }
                }
            }
        }
        
        if getCached {
            if let data = UserDefaults.standard.data(forKey: "contact") {
                do {
                    let decoder = JSONDecoder()
                    let contacts = try decoder.decode(Contacts.self, from: data)
                    completionHandler(contacts.contact, nil)
                } catch {
                    
                }
            }
        }
    }
    
    func postPendingNewCustomers(completionHandler: @escaping PostPendingInvoicesHandler)
    {
        if let params = UserDefaults.standard.dictionary(forKey: "localcontacts")
        {
            let request = API.post(NetworkConfig.Endpoint.contacts, params:params, contentType: .json)
            request.json { (json, response, error) in
                
                if let error = error
                {
                    print(error)
                    completionHandler(error)
                }
                else if let _ = json as? [String:Any]
                {
                    print(json)
                    print("done post pending contacts")
                    UserDefaults.standard.removeObject(forKey: "localcontacts")
                    UserDefaults.standard.synchronize()
                    completionHandler(nil)
                }else{
                    completionHandler(NetworkError.unknown)
                }
            }
        }
        completionHandler(nil)
    }
    
    func addContactToCache(name:String, email:String , phone:String)
    {
        let contactDict:[String:Any] = [
            "id" : 0,
            "contact_name" : name,
            "organization_name": "",
            "contact_type": "",
            "website": "",
            "secondary_contact_number": "",
            "customer" : true,
            "primary_contact_number" : phone,
            "primary_email" : email,
            "status" : "Active",
            "secondary_email": "",
            "vendor": false,
            "tax_number": "",
            "deleted_at": "",
            "billing_city" : "",
            "billing_state" : "",
            "billing_zip" : "",
            "billing_country" : "",
            "created_at" : "",
            "updated_at" : "",
            "billing_address" : [
                "id" : 0,
                "contact_id" : 0,
                "is_defaultd" : false,
                "billing_address" : "",
                "billing_city" : "",
                "billing_state" : "",
                "billing_zip" : "",
                "billing_country" : "",
                "created_at" : "",
                "updated_at" : "",
            ]
        ]
        
        do {
            if let localContacts = UserDefaults.standard.data(forKey: "contact"){
                let data = try JSONSerialization.data(withJSONObject: contactDict, options: [])
                let decoder = JSONDecoder()
                let contactObject = try decoder.decode(Contact.self, from: data)
                let contacts = try decoder.decode(Contacts.self, from: localContacts)
                
                contacts.contact.append(contactObject)
                customersList.append(contactObject)
                let encoder = JSONEncoder()
                let contactsNewData = try encoder.encode(contacts)
                
                UserDefaults.standard.set(contactsNewData, forKey: "contact")
                UserDefaults.standard.synchronize()
            }
        }catch {
            print(error)
        }
    }
    
    func createContact(name:String, email:String, phone:String , completionHandler: @escaping AddContactsHander) {
        
        let contactDict:[String:Any] = [
            "contact_name" : name,
            "customer" : 1,
            "primary_contact_number" : phone,
            "primary_email" : email,
            "status" : "Active",
            "contact_billing_address_attributes" : [
                "billing_address" : "",
                "billing_city" : "",
                "billing_state" : "",
                "billing_zip" : "",
                "billing_country" : ""
            ]
        ]
        
        var params:[String:Any] = [:]
        params["contact"] = [contactDict]
        
        if var localContacts = UserDefaults.standard.dictionary(forKey: "localcontacts")
        {
            if var list = localContacts["contact"] as? [[String:Any]]
            {
                list.append(contactDict)
                localContacts["contact"] = list
            }
            UserDefaults.standard.set(localContacts, forKey: "localcontacts")
        }
        else
        {
            UserDefaults.standard.set(params, forKey: "localcontacts")
        }
        
        addContactToCache(name: name, email: email, phone: phone)
        
        UserDefaults.standard.synchronize()
        completionHandler("Success",nil)
    }
}

class Contacts: Codable {
    var contact: [Contact]
}

class Contact: Codable {
    var id: Int
    var contact_name: String?
    var organization_name: String?
    var contact_type: String?
    var website: String?
    var primary_contact_number: String?
    var secondary_contact_number: String?
    var primary_email: String?
    var secondary_email: String?
    var status: String?
    var vendor: Bool?
    var customer: Bool?
    var created_at: String?
    var updated_at: String?
    var tax_number: String?
    var deleted_at: String?
    var billing_city: String?
    var billing_state: String?
    var billing_zip: String?
    var billing_country: String?
    var contact_id: Int?
    var billing_address:BillingAddress?
}

class BillingAddress: Codable {
    var id: Int?
    var contact_id: Int?
    var is_default: Bool?
    var billing_address: String?
    var billing_city: String?
    var billing_state: String?
    var billing_zip: String?
    var billing_country: String?
    var created_at: String?
    var updated_at: String?
}

