//
//  UITableView+Addition.swift
//  Qoyod point of sale
//
//  Created by Sharjeel Ahmad on 04/09/2018.
//  Copyright © 2018 Sharjeel Ahmad. All rights reserved.
//

import Foundation
import UIKit

extension UITableView {
    func setEmptyMessage(_ message: String) {
        let messageLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.bounds.size.width, height: self.bounds.size.height))
        messageLabel.text = message
        messageLabel.textColor = .black
        messageLabel.numberOfLines = 0;
        messageLabel.textAlignment = .center;
        messageLabel.font = UIFont.systemFont(ofSize: 17)
        messageLabel.sizeToFit()
        
        self.backgroundView = messageLabel;
    }
    
    func clearMessage() {
        self.backgroundView = nil
    }
}
