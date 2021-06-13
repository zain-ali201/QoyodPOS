//
//  ILocalizeReceipts.swift
//  Swift SDK
//
//  Created by Yuji on 2016/**/**.
//  Copyright © 2016年 Star Micronics. All rights reserved.
//

import Foundation

class LocalizeReceipts
{
    static func createLocalizeReceipts(paperSizeIndex: PaperSizeIndex, invoice: Invoice , taxAmount:String, subTotal:String , total:String) -> ILocalizeReceipts {
        var localizeReceipts: ILocalizeReceipts
        
        localizeReceipts = GenericReceiptsImpl()
        
        localizeReceipts.paperSize      = "2\""
        localizeReceipts.scalePaperSize = "3\""     // 3inch -> 2inch
        
        localizeReceipts.paperSizeIndex = paperSizeIndex
        
        localizeReceipts.invoice = invoice
        localizeReceipts.posNo = invoice.invoice.pos_invoice_no ?? ""
        localizeReceipts.taxAmount = taxAmount
        localizeReceipts.subTotal = subTotal
        localizeReceipts.total = total
        
        return localizeReceipts
    }
    
    static func createLocalizeReceipts() -> ILocalizeReceipts
    {
        var localizeReceipts: ILocalizeReceipts
        
        localizeReceipts = GenericReceiptsImpl()
        
        localizeReceipts.paperSize      = "2\""
        localizeReceipts.scalePaperSize = "3\""
        
        return localizeReceipts
    }
}


class ILocalizeReceipts
{
    fileprivate var paperSizeIndex: PaperSizeIndex!    
    var paperSize:      String!
    var scalePaperSize: String!
    var characterCode:  StarIoExtCharacterCode!
    var invoice:        Invoice?
    var taxAmount = ""
    var subTotal = ""
    var total = ""
    var posNo = ""
    
    func createRasterReceiptImage() -> UIImage? {
        let image: UIImage?
        image = self.create2inchRasterReceiptImage()!
        return image
    }
    
    func create2inchRasterReceiptImage() -> UIImage? {     // abstract!!!
        return nil
    }
    
    func appendTextReceiptData(_ builder: ISCBBuilder, utf8: Bool) {
        self.append2inchTextReceiptData(builder, utf8: utf8)
    }
    
    func append2inchTextReceiptData(_ builder: ISCBBuilder, utf8: Bool) {     // abstract!!!
    }
    
    static func imageWithString(_ string: String, font: UIFont, width: CGFloat) -> UIImage {
        
//        let languageCode = Locale.current.languageCode
//
//        if languageCode == "ar"
//        {
//            let attributeDic: NSDictionary = NSDictionary(dictionary: [NSAttributedStringKey.font : font])
//
//            let stringDrawingOptions: NSStringDrawingOptions = [NSStringDrawingOptions.usesLineFragmentOrigin, NSStringDrawingOptions.truncatesLastVisibleLine]
//
//            let size: CGSize = (string.boundingRect(with: CGSize(width: width, height: 10000), options: stringDrawingOptions, attributes: attributeDic as? [NSAttributedStringKey : Any], context: nil)).size
//
//            if UIScreen.main.responds(to: #selector(NSDecimalNumberBehaviors.scale)) {
//                if UIScreen.main.scale == 2.0 {
//                    UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
//                } else {
//                    UIGraphicsBeginImageContext(size)
//                }
//            } else {
//                UIGraphicsBeginImageContext(size)
//            }
//
//            let context: CGContext = UIGraphicsGetCurrentContext()!
//
//            UIColor.white.set()
//
//            let rect: CGRect = CGRect(x: 0, y: 0, width: size.width + 1, height: size.height + 1)
//
//            context.fill(rect)
//
//            let attributes: NSDictionary = NSDictionary(dictionary: [NSAttributedStringKey.foregroundColor : UIColor.black, NSAttributedStringKey.font : font])
//
//            string.draw(in: rect, withAttributes: attributes as? [NSAttributedStringKey : Any])
//
//            let imageToPrint: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
//
//
//
//            UIGraphicsEndImageContext()
//
//            return imageToPrint
//        }
//        else
//        {
            let data = Data(string.utf8)

            let attributedString = try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil)

            UIGraphicsBeginImageContextWithOptions(attributedString!.size(), false, 0.0);
            attributedString!.draw(at: CGPoint(x: 0, y: 0))

            let imageToPrint: UIImage = UIGraphicsGetImageFromCurrentImageContext()!

            UIGraphicsEndImageContext()

            return imageToPrint;
//        }
        
    }
}
