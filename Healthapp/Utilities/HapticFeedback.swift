//
//  HapticFeedback.swift
//  Health App
//
//  Utility for providing haptic feedback
//

import UIKit
import SwiftUI

/// Haptic feedback manager
enum HapticFeedback {

    // MARK: - Impact Feedback

    /// Light impact (button taps, switches)
    static func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    /// Medium impact (standard actions)
    static func medium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    /// Heavy impact (important actions)
    static func heavy() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }

    /// Soft impact (subtle feedback)
    @available(iOS 13.0, *)
    static func soft() {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.impactOccurred()
    }

    /// Rigid impact (firm feedback)
    @available(iOS 13.0, *)
    static func rigid() {
        let generator = UIImpactFeedbackGenerator(style: .rigid)
        generator.impactOccurred()
    }

    // MARK: - Notification Feedback

    /// Success feedback (completed actions)
    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    /// Warning feedback (caution needed)
    static func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }

    /// Error feedback (failed actions)
    static func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }

    // MARK: - Selection Feedback

    /// Selection changed feedback (picker, segmented control)
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}

// MARK: - View Extension for Haptic Feedback

extension View {
    /// Add haptic feedback to a button tap
    func hapticFeedback(_ style: HapticStyle = .light) -> some View {
        self.simultaneousGesture(
            TapGesture()
                .onEnded { _ in
                    style.trigger()
                }
        )
    }
}

/// Haptic style enumeration for convenience
enum HapticStyle {
    case light
    case medium
    case heavy
    case soft
    case rigid
    case success
    case warning
    case error
    case selection

    func trigger() {
        switch self {
        case .light:
            HapticFeedback.light()
        case .medium:
            HapticFeedback.medium()
        case .heavy:
            HapticFeedback.heavy()
        case .soft:
            if #available(iOS 13.0, *) {
                HapticFeedback.soft()
            } else {
                HapticFeedback.light()
            }
        case .rigid:
            if #available(iOS 13.0, *) {
                HapticFeedback.rigid()
            } else {
                HapticFeedback.medium()
            }
        case .success:
            HapticFeedback.success()
        case .warning:
            HapticFeedback.warning()
        case .error:
            HapticFeedback.error()
        case .selection:
            HapticFeedback.selection()
        }
    }
}
