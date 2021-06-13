//
//  StyledNavigationController.swift
//  BenefitNet
//
//  Created by Mahmood Tahir on 09/01/2018.
//  Copyright © 2018 BenefitNet. All rights reserved.
//

import UIKit

extension UINavigationController {
    func customize() {
        // add the status view
        navigationBar.barTintColor = UIColor.colorPrimaryDark
        
        // font
        navigationBar.titleTextAttributes = [.font: UIFont.systemFont(ofSize: 20, weight: .medium), .foregroundColor: UIColor.white]
        navigationBar.tintColor = UIColor.primary
    }
}

class StyledNavigationController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()

        customize()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
