//
//  SignupViewController.swift
//  Qoyod point of sale
//
//  Created by Sprint on 18/04/2019.
//  Copyright © 2019 Sprint. All rights reserved.
//

import UIKit

class ForgotPasswordVC: UIViewController, UIWebViewDelegate {
    
    @IBOutlet var webView:UIWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        let request = URLRequest.init(url: URL(string: NetworkConfig.passwordUrl)!)
        webView.loadRequest(request)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        //for white status bar
        return .lightContent
    }
    
    @IBAction func backBtnAction(_ sender: Any)
    {
        self.navigationController?.popViewController(animated: true)
    }
    
    func webViewDidStartLoad(_ webView: UIWebView) {
        showActivityIndicator(tint: .textColorPrimary)
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        self.hideActivityIndicator()
    }
    
    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        self.hideActivityIndicator()
        self.view.makeToast(languageBundle!.localizedString(forKey: "Network error. Please try later.", value: "", table: nil))
    }
}
