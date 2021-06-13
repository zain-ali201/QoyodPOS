//
//  PinViewController.swift
//  Qoyod point of sale
//
//  Created by Sharjeel Ahmad on 02/09/2018.
//  Copyright © 2018 Sharjeel Ahmad. All rights reserved.
//

import UIKit
import JVFloatLabeledTextField

class PinViewController: UIViewController {
    @IBOutlet weak var btnBack: UIButton!
    @IBOutlet weak var labelBack: UILabel!
    @IBOutlet weak var btnlogout: UIButton!
    
    @IBOutlet weak var lblMain: UILabel!
    @IBOutlet weak var lblCode: UILabel!
    @IBOutlet weak var btnReset: UIButton!
    @IBOutlet weak var btnConfirm: UIButton!
    
    lazy private var organizations:[Organization] = []
    @IBOutlet weak var pinTextfield: JVFloatLabeledTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        #if DEBUG
        pinTextfield.text = "1234"
//        pinTextfield.text = "1111"
        #endif
        
        pinTextfield.addTarget(self, action: #selector(textFieldDidChange(sender:)), for: .editingChanged)
        
        lblMain.text = languageBundle!.localizedString(forKey: "Enter Pin Code", value: "", table: nil)
        pinTextfield.placeholder = languageBundle!.localizedString(forKey: "Pin Code", value: "", table: nil)
        btnlogout.setTitle(languageBundle!.localizedString(forKey: "Logout", value: "", table: nil), for: .normal)
        btnReset.setTitle(languageBundle!.localizedString(forKey: "Reset pin code", value: "", table: nil), for: .normal)
        btnConfirm.setTitle(languageBundle!.localizedString(forKey: "Confirm", value: "", table: nil), for: .normal)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //open keyboard
//        pinTextfield.becomeFirstResponder()
    }
    
    @objc func textFieldDidChange(sender: UITextField)
    {
        if let code = pinTextfield.text, let pin = Int(code)
        {
            print(UserDefaults.standard.integer(forKey: UserDefaults.Key.pinCode))
            if pin == UserDefaults.standard.integer(forKey: UserDefaults.Key.pinCode)
            {
                sendRequest()
            }
        }
    }
    
    @IBAction func logOutTapped(_ sender: UIButton)
    {
        if timer != nil
        {
            timer.invalidate()
        }
        self.hideActivityIndicator()
        let alert = UIAlertController(title: "" , message: languageBundle!.localizedString(forKey:"Do you want to sync unsynced invoices?", value: "", table: nil), preferredStyle: UIAlertControllerStyle.alert)
        
        //add actions
        alert.addAction(UIAlertAction(title: languageBundle!.localizedString(forKey: "YES" , value: "", table: nil), style: .default, handler: { action in
            
            self.showActivityIndicator()
            InvoicesManager.shared.postPendingNewInvoices(completionHandler: { (error) in
                if let error = error
                {
                    self.hideActivityIndicator()
                    self.show(error: error)
                }else {
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
        
        //post pending data before logout.
        
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
    
    @IBAction func backTapped(_ sender: UIButton)
    {
      navigationController?.popViewController(animated: true)
    }
    
    @IBAction func resetCodeAction(_ sender: UIButton)
    {
        let alert = UIAlertController(title: languageBundle!.localizedString(forKey:"Pin Code" , value: "", table: nil), message:languageBundle!.localizedString(forKey: "You can reset pin code.", value: "", table: nil), preferredStyle: UIAlertControllerStyle.alert)

        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { action in
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func confirmTapped(_ sender: UIButton)
    {
        sendRequest()
    }
    
    func sendRequest()
    {
        if let code = pinTextfield.text, let pin = Int(code)
        {
            print(UserDefaults.standard.integer(forKey: UserDefaults.Key.pinCode))
            if pin == UserDefaults.standard.integer(forKey: UserDefaults.Key.pinCode)
            { //if enteted correct pin
                if UserDefaults.standard.bool(forKey: UserDefaults.Key.isLoggedIn)
                {
                    //unlock the app
                    dismiss(animated: true) {
                        UserDefaults.standard.set(false, forKey: UserDefaults.Key.isLocked)
                        UserDefaults.standard.synchronize()
                        self.showMessage("\(languageBundle!.localizedString(forKey: "Welcome back", value: "", table: nil)) \(UserDefaults.standard.string(forKey: UserDefaults.Key.orgName) ?? "")")
                    }
                }
                else
                {
//                    sender.isEnabled = false
                    showActivityIndicator(tint: .textColorPrimary)
                    OrganizationManager.shared.getOrganizations {[weak self] (data, error) in
                        self?.hideActivityIndicator()
//                        sender.isEnabled = true
                        if let error = error{
                            self?.show(error: error)
                        }else {
                            if let data = data {
                                if let message = data as? String {
                                    UserDefaults.standard.set(true, forKey: UserDefaults.Key.isLoggedIn)
                                    UserDefaults.standard.synchronize()
                                    
                                    //proceed to home
                                    self?.gotoHome(with: message)
                                }else if let orgs = data as? [Organization] {
                                    self?.organizations = orgs
                                    self?.performSegue(withIdentifier: "organization", sender: nil)
                                }
                            }
                        }
                    }
                }
            }
            else {
                pinTextfield.resignFirstResponder()
                showMessage(languageBundle!.localizedString(forKey: "Wrong pin", value: "", table: nil))
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let org = segue.destination as? OrganizationViewController {
            org.organizations = organizations
        }
    }
    
    // MARK: - Private methods
    private func gotoHome(with message:String?) {
        let vc:UITabBarController = UIStoryboard.main.instantiateViewController(withIdentifier: "Home") as! UITabBarController
        vc.selectedIndex = 1
        rootVC = vc
        present(vc, animated: true, completion: {
            //show mesage
            if let message = message {
                vc.showMessage(message)
            }
        })
    }
}

extension PinViewController: UITextFieldDelegate
{
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        if textField == pinTextfield
        {
            confirmTapped(UIButton())
            textField.resignFirstResponder()
        }
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return true
    }
}
