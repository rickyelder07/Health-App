//
//  AccessibilityExtensions.swift
//  Health App
//
//  Accessibility utilities and extensions
//

import SwiftUI

// MARK: - View Extensions for Accessibility

extension View {
    /// Add accessibility label and hint
    func accessible(label: String, hint: String? = nil, traits: AccessibilityTraits = []) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(traits)
    }

    /// Make view accessible as a button
    func accessibleButton(label: String, hint: String? = nil) -> some View {
        self.accessible(label: label, hint: hint, traits: .isButton)
    }

    /// Make view accessible as a header
    func accessibleHeader(label: String) -> some View {
        self.accessible(label: label, traits: .isHeader)
    }

    /// Hide from accessibility
    func hideFromAccessibility() -> some View {
        self.accessibilityHidden(true)
    }

    /// Support Dynamic Type
    func dynamicTypeSize(min: DynamicTypeSize = .xSmall, max: DynamicTypeSize = .xxxLarge) -> some View {
        if #available(iOS 15.0, *) {
            return AnyView(self.dynamicTypeSize(...max))
        } else {
            return AnyView(self)
        }
    }
}

// MARK: - Accessibility Modifiers

struct AccessibleCard: ViewModifier {
    let label: String
    let hint: String?

    func body(content: Content) -> some View {
        content
            .accessibilityElement(children: .combine)
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(.isButton)
    }
}

extension View {
    func accessibleCard(label: String, hint: String? = nil) -> some View {
        modifier(AccessibleCard(label: label, hint: hint))
    }
}

// MARK: - Color Contrast Helpers

extension Color {
    /// Check if color meets WCAG AA contrast ratio (4.5:1) against background
    func hassufficientContrast(against background: Color) -> Bool {
        let ratio = contrastRatio(with: background)
        return ratio >= 4.5
    }

    /// Calculate contrast ratio between two colors
    func contrastRatio(with other: Color) -> Double {
        let l1 = relativeLuminance()
        let l2 = other.relativeLuminance()
        let lighter = max(l1, l2)
        let darker = min(l1, l2)
        return (lighter + 0.05) / (darker + 0.05)
    }

    private func relativeLuminance() -> Double {
        // Simplified luminance calculation
        // In production, you'd want to properly extract RGB components
        return 0.5 // Placeholder
    }
}

// MARK: - VoiceOver Announcements

struct VoiceOverAnnouncement {
    /// Announce a message to VoiceOver users
    static func announce(_ message: String, priority: AccessibilityAnnouncementPriority = .default) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            #if os(iOS)
            UIAccessibility.post(notification: .announcement, argument: message)
            #endif
        }
    }

    enum AccessibilityAnnouncementPriority {
        case `default`
        case high

        #if os(iOS)
        var uiValue: UIAccessibility.Notification {
            switch self {
            case .default:
                return .announcement
            case .high:
                return .screenChanged
            }
        }
        #endif
    }
}

// MARK: - Accessibility Utilities

struct AccessibilityUtility {
    /// Check if VoiceOver is running
    static var isVoiceOverRunning: Bool {
        #if os(iOS)
        return UIAccessibility.isVoiceOverRunning
        #else
        return false
        #endif
    }

    /// Check if Bold Text is enabled
    static var isBoldTextEnabled: Bool {
        #if os(iOS)
        return UIAccessibility.isBoldTextEnabled
        #else
        return false
        #endif
    }

    /// Check if Reduce Motion is enabled
    static var isReduceMotionEnabled: Bool {
        #if os(iOS)
        return UIAccessibility.isReduceMotionEnabled
        #else
        return false
        #endif
    }

    /// Check if Switch Control is running
    static var isSwitchControlRunning: Bool {
        #if os(iOS)
        return UIAccessibility.isSwitchControlRunning
        #else
        return false
        #endif
    }
}

// MARK: - Reduce Motion Modifier

struct ReduceMotionModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    let animation: Animation
    let reducedAnimation: Animation

    func body(content: Content) -> some View {
        content
            .animation(reduceMotion ? reducedAnimation : animation, value: UUID())
    }
}

extension View {
    /// Apply animation that respects Reduce Motion setting
    func reducibleAnimation(_ animation: Animation = .default, reduced: Animation = .linear(duration: 0.1)) -> some View {
        modifier(ReduceMotionModifier(animation: animation, reducedAnimation: reduced))
    }
}

// MARK: - Sample Accessibility Labels

enum AccessibilityLabels {
    // Food Logging
    static let logFoodButton = "Log food"
    static let logFoodHint = "Opens food search to log a meal"

    // Navigation
    static let homeTab = "Home"
    static let calendarTab = "Calendar"
    static let foodTab = "Food"
    static let activitiesTab = "Activities"
    static let profileTab = "Profile"

    // Actions
    static let addButton = "Add"
    static let saveButton = "Save"
    static let cancelButton = "Cancel"
    static let deleteButton = "Delete"
    static let editButton = "Edit"

    // Status
    static func caloriesConsumed(_ amount: Int) -> String {
        "\(amount) calories consumed"
    }

    static func caloriesBurned(_ amount: Int) -> String {
        "\(amount) calories burned"
    }

    static func macroProgress(_ name: String, current: Double, target: Double) -> String {
        "\(name): \(Int(current)) of \(Int(target)) grams"
    }
}
