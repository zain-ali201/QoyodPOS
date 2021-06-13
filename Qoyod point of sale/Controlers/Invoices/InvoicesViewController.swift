//
//  InvoicesViewController.swift
//  Qoyod point of sale
//
//  Created by Sharjeel Ahmad on 03/09/2018.
//  Copyright © 2018 Sharjeel Ahmad. All rights reserved.
//

import UIKit
import AVFoundation
import CCBottomRefreshControl
import Reachability

var allProducts:[Product] = []
var orgImage: UIImage!

var allInvoicesFlag = true

class InvoicesTableViewCell: UITableViewCell
{
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var subTitle: UILabel!
    @IBOutlet weak var date: UILabel!
    @IBOutlet weak var amount: UILabel!
    @IBOutlet weak var upload: UIImageView!
    @IBOutlet weak var lblSync: UILabel!
}

class InvoicesViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    fileprivate var tableViewDatasource:[Invoice]!
    lazy fileprivate var pickerTextField = UITextField()
    lazy var pickerView = UIPickerView()
//    var componentList = [languageBundle!.localizedString(forKey: "Unpaid Invoices", value: "", table: nil),languageBundle!.localizedString(forKey: "Paid Invoices", value: "", table: nil)]
    
    var componentList = ["Unpaid Invoices", "Partially Paid Invoices", "Paid Invoices"]
    var filterList = ["All", "Synchronized", "Unsynchronized"]
    
    var filterFlag = 1
    
    @IBOutlet var lblInvoice: UILabel!
    @IBOutlet var lblFilter: UILabel!
    @IBOutlet var lblInvoiceTitle: UILabel!
    @IBOutlet var lblFilterTitle: UILabel!
    @IBOutlet weak var searchBar: UISearchBar!
    var searchTerm = ""
    
    private let refreshControl = UIRefreshControl()
    
    private let bottomeRefresher = UIRefreshControl()
    
    var invStatus:InvoiceStatus!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        invoicesVC = self
        
        allInvoicesFlag = true
        searchBar.text = ""
        searchBar.resignFirstResponder()
        
        tableView.tableFooterView = UIView(frame: .zero)
        
        //for invoices type picker
        pickerTextField.isHidden = true
        view.addSubview(pickerTextField)
        
        
        refreshControl.tintColor = #colorLiteral(red: 0.01960784314, green: 0.4196078431, blue: 0.6117647059, alpha: 1)
        refreshControl.addTarget(self, action: #selector(loadInitialInvoices), for: .valueChanged)
        
        bottomeRefresher.tintColor = #colorLiteral(red: 0.01960784314, green: 0.4196078431, blue: 0.6117647059, alpha: 1)
        bottomeRefresher.triggerVerticalOffset = 100;
        bottomeRefresher.addTarget(self, action: #selector(loadInvoices), for: .valueChanged)
        tableView.bottomRefreshControl = bottomeRefresher
        
        
        // Add Refresh Control to Table View
        if #available(iOS 10.0, *) {
            tableView.refreshControl = refreshControl
        } else {
            tableView.addSubview(refreshControl)
        }
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        DispatchQueue.main.async
        {
            if !Reachability.isReachable
            {
                homeVC.syncAllData()
            }
            self.refreshSource()
        }
        
        searchBar.placeholder = languageBundle!.localizedString(forKey: "Search Invoices", value: "", table: nil)
        createPickerView(textField: pickerTextField)
    }
    
    @objc func loadInvoices()
    {
        InvoicesManager.shared.getInvoices(offset: paidOffset,forceRefresh: true, status: .paid, completionHandler: {[weak self] (invoices, error) in
            if self?.tableViewDatasource == nil {
                self?.hideActivityIndicator()
            }
            if let error = error {
                loggingPrint(error)
            }else if let invoices = invoices {
//                invoicesPaid = invoices
                
                for invoice in invoices
                {
                    if invoicesPaid.contains(where: { (paidInvoice) -> Bool in
                        return paidInvoice.invoice.pos_invoice_no == invoice.invoice.pos_invoice_no
                    }) {
                        
                        let index = invoicesPaid.index(where: { (paidInvoice) -> Bool in
                            return paidInvoice.invoice.pos_invoice_no == invoice.invoice.pos_invoice_no
                        })
                        invoicesPaid[index!] = invoice
                        
                    }else {
                        invoicesPaid.append(invoice)
                    }
                }
                
                if invoices.count > 0
                {
                    self?.refreshSource()
                    paidOffset += 10
                }
                self?.bottomeRefresher.endRefreshing()
            }
        })
        
        InvoicesManager.shared.getInvoices(offset: unpaidOffset,forceRefresh: true, status: .unpaid) {[weak self] (invoices, error) in
            if self?.tableViewDatasource == nil {
                self?.hideActivityIndicator()
            }
            if let error = error {
                loggingPrint(error)
            }
            else if let invoices = invoices
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
                        
                    }else {
                        invoicesUnPaid.append(invoice)
                    }
                }
                
                if invoices.count > 0
                {
                    self?.refreshSource()
                    unpaidOffset += 10
                }
            }
        }
        
        InvoicesManager.shared.getInvoices(offset: partiallyOffset,forceRefresh: true, status: .partiallyPaid) {[weak self] (invoices, error) in
            if self?.tableViewDatasource == nil {
                self?.hideActivityIndicator()
            }
            if let error = error {
                loggingPrint(error)
            }
            else if let invoices = invoices
            {
                for invoice in invoices
                {
                    if invoicesPartiallyPaid.contains(where: { (partiallyPaidInvoice) -> Bool in
                        return partiallyPaidInvoice.invoice.pos_invoice_no == invoice.invoice.pos_invoice_no
                    }) {
                        
                        let index = invoicesPartiallyPaid.index(where: { (partiallyPaidInvoice) -> Bool in
                            return partiallyPaidInvoice.invoice.pos_invoice_no == invoice.invoice.pos_invoice_no
                        })
                        invoicesPartiallyPaid[index!] = invoice
                        
                    }else {
                        invoicesPartiallyPaid.append(invoice)
                    }
                }
                
                if invoices.count > 0
                {
                    self?.refreshSource()
                    partiallyOffset += 10
                }
            }
        }
    }
    
    @objc func loadInitialInvoices()
    {
        paidOffset = 0
        unpaidOffset = 0
        InvoicesManager.shared.getInvoices(offset: paidOffset,forceRefresh: true, status: .paid, completionHandler: {[weak self] (invoices, error) in
            if self?.tableViewDatasource == nil {
                self?.hideActivityIndicator()
            }
            if let error = error {
                loggingPrint(error)
            }else if let invoices = invoices {
                
                for invoice in invoices
                {
                    if invoicesPaid.contains(where: { (paidInvoice) -> Bool in
                        return paidInvoice.invoice.pos_invoice_no == invoice.invoice.pos_invoice_no
                    }) {
                        
                        let index = invoicesPaid.index(where: { (paidInvoice) -> Bool in
                            return paidInvoice.invoice.pos_invoice_no == invoice.invoice.pos_invoice_no
                        })
                        invoicesPaid[index!] = invoice
                        
                    }else {
                        invoicesPaid.append(invoice)
                    }
                }
                
                self?.refreshSource()
                self?.refreshControl.endRefreshing()
            }
        })
        
        InvoicesManager.shared.getInvoices(offset: unpaidOffset,forceRefresh: true, status: .unpaid) {[weak self] (invoices, error) in
            if self?.tableViewDatasource == nil {
                self?.hideActivityIndicator()
            }
            if let error = error {
                loggingPrint(error)
            }else if let invoices = invoices {
                
                for invoice in invoices
                {
                    if invoicesUnPaid.contains(where: { (unpaidInvoice) -> Bool in
                        return unpaidInvoice.invoice.pos_invoice_no == invoice.invoice.pos_invoice_no
                    }) {

                        let index = invoicesUnPaid.index(where: { (unpaidInvoice) -> Bool in
                            return unpaidInvoice.invoice.pos_invoice_no == invoice.invoice.pos_invoice_no
                        })
                        invoicesUnPaid[index!] = invoice

                    }else {
                        invoicesUnPaid.append(invoice)
                    }
                }
                
                self?.refreshSource()
            }
        }
        
        InvoicesManager.shared.getInvoices(offset: partiallyOffset,forceRefresh: true, status: .partiallyPaid) {[weak self] (invoices, error) in
            if self?.tableViewDatasource == nil {
                self?.hideActivityIndicator()
            }
            if let error = error {
                loggingPrint(error)
            }else if let invoices = invoices {
                
                for invoice in invoices
                {
                    if invoicesPartiallyPaid.contains(where: { (partiallyPaidInvoice) -> Bool in
                        return partiallyPaidInvoice.invoice.pos_invoice_no == invoice.invoice.pos_invoice_no
                    }) {
                        
                        let index = invoicesPartiallyPaid.index(where: { (partiallyPaidInvoice) -> Bool in
                            return partiallyPaidInvoice.invoice.pos_invoice_no == invoice.invoice.pos_invoice_no
                        })
                        invoicesPartiallyPaid[index!] = invoice
                        
                    }else {
                        invoicesPartiallyPaid.append(invoice)
                    }
                }
                
                self?.refreshSource()
            }
        }
    }
    
    @IBAction func selectInvoiceType(_ sender: UIButton)
    {
        filterFlag = 1
        pickerTextField.becomeFirstResponder()
    }
    
    @IBAction func filterBtnAction(_ sender: UIButton)
    {
        filterFlag = 2
        pickerTextField.becomeFirstResponder()
    }
    
    @IBAction func searchTapped(_ sender: UIButton)
    {
        searchBar.becomeFirstResponder()
    }
    
    func refreshSource()
    {
        DispatchQueue.main.async
        {
            if self.lblInvoice.text == self.componentList[0]
            {
                self.lblInvoiceTitle.text = languageBundle!.localizedString(forKey: self.componentList[0], value: "", table: nil)
                invoicesUnPaid = invoicesUnPaid.sorted(by: {
                    let date1 = Formatter.serverDateTime.date(from: $0.invoice.created_at!)!
                    let date2 = Formatter.serverDateTime.date(from: $1.invoice.created_at!)!
                    return date1.compare(date2) == .orderedDescending
                })
                
                self.tableViewDatasource = invoicesUnPaid
                self.invStatus = .unpaid
            }
            else if self.lblInvoice.text == self.componentList[1]
            {
                self.lblInvoiceTitle.text = languageBundle!.localizedString(forKey: self.componentList[1], value: "", table: nil)
                invoicesPartiallyPaid = invoicesPartiallyPaid.sorted(by: {
                    let date1 = Formatter.serverDateTime.date(from: $0.invoice.created_at!)!
                    let date2 = Formatter.serverDateTime.date(from: $1.invoice.created_at!)!
                    return date1.compare(date2) == .orderedDescending
                })
                
                self.tableViewDatasource = invoicesPartiallyPaid
                self.invStatus = .partiallyPaid
            }
            else
            {
                self.lblInvoiceTitle.text = languageBundle!.localizedString(forKey: self.componentList[2], value: "", table: nil)
                invoicesPaid = invoicesPaid.sorted(by: {
                    let date1 = Formatter.serverDateTime.date(from: $0.invoice.created_at!)!
                    let date2 = Formatter.serverDateTime.date(from: $1.invoice.created_at!)!
                    return date1.compare(date2) == .orderedDescending
                })
                
                self.tableViewDatasource = invoicesPaid
                self.invStatus = .paid
            }
            
            self.filterDatasource()
        }
    }
    
    func filterDatasource() {
//        if searchTerm.isEmpty {
//
//        }else {
//            tableViewDatasource = tableViewDatasource.filter { (invoice) -> Bool in
//                let customerName = invoice.customer_detail.contact_name ?? ""
//                let customerNumber = invoice.customer_detail.primary_contact_number ?? ""
//                let invoiceNo = invoice.invoice.pos_invoice_no ?? ""
//
//                return customerName.capitalized.contains(searchTerm.capitalized)
//                || customerNumber.capitalized.contains(searchTerm.capitalized)
//                || invoiceNo.capitalized.contains(searchTerm.capitalized)
//            }
//        }
//
//        DispatchQueue.main.async {
//            self.tableView.reloadData()
//        }
        
        if !searchTerm.isEmpty && searchTerm != "All"
        {
            
            tableViewDatasource = tableViewDatasource.filter { (invoice) -> Bool in
                
                var flag = false
                
                let invoiceNo = invoice.invoice.pos_invoice_no ?? ""
                let name = invoice.customer_detail.contact_name ?? ""
                let number = invoice.customer_detail.primary_contact_number ?? ""
                let sync = "Synchronized"
                let unsync = "Unsynchronized"
                
                if let _ = invoiceNo.range(of: searchTerm, options: .caseInsensitive)
                {
                    flag = true
                }
                else if let _ = name.range(of: searchTerm, options: .caseInsensitive)
                {
                    flag = true
                }
                else if let _ = number.range(of: searchTerm, options: .caseInsensitive)
                {
                    flag = true
                }
                else if let _ = sync.range(of: searchTerm, options: .caseInsensitive)
                {
                    self.lblFilterTitle.text = languageBundle!.localizedString(forKey: "Synchronized", value: "", table: nil)
                    if invoice.invoice.updated_at != nil && !(invoice.invoice.updated_at!.isEmpty)
                    {
                        flag = true
                    }
                }
                else if let _ = unsync.range(of: searchTerm, options: .caseInsensitive)
                {
                    self.lblFilterTitle.text = languageBundle!.localizedString(forKey: "Unsynchronized", value: "", table: nil)
                    if invoice.invoice.updated_at == nil || invoice.invoice.updated_at!.isEmpty
                    {
                        flag = true
                    }
                }
                
                return flag
            }
        }
        else
        {
            self.lblFilterTitle.text = languageBundle!.localizedString(forKey: "All", value: "", table: nil)
            if self.lblInvoice.text == self.componentList[0]
            {
                tableViewDatasource = invoicesUnPaid
                invStatus = .unpaid
            }
            else if self.lblInvoice.text == self.componentList[1]
            {
                tableViewDatasource = invoicesPartiallyPaid
                invStatus = .partiallyPaid
            }
            else
            {
                tableViewDatasource = invoicesPaid
                invStatus = .paid
            }
        }
    
        DispatchQueue.main.async
        {
            self.tableView.reloadData()
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let details = segue.destination as? InvoiceDetailsViewController {
            if let selectedIndexPath = tableView.indexPathForSelectedRow {
                details.invoice = tableViewDatasource[selectedIndexPath.row]
                details.taxes = allTaxes
            }
        }
    }
    
    func searchBarIsEmpty() -> Bool {
        // Returns true if the text is empty or nil
        return searchBar.text?.isEmpty ?? true
    }
    
    @objc func donePicker()
    {
        pickerTextField.resignFirstResponder()
        allInvoicesFlag = true
    }
    
    func createPickerView(textField: UITextField) {
        let picker: UIPickerView
        picker = UIPickerView()
        picker.backgroundColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
        
        picker.showsSelectionIndicator = true
        picker.delegate = self
        picker.dataSource = self
        
        let toolBar = UIToolbar()
        toolBar.barStyle = .default
        toolBar.isOpaque = true
        toolBar.isTranslucent = true
        toolBar.backgroundColor = UIColor.darkGray
        toolBar.tintColor = #colorLiteral(red: 0.01960784314, green: 0.4196078431, blue: 0.6117647059, alpha: 1)
        toolBar.sizeToFit()
        
        let doneButton = UIBarButtonItem(title: languageBundle!.localizedString(forKey: "Done", value: "", table: nil), style: UIBarButtonItemStyle.plain, target: self, action: #selector(donePicker))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        
        toolBar.setItems([spaceButton, doneButton], animated: false)
        toolBar.isUserInteractionEnabled = true
        
        textField.inputView = picker
        textField.inputAccessoryView = toolBar
        pickerView = picker
    }
}

extension InvoicesViewController: UIPickerViewDelegate
{
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
    {
        if filterFlag == 1
        {
            DispatchQueue.main.async {
                self.lblInvoice.text = self.componentList[row]
            }
            
            if row == 0
            {
                invStatus = .unpaid
            }
            else if row == 1
            {
                invStatus = .partiallyPaid
            }
            else
            {
                invStatus = .paid
            }
//            searchTerm = "All"
            paidOffset = 0
            
        }
        else
        {
            searchTerm = self.filterList[row]
            DispatchQueue.main.async {
                self.lblFilter.text = self.searchTerm
            }
        }
        
        refreshSource()
    }
}

extension InvoicesViewController: UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int
    {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int
    {
        return 3
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String?
    {
        if filterFlag == 1
        {
            return languageBundle!.localizedString(forKey: componentList[row], value: "", table: nil)
        }
        else
        {
            return languageBundle!.localizedString(forKey: filterList[row], value: "", table: nil)
        }
    }
}

extension InvoicesViewController: UITableViewDataSource
{
    func numberOfSections(in tableView: UITableView) -> Int
    {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        let count = tableViewDatasource == nil ? 0 : tableViewDatasource.count
        if count == 0
        {
            tableView.setEmptyMessage(languageBundle!.localizedString(forKey: "There is nothing here.", value: "", table: nil))
        }
        else
        {
            tableView.clearMessage()
        }
        return count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as? InvoicesTableViewCell
        else
        {
            return UITableViewCell()
        }
//        print(tableViewDatasource.count)
        let invoice = tableViewDatasource[indexPath.row]
        
        if let pos = invoice.invoice.pos_invoice_no {
            cell.title.text = pos
        }
        
        if let name = invoice.customer_detail.contact_name {
            cell.subTitle.text = name
        }
        
        if  invoice.invoice.updated_at != nil && !(invoice.invoice.updated_at!.isEmpty)
        {
            cell.upload.image = UIImage(named: "upload-select")
            cell.lblSync.text = languageBundle!.localizedString(forKey: "Synchronized", value: "", table: nil)
        }
        else
        {
            cell.upload.image = UIImage(named: "upload-unselect")
            cell.lblSync.text = languageBundle!.localizedString(forKey: "Unsynchronized", value: "", table: nil)
        }
        
        if let date = invoice.invoice.created_at  , let serverDate = Formatter.serverDateTime.date(from: date){
            cell.date.text = Formatter.displayDateTime.string(from: serverDate)
        }
        
        if lblInvoice.text == "Unpaid Invoices" || lblInvoice.text == "Partially Paid Invoices"
        {
            if let amount = invoice.invoice.due_amount {
                cell.amount.text = "\(amount)\(UserDefaults.standard.string(forKey: UserDefaults.Key.orgCurrencySymbol) ?? "")"
            }
        }
        else
        {
            if let amount = invoice.invoice.paid_amount {
                cell.amount.text = "\(amount)\(UserDefaults.standard.string(forKey: UserDefaults.Key.orgCurrencySymbol) ?? "")"
            }
        }
        
        return cell
    }
}

extension InvoicesViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        
    }
}

extension InvoicesViewController: UISearchBarDelegate {
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = true
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String)
    {
//        let numberFormatter = NumberFormatter()
//        numberFormatter.locale = Locale(identifier: "EN")
//        let finalText = Int(truncating: numberFormatter.number(from:searchText) ?? 0)
//        searchTerm = String(finalText)
        
        if !Reachability.isReachable
        {
            searchTerm = searchText
            
            refreshSource()
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar)
    {
        if Reachability.isReachable
        {
            self.view.endEditing(true)
            if !searchBar.text!.isEmpty
            {
                self.showActivityIndicator()
                searchInvoices(text: searchBar.text!)
            }
        }
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar)
    {
        searchBar.resignFirstResponder()
//        refreshSource()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar)
    {
        allInvoicesFlag = true
        searchBar.resignFirstResponder()
        searchBar.text = ""
        searchTerm = ""
        refreshSource()
        searchBar.showsCancelButton = false
    }
    
    func searchInvoices(text: String)
    {
        InvoicesManager.shared.getInvoicesByPOSNumber(text: text,forceRefresh: true, status: invStatus) {[weak self] (invoices, error) in
            if self?.tableViewDatasource == nil {
                self?.hideActivityIndicator()
            }
            if let error = error {
                loggingPrint(error)
            }
            else if let invoices = invoices
            {
                if self!.invStatus == InvoiceStatus.unpaid
                {
                    if invoices.count > 0
                    {
                        invoicesUnPaid.removeAll()
                        
                        for invoice in invoices
                        {
                            if invoicesUnPaid.contains(where: { (unpaidInvoice) -> Bool in
                                return unpaidInvoice.invoice.id == invoice.invoice.id
                            }) {
                                
                                let index = invoicesUnPaid.index(where: { (unpaidInvoice) -> Bool in
                                    return unpaidInvoice.invoice.id == invoice.invoice.id
                                })
                                invoicesUnPaid[index!] = invoice
                                
                            }else {
                                invoicesUnPaid.append(invoice)
                            }
                        }
                    }
                }
                else if self!.invStatus == InvoiceStatus.partiallyPaid
                {
                    if invoices.count > 0
                    {
                        invoicesPartiallyPaid.removeAll()
                        
                        for invoice in invoices
                        {
                            if invoicesPartiallyPaid.contains(where: { (partiallypaidInvoice) -> Bool in
                                return partiallypaidInvoice.invoice.id == invoice.invoice.id
                            }) {
                                
                                let index = invoicesPartiallyPaid.index(where: { (partiallypaidInvoice) -> Bool in
                                    return partiallypaidInvoice.invoice.id == invoice.invoice.id
                                })
                                invoicesPartiallyPaid[index!] = invoice
                                
                            }else {
                                invoicesPartiallyPaid.append(invoice)
                            }
                        }
                    }
                }
                else
                {
                    if invoices.count > 0
                    {
                        invoicesPaid.removeAll()
                        
                        for invoice in invoices
                        {
                            if invoicesPaid.contains(where: { (paidInvoice) -> Bool in
                                return paidInvoice.invoice.id == invoice.invoice.id
                            }) {
                                
                                let index = invoicesPaid.index(where: { (paidInvoice) -> Bool in
                                    return paidInvoice.invoice.id == invoice.invoice.id
                                })
                                invoicesPaid[index!] = invoice
                                
                            }else {
                                invoicesPaid.append(invoice)
                            }
                        }
                    }
                }
                allInvoicesFlag = false
                self?.refreshSource()
                self?.searchBar.text = ""
            }
        }
    }
}
