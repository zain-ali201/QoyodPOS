//
//  OrganizationViewController.swift
//  Qoyod point of sale
//
//  Created by Sharjeel Ahmad on 03/09/2018.
//  Copyright © 2018 Sharjeel Ahmad. All rights reserved.
//

import UIKit

class OrganizationViewController: UIViewController {

    var organizations:[Organization]!
    lazy fileprivate var pickerView = UIPickerView()
    @IBOutlet weak var orgTextfield: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        pickerView.delegate = self
        orgTextfield.inputView = pickerView
        orgTextfield.becomeFirstResponder()
    }
    
    @IBAction func continueTapped(_ sender: UIButton)
    {
        if organizations.count > 0
        {
            showActivityIndicator()
            sender.isEnabled = false
            OrganizationManager.shared.setOrganization(identifier: organizations[pickerView.selectedRow(inComponent: 0)].identifier) {[weak self] (message, error) in
                self?.hideActivityIndicator()
                sender.isEnabled = true
                if let error = error{
                    self?.show(error: error)
                }else {
                    if let message = message {
                        UserDefaults.standard.set(true, forKey: UserDefaults.Key.isLoggedIn)
                        UserDefaults.standard.synchronize()
                        
                        //proceed to home
                        let vc:UITabBarController = UIStoryboard.main.instantiateViewController(withIdentifier: "Home") as! UITabBarController
                        vc.selectedIndex = 1
                        rootVC = vc
                        self?.present(vc, animated: true, completion: {
                            //show mesage
                            vc.showMessage(message)
                        })
                    }
                }
            }
        }
        else
        {
            self.view.makeToast(languageBundle!.localizedString(forKey: "Organisation not found", value: "", table: nil))
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if organizations.count > 0
        {
            orgTextfield.text = organizations.first!.organization_name
        }
    }
}

extension OrganizationViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return organizations.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return organizations[row].organization_name
    }
}


extension OrganizationViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        print("selected \(organizations[row])")
        orgTextfield.text = organizations[row].organization_name
    }
}
