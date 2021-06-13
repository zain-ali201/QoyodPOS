//
//  OrganizationManager.swift
//  BenefitNet
//
//  Created by Apple on 23/04/2018.
//  Copyright © 2018 Inova Care. All rights reserved.
//

import UIKit

typealias GetCategoriesHandler = ([Category]?, Error?) -> ()
typealias GetProductsHandler = ([Product]?, Error?) -> ()

class CategoriesManager {
    static let shared = CategoriesManager()
    
    func getCategories(completionHandler: @escaping GetCategoriesHandler) {
        var params:[String:String] = [:]
        params["date"] = "0"
        
        let request = API.get(NetworkConfig.Endpoint.getCategories , params:params)
        request.data { (data, response, error) in
            if let _ = error {
                completionHandler(nil, error)
            }else {
                if let data = data {
                    do {
                        let decoder = JSONDecoder()
                        let cats = try decoder.decode(Categories.self, from: data)
                        completionHandler(cats.categories, nil)
                        UserDefaults.standard.set(data, forKey: "category")
                        UserDefaults.standard.synchronize()
                    } catch {
                        completionHandler(nil, error)
                    }
                }
            }
        }
        
        if let data = UserDefaults.standard.data(forKey: "category") {
            do {
                let decoder = JSONDecoder()
                let cats = try decoder.decode(Categories.self, from: data)
                completionHandler(cats.categories, nil)
            } catch {
                
            }
        }
    }
    
    func getProducts(completionHandler: @escaping GetProductsHandler)
    {
        var params:[String:String] = [:]
        params["date"] = "0"
        
        let request = API.get(NetworkConfig.Endpoint.getProducts , params:params)
        request.data { (data, response, error) in
            if let _ = error {
                completionHandler(nil, error)
            }else {
                if let data = data {
                    do {
                        let decoder = JSONDecoder()
                        let products = try decoder.decode(Products.self, from: data)
                        
                        completionHandler(products.products, nil)
                        UserDefaults.standard.set(data, forKey: "product")
                        UserDefaults.standard.synchronize()
                    } catch {
                        completionHandler(nil, error)
                    }
                }
            }
        }
        
        if let data = UserDefaults.standard.data(forKey: "product") {
            do {
                let decoder = JSONDecoder()
                let products = try decoder.decode(Products.self, from: data)
                completionHandler(products.products, nil)
            } catch {
                
            }
        }
    }
}

class Categories: Codable {
    var categories: [Category]
}

class Category: Codable {
    var id: Int
    var name: String
    var description: String
    var parent_id: Int?
    var level: Int
    var created_at: String
    var updated_at: String
}

class Products: Codable {
    var products: [Product]
}

class Product: Codable
{
    var id: Int
    var name: String
    var current_stock: String?
    var track_quantity: Bool
    var product_unit_type_id: Int
    var category_id: Int?
    var barcode: String?
    var average_price: String?
    var sku: String?
    var created_at: String? //using for quantity
    var updated_at: String? //using for discount
    var deleted_at: String? //using for tax
    var buying_price: String?
    var selling_price: String?
    var cogs_account_id: Int?
    var sales_account_id: Int?
    var purchase_account_id: Int?
    var asset_account_id: Int?
    var tax_id: Int?
    var purchase_item: Bool?
    var sale_item: Bool?
    var en_name: String?
    var parent_id: Int?
    var unit_name: String
    var unit_representation: String //using for unit rate
    var large_picture: String
    var small_picture: String
    var type: String
    var units_list: [UnitConversions]
}

class UnitConversions: Codable
{
    var product_id: Int
    var id: Int
    var to_unit: Int
    var from_unit: Int
    var from_unit_name: String
    var rate: String
    var created_at: String
    var updated_at: String
}

