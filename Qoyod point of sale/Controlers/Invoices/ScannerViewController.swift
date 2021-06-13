//
//  ScannerViewController.swift
//  Qoyod point of sale
//
//  Created by Sharjeel Ahmad on 06/09/2018.
//  Copyright © 2018 Sharjeel Ahmad. All rights reserved.
//

import UIKit
import AVFoundation
import BarcodeScanner

class ScannedProductsTableViewCell: UITableViewCell {
    var imageUrl:String!
}

class SelectedProductCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var sku: UILabel!
    @IBOutlet weak var rate: UILabel!
}

class ScannerViewController: UIViewController {

    @IBOutlet weak var barCodeScanner: UIView!
    @IBOutlet weak var productsView: UIView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewBackground: UIView!
    
    @IBOutlet weak var lblMain: UILabel!
    @IBOutlet weak var btnDone: UIButton!
    @IBOutlet weak var btnCheckout: UIButton!
    
    var productView:ProductsViewController!
    var scanner:BarcodeScannerViewController!
    fileprivate lazy var scannedProducts:[Product] = []
    var scannedVolume = 1.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        productsView.isHidden = productView.selectedProducts.count == 0
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        lblMain.text = languageBundle!.localizedString(forKey: "Cart", value: "", table: nil)
        btnDone.setTitle(languageBundle!.localizedString(forKey: "Done", value: "", table: nil), for: .normal)
        btnCheckout.setTitle(languageBundle!.localizedString(forKey: "Checkout", value: "", table: nil), for: .normal)
    }
    
    @IBAction func backTapped(_ sender: UIButton)
    {
        navigationController?.popViewController(animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let viewController = segue.destination as? BarcodeScannerViewController {
            viewController.codeDelegate = self
            viewController.errorDelegate = self
            viewController.dismissalDelegate = self
            scanner = viewController
            scanner.isOneTimeSearch = true
        }
    }
    
    @IBAction func scanBtnAction(_ sender: UIButton)
    {
        scanner.resetWithError(flag: true)
    }
    
    @IBAction func increaseQuantity(_ sender: UIButton)
    {
        if let cell = sender.superview?.superview as? SelectedProductCollectionViewCell {
            if let indexPath = collectionView.indexPath(for: cell) {
                let product = productView.selectedProducts[indexPath.item]
                
                var val = 1.0
                if let quantity = Double(product.created_at ?? "0.0") {
                    val = quantity
                }
                
                if verifyProduct(product: product)
                {
                    if product.current_stock != nil
                    {
//                        let stock = Double(product.current_stock!) ?? 0
//
//                        if val < stock
                       
                        let stock = Double(product.current_stock!) ?? 0
                        
                        var increment = 0.0
                        if let rateVal = Double(product.unit_representation) {
                            increment = rateVal
                        }
                        
                        let qty = (val + 1) * increment
                        
                        if qty < stock
                        {
                            product.created_at = "\(val + 1)"
                            collectionView.reloadData()
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
                    product.created_at = "\(val + 1)"
                    collectionView.reloadData()
                }
            }
        }
    }
    
    @IBAction func decreaseQuantity(_ sender: UIButton)
    {
        if let cell = sender.superview?.superview as? SelectedProductCollectionViewCell {
            if let indexPath = collectionView.indexPath(for: cell) {
                let product = productView.selectedProducts[indexPath.item]
                
                var val = 1.0
                if let quantity = Double(product.created_at ?? "0.0") {
                    val = quantity
                }
                
                let parts = String(val).components(separatedBy: ".")
                
                if parts[0] == "0" {
                    return
                }
                
                if val > 1.0
                {
                    product.created_at = "\(val - 1.0)"
                    
                    collectionView.reloadData()
                }
            }
        }
    }
    
    @IBAction func checkoutBtnAction(_ sender: UIButton)
    {
        let cart = UIStoryboard.main.instantiateViewController(withIdentifier: "CartViewController") as! CartViewController  
        cart.selectedProducts = productView.selectedProducts
        cart.contacts = productView.contacts
        cart.taxes = productView.taxes
        cart.productView = productView
        navigationController?.pushViewController(cart, animated: true)
    }
}

extension ScannerViewController: BarcodeScannerCodeDelegate , BarcodeScannerErrorDelegate , BarcodeScannerDismissalDelegate{
    func scanner(_ controller: BarcodeScannerViewController, didCaptureCode code: String, type: String) {
        print("found " + code + type)
        
        //play beep sound
        if let customSoundUrl = Bundle.main.url(forResource: "beep", withExtension: "mp3") {
            var customSoundId: SystemSoundID = 0
            AudioServicesCreateSystemSoundID(customSoundUrl as CFURL, &customSoundId)
            AudioServicesAddSystemSoundCompletion(customSoundId, nil, nil, { (customSoundId, _) -> Void in
                AudioServicesDisposeSystemSoundID(customSoundId)
            }, nil)
            
            AudioServicesPlaySystemSound(customSoundId)
        }
        
        //wait for animation to kick in
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: {
           self.performSearch(code: code, type: type)
        })
    }
    
    func performSearch(code:String , type:String) {
        var code = code
        scannedVolume = 1.0
        
        //check if its our kind of ean code
        if type.contains("EAN-13") && code.starts(with: "22")
        {
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
                if productView.selectedProducts.contains(where: { (product) -> Bool in
                    return product.id == productsFound.first!.id
                })
                {
                    let product = productView.selectedProducts.filter { (product) -> Bool in
                        return product.id == productsFound.first!.id
                    }
                    
                    if verifyProduct(product: product.first!)
                    {
                        if product.first!.current_stock != nil
                        {
                            let stock = Double(product.first!.current_stock!) ?? 0
                            let qty = Double(product.first!.created_at!) ?? 0
                            
                            if qty < stock
                            {
                                var quantity = Double(product.first!.created_at ?? "1.0") ?? 1.0
                                quantity = quantity + scannedVolume
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
                                
                                productView.selectedProducts.append(productsFound.first!)
                                print(productView.selectedProducts.count)
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
                        
                        productView.selectedProducts.append(productsFound.first!)
                        print(productView.selectedProducts.count)
                    }
                }
                collectionView.reloadData()
            }
            else
            {
                scannedProducts = productsFound
                view.bringSubview(toFront: tableViewBackground)
                tableView.reloadData()
                print("found multiple")
            }
            
            scanner.reset(flag: true)
        }
        else
        {
            scanner.reset(flag: false)
        }
        
        if productView.selectedProducts.count > 0
        {
            collectionView.reloadData()
            productsView.isHidden = false
        }
    }
    
    func scanner(_ controller: BarcodeScannerViewController, didReceiveError error: Error) {
        print(error)
    }
    
    func scannerDidDismiss(_ controller: BarcodeScannerViewController) {
        controller.dismiss(animated: true, completion: nil)
        print("Dismiss scanner")
    }
}

extension ScannerViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return productView.selectedProducts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as? SelectedProductCollectionViewCell
        {
       
            cell.name.text = productView.selectedProducts[indexPath.row].name
            
            let sku = productView.selectedProducts[indexPath.row].sku ?? "-"
            cell.sku.text = "\(sku)"
            
            cell.rate.text = String(format:"%.1f" , Double(productView.selectedProducts[indexPath.row].created_at ?? "1.0") ?? 1.0)
            
            cell.name.preferredMaxLayoutWidth = 200
            cell.sku.preferredMaxLayoutWidth = 200
            cell.rate.preferredMaxLayoutWidth = 50
            
            return cell
        }
        return UICollectionViewCell()
    }
}

extension ScannerViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return scannedProducts.count
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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

extension ScannerViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedProduct = scannedProducts[indexPath.row]
        
        view.sendSubview(toBack: tableViewBackground)
        
        if productView.selectedProducts.contains(where: { (product) -> Bool in
            return product.id == selectedProduct.id
        }) {
            var quantity = Double(selectedProduct.created_at ?? "1.0") ?? 1.0
            quantity = quantity + scannedVolume
            selectedProduct.created_at = "\(quantity)"
        }else {
            var quantity = Double(selectedProduct.created_at ?? "0.0") ?? 0.0
            quantity = quantity + scannedVolume
            selectedProduct.created_at = "\(quantity)"
            
            productView.selectedProducts.append(selectedProduct)
        }
        
        collectionView.reloadData()
        
        tableView.deselectRow(at: indexPath, animated: false)
    }
}
