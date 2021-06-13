//
//  UIStoryboard+Helper.swift
//  Qoyod
//
//  Created by Sharjeel Ahmad on 29/11/2017.
//  Copyright © 2017 Qoyod. All rights reserved.
//

import UIKit

extension UIStoryboard {
    static var main: UIStoryboard {
        return UIStoryboard(name: "Main", bundle: Bundle.main)
    }
    static var onboarding: UIStoryboard {
        return UIStoryboard(name: "Onboarding", bundle: Bundle.main)
    }
    static var starprinter: UIStoryboard {
        return UIStoryboard(name: "Star", bundle: Bundle.main)
    }
    
    static var epson: UIStoryboard
    {
        return UIStoryboard(name: "Epson", bundle: Bundle.main)
    }
}
