//
//  UnderlinedTextField.swift
//  Qoyod
//
//  Created by Sharjeel Ahmad on 29/11/2017.
//  Copyright © 2017 Qoyod. All rights reserved.
//

import UIKit
import JVFloatLabeledTextField

@IBDesignable
class UnderlinedTextField: JVFloatLabeledTextField {
    @discardableResult
    override func becomeFirstResponder() -> Bool {
        setNeedsDisplay()
        return super.becomeFirstResponder()
    }
    @discardableResult
    override func resignFirstResponder() -> Bool {
        setNeedsDisplay()
        return super.resignFirstResponder()
    }
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
        let path = UIBezierPath()
        path.move(to: CGPoint(x: rect.origin.x, y: rect.size.height-1))
        path.addLine(to: CGPoint(x: rect.origin.x + rect.width, y: rect.height-1))
        if isFirstResponder {
            tintColor.setStroke()
        } else {
            #colorLiteral(red: 0.8235294118, green: 0.8235294118, blue: 0.8235294118, alpha: 1).setStroke()
        }
        path.stroke()
    }
 

}
