//
//  DiscountViewController.swift
//  Qoyod point of sale
//
//  Created by Sharjeel Ahmad on 07/09/2018.
//  Copyright © 2018 Sharjeel Ahmad. All rights reserved.
//

import UIKit

class DiscountViewController: UIViewController {
    
    //shared
    var product:Product!

    @IBOutlet weak var lblMain: UILabel!
    @IBOutlet weak var lblText: UILabel!
    @IBOutlet weak var productname: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var discountTextField: UITextField!
    
    @IBOutlet weak var btnCancel: UIButton!
    @IBOutlet weak var btnApply: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        productname.text = product.name
        
        let discountText = product.updated_at ?? ""
        let discount = Double(discountText) ?? 0
        
        if discount > 0
        {
            let discountStr = String(format: "%.2f", discount)
            discountTextField.text = "\(discountStr)%"
        }
        else
        {
            discountTextField.text = "0%"
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        registerForKeyboardNotifications()
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        lblMain.text = languageBundle!.localizedString(forKey: "Discount", value: "", table: nil)
        lblText.text = languageBundle!.localizedString(forKey: "Enter the amount of discount on", value: "", table: nil)
        
        btnCancel.setTitle(languageBundle!.localizedString(forKey: "CANCEL", value: "", table: nil), for: .normal)
        btnApply.setTitle(languageBundle!.localizedString(forKey: "APPLY", value: "", table: nil), for: .normal)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidAppear(animated)
        unregisterForKeyboardNotifications()
    }
    
    @IBAction func applyTapped(_ sender: UIButton)
    {
        let discountText = discountTextField.text ?? ""
        
        let numberFormatter = NumberFormatter()
        numberFormatter.locale = Locale(identifier: "EN")
        let finalText = numberFormatter.number(from:discountText)
        
        if finalText != nil
        {
            var discount = Double(discountText)
            
            if discount! < 0
            {
                discount = 0
            }
            else if discount! > 100
            {
                discount = 100
            }
            
            product.updated_at = discountText
            
            performSegue(withIdentifier: "exit", sender: self)
        }
        else
        {
            self.view.makeToast(languageBundle!.localizedString(forKey: "Please enter a valid amount", value: "", table: nil))
        }
    }
    
    @IBAction func cancelTapped(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func startEdit(_ sender: UITextField) {
        sender.text = ""
    }
}

extension DiscountViewController: UITextFieldDelegate
{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        applyTapped(UIButton())
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - Keyboard Notifications
extension DiscountViewController {
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

