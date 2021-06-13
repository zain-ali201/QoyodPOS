//
//  NewCustomerViewController.swift
//  Qoyod point of sale
//
//  Created by Sharjeel Ahmad on 06/09/2018.
//  Copyright © 2018 Sharjeel Ahmad. All rights reserved.
//

import UIKit
import JVFloatLabeledTextField

class NewCustomerViewController: UIViewController {

    @IBOutlet weak var firstname: JVFloatLabeledTextField!
    @IBOutlet weak var lastname: JVFloatLabeledTextField!
    @IBOutlet weak var email: JVFloatLabeledTextField!
    @IBOutlet weak var phone: JVFloatLabeledTextField!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var lblMain: UILabel!
    @IBOutlet weak var btnCancel: UIButton!
    @IBOutlet weak var btnConfirm: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        lblMain.text = languageBundle!.localizedString(forKey: "Create New Customer", value: "", table: nil)
        firstname.placeholder = languageBundle!.localizedString(forKey: "Customer Name", value: "", table: nil)
        email.placeholder = languageBundle!.localizedString(forKey: "Email", value: "", table: nil)
        phone.placeholder = languageBundle!.localizedString(forKey: "Primary Contact Number", value: "", table: nil)
        
        btnCancel.setTitle(languageBundle!.localizedString(forKey: "CANCEL", value: "", table: nil), for: .normal)
        btnConfirm.setTitle(languageBundle!.localizedString(forKey: "CONFIRM", value: "", table: nil), for: .normal)
        
        firstname.text = "Test Cust1"
        email.text = "tc1@tc.com"
        phone.text = "0987654321"
    }
    
    @IBAction func confirmTapped(_ sender: UIButton) {
        resetFieldsAndError()
        
        if firstname.isFirstResponder && firstname.canResignFirstResponder {
            firstname.resignFirstResponder()
        }
        
        if email.isFirstResponder && email.canResignFirstResponder {
            email.resignFirstResponder()
        }
        
        if phone.isFirstResponder && phone.canResignFirstResponder {
            phone.resignFirstResponder()
        }
        
        if validate()
        {
            sender.isEnabled = false
            
            showActivityIndicator(tint: .textColorPrimary)
            
            CustomerManager.shared.createContact(name: firstname.text!, email: email.text!, phone: phone.text!) {[weak self] (message, error) in
                self?.hideActivityIndicator()
                sender.isEnabled = true
                if let error = error {
                    self?.show(error: error)
                }
                else if let _ = message
                {
                    let alert = UIAlertView(title: nil, message: languageBundle!.localizedString(forKey: "Customer has been created successfully.", value: "", table: nil), delegate: nil, cancelButtonTitle: "OK")
                    alert.show()
                    self?.performSegue(withIdentifier: "exit", sender: self)
                    cartVC.refreshCustomer()
                }
            }
        }
        else
        {
            
        }
    }
    
    @IBAction func cancelTapped(_ sender: UIButton) {
        cartVC.refreshCustomer()
        dismiss(animated: true, completion: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //to manage scroll view for keyboard
        registerForKeyboardNotifications()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        //unregister as we are going out of view
        unregisterForKeyboardNotifications()
    }
    
    func validate() -> Bool {
        resetFieldsAndError()
        
        if firstname.text == ""
        {
            messageLabel.text = languageBundle!.localizedString(forKey: "Please enter a valid name", value: "", table: nil)
            return false
        }
        else if email.text != "" && !email.text!.isEmail
        {
            messageLabel.text = languageBundle!.localizedString(forKey: "Please enter a valid email", value: "", table: nil)
            return false
        }
        else if phone.text != "" && (phone.text?.count)! < 10
        {
            messageLabel.text = languageBundle!.localizedString(forKey: "Please enter a valid phone number", value: "", table: nil)
            return false
        }
        else
        {
            for i in 0..<customersList.count
            {
                let contact:Contact = customersList[i]
                
                if email.text != "" && contact.primary_email == email.text
                {
                    messageLabel.text = languageBundle!.localizedString(forKey: "This email belongs to another customer", value: "", table: nil)
                    return false
                }
                
                if phone.text != "" && contact.primary_contact_number == phone.text
                {
                    messageLabel.text = languageBundle!.localizedString(forKey: "This contact number belongs to another customer", value: "", table: nil)
                    return false
                }
            }
        }
        
        return true
    }
    
    func resetFieldsAndError() {
        messageLabel.text = ""
    }
}

extension NewCustomerViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == email {
            if !email.text!.isEmail {
                messageLabel.text = languageBundle!.localizedString(forKey: "Please enter a valid email", value: "", table: nil)
            }else {
                resetFieldsAndError()
            }
            
            phone.becomeFirstResponder()
        } else if textField == firstname {
            email.becomeFirstResponder()
        } else if textField == phone {
            confirmTapped(UIButton())
        }
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == phone {
            
            let  char = string.cString(using: String.Encoding.utf8)!
            let isBackSpace = strcmp(char, "\\b")
            
            if (isBackSpace == -92) {
                return true
            }
            
            guard let text = textField.text else { return true }
            let limitLength = 20
            let newLength = text.count + string.count - range.length
            if newLength > limitLength {
                return false
            }
            let allowedCharacters = "0123456789+"
            let allowedCharacterSet = CharacterSet(charactersIn: allowedCharacters)
            let typedCharacterSet = CharacterSet(charactersIn: string)
            let alphabet = allowedCharacterSet.isSuperset(of: typedCharacterSet)
            return alphabet
            
        } else if textField == firstname {
            
            let  char = string.cString(using: String.Encoding.utf8)!
            let isBackSpace = strcmp(char, "\\b")
            
            if (isBackSpace == -92) {
                return true
            }
            
            guard let text = textField.text else { return true }
            
            let limitLength = 30
            let newLength = text.count + string.count - range.length
            if newLength > limitLength {
                return false
            }
            
            let allowedCharacters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz "
            let allowedCharacterSet = CharacterSet(charactersIn: allowedCharacters)
            let typedCharacterSet = CharacterSet(charactersIn: string)
            let numeric = allowedCharacterSet.isSuperset(of: typedCharacterSet)
            return numeric
            
        }
        return true
    }
}

// MARK: - Keyboard Notifications
extension NewCustomerViewController {
    func registerForKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWasShown(_:)), name: .UIKeyboardDidShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillBeHidden(_:)), name: .UIKeyboardWillHide, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(_:)), name: .UIKeyboardWillChangeFrame, object: nil)
    }
    
    func unregisterForKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardDidShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillHide, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillChangeFrame, object: nil)
    }
    
    @objc func keyboardWasShown(_ notification: Notification) {
        
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height, right: 0)
            // ...
            scrollView.contentInset = contentInsets
            scrollView.scrollIndicatorInsets = contentInsets
        }
    }
    @objc func keyboardWillBeHidden(_ notification: Notification) {
        let contentInsets = UIEdgeInsets();
        scrollView.contentInset = contentInsets;
        scrollView.scrollIndicatorInsets = contentInsets;
    }
    @objc func keyboardWillChange(_ notification: Notification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height, right: 0)
            // ...
            scrollView.contentInset = contentInsets
            scrollView.scrollIndicatorInsets = contentInsets
        }
    }
    // MARK: -
}

