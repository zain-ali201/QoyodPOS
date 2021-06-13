//
//  QuantityViewController.swift
//  Qoyod point of sale
//
//  Created by Sharjeel Ahmad on 19/09/2018.
//  Copyright © 2018 Sharjeel Ahmad. All rights reserved.
//

import UIKit

class QuantityViewController: UIViewController
{
    //shared
    var product:Product!
    
    @IBOutlet weak var lblMain: UILabel!
    @IBOutlet weak var lblText: UILabel!
    @IBOutlet weak var productname: UILabel!
    @IBOutlet weak var productStock: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var quantityTextField: UITextField!
    
    @IBOutlet weak var btnCancel: UIButton!
    @IBOutlet weak var btnApply: UIButton!
    
    let windowCount = UIApplication.shared.windows.count
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        productname.text = product.name
        
        let quantityText = product.created_at ?? ""
        let quantity = Double(quantityText) ?? 1.0
        quantityTextField.text = "\(quantity)"
        
        if verifyProduct(product: product)
        {
            productStock.text = String(format: "%@: %@" , languageBundle!.localizedString(forKey:"Stock", value: "", table: nil), product.current_stock ?? "0")
        }
    }
  
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        registerForKeyboardNotifications()
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        lblMain.text = languageBundle!.localizedString(forKey: "Item Quantity", value: "", table: nil)
        lblText.text = languageBundle!.localizedString(forKey: "Enter the quantity of", value: "", table: nil)
        
        btnCancel.setTitle(languageBundle!.localizedString(forKey: "CANCEL", value: "", table: nil), for: .normal)
        btnApply.setTitle(languageBundle!.localizedString(forKey: "APPLY", value: "", table: nil), for: .normal)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidAppear(animated)
        unregisterForKeyboardNotifications()
    }
    
    @IBAction func applyTapped(_ sender: UIButton)
    {
        let quantityText = quantityTextField.text ?? ""
        var quantity = Double(quantityText) ?? 1.0
        
        if quantity <= 0
        {
            let alert = UIAlertController(title: "" , message: languageBundle!.localizedString(forKey: "Quantity cannot be zero. Do you want to deselect this product?", value: "", table: nil), preferredStyle: UIAlertControllerStyle.alert)
            
            alert.addAction(UIAlertAction(title: "YES", style: .default, handler: { action in
                self.product.created_at = "0"
                self.performSegue(withIdentifier: "exit", sender: self)
            }))
            
            alert.addAction(UIAlertAction(title: "NO", style: .cancel, handler: { action in
            
            }))
            
            self.present(alert, animated: true, completion: nil)
//            quantity = 1.0
        }
        else
        {
            if quantity > Double(product.current_stock!)!
            {
                quantity = Double(product.current_stock!)!
            }
            
            if verifyProduct(product: product)
            {
                if product.current_stock != nil
                {
                    let stock = Double(product.current_stock!) ?? 0
                    
                    if quantity <= stock
                    {
                        product.created_at = "\(quantity.rounded(toPlaces: 2))"
                        performSegue(withIdentifier: "exit", sender: self)
                    }
                    else
                    {
                        UIApplication.shared.windows[windowCount-1].makeToast(languageBundle!.localizedString(forKey: "Quantity should not be greater than stock.", value: "", table: nil))
                        
                    }
                }
                else
                {
                    UIApplication.shared.windows[windowCount-1].makeToast(languageBundle!.localizedString(forKey: "Quantity should not be greater than stock.", value: "", table: nil))
                }
            }
            else
            {
                product.created_at = "\(quantity.rounded(toPlaces: 2))"
                performSegue(withIdentifier: "exit", sender: self)
            }
        }
    }
    
    @IBAction func cancelTapped(_ sender: UIButton)
    {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func startEdit(_ sender: UITextField) {
        sender.text = ""
    }
    
    @IBAction func increaseQuantity(_ sender: UIButton)
    {
        let discountText = quantityTextField.text ?? ""
        var discount = Double(discountText) ?? 1.0
        discount += 1.0
        
        if verifyProduct(product: product)
        {
            if product.current_stock != nil
            {
//                let stock = Double(product.current_stock!) ?? 0
                
//                if discount <= stock
                
                let stock = Double(product.current_stock!) ?? 0
                
                var increment = 0.0
                if let rateVal = Double(product.unit_representation) {
                    increment = rateVal
                }
                
                let qty = discount * increment
                
                if qty < stock
                {
                    product.created_at = "\(discount.rounded(toPlaces: 2))"
                    quantityTextField.text = "\(discount)"
                }
                else
                {
                    self.view.makeToast(languageBundle!.localizedString(forKey: "Product is out of stock", value: "", table: nil))
                }
            }
            else
            {
                self.view.makeToast(languageBundle!.localizedString(forKey: "Product is out of stock", value: "", table: nil))
            }
        }
        else
        {
            product.created_at = "\(discount.rounded(toPlaces: 2))"
            quantityTextField.text = "\(discount)"
        }
    }
    
    @IBAction func decreaseQuantity(_ sender: UIButton)
    {
        let discountText = quantityTextField.text ?? ""
        var discount = Double(discountText) ?? 1.0
        discount -= 1.0
        
        if discount <= 0
        {
            let alert = UIAlertController(title: "" , message: languageBundle!.localizedString(forKey: "Quantity cannot be less than one. Do you want to deselect this product?", value: "", table: nil), preferredStyle: UIAlertControllerStyle.alert)
            
            alert.addAction(UIAlertAction(title: languageBundle!.localizedString(forKey: "YES", value: "", table: nil), style: .default, handler: { action in
                self.product.created_at = "0"
                self.performSegue(withIdentifier: languageBundle!.localizedString(forKey: "exit", value: "", table: nil), sender: self)
            }))
            
            alert.addAction(UIAlertAction(title: languageBundle!.localizedString(forKey: "NO", value: "", table: nil), style: .cancel, handler: { action in
                
            }))
            
            self.present(alert, animated: true, completion: nil)
        }
        else
        {
//            if discount <= 0 {
//                discount = 1.0
//            }
            
            product.created_at = "\(discount.rounded(toPlaces: 2))"
            quantityTextField.text = "\(discount)"
        }
    }
}

extension QuantityViewController: UITextFieldDelegate
{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        applyTapped(UIButton())
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - Keyboard Notifications
extension QuantityViewController {
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
}
