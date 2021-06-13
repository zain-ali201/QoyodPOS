//
//  CommonManager.swift
//  BenefitNet
//
//  Created by Sharjeel Ahmad on 27/04/2018.
//  Copyright © 2018 Inova Care. All rights reserved.
//

import UIKit

typealias GetImageHandler = (UIImage?, Error?) -> ()

class CommonManager {
    
    static let shared = CommonManager()
    
    private var completionHandlersForimageUrls = [String: [GetImageHandler]]()
    /// Contains profile images cache for policy code
    var imagesCache = NSCache<NSString, ImageCache>()
    func getImage(forUrl imageUrl: String, completionHandler: @escaping GetImageHandler) {
        if let oldHandlers = completionHandlersForimageUrls[imageUrl], !oldHandlers.isEmpty {
            // already loading image for the policy code. Only add the completion handler
            var new = oldHandlers
            new.append(completionHandler)
            completionHandlersForimageUrls[imageUrl] = new
            return
        }
        var completionHandlers = completionHandlersForimageUrls[imageUrl] ?? [GetImageHandler]()
        completionHandlers.append(completionHandler)
        completionHandlersForimageUrls[imageUrl] = completionHandlers
        
        if let image = imagesCache.object(forKey: imageUrl as NSString) {
            for completionHandler in completionHandlersForimageUrls[imageUrl]! {
                completionHandler(image.image, nil)
            }
            completionHandlersForimageUrls[imageUrl] = []
            return
        }
        
        // now get the image
        API.get("", baseUrl: imageUrl, params: [:], contentType: .plainText, cachePolicy: .returnCacheDataElseLoad).data { (data, response, error) in
            if let error = error {
                for completionHandler in self.completionHandlersForimageUrls[imageUrl]! {
                    completionHandler(nil, error)
                }
            } else {
                if let data = data, let image = UIImage(data: data) {
                    loggingPrint("Downloaded image")
                    let cacheImage = ImageCache()
                    cacheImage.image = image
                    self.imagesCache.setObject(cacheImage, forKey: imageUrl as NSString)
                    for completionHandler in self.completionHandlersForimageUrls[imageUrl]! {
                        completionHandler(image, nil)
                    }
                } else {
                    for completionHandler in self.completionHandlersForimageUrls[imageUrl]! {
                        completionHandler(nil, NetworkError.unknown)
                    }
                }
            }
            self.completionHandlersForimageUrls[imageUrl] = []
        }
    }
}

//to persist images in cache
class ImageCache: NSObject , NSDiscardableContent {
    
    public var image: UIImage!
    
    func beginContentAccess() -> Bool {
        return true
    }
    
    func endContentAccess() {
        
    }
    
    func discardContentIfPossible() {
        
    }
    
    func isContentDiscarded() -> Bool {
        return false
    }
}
