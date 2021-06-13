//
//  OrganizationManager.swift
//  BenefitNet
//
//  Created by Apple on 23/04/2018.
//  Copyright © 2018 Inova Care. All rights reserved.
//

import UIKit

typealias GetInvoicesHander = ([Invoice]?, Error?) -> ()
typealias GetInvoiceHandler = (Invoice?, Error?) -> ()
typealias GetTaxesHander = ([Tax]?, Error?) -> ()
typealias GetAccountsHandler = ([Account]?, Error?) -> ()
typealias CreateInvoiceHandler = (String?, Error?) -> ()
typealias PostPendingInvoicesHandler = (Error?) -> ()

public enum InvoiceStatus: String
{
    case paid = "Paid"
    case unpaid = "Approved"
    case partiallyPaid = "Partially Paid"
}

class InvoicesManager
{
    static let shared = InvoicesManager()
    
    func getInvoice(posNumber:String, completionHandler: @escaping GetInvoiceHandler)
    {
        var params:[String:String] = [:]
        params["pos_number"] = posNumber
        
        let request = API.get(NetworkConfig.Endpoint.getInvoice, params:params)
        request.data { (data, response, error) in
            if let _ = error
            {
                completionHandler(nil, error)
            }
            else
            {
                if let data = data {
                    do {
                        let decoder = JSONDecoder()
                        let invoice = try decoder.decode(Invoice.self, from: data)
                        completionHandler(invoice, nil)
                    } catch {
                        completionHandler(nil, error)
                    }
                }
            }
        }
    }
    
    func getInvoicesByPOSNumber(text: String, forceRefresh:Bool = false, status:InvoiceStatus, completionHandler: @escaping GetInvoicesHander) {
        if forceRefresh
        {
            var params:[String:String] = [:]
            params["value"] = text
            params["status"] = status.rawValue
            
            let request = API.get(NetworkConfig.Endpoint.getInvoicesByPOSNumber, params:params)
            request.data { (data, response, error) in
                if let _ = error {
                    completionHandler(nil, error)
                }
                else
                {
                    if let data = data {
                        do {
                            let decoder = JSONDecoder()
                            let invoices = try decoder.decode(Invoices.self, from: data)
                            completionHandler(invoices.invoices, nil)
                            UserDefaults.standard.set(data, forKey: status.rawValue)
                            UserDefaults.standard.synchronize()
                        }
                        catch
                        {
                            completionHandler(nil, error)
                        }
                    }
                }
            }
        }
        
        if let data = UserDefaults.standard.data(forKey: status.rawValue) {
            do {
                let decoder = JSONDecoder()
                let invoices = try decoder.decode(Invoices.self, from: data)
                completionHandler(invoices.invoices, nil)
            } catch {
                print(error)
            }
        }
        else if !forceRefresh
        {
            getInvoicesByPOSNumber(text: text, forceRefresh: true, status: status, completionHandler: completionHandler)
        }
    }
    
    func getInvoices(offset:Int, forceRefresh:Bool = false, status:InvoiceStatus, completionHandler: @escaping GetInvoicesHander) {
        if forceRefresh
        {
            var params:[String:String] = [:]
            params["date"] = "0"
            params["status"] = status.rawValue
            params["limit"] = "20"
            params["offset"] = String(format: "%i", offset)
            
            let request = API.get(NetworkConfig.Endpoint.getInvoices, params:params)
            request.data { (data, response, error) in
                if let _ = error {
                    completionHandler(nil, error)
                }else {
                    if let data = data {
                        do {
                            let decoder = JSONDecoder()
                            let invoices = try decoder.decode(Invoices.self, from: data)
                            completionHandler(invoices.invoices.reversed(), nil)
                            UserDefaults.standard.set(data, forKey: status.rawValue)
                            UserDefaults.standard.synchronize()
                        } catch {
                            completionHandler(nil, error)
                        }
                    }
                }
            }
        }
        
        if let data = UserDefaults.standard.data(forKey: status.rawValue) {
            do {
                let decoder = JSONDecoder()
                let invoices = try decoder.decode(Invoices.self, from: data)
                completionHandler(invoices.invoices.reversed(), nil)
            } catch {
                print(error)
            }
        }
        else if !forceRefresh
        {
            getInvoices(offset: offset, forceRefresh: true, status: status, completionHandler: completionHandler)
        }
    }
    
    func getProductTaxes(completionHandler: @escaping GetTaxesHander) {
        var params:[String:String] = [:]
        params["date"] = "0"
        
        let request = API.get(NetworkConfig.Endpoint.getTaxes, params:params)
        request.data { (data, response, error) in
            if let _ = error {
                completionHandler(nil, error)
            }else {
                if let data = data {
                    do {
                        let decoder = JSONDecoder()
                        let taxes = try decoder.decode(Taxes.self, from: data)
                        completionHandler(taxes.taxes, nil)
                        UserDefaults.standard.set(data, forKey: "tax")
                        UserDefaults.standard.synchronize()
                    } catch {
                        completionHandler(nil, error)
                    }
                }
            }
        }
        
        if let data = UserDefaults.standard.data(forKey: "tax") {
            do {
                let decoder = JSONDecoder()
                let taxes = try decoder.decode(Taxes.self, from: data)
                completionHandler(taxes.taxes, nil)
            } catch {
                
            }
        }
    }
    
    func getCustomerAccounts(forceReload:Bool = false, completionHandler: @escaping GetAccountsHandler) {
        if forceReload {
            var params:[String:String] = [:]
            params["date"] = "0"
            
            let request = API.get(NetworkConfig.Endpoint.getAccounts, params:params)
            request.data { (data, response, error) in
                if let _ = error {
                    completionHandler(nil, error)
                }else {
                    if let data = data {
                        do {
                            let decoder = JSONDecoder()
                            let accounts = try decoder.decode(Accounts.self, from: data)
                            UserDefaults.standard.set(data, forKey: "account")
                            UserDefaults.standard.synchronize()
                            completionHandler(accounts.account_name, nil)
                        } catch {
                            completionHandler(nil, error)
                        }
                    }
                }
            }
        }
        
        if let data = UserDefaults.standard.data(forKey: "account") {
            do {
                let decoder = JSONDecoder()
                let accounts = try decoder.decode(Accounts.self, from: data)
                completionHandler(accounts.account_name, nil)
            } catch {
                
            }
        }else if !forceReload{
            getCustomerAccounts(forceReload: true, completionHandler: completionHandler)
        }
    }
    
    func addNewInvoiceToCache(invoiceNo:String, customer:Contact ,products:[Product] ,status:InvoiceStatus , totalAmount:String) -> Invoice? {
        var invoice_products:[[String:Any?]] = []
        
        for prod in products {
            invoice_products.append([
                "id" : prod.id,
                "name" : prod.name,
                "description" : "",
                "sku" : prod.sku,
                "row_total" : prod.selling_price,
                "barcode" : prod.barcode,
                "product_id" : prod.id,
                "quantity" : "\(Double(prod.created_at ?? "1.0") ?? 1.0)",
                "rate" : prod.selling_price,
                "discount_percentage" : "0.0",
                "url": "https://s3-eu-west-1.amazonaws.com/qoyoddev/-4531771242208746575/52d7750c3445cb7d7e61d6dde57499b1deec8b26.png",
                "unit_name" : prod.unit_name,
                "tax_percentage" : Int(prod.deleted_at ?? "0")
                ])
        }
       
        let customer_detail:[String:Any?] = [
            "id" : customer.id,
            "contact_name" : customer.contact_name,
            "organization_name" : customer.organization_name,
            "contact_type" : customer.contact_type,
            "website" : customer.website,
            "primary_contact_number" : customer.primary_contact_number,
            "secondary_contact_number" : customer.secondary_contact_number,
            "primary_email" : customer.primary_email,
            "secondary_email" : customer.secondary_email,
            "status" : customer.status,
            "vendor" : customer.vendor,
            "customer" : customer.customer,
            "created_at" : customer.created_at,
            "updated_at" : customer.updated_at,
            "tax_number" : customer.tax_number,
            "deleted_at" : customer.deleted_at,
        ]
        
        let invoice:[String:Any?] = [
            "id" : 0,
            "contact_id" : 0,
            "tenant_payment_term_id" : 0,
            "invoice_number" : invoiceNo,
            "invoice_description" : "",
            "invoiced_date" : Formatter.serverDateTime.string(from: Date()),
            "due_on" : "",
            "status" : status.rawValue,
            "term_conditions" : "",
            "notes" : "",
            "total" : totalAmount,
            "is_mail_sent" : false,
            "is_reminder_sent" : false,
            "last_reminder_sent_on" : "",
            "modified_date" : "",
            "contact_shiping_address_id" : 0,
            "paid_amount" : totalAmount,
            "due_amount" : totalAmount,
            "quote_id" : 0,
            "created_at" : Formatter.serverDateTime.string(from: Date()),
            "updated_at" : "",
            "created_through_mobile" : true,
            "pos_invoice_no" : invoiceNo,
            "deleted_at" : 0,
        ]
        
        let finalData:[String:Any] = [
            "invoice": invoice,
            "customer_detail": customer_detail,
            "invoice_products": invoice_products
        ]
        
        do {
            if let paidData = UserDefaults.standard.data(forKey: "Paid"), let partiallypaidData = UserDefaults.standard.data(forKey: "Partially Paid") , let unpaidData = UserDefaults.standard.data(forKey: "Approved"){
                let data = try JSONSerialization.data(withJSONObject: finalData, options: [])
                let decoder = JSONDecoder()
                let piadInvoices = try decoder.decode(Invoices.self, from: paidData)
                let partiallyPaidnvoices = try decoder.decode(Invoices.self, from: partiallypaidData)
                let unPaidnvoices = try decoder.decode(Invoices.self, from: unpaidData)
                
                let invoiceObject = try decoder.decode(Invoice.self, from: data)
                
                if status == .paid
                {
                    piadInvoices.invoices.append(invoiceObject)
                }
                else if status == .partiallyPaid
                {
                    partiallyPaidnvoices.invoices.append(invoiceObject)
                }
                else
                {
                    unPaidnvoices.invoices.append(invoiceObject)
                }
                
                let encoder = JSONEncoder()
                let paidNewData = try encoder.encode(piadInvoices)
                let partiallypaidNewData = try encoder.encode(partiallyPaidnvoices)
                let unPaidNewData = try encoder.encode(unPaidnvoices)
                
                UserDefaults.standard.set(paidNewData, forKey: "Paid")
                UserDefaults.standard.set(partiallypaidNewData, forKey: "Partially Paid")
                UserDefaults.standard.set(unPaidNewData, forKey: "Approved")
                UserDefaults.standard.synchronize()
                
                return invoiceObject
            }
        }catch {
            print(error)
        }
        
        return nil
    }
    
    func postPendingNewInvoices(completionHandler: @escaping PostPendingInvoicesHandler)
    {
        if var params = UserDefaults.standard.dictionary(forKey: "unpaidinvoices")
        {
            do {
                if let localContacts = UserDefaults.standard.data(forKey: "contact"){
                    let decoder = JSONDecoder()
                    let contacts = try decoder.decode(Contacts.self, from: localContacts)
                    
                    if var invoices = params["invoice"] as? [[String : Any]] {
                        for (index, invoice) in invoices.enumerated() {
                            if let contactId = invoice["contact_id"] as? Int , contactId  == 0 {
                                let filterContacts = contacts.contact.filter { (contact) -> Bool in
                                    return contact.primary_contact_number == invoice["primary_contact_number"] as? String
                                }
                                
                                if let selectedContact = filterContacts.first {
                                    var modifiedInvoice = invoice
                                    modifiedInvoice["contact_id"] = selectedContact.id
                                    
                                    invoices[index] = modifiedInvoice
                                }
                            }
                        }
                        
                        params["invoice"] = invoices
                    }
                }
            }
            catch
            {
                print(error)
            }
            print(params)
            let request = API.post(NetworkConfig.Endpoint.getInvoices, params:params, contentType: .json)
            request.json { (json, response, error) in
                if let error = error
                {
                    completionHandler(error)
                }
                else if let _ = json as? [String:Any]
                {
                    UserDefaults.standard.removeObject(forKey: "unpaidinvoices")
                    UserDefaults.standard.synchronize()
                    completionHandler(nil)
                }
                else
                {
                    completionHandler(NetworkError.unknown)
                }
            }
        }
        completionHandler(nil)
    }
    
    func postPendingPartialInvoices(completionHandler: @escaping PostPendingInvoicesHandler)
    {
        if var params = UserDefaults.standard.dictionary(forKey: "partiallypaidinvoices")
        {
            do {
                if let localContacts = UserDefaults.standard.data(forKey: "contact"){
                    let decoder = JSONDecoder()
                    let contacts = try decoder.decode(Contacts.self, from: localContacts)
                    
                    if var invoices = params["invoice"] as? [[String : Any]] {
                        for (index, invoice) in invoices.enumerated() {
                            if let contactId = invoice["contact_id"] as? Int , contactId  == 0 {
                                let filterContacts = contacts.contact.filter { (contact) -> Bool in
                                    return contact.primary_contact_number == invoice["primary_contact_number"] as? String
                                }
                                
                                if let selectedContact = filterContacts.first {
                                    var modifiedInvoice = invoice
                                    modifiedInvoice["contact_id"] = selectedContact.id
                                    
                                    invoices[index] = modifiedInvoice
                                }
                            }
                        }
                        
                        params["invoice"] = invoices
                    }
                }
            }
            catch
            {
                print(error)
            }
            print(params)
            let request = API.post(NetworkConfig.Endpoint.getInvoices, params:params, contentType: .json)
            request.json { (json, response, error) in
                if let error = error
                {
                    completionHandler(error)
                }
                else if let _ = json as? [String:Any]
                {
                    UserDefaults.standard.removeObject(forKey: "partiallypaidinvoices")
                    UserDefaults.standard.synchronize()
                    completionHandler(nil)
                }
                else
                {
                    completionHandler(NetworkError.unknown)
                }
            }
        }
        completionHandler(nil)
    }
    
    public var invoiceToPrint:Invoice? = nil
    
    func createInvoiceWithStatus(invoiceNo:String, contact:Contact, products:[Product], status:InvoiceStatus, totalAmount:String, totalPaidAmount:String, accounts:[SelectedAccount], completionHandler: @escaping CreateInvoiceHandler) {
        var invoiceAttributes:[[String:Any]] = []
        
        for product in products {
            
            let unitRate = (Double(product.created_at ?? "1.0") ?? 1.0) * (Double(product.unit_representation) ?? 1.0)
            
            invoiceAttributes.append([
                "product_id" : product.id,
                "quantity" : Double(product.created_at ?? "1.0") ?? 1.0,
                "rate" : product.selling_price ?? 0,
                "tax_percentage" : Double(product.deleted_at ?? "0") ?? 0.0,
                "discount_percentage" : Double(product.updated_at ?? "0") ?? 0.0,
//                "unit_type" : product.unit_name,
                "unit_type" : product.product_unit_type_id,
                "unit_rate" : unitRate,
                "row_total" : product.selling_price ?? 0
                ])
        }
        
        var receiptsAttributes:[[String:Any]] = []
        
        for account in accounts {
            receiptsAttributes.append([
                "account_id" : account.accountID,
                "paid_amount" : account.amount
                ])
        }
        
        let dateFormatterPrint = DateFormatter()
        dateFormatterPrint.dateFormat = "yyyy-MMM-dd"
        
        var invoiceDict:[String:Any] = [
            "primary_contact_number" : contact.primary_contact_number ?? "",
            "pos_invoice_no" : invoiceNo,
            "invoiced_date" : dateFormatterPrint.string(from: Date()),
            "contact_id" : contact.id,
            "total" : totalAmount,
            "paid_amount" : totalPaidAmount,
            "status" : status == .unpaid ? "Approved" : "Paid",
            "payments" : receiptsAttributes,
            "location_id" : Int(UserDefaults.standard.string(forKey: UserDefaults.Key.orgLocationId) ?? "") ?? 0,
            "contact_invoice_details_attributes" : invoiceAttributes
        ]
        
        //no payment method if invoice is not paid. 
        if status == .unpaid {
            invoiceDict.removeValue(forKey: "receipts_attributes")
        }
        
        
        var params:[String:Any] = [:]
        params["invoice"] = [invoiceDict]
        
        invoiceToPrint = addNewInvoiceToCache(invoiceNo: invoiceNo, customer: contact, products: products, status: status, totalAmount: totalAmount)
        
        if status == .unpaid
        {
            if var paidOnes = UserDefaults.standard.dictionary(forKey: "unpaidinvoices")
            {
                if var dict = paidOnes["invoice"] as? [[String:Any]]
                {
                    dict.append(invoiceDict)
                    paidOnes["invoice"] = dict
                }
                UserDefaults.standard.set(paidOnes, forKey: "unpaidinvoices")
            }
            else
            {
                UserDefaults.standard.set(params, forKey: "unpaidinvoices")
            }
        }
        else if status == .partiallyPaid
        {
            if var paidOnes = UserDefaults.standard.dictionary(forKey: "partiallypaidinvoices")
            {
                if var dict = paidOnes["invoice"] as? [[String:Any]]
                {
                    dict.append(invoiceDict)
                    paidOnes["invoice"] = dict
                }
                UserDefaults.standard.set(paidOnes, forKey: "partiallypaidinvoices")
            }
            else
            {
                UserDefaults.standard.set(params, forKey: "partiallypaidinvoices")
            }
        }
        else
        {
            if var paidOnes = UserDefaults.standard.dictionary(forKey: "paidinvoices")
            {
                if var dict = paidOnes["invoice"] as? [[String:Any]]
                {
                    dict.append(invoiceDict)
                    paidOnes["invoice"] = dict
                }
                UserDefaults.standard.set(paidOnes, forKey: "paidinvoices")
            }
            else
            {
                UserDefaults.standard.set(params, forKey: "paidinvoices")
            }
        }
        
        UserDefaults.standard.synchronize()
        completionHandler("Success",nil)
    }
    
    func moveInvoiceToPaid(invoice:Invoice)
    {
        if let paidData = UserDefaults.standard.data(forKey: "Paid"), let partiallypaidData = UserDefaults.standard.data(forKey: "Partially Paid"), let unpaidData = UserDefaults.standard.data(forKey: "Approved"){
            do {
                let decoder = JSONDecoder()
                let piadInvoices = try decoder.decode(Invoices.self, from: paidData)
                let partiallyPiadInvoices = try decoder.decode(Invoices.self, from: partiallypaidData)
                let unPaidnvoices = try decoder.decode(Invoices.self, from: unpaidData)
                
                let index = unPaidnvoices.invoices.index { (obj) -> Bool in
                    return obj.invoice.pos_invoice_no! == invoice.invoice.pos_invoice_no!
                }
                
                if let index = index
                {
                    unPaidnvoices.invoices.remove(at: index)
                }
                
                let index1 = partiallyPiadInvoices.invoices.index { (obj) -> Bool in
                    return obj.invoice.pos_invoice_no! == invoice.invoice.pos_invoice_no!
                }
                
                if let index1 = index1
                {
                    partiallyPiadInvoices.invoices.remove(at: index1)
                }
                
                invoice.invoice.status = "Paid"
                
                piadInvoices.invoices.append(invoice)
                
                let encoder = JSONEncoder()
                let paidNewData = try encoder.encode(piadInvoices)
                let partiallypaidNewData = try encoder.encode(partiallyPiadInvoices)
                let unPaidNewData = try encoder.encode(unPaidnvoices)
                
                UserDefaults.standard.set(paidNewData, forKey: "Paid")
                UserDefaults.standard.set(partiallypaidNewData, forKey: "Partially Paid")
                UserDefaults.standard.set(unPaidNewData, forKey: "Approved")
                UserDefaults.standard.synchronize()
                
            } catch {
            }
        }
    }
    
    func postPendingApprovedInvoices(completionHandler: @escaping PostPendingInvoicesHandler) {
        if let params = UserDefaults.standard.dictionary(forKey: "paidinvoices") {
            print(params)
            let request = API.post(NetworkConfig.Endpoint.getInvoices, params:params, contentType: .json)
            request.json { (json, response, error) in
                if let error = error {
                    completionHandler(error)
                }else if let _ = json as? [String:Any]{
                    print(json)
                    UserDefaults.standard.removeObject(forKey: "paidinvoices")
                    UserDefaults.standard.synchronize()
                    completionHandler(nil)
                }else{
                    completionHandler(NetworkError.unknown)
                }
            }
        }
        completionHandler(nil)
    }
    
    func createInvoiceApproved(invoice:Invoice, totalAmount:String, accountId:Int , completionHandler: @escaping CreateInvoiceHandler) {
        var invoiceAttributes:[[String:Any]] = []
        
        for product in invoice.invoice_products ?? [] {
            invoiceAttributes.append([
                "product_id" : product.product_id ?? 0,
                "quantity" : product.quantity ?? 0,
                "rate" : product.rate ?? 0,
                "row_total" : product.row_total ?? 0
                ])
        }
        
        let invoiceDict:[String:Any] = [
            "primary_contact_number" : invoice.customer_detail.primary_contact_number ?? "",
            "pos_invoice_no" : invoice.invoice.pos_invoice_no ?? "",
            "invoiced_date" : invoice.invoice.invoiced_date ?? "",
            "contact_id" : invoice.invoice.contact_id ?? "",
            "total" : totalAmount,
            "paid_amount" : totalAmount,
            "status" : "Paid",
            "account_id" : accountId,
            "location_id" : Int(UserDefaults.standard.string(forKey: UserDefaults.Key.orgLocationId) ?? "") ?? 0,
            "contact_invoice_details_attributes" : invoiceAttributes
        ]
        
        var params:[String:Any] = [:]
        params["invoice"] = [invoiceDict]
        
        if var paidOnes = UserDefaults.standard.dictionary(forKey: "paidinvoices") {
            if var dict = paidOnes["invoice"] as? [[String:Any]] {
                dict.append(invoiceDict)
                paidOnes["invoice"] = dict
            }
            UserDefaults.standard.set(paidOnes, forKey: "paidinvoices")
        }else {
            UserDefaults.standard.set(params, forKey: "paidinvoices")
        }
        
        moveInvoiceToPaid(invoice: invoice)
        
        UserDefaults.standard.synchronize()
        completionHandler("Success",nil)
    }
}

class Accounts: Codable {
    var account_name: [Account]
}

class Account: Codable {
    var id: Int
    var name: String
}

class Taxes: Codable {
    var taxes: [Tax]
}

class Tax: Codable {
    var id: Int
    var account_id: Int
    var arabic_name: String?
    var english_name: String?
    var percentage: Int?
    var created_at: String?
    var updated_at: String?
}

class Invoices: Codable {
    var invoices: [Invoice]
}

class Invoice: Codable {
    var invoice: InvoiceData
    var customer_detail: CustomerDetail
    var invoice_products: [InvoiceProducts]?
}

class InvoiceData: Codable
{
    var id: Int?
    var contact_id: Int?
    var tenant_payment_term_id: Int?
    var invoice_number: String?
    var invoice_description: String?
    var invoiced_date: String?
    var due_on: String?
    var status: String?
    var term_conditions: String?
    var notes: String?
    var total: String?
    var is_mail_sent: Bool?
    var is_reminder_sent: Bool?
    var last_reminder_sent_on: String?
    var modified_date: String?
    var contact_shiping_address_id: Int?
    var paid_amount: String?
    var due_amount: String?
    var quote_id: Int?
    var created_at: String?
    var updated_at: String?
    var created_through_mobile: Bool?
    var pos_invoice_no: String?
    var deleted_at: Int?
}

class CustomerDetail: Codable {
    var id: Int = 0
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
}

class InvoiceProducts: Codable {
    var id: Int?
    var name: String?
    var description: String?
    var sku: String?
    var row_total: String?
    var barcode: String?
    var product_id: Int?
    var quantity: String?
    var rate: String?
    var discount_percentage: String?
    var url: String?
    var unit_name: String?
    var tax_percentage: Int?
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case name = "name"
        case description = "description"
        case sku = "sku"
        case row_total = "row_total"
        case barcode = "barcode"
        case product_id = "product_id"
        case quantity = "quantity"
        case rate = "rate"
        case discount_percentage = "discount_percentage"
        case url = "url"
        case unit_name = "unit_name"
        case tax_percentage = "tax_percentage"
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encode(sku, forKey: .sku)
        try container.encode(row_total, forKey: .row_total)
        try container.encode(barcode, forKey: .barcode)
        try container.encode(product_id, forKey: .product_id)
        try container.encode(quantity, forKey: .quantity)
        try container.encode(rate, forKey: .rate)
        try container.encode(discount_percentage, forKey: .discount_percentage)
        try container.encode(url, forKey: .url)
        try container.encode(unit_name, forKey: .unit_name)
        try container.encode(tax_percentage, forKey: .tax_percentage)
    }
    
    //to handle quantity
    required init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String?.self, forKey: .name)
        description = try container.decode(String?.self, forKey: .description)
        sku = try container.decode(String?.self, forKey: .sku)
        row_total = try container.decode(String?.self, forKey: .row_total)
        barcode = try container.decode(String?.self, forKey: .barcode)
        discount_percentage = try container.decode(String?.self, forKey: .discount_percentage)
        rate = try container.decode(String?.self, forKey: .rate)
        url = try container.decode(String?.self, forKey: .url)
        product_id = try container.decode(Int?.self, forKey: .product_id)
        unit_name = try container.decode(String?.self, forKey: .unit_name)
        tax_percentage = try container.decode(Int?.self, forKey: .tax_percentage)
        
        //sometimes quantity is considered string and sometimes int
        if let value = try? container.decode(Int.self, forKey: .quantity) {
            quantity = String(value)
        } else {
            quantity = try container.decode(String.self, forKey: .quantity)
        }
    }
}
