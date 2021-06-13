//
//  SettingsViewController.swift
//  Qoyod point of sale
//
//  Created by Sharjeel Ahmad on 02/09/2018.
//  Copyright © 2018 Sharjeel Ahmad. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController
{
    @IBOutlet weak var orgNameLabel: UILabel!
    @IBOutlet weak var paidLabel: UILabel!
    @IBOutlet weak var unpaidLabel: UILabel!
    @IBOutlet weak var printerSwitch: UISwitch!
    @IBOutlet weak var segment: UISegmentedControl!
    
    @IBOutlet weak var logoutBtn: UIButton!
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var lblPaid: UILabel!
    @IBOutlet weak var lblUnpaid: UILabel!
    @IBOutlet weak var lblLanguage: UILabel!
    @IBOutlet weak var lblPrinter: UILabel!
    @IBOutlet weak var lblPrinterName: UILabel!
    @IBOutlet weak var lblNoPrinter: UILabel!
    
    @IBOutlet weak var btnPrinter: UIButton!
    
    var starIoExtManager: StarIoExtManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        orgNameLabel.text = UserDefaults.standard.string(forKey: UserDefaults.Key.orgName)
        self.starIoExtManager = StarIoExtManager(type: StarIoExtManagerType.standard,
                                                 portName: AppDelegate.getPortName(),
                                                 portSettings: AppDelegate.getPortSettings(),
                                                 ioTimeoutMillis: 10000)                             // 10000mS!!!
        
        
        if UserDefaults.standard.string(forKey: "language") == "ar"
        {
            segment.selectedSegmentIndex = 1
        }
        else
        {
            segment.selectedSegmentIndex = 0
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //chceck if printer is connected
        
        if AppDelegate.settingManager.settings[0] != nil
        {
            printerSwitch.setOn(true, animated: false)
        }
        else if AppDelegate.settingManager.settings[0] != nil
        {
            printerSwitch.setOn(true, animated: false)
        }
        
        
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        paidLabel.text = String(format: "%d", invoicesPaid.count)
        unpaidLabel.text = String(format: "%d", invoicesUnPaid.count)
        
        print("Printer: \(AppDelegate.getModelName())")
        lblPrinterName.text = AppDelegate.getModelName().isEmpty ? "No Printer" : AppDelegate.getModelName()
        
        changeText()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        GlobalQueueManager.shared.serialQueue.async {
            self.starIoExtManager.disconnect()
        }
    }
    
    @IBAction func connectPrinter(_ sender: UISwitch)
    {
        if sender.isOn
        {
            let alert = UIAlertController(title: "" , message: languageBundle!.localizedString(forKey: "Please select printer", value: "", table: nil), preferredStyle: UIAlertControllerStyle.alert)
            
            //add actions
            alert.addAction(UIAlertAction(title: languageBundle!.localizedString(forKey: "Star Printer", value: "", table: nil), style: .default, handler: { action in
                
                if let vc = UIStoryboard.starprinter.instantiateInitialViewController() {
                    self.present(vc, animated: true, completion: nil)
                }
            }))
            
            alert.addAction(UIAlertAction(title: languageBundle!.localizedString(forKey: "EPSON Printer" , value: "", table: nil), style: .default, handler: { action in
                
                if let vc = UIStoryboard.epson.instantiateInitialViewController() {
                    self.present(vc, animated: true, completion: nil)
                }
            }))
            
            alert.addAction(UIAlertAction(title: languageBundle!.localizedString(forKey: "Cancel" , value: "", table: nil), style: .cancel, handler: { action in
                sender.setOn(false, animated: true)
            }))
            
            present(alert, animated: true, completion: nil)
        }
        else
        {
            if self.starIoExtManager.disconnect()
            {
                lblPrinterName.text = "No Printer"
                AppDelegate.settingManager.settings = [nil, nil]
            }
            else
            {
                sender.setOn(true, animated: true)
            }
        }
    }
    
    @IBAction func connectBarcodeReader(_ sender: UISwitch) {
        if sender.isOn
        {
            if let vc = UIStoryboard.starprinter.instantiateInitialViewController() {
                present(vc, animated: true, completion: nil)
            }
        }
        else {
            if self.starIoExtManager.disconnect() {
                AppDelegate.settingManager.settings = [nil, nil]
            }else {
                sender.setOn(true, animated: true)
            }
        }
    }
    
    @IBAction func printersBtnAction(_ sender: Any)
    {
        let vc = UIStoryboard.main.instantiateViewController(withIdentifier: "PrintersListVC")
        present(vc, animated: true, completion: nil)
    }
    
    @IBAction func segmentBtnAction(_ sender: UISegmentedControl)
    {
        switch sender.selectedSegmentIndex
        {
        case 0:
            UserDefaults.standard.set("en", forKey: "language")
        case 1:
            UserDefaults.standard.set("ar", forKey: "language")
        default:
            break
        }
        
        language()
    }
    
    func language()
    {
        let languageCode = UserDefaults.standard
        if UserDefaults.standard.value(forKey: "language") != nil
        {
            let language = languageCode.string(forKey: "language")!
            if let path  = Bundle.main.path(forResource: language, ofType: "lproj") {
                languageBundle =  Bundle(path: path)
            }
            else{
                languageBundle = Bundle(path: Bundle.main.path(forResource: "en", ofType: "lproj")!)
            }
        }
        else {
            languageCode.set("en", forKey: "language")
            languageCode.synchronize()
            let language = languageCode.string(forKey: "language")!
            if let path  = Bundle.main.path(forResource: language, ofType: "lproj") {
                languageBundle =  Bundle(path: path)
            }
            else{
                languageBundle = Bundle(path: Bundle.main.path(forResource: "en", ofType: "lproj")!)
            }
        }
        
        changeText()
    }
    
    func changeText()
    {
        lblTitle.text = languageBundle!.localizedString(forKey: "Settings", value: "", table: nil)
        lblPaid.text = languageBundle!.localizedString(forKey: "Paid Invoices", value: "", table: nil)
        lblUnpaid.text = languageBundle!.localizedString(forKey: "Unpaid Invoices", value: "", table: nil)
        lblPrinter.text = languageBundle!.localizedString(forKey: "Printer", value: "", table: nil)
        lblLanguage.text = languageBundle!.localizedString(forKey: "Language", value: "", table: nil)
        lblNoPrinter.text = languageBundle!.localizedString(forKey: "No Printer", value: "", table: nil)
        logoutBtn.setTitle(languageBundle!.localizedString(forKey: "Logout", value: "", table: nil), for: .normal)
        btnPrinter.setTitle(languageBundle!.localizedString(forKey: "Printers", value: "", table: nil), for: .normal)
        rootVC?.viewControllers![0].title = languageBundle!.localizedString(forKey: "Invoices", value: "", table: nil)
        rootVC?.viewControllers![1].title = languageBundle!.localizedString(forKey: "New Invoice", value: "", table: nil)
        rootVC?.viewControllers![2].title = languageBundle!.localizedString(forKey: "Settings", value: "", table: nil)
    }
    
    @IBAction func logoutTapped(_ sender: UIButton)
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
        
        alert.addAction(UIAlertAction(title: languageBundle!.localizedString(forKey: "NO" , value: "", table: nil), style: .cancel, handler: { action in
            
            self.showActivityIndicator()
            AuthManager.shared.logout {[weak self] (success, error) in
                self?.hideActivityIndicator()
                if success
                {
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
        
//        showActivityIndicator()
//
//        //post pending data before logout.
//
//        CustomerManager.shared.postPendingNewCustomers { (error) in
//            if let error = error {
//                self.hideActivityIndicator()
//                self.show(error: error)
//            }else {
//                CustomerManager.shared.getContacts(completionHandler: { (contacts, error) in
//                    if let error = error {
//                        self.hideActivityIndicator()
//                        self.show(error: error)
//                    }else {
//                        InvoicesManager.shared.postPendingNewInvoices(completionHandler: { (error) in
//                            if let error = error {
//                                self.hideActivityIndicator()
//                                self.show(error: error)
//                            }else {
//                                InvoicesManager.shared.postPendingApprovedInvoices(completionHandler: { (error) in
//                                    if let error = error {
//                                        self.hideActivityIndicator()
//                                        self.show(error: error)
//                                    }else {
//                                        //finally logout
//                                        AuthManager.shared.logout {[weak self] (success, error) in
//                                            self?.hideActivityIndicator()
//                                            if success {
//                                                let controller = UIStoryboard.onboarding.instantiateViewController(withIdentifier: "Login")
//                                                self?.present(controller, animated: true, completion: nil)
//                                            }
//                                        }
//                                    }
//                                })
//                            }
//                        })
//                    }
//                })
//            }
//        }
    }
}
