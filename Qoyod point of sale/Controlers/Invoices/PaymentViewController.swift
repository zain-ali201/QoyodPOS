//
//  PaymentViewController.swift
//  Qoyod point of sale
//
//  Created by Sharjeel Ahmad on 05/09/2018.
//  Copyright © 2018 Sharjeel Ahmad. All rights reserved.
//

import UIKit
import DLRadioButton

class PaymentTableViewCell: UITableViewCell
{
    @IBOutlet weak var txtAmount: UITextField!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var btnExpand: UIButton!
    var accountID = 0
}

class SelectedAccount: NSObject
{
    var contactID: Int = 0
    var accountID: Int = 0
    var currentDate: String = ""
    var amount: String = ""
}

class PaymentViewController: UIViewController, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource
{
    @IBOutlet weak var lblMain: UILabel!
    @IBOutlet weak var lblTotalTitle: UILabel!
    @IBOutlet weak var lblRemainingTitle: UILabel!
    @IBOutlet weak var lblChangeTitle: UILabel!
    @IBOutlet weak var lblTotal: UILabel!
    @IBOutlet weak var lblRemaining: UILabel!
    @IBOutlet weak var lblChange: UILabel!
    @IBOutlet weak var tblView: UITableView!
    @IBOutlet weak var btnCancel: UIButton!
    @IBOutlet weak var btnConfirm: UIButton!
    
    var starIoExtManager: StarIoExtManager!
    
    var accounts:[Account] = []
    var invoice:Invoice!
    var mainView:UIView!
    
    var paymentSuccessVC: PaymentConfirmationViewController!
    var paymentSuccessView: UIView!
    
    var currentAccount = 0
    var totalAmount = 0.0
    var dueAmount = 0.0
    var invoiceStatus:InvoiceStatus?
    
    var invoiceNo:String!
//    var selectedContact:Contact!
    var selectedProducts:[Product]!
    var selectedAccounts:[SelectedAccount] = []
    
    var firstTime = true
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self.starIoExtManager = StarIoExtManager(type: StarIoExtManagerType.standard,
                                                 portName: AppDelegate.getPortName(),
                                                 portSettings: AppDelegate.getPortSettings(),
                                                 ioTimeoutMillis: 10000)
        
        lblMain.text = languageBundle!.localizedString(forKey: "Choose a payment method", value: "", table: nil)
        lblTotalTitle.text = languageBundle!.localizedString(forKey: "Total", value: "", table: nil)
        lblRemainingTitle.text = languageBundle!.localizedString(forKey: "Remaining", value: "", table: nil)
        lblChangeTitle.text = languageBundle!.localizedString(forKey: "Change", value: "", table: nil)
        
        btnCancel.setTitle(languageBundle!.localizedString(forKey: "CANCEL", value: "", table: nil), for: .normal)
        btnConfirm.setTitle(languageBundle!.localizedString(forKey: "CONFIRM", value: "", table: nil), for: .normal)
        
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        tblView.reloadData()
    }
    
    func calculatePaidAmount()-> Double
    {
        let cells = tblView.visibleCells as! [PaymentTableViewCell]
        
        var paidPrice = 0.0
        
        for cell in cells
        {
            let priceStr = cell.txtAmount.text ?? ""
            
            if !priceStr.isEmpty && !priceStr.hasPrefix(".")
            {
                let price = Double(priceStr)!
                
                if price > 0
                {
                    paidPrice += price
                }
            }
        }
        
        return paidPrice
    }
    
    func verifyPaidPrice()-> Bool
    {
        let paidPrice = calculatePaidAmount()
        
        if paidPrice >= totalAmount
        {
            return false
        }
        else
        {
            return true
        }
    }
    
    func updateChangeAmount()
    {
        let paidPrice = calculatePaidAmount()
        print(paidPrice)
        
        if paidPrice > totalAmount
        {
            lblChange.text = String(format: "%.2f", paidPrice - dueAmount)
            lblRemaining.text = "0"
        }
        else if paidPrice < totalAmount
        {
            lblRemaining.text = String(format: "%.2f", dueAmount - paidPrice)
            lblChange.text = "0"
        }
        else
        {
            lblChange.text = "0"
            lblRemaining.text = "0"
        }
    }
    
    @IBAction func doneTapped(_ sender: UIButton)
    {
        if self.starIoExtManager.connect() == false
        {
            self.starIoExtManager.disconnect()
            let alert = UIAlertController(title: languageBundle!.localizedString(forKey: "No Printer Connected", value: "", table: nil), message: languageBundle!.localizedString(forKey: "Do you want to continue without a printer connected?", value: "", table: nil), preferredStyle: UIAlertControllerStyle.alert)
            
            //add actions
            alert.addAction(UIAlertAction(title: languageBundle!.localizedString(forKey: "Pay Later", value: "", table: nil), style: .default, handler: { action in
                
                self.payInvoice(sender, flag: false)
            }))
            
            alert.addAction(UIAlertAction(title: languageBundle!.localizedString(forKey: "Continue", value: "", table: nil), style: .default, handler: { action in
                self.payInvoice(sender, flag: true)
            }))
            
            alert.addAction(UIAlertAction(title: languageBundle!.localizedString(forKey: "Cancel", value: "", table: nil), style: .cancel, handler: { action in
                
            }))
            
            //present the dialog
            self.present(alert, animated: true, completion: nil)
        }
        else
        {
            self.starIoExtManager.disconnect()
            payInvoice(sender, flag: true)
        }
    }
    
    func payInvoice(_ sender: UIButton, flag: Bool)
    {
        self.view.endEditing(true)
        sender.isUserInteractionEnabled = false
        
        let cells = tblView.visibleCells as! [PaymentTableViewCell]
        
        for cell in cells
        {
            let priceStr = cell.txtAmount.text ?? ""
            
            if priceStr.hasPrefix(".")
            {
                self.view.makeToast(languageBundle!.localizedString(forKey: "Please enter a valid amount", value: "", table: nil))
                sender.isUserInteractionEnabled = true
                return
            }
            else if !priceStr.isEmpty
            {
                var price = Double(priceStr)!
                
                if price > 0
                {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd"
                    
                    accountStr = accountStr + "\(cell.name.text ?? ""): \(priceStr),"
                    paidAmount += price
                    receiptCount += 1
                    
                    let difference = paidAmount - totalAmount
                    
                    if difference > 0
                    {
                        price = price - difference
                    }
                    
                    let account = SelectedAccount()
                    account.accountID = cell.accountID
                    print(account.accountID)
//                    account.contactID = selectedContact.id
                    account.amount = String(format: "%.2f", price)
                    account.currentDate = formatter.string(from: Date())
                    selectedAccounts.append(account)
                }
            }
        }
        
        print(accountStr)
        showActivityIndicator()
        
        if !flag
        {
            paidAmount = 0
        }
        
        if paidAmount > 0
        {
            if paidAmount > totalAmount
            {
                changeAmount = paidAmount - totalAmount
            }
            
            paymentSuccessVC.lblPaid.text = String(format: "\(languageBundle!.localizedString(forKey: "Paid", value: "", table: nil)): %.2f", paidAmount)
            paymentSuccessVC.lblChange.text = String(format: "\(languageBundle!.localizedString(forKey: "Change", value: "", table: nil)): %.2f", changeAmount)
            
            if var status = invoiceStatus
            {
//                var amount = paidAmount
//
//                if dueAmount > 0
//                {
//                    amount = dueAmount + paidAmount
//                }
                
                if paidAmount < dueAmount
                {
                    status = .partiallyPaid
                    invoiceStatus = .partiallyPaid
                    paymentSuccessVC.invStatus = 1
                }
                else
                {
                    status = .paid
                    invoiceStatus = .paid
                    paymentSuccessVC.invStatus = 2
                }
                
                InvoicesManager.shared.createInvoiceWithStatus(invoiceNo: invoiceNo, contact: selectedContact, products: selectedProducts, status: status, totalAmount:  "\(totalAmount)", totalPaidAmount:  "\(paidAmount)", accounts: selectedAccounts) {[weak self] (message, error) in
                    self?.hideActivityIndicator()
                    sender.isUserInteractionEnabled = true
                    if let error = error {
                        self?.show(error: error)
                    }else if let message = message {
                        self?.showMessage(message)
                        self?.showConfirmation()
                        UserDefaults.standard.set(selectedContact.id, forKey: "SelectedContact")
                    }
                }
            }
            else
            {
                paymentSuccessVC.invStatus = 2
                print(totalAmount)
                print(accounts[currentAccount].id)
                
                InvoicesManager.shared.createInvoiceApproved(invoice: invoice, totalAmount: "\(totalAmount)" , accountId: accounts[currentAccount].id) {[weak self] (message, error) in
                    self?.hideActivityIndicator()
                    sender.isUserInteractionEnabled = true
                    if let error = error {
                        self?.show(error: error)
                    }else if let message = message {
                        self?.showMessage(message)
                        self?.showConfirmation()
                    }
                }
            }
        }
        else
        {
            sender.isUserInteractionEnabled = false
            InvoicesManager.shared.createInvoiceWithStatus(invoiceNo: invoiceNo, contact: selectedContact, products: selectedProducts, status: .unpaid, totalAmount: "\(totalAmount)", totalPaidAmount:  "\(paidAmount)", accounts: []) {[weak self] (message, error) in
                self?.hideActivityIndicator()
                sender.isUserInteractionEnabled = true
                if let error = error {
                    self?.show(error: error)
                }else if let message = message {
                    self?.showMessage(message)
                    //reset selection
                    
                    self?.selectedProducts.removeAll()

                    NotificationCenter.default.post(name: Notification.Name.resetSelection, object: nil)
                    NotificationCenter.default.post(name: Notification.Name.syncData, object: nil)
                    
                    //switch to invoices
                    if let invoicesNav = self?.tabBarController?.viewControllers?.first as? StyledNavigationController {
                        if let invoiceVC = invoicesNav.viewControllers.first as? InvoicesViewController {
                            invoiceVC.pickerView(UIPickerView(), didSelectRow: 0, inComponent: 0)
                            invoiceVC.pickerView.selectRow(0, inComponent: 0, animated: false)
                        }
                    }
                    
                    self?.tabBarController?.selectedIndex = 0
                    self?.navigationController?.popViewController(animated: false)
                }
            }
        }
    }
    
    func showConfirmation()
    {
        UIView.animate(withDuration: 0.2, delay: 0, options: [], animations: {
            self.mainView.alpha = 0 // Here you will get the animation you want
        }, completion: { _ in
            self.mainView.isHidden = true // Here you hide it when animation done
            
            self.paymentSuccessView.alpha = 0
            UIView.animate(withDuration: 0.2, delay: 0.2, options: [.curveEaseIn], animations: {
                self.paymentSuccessView.alpha = 1 // Here you will get the animation you want
            }, completion: { _ in
                self.paymentSuccessView.isHidden = false // Here you hide it when animation done
            })
        })
    }
    
    @IBAction func cancelTapped(_ sender: UIButton)
    {
        self.view.endEditing(true)
        firstTime = true
        UIView.animate(withDuration: 0.2, delay: 0, options: [], animations: {
            self.mainView.alpha = 0 // Here you will get the animation you want
        }, completion: { _ in
            self.mainView.isHidden = true // Here you hide it when animation done
        })
    }
    
    @IBAction func accountChange(_ sender: DLRadioButton)
    {
        currentAccount = sender.tag
        tblView.reloadData()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int
    {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return accounts.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        let cell = tableView.cellForRow(at: indexPath) as? PaymentTableViewCell
        
        if cell?.btnExpand.tag == 1
        {
            cell?.txtAmount.becomeFirstResponder()
            return 85
        }
        else if indexPath.row == 0 && firstTime
        {
            firstTime = false
            return 85
        }
        else
        {
            return 40
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as? PaymentTableViewCell
        {
            if indexPath.row == 0 && firstTime
            {
                cell.txtAmount.becomeFirstResponder()
                cell.btnExpand.setTitle("-", for: .normal)
            }
            
            cell.accountID = accounts[indexPath.row].id
            cell.name.text = accounts[indexPath.row].name
            cell.txtAmount.tag = indexPath.row
            cell.txtAmount.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
            cell.btnExpand.addTarget(self, action: #selector(expandBtnAction(button:)), for: .touchUpInside)
            cell.btnExpand.tag = indexPath.row + 1000
            return cell
        }
        return UITableViewCell()
    }

    @IBAction func expandBtnAction(button: UIButton)
    {
        let cell = tblView.cellForRow(at: IndexPath.init(item: button.tag - 1000, section: 0)) as? PaymentTableViewCell
        
        if verifyPaidPrice()
        {
            if button.tag == 1
            {
                button.tag = 0
                button.setTitle("+", for: .normal)
//                cell?.txtAmount.text = ""
            }
            else
            {
                button.tag = 1
                button.setTitle("-", for: .normal)
                
                if cell?.txtAmount.text != nil && (cell?.txtAmount.text!.isEmpty)!
                {
                    cell?.txtAmount.text = lblRemaining.text
                }
//                lblRemaining.text = "0"
            }
            
            tblView.beginUpdates()
            tblView.endUpdates()
        }
        else
        {
            let windowCount = UIApplication.shared.windows.count
            UIApplication.shared.windows[windowCount-1].makeToast(languageBundle!.localizedString(forKey: "You have already entered your billed amount.", value: "", table: nil))
        }
    }
    
    @objc func textFieldDidChange(_ textField: UITextField)
    {
        updateChangeAmount()
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField)
    {
        addToolBar(textField: textField)
    }
    
    func addToolBar(textField: UITextField)
    {
        let toolBar = UIToolbar()
        toolBar.barStyle = UIBarStyle.default
        toolBar.isTranslucent = true
        toolBar.tintColor = UIColor(red: 42/255, green: 113/255, blue: 158/255, alpha: 1)
        let doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.plain, target: self, action: #selector(doneBtnAction(button:)))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        toolBar.setItems([spaceButton, doneButton], animated: false)
        toolBar.isUserInteractionEnabled = true
        toolBar.sizeToFit()
        textField.delegate = self
        textField.inputAccessoryView = toolBar
    }
    
    @IBAction func doneBtnAction(button: UIButton)
    {
        self.view.endEditing(true)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        self.view.endEditing(true)
    }
}
