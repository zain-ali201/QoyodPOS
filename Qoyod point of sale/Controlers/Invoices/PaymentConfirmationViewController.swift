//
//  PaymentConfirmationViewController.swift
//  Qoyod point of sale
//
//  Created by Sharjeel Ahmad on 05/09/2018.
//  Copyright © 2018 Sharjeel Ahmad. All rights reserved.
//

import UIKit

class PaymentConfirmationViewController: UIViewController, Epos2PtrReceiveDelegate
{
    @IBOutlet weak var lblMain: UILabel!
    @IBOutlet weak var customerNo: UILabel!
    @IBOutlet weak var customerName: UILabel!
    @IBOutlet weak var invoiceNo: UILabel!
    @IBOutlet weak var totalLabel: UILabel!
    @IBOutlet weak var lblPaid: UILabel!
    @IBOutlet weak var lblChange: UILabel!
    @IBOutlet weak var btnDone: UIButton!
    var mainView:UIView!
    var posInvoiceNo:String!
    var beforeTax:String!
    var afterTax:String!
    var tax:String!
    
    var starIoExtManager: StarIoExtManager!
    
    var invStatus:Int!
    
    //Epson outlets and variables
    let PAGE_AREA_HEIGHT: Int = 500
    let PAGE_AREA_WIDTH: Int = 500
    let FONT_A_HEIGHT: Int = 24
    let FONT_A_WIDTH: Int = 12
    let BARCODE_HEIGHT_POS: Int = 70
    let BARCODE_WIDTH_POS: Int = 110
    
    @IBOutlet weak var buttonDiscovery: UIButton!
    @IBOutlet weak var buttonLang: UIButton!
    @IBOutlet weak var buttonPrinterSeries: UIButton!
    @IBOutlet weak var buttonReceipt: UIButton!
    @IBOutlet weak var buttonCoupon: UIButton!
    
    var printerList: CustomPickerDataSource?
    var langList: CustomPickerDataSource?
    
    var printerPicker: CustomPickerView?
    var langPicker: CustomPickerView?
    
    var printer: Epos2Printer?
    
    var valuePrinterSeries: Epos2PrinterSeries = EPOS2_TM_M30
    var valuePrinterModel: Epos2ModelLang = EPOS2_MODEL_ANK
    
    var epsonPrinterFlag = false
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        lblMain.text = languageBundle!.localizedString(forKey: "Payment Confirmation", value: "", table: nil)
        
        btnDone.setTitle(languageBundle!.localizedString(forKey: "Done", value: "", table: nil), for: .normal)
        
        if AppDelegate.settingManager.settings[0] == nil
        {
            epsonPrinterFlag = runPrinterReceiptSequence()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    @IBAction func doneTapped(_ sender: UIButton)
    {
        if AppDelegate.settingManager.settings[0] != nil
        {
            showActivityIndicator()
            printStarRecipt()
        }
        else if epsonPrinterFlag
        {
            showActivityIndicator()
            printEpsonReceipt()
        }
        else
        {
            paidAmount = 0
            accountStr = ""
            changeAmount = 0
            dismissView()
        }
    }
    
    func dismissView()
    {
        UIView.animate(withDuration: 0.2, delay: 0, options: [], animations: {
            self.mainView.alpha = 0 // Here you will get the animation you want
        }, completion: { _ in
            self.mainView.isHidden = true // Here you hide it when animation done
            
            //reset selection
            NotificationCenter.default.post(name: Notification.Name.resetSelection, object: nil)
            NotificationCenter.default.post(name: Notification.Name.syncData, object: nil)
            
            //switch to paid invoices
            if let invoicesNav = self.tabBarController?.viewControllers?.first as? StyledNavigationController
            {
                if let invoiceVC = invoicesNav.viewControllers.first as? InvoicesViewController
                {
                    invoiceVC.pickerView(UIPickerView(), didSelectRow: self.invStatus, inComponent: 0)
                    invoiceVC.pickerView.selectRow(self.invStatus, inComponent: 0, animated: false)
                }
            }
            
            //swtich to invoices after creation
            self.tabBarController?.selectedIndex = 0
            self.navigationController?.popViewController(animated: false)
        })
    }
    
    func printStarRecipt()
    {
        if let invoiceToPrint = InvoicesManager.shared.invoiceToPrint
        {
            if let pos = invoiceToPrint.invoice.pos_invoice_no
            {
                if pos == posInvoiceNo
                {
                    sendCommand(invoice: invoiceToPrint)
                    print("Found invoice in cache")
                }
                else
                {
                    dismissView()
                }
            }
        }
        else
        {
            InvoicesManager.shared.getInvoice(posNumber: posInvoiceNo) {[weak self] (invoice, error) in
                if let invoiceToPrint = invoice
                {
                    self?.sendCommand(invoice: invoiceToPrint)
                }
                else
                {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: {
                        self?.printStarRecipt()
                    })
                }
            }
        }
    }
    
    func sendCommand(invoice:Invoice)
    {
        print("Printing invoice...")
        
        let emulation: StarIoExtEmulation = AppDelegate.getEmulation()
        
        let localizeReceipts: ILocalizeReceipts = LocalizeReceipts.createLocalizeReceipts(paperSizeIndex: AppDelegate.getSelectedPaperSize(), invoice: invoice , taxAmount: tax , subTotal: beforeTax, total: afterTax)
        
        let commands: Data = PrinterFunctions.createRasterReceiptData(emulation, localizeReceipts: localizeReceipts)
        
        let portName: String = AppDelegate.getPortName()
        let portSettings: String = AppDelegate.getPortSettings()
        
        GlobalQueueManager.shared.serialQueue.async {
            _ = Communication.sendCommands(commands,
                                           portName: portName,
                                           portSettings: portSettings,
                                           timeout: 10000,
                completionHandler: { (result: Bool, title: String, message: String) in
                    
                    print("result: \(result)")
                    print("title: \(title)")
                    print("message: \(message)")
                    DispatchQueue.main.async {
                        self.hideActivityIndicator()
                        self.dismissView()
                        paidAmount = 0
                        accountStr = ""
                        changeAmount = 0
                        totalamountWithTax = 0
                    }
            })
        }
    }

    // Epson Printer functions
    func printEpsonReceipt()
    {
        if let invoiceToPrint = InvoicesManager.shared.invoiceToPrint
        {
            if let pos = invoiceToPrint.invoice.pos_invoice_no
            {
                if pos == posInvoiceNo
                {
                    if !printData(invoice: invoiceToPrint) {
                        finalizePrinterObject()
                    }
                    else
                    {
                        DispatchQueue.main.async {
                            self.hideActivityIndicator()
                            self.dismissView()
                            paidAmount = 0
                            accountStr = ""
                            changeAmount = 0
                            totalamountWithTax = 0
                        }
                    }
                }
                else
                {
                    dismissView()
                }
            }
        }
        else
        {
            InvoicesManager.shared.getInvoice(posNumber: posInvoiceNo) {[weak self] (invoice, error) in
                if let invoiceToPrint = invoice
                {
                    if !(self?.printData(invoice: invoiceToPrint))! {
                        self?.finalizePrinterObject()
                    }
                    else
                    {
                        DispatchQueue.main.async {
                            self?.hideActivityIndicator()
                            self?.dismissView()
                            paidAmount = 0
                            accountStr = ""
                            changeAmount = 0
                            totalamountWithTax = 0
                        }
                    }
                }
                else
                {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: {
                        self?.printEpsonReceipt()
                    })
                }
            }
        }
    }
    
    func runPrinterReceiptSequence() -> Bool {
        
        if !initializePrinterObject() {
            return false
        }
        
        if !connectPrinter() {
            return false
        }
        
        return true
    }
    
    func runPrinterCouponSequence() -> Bool {
//        textWarnings.text = ""
//
//        if !initializePrinterObject() {
//            return false
//        }
//
//        if !createCouponData() {
//            finalizePrinterObject()
//            return false
//        }
        
//        if !printData() {
//            finalizePrinterObject()
//            return false
//        }
        
        return true
    }
    
    func createReceiptData(invoice:Invoice) -> Bool
    {
        var result = EPOS2_SUCCESS.rawValue
        
        let textData: NSMutableString = NSMutableString()
        
        result = printer!.addTextAlign(EPOS2_ALIGN_LEFT.rawValue)
        if result != EPOS2_SUCCESS.rawValue {
            MessageView.showErrorEpos(result, method:"addTextAlign")
            return false;
        }
        
        if (orgImage != nil)
        {
            result = printer!.add(orgImage, x: 0, y:0,
                                  width:Int(orgImage!.size.width),
                                  height:Int(orgImage!.size.height),
                                  color:EPOS2_COLOR_1.rawValue,
                                  mode:EPOS2_MODE_MONO.rawValue,
                                  halftone:EPOS2_HALFTONE_DITHER.rawValue,
                                  brightness:Double(EPOS2_PARAM_DEFAULT),
                                  compress:EPOS2_COMPRESS_AUTO.rawValue)
            
            if result != EPOS2_SUCCESS.rawValue {
                MessageView.showErrorEpos(result, method:"addImage")
                return false
            }
        }
        
        result = printer!.addFeedLine(1)
        if result != EPOS2_SUCCESS.rawValue {
            MessageView.showErrorEpos(result, method:"addFeedLine")
            return false
        }
        
        textData.append(UserDefaults.standard.string(forKey: UserDefaults.Key.orgName) ?? "")
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/YYYY"
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:MM"
        textData.append(String(format:"Date: %@    Time: %@\n",dateFormatter.string(from: Date()), timeFormatter.string(from: Date())));
        
        if receiptCount > 1
        {
            let accountsArray = accountStr.components(separatedBy: ",")
            
            for amountStr in accountsArray
            {
                if !amountStr.isEmpty
                {
                    textData.append(String(format:"%@\n", amountStr))
                }
            }
        }
        
        if changeAmount > 0
        {
            textData.append(String(format:"Change: %@\n", changeAmount))
        }
        textData.append("------------------------------\n")
        
        result = printer!.addText(textData as String)
        if result != EPOS2_SUCCESS.rawValue {
            MessageView.showErrorEpos(result, method:"addText")
            return false;
        }
        textData.setString("")
        
        // Section 2 : Purchaced items
        textData.append("Product     Quantity     Price\n");
        for product in invoice.invoice_products ?? [] {
            let name = product.name ?? "-"
            let quantity = product.quantity ?? "1.00"
            let price = product.row_total ?? "0.00"
            textData.append(String(format: "%@     %@     %@\n",name,quantity,price));
        }
        
        textData.append(String(format: "Sub Total: %@\n", beforeTax))
        textData.append(String(format: "Vat: %.@\n", tax))
        textData.append("--------------------------------\n")
        textData.append(String(format: "Total: %@\n", afterTax))
        textData.append("--------------------------------\n")
        
        if paidAmount < totalamountWithTax
        {
            textData.append(String(format: "%@ Paid: %.1f",paidAmount))
            textData.append(String(format: "%@ Remaining: %.1f",totalamountWithTax - paidAmount))
        }
        
        result = printer!.addText(textData as String)
        if result != EPOS2_SUCCESS.rawValue {
            MessageView.showErrorEpos(result, method:"addText")
            return false;
        }
        
        result = printer!.addCut(EPOS2_CUT_FEED.rawValue)
        if result != EPOS2_SUCCESS.rawValue {
            MessageView.showErrorEpos(result, method:"addCut")
            return false
        }
        
        return true
    }
    
    func printData(invoice: Invoice) -> Bool
    {
        var status: Epos2PrinterStatusInfo?
        
        if printer == nil {
            return false
        }
        
        if !createReceiptData(invoice: invoice) {
            finalizePrinterObject()
            return false
        }
        
        status = printer!.getStatus()
        dispPrinterWarnings(status)
        
        if !isPrintable(status) {
            MessageView.show(makeErrorMessage(status))
            printer!.disconnect()
            return false
        }
        
        let result = printer!.sendData(Int(EPOS2_PARAM_DEFAULT))
        if result != EPOS2_SUCCESS.rawValue {
            MessageView.showErrorEpos(result, method:"sendData")
            printer!.disconnect()
            return false
        }
        
        return true
    }
    
    func initializePrinterObject() -> Bool {
        printer = Epos2Printer(printerSeries: valuePrinterSeries.rawValue, lang: valuePrinterModel.rawValue)
        
        if printer == nil {
            return false
        }
        printer!.setReceiveEventDelegate(self)
        
        return true
    }
    
    func finalizePrinterObject() {
        if printer == nil {
            return
        }
        
        printer!.clearCommandBuffer()
        printer!.setReceiveEventDelegate(nil)
        printer = nil
    }
    
    func connectPrinter() -> Bool
    {
        var result: Int32 = EPOS2_SUCCESS.rawValue
        
        if printer == nil {
            return false
        }
        
        let target = UserDefaults.standard.string(forKey: "epsonTarget") ?? ""
        
        if !target.isEmpty
        {
            result = printer!.connect(target, timeout:Int(EPOS2_PARAM_DEFAULT))
            if result != EPOS2_SUCCESS.rawValue {
                //            MessageView.showErrorEpos(result, method:"connect")
                return false
            }
            
            result = printer!.beginTransaction()
            if result != EPOS2_SUCCESS.rawValue {
                //            MessageView.showErrorEpos(result, method:"beginTransaction")
                printer!.disconnect()
                return false
                
            }
        }
        else
        {
            return false
        }
        
        return true
    }
    
    func disconnectPrinter() {
        var result: Int32 = EPOS2_SUCCESS.rawValue
        
        if printer == nil {
            return
        }
        
        result = printer!.endTransaction()
        if result != EPOS2_SUCCESS.rawValue {
            DispatchQueue.main.async(execute: {
                MessageView.showErrorEpos(result, method:"endTransaction")
            })
        }
        
        result = printer!.disconnect()
        if result != EPOS2_SUCCESS.rawValue {
            DispatchQueue.main.async(execute: {
                MessageView.showErrorEpos(result, method:"disconnect")
            })
        }
        
        finalizePrinterObject()
    }
    func isPrintable(_ status: Epos2PrinterStatusInfo?) -> Bool {
        if status == nil {
            return false
        }
        
        if status!.connection == EPOS2_FALSE {
            return false
        }
        else if status!.online == EPOS2_FALSE {
            return false
        }
        else {
            // print available
        }
        return true
    }
    
    func onPtrReceive(_ printerObj: Epos2Printer!, code: Int32, status: Epos2PrinterStatusInfo!, printJobId: String!) {
        MessageView.showResult(code, errMessage: makeErrorMessage(status))
        
        dispPrinterWarnings(status)
        
        DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async(execute: {
            self.disconnectPrinter()
        })
    }
    
    func dispPrinterWarnings(_ status: Epos2PrinterStatusInfo?) {
        if status == nil {
            return
        }
        
//        textWarnings.text = ""
        
        if status!.paper == EPOS2_PAPER_NEAR_END.rawValue {
//            textWarnings.text = NSLocalizedString("warn_receipt_near_end", comment:"")
        }
        
        if status!.batteryLevel == EPOS2_BATTERY_LEVEL_1.rawValue {
//            textWarnings.text = NSLocalizedString("warn_battery_near_end", comment:"")
        }
    }
    
    func makeErrorMessage(_ status: Epos2PrinterStatusInfo?) -> String {
        let errMsg = NSMutableString()
        if status == nil {
            return ""
        }
        
        if status!.online == EPOS2_FALSE {
            errMsg.append(NSLocalizedString("err_offline", comment:""))
        }
        if status!.connection == EPOS2_FALSE {
            errMsg.append(NSLocalizedString("err_no_response", comment:""))
        }
        if status!.coverOpen == EPOS2_TRUE {
            errMsg.append(NSLocalizedString("err_cover_open", comment:""))
        }
        if status!.paper == EPOS2_PAPER_EMPTY.rawValue {
            errMsg.append(NSLocalizedString("err_receipt_end", comment:""))
        }
        if status!.paperFeed == EPOS2_TRUE || status!.panelSwitch == EPOS2_SWITCH_ON.rawValue {
            errMsg.append(NSLocalizedString("err_paper_feed", comment:""))
        }
        if status!.errorStatus == EPOS2_MECHANICAL_ERR.rawValue || status!.errorStatus == EPOS2_AUTOCUTTER_ERR.rawValue {
            errMsg.append(NSLocalizedString("err_autocutter", comment:""))
            errMsg.append(NSLocalizedString("err_need_recover", comment:""))
        }
        if status!.errorStatus == EPOS2_UNRECOVER_ERR.rawValue {
            errMsg.append(NSLocalizedString("err_unrecover", comment:""))
        }
        
        if status!.errorStatus == EPOS2_AUTORECOVER_ERR.rawValue
        {
            if status!.autoRecoverError == EPOS2_HEAD_OVERHEAT.rawValue {
                errMsg.append(NSLocalizedString("err_overheat", comment:""))
                errMsg.append(NSLocalizedString("err_head", comment:""))
            }
            if status!.autoRecoverError == EPOS2_MOTOR_OVERHEAT.rawValue {
                errMsg.append(NSLocalizedString("err_overheat", comment:""))
                errMsg.append(NSLocalizedString("err_motor", comment:""))
            }
            if status!.autoRecoverError == EPOS2_BATTERY_OVERHEAT.rawValue {
                errMsg.append(NSLocalizedString("err_overheat", comment:""))
                errMsg.append(NSLocalizedString("err_battery", comment:""))
            }
            if status!.autoRecoverError == EPOS2_WRONG_PAPER.rawValue {
                errMsg.append(NSLocalizedString("err_wrong_paper", comment:""))
            }
        }
        if status!.batteryLevel == EPOS2_BATTERY_LEVEL_0.rawValue {
            errMsg.append(NSLocalizedString("err_battery_real_end", comment:""))
        }
        
        return errMsg as String
    }
}
