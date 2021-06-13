//
//  UnderlineView.swift
//  Qoyod
//
//  Created by Apple on 31/01/2018.
//  Copyright © 2018 Inova Care. All rights reserved.
//

import UIKit

class UnderlineView: UIView {

    var underlineColor = UIColor.lightGray {
        didSet {
            setNeedsDisplay()
        }
    }
    
    override func draw(_ rect: CGRect) {
        let path = UIBezierPath()
        path.lineWidth = 1.0
        path.move(to: CGPoint(x: 0, y: rect.size.height))
        path.addLine(to: CGPoint(x: rect.size.width, y: rect.size.height))
        self.underlineColor.setStroke()
        path.stroke()
    }
    
    override func layoutSubviews() {
        setNeedsDisplay()
        //layoutSubviews()
    }
    
    

}
