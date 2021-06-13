//
//  CartViewController.swift
//  Qoyod point of sale
//
//  Created by Sharjeel Ahmad on 05/09/2018.
//  Copyright © 2018 Sharjeel Ahmad. All rights reserved.
//

import UIKit

var receiptCount = 0
var accountStr = ""
var paidAmount = 0.0
var changeAmount = 0.0
var totalamountWithTax = 0.0

var selectedContact:Contact!

class CartTableViewCell: UITableViewCell
{
    @IBOutlet weak var imgView: UIImageView!
    @IBOutlet weak var rate: UILabel!
    @IBOutlet weak var amount: UILabel!
    @IBOutlet weak var quantity: UILabel!
    @IBOutlet weak var percentage: UILabel!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var quantityV: UILabel!
    @IBOutlet weak var stock: UILabel!
    @IBOutlet weak var sku: UILabel!
    @IBOutlet weak var lblTax: UILabel!
    @IBOutlet weak var unitBtn: UIButton!
}

struct Unit
{
    var product_id: Int
    var id: Int
    var rate: String
    var name: String
}

class CartViewController: UIViewController
{
    //Invoice selected on previous screen
    var selectedProducts:[Product] = []
    var contacts:[Contact] = []
    var unitsArray:[Unit] = []
    var taxes:[Tax]!
    var totalPayable = 0.0
    var actuallTotal = 0.0
    
    var selectedProd:Product!
    var productView:ProductsViewController!
    var prevProdID:Int!
    
    @IBOutlet weak var lblCustomerPhone: UILabel!
    @IBOutlet weak var lblPOSInvoice: UILabel!
    @IBOutlet weak var customerPhone: UILabel!
    @IBOutlet weak var invoiceNo: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var beforeTax: UILabel!
    @IBOutlet weak var taxAmount: UILabel!
    @IBOutlet weak var total: UILabel!
    @IBOutlet weak var payButton: UIButton!
    @IBOutlet weak var paymentView: UIView!
    @IBOutlet weak var paymentSuccessView: UIView!
    @IBOutlet weak var payLaterButton: UIButton!
    @IBOutlet weak var userName: UILabel!
    @IBOutlet weak var tableViewBackground: UIView!
    @IBOutlet weak var scannedProductsTableView: UITableView!
    
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var lblTaxTitle: UILabel!
    @IBOutlet weak var lblAmountTitle: UILabel!
    @IBOutlet weak var lblTotalTitle: UILabel!
    @IBOutlet weak var customerBtn: UIButton!
    
    lazy fileprivate var pickerTextField = UITextField()
    
    var paymentDialog:PaymentViewController!
    var paymentSuccessDialog:PaymentConfirmationViewController!
    
    //star bar code reader
    var starIoExtManager: StarIoExtManager!
    var scannedVolume = 1.0
    fileprivate lazy var scannedProducts:[Product] = []
    
    let windowCount = UIApplication.shared.windows.count
    
    var count = 0
    
    var pickerTag = 1
    
    var pickerRow = 0
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        payLaterButton.layer.borderColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        cartVC = self
        
        let contactID:Int = UserDefaults.standard.integer(forKey: "SelectedContact")
        
        if contactID > 0
        {
            let contactFounds = contacts.filter { (contact) -> Bool in
                return contact.id == contactID
            }
            
            selectedContact = contactFounds.first
        }
        else
        {
            selectedContact = contacts.first
        }
        
        loadData()
        
        //for customer picker
        pickerTextField.isHidden = true
        view.addSubview(pickerTextField)
        createPickerView(textField: pickerTextField)
        
        //Loading Invoice details
        invoiceNo.text = generateInvoiceNo(min: 10000, max: 600000)
        
        //bar code printer
        self.starIoExtManager = StarIoExtManager(type: StarIoExtManagerType.standard,
                                                 portName: AppDelegate.getPortName(),
                                                 portSettings: AppDelegate.getPortSettings(),
                                                 ioTimeoutMillis: 10000)                                      // 10000mS!!!
        
        self.starIoExtManager.cashDrawerOpenActiveHigh = AppDelegate.getCashDrawerOpenActiveHigh()
        
        self.starIoExtManager.delegate = self
        
        UIApplication.shared.windows[windowCount-1].makeToast(languageBundle!.localizedString(forKey: "You can deselect the product by swiping it to right.", value: "", table: nil))
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
//        NotificationCenter.default.addObserver(self, selector: #selector(ProductsViewController.applicationWillResignActive), name: NSNotification.Name(rawValue: "UIApplicationWillResignActiveNotification"), object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(ProductsViewController.applicationDidBecomeActive),  name: NSNotification.Name(rawValue: "UIApplicationDidBecomeActiveNotification"),  object: nil)
        
//        GlobalQueueManager.shared.serialQueue.async {
//            DispatchQueue.main.async {
//                self.starIoExtManager.disconnect()
//
//                if self.starIoExtManager.connect() == false {
//                    self.showMessage("Fail to Open Port.")
//                }
//                else
//                {
//                    print("Printer connected.....")
//                }
//            }
//        }
        
        lblCustomerPhone.text = "\(languageBundle!.localizedString(forKey: "Customer Phone", value: "", table: nil))#"
        lblPOSInvoice.text = "\(languageBundle!.localizedString(forKey: "POS Invoice", value: "", table: nil))#"
        lblTitle.text = languageBundle!.localizedString(forKey: "Cart", value: "", table: nil)
        lblAmountTitle.text = languageBundle!.localizedString(forKey: "Tax Amount", value: "", table: nil)
        lblTaxTitle.text = languageBundle!.localizedString(forKey: "Before Tax", value: "", table: nil)
        lblTotalTitle.text = languageBundle!.localizedString(forKey: "Total", value: "", table: nil)
        payLaterButton.setTitle(languageBundle!.localizedString(forKey: "Pay Later", value: "", table: nil), for: .normal)
        customerBtn.setTitle(languageBundle!.localizedString(forKey: "NEW CUSTOMER", value: "", table: nil), for: .normal)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
//        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "UIApplicationWillResignActiveNotification"), object: nil)
//        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "UIApplicationDidBecomeActiveNotification"),  object: nil)
        
        GlobalQueueManager.shared.serialQueue.async {
            self.starIoExtManager.disconnect()
        }
    }
    
    func refreshCustomer() {
        selectedContact = contacts.last
        loadCustomer()
    }
    
//    @objc func applicationDidBecomeActive() {
//        GlobalQueueManager.shared.serialQueue.async {
//            DispatchQueue.main.async {
//                self.refreshPrinter()
//            }
//        }
//    }
//
//    @objc func applicationWillResignActive() {
//        GlobalQueueManager.shared.serialQueue.async {
//            self.starIoExtManager.disconnect()
//        }
//    }
//
//    @objc func refreshPrinter() {
//        self.starIoExtManager.disconnect()
//
//        if self.starIoExtManager.connect() == false {
//            showMessage("Fail to Open Port.")
//        }
//    }
    
    func loadCartData()
    {
        if count > 0
        {
            print("Count Selected: \(count)")
            loadData()
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
        else
        {
            navigationController?.popViewController(animated: true)
        }
    }
    
    @IBAction func backTapped(_ sender: UIButton)
    {
        productView.selectedProducts = selectedProducts
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func contactSearchTapped(_ sender: UIButton) {
    }
    
    @IBAction func searchTaped(_ sender: UIButton)
    {
        
    }
    
    @IBAction func userNameTapped(_ sender: UIButton)
    {
        pickerTag = 1
        pickerTextField.becomeFirstResponder()
    }
    
    @IBAction func newCustomerTapped(_ sender: UIButton) {
        
    }
    
    @IBAction func increaseQuantity(_ sender: UIButton)
    {
        if let cell = sender.superview?.superview?.superview as? CartTableViewCell {
            if let indexPath = tableView.indexPath(for: cell) {
                let product = selectedProducts[indexPath.row]
                
                var val = 1.0
//                if let quantity = Double(product.created_at ?? "0.0") {
//                    val = quantity
//                }
                
                if verifyProduct(product: product)
                {
                    if product.current_stock != nil
                    {
//                        let stock = Double(product.current_stock!) ?? 0
//
//                        if val < stock
                        
                        let stock = Double(product.current_stock!) ?? 0
                        
                        if let quantity = Double(product.created_at ?? "0.0") {
                            val = quantity
                        }
                        
                        var increment = 0.0
                        if let rateVal = Double(product.unit_representation) {
                            increment = rateVal
                        }
                        
                        let qty = (val + 1) * increment
                        
                        if qty < stock
                        {
                            newFlag = false
                            product.created_at = "\(val + 1)"
                            
                            tableView.reloadData()
                            loadData()
                        }
                        else
                        {
                            self.view.makeToast(languageBundle!.localizedString(forKey: "Product is out of stock", value: "", table: nil))
                        }
                    }
                }
                else
                {
                    product.created_at = "\(val + 1)"
                    tableView.reloadData()
                    loadData()
                }
            }
        }
    }
    
    @IBAction func decreaseQuantity(_ sender: UIButton)
    {
        if let cell = sender.superview?.superview?.superview as? CartTableViewCell {
            if let indexPath = tableView.indexPath(for: cell) {
                let product = selectedProducts[indexPath.row]
                
                var val = 1.0
                if let quantity = Double(product.created_at ?? "0.0") {
                    val = quantity
                }
                val -= 1.0
//                let parts = String(val).components(separatedBy: ".")
                
                if val <= 0
                {
                    let alert = UIAlertController(title: "" , message: languageBundle!.localizedString(forKey: languageBundle!.localizedString(forKey: "Quantity cannot be zero. Do you want to deselect this product?", value: "", table: nil), value: "", table: nil), preferredStyle: UIAlertControllerStyle.alert)
                    
                    alert.addAction(UIAlertAction(title: "YES", style: .default, handler: { action in
                        self.selectedProducts.remove(at: indexPath.row)
                        self.tableView.reloadData()
                        self.loadData()
                    }))
                    
                    alert.addAction(UIAlertAction(title: "NO", style: .cancel, handler: { action in
                        
                    }))
                    
                    self.present(alert, animated: true, completion: nil)
                }
                else
                {
                    newFlag = false
                    product.created_at = "\(val)"
                    
                    tableView.reloadData()
                    loadData()
                }
            }
        }
    }
    
    @IBAction func changeDiscount(_ sender: UIButton) {
        newFlag = true
    }
    
    @IBAction func changePriceBtnAction(_ sender: UIButton) {
        
    }
    
    @IBAction func changeTaxAction(_ sender: UIButton) {
        newFlag = false
    }
    
    @IBAction func payLaterTapped(_ sender: UIButton)
    {
        if self.starIoExtManager.connect() == false
        {
            self.view.makeToast(languageBundle!.localizedString(forKey: "Printer is not connected.", value: "", table: nil))
        }
        else
        {
            self.starIoExtManager.disconnect()
        }
        
        if selectedProducts.count > 0
        {
            if selectedContact != nil
            {
                showActivityIndicator()
                sender.isUserInteractionEnabled = false
                InvoicesManager.shared.createInvoiceWithStatus(invoiceNo: invoiceNo.text!, contact: selectedContact, products: selectedProducts, status: .unpaid, totalAmount: "\(totalPayable)", totalPaidAmount:  "0", accounts: []) {[weak self] (message, error) in
                    self?.hideActivityIndicator()
                    sender.isUserInteractionEnabled = true
                    if let error = error {
                        self?.show(error: error)
                    }else if let message = message {
                        self?.showMessage(message)
                        //reset selection
                        self?.selectedProducts.removeAll()
                        self?.loadData()
                        NotificationCenter.default.post(name: Notification.Name.resetSelection, object: nil)
                        NotificationCenter.default.post(name: Notification.Name.syncData, object: nil)
                        
                        //switch to invoices
                        if let invoicesNav = self?.tabBarController?.viewControllers?.first as? StyledNavigationController {
                            if let invoiceVC = invoicesNav.viewControllers.first as? InvoicesViewController {
                                invoiceVC.pickerView(UIPickerView(), didSelectRow: 0, inComponent: 0)
                                invoiceVC.pickerView.selectRow(0, inComponent: 0, animated: false)
                            }
                        }
                        
                        self?.tabBarController?.selectedIndex = 0
                        self?.navigationController?.popViewController(animated: false)
                        UserDefaults.standard.set(selectedContact.id, forKey: "SelectedContact")
                    }
                }
            }
        }
        else
        {
            self.view.makeToast(languageBundle!.localizedString(forKey: "Please select a product.", value: "", table: nil))
        }
    }
    
    @IBAction func payTapped(_ sender: UIButton)
    {
        if selectedProducts.count > 0
        {
            if selectedContact != nil
            {
                createInvoice(status: .paid, sender: sender)
            }
            else
            {
                self.view.makeToast(languageBundle!.localizedString(forKey: "Please select a customer to generate invoice.", value: "", table: nil))
            }
        }
        else
        {
            self.view.makeToast(languageBundle!.localizedString(forKey: "Please select a product.", value: "", table: nil))
        }
    }
    
    private func createInvoice(status:InvoiceStatus , sender: UIButton)
    {
        showActivityIndicator()
        sender.isUserInteractionEnabled = false
        InvoicesManager.shared.getCustomerAccounts {[weak self] (accounts, error) in
            self?.hideActivityIndicator()
            if let error = error
            {
                self?.show(error: error)
            }
            else if let accounts = accounts
            {
                let currencySymbol = UserDefaults.standard.string(forKey: UserDefaults.Key.orgCurrencySymbol) ?? ""
                
                self?.paymentDialog.accounts = accounts
                self?.paymentDialog.mainView = self?.paymentView
                self?.paymentDialog.paymentSuccessVC = self?.paymentSuccessDialog
                self?.paymentDialog.paymentSuccessView = self?.paymentSuccessView
                self?.paymentDialog.tblView.reloadData()
                self?.paymentDialog.totalAmount = self?.totalPayable ?? 0.0
                self?.paymentDialog.dueAmount = self?.totalPayable ?? 0.0
                self?.paymentDialog.invoiceStatus = status
                self?.paymentDialog.invoiceNo = self?.invoiceNo.text ?? ""
                self?.paymentDialog.selectedProducts = self?.selectedProducts
                self?.paymentDialog.lblTotal.text = "\(self?.totalPayable ?? 0)"
                self?.paymentDialog.lblRemaining.text = String(format: "%.2f", self!.totalPayable)
                self?.paymentDialog.lblChange.text = "0.0"
                    
                let cells = self?.paymentDialog.tblView.visibleCells as! [PaymentTableViewCell]
                
                for cell in cells
                {
                    cell.btnExpand.tag = 0
                    cell.txtAmount.text = ""
                    
                }
                self?.paymentDialog.firstTime = true
                self?.paymentDialog.tblView.reloadData()
                
                self?.paymentView.alpha = 0
                UIView.animate(withDuration: 0.2, delay: 0.2, options: [.curveEaseIn], animations: {
                    self?.paymentView.alpha = 1 // Here you will get the animation you want
                }, completion: { _ in
                    self?.paymentView.isHidden = false // Here you hide it when animation done
                })
                
                self?.view.bringSubview(toFront: (self?.paymentView)!)
                sender.isUserInteractionEnabled = true
                
                //success dialog
                self?.paymentSuccessDialog.mainView = self?.paymentSuccessView
                self?.paymentSuccessDialog.starIoExtManager = self?.starIoExtManager
                self?.paymentSuccessDialog.posInvoiceNo = self?.invoiceNo.text!
                self?.paymentSuccessDialog.beforeTax = self?.beforeTax.text!
                self?.paymentSuccessDialog.afterTax = String(format: "%.2f", self?.totalPayable ?? 0)
                self?.paymentSuccessDialog.tax = self?.taxAmount.text!
                totalamountWithTax = (self?.totalPayable)!
                
                self?.paymentSuccessDialog.totalLabel.text = "\(languageBundle!.localizedString(forKey: "Total", value: "", table: nil)): \(self?.totalPayable ?? 0) \(currencySymbol)"
                self?.paymentSuccessDialog.invoiceNo.text = "\(languageBundle!.localizedString(forKey: "POS Invoice", value: "", table: nil))# " + (self?.invoiceNo.text)!
                self?.paymentSuccessDialog.customerName.text = "\(languageBundle!.localizedString(forKey: "Customer Name", value: "", table: nil)): " + (self?.userName.text)!
                self?.paymentSuccessDialog.customerNo.text = "\(languageBundle!.localizedString(forKey: "Customer Phone", value: "", table: nil)): " + (self?.customerPhone.text)!
                
                
                self?.view.bringSubview(toFront: (self?.paymentSuccessView)!)
            }
        }
    }
    
    func generateInvoiceNo(min:Int, max:Int) -> String
    {
        let randomNumber = random(max) + min
        
        let date = Date()
        let calendar = NSCalendar.current
        
        let day = calendar.component(.day, from: date)
        let month = calendar.component(.month, from: date) + 1
        let year = calendar.component(.year, from: date) % 100
        
        return "POS\(year)\(month)\(day)\(randomNumber)"
    }
    
    func random(_ n:Int) -> Int {
        return Int(arc4random_uniform(UInt32(n)))
    }
    
    func loadCustomer() {
        if selectedContact != nil {
            customerPhone.text = selectedContact.primary_contact_number ?? ""
            userName.text = selectedContact.contact_name ?? ""
        }
        else
        {
        }
    }
    
    func removeProducts()
    {
        var count = 0
        for product in selectedProducts
        {
            let qunantity = Double(product.created_at ?? "0")
            
            if qunantity == 0
            {
                selectedProducts.remove(at: count)
            }
            count += 1
        }
    }
    
    var newFlag = false
    var newDiscount = 0.0
    
    func loadData()
    {
        //load customer
        loadCustomer()
        
        //calculating amount
        var totalPrice = 0.0
        var taxValue = 0.0
        for product in selectedProducts
        {
            if let price = Double(product.selling_price ?? "0")
            {
                let discount = Double(product.updated_at ?? "0") ?? 0.0
                let qunantity = Double(product.created_at ?? "0") ?? 1.0
                var discountedPrice =  discountPrice(price: price, discount: discount).rounded(toPlaces: 2)
                
                discountedPrice = qunantity * discountedPrice
                
                totalPrice = totalPrice + discountedPrice.rounded(toPlaces: 2)
                totalPrice = totalPrice.rounded(toPlaces: 2)
                
                if product.deleted_at == nil || product.deleted_at!.isEmpty
                {
                    let taxPercent = Double(taxPercentage(productId: product.tax_id ?? 0))
                    if taxPercent > 0 {
                        newDiscount = Double(product.updated_at ?? "0") ?? 0.0
                        taxValue = taxValue + ( discountedPrice * (taxPercent / 100.0))
                    }
                    product.deleted_at = "\(taxPercent)"
                }
                else
                {
                    let taxPercent = Double(product.deleted_at!) ?? 0.0
                    
                    if(!newFlag)
                    {
                        discountedPrice = discountPrice(price: price, discount: newDiscount).rounded(toPlaces: 2)
                        discountedPrice = qunantity * discountedPrice
                        print(discountedPrice)
                        print(newDiscount)
                        taxValue = taxValue + (discountedPrice * (taxPercent / 100.0))
                    }
                    else
                    {
                        let newPrice = discountPrice(price: price, discount: newDiscount).rounded(toPlaces: 2)
                        taxValue = taxValue + (newPrice * (taxPercent / 100.0))
                    }
                }
            }
        }
        
        totalPayable = totalPrice + taxValue.rounded(toPlaces: 2)
        totalPayable = totalPayable.rounded(toPlaces: 2)
        actuallTotal = totalPayable
        let currencySymbol = UserDefaults.standard.string(forKey: UserDefaults.Key.orgCurrencySymbol) ?? ""
        
        beforeTax.text = "\(totalPrice.rounded(toPlaces: 2)) \(currencySymbol)"
        print(taxValue.rounded(toPlaces: 2))
        print(taxValue)
        taxAmount.text = "\(taxValue.rounded(toPlaces: 2)) \(currencySymbol)"
        total.text = "\(totalPayable.rounded(toPlaces: 2)) \(currencySymbol)"
        payButton.setTitle("   \(languageBundle!.localizedString(forKey: "Pay", value: "", table: nil)) \(totalPayable.rounded(toPlaces: 2)) \(currencySymbol)   ", for: .normal)
    }
    
    func loadDataAfterTaxChanges()
    {
        let beforeTaxStr = String(format: "%@",beforeTax.text ?? "0.0")
        let taxValueStr = String(format: "%@",taxAmount.text ?? "0.0")

        let totalPrice = (beforeTaxStr as NSString).doubleValue
        let taxValue = (taxValueStr as NSString).doubleValue
        
        totalPayable = totalPrice + taxValue
        let currencySymbol = UserDefaults.standard.string(forKey: UserDefaults.Key.orgCurrencySymbol) ?? ""
        total.text = "\(totalPayable.rounded(toPlaces: 2)) \(currencySymbol)"
        payButton.setTitle("   \(languageBundle!.localizedString(forKey: "Pay", value: "", table: nil)) \(totalPayable.rounded(toPlaces: 2)) \(currencySymbol)   ", for: .normal)
    }
    
    func taxPercentage(productId:Int) -> Int{
        for tax in taxes {
            if tax.id == productId {
                return tax.percentage ?? 0
            }
        }
        
        return 0
    }
    
    func discountPrice(price:Double , discount:Double) -> Double {
        var discountedPrice = price
        
        if discount > 0 {
            discountedPrice = price - ( price * (discount / 100.0))
        }
        
        return discountedPrice
    }
    
    @objc func donePicker()
    {
        if pickerTag == 2
        {
            if selectedProd.current_stock != nil
            {
                let stock = Double(selectedProd.current_stock!) ?? 0
                
                var val = 0.0
                if let quantity = Double(selectedProd.created_at ?? "0.0") {
                    val = quantity
                }
                
                var increment = 0.0
                if let rateVal = Double(unitsArray[pickerRow].rate) {
                    increment = rateVal
                }
                
                val = val * increment
                
                if val < stock
                {
                    newFlag = false
                    selectedProd.product_unit_type_id = unitsArray[pickerRow].id
                    selectedProd.unit_name = unitsArray[pickerRow].name
                    selectedProd.unit_representation = unitsArray[pickerRow].rate
                    
//                    selectedProd.created_at = "\(val)"
                    self.tableView.reloadData()
                    
                    pickerTextField.resignFirstResponder()
                }
                else
                {
                    pickerTextField.resignFirstResponder()
                    UIApplication.shared.windows[windowCount-1].makeToast(languageBundle!.localizedString(forKey: "Product is out of stock", value: "", table: nil))
                }
            }
        }
        else
        {
            pickerTextField.resignFirstResponder()
        }
    }
    
    func createPickerView(textField: UITextField)
    {
        let picker: UIPickerView
        picker = UIPickerView()
        picker.backgroundColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
        
        picker.showsSelectionIndicator = true
        picker.delegate = self
        picker.dataSource = self
        
        let toolBar = UIToolbar()
        toolBar.barStyle = .default
        toolBar.isOpaque = true
        toolBar.isTranslucent = true
        toolBar.backgroundColor = UIColor.darkGray
        toolBar.tintColor = #colorLiteral(red: 0.01960784314, green: 0.4196078431, blue: 0.6117647059, alpha: 1)
        toolBar.sizeToFit()
        
        let doneButton = UIBarButtonItem(title: languageBundle!.localizedString(forKey: "Done", value: "", table: nil), style: UIBarButtonItemStyle.plain, target: self, action: #selector(donePicker))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        
        toolBar.setItems([spaceButton, doneButton], animated: false)
        toolBar.isUserInteractionEnabled = true
        
        textField.inputView = picker
        textField.inputAccessoryView = toolBar
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if let paymentScreen = segue.destination as? PaymentViewController
        {
            paymentDialog = paymentScreen
        }
        else if let paymentSuccessScreen = segue.destination as? PaymentConfirmationViewController
        {
            paymentSuccessDialog = paymentSuccessScreen
        }
        else if let discountScreen = segue.destination as? DiscountViewController
        {
            if let discountButton =  sender as? UIButton
            {
                if let cell = discountButton.superview?.superview as? CartTableViewCell
                {
                    if let indexPath = tableView.indexPath(for: cell)
                    {
                        discountScreen.product = selectedProducts[indexPath.row]
                    }
                }
            }
        }
        else if let priceScreen = segue.destination as? PriceViewController
        {
            if let priceButton =  sender as? UIButton
            {
                if let cell = priceButton.superview?.superview as? CartTableViewCell
                {
                    if let indexPath = tableView.indexPath(for: cell)
                    {
                        priceScreen.product = selectedProducts[indexPath.row]
                    }
                }
            }
        }
        else if let taxScreen = segue.destination as? TaxViewController
        {
            if let taxButton =  sender as? UIButton
            {
                if let cell = taxButton.superview?.superview as? CartTableViewCell
                {
                    if let indexPath = tableView.indexPath(for: cell)
                    {
                        taxScreen.product = selectedProducts[indexPath.row]
                    }
                }
            }
        }
        else if let quantityScreen = segue.destination as? QuantityViewController
        {
            if let quantityButton =  sender as? UIButton
            {
                if let cell = quantityButton.superview?.superview?.superview?.superview as? CartTableViewCell
                {
                    if let indexPath = tableView.indexPath(for: cell)
                    {
                        quantityScreen.product = selectedProducts[indexPath.row]
                    }
                }
            }
        }
    }
    
    @IBAction func unwindToHome(_ sender: UIStoryboardSegue)
    {
        if let _ = sender.source as? DiscountViewController
        {
            loadData()
            tableView.reloadData()
        }
        
        if let _ = sender.source as? PriceViewController
        {
            loadData()
            tableView.reloadData()
        }
        
        if let _ = sender.source as? TaxViewController
        {
            loadData()
            tableView.reloadData()
//            loadDataAfterTaxChanges()
        }
        
        if let _ = sender.source as? QuantityViewController
        {
            removeProducts()
            tableView.reloadData()
            loadData()
//            if selectedProducts.count > 0
//            {
//                loadCartData()
//                tableView.reloadData()
//            }
//            else
//            {
//                navigationController?.popViewController(animated: true)
//            }
        }
        
        if let _ = sender.source as? NewCustomerViewController
        {
            CustomerManager.shared.getContacts {[weak self] (data, error) in
                if let data = data {
                    self!.contacts = data
                    if let picker = self?.pickerTextField.inputView as? UIPickerView {
                        picker.reloadAllComponents()
                    }
                }
            }
        }
        
        if let customers = sender.source as? CustomerSearchTableViewController
        {
            selectedContact = customers.selectedContact
            loadData()
            tableView.reloadData()
        }
    }
    
    @objc func refreshBarcodeReader() {
        if self.starIoExtManager.connect() == false {
            print("unable to connect printer")
        }
        
        self.tableView.reloadData()
    }
    
    @IBAction func unitBtnAction(button: UIButton)
    {
        selectedProd = selectedProducts[button.tag - 1000]
        if selectedProd.units_list.count > 0
        {
            if unitsArray.count == 0 || selectedProd.id != prevProdID
            {
                prevProdID = selectedProd.id
                
                unitsArray = []
                let primaryUnit = Unit(product_id: selectedProd.id, id: selectedProd.product_unit_type_id, rate: "1", name: selectedProd.unit_name)
                unitsArray.append(primaryUnit)
                
                for unit in selectedProd.units_list
                {
                    let secondaryUnit = Unit(product_id: unit.product_id, id: unit.from_unit, rate: unit.rate, name: unit.from_unit_name)
                    unitsArray.append(secondaryUnit)
                }
            }
            
            pickerTag = 2
            pickerTextField.becomeFirstResponder()
        }
    }
}

extension CartViewController: UITableViewDelegate
{
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let vw = UIView()
        vw.backgroundColor = UIColor.clear
        
        let label = UILabel()
        label.text = languageBundle!.localizedString(forKey: "Products", value: "", table: nil)
        label.font = UIFont.systemFont(ofSize: 15 , weight:.semibold)
        label.textColor = #colorLiteral(red: 0.4509803922, green: 0.4509803922, blue: 0.4509803922, alpha: 1)
        label.frame = CGRect(x: 15, y: 0, width: 100, height: 30)
        
        vw.addSubview(label)
        return vw
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        let selectedProduct = scannedProducts[indexPath.row]
        
        view.sendSubview(toBack: tableViewBackground)
        tableViewBackground.isHidden = true
        
        if selectedProducts.contains(where: { (product) -> Bool in
            return product.id == selectedProduct.id
        }) {
            var quantity = Double(selectedProduct.created_at ?? "1.0") ?? 1.0
            quantity = quantity + scannedVolume
            selectedProduct.created_at = "\(quantity)"
        }else {
            var quantity = Double(selectedProduct.created_at ?? "0.0") ?? 0.0
            quantity = quantity + scannedVolume
            selectedProduct.created_at = "\(quantity)"
            
            selectedProducts.append(selectedProduct)
        }
        
        loadData()
        tableView.reloadData()
        
        tableView.deselectRow(at: indexPath, animated: false)
    }
}

extension CartViewController: UITableViewDataSource
{
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, didEndEditingRowAt indexPath: IndexPath?) {
        
    }
    
    func tableView(_ tableView: UITableView, willBeginEditingRowAt indexPath: IndexPath) {
        
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        switch editingStyle {
        case .delete:
            selectedProducts.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            loadData()
        default:
            break
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        if tableView == scannedProductsTableView
        {
            return 78
        }
        else
        {
            return 110
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if tableView == scannedProductsTableView {
            return scannedProducts.count
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == scannedProductsTableView {
            return 1
        }
        return selectedProducts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if tableView == scannedProductsTableView
        {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as? ScannedProductsTableViewCell {
                
                let product = scannedProducts[indexPath.section]
                
                cell.textLabel?.text = product.name
                cell.detailTextLabel?.text = product.selling_price
                
                let imageUrl = product.large_picture
                cell.imageUrl = imageUrl
                cell.imageView?.image = nil
                
                CommonManager.shared.getImage(forUrl: imageUrl) { (image, error) in
                    if let image = image {
                        if cell.imageUrl == imageUrl {
                            cell.imageView?.image = image
                        }
                    }
                }
                
                return cell
            }
            return UITableViewCell()
        }
        else
        {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as? CartTableViewCell else{
                return UITableViewCell()
            }
            
            let account = selectedProducts[indexPath.row]
            
            let imageUrl = account.large_picture
            cell.imgView.image = nil
            
            CommonManager.shared.getImage(forUrl: imageUrl) { (image, error) in
                if let image = image
                {
                    cell.imgView.image = image
                }
            }
            
            cell.name.text = account.name
            
            var discount = 0.0
            if let val = Double(account.updated_at ?? "0") {
                discount = val
            }
            
            if discount > 0
            {
                let discountString = String(format: "%.2f", Double(discount))
                cell.percentage.text = "\(discountString)%"
            }
            else
            {
                cell.percentage.text = "0%"
            }
            
            var quantity = 1.0
            if let val = Double(account.created_at ?? "0.0") {
                quantity = val
            }
            
            if verifyProduct(product: account)
            {
                cell.stock.text = String(format: "%@: %@" , languageBundle!.localizedString(forKey:"Stock", value: "", table: nil), account.current_stock ?? "0")
            }
            
            cell.sku.text = String(format: "%@: %@" , languageBundle!.localizedString(forKey:"SKU", value: "", table: nil), account.sku ?? "-")
            
            let quantityString = String(format: "%.1f", quantity)
            cell.quantity.text = "\(quantityString)"
            cell.quantityV.text = "\(quantityString)"
            
            var taxValue = "0"
            
            if account.deleted_at != nil && !account.deleted_at!.isEmpty
            {
                let tax = Double(account.deleted_at!) ?? 0.0
                
                if tax > 0
                {
                    taxValue = String(format: "%.2f", tax)
                }
            }
            cell.lblTax.text = taxValue + "%"
            let sellingPrice = discountPrice(price: Double("\(account.selling_price ?? "0")") ?? 0, discount: Double(discount))
            
            let amountText = String(format: "%.2f", Double("\(account.selling_price ?? "0")") ?? 0)
            cell.amount.text =  "\(amountText) \(UserDefaults.standard.string(forKey: UserDefaults.Key.orgCurrencySymbol) ?? "")"
            
            let totalPrice = String(format: "%.2f", sellingPrice * Double(quantity))
            
            cell.rate.text = "\(account.unit_name) \(account.selling_price ?? "0")\(UserDefaults.standard.string(forKey: UserDefaults.Key.orgCurrencySymbol) ?? "")/\(account.unit_name ) "
            
            cell.unitBtn.addTarget(self, action: #selector(unitBtnAction(button:)), for: .touchUpInside)
            cell.unitBtn.tag = 1000 + indexPath.row
            
//            cell.rate.text = "\(account.unit_name) \(totalPrice)\(UserDefaults.standard.string(forKey: UserDefaults.Key.orgCurrencySymbol) ?? "")/\(account.unit_name ) "
            
            return cell
        }
    }
}

extension CartViewController: UIPickerViewDelegate
{
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
    {
        if pickerTag == 1
        {
            selectedContact = contacts[row]
            loadCustomer()
        }
        
        pickerRow = row
    }
}

extension CartViewController: UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int
    {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int
    {
        if pickerTag == 1
        {
            return contacts.count
        }
        else
        {
            return unitsArray.count
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String?
    {
        if pickerTag == 1
        {
            return contacts[row].contact_name ?? "N/A"
        }
        else
        {
            return unitsArray[row].name
        }
    }
}

extension CartViewController: StarIoExtManagerDelegate {
    func didBarcodeDataReceive(_ data: Data!) {
        NSLog("%@", MakePrettyFunction())
        
        var text: String = ""
        var codes:[String] = []
        
        var buffer: Array<UInt8> = Array<UInt8>(repeating: 0, count: data.count)
        
        data.copyBytes(to: &buffer, count: data.count)
        
        for i: Int in 0 ..< data.count {
            let ch: UInt8 = buffer[i]
            
            if ch >= 0x20 && ch <= 0x7f {
                text += String(format: "%c", ch)
            }
            else if ch == 0x0d {
                codes.append(text)
                text = ""
            }
        }
        if let code = codes.first
        {
            var type = ""
            if code.count == 13 {
                type = "EAN-13"
            }
            performSearch(code: code, type: type)
        }
    }
    
    func performSearch(code:String , type:String)
    {
        var code = code
        scannedVolume = 1.0
        
        //check if its our kind of ean code
        if type.contains("EAN-13") && code.starts(with: "22"){
            //extract quantity string
            let endString = code.suffix(6)
            let quantityString = String(endString[..<endString.index(endString.startIndex, offsetBy: 5)])
            
            //convert volume into weight
            scannedVolume = (Double(quantityString) ?? 1.0) / 1000.0
            
            //round off
            scannedVolume = scannedVolume.rounded(toPlaces: 2)
            
            //extract bar code string
            let index = code.index(code.startIndex, offsetBy: 7)
            code = String(code[..<index])
        }
        
        print("code " + code)
        print("volume \(scannedVolume)")
        
        let productsFound = productView.products.filter { (product) -> Bool in
            return product.barcode == code
        }
        
        if productsFound.count > 0
        {
            if productsFound.count == 1
            {
                if selectedProducts.contains(where: { (product) -> Bool in
                    return product.id == productsFound.first!.id
                })
                {
                    let product = selectedProducts.filter { (product) -> Bool in
                        return product.id == productsFound.first!.id
                    }
                    
                    if verifyProduct(product: product.first!)
                    {
                        if product.first!.current_stock != nil
                        {
                            let stock = Double(product.first!.current_stock!) ?? 0
                            let actualQTY = Double(product.first!.created_at!) ?? 0
                            
                            if actualQTY < stock
                            {
                                var quantity = Double(product.first!.created_at ?? "1.0") ?? 1.0
                                quantity = quantity + scannedVolume
                                
                                var increment = 0.0
                                if let rateVal = Double(product.first!.unit_representation) {
                                    increment = rateVal
                                }
                                
                                let qty = quantity * increment
                                
                                if qty < stock
                                {
                                    product.first!.created_at = "\(quantity)"
                                }
                                else
                                {
                                    self.view.makeToast(languageBundle!.localizedString(forKey: "Product is out of stock", value: "", table: nil))
                                }
                            }
                            else
                            {
                                self.view.makeToast(languageBundle!.localizedString(forKey: "Product is out of stock", value: "", table: nil))
                            }
                        }
                        else
                        {
                            self.view.makeToast(languageBundle!.localizedString(forKey: "Product is out of stock", value: "", table: nil))
                        }
                    }
                    else
                    {
                        var quantity = Double(product.first!.created_at ?? "1.0") ?? 1.0
                        quantity = quantity + scannedVolume
                        product.first!.created_at = "\(quantity)"
                    }
                }
                else
                {
                    var quantity = 0.0
                    
                    if verifyProduct(product: productsFound.first!)
                    {
                        if productsFound.first!.current_stock != nil
                        {
                            let stock = Double(productsFound.first!.current_stock!) ?? 0
                            
                            if stock > 0
                            {
                                quantity = quantity + scannedVolume
                                productsFound.first!.created_at = "\(quantity)"
                                
                                selectedProducts.append(productsFound.first!)
                            }
                            else
                            {
                                self.view.makeToast(languageBundle!.localizedString(forKey: "Product is out of stock", value: "", table: nil))
                            }
                        }
                        else
                        {
                            self.view.makeToast(languageBundle!.localizedString(forKey: "Product is out of stock", value: "", table: nil))
                        }
                    }
                    else
                    {
                        quantity = quantity + scannedVolume
                        productsFound.first!.created_at = "\(quantity)"
                        
                        selectedProducts.append(productsFound.first!)
                    }
                }
                
                self.tableView.reloadData()
            }
            else
            {
                scannedProducts = productsFound
                view.bringSubview(toFront: tableViewBackground)
                tableViewBackground.isHidden = false
                scannedProductsTableView.reloadData()
                print("found multiple")
            }
        }
        else
        {
            self.view.makeToast(languageBundle!.localizedString(forKey: "Product does not exist", value: "", table: nil))
        }
    }
}
