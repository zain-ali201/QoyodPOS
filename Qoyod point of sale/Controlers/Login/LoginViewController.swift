//
//  LoginViewController.swift
//  Qoyod point of sale
//
//  Created by Sharjeel Ahmad on 01/09/2018.
//  Copyright © 2018 Sharjeel Ahmad. All rights reserved.
//

import UIKit
import SafariServices

class LoginViewController: UIViewController
{
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var messageLabel: UILabel!
    
    @IBOutlet weak var btnForgot: UIButton!
    @IBOutlet weak var btnLogin: UIButton!
    @IBOutlet weak var btnRegister: UIButton!
    @IBOutlet weak var lblMain: UILabel!
    @IBOutlet weak var lblReg: UILabel!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        //for white status bar
        return .lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        #if DEBUG
//        emailTextField.text = "appletester@moh.qdev.it"
//        passwordTextField.text = "appletest"
        emailTextField.text = "zain@sprintsols.com"
        passwordTextField.text = "12345678"
        #endif
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        lblMain.text = languageBundle!.localizedString(forKey: "Login", value: "", table: nil)
        lblReg.text = languageBundle!.localizedString(forKey: "Don't have an account?", value: "", table: nil)
        emailTextField.placeholder = languageBundle!.localizedString(forKey: "Email", value: "", table: nil)
        passwordTextField.placeholder = languageBundle!.localizedString(forKey: "Password", value: "", table: nil)
        btnForgot.setTitle(languageBundle!.localizedString(forKey: "Forgot Password?", value: "", table: nil), for: .normal)
        btnLogin.setTitle(languageBundle!.localizedString(forKey: "Login", value: "", table: nil), for: .normal)
        btnRegister.setTitle(languageBundle!.localizedString(forKey: "Register now", value: "", table: nil), for: .normal)
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
    
    @IBAction func registerTapped(_ sender: UIButton) {
        showRegisterDialog()
    }
    
    @IBAction func loginTapped(_ sender: UIButton) {
        resetFieldsAndError()
        
        if emailTextField.isFirstResponder && emailTextField.canResignFirstResponder {
            emailTextField.resignFirstResponder()
        }
        
        if passwordTextField.isFirstResponder && passwordTextField.canResignFirstResponder {
            passwordTextField.resignFirstResponder()
        }
        
        if validate() {
            sender.isEnabled = false
            showActivityIndicator(tint: .textColorPrimary)
            AuthManager.shared.login(withUsername: self.emailTextField.text!, password: self.passwordTextField.text!, completionHandler: {[weak self] (success, error) in
                self?.hideActivityIndicator()
                if success { //no pin code found
                    if UserDefaults.standard.integer(forKey: UserDefaults.Key.pinCode) == 0
                    {
                        self?.performSegue(withIdentifier: "newpincode", sender: nil)
                    }
                    else
                    {
                        self?.performSegue(withIdentifier: "pincode", sender: nil)
                    }
                }
                else
                {
                    sender.isEnabled = true
                    if let errorMessage = error?.localizedDescription {
                        self?.messageLabel.text = errorMessage
                    }
                }
            })
        }
    }
    
    @IBAction func forgotTapped(_ sender: UIButton)
    {
//        let svc = SFSafariViewController(url: URL(string: NetworkConfig.passwordUrl)!)
//        self.present(svc, animated: true, completion: nil)
        
        let forgotVC = UIStoryboard.onboarding.instantiateViewController(withIdentifier: "ForgotPasswordVC") as! ForgotPasswordVC
        self.navigationController?.pushViewController(forgotVC, animated: true)
    }
    
    fileprivate func showRegisterDialog()
    {
        //create alert dialog
//        let alert = UIAlertController(title: languageBundle!.localizedString(forKey: "Register", comment: "Register") , message: languageBundle!.localizedString(forKey: "You can register in the Qoyod's POS program by registering on Qoyod's website and then activate POS for the user", value: "", table: nil), preferredStyle: UIAlertControllerStyle.alert)
//
//        //add actions
//
//        alert.addAction(UIAlertAction(title: languageBundle!.localizedString(forKey: "HOW TO ACTIVATE QOYOD'S POINT OF SALE USER", value: "", table: nil) , style: .destructive, handler: { action in
//            alert.dismiss(animated: false, completion: nil)
//            self.showSalePointDialog()
//        }))
//
//        alert.addAction(UIAlertAction(title: languageBundle!.localizedString(forKey: "CANCEL" , comment: "cancel"), style: .cancel, handler: { action in
//        }))
//
//        //present the dialog
//        self.present(alert, animated: true, completion: nil)
        
//        let svc = SFSafariViewController(url: URL(string: NetworkConfig.registerUrl)!)
//        self.present(svc, animated: true, completion: nil)
        
        let signupVC = UIStoryboard.onboarding.instantiateViewController(withIdentifier: "SignupViewController") as! SignupViewController
        self.navigationController?.pushViewController(signupVC, animated: true)
    }
    
    fileprivate func showSalePointDialog() {
        //create alert dialog
//        let alert = UIAlertController(title: languageBundle!.localizedString(forKey: "How to activate Qoyod's Point of Sale user", value: "", table: nil) , message: languageBundle!.localizedString(forKey: "Go to the Qoyod's Dashboard > Settings > Users > check POS user", value: "", table: nil), preferredStyle: UIAlertControllerStyle.alert)
        languageBundle!.localizedString(forKey: "1 item selected", value: "", table: nil)
        let alert = UIAlertController(title:  languageBundle!.localizedString(forKey: "How to activate Qoyod's Point of Sale user", value: "", table: nil) , message: languageBundle!.localizedString(forKey: "Go to the Qoyod's Dashboard > Settings > Users > check POS user", value: "", table: nil), preferredStyle: UIAlertControllerStyle.alert)
        
        //add actions
        
        alert.addAction(UIAlertAction(title: languageBundle!.localizedString(forKey: "OK", value: "", table: nil), style: .cancel, handler: { action in
        }))
        
        //present the dialog
        self.present(alert, animated: true, completion: nil)
    }
    
    func validate() -> Bool {
        resetFieldsAndError()
        
        if passwordTextField.text == "" {
            messageLabel.text = languageBundle!.localizedString(forKey: "Please enter a valid password", value: "", table: nil)
            return false
        }
        
        if !emailTextField.text!.isEmail {
            messageLabel.text = languageBundle!.localizedString(forKey: "Please enter a valid email", value: "", table: nil)
            return false
        }
        
        return true
    }
    
    func resetFieldsAndError() {
        messageLabel.text = ""
    }
}

extension LoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailTextField {
            if !textField.text!.isEmail {
                messageLabel.text = languageBundle!.localizedString(forKey: "Please enter a valid email", value: "", table: nil)
            }else {
                resetFieldsAndError()
            }
            
            passwordTextField.becomeFirstResponder()
        } else {
            loginTapped(UIButton())
        }
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return true
    }
}

// MARK: - Keyboard Notifications
extension LoginViewController {
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

