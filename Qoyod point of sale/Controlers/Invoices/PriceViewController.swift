//
//  priceViewController.swift
//  Qoyod point of sale
//
//  Created by Sharjeel Ahmad on 07/09/2018.
//  Copyright © 2018 Sharjeel Ahmad. All rights reserved.
//

import UIKit

class PriceViewController: UIViewController {
    
    //shared
    var product:Product!
    
    @IBOutlet weak var lblMain: UILabel!
    @IBOutlet weak var lblText: UILabel!
    @IBOutlet weak var productname: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var txtPrice: UITextField!
    
    @IBOutlet weak var btnCancel: UIButton!
    @IBOutlet weak var btnApply: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        productname.text = product.name
        
        let priceText = product.selling_price ?? ""
        let price = Double(priceText) ?? 0.0
        
        if price > 0
        {
            let priceStr = String(format: "%.2f", price)
            txtPrice.text = "\(priceStr)"
        }
        else
        {
            txtPrice.text = "0.0"
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        registerForKeyboardNotifications()
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        lblMain.text = languageBundle!.localizedString(forKey: "Product Price", value: "", table: nil)
        lblText.text = languageBundle!.localizedString(forKey: "Enter the price of product", value: "", table: nil)
        
        btnCancel.setTitle(languageBundle!.localizedString(forKey: "CANCEL", value: "", table: nil), for: .normal)
        btnApply.setTitle(languageBundle!.localizedString(forKey: "APPLY", value: "", table: nil), for: .normal)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidAppear(animated)
        unregisterForKeyboardNotifications()
    }
    
    @IBAction func applyTapped(_ sender: UIButton)
    {
        let priceText = txtPrice.text ?? ""
        
        let numberFormatter = NumberFormatter()
        numberFormatter.locale = Locale(identifier: "EN")
        let finalText = numberFormatter.number(from:priceText)
        
        if finalText != nil
        {
            product.selling_price = priceText
            
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

extension PriceViewController: UITextFieldDelegate
{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        applyTapped(UIButton())
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - Keyboard Notifications
extension PriceViewController {
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

