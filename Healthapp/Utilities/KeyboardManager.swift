//
//  KeyboardManager.swift
//  Health App
//
//  Keyboard handling utilities
//

import SwiftUI
import Combine

/// View extension for keyboard handling
extension View {
    /// Dismiss keyboard when tapping outside
    func dismissKeyboardOnTap() -> some View {
        self.onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }

    /// Add a toolbar with Done button for number pads
    func numberPadToolbar() -> some View {
        self.toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            }
        }
    }

    /// Dismiss keyboard on scroll (for ScrollView)
    func dismissKeyboardOnScroll() -> some View {
        self.simultaneousGesture(
            DragGesture().onChanged { _ in
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        )
    }

    /// Adjust view when keyboard appears/disappears
    @ViewBuilder
    func adaptiveKeyboard() -> some View {
        if #available(iOS 14.0, *) {
            self.ignoresSafeArea(.keyboard, edges: .bottom)
        } else {
            self
        }
    }
}

/// Observable keyboard state manager
class KeyboardManager: ObservableObject {
    @Published var keyboardHeight: CGFloat = 0
    @Published var isKeyboardVisible: Bool = false

    private var cancellables = Set<AnyCancellable>()

    init() {
        setupKeyboardNotifications()
    }

    private func setupKeyboardNotifications() {
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .compactMap { notification in
                notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
            }
            .map { $0.height }
            .sink { [weak self] height in
                self?.keyboardHeight = height
                self?.isKeyboardVisible = true
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .sink { [weak self] _ in
                self?.keyboardHeight = 0
                self?.isKeyboardVisible = false
            }
            .store(in: &cancellables)
    }
}

/// Custom text field with improved keyboard handling
struct AdaptiveTextField: View {
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var onCommit: (() -> Void)?

    @FocusState private var isFocused: Bool

    var body: some View {
        TextField(placeholder, text: $text)
            .keyboardType(keyboardType)
            .focused($isFocused)
            .onSubmit {
                onCommit?()
            }
            .toolbar {
                if keyboardType == .numberPad || keyboardType == .decimalPad {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") {
                            isFocused = false
                        }
                    }
                }
            }
    }
}
