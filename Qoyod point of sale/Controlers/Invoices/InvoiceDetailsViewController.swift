//
//  InvoiceDetailsViewController.swift
//  Qoyod point of sale
//
//  Created by Sharjeel Ahmad on 03/09/2018.
//  Copyright © 2018 Sharjeel Ahmad. All rights reserved.
//

import UIKit

class InvoiceDetailsTableViewCell: UITableViewCell {
    @IBOutlet weak var imgView: UIImageView!
    @IBOutlet weak var rate: UILabel!
    @IBOutlet weak var amount: UILabel!
    @IBOutlet weak var quantity: UILabel!
    @IBOutlet weak var percentage: UILabel!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var quantityV: UILabel!
    @IBOutlet weak var lblTax: UILabel!
    @IBOutlet weak var stock: UILabel!
    @IBOutlet weak var sku: UILabel!
}

class InvoiceDetailsViewController: UIViewController {
    
    //Invoice selected on previous screen
    var invoice:Invoice!
    var taxes:[Tax]!
    var totalPayable = 0.0
    
    @IBOutlet weak var invoiceNumber: UILabel!
    @IBOutlet weak var createdDate: UILabel!
    @IBOutlet weak var customerName: UILabel!
    @IBOutlet weak var customerPhone: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var beforeTax: UILabel!
    @IBOutlet weak var taxAmount: UILabel!
    @IBOutlet weak var total: UILabel!
    @IBOutlet weak var payButton: UIButton!
    
    @IBOutlet weak var lblRemaining: UILabel!
    @IBOutlet weak var lblRemainingAmount: UILabel!
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    var paymentDialog:PaymentViewController!
    @IBOutlet weak var paymentView: UIView!
    var paymentSuccessDialog:PaymentConfirmationViewController!
    @IBOutlet weak var paymentSuccessView: UIView!
    
    @IBOutlet weak var lblTotalTitle: UILabel!
    @IBOutlet weak var lblTaxTitle: UILabel!
    @IBOutlet weak var lblAmountTitle: UILabel!
    @IBOutlet weak var lblRemainingTitle: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadData()
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        lblTotalTitle.text = languageBundle!.localizedString(forKey: "Total", value: "", table: nil)
        lblAmountTitle.text = languageBundle!.localizedString(forKey: "Tax Amount", value: "", table: nil)
        lblTaxTitle.text = languageBundle!.localizedString(forKey: "Before Tax", value: "", table: nil)
        lblRemainingTitle.text = languageBundle!.localizedString(forKey: "Remaining", value: "", table: nil)
    }
    
    @IBAction func searchTaped(_ sender: UIButton) {
    }
    
    @IBAction func goBack(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func payTapped(_ sender: UIButton)
    {
        showActivityIndicator()
        sender.isUserInteractionEnabled = false
        InvoicesManager.shared.getCustomerAccounts {[weak self] (accounts, error) in
            self?.hideActivityIndicator()
            if let error = error
            {
                loggingPrint(error)
            }
            else if let accounts = accounts
            {
                let currencySymbol = UserDefaults.standard.string(forKey: UserDefaults.Key.orgCurrencySymbol) ?? ""
                
                self?.paymentDialog.accounts = accounts
                self?.paymentDialog.mainView = self?.paymentView
                self?.paymentDialog.paymentSuccessVC = self?.paymentSuccessDialog
                self?.paymentDialog.paymentSuccessView = self?.paymentSuccessView
                self?.paymentDialog.tblView.reloadData()
                self?.paymentDialog.totalAmount = Double(String(format: "%@", self?.invoice.invoice.total ?? "0.0")) ?? 0.0
                self?.paymentDialog.invoice = self?.invoice
                self?.paymentDialog.dueAmount = Double(String(format: "%@", self?.invoice.invoice.due_amount ?? "0.0")) ?? 0.0
                self?.paymentDialog.invoiceNo = self?.invoiceNumber.text ?? ""
                self?.paymentDialog.lblTotal.text = "\(self?.invoice.invoice.total ?? "0.0")"
                self?.paymentDialog.lblRemaining.text = "\(self?.invoice.invoice.due_amount ?? "0.0")"
                
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
                self?.paymentSuccessDialog.totalLabel.text = "\(self?.totalPayable ?? 0) \(currencySymbol)"
                self?.paymentSuccessDialog.invoiceNo.text = "\(languageBundle!.localizedString(forKey: "POS invoice #", value: "", table: nil)) \((self?.invoiceNumber.text)!)"
                self?.paymentSuccessDialog.posInvoiceNo = self?.invoiceNumber.text!
                self?.paymentSuccessDialog.tax = self?.taxAmount.text!
                self?.paymentSuccessDialog.beforeTax = self?.beforeTax.text!
                self?.paymentSuccessDialog.afterTax = "\(self?.totalPayable ?? 0)"
                self?.paymentSuccessDialog.customerName.text = languageBundle!.localizedString(forKey: "Customer Name ", value: "", table: nil) + " " + (self?.customerName.text)!
                self?.paymentSuccessDialog.customerNo.text = languageBundle!.localizedString(forKey: "Customer Phone", value: "", table: nil) + " " + (self?.customerPhone.text != nil ? (self?.customerPhone.text)! : "")
                self?.view.bringSubview(toFront: (self?.paymentSuccessView)!)
            }
        }
    }

    func loadData() {
        //hide pay button if piad
        if invoice.invoice.status ?? "" == "Paid"
        {
            payButton.removeFromSuperview()
            heightConstraint.constant = 100
        }
        
        //Loading Invoice detials
        invoiceNumber.text = invoice.invoice.pos_invoice_no
        createdDate.text = ""
        if let date = invoice.invoice.created_at  , let serverDate = Formatter.serverDateTime.date(from: date){
            createdDate.text = Formatter.displayDateTime.string(from: serverDate)
        }
        customerName.text = invoice.customer_detail.contact_name
        customerPhone.text = invoice.customer_detail.primary_contact_number
        
        //calculating amount
        var totalPrice = 0.0
        var taxValue = 0.0
        for product in invoice.invoice_products ?? []
        {
            if var price = Double(product.rate ?? "0"),
                let discount = Double(product.discount_percentage ?? "0")
            {
                
                price = price * Double(product.quantity ?? "1")!
                
                var discountedPrice = price
                if discount > 0 {
                    discountedPrice = price - ( price * (discount / 100.0))
                }
                
                totalPrice = totalPrice + discountedPrice.rounded(toPlaces: 2)
                totalPrice = totalPrice.rounded(toPlaces: 2)
                
                let taxPercent = Double(taxPercentage(productId: product.product_id ?? 0))
                if taxPercent > 0 {
                    taxValue = taxValue + ( discountedPrice * (taxPercent / 100.0))
                }
            }
        }
        
        totalPayable = totalPrice + taxValue.rounded(toPlaces: 2)
        totalPayable = totalPayable.rounded(toPlaces: 2)
        let currencySymbol = UserDefaults.standard.string(forKey: UserDefaults.Key.orgCurrencySymbol) ?? ""
        
        beforeTax.text = "\(totalPrice.rounded(toPlaces: 2)) \(currencySymbol)"
        taxAmount.text = "\(taxValue.rounded(toPlaces: 2)) \(currencySymbol)"
        total.text = "\(totalPayable.rounded(toPlaces: 2)) \(currencySymbol)"
//        paidAmount = Double(invoice.invoice.paid_amount ?? "0.0")
        
        var remainingAmount = Double(invoice.invoice.due_amount ?? "0.0")
        if remainingAmount! > 0.0
        {
            lblRemainingAmount.text = String(format: "%.1f", remainingAmount!)
            totalPayable = remainingAmount ?? 0.0
        }
        else
        {
            remainingAmount = totalPayable
        }
        payButton.setTitle("   \(languageBundle!.localizedString(forKey: "Pay", value: "", table: nil)) \(remainingAmount ?? 0.0) \(currencySymbol)   ", for: .normal)
        
    }
    
//    func taxPercentage(productId:Int) -> Int{
//        for tax in taxes {
//            if tax.id == productId {
//                return tax.percentage ?? 0
//            }
//        }
//
//        return 0
//    }
    
    func taxPercentage(productId:Int) -> Int
    {
        for product in allProducts
        {
            if product.id == productId {
                for tax in taxes {
                    if tax.id == product.tax_id {
                        return tax.percentage ?? 0
                    }
                }
            }
        }

        return 0
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let paymentScreen = segue.destination as? PaymentViewController {
            paymentDialog = paymentScreen
        }
        if let paymentSuccessScreen = segue.destination as? PaymentConfirmationViewController {
            paymentSuccessDialog = paymentSuccessScreen
        }
        
    }
}

extension InvoiceDetailsViewController: UITableViewDelegate {
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
}

extension InvoiceDetailsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return invoice.invoice_products?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as? InvoiceDetailsTableViewCell else{
            return UITableViewCell()
        }
        
        if let products =  invoice.invoice_products{
            let account = products[indexPath.row]
            
            let imageUrl = account.url
            cell.imgView.image = nil

            if imageUrl != nil
            {
                CommonManager.shared.getImage(forUrl: imageUrl!) { (image, error) in
                    if let image = image
                    {
                        cell.imgView.image = image
                    }
                }
            }
            
            cell.name.text = account.name
            cell.sku.text = String(format: "%@: %@",languageBundle!.localizedString(forKey:"SKU", value: "", table: nil) ,account.sku ?? "-")
            cell.percentage.text = "\(account.discount_percentage ?? "")%"
            cell.quantity.text = "\(account.quantity ?? " ")"
            
            cell.amount.text =  String(format: "%@/%@", account.rate ?? "0.0", account.unit_name ?? "")
            var taxValue = "0"
            
            if account.tax_percentage != nil && account.tax_percentage! > 0
            {
                let tax = Double(account.tax_percentage!)
                
                if tax > 0
                {
                    taxValue = String(format: "%.2f", tax)
                }
            }
            cell.lblTax.text = taxValue + "%"
            
        }
        
        return cell
    }
}
