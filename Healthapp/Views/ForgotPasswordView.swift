//
//  ForgotPasswordView.swift
//  Netfuel
//
//  View for password reset functionality
//

import SwiftUI

struct ForgotPasswordView: View {
    @ObservedObject var viewModel: AuthenticationViewModel
    @Environment(\.dismiss) var dismiss
    @FocusState private var isEmailFocused: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "lock.rotation")
                            .font(.system(size: 60))
                            .foregroundStyle(.blue.gradient)
                        
                        Text("Reset Password")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Enter your email address and we'll send you a link to reset your password.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 40)
                    
                    // Email field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email Address")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        TextField("your@email.com", text: $viewModel.email)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                            .focused($isEmailFocused)
                            .disabled(viewModel.isLoading)
                            .submitLabel(.send)
                            .onSubmit {
                                Task {
                                    await viewModel.sendPasswordReset()
                                }
                            }
                    }
                    .padding(.horizontal)
                    
                    // Success message
                    if let successMessage = viewModel.successMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text(successMessage)
                                .font(.callout)
                                .foregroundColor(.green)
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    // Error message
                    if let errorMessage = viewModel.errorMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(errorMessage)
                                .font(.callout)
                                .foregroundColor(.red)
                        }
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    // Send reset link button
                    Button {
                        viewModel.dismissKeyboard()
                        Task {
                            await viewModel.sendPasswordReset()
                        }
                    } label: {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(.white)
                            } else {
                                Image(systemName: "paperplane.fill")
                                Text("Send Reset Link")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                    }
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .disabled(viewModel.isLoading || viewModel.email.isEmpty)
                    
                    // Back to sign in button
                    Button {
                        viewModel.clearForm()
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.left")
                            Text("Back to Sign In")
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.accentColor)
                    }
                    .disabled(viewModel.isLoading)
                    
                    Spacer()
                }
                .padding(.top, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        viewModel.clearForm()
                        dismiss()
                    }
                    .disabled(viewModel.isLoading)
                }
            }
        }
        .onAppear {
            isEmailFocused = true
        }
        .interactiveDismissDisabled(viewModel.isLoading)
    }
}

#Preview {
    ForgotPasswordView(viewModel: AuthenticationViewModel(appState: AppState()))
}

