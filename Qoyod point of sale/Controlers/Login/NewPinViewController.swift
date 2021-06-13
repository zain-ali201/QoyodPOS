//
//  NewPinViewController.swift
//  Qoyod point of sale
//
//  Created by Sharjeel Ahmad on 23/11/2018.
//  Copyright © 2018 Sharjeel Ahmad. All rights reserved.
//

import UIKit
import JVFloatLabeledTextField

class NewPinViewController: UIViewController {

    lazy private var organizations:[Organization] = []
    @IBOutlet weak var pinTextfield: JVFloatLabeledTextField!
    @IBOutlet weak var confirmPinTextfiled: JVFloatLabeledTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //open keyboard
        pinTextfield.becomeFirstResponder()
    }
    
    @IBAction func confirmTapped(_ sender: UIButton) {
        if let pinCode = pinTextfield.text, let confirmPinCode = confirmPinTextfiled.text {
            pinTextfield.resignFirstResponder()
            confirmPinTextfiled.resignFirstResponder()
            if pinCode.isEmpty || confirmPinCode.isEmpty || pinCode.count != 4 || Int(pinCode) ?? 0 == 0{
                showMessage(languageBundle!.localizedString(forKey: "Invalid pin", value: "", table: nil))
            } else if pinCode != confirmPinCode {
                showMessage(languageBundle!.localizedString(forKey: "Pin code doesn't match", value: "", table: nil))
            }else {
                sender.isEnabled = false
                showActivityIndicator(tint: .textColorPrimary)
                AuthManager.shared.setPinCode(pinCode: pinCode) {[weak self] (success, error) in
                    if success {
                        //get organizations
                        OrganizationManager.shared.getOrganizations {[weak self] (data, error) in
                            self?.hideActivityIndicator()
                            sender.isEnabled = true
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
                    }else if let error = error {
                        self?.show(error: error)
                    }else {
                        
                    }
                }
            }
        }else {
            pinTextfield.resignFirstResponder()
            confirmPinTextfiled.resignFirstResponder()
            showMessage(languageBundle!.localizedString(forKey: "Invalid pin", value: "", table: nil))
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

extension NewPinViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if textField == pinTextfield {
            confirmPinTextfiled.becomeFirstResponder()
        }
        
        if textField == confirmPinTextfiled {
            confirmTapped(UIButton())
            textField.resignFirstResponder()
        }
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let count = textField.text?.count , !string.isEmpty { //check if not delete
            return  count < 4
        }
        
        return true
    }
}
