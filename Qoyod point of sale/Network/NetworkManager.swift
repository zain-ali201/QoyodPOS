//
//  NetworkManager.swift
//  Qoyod
//
//  Created by Sharjeel Ahmad on 01/01/2018.
//  Copyright © 2018 Qoyod. All rights reserved.
//

import Foundation

class NetworkManager {
    static let shared = NetworkManager()
}

public enum NetworkError: Error {
    case unknown
    case message(String)
    case codedMessage(String, Int)
}

extension NetworkError: LocalizedError {
    public var localizedDescription: String {
        switch self {
        case .unknown:
            return languageBundle!.localizedString(forKey: "An unknown error occurred", value: "", table: nil)
        case .message(let value):
            return value
        case .codedMessage(let value, let code):
            return "\(value)" + " (" + languageBundle!.localizedString(forKey: "Error Code", value: "", table: nil) + ": \(NumberFormatter.localizedString(from: code as NSNumber, number: .none))"
        }
    }
    
    public var errorDescription: String? {
        return localizedDescription
    }
}
