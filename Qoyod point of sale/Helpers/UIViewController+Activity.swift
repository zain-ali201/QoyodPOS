//
//  UIViewController+Activity.swift
//  Qoyod
//
//  Created by Sharjeel Ahmad on 01/01/2018.
//  Copyright © 2018 Qoyod. All rights reserved.
//

import UIKit
import NVActivityIndicatorView
import CocoaBar

extension UIViewController {
    @discardableResult
    func showActivityIndicator(tint: UIColor = .primary) -> NVActivityIndicatorPresenter {
        // don't show activity indicator if app is locked.
        if !UserDefaults.standard.bool(forKey: UserDefaults.Key.isLocked) {
            
            let activity = ActivityData(size: CGSize(width: 50, height: 50), message: nil, type: .ballClipRotateMultiple, color: tint, backgroundColor: UIColor(white: 0, alpha: 0.1))
            NVActivityIndicatorPresenter.sharedInstance.startAnimating(activity, nil)
        }
        
        return NVActivityIndicatorPresenter.sharedInstance
    }
    
    func hideActivityIndicator() {
        NVActivityIndicatorPresenter.sharedInstance.stopAnimating(nil)
    }
    
    func show(error: Error) {
        let alert = UIAlertController(title: languageBundle!.localizedString(forKey: "Error", value: "", table: nil), message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    func showSuccessMessage() {
        showMessage(languageBundle!.localizedString(forKey: "Success", value: "", table: nil))
    }
    func showFailedMessage() {
        showMessage(languageBundle!.localizedString(forKey: "Failed", value: "", table: nil))
    }
    func showMessage(_ message: String) {
        let bar = CocoaBar(view: self.view)
        bar.showAnimated(true, duration: CocoaBar.DisplayDuration.short, style: CocoaBar.Style.default, populate: {(layout) in
            if let layout = layout as? CocoaBarDefaultLayout {
                layout.titleLabel?.text = message
                layout.backgroundStyle = .blurDark
            }
        }) { (animated, completed, visible) in
            
        }
    }
    
    @objc func showSimpleAlert(title: String?,
                         message: String?,
                         buttonTitle: String?,
                         buttonStyle: UIAlertActionStyle,
                         completion: ((UIAlertController) -> Void)? = nil) {
        let alertController = UIAlertController(title: title,
                                                message: message,
                                                preferredStyle: .alert)
        
        let action = UIAlertAction(title: buttonTitle, style: buttonStyle, handler: nil)
        
        alertController.addAction(action)
        
        self.present(alertController, animated: true, completion: nil)
        
        DispatchQueue.main.async {
            completion?(alertController)
        }
    }
}
