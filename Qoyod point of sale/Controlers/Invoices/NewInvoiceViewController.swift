//
//  NewInvoiceViewController.swift
//  Qoyod point of sale
//
//  Created by Sharjeel Ahmad on 03/09/2018.
//  Copyright © 2018 Sharjeel Ahmad. All rights reserved.
//

import UIKit
import Reachability

var homeVC:NewInvoiceViewController!
var invoicesVC:InvoicesViewController!
var printerFlag = false
var alertFlag = true

class CategoryCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var textLabel: UILabel!
}

var invoicesPaid:[Invoice] = []
var invoicesUnPaid:[Invoice] = []
var invoicesPartiallyPaid:[Invoice] = []
var allTaxes:[Tax]!
var allProductsFlag = true

var paidOffset = 0
var unpaidOffset = 0
var partiallyOffset = 0

var timer:Timer!

class NewInvoiceViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource
{
    @IBOutlet weak var categoriesCollectionView: UICollectionView!
    @IBOutlet weak var selectBtn: UIButton!
    @IBOutlet weak var allCategoriesTop: NSLayoutConstraint!
    fileprivate lazy var categories:[Category] = []
    fileprivate lazy var products:[Product] = []
    fileprivate lazy var categoriesDataSource:[Category] = []
    var selectedCategory:Category!
    var productsContainer:ProductsViewController!
    @IBOutlet weak var searchBar: UISearchBar!
    
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var lblAllCat: UILabel!
    @IBOutlet weak var lblAllProd: UILabel!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        rootVC?.viewControllers![0].title = languageBundle!.localizedString(forKey: "Invoices", value: "", table: nil)
        rootVC?.viewControllers![1].title = languageBundle!.localizedString(forKey: "New Invoice", value: "", table: nil)
        rootVC?.viewControllers![2].title = languageBundle!.localizedString(forKey: "Settings", value: "", table: nil)
        
        homeVC = self
        
        
        //for dynamic label size
        if let flowLayout = categoriesCollectionView.collectionViewLayout as? UICollectionViewFlowLayout { flowLayout.estimatedItemSize = CGSize(width: 1, height: 1) }
        
        //hide search by default
        allCategoriesTop.constant = 10
        
        //timer to sync data
        timer = Timer.scheduledTimer(timeInterval: 15, target: self, selector: #selector(self.syncAllData), userInfo: nil, repeats: true)
        
        Timer.scheduledTimer(timeInterval: 180, target: self, selector: #selector(self.checkReachability), userInfo: nil, repeats: true)
        
        //notification to sync data
        NotificationCenter.default.addObserver(self, selector: #selector(checkReachability), name: Notification.Name.syncData, object: nil)
        
        syncAllData()
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        
        if categories.count == 0 {
            self.showActivityIndicator()
            syncAllData()
        }
        allInvoicesFlag = true
        
        lblTitle.text = languageBundle!.localizedString(forKey: "New Invoice", value: "", table: nil)
        lblAllCat.text = languageBundle!.localizedString(forKey: "All Categories", value: "", table: nil)
        lblAllProd.text = languageBundle!.localizedString(forKey: "All Products", value: "", table: nil)
        selectBtn.setTitle(languageBundle!.localizedString(forKey: "Deselect all", value: "", table: nil), for: .normal)
        searchBar.placeholder = languageBundle!.localizedString(forKey: "Search Products", value: "", table: nil)
    }
    
    @objc func checkReachability()
    {
        Reachability.startMonitoring()
        
        if !Reachability.isReachable
        {
            UIApplication.shared.windows[UIApplication.shared.windows.count - 1].makeToast(languageBundle!.localizedString(forKey: "Unable to connect with the server. Please check your internet connection.", value: "", table: nil))
            
            var flag = false
            
            for invoice in invoicesPaid
            {
                if invoice.invoice.updated_at == nil || invoice.invoice.updated_at!.isEmpty
                {
                    flag = true
                    break
                }
            }
            
            if !flag
            {
                for invoice in invoicesUnPaid
                {
                    if invoice.invoice.updated_at == nil || invoice.invoice.updated_at!.isEmpty
                    {
                        flag = true
                        break
                    }
                }
            }
            
            if !flag
            {
                for invoice in invoicesPartiallyPaid
                {
                    if invoice.invoice.updated_at == nil || invoice.invoice.updated_at!.isEmpty
                    {
                        flag = true
                        break
                    }
                }
            }
            
            if flag
            {
                self.perform(#selector(unsyncMsg), with: nil, afterDelay: 3)
            }
        }
    }
    
    @objc func unsyncMsg()
    {
        UIApplication.shared.windows[UIApplication.shared.windows.count - 1].makeToast(languageBundle!.localizedString(forKey: "You have some unsynchronized invoices in the app.", value: "", table: nil))
    }
    
    @objc func syncAllData()
    {
//        print("....SYNC....")
        
        if !Reachability.isReachable && alertFlag
        {
            checkReachability()
            alertFlag = false
        }
        
        AuthManager.shared.checkUserStatus{[weak self] (success, error) in
            
            if !success.isEmpty && success == "false"
            {
                self!.logoutUser()
            }
            else
            {
                //load categories
                CategoriesManager.shared.getCategories {[weak self] (cats, error) in
                    self?.hideActivityIndicator()
                    if let error = error{
                        loggingPrint(error)
                    }
                    else
                    {
                        if let cats = cats
                        {
                            if allProductsFlag
                            {
                                self?.categories = cats
                                self?.categoriesCollectionView.reloadData()
                            }
                        }
                    }
                }
                
                //load products
                CategoriesManager.shared.getProducts {[weak self] (products, error) in
                    if let error = error{
                        loggingPrint(error)
                    }
                    else
                    {
                        if let products = products
                        {
                            self?.products = products
                            allProducts = products
                            
                            if allProductsFlag
                            {
                                self?.productsContainer.products = products
                                self?.productsContainer.refreshSource()
                            }
                        }
                    }
                }
                
                //sync pending customers
                CustomerManager.shared.postPendingNewCustomers { (error) in
                    //load customers
                    CustomerManager.shared.getContacts(getCached: false, completionHandler: { (contact, error) in
                        //sync pending new invoices
                        InvoicesManager.shared.postPendingApprovedInvoices { (error) in
                            //load paid invoices
                            if allInvoicesFlag
                            {
                                InvoicesManager.shared.getInvoices(offset: paidOffset,forceRefresh: true, status: .paid, completionHandler: {[weak self] (invoices, error) in
                                    
                                    if let error = error
                                    {
                                        loggingPrint(error)
                                    }
                                    else if let invoices = invoices
                                    {
                                        if allInvoicesFlag
                                        {
                                            for invoice in invoices
                                            {
                                                if invoicesPaid.contains(where: { (paidInvoice) -> Bool in
                                                    return paidInvoice.invoice.pos_invoice_no == invoice.invoice.pos_invoice_no
                                                }) {

                                                    let index = invoicesPaid.index(where: { (paidInvoice) -> Bool in
                                                        return paidInvoice.invoice.pos_invoice_no == invoice.invoice.pos_invoice_no
                                                    })
                                                    invoicesPaid[index!] = invoice

                                                }
                                                else
                                                {
                                                    invoicesPaid.append(invoice)
                                                }
                                            }
                                        }
                                        
                                        if invoicesVC != nil
                                        {
                                            invoicesVC.refreshSource()
                                        }
                                    }
                                })
                            }
                        }
                    })
                }
            
                //sync pending unpaid invoices
                InvoicesManager.shared.postPendingNewInvoices { (error) in
                    //load unpaid invoices
                    if allInvoicesFlag
                    {
                        InvoicesManager.shared.getInvoices(offset: unpaidOffset,forceRefresh: true, status: .unpaid) {[weak self] (invoices, error) in
                            if let error = error {
                                loggingPrint(error)
                            }
                            else if let invoices = invoices
                            {
                                if allInvoicesFlag
                                {
                                    for invoice in invoices
                                    {
                                        if invoicesUnPaid.contains(where: { (unpaidInvoice) -> Bool in
                                            return unpaidInvoice.invoice.pos_invoice_no == invoice.invoice.pos_invoice_no
                                        }) {

                                            let index = invoicesUnPaid.index(where: { (unpaidInvoice) -> Bool in
                                                return unpaidInvoice.invoice.pos_invoice_no == invoice.invoice.pos_invoice_no
                                            })
                                            invoicesUnPaid[index!] = invoice

                                        }
                                        else
                                        {
                                            invoicesUnPaid.append(invoice)
                                        }
                                    }
                                }
                                
                                if invoicesVC != nil
                                {
                                    invoicesVC.refreshSource()
                                }
                            }
                        }
                    }
                }
                
                //sync pending partially paid invoices
                InvoicesManager.shared.postPendingPartialInvoices { (error) in
                    //load unpaid invoices
                    if allInvoicesFlag
                    {
                        InvoicesManager.shared.getInvoices(offset: partiallyOffset,forceRefresh: true, status: .partiallyPaid) {[weak self] (invoices, error) in
                            if let error = error {
                                loggingPrint(error)
                            }
                            else if let invoices = invoices
                            {
                                if allInvoicesFlag
                                {
                                    for invoice in invoices
                                    {
                                        if invoicesPartiallyPaid.contains(where: { (partiallypaidInvoice) -> Bool in
                                            return partiallypaidInvoice.invoice.pos_invoice_no == invoice.invoice.pos_invoice_no
                                        }) {
                                            
                                            let index = invoicesPartiallyPaid.index(where: { (partiallypaidInvoice) -> Bool in
                                                return partiallypaidInvoice.invoice.pos_invoice_no == invoice.invoice.pos_invoice_no
                                            })
                                            invoicesPartiallyPaid[index!] = invoice
                                            
                                        }
                                        else
                                        {
                                            invoicesPartiallyPaid.append(invoice)
                                        }
                                    }
                                }
                                
                                if invoicesVC != nil
                                {
                                    invoicesVC.refreshSource()
                                }
                            }
                        }
                    }
                }
            
                //load taxes invoices
                InvoicesManager.shared.getProductTaxes {[weak self] (taxes, error) in
                    if let error = error {
                        loggingPrint(error)
                    }else if let taxes = taxes {
                        allTaxes = taxes
                    }
                }
            
                //load accounts
                InvoicesManager.shared.getCustomerAccounts(forceReload: true) { (accounts, error) in
                }
                
                let orgLogoURL =  UserDefaults.standard.string(forKey: "Qoyod.Key.orglogo")
                
                if orgLogoURL != nil && !(orgLogoURL?.isEmpty)! && (orgLogoURL != "No Logo")
                {
                    CommonManager.shared.getImage(forUrl: String(format: "http:%@", orgLogoURL!)) { (image, error) in
                        if let error = error
                        {
                            loggingPrint(error)
                        }
                        else if let image = image {
                            orgImage = image
                        }
                    }
                }
            }
        }
    }
    
    func logoutUser()
    {
        if timer != nil
        {
            timer.invalidate()
        }
        self.hideActivityIndicator()
        let alert = UIAlertController(title: "" , message: languageBundle!.localizedString(forKey: "Do you want to sync unsynced invoices?", value: "", table: nil), preferredStyle: UIAlertControllerStyle.alert)
        
        //add actions
        alert.addAction(UIAlertAction(title: languageBundle!.localizedString(forKey: "YES", value: "", table: nil), style: .default, handler: { action in
            
            self.showActivityIndicator()
            InvoicesManager.shared.postPendingNewInvoices(completionHandler: { (error) in
                if let error = error
                {
                    self.hideActivityIndicator()
                    self.show(error: error)
                }
                else
                {
                    InvoicesManager.shared.postPendingApprovedInvoices(completionHandler: { (error) in
                        if let error = error
                        {
                            self.hideActivityIndicator()
                            self.show(error: error)
                        }
                        else
                        {
                            //finally logout
                            self.showActivityIndicator()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0, execute: {
                                
                                AuthManager.shared.logout {[weak self] (success, error) in
                                    self?.hideActivityIndicator()
                                    if success
                                    {
                                        invoicesUnPaid.removeAll()
                                        invoicesPaid.removeAll()
                                        
                                        let controller = UIStoryboard.onboarding.instantiateViewController(withIdentifier: "Login")
                                        self?.present(controller, animated: true, completion: nil)
                                    }
                                }
                            })
                        }
                    })
                }
            })
        }))
        
        alert.addAction(UIAlertAction(title: languageBundle!.localizedString(forKey: "NO", value: "", table: nil), style: .cancel, handler: { action in
            
            self.showActivityIndicator()
            AuthManager.shared.logout {[weak self] (success, error) in
                self?.hideActivityIndicator()
                if success {
                    
                    invoicesUnPaid.removeAll()
                    invoicesPaid.removeAll()
                    let domain = Bundle.main.bundleIdentifier!
                    UserDefaults.standard.removePersistentDomain(forName: domain)
                    UserDefaults.standard.synchronize()
                    
                    let controller = UIStoryboard.onboarding.instantiateViewController(withIdentifier: "Login")
                    self?.present(controller, animated: true, completion: nil)
                }
            }
            
        }))
        
        //present the dialog
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func searchTapped(_ sender: UIButton)
    {
        showSearch()
    }
    
    @IBAction func selectBtnAction(_ button: UIButton)
    {
        if button.tag == 0
        {
            button.setTitle(languageBundle!.localizedString(forKey: "Select all", value: "", table: nil), for: .normal)
            
            for category in categories
            {
                category.level = 1
            }
            
            allProductsFlag = false
            self.productsContainer.products = []
            self.productsContainer.refreshSource()
            button.tag = 1
        }
        else
        {
            button.setTitle(languageBundle!.localizedString(forKey: "Deselect all", value: "", table: nil), for: .normal)
            
            for category in categories
            {
                category.level = 0
            }
            
            allProductsFlag = true
            self.productsContainer.products = allProducts
            self.productsContainer.refreshSource()
            button.tag = 0
        }
        
        categoriesCollectionView.reloadData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if sender == nil , let productsVC = segue.destination as? ProductsViewController  {
//            productsVC.selectedCategory = selectedCategory
            productsVC.products = products
            productsVC.superView = productsContainer
            productsVC.selectedProducts = productsContainer.selectedProducts
        } else if let productsVC = segue.destination as? ProductsViewController {
            productsContainer = productsVC
        }
    }
    
    private func hideSearch() {
        allCategoriesTop.constant = 10
        UIView.animate(withDuration: 0.2, animations: {
            self.view.layoutIfNeeded()
        }) { (isDone) in
            if isDone {
                
            }
        }
    }
    
    private func showSearch() {
        allCategoriesTop.constant = 66
        UIView.animate(withDuration: 0.2, animations: {
            self.view.layoutIfNeeded()
        }) { (isDone) in
            if isDone {
                self.searchBar.becomeFirstResponder()
            }
        }
    }
}

extension NewInvoiceViewController: UISearchBarDelegate {
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = true
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        productsContainer.searchTerm = searchText
        productsContainer.refreshSource()
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        productsContainer.refreshSource()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        hideSearch()
        searchBar.text = ""
        productsContainer.searchTerm = ""
        productsContainer.refreshSource()
        searchBar.showsCancelButton = false
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        selectedCategory = categories[indexPath.row]
        
        if selectedCategory.level == 0
        {
            selectedCategory.level = 1
            
            self.productsContainer.products = self.productsContainer.products.filter({ (product) -> Bool in
                return product.category_id != selectedCategory.id
            })
            self.productsContainer.refreshSource()
            
            allProductsFlag = false
            
            selectBtn.setTitle(languageBundle!.localizedString(forKey: "Select all", value: "", table: nil), for: .normal)
        }
        else
        {
            selectedCategory.level = 0
            
            allProductsFlag = true
            
            for category in categories
            {
                if category.level == 1
                {
                    allProductsFlag = false
                    break
                }
            }
            
            if allProductsFlag
            {
                selectBtn.setTitle(languageBundle!.localizedString(forKey: "Deselect all", value: "", table: nil), for: .normal)
                self.productsContainer.products = allProducts
            }
            else
            {
                let products = allProducts.filter({ (product) -> Bool in
                    return product.category_id == selectedCategory.id
                })
                
                self.productsContainer.products.append(contentsOf: products)
            }
    
            self.productsContainer.refreshSource()
        }
        
        collectionView.reloadData()
//        performSegue(withIdentifier: "products", sender: nil)
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return categories.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as? CategoryCollectionViewCell else {
            return UICollectionViewCell()
        }
        
        let category = categories[indexPath.row]
        
        cell.textLabel.text = category.name
        cell.textLabel.preferredMaxLayoutWidth = 100
        
        if category.level == 1
        {
            cell.textLabel.alpha = 0.5
        }
        else
        {
            cell.textLabel.alpha = 1.0
        }
        
        
        return cell
    }
}
