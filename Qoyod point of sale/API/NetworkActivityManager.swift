//
//  NetworkActivityManager.swift
//
//  Created by Sharjeel Ahmad on 01/01/2018.
//  Copyright © 2018 Qoyod. All rights reserved.
//

import UIKit

class NetworkActivityManager: NSObject {
    static private let shared = NetworkActivityManager()
    private var actions = 0
    private var hideTimer: Timer?
    static func show() {
        shared.actions += 1
        shared.recheckIndicator()
    }
    static func hide() {
        shared.actions -= 1
        shared.recheckIndicator()
    }
    private func recheckIndicator() {
        DispatchQueue.main.async {
            if self.actions > 0 {
                if self.hideTimer != nil {
                    self.hideTimer?.invalidate()
                    self.hideTimer = nil
                }
                if !UIApplication.shared.isNetworkActivityIndicatorVisible {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = true
                }
            } else {
                if UIApplication.shared.isNetworkActivityIndicatorVisible {
                    //UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    // start the timer to hide after a bit to ensure another task isn't queued to begin right after
                    if self.hideTimer == nil {
                        self.hideTimer = Timer.scheduledTimer(timeInterval: 0.3, target: self, selector: #selector(NetworkActivityManager.timerFired(_:)), userInfo: nil, repeats: false)
                    }
                }
            }
        }
    }
    
    @objc private func timerFired(_ sender: Timer) {
        hideTimer?.invalidate()
        hideTimer = nil
        if actions == 0 && UIApplication.shared.isNetworkActivityIndicatorVisible {
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        }
    }
}
