//
//  SearchPortViewController.swift
//  Swift SDK
//
//  Created by Yuji on 2015/**/**.
//  Copyright © 2015年 Star Micronics. All rights reserved.
//

import UIKit

class SearchPortViewController: CommonViewController, UITableViewDelegate, UITableViewDataSource {
    enum CellParamIndex: Int {
        case portName = 0
        case modelName
        case macAddress
    }
    
    @IBOutlet weak var tableView: UITableView!
    
    var cellArray: NSMutableArray!
    
    var selectedIndexPath: IndexPath!
    
    var didAppear: Bool!
    
    var portName:     String!
    var portSettings: String!
    var modelName:    String!
    var macAddress:   String!
    var paperSizeIndex: PaperSizeIndex? = nil
    
    var emulation: StarIoExtEmulation!
    
    var selectedModelIndex: ModelIndex?
    
    var selectedPrinterIndex: Int = 0
    
    var currentSetting: PrinterSetting? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.appendRefreshButton(#selector(SearchPortViewController.refreshPortInfo))
        
        self.cellArray = NSMutableArray()
        
        self.selectedIndexPath = nil
        
        self.didAppear = false
        
        self.currentSetting = AppDelegate.settingManager.settings[selectedPrinterIndex]
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if didAppear == false {
            self.refreshPortInfo()
            
            self.didAppear = true
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.cellArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier: String = "UITableViewCellStyleSubtitle"
        
        var cell: UITableViewCell! = self.tableView.dequeueReusableCell(withIdentifier: cellIdentifier)
        
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: cellIdentifier)
        }
        
        if cell != nil {
            let cellParam: [String] = self.cellArray[indexPath.row] as! [String]
            
            cell.textLabel!.text = cellParam[CellParamIndex.modelName.rawValue]
            
            if cellParam[CellParamIndex.macAddress.rawValue] == "" {
                cell.detailTextLabel!.text = cellParam[CellParamIndex.portName.rawValue]
            }
            else {
                cell.detailTextLabel!.text = "\(cellParam[CellParamIndex.portName.rawValue]) (\(cellParam[CellParamIndex.macAddress.rawValue]))"
            }
            
            cell      .textLabel!.textColor = UIColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0)
            cell.detailTextLabel!.textColor = UIColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0)
            
            cell.accessoryType = UITableViewCellAccessoryType.none
            
            if cellParam[CellParamIndex.portName.rawValue] == AppDelegate.settingManager.settings[self.selectedPrinterIndex]?.portName {
                cell.accessoryType = .checkmark
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "List"
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        var cell: UITableViewCell!
        
        if self.selectedIndexPath != nil {
            cell = tableView.cellForRow(at: self.selectedIndexPath)
            
            if cell != nil {
                cell.accessoryType = UITableViewCellAccessoryType.none
            }
        }
        
        cell = tableView.cellForRow(at: indexPath)!
        
        _ = tableView.visibleCells.map{ $0.accessoryType = .none }
        cell.accessoryType = UITableViewCellAccessoryType.checkmark
        
        self.selectedIndexPath = indexPath
        
        let cellParam: [String] = self.cellArray[self.selectedIndexPath.row] as! [String]
        
        let modelName:  String = cellParam[CellParamIndex.modelName.rawValue]
        
        let modelIndex = ModelCapability.modelIndex(of: modelName)
        
        if let modelIndex = modelIndex {
            self.selectedModelIndex = modelIndex
            
            guard let title = ModelCapability.title(at: modelIndex) else {
                fatalError()
            }
            
            let alert = UIAlertController(title: languageBundle!.localizedString(forKey: "Confirm.", value: "", table: nil),
                                          message: "\(languageBundle!.localizedString(forKey: "Is your printer", value: "", table: nil)) \(title)?",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: languageBundle!.localizedString(forKey: "YES", value: "", table: nil), style: .default, handler: { _ in
                self.didConfirmModel(buttonIndex: 1)
            }))
            alert.addAction(UIAlertAction(title: languageBundle!.localizedString(forKey: "NO", value: "", table: nil), style: .cancel, handler: { _ in
                self.didConfirmModel(buttonIndex: 0)
            }))

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                printerFlag = true
                self.present(alert, animated: true, completion: nil)
            }
        }
        else
        {
            let alert = UIAlertController(title: languageBundle!.localizedString(forKey: "Confirm.", value: "", table: nil),
                                          message: languageBundle!.localizedString(forKey: "What is your printer?", value: "", table: nil),
                                          preferredStyle: .alert)
            
            for i: Int in 0..<ModelCapability.modelIndexCount() {
                let modelIndex: ModelIndex = ModelCapability.modelIndex(at: i)
                let title: String? = ModelCapability.title(at: modelIndex)
                
                alert.addAction(UIAlertAction(title: title, style: .default, handler: { _ in
                    self.didSelectModel(buttonIndex: i + 1)
                }))
            }
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                printerFlag = true
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    @objc func refreshPortInfo() {
        let alert = UIAlertController(title: languageBundle!.localizedString(forKey: "Select Interface.", value: "", table: nil),
                                      message: nil,
                                      preferredStyle: .alert)
        let buttonTitles = [languageBundle!.localizedString(forKey: "LAN", value: "", table: nil), languageBundle!.localizedString(forKey: "Bluetooth", value: "", table: nil) , languageBundle!.localizedString(forKey: "Bluetooth Low Energy", value: "", table: nil) ,languageBundle!.localizedString(forKey: "USB", value: "", table: nil), languageBundle!.localizedString(forKey: "All", value: "", table: nil)]
        for i in 0..<buttonTitles.count {
            alert.addAction(UIAlertAction(title: buttonTitles[i], style: .default, handler: { _ in
                self.didSelectRefreshPortInterfaceType(buttonIndex: i + 1)
            }))
        }
        
        alert.addAction(UIAlertAction(title: languageBundle!.localizedString(forKey: "Manual", value: "", table: nil), style: .default, handler: { _ in
            self.didSelectManualInput()
        }))
        
        alert.addAction(UIAlertAction(title: languageBundle!.localizedString(forKey: "Cancel", value: "", table: nil), style: .cancel, handler: { _ in
            self.navigationController!.popViewController(animated: true)
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func modelSelect1AlertClickedButtonAt(buttonIndex: Int?) {
        if buttonIndex != 0 {   // Not cancel
            let modelIndex = ModelCapability.modelIndex(at: buttonIndex! - 1)
            
            self.modelName    = ModelCapability.title(at: modelIndex)
            self.macAddress   = self.portSettings                                        // for display.
            self.emulation    = ModelCapability.emulation(at: modelIndex)
            self.selectedModelIndex = modelIndex
            
            self.paperSizeIndex = .twoInch
            
            if self.paperSizeIndex == nil {
                
            } else {
                if ModelCapability.supportedExternalCashDrawer(at: modelIndex) == true {
                    self.showAlert(title: languageBundle!.localizedString(forKey: "Select CashDrawer Open Status.", value: "", table: nil),
                                   buttonTitles: [languageBundle!.localizedString(forKey: "High when Open", value: "", table: nil), languageBundle!.localizedString(forKey: "Low when Open", value: "", table: nil)],
                                   handler: { selectedButtonIndex in
                                    self.didSelectCashDrawerOpenActiveHigh(buttonIndex: selectedButtonIndex)
                    })
                }
                else {
                    self.saveParams(portName: self.portName,
                                    portSettings: self.portSettings,
                                    modelName: self.modelName,
                                    macAddress: self.macAddress,
                                    emulation: self.emulation,
                                    isCashDrawerOpenActiveHigh: true,
                                    modelIndex: self.selectedModelIndex)
                    
                    self.navigationController!.popViewController(animated: true)
                }
            }
        }
    }
    
    fileprivate func saveParams(portName: String,
                                portSettings: String,
                                modelName: String,
                                macAddress: String,
                                emulation: StarIoExtEmulation,
                                isCashDrawerOpenActiveHigh: Bool,
                                modelIndex: ModelIndex?) {
        if let modelIndex = modelIndex {
            let allReceiptsSetting = AppDelegate.settingManager.settings[selectedPrinterIndex]?.allReceiptsSettings ?? 0x07
            
            AppDelegate.settingManager.settings[selectedPrinterIndex] = PrinterSetting(portName: portName,
                                                                                       portSettings: portSettings,
                                                                                       macAddress: macAddress,
                                                                                       modelName: modelName,
                                                                                       emulation: emulation,
                                                                                       cashDrawerOpenActiveHigh: isCashDrawerOpenActiveHigh,
                                                                                       allReceiptsSettings: allReceiptsSetting,
                                                                                       selectedModelIndex: modelIndex)
            
            AppDelegate.settingManager.save()
        } else {
            fatalError()
        }
    }
    
    fileprivate func didSelectCashDrawerOpenActiveHigh(buttonIndex: Int) {
        let isCashDrawerOpenActiveHigh: Bool
        
        if buttonIndex == 1 {     // High when Open
            isCashDrawerOpenActiveHigh = true
        }
        else if buttonIndex == 2 {     // Low when Open
            isCashDrawerOpenActiveHigh = false
        } else {
            fatalError()
        }
        
        self.saveParams(portName: self.portName,
                        portSettings: self.portSettings,
                        modelName: self.modelName,
                        macAddress: self.macAddress,
                        emulation: self.emulation,
                        isCashDrawerOpenActiveHigh: isCashDrawerOpenActiveHigh,
                        modelIndex: self.selectedModelIndex)
        
        self.navigationController!.popViewController(animated: true)
    }
    
    fileprivate func didSelectPaperSize(buttonIndex: Int) {
        self.paperSizeIndex = .twoInch
        
        guard let modelIndex = self.selectedModelIndex else {
            fatalError()
        }
        
        if ModelCapability.supportedExternalCashDrawer(at: modelIndex) == true {
            self.showAlert(title: languageBundle!.localizedString(forKey: "Select CashDrawer Open Status.", value: "", table: nil),
                           buttonTitles: ["High when Open", "Low when Open"],
                           handler: { selectedButtonIndex in
                            self.didSelectCashDrawerOpenActiveHigh(buttonIndex: selectedButtonIndex)
            })
        }
        else {
            self.saveParams(portName: self.portName,
                            portSettings: self.portSettings,
                            modelName: self.modelName,
                            macAddress: self.macAddress,
                            emulation: self.emulation,
                            isCashDrawerOpenActiveHigh: true,
                            modelIndex: self.selectedModelIndex)
            
            self.navigationController!.popViewController(animated: true)
        }
    }
    
    func didConfirmModel(buttonIndex: Int) {
        if buttonIndex == 1 {     // YES
            let cellParam: [String] = self.cellArray[self.selectedIndexPath.row] as! [String]
            
            self.portName   = cellParam[CellParamIndex.portName  .rawValue]
            self.modelName  = cellParam[CellParamIndex.modelName .rawValue]
            self.macAddress = cellParam[CellParamIndex.macAddress.rawValue]
            
            guard let modelIndex = ModelCapability.modelIndex(of: self.modelName) else {
                fatalError()
            }
            
            self.portSettings = ModelCapability.portSettings(at: modelIndex)
            self.emulation = ModelCapability.emulation(at: modelIndex)
            self.selectedModelIndex = modelIndex
            
            self.paperSizeIndex = .twoInch
            
            if self.paperSizeIndex == nil {
                
            } else {
                if ModelCapability.supportedExternalCashDrawer(at: modelIndex) == true {
                    self.showAlert(title: languageBundle!.localizedString(forKey: "Select CashDrawer Open Status.", value: "", table: nil),
                                   buttonTitles: [languageBundle!.localizedString(forKey: "High when Open", value: "", table: nil) , languageBundle!.localizedString(forKey: "Low when Open", value: "", table: nil)],
                                   handler: { selectedButtonIndex in
                                    self.didSelectCashDrawerOpenActiveHigh(buttonIndex: selectedButtonIndex)
                    })
                } else {
                    self.saveParams(portName: self.portName,
                                    portSettings: self.portSettings,
                                    modelName: self.modelName,
                                    macAddress: self.macAddress,
                                    emulation: self.emulation,
                                    isCashDrawerOpenActiveHigh: true,
                                    modelIndex: self.selectedModelIndex)
                    
                    self.navigationController!.popViewController(animated: true)
                }
            }
        }
        else {     // NO
            let alert = UIAlertController(title: languageBundle!.localizedString(forKey: "Confirm.", value: "", table: nil),
                                          message: languageBundle!.localizedString(forKey: "What is your printer?", value: "", table: nil),
                                          preferredStyle: .alert)
            
            for i: Int in 0..<ModelCapability.modelIndexCount() {
                let modelIndex: ModelIndex = ModelCapability.modelIndex(at: i)
                let title: String? = ModelCapability.title(at: modelIndex)
                
                alert.addAction(UIAlertAction(title: title, style: .default, handler: { _ in
                    self.didSelectModel(buttonIndex: i + 1)
                }))
            }
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func didSelectModel(buttonIndex: Int) {
        let cellParam: [String] = self.cellArray[self.selectedIndexPath.row] as! [String]
        
        self.portName   = cellParam[CellParamIndex.portName  .rawValue]
        self.modelName  = cellParam[CellParamIndex.modelName .rawValue]
        self.macAddress = cellParam[CellParamIndex.macAddress.rawValue]
        
        let modelIndex: ModelIndex = ModelCapability.modelIndex(at: buttonIndex - 1)
        
        self.portSettings = ModelCapability.portSettings(at: modelIndex)
        self.emulation = ModelCapability.emulation(at: modelIndex)
        self.selectedModelIndex = modelIndex
        
        let supportedExternalCashDrawer = ModelCapability.supportedExternalCashDrawer(at: modelIndex)!
        
        self.paperSizeIndex = .twoInch
        
        
        if self.paperSizeIndex == nil {

        } else {
            if supportedExternalCashDrawer == true {
                self.showAlert(title: languageBundle!.localizedString(forKey: "Select CashDrawer Open Status.", value: "", table: nil),
                               buttonTitles: [languageBundle!.localizedString(forKey: "High when Open", value: "", table: nil), languageBundle!.localizedString(forKey: "Low when Open", value: "", table: nil)],
                               handler: { selectedButtonIndex in
                                self.didSelectCashDrawerOpenActiveHigh(buttonIndex: selectedButtonIndex)
                })
            } else {
                self.saveParams(portName: self.portName,
                                portSettings: self.portSettings,
                                modelName: self.modelName,
                                macAddress: self.macAddress,
                                emulation: self.emulation,
                                isCashDrawerOpenActiveHigh: true,
                                modelIndex: self.selectedModelIndex)
                
                self.navigationController!.popViewController(animated: true)
            }
        }
    }
    
    func didInputPortName(portName: String) {
        self.portName = portName
        
        if self.portName == "" {
            let alert = UIAlertController(title: languageBundle!.localizedString(forKey: "Please enter the port name.", value: "", table: nil),
                                          message: languageBundle!.localizedString(forKey: "Fill in the port name.", value: "", table: nil),
                                          preferredStyle: .alert)
            alert.addTextField { textField in
                textField.text = self.currentSetting?.portName ?? ""
            }
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                if let newPortName = alert.textFields?.first?.text {
                    self.didInputPortName(portName: newPortName)
                }
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
                self.navigationController!.popViewController(animated: true)
            }))
            
            self.present(alert, animated: true, completion: nil)
        }
        else {
            let alert = UIAlertController(title: languageBundle!.localizedString(forKey: "Please enter the port settings.", value: "", table: nil),
                                          message: nil,
                                          preferredStyle: .alert)
            alert.addTextField { textField in
                textField.text = self.currentSetting?.portSettings ?? ""
            }
            
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                if let newPortSettings = alert.textFields?.first?.text {
                    self.didInputPortSettings(portSettings: newPortSettings)
                }
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: {_ in
                self.navigationController!.popViewController(animated: true)
            }))
            
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func didInputPortSettings(portSettings: String) {
        self.portSettings = portSettings
        
        let nestAlertController = UIAlertController(title: languageBundle!.localizedString(forKey: "Confirm.", value: "", table: nil),
                                                    message: languageBundle!.localizedString(forKey: "What is your printer?", value: "", table: nil),
                                                    preferredStyle: .alert)
        
        let handler = { (action: UIAlertAction!) in
            let buttonIndex = nestAlertController.actions.index(of: action)
            
            self.modelSelect1AlertClickedButtonAt(buttonIndex: buttonIndex)
        }
        
        nestAlertController.addAction(UIAlertAction(title: "Cancel",
                                                    style: .cancel,
                                                    handler: handler))
        
        for i: Int in 0 ..< ModelCapability.modelIndexCount() {
            let modelIndex: ModelIndex = ModelCapability.modelIndex(at: i)
            let title: String? = ModelCapability.title(at: modelIndex)
            let action: UIAlertAction = UIAlertAction(title: title,
                                                      style: .default,
                                                      handler: handler)
            nestAlertController.addAction(action)
        }
        
        present(nestAlertController, animated: true, completion: nil)
    }
    
    func didSelectRefreshPortInterfaceType(buttonIndex: Int) {
        self.blind = true
        
        defer {
            self.blind = false
        }
        
        self.cellArray.removeAllObjects()
        
        self.selectedIndexPath = nil
        
        let searchPrinterResult: [PortInfo]?
        
        switch buttonIndex {
        case 1  :     // LAN
            searchPrinterResult = SMPort.searchPrinter("TCP:") as? [PortInfo]
        case 2  :     // Bluetooth
            searchPrinterResult = SMPort.searchPrinter("BT:")  as? [PortInfo]
        case 3  :     // Bluetooth Low Energy
            searchPrinterResult = SMPort.searchPrinter("BLE:") as? [PortInfo]
        case 4  :     // USB
            searchPrinterResult = SMPort.searchPrinter("USB:") as? [PortInfo]
        //              case 5  :     // All
        default :
            searchPrinterResult = SMPort.searchPrinter()       as? [PortInfo]
        }
        
        guard let portInfoArray: [PortInfo] = searchPrinterResult else {
            self.tableView.reloadData()
            return
        }
        
        let portName:   String = currentSetting?.portName ?? ""
        let modelName:  String = currentSetting?.portSettings ?? ""
        let macAddress: String = currentSetting?.macAddress ?? ""
        
        var row: Int = 0
        
        for portInfo: PortInfo in portInfoArray {
            self.cellArray.add([portInfo.portName, portInfo.modelName, portInfo.macAddress])
            
            if portInfo.portName   == portName  &&
                portInfo.modelName  == modelName &&
                portInfo.macAddress == macAddress {
                self.selectedIndexPath = IndexPath(row: row, section: 0)
            }
            
            row += 1
        }
        
        self.tableView.reloadData()
    }
    
    func didSelectManualInput() {
        let alert = UIAlertController(title: languageBundle!.localizedString(forKey: "Please enter the port name.", value: "", table: nil),
                                      message: nil,
                                      preferredStyle: .alert)
        alert.addTextField { textField in
            textField.text = self.currentSetting?.portName ?? ""
        }
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            if let portName = alert.textFields?.first?.text {
                self.didInputPortName(portName: portName)
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
            self.navigationController!.popViewController(animated: true)
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
}
