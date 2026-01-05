//
//  UnitFormatter.swift
//  Health App
//
//  Unit formatting utilities for consistent display
//

import Foundation

/// Extension for formatting values with user's preferred units
extension UserSettings {
    /// Format weight value using user's preferred unit
    /// - Parameters:
    ///   - kg: Weight value in kilograms (stored format)
    ///   - decimals: Number of decimal places (default: 1)
    /// - Returns: Formatted string with unit abbreviation (e.g., "70.5 kg" or "155.4 lbs")
    func formatWeight(_ kg: Double, decimals: Int = 1) -> String {
        let converted = weightUnit.convert(fromKg: kg)
        return String(format: "%.\(decimals)f \(weightUnit.abbreviation)", converted)
    }

    /// Format weight change/delta value using user's preferred unit
    /// - Parameters:
    ///   - kgChange: Weight change in kilograms (stored format)
    ///   - decimals: Number of decimal places (default: 1)
    ///   - showSign: Whether to show + sign for positive values (default: true)
    /// - Returns: Formatted string with unit abbreviation (e.g., "+2.5 kg" or "-5.5 lbs")
    func formatWeightChange(_ kgChange: Double, decimals: Int = 1, showSign: Bool = true) -> String {
        let converted = weightUnit.convert(fromKg: kgChange)
        let sign = showSign && converted >= 0 ? "+" : ""
        return String(format: "\(sign)%.\(decimals)f \(weightUnit.abbreviation)", converted)
    }

    /// Format height value using user's preferred unit
    /// - Parameter cm: Height value in centimeters (stored format)
    /// - Returns: Formatted string with unit (e.g., "175 cm" or "5'9\"")
    func formatHeight(_ cm: Double) -> String {
        let converted = heightUnit.convert(fromCm: cm)
        switch heightUnit {
        case .cm:
            return "\(converted.primary) \(heightUnit.abbreviation)"
        case .feet:
            if let inches = converted.secondary {
                return "\(converted.primary)'\(inches)\""
            }
            return "\(converted.primary) ft"
        }
    }

    /// Format distance value using user's preferred unit
    /// - Parameters:
    ///   - meters: Distance value in meters (stored format)
    ///   - decimals: Number of decimal places (default: 1)
    /// - Returns: Formatted string with unit abbreviation (e.g., "5.2 km" or "3.2 mi")
    func formatDistance(_ meters: Double, decimals: Int = 1) -> String {
        let converted = distanceUnit.convert(fromMeters: meters)
        return String(format: "%.\(decimals)f \(distanceUnit.abbreviation)", converted)
    }

    /// Get just the converted weight value (no string formatting)
    func convertWeight(_ kg: Double) -> Double {
        return weightUnit.convert(fromKg: kg)
    }

    /// Get just the converted distance value (no string formatting)
    func convertDistance(_ meters: Double) -> Double {
        return distanceUnit.convert(fromMeters: meters)
    }
}

/// Global convenience functions for unit formatting
struct UnitFormatter {
    private static var settings: UserSettings {
        UserSettings.load()
    }

    /// Format weight with user's preferred units
    static func formatWeight(_ kg: Double, decimals: Int = 1) -> String {
        settings.formatWeight(kg, decimals: decimals)
    }

    /// Format weight change/delta with user's preferred units
    static func formatWeightChange(_ kgChange: Double, decimals: Int = 1, showSign: Bool = true) -> String {
        settings.formatWeightChange(kgChange, decimals: decimals, showSign: showSign)
    }

    /// Format height with user's preferred units
    static func formatHeight(_ cm: Double) -> String {
        settings.formatHeight(cm)
    }

    /// Format distance with user's preferred units
    static func formatDistance(_ meters: Double, decimals: Int = 1) -> String {
        settings.formatDistance(meters, decimals: decimals)
    }

    /// Get weight unit abbreviation
    static var weightUnit: String {
        settings.weightUnit.abbreviation
    }

    /// Get height unit abbreviation
    static var heightUnit: String {
        settings.heightUnit.abbreviation
    }

    /// Get distance unit abbreviation
    static var distanceUnit: String {
        settings.distanceUnit.abbreviation
    }
}
