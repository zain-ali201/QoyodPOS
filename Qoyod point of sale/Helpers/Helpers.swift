//
//  Helpers.swift
//  Qoyod
//
//  Created by Sharjeel Ahmad on 05/12/2017.
//  Copyright © 2017 Qoyod. All rights reserved.
//

import UIKit

extension Notification.Name {
    static let syncData = Notification.Name(rawValue: "Qoyod.Notification.Name.SyncData")
    static let resetSelection = Notification.Name(rawValue: "Qoyod.Notification.Name.ResetSelection")
}

extension UserDefaults {
    struct Key {
        static let isLoggedIn = "Qoyod.Key.isloggedin"
        static let isLocked = "Qoyod.Key.islocked"
        static let token = "Qoyod.Key.logintoken"
        static let identifier = "Qoyod.Key.orgid"
        static let orgName = "Qoyod.Key.orgname"
        static let orgLogo = "Qoyod.Key.orglogo"
        static let orgIdentifier = "Qoyod.Key.orgindetifier"
        static let orgLocationId = "Qoyod.Key.orglocid"
        static let orgAccountId = "Qoyod.Key.orgaccid"
        static let orgVatNo = "Qoyod.Key.orgvatno"
        static let orgCurrencySymbol = "Qoyod.Key.orgcurrency"
        static let pinCode = "Qoyod.Key.pincode"
        static let tokenExpires = "Qoyod.Key.expiresIn"
        static let username = "Qoyod.Key.username"
        static let biometricConfigured = "Qoyod.Key.biometric.configured"
    }
}

struct Constant { //for storing password in keychain
    static let service = "keychain"
    static let account = "qoyod"
}

extension String {
    public var isEmail: Bool {
        let dataDetector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let firstMatch = dataDetector?.firstMatch(in: self, options: .reportCompletion, range: NSRange(location: 0, length: count))
        return (firstMatch?.range.location != NSNotFound && firstMatch?.url?.scheme == "mailto")
    }
}

extension Double {
    /// Rounds the double to decimal places value
    func rounded(toPlaces places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

