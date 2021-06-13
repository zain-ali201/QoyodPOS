
//
//  Reachability+Shared.swift
//  Qoyod
//
//  Created by Sharjeel Ahmad on 22/12/2017.
//  Copyright © 2017 Qoyod. All rights reserved.
//

import UIKit
import Reachability

extension Reachability
{
    static let reachability = Reachability()!

    static var isReachable = false
    static func stopMonitoring() {
        reachability.stopNotifier()
    }
    
    static func startMonitoring()
    {
        reachability.whenReachable = { reachability in
            self.isReachable = true
            if reachability.connection == .wifi
            {
                print("Reachable via WiFi")
            }
            else
            {
                print("Reachable via Cellular")
            }
        }
        reachability.whenUnreachable = { _ in
            self.isReachable = false
        }
        
        do {
            try reachability.startNotifier()
        } catch {
            print("Unable to start notifier")
        }
    }
}
