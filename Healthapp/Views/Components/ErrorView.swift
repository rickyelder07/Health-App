//
//  ErrorView.swift
//  Netfuel
//
//  Reusable error state components
//

import SwiftUI

// MARK: - Generic Error View

struct ErrorView: View {
    let error: Error
    var onRetry: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Error Icon
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.red.gradient)
                .accessibilityHidden(true)

            // Error Message
            VStack(spacing: 8) {
                Text("Something Went Wrong")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text(error.localizedDescription)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            // Retry Button
            if let onRetry = onRetry {
                Button(action: {
                    HapticFeedback.light()
                    onRetry()
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Try Again")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: 300)
                    .frame(height: 50)
                    .background(Color.red)
                    .cornerRadius(12)
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Error: \(error.localizedDescription)")
    }
}

// MARK: - Inline Error Banner

struct ErrorBanner: View {
    let message: String
    var onDismiss: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.title3)
                .foregroundColor(.white)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)

            Spacer()

            if let onDismiss = onDismiss {
                Button(action: {
                    HapticFeedback.soft()
                    onDismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Circle())
                }
            }
        }
        .padding()
        .background(Color.red)
        .cornerRadius(12)
        .shadow(color: .red.opacity(0.3), radius: 8, y: 4)
        .transition(.move(edge: .top).combined(with: .opacity))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Error: \(message)")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Success Banner

struct SuccessBanner: View {
    let message: String
    var onDismiss: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundColor(.white)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)

            Spacer()

            if let onDismiss = onDismiss {
                Button(action: {
                    HapticFeedback.soft()
                    onDismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Circle())
                }
            }
        }
        .padding()
        .background(Color.green)
        .cornerRadius(12)
        .shadow(color: .green.opacity(0.3), radius: 8, y: 4)
        .transition(.move(edge: .top).combined(with: .opacity))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Success: \(message)")
    }
}

// MARK: - Warning Banner

struct WarningBanner: View {
    let message: String
    var onDismiss: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title3)
                .foregroundColor(.black)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.black)
                .multilineTextAlignment(.leading)

            Spacer()

            if let onDismiss = onDismiss {
                Button(action: {
                    HapticFeedback.soft()
                    onDismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .foregroundColor(.black)
                        .padding(8)
                        .background(Color.black.opacity(0.1))
                        .clipShape(Circle())
                }
            }
        }
        .padding()
        .background(Color.yellow)
        .cornerRadius(12)
        .shadow(color: .yellow.opacity(0.3), radius: 8, y: 4)
        .transition(.move(edge: .top).combined(with: .opacity))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Warning: \(message)")
    }
}

// MARK: - Network Error View

struct NetworkErrorView: View {
    var onRetry: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 60))
                .foregroundStyle(.orange.gradient)

            VStack(spacing: 8) {
                Text("Network Error")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Unable to connect to the server. Please check your internet connection.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Button(action: {
                HapticFeedback.light()
                onRetry()
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Retry")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: 300)
                .frame(height: 50)
                .background(Color.orange)
                .cornerRadius(12)
            }
        }
        .padding()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Network error. Retry button available.")
    }
}

// MARK: - View Extension for Toasts

extension View {
    /// Show a toast message
    func toast(message: String, isShowing: Binding<Bool>, type: ToastType = .success) -> some View {
        ZStack {
            self

            if isShowing.wrappedValue {
                VStack {
                    toastView(message: message, type: type, isShowing: isShowing)
                        .padding(.horizontal)
                        .padding(.top, 50)

                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(), value: isShowing.wrappedValue)
                .onAppear {
                    HapticFeedback.success()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation {
                            isShowing.wrappedValue = false
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func toastView(message: String, type: ToastType, isShowing: Binding<Bool>) -> some View {
        switch type {
        case .success:
            SuccessBanner(message: message) {
                withAnimation {
                    isShowing.wrappedValue = false
                }
            }
        case .error:
            ErrorBanner(message: message) {
                withAnimation {
                    isShowing.wrappedValue = false
                }
            }
        case .warning:
            WarningBanner(message: message) {
                withAnimation {
                    isShowing.wrappedValue = false
                }
            }
        }
    }
}

enum ToastType {
    case success
    case error
    case warning
}

#Preview("Error View") {
    ErrorView(error: NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to load data from server"])) {
        print("Retry tapped")
    }
}

#Preview("Error Banner") {
    VStack {
        ErrorBanner(message: "Failed to save food log") {}
        Spacer()
    }
    .padding()
}

#Preview("Success Banner") {
    VStack {
        SuccessBanner(message: "Food logged successfully!") {}
        Spacer()
    }
    .padding()
}

#Preview("Network Error") {
    NetworkErrorView(onRetry: {})
}
