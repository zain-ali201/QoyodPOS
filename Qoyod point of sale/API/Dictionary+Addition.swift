//
//  Dictionary+Addition.swift
//
//  Created by Sharjeel Ahmad on 19/06/2018.
//  Copyright © 2018 Sharjeel Ahmad. All rights reserved.
//

import Foundation

func += <K, V> ( left: inout [K:V], right: [K:V]) {
    for (k, v) in right {
        left[k] = v
    }
}

func + <K,V>(left: Dictionary<K,V>, right: Dictionary<K,V>)
    -> Dictionary<K,V>
{
    var map = Dictionary<K,V>()
    for (k, v) in left {
        map[k] = v
    }
    for (k, v) in right {
        map[k] = v
    }
    return map
}

struct Formatter {
    
    /// Formatter for date time in UTC format `yyyy-MM-dd'T'HH:mm:ss.SSS'Z'`
    static let serverDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter
    }()
    
    static let displayDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter
    }()
}

extension Dictionary where Key == String, Value == Any {
    func timestamp(for key: String) -> Date? {
        let intValue = self.int(for: key)
        if intValue > 0 {
            return Date(timeIntervalSince1970: TimeInterval(intValue))
        } else if let createdDict = self[key] as? [String: Any] {
            return Date(timeIntervalSince1970: TimeInterval(createdDict.int(for: "timestamp")))
        }
        return nil
    }
    
    func int(for key: String) -> Int {
        if let anInt = self[key] as? Int {
            return anInt
        }
        if let aString = self[key] as? String {
            return (aString as NSString).integerValue
        }
        return 0
    }
    
    func bool(for key: String) -> Bool {
        if let aBool = self[key] as? Bool {
            return aBool
        }
        if let aString = self[key] as? String {
            return (aString as NSString).boolValue
        }
        return false
    }
    
    func date(for key: String, formatter: DateFormatter = Formatter.serverDateTime) -> Date? {
        if let value = self[key] as? String, let date = formatter.date(from: value) {
            return date
        }
        return nil
    }
    
    func double(for key: String) -> Double {
        if let aDouble = self[key] as? Double {
            return aDouble
        }
        if let aString = self[key] as? String, let aDouble = Double(aString) {
            return aDouble
        }
        return 0
    }
    
    func string(for key: String) -> String? {
        if let aString = self[key] as? String, aString != "null" {
            let trimmed = aString.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed != "null" {
                return trimmed
            }
        }
        return nil
    }
}
