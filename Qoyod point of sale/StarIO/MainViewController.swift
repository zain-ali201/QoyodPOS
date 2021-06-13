//
//  MainViewController.swift
//  Swift SDK
//
//  Created by Yuji on 2015/**/**.
//  Copyright © 2015年 Star Micronics. All rights reserved.
//

import UIKit

class MainViewController: CommonViewController, UITableViewDelegate, UITableViewDataSource
{
    enum SectionIndex: Int {
        case device = 0
        case printer
        case cashDrawer
        case barcodeReader
        case deviceStatus
        case bluetooth
    }
    
    @IBOutlet weak var tableView: UITableView!
    
    var selectedIndexPath: IndexPath!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let title: String = "StarPRINT"
        
        let version: String = String(format: "Ver.%@", Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String)
        
        self.navigationItem.title = String(format: "%@ %@", title, version)
        
        self.selectedIndexPath = nil
        
        tableView.tableFooterView = UIView(frame: .zero)
    }
    
    @IBAction func doneTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.reloadData()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 5
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == SectionIndex.device.rawValue {
            return 1
        }
        if section == SectionIndex.printer.rawValue {
            return 1
        }
        if section == SectionIndex.deviceStatus.rawValue {
            return 2
        }
        
        if section == SectionIndex.bluetooth.rawValue {
            return 3
        }
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell!
        
        if SectionIndex(rawValue: indexPath.section)! == SectionIndex.device
        {
            if  AppDelegate.settingManager.settings[0] == nil
            {
                let cellIdentifier: String = "UITableViewCellStyleValue1"
                
                cell = self.tableView.dequeueReusableCell(withIdentifier: cellIdentifier)
                
                if cell == nil {
                    cell = UITableViewCell(style: UITableViewCellStyle.value1,
                                           reuseIdentifier: cellIdentifier)
                }
                
                if cell != nil {
                    cell.backgroundColor = UIColor(red: 0.8, green: 0.9, blue: 1.0, alpha: 1.0)
                    
                    cell      .textLabel!.text = "Unselected State"
                    cell.detailTextLabel!.text = ""
                    
                    cell      .textLabel!.textColor = UIColor.red
                    cell.detailTextLabel!.textColor = UIColor.red
                    
                    UIView.beginAnimations(nil, context: nil)
                    
                    cell      .textLabel!.alpha = 0.0
                    cell.detailTextLabel!.alpha = 0.0
                    
                    UIView.setAnimationDelay             (0.0)                             // 0mS!!!
                    UIView.setAnimationDuration          (0.6)                             // 600mS!!!
                    UIView.setAnimationRepeatCount       (Float(UINT32_MAX))
                    UIView.setAnimationRepeatAutoreverses(true)
                    UIView.setAnimationCurve             (UIViewAnimationCurve.easeIn)
                    
                    cell      .textLabel!.alpha = 1.0
                    cell.detailTextLabel!.alpha = 1.0
                    
                    UIView.commitAnimations()
                    
                    cell.accessoryType = UITableViewCellAccessoryType.disclosureIndicator
                    
                    cell.isUserInteractionEnabled = true
                }
            }
            else
            {
                let currentSetting = AppDelegate.settingManager.settings[indexPath.row]!
                
                let cellIdentifier: String = "UITableViewCellStyleSubtitle"
                
                cell = self.tableView.dequeueReusableCell(withIdentifier: cellIdentifier)
                
                if cell == nil {
                    cell = UITableViewCell(style: UITableViewCellStyle.subtitle,
                                           reuseIdentifier: cellIdentifier)
                }
                
                cell.textLabel!.text = currentSetting.modelName
                
                if currentSetting.macAddress == "" {
                    cell.detailTextLabel!.text = currentSetting.portName
                } else {
                    cell.detailTextLabel!.text = "\(currentSetting.portName) (\(currentSetting.macAddress))"
                }

                cell.backgroundColor = UIColor(red: 0.8, green: 0.9, blue: 1.0, alpha: 1.0)
                cell.textLabel!.textColor = UIColor.blue
                cell.detailTextLabel!.textColor = UIColor.blue
                cell.accessoryType = .disclosureIndicator
                
                return cell
            }
        }
        else
        {
            let cellIdentifier: String = "UITableViewCellStyleValue1"
            
            cell = self.tableView.dequeueReusableCell(withIdentifier: cellIdentifier)
            
            if cell == nil {
                cell = UITableViewCell(style: UITableViewCellStyle.value1, reuseIdentifier: cellIdentifier)
            }
            
            if cell != nil
            {
                switch SectionIndex(rawValue: indexPath.section)!{
                case SectionIndex.printer :
                    cell.backgroundColor = UIColor.white
                    
                    cell      .textLabel!.text = "Sample"
                    cell.detailTextLabel!.text = ""
                    
                    cell      .textLabel!.textColor = UIColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0)
                    cell.detailTextLabel!.textColor = UIColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0)
                case SectionIndex.cashDrawer:
                    cell.backgroundColor = UIColor.white
                    
                    cell      .textLabel!.text = "Sample"
                    cell.detailTextLabel!.text = ""
                    
                    cell      .textLabel!.textColor = UIColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0)
                    cell.detailTextLabel!.textColor = UIColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0)
                case SectionIndex.barcodeReader:
                    cell.backgroundColor = UIColor.white
                    
                    cell      .textLabel!.text = "StarIoExtManager Sample"
                    cell.detailTextLabel!.text = ""
                    
                    cell      .textLabel!.textColor = UIColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0)
                    cell.detailTextLabel!.textColor = UIColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0)
                case SectionIndex.deviceStatus :
                    cell.backgroundColor = UIColor.white
                    
                    switch indexPath.row {
                    case 0 :
                        cell      .textLabel!.text = "Sample"
                        cell.detailTextLabel!.text = ""
//                  case 1  :
                    default :
                        cell      .textLabel!.text = "Product Serial Number"
                        cell.detailTextLabel!.text = ""
                    }
                    
                    cell      .textLabel!.textColor = UIColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0)
                    cell.detailTextLabel!.textColor = UIColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0)
                case SectionIndex.bluetooth :
                    cell.backgroundColor = UIColor.white
                    
                    switch indexPath.row {
                    case 0 :
                        cell      .textLabel!.text = "Pairing and Connect Bluetooth"
                        cell.detailTextLabel!.text = ""
                    case 1 :
                        cell      .textLabel!.text = "Disconnect Bluetooth"
                        cell.detailTextLabel!.text = ""
//                  case 2  :
                    default :
                        cell      .textLabel!.text = "Bluetooth Setting"
                        cell.detailTextLabel!.text = ""
                    }
                    
                    cell      .textLabel!.textColor = UIColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0)
                    cell.detailTextLabel!.textColor = UIColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0)
//              case SectionIndex.appendix :
                default                    :
                    cell.backgroundColor = UIColor.white
                    
                    cell      .textLabel!.text = "Framework Version"
                    cell.detailTextLabel!.text = ""
                    
                    cell      .textLabel!.textColor = UIColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0)
                    cell.detailTextLabel!.textColor = UIColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0)
                }
                
                var userInteractionEnabled: Bool = true
                
                if let modelIndex = AppDelegate.getSelectedModelIndex() {
                    if let printerInfo = ModelCapability.modelCapabilityDictionary[modelIndex] {
                        switch (indexPath.section, indexPath.row) {
                        case (SectionIndex.cashDrawer.rawValue, _):
                            userInteractionEnabled = printerInfo.cashDrawerIsEnabled
                        case (SectionIndex.barcodeReader.rawValue, _):
                            userInteractionEnabled = printerInfo.barcodeReaderIsEnabled
                        case (SectionIndex.deviceStatus.rawValue, 1):   // Product Serial Number
                            let modelName = AppDelegate.getModelName()
                            if modelName.hasPrefix("TSP113 ") || modelName.hasPrefix("TSP143 ") {
                                userInteractionEnabled = false
                            } else {
                                userInteractionEnabled = printerInfo.productSerialNumberIsEnabled
                            }
                        case (SectionIndex.bluetooth.rawValue, 1):
                            userInteractionEnabled = printerInfo.supportBluetoothDisconnection
                        default:
                            break
                        }
                    } else {
                        userInteractionEnabled = false
                    }
                } else {
                    userInteractionEnabled = false
                }
                
                if indexPath.section == SectionIndex.bluetooth.rawValue {
                    if indexPath.row == 0 {     // Pairing and Connect Bluetooth
                        userInteractionEnabled = true
                    }
                    if indexPath.row == 1 {     // Disconnect Bluetooth
                        if AppDelegate.getPortName().hasPrefix("BT:") == false {
                            userInteractionEnabled = false
                        }
                    }
                    if indexPath.row == 2 {     // Bluetooth Setting
                        if AppDelegate.getPortName().hasPrefix("BT:")  == false &&
                           AppDelegate.getPortName().hasPrefix("BLE:") == false {
                            userInteractionEnabled = false
                        }
                    }
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
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let title: String!
        
        switch SectionIndex(rawValue: section)! {
        case SectionIndex.device :
            title = "Destination Device"
        case SectionIndex.printer :
            title = "Printer"
        case SectionIndex.cashDrawer :
            title = "Cash Drawer"
        case SectionIndex.barcodeReader :
            title = "Barcode Reader"
        case SectionIndex.deviceStatus :
            title = "Device Status"
        case SectionIndex.bluetooth :
            title = "Interface"
        }
        
        return title
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.deselectRow(at: indexPath, animated: true)
        
        self.selectedIndexPath = indexPath

        switch SectionIndex(rawValue: self.selectedIndexPath.section)! {
        case SectionIndex.device :
            self.performSegue(withIdentifier: "PushSearchPortViewController", sender: nil)
        case SectionIndex.printer :
            self.performSegue(withIdentifier: "PushPrinterViewController", sender: nil)
        case SectionIndex.cashDrawer :
            self.performSegue(withIdentifier: "PushCashDrawerViewController", sender: nil)
        case SectionIndex.barcodeReader:
             self.performSegue(withIdentifier: "PushBarcodeReaderExtViewController", sender: nil)
        case SectionIndex.deviceStatus :
            if self.selectedIndexPath.row == 0 {
                self.performSegue(withIdentifier: "PushDeviceStatusViewController", sender: nil)
            }
            else {
                self.confirmSerialNumber()
            }
        case SectionIndex.bluetooth :
            if self.selectedIndexPath.row == 0 {
                Communication.connectBluetooth({ (result: Bool, title: String?, message: String?) in
                    if title   != nil ||
                        message != nil {
                        self.showSimpleAlert(title: title,
                                             message: message,
                                             buttonTitle: "OK",
                                             buttonStyle: .cancel)
                    }
                })
            }
            else if self.selectedIndexPath.row == 1 {
                self.blind = true
                
                defer {
                    self.blind = false
                }
                
                let modelName:    String = AppDelegate.getModelName()
                let portName:     String = AppDelegate.getPortName()
                let portSettings: String = AppDelegate.getPortSettings()
                
                _ = Communication.disconnectBluetooth(modelName,
                                                      portName: portName,
                                                      portSettings: portSettings,
                                                      timeout: 10000,
                                                      completionHandler: { (result: Bool, title: String, message: String) in
                                                        self.showSimpleAlert(title: title,
                                                                             message: message,
                                                                             buttonTitle: "OK",
                                                                             buttonStyle: .cancel)
                })
            }
            else {
                self.performSegue(withIdentifier: "PushBluetoothSettingViewController", sender: nil)
            }
        }
    }
    
    fileprivate func confirmSerialNumber() {
        self.blind = true
        
        defer {
            self.blind = false
        }
        
        let portName:     String = AppDelegate.getPortName()
        let portSettings: String = AppDelegate.getPortSettings()
        let timeout:      UInt32 = 10000
        
        _ = Communication.confirmSerialNumber(portName,
                                              portSettings: portSettings,
                                              timeout: timeout,
                                              completionHandler: { (result: Bool, title: String, message: String) in
                                                self.showSimpleAlert(title: title,
                                                                     message: message,
                                                                     buttonTitle: "OK",
                                                                     buttonStyle: .cancel)
        })
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "PushSearchPortViewController":
            let vc = segue.destination as? SearchPortViewController
            if let vc = vc {
                vc.selectedPrinterIndex = self.selectedIndexPath.row
            }
        default:
            break
        }
    }
}
