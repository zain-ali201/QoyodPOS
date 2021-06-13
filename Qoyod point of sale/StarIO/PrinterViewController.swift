//
//  PrinterViewController.swift
//  Swift SDK
//
//  Created by Yuji on 2015/**/**.
//  Copyright © 2015年 Star Micronics. All rights reserved.
//

import UIKit

class CustomUIImagePickerController: UIImagePickerController {
    override var shouldAutorotate : Bool {
        return true
    }
    
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        if AppDelegate.isIPad() {
            return UIInterfaceOrientationMask.all
        }
        
        return UIInterfaceOrientationMask.allButUpsideDown
    }
}

class PrinterViewController: CommonViewController, UITableViewDelegate, UITableViewDataSource, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier: String = "UITableViewCellStyleValue1"
        
        var cell: UITableViewCell! = self.tableView.dequeueReusableCell(withIdentifier: cellIdentifier)
        
        if cell == nil {
            cell = UITableViewCell(style: UITableViewCellStyle.value1, reuseIdentifier: cellIdentifier)
        }
        
        if cell != nil
        {
            if indexPath.section != 2
            {
               cell.textLabel!.text = String(format: "Text Receipt (UTF8)")
                
                cell.detailTextLabel!.text = ""
                
                cell      .textLabel!.textColor = UIColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0)
                cell.detailTextLabel!.textColor = UIColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0)
                
//              cell.accessoryType = UITableViewCellAccessoryType.disclosureIndicator
                
                var userInteractionEnabled: Bool = true
                
                guard let modelIndex = AppDelegate.getSelectedModelIndex() else {
                    fatalError()
                }
                
                guard let printerInfo = ModelCapability.modelCapabilityDictionary[modelIndex] else {
                    fatalError()
                }

                if indexPath.row == 0 ||     // Text Receipt
                    indexPath.row == 1 {      // Text Receipt (UTF8)
                    userInteractionEnabled = printerInfo.textReceiptIsEnabled
                }

                if indexPath.row == 1 {     // Text Receipt (UTF8)
                    userInteractionEnabled = printerInfo.UTF8IsEnabled
                }

                if indexPath.row == 2 ||     // Raster Receipt
                    indexPath.row == 3 ||     // Raster Receipt (Both Scale)
                    indexPath.row == 4 {      // Raster Receipt (Scale)
                    userInteractionEnabled = printerInfo.rasterReceiptIsEnabled
                }
            
                
                if userInteractionEnabled == true {
                    cell      .textLabel!.alpha = 1.0
                    cell.detailTextLabel!.alpha = 1.0
                    
                    cell.accessoryType = UITableViewCellAccessoryType.disclosureIndicator
                    
                    cell.isUserInteractionEnabled = true
                }
                else {
                    cell      .textLabel!.alpha = 0.3
                    cell.detailTextLabel!.alpha = 0.3
                    
                    cell.accessoryType = UITableViewCellAccessoryType.none
                    
                    cell.isUserInteractionEnabled = false
                }
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let title: String
        
        if section == 0 {
            title = "Like a StarIO-SDK Sample"
        }
        else if section == 1 {
            title = "StarIoExtManager Sample"
        }
        else {
            title = "Appendix"
        }
        
        return title
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 0
        {
            let commands: Data
            
            let emulation: StarIoExtEmulation = AppDelegate.getEmulation()
            
            let width: Int = AppDelegate.getSelectedPaperSize().rawValue
            
            let localizeReceipts: ILocalizeReceipts = LocalizeReceipts.createLocalizeReceipts()
            
                commands = PrinterFunctions.createTextReceiptData(emulation, localizeReceipts: localizeReceipts, utf8: true)

            
            self.blind = true
            
            let portName: String = AppDelegate.getPortName()
            let portSettings: String = AppDelegate.getPortSettings()
            
            GlobalQueueManager.shared.serialQueue.async {
                _ = Communication.sendCommands(commands,
                                               portName: portName,
                                               portSettings: portSettings,
                                               timeout: 10000,  // 10000mS!!!
                                               completionHandler: { (result: Bool, title: String, message: String) in
                                                DispatchQueue.main.async {
//                                                    self.showSimpleAlert(title: title,
//                                                                         message: message,
//                                                                         buttonTitle: "OK",
//                                                                         buttonStyle: .cancel)

                                                    self.blind = false
                                                }
                })
            }
        }
    }
    
    func imagePickerController(_ imagePicker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let image: UIImage = info[UIImagePickerControllerOriginalImage] as! UIImage
//      let image: UIImage = info[UIImagePickerControllerEditedImage]   as! UIImage
        
        self.dismiss(animated: true, completion: {
            let commands: Data
            
            let builder: ISCBBuilder = StarIoExt.createCommandBuilder(AppDelegate.getEmulation())
            
            builder.beginDocument()
            
            builder.appendBitmap(image, diffusion: true, width: AppDelegate.getSelectedPaperSize().rawValue, bothScale: true)
            
            builder.appendCutPaper(SCBCutPaperAction.partialCutWithFeed)
            
            builder.endDocument()
            
            commands = builder.commands.copy() as! Data
            
            self.blind = true
            
            let portName:     String = AppDelegate.getPortName()
            let portSettings: String = AppDelegate.getPortSettings()

            GlobalQueueManager.shared.serialQueue.async {
                _ = Communication.sendCommands(commands,
                                               portName: portName,
                                               portSettings: portSettings,
                                               timeout: 10000,
                                               completionHandler: { (result: Bool, title: String, message: String) in
                                                DispatchQueue.main.async {
//                                                    self.showSimpleAlert(title: title,
//                                                                         message: message,
//                                                                         buttonTitle: "OK",
//                                                                         buttonStyle: .cancel)
                                                
                                                    self.blind = false
                                                }
                })
            }
        })
    }
}
