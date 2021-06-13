//
//  NetworkConfig.swift
//  Qoyod
//
//  Created by Sharjeel Ahmad on 01/01/2018.
//  Copyright © 2018 Qoyod. All rights reserved.
//

import Foundation

struct NetworkConfig {
    
    //Production URLs
//    static let baseUrl = "https://qoyod.com/api/v1"
//    static let passwordUrl = "https://qoyod.com/users/password/new"
//    static let registerUrl = "https://www.qoyod.com/home/free_trial_sign_up"
    
    //Stagging URLs
    static let baseUrl = "https://staaging.qoyod.com/api/v1"
    static let passwordUrl = "https://staaging.qoyod.com/users/password/new"
//    static let registerUrl = "https://staaging.qoyod.com/home/free_trial_sign_up"
    static let registerUrl = "https://www.qoyod.com/en/pricing"
    static let environment = Environment(apiPath: NetworkConfig.baseUrl)
    
    struct Endpoint {
        static let login = "/sessions"
        static let logout = "/sessions/destroy_user"
        static let userStatus = "/sessions/user_auth_status"
        
        //organizations
        static let getOrganizations = "/dashboard/organizations"
        static let setOrganization = "/dashboard/set_organization"
        
        //categories
        static let getCategories = "/categories"
        static let getProducts = "/products"
        
        //invoices
        static let getInvoices = "/invoices"
        static let getInvoicesByPOSNumber = "/invoices/invoices_by_pos_or_customer"
        
        static let getInvoice = "/invoices/get_inv_by_pos"
        static let getTaxes = "/products/taxes"
        static let getAccounts = "/accounts"
        
        //contacts
        static let contacts = "/contacts"
        
        //user
        static let updatePin = "/users/update_identification_number"
        
    }
}
