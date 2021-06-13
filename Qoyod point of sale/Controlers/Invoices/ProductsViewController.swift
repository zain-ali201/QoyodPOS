//
//  ProductsViewController.swift
//  Qoyod point of sale
//
//  Created by Sharjeel Ahmad on 05/09/2018.
//  Copyright © 2018 Sharjeel Ahmad. All rights reserved.
//

import UIKit
import Toast_Swift

var cartVC: CartViewController!
var customersList:[Contact] = []

class ProductsCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var enclosingView: UIView!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var currentStock: UILabel!
    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var lblSKU: UILabel!
    @IBOutlet weak var sellingPrice: UILabel!
    @IBOutlet weak var sellingUnitName: UILabel!
    @IBOutlet weak var buyingPrice: UILabel!
    @IBOutlet weak var unitName: UILabel!
    
    //to cache image
    var imageUrl:String!
}

class ProductsViewController: UIViewController {

    @IBOutlet weak var selectBtn: UIButton!
    @IBOutlet weak var productsCollectionView: UICollectionView!
    @IBOutlet weak var lblNoProduct: UILabel!
    @IBOutlet weak var cartLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var checkoutButton: UIButton!
    @IBOutlet weak var cartViewBottom: NSLayoutConstraint!
    @IBOutlet weak var navigationView: UIView!
    @IBOutlet weak var navigationTitleView: UILabel!
    @IBOutlet weak var collectionTopSpace: NSLayoutConstraint!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var cartView: UIView!
    @IBOutlet weak var btnCancel: UIButton!
    
    var searchTerm = ""
    var taxes:[Tax]!
    
    //shared
    var products:[Product] = []
    var contacts:[Contact] = []
//    var selectedCategory:Category!
    var superView:ProductsViewController!
    var selectedProducts:[Product] = []
    
    //local
    var productsDataSource:[Product] = []
    
    //star bar code reader
    var starIoExtManager: StarIoExtManager!
    var scannedVolume = 1.0
    fileprivate lazy var scannedProducts:[Product] = []
    @IBOutlet weak var tableViewBackground: UIView!
    @IBOutlet weak var scannedProductsTableView: UITableView!
    
    var timer:Timer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        //button image on right
        checkoutButton.semanticContentAttribute = UIApplication.shared
            .userInterfaceLayoutDirection == .rightToLeft ? .forceLeftToRight : .forceRightToLeft
        
            navigationView.removeFromSuperview()
        
        //to clear selection after payment
        NotificationCenter.default.addObserver(self, selector: #selector(clearSelection), name: Notification.Name.syncData, object: nil)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(quantityBtnAction(sender:)))
        tap.numberOfTapsRequired = 2
        tap.delaysTouchesBegan = true
        productsCollectionView.addGestureRecognizer(tap)
        
        timer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(self.checkProductsQuantity), userInfo: nil, repeats: true)
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        
        //hide cart view by default
        showHideCartView()
        refreshSource()
        
        //load taxes invoices
        InvoicesManager.shared.getProductTaxes {[weak self] (taxes, error) in
            if let error = error {
                loggingPrint(error)
            }else if let taxes = taxes {
                self?.taxes = taxes
            }
        }
        
        //load contacts
        CustomerManager.shared.getContacts {[weak self] (contacts, error) in
            if let error = error {
                loggingPrint(error)
            }else if let contacts = contacts {
                self?.contacts = contacts
                customersList = contacts
            }
        }
        
        //bar code printer
        self.starIoExtManager = StarIoExtManager(type: StarIoExtManagerType.onlyBarcodeReader,
                                                 portName: AppDelegate.getPortName(),
                                                 portSettings: AppDelegate.getPortSettings(),
                                                 ioTimeoutMillis: 10000)                                      // 10000mS!!!
        
        self.starIoExtManager.cashDrawerOpenActiveHigh = AppDelegate.getCashDrawerOpenActiveHigh()
        
        self.starIoExtManager.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(ProductsViewController.applicationWillResignActive), name: NSNotification.Name(rawValue: "UIApplicationWillResignActiveNotification"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ProductsViewController.applicationDidBecomeActive),  name: NSNotification.Name(rawValue: "UIApplicationDidBecomeActiveNotification"),  object: nil)

        connectPrinter()
        
        btnCancel.setTitle(languageBundle!.localizedString(forKey: "Cancel", value: "", table: nil), for: .normal)
        checkoutButton.setTitle(languageBundle!.localizedString(forKey: "Checkout", value: "", table: nil), for: .normal)
    }
    
    @objc func checkProductsQuantity()
    {
        if selectedProducts.count > 0
        {
            for prod in selectedProducts
            {
                let filteredProducts = products.filter{ $0.id == prod.id }
                
                if filteredProducts.count > 0
                {
                    let filteredProduct = filteredProducts.first!
                    
                    let stock = Double(filteredProduct.current_stock!) ?? 0
                    let quantity = Double(prod.created_at!) ?? 0
                    
                    if verifyProduct(product: filteredProduct)
                    {
                        if stock <= 0
                        {
                            let alert = UIAlertController(title: "" , message: String(format: languageBundle!.localizedString(forKey:"Product '%@' is out of stock. Please deselect this product from your cart.", value: "", table: nil),prod.name), preferredStyle: UIAlertControllerStyle.alert)
                            
                            alert.addAction(UIAlertAction(title: languageBundle!.localizedString(forKey:"Deselect", value: "", table: nil), style: .cancel, handler: { action in
                                
                                let index = self.selectedProducts.index(where: { (actionItem) -> Bool in
                                    return actionItem.id == prod.id
                                })
                                self.selectedProducts.remove(at: index!)
                                self.showHideCartView()
//                                print(self.selectedProducts.count)
                                DispatchQueue.main.async {
                                    if cartVC != nil
                                    {
                                        cartVC.count = self.selectedProducts.count
                                        cartVC.loadCartData()
                                        
                                    }
                                }
                            }))
                            
                            self.present(alert, animated: true, completion: nil)
                        }
                        else if quantity > stock
                        {
                            let alert = UIAlertController(title: "" , message: String(format: languageBundle!.localizedString(forKey:"Quantity of Product '%@' is greater than the current stock. Please decrease the quantity.", value: "", table: nil),prod.name), preferredStyle: UIAlertControllerStyle.alert)
                            
                            alert.addAction(UIAlertAction(title: languageBundle!.localizedString(forKey:"Decrease", value: "", table: nil), style: .cancel, handler: { action in
                                
                                prod.created_at = filteredProduct.current_stock
                                prod.current_stock = filteredProduct.current_stock
                                self.showHideCartView()
                                
                                if cartVC != nil
                                {
                                    cartVC.count = self.selectedProducts.count
                                    cartVC.loadCartData()
                                }
                            }))
                            
                            self.present(alert, animated: true, completion: nil)
                        }
                    }
                }
            }
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
    
    func connectPrinter()
    {
        GlobalQueueManager.shared.serialQueue.async {
            DispatchQueue.main.async {
                self.starIoExtManager.disconnect()
                
                if self.starIoExtManager.connect() == false
                {
                    if !printerFlag
                    {
                        self.showMessage(languageBundle!.localizedString(forKey:"Printer is not connected.", value: "", table: nil))
                    }
                }
                else
                {
                    print("Printer connected.")
                }
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
         
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "UIApplicationWillResignActiveNotification"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "UIApplicationDidBecomeActiveNotification"),  object: nil)
        
        GlobalQueueManager.shared.serialQueue.async {
            self.starIoExtManager.disconnect()
        }
    }
    
    @objc func applicationDidBecomeActive() {
        GlobalQueueManager.shared.serialQueue.async {
            DispatchQueue.main.async {
                self.refreshPrinter()
            }
        }
    }
    
    @objc func applicationWillResignActive() {
        GlobalQueueManager.shared.serialQueue.async {
            self.starIoExtManager.disconnect()
        }
    }
    
    @objc func refreshPrinter() {
        self.starIoExtManager.disconnect()
        
        if self.starIoExtManager.connect() == false {
            showMessage(languageBundle!.localizedString(forKey:"Fail to Open Port.", value: "", table: nil))
        }
    }
    
    @IBAction func cancelTapped(_ sender: UIButton)
    {
        clearSelection()
    }
    
    @objc func clearSelection()
    {
        for prod in selectedProducts {
            prod.created_at = "-" //reset quantity
            prod.updated_at = "0" //reset discount
        }
        
        selectedProducts.removeAll()
        selectBtn.setTitle(languageBundle!.localizedString(forKey:"Select all", value: "", table: nil), for: .normal)
        showHideCartView()
    }
    
    @IBAction func quantityBtnAction(sender: UITapGestureRecognizer)
    {
        let point:CGPoint = sender.location(ofTouch: 0, in: productsCollectionView)
//        let point:CGPoint = touch.location(in: productsCollectionView)
        let indexPath:IndexPath = productsCollectionView.indexPathForItem(at: point)!
        let actionItem = productsDataSource[indexPath.item]
        
        if verifyProduct(product: actionItem)
        {
            let stock = Double(actionItem.current_stock!) ?? 0
            
            if stock > 0
            {
                if selectedProducts.contains(where: { (prod) -> Bool in
                    return prod.id == actionItem.id
                })
                {
                    
                }
                else
                {
                    actionItem.created_at = "\(1.0)"
                    selectedProducts.append(actionItem)
                    showHideCartView()
                }
                
                performSegue(withIdentifier: "quantity", sender: indexPath)
            }
            else
            {
                self.view.makeToast(languageBundle!.localizedString(forKey: "Product is out of stock", value: "", table: nil))
            }
        }
        else
        {
            if selectedProducts.contains(where: { (prod) -> Bool in
                return prod.id == actionItem.id
            })
            {
                
            }
            else
            {
                actionItem.created_at = "\(1.0)"
                selectedProducts.append(actionItem)
                showHideCartView()
            }
            
            performSegue(withIdentifier: "quantity", sender: indexPath)
        }
    }
    
    @IBAction func checkoutTapped(_ sender: UIButton) {
        
    }
    
    @IBAction func backTapped(_ sender: UIButton)
    {
        superView.selectedProducts = selectedProducts
        superView.productsCollectionView.reloadData()
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func selectBtnAction(_ button: UIButton) {
        
        if button.titleLabel?.text == "Select all"
        {
            selectedProducts = []
            
            for prod in productsDataSource
            {
                if verifyProduct(product: prod)
                {
                    let stock = Double(prod.current_stock!) ?? 0
                    
                    if stock > 0
                    {
                        selectedProducts.append(prod)
                    }
                }
                else
                {
                    selectedProducts.append(prod)
                }
            }
            button.setTitle(languageBundle!.localizedString(forKey:"Deselect all", value: "", table: nil), for: .normal)
        }
        else
        {
            selectedProducts.removeAll()
            button.setTitle(languageBundle!.localizedString(forKey:"Select all", value: "", table: nil), for: .normal)
        }
        
        showHideCartView()
    }
    
    @IBAction func scanTapped(_ sender: UIButton) {
    }
    
    @IBAction func searchTapped(_ sender: UIButton) {
        showSearch()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if let scanner = segue.destination as? ScannerViewController {
            scanner.productView = self
        } else if let quantityScreen = segue.destination as? QuantityViewController {
            if let indexPath =  sender as? NSIndexPath {

                let actionItem = productsDataSource[indexPath.item]
                
                let products = selectedProducts.filter{ $0.id == actionItem.id }
                
                if products.count > 0
                {
                    quantityScreen.product = products[0]
                }
                else
                {
                    selectedProducts.append(actionItem)
                }
            }
        } else if let cart = segue.destination as? CartViewController
        {
                cart.selectedProducts = selectedProducts
                cart.contacts = contacts
                cart.taxes = taxes
                cart.productView = self
        }
    }
    
    @IBAction func unwindToHome(_ sender: UIStoryboardSegue) {
        if let _ = sender.source as? QuantityViewController {
            removeProducts()
            productsCollectionView.reloadData()
            showHideCartView()
        }
    }
    
    // MARK: - Shared Methods
    func refreshSource()
    {
        productsDataSource = products
//        print(productsDataSource.count)
        filterDatasource()
    }
    
    // MARK: - Private Methods
    private func hideSearch() {
        collectionTopSpace.constant = 0
        UIView.animate(withDuration: 0.2, animations: {
            self.view.layoutIfNeeded()
        }) { (isDone) in
            if isDone {
                
            }
        }
    }
    
    private func showSearch() {
        collectionTopSpace.constant = 56
        UIView.animate(withDuration: 0.2, animations: {
            self.view.layoutIfNeeded()
        }) { (isDone) in
            if isDone {
                self.searchBar.becomeFirstResponder()
            }
        }
    }
    
    private func hideCartView() {
        cartViewBottom.constant = -200
        UIView.animate(withDuration: 0.2, animations: {
            self.view.layoutIfNeeded()
            self.cartView.alpha = 0
        }) { (isDone) in
            if isDone {
                self.refreshSource()
            }
        }
    }
    
    private func showCartView()
    {
        cartViewBottom.constant = 0
        UIView.animate(withDuration: 0.2, animations: {
            self.cartView.alpha = 1
            self.view.layoutIfNeeded()
        }) { (isDone) in
            if isDone {
                self.refreshSource()
            }
        }
    }
    
    fileprivate func showHideCartView()
    {
        if selectedProducts.count > 0
        {
            calculateTotalPrice()
            showCartView()
        }
        else
        {
            hideCartView()
        }
        
        if selectedProducts.count == 1
        {
            cartLabel.text = languageBundle!.localizedString(forKey: "1 item selected", value: "", table: nil)
//            cartLabel.text =  languageBundle!.localizedString(forKey: "1 item selected", comment: "1 item selected")
        }
        else
        {
            cartLabel.text = "\(selectedProducts.count) \(languageBundle!.localizedString(forKey: "1 item selected", value: "", table: nil))"
//            cartLabel.text = "\(selectedProducts.count) \(languageBundle!.localizedString(forKey: "items selected", comment: "items selected"))"
            
        }
    }
    
    func calculateTotalPrice()
    {
        var totalPrice = 0.0
        
        for product in selectedProducts {
            if let price = Double(product.selling_price ?? "0") {
                let qunantity = Double(product.created_at ?? "0") ?? 1.0
                totalPrice += price * qunantity
                totalPrice = totalPrice.rounded(toPlaces: 2)
            }
        }
        priceLabel.text = "\(totalPrice)"
    }
    
    fileprivate func filterDatasource()
    {
        if !searchTerm.isEmpty
        {
            productsDataSource = productsDataSource.filter { (product) -> Bool in
                
                var flag = false
                
                let name = product.name
                let sku = product.sku ?? ""
                
                if let _ = name.range(of: searchTerm, options: .caseInsensitive)
                {
                    flag = true
                }
                else if let _ = sku.range(of: searchTerm, options: .caseInsensitive)
                {
                    flag = true
                }
                return flag
            }
        }
        productsCollectionView.reloadData()
        
        if productsDataSource.count == 0
        {
            lblNoProduct.text = languageBundle!.localizedString(forKey: "There is nothing here.", value: "", table: nil)
            lblNoProduct.isHidden = false
        }
        else
        {
            lblNoProduct.isHidden = true
        }
    }
}

// MARK: - Extensions

extension ProductsViewController: UISearchBarDelegate {
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = true
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchTerm = searchText
        refreshSource()
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        refreshSource()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        hideSearch()
        searchBar.text = ""
        searchTerm = ""
        refreshSource()
        searchBar.showsCancelButton = false
    }
}

extension ProductsViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let actionItem = productsDataSource[indexPath.item]
        
        if verifyProduct(product: actionItem)
        {
            if actionItem.current_stock != nil
            {
                let stock = Double(actionItem.current_stock!) ?? 0
                
                if stock > 0
                {
                    if selectedProducts.contains(where: { (prod) -> Bool in
                        return prod.id == actionItem.id
                    }) {
                        //show quantity dialog
                        //                    performSegue(withIdentifier: "quantity", sender: indexPath)
                        //                    selectedProducts = [actionItem]
                        let index = selectedProducts.index(where: { (prod) -> Bool in
                            return prod.id == actionItem.id
                        })
                        selectedProducts.remove(at: index!)
                        
                    }else {
                        actionItem.created_at = "\(1.0)"
                        selectedProducts.append(actionItem)
                    }
                    
                    showHideCartView()
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
            if selectedProducts.contains(where: { (prod) -> Bool in
                return prod.id == actionItem.id
            }) {
                let index = selectedProducts.index(where: { (prod) -> Bool in
                    return prod.id == actionItem.id
                })
                selectedProducts.remove(at: index!)
                
            }else {
                actionItem.created_at = "\(1.0)"
                selectedProducts.append(actionItem)
            }
            
            showHideCartView()
        }
    }
}

extension ProductsViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == productsCollectionView {
            let width  = self.view.frame.size.width - 10;
            // in case you you want the cell to be 40% of your controllers view
            return CGSize(width:width * 0.48 , height: width * 0.48);
        }
        
        return CGSize(width: 1, height: 1)
    }
}

extension ProductsViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return productsDataSource.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as? ProductsCollectionViewCell
        {
            let product = productsDataSource[indexPath.item]
            product.unit_representation = "1.0"
            cell.name.text = product.name
            
            cell.currentStock.text = ""
            
            if verifyProduct(product: product)
            {
                cell.currentStock.text = String(format: "%@: %@", languageBundle!.localizedString(forKey:"Stock", value: "", table: nil), product.current_stock ?? "0")
            }
            
            cell.unitName.text = ""
            cell.buyingPrice.text = ""
            if let buyingPrice = Double(product.created_at ?? "-") {
                cell.unitName.text = product.unit_name
                cell.buyingPrice.text = "\(buyingPrice)"
            }
            
            let sku = product.sku ?? "-"
            
            cell.lblSKU.text = "\(languageBundle!.localizedString(forKey:"SKU", value: "", table: nil)): \(sku)"
            
            let sellingPrice = product.selling_price ?? ""
            cell.sellingPrice.text = "\(sellingPrice) \(UserDefaults.standard.string(forKey: UserDefaults.Key.orgCurrencySymbol) ?? "")"
            
            if !sellingPrice.isEmpty {
                cell.sellingUnitName.text = product.unit_name
            }
            
            let imageUrl = product.large_picture
            cell.imageUrl = imageUrl
            cell.image.image = nil
            
            CommonManager.shared.getImage(forUrl: imageUrl) { (image, error) in
                if let image = image {
                    if cell.imageUrl == imageUrl {
                        cell.image.image = image
                    }
                }
            }
            
            cell.enclosingView.layer.shadowRadius = 2
            cell.enclosingView.layer.shadowOpacity = 0.2
            cell.enclosingView.layer.shadowOffset = CGSize(width: 0.0, height: 2.0)
            cell.enclosingView.layer.masksToBounds = false
            cell.enclosingView.layer.cornerRadius = 2.0
            
            cell.backgroundColor = selectedProducts.contains(where: { (prod) -> Bool in
                return prod.id == product.id
            }) ? UIColor.primary : UIColor.clear
            
            return cell
        }
        return UICollectionViewCell()
    }
}

extension ProductsViewController: UITableViewDataSource
{
    func numberOfSections(in tableView: UITableView) -> Int
    {
        return scannedProducts.count
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
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
}

extension ProductsViewController: UITableViewDelegate
{
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
        
        showHideCartView()
        
        tableView.deselectRow(at: indexPath, animated: false)
    }
}

extension ProductsViewController: StarIoExtManagerDelegate
{
    func didBarcodeDataReceive(_ data: Data!)
    {
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
        
//        print("code " + code)
//        print("volume \(scannedVolume)")
        
        let productsFound = products.filter { (product) -> Bool in
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
                
                showHideCartView()
            }
            else
            {
                scannedProducts = productsFound
                view.bringSubview(toFront: tableViewBackground)
                tableViewBackground.isHidden = false
                scannedProductsTableView.reloadData()
//                print("found multiple")
            }
            
        }
        else
        {
            self.view.makeToast(languageBundle!.localizedString(forKey: "Product does not exist", value: "", table: nil))
        }
    }
}
