//
//  EnglishReceiptsImpl.swift
//  Swift SDK
//
//  Created by Yuji on 2016/**/**.
//  Copyright © 2016年 Star Micronics. All rights reserved.
//

import Foundation

class GenericReceiptsImpl: ILocalizeReceipts {
    var orgName:String = ""
    var vatNumber:String = ""
    
    var currencySymbol = ""
    
    override init() {
        super.init()
        
        characterCode = StarIoExtCharacterCode.standard
        orgName = UserDefaults.standard.string(forKey: UserDefaults.Key.orgName) ?? ""
        vatNumber = UserDefaults.standard.string(forKey: UserDefaults.Key.orgVatNo) ?? ""
        currencySymbol = UserDefaults.standard.string(forKey: UserDefaults.Key.orgCurrencySymbol) ?? "$"
    }
    
    override func create2inchRasterReceiptImage() -> UIImage {
        
        var textToPrint = ""
        
        var orgImgText = ""
        
        if (orgImage != nil)
        {
            let imageData:NSData = UIImagePNGRepresentation(orgImage)! as NSData
            let strBase64 = imageData.base64EncodedString(options: .lineLength64Characters)
            orgImgText = String(format: "<img src='data:image/png;base64, %@' width = '350' height = '230'/>",strBase64)
        }
        
        if languageCode == "ar"
        { //arabic language
            var resultTitle = ""
            
            for product in invoice?.invoice_products ?? []
            {
                var name = String(product.name ?? "-")
                
                let shortName = String(name.prefix(10))
                let quantity = product.quantity ?? "1.00"
                let price = product.row_total ?? "0.00"
                
                resultTitle += "\u{200E}" + getPaddedString(str1:price , str2: quantity, str3: shortName) + "\u{200E}"
                
                if name.count > 10 {
                    name.removeSubrange(name.startIndex..<name.index(name.startIndex, offsetBy: 10))
                    resultTitle += "\n"
                    resultTitle += "\u{200F}" +  fillExtraSpace(str: String(name.prefix(25))) +  "\u{200F}" + "\n"
                }
                
                resultTitle += "\n"
            }
            
            let orgNameCentered = getPaddedString(str: orgName)
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM/dd/YYYY"
            dateFormatter.calendar = Calendar(identifier: .gregorian)
            dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
            
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:MM"
            timeFormatter.calendar = Calendar(identifier: .gregorian)
            timeFormatter.timeZone = TimeZone(abbreviation: "UTC")
            
            let footer =  getPaddedString(str:"زورنا مرة أخرى")
            
            textToPrint = "\u{200F}        " + orgNameCentered + "        \u{200F}\r\n\n"
                + "\u{200F}" + "التاريخ:" + "\u{200F}" + dateFormatter.string(from: Date()) + "         " + "\u{200F}" + "الوقت:" + "\u{200F}" + timeFormatter.string(from: Date()) + "\u{200F}" + "\r\n"
                + "\r\n\n"
                +  "\u{200F}" +  fillExtraSpace(str: "الرقم الضريبي: " + vatNumber ) + "\u{200F}" + "\n"
                + "\u{200F}" + "فاتورة نقاط البيع #" + " " + posNo + "\u{200F}" + "\n"
                + "--------------------------------\r\n\n"
                + "\u{200F}" + "المنتج                الكمية                    السعر" + "\u{200F}" + "\n\n"
                + "\u{200E}" + resultTitle + "\u{200E}" + "</br></br>"
                + "\u{200F}" + "المجموع الفرعي" + "              " + subTotal + "\u{200F}" + "\n"
                + "\u{200F}" + "ضريبة القيمة المضافة" + "        " + taxAmount + "\u{200F}" + "\n"
                + "--------------------------------\r\n"
                + "\u{200F}" + "المجموع" + "                 " + total + " " + currencySymbol + "\u{200F}" + "\n"
                + "--------------------------------\r\n";
//                + "\r\n\n"
//                + "\u{200F}" + footer + "\u{200F} \n"
        }
        else
        {
            var resultTitle = ""
            
            for product in invoice?.invoice_products ?? [] {
                var name = product.name ?? "-"
                
                let shortName = name.prefix(10);
                let quantity = product.quantity ?? "1.00"
                let price = product.row_total ?? "0.00"
                
                resultTitle += String(shortName) + "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;" + quantity + "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;" + price
                
                if name.count > 10 {
                    name.removeSubrange(name.startIndex..<name.index(name.startIndex, offsetBy: 10))
                    resultTitle += "</br>"
                    resultTitle += name.prefix(25) + "</br></br>"
                }
                
                resultTitle += "</br>"
            }
            
            let orgNameCentered = getPaddedString(str: orgName)
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM/dd/YYYY"
            
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:MM"
            
            var accountsHTML = ""
            
            if receiptCount > 1
            {
                let accountsArray = accountStr.components(separatedBy: ",")
                
                for amountStr in accountsArray
                {
                    if !amountStr.isEmpty
                    {
                        accountsHTML = accountsHTML + "\(amountStr)</br>"
                    }
                }
            }
            
            if changeAmount > 0
            {
                accountsHTML = accountsHTML + "Change: \(changeAmount)</br>"
            }
            
            textToPrint = "<html><meta http-equiv='Content-Type' content='text/html;charset=UTF-8'><div style='font-size:20px; font-family:Arial;' align = 'center'><span'>" + orgImgText + "</span></br></br>"
                + "<span>" + orgNameCentered + "</span></br></br>"
                + "         Date:" + dateFormatter.string(from: Date()) + "&nbsp;&nbsp;&nbsp;&nbsp;" + "Time:" + timeFormatter.string(from: Date()) + "</br>"
//                + "         Vat # " + vatNumber + "</br>"
//                + "         POS Invoice #" + posNo + "</br>"
                + accountsHTML
                + "         --------------------------------</br></br>"
                + "Product &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; Quantity &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; Price</br></br>"
                + resultTitle + "</br></br>"
                + "Sub Total : " + subTotal + "</br>"
                + "Vat : " + taxAmount + "</br>"
                + "--------------------------------</br>"
                + "Total : " + total + "</br>"
                + "--------------------------------</br></div></html>";
//                + "\r\n\n"
//                + "                            Visit Us Again        \n";
        }
        
        let font: UIFont = UIFont.systemFont(ofSize: 30)
        
        return ILocalizeReceipts.imageWithString(textToPrint, font: font, width: 384)     // 2inch(384dots)
    }
    
    func fillExtraSpace(str:String , totalSpace:Int = 32) -> String{
        if str.count < totalSpace {
            return str + whiteSpace(count: totalSpace - str.count)
        }
        return str
    }
    
    func whiteSpace(count:Int) -> String {
        var space = ""
        for _ in 0..<count {
            space += " "
        }
        return space
    }
    
    //for centered multiple strings
    func getPaddedString(str1:String, str2:String , str3:String) -> String{
        
        var finalString = ""
        let maxPadding = 50 //Assuming total space
        let center = maxPadding / 2
        
        finalString += str1
        
        var padding = center - str1.count - (str2.count / 2) //assuming str1 is always shorter than half i.e less than 15
        
        for _ in 0..<padding {
            finalString += " "
        }
        
        //now we are at center
        finalString += str2
        
        let spaceLeft = maxPadding - finalString.count
        padding = spaceLeft - str3.count - (13 - str3.count)
        
        for _ in 0..<padding {
            finalString += " "
        }
        
        finalString += str3
        return finalString
    }
    
    //for centered string
    func getPaddedString(str:String) -> String{
        
        let maxPadding = 50 //This is what you have to decide
        let length = str.count
        let padding = (maxPadding - length) / 2 //decide left and right padding
        if padding <= 0 {
            return str // return actual String if padding is less than or equal to 0
        }
        
        // extra character in case of String with even length
        let extra = (length % 2 == 0) ? 1 : 0
        
        var finalString = ""
        for _ in 0..<padding {
            finalString += " "
        }
        
        finalString += str
        
        for _ in 0..<padding+extra {
            finalString += " "
        }
        
        return finalString
    }
}
