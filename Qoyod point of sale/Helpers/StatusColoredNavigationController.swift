//
//  StatusColoredNavigationController.swift
//  BenefitNet
//
//  Created by Mahmood Tahir on 29/11/2017.
//  Copyright © 2017 BenefitNet. All rights reserved.
//

import UIKit

class StatusColoredNavigationController: StyledNavigationController {
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    var statusBarView: UIView?
    override func viewDidLoad() {
        super.viewDidLoad()
        style()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let bg = statusBarView {
            view.bringSubview(toFront: bg)
            bg.isHidden = isNavigationBarHidden
        }
    }
    
    override func setNavigationBarHidden(_ hidden: Bool, animated: Bool) {
        if let bg = statusBarView {
            view.bringSubview(toFront: bg)
            bg.isHidden = hidden
        }
        super.setNavigationBarHidden(hidden, animated: animated)
    }
    
    private func style() {
        // add the status view
        let bgView = UIView(frame: CGRect(origin: CGPoint(), size: CGSize(width: self.view.frame.width, height: 0)))
        bgView.backgroundColor = UIColor.primary
        self.view.addSubview(bgView)
        statusBarView = bgView
        
        bgView.translatesAutoresizingMaskIntoConstraints = false
        // create constraints
        let bottomConstraint: NSLayoutConstraint
        if #available(iOS 11.0, *) {
            bottomConstraint = NSLayoutConstraint(item: bgView, attribute: .bottom, relatedBy: .equal, toItem: view.safeAreaLayoutGuide, attribute: .top, multiplier: 1, constant: 0)
        } else {
            // Fallback on earlier versions
            bottomConstraint = NSLayoutConstraint(item: bgView, attribute: .bottom, relatedBy: .equal, toItem: topLayoutGuide, attribute: .top, multiplier: 1, constant: 0)
        }
        NSLayoutConstraint.activate([
            NSLayoutConstraint(item: bgView, attribute: .top, relatedBy: .equal, toItem: bgView.superview, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: bgView, attribute: .leading, relatedBy: .equal, toItem: bgView.superview, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: bgView, attribute: .trailing, relatedBy: .equal, toItem: bgView.superview, attribute: .trailing, multiplier: 1, constant: 0),
            bottomConstraint,
            ])
    }
}
