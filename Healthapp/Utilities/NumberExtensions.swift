//
//  NumberExtensions.swift
//  Health App
//
//  Extensions for numeric types
//

import Foundation

extension Double {
    /// Round to specified decimal places
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
    
    /// Format as string with specified decimal places
    func formatted(decimalPlaces: Int) -> String {
        return String(format: "%.\(decimalPlaces)f", self)
    }
    
    /// Convert kg to lbs
    var kgToLbs: Double {
        return self * 2.20462
    }
    
    /// Convert lbs to kg
    var lbsToKg: Double {
        return self / 2.20462
    }
    
    /// Convert cm to inches
    var cmToInches: Double {
        return self / 2.54
    }
    
    /// Convert inches to cm
    var inchesToCm: Double {
        return self * 2.54
    }
    
    /// Convert meters to kilometers
    var metersToKm: Double {
        return self / 1000.0
    }
    
    /// Convert meters to miles
    var metersToMiles: Double {
        return self / 1609.34
    }
}

extension Int {
    /// Format as calorie string (e.g., "1,234 cal")
    var calorieString: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return "\(formatter.string(from: NSNumber(value: self)) ?? "\(self)") cal"
    }
    
    /// Format as gram string (e.g., "125 g")
    var gramString: String {
        return "\(self) g"
    }
}

