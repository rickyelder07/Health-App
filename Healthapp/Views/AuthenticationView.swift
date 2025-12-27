//
//  AuthenticationView.swift
//  Health App
//
//  View for user authentication (sign in / sign up)
//

import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        AuthenticationViewContent(appState: appState)
    }
}

struct AuthenticationViewContent: View {
    @StateObject private var viewModel: AuthenticationViewModel
    @FocusState private var focusedField: Field?
    
    enum Field {
        case email
        case password
        case confirmPassword
    }
    
    init(appState: AppState) {
        _viewModel = StateObject(wrappedValue: AuthenticationViewModel(appState: appState))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Logo/Header
                    VStack(spacing: 8) {
                        Image(systemName: "heart.circle.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(.red.gradient)
                        
                        Text("Health Tracker")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text(viewModel.isSignUpMode ? "Create your account" : "Welcome back")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)
                    .padding(.bottom, 20)
                    
                    // Form fields
                    VStack(spacing: 16) {
                        // Email field
                        TextField("Email", text: $viewModel.email)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                            .focused($focusedField, equals: .email)
                            .submitLabel(.next)
                            .disabled(viewModel.isLoading)
                            .onSubmit {
                                focusedField = .password
                            }
                        
                        // Password field
                        SecureField("Password", text: $viewModel.password)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(viewModel.isSignUpMode ? .newPassword : .password)
                            .focused($focusedField, equals: .password)
                            .submitLabel(viewModel.isSignUpMode ? .next : .go)
                            .disabled(viewModel.isLoading)
                            .onSubmit {
                                if viewModel.isSignUpMode {
                                    focusedField = .confirmPassword
                                } else {
                                    Task {
                                        await viewModel.signIn()
                                    }
                                }
                            }
                        
                        // Confirm password (sign up only)
                        if viewModel.isSignUpMode {
                            SecureField("Confirm Password", text: $viewModel.confirmPassword)
                                .textFieldStyle(.roundedBorder)
                                .textContentType(.newPassword)
                                .focused($focusedField, equals: .confirmPassword)
                                .submitLabel(.go)
                                .disabled(viewModel.isLoading)
                                .onSubmit {
                                    Task {
                                        await viewModel.signUp()
                                    }
                                }
                        }
                        
                        // Forgot password link (sign in only)
                        if !viewModel.isSignUpMode {
                            HStack {
                                Spacer()
                                Button {
                                    viewModel.showForgotPassword = true
                                } label: {
                                    Text("Forgot Password?")
                                        .font(.caption)
                                        .foregroundColor(.accentColor)
                                }
                                .disabled(viewModel.isLoading)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Success message
                    if let successMessage = viewModel.successMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                            Text(successMessage)
                                .font(.callout)
                        }
                        .foregroundColor(.green)
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    // Error message
                    if let errorMessage = viewModel.errorMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text(errorMessage)
                                .font(.callout)
                        }
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    // Action button
                    Button {
                        viewModel.dismissKeyboard()
                        Task {
                            if viewModel.isSignUpMode {
                                await viewModel.signUp()
                            } else {
                                await viewModel.signIn()
                            }
                        }
                    } label: {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(.white)
                            } else {
                                Image(systemName: viewModel.isSignUpMode ? "person.badge.plus" : "arrow.right.circle.fill")
                                Text(viewModel.isSignUpMode ? "Sign Up" : "Sign In")
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
                    .disabled(viewModel.isLoading || viewModel.email.isEmpty || viewModel.password.isEmpty)
                    
                    // Divider for social sign in
                    HStack(spacing: 16) {
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(.gray.opacity(0.3))
                        
                        Text("OR")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(.gray.opacity(0.3))
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    
                    // Google Sign In button
                    Button {
                        viewModel.dismissKeyboard()
                        Task {
                            await viewModel.signInWithGoogle()
                        }
                    } label: {
                        HStack(spacing: 12) {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(.circular)
                            } else {
                                Image(systemName: "g.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(
                                        .linearGradient(
                                            colors: [.red, .yellow, .green, .blue],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                
                                Text("Continue with Google")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                    }
                    .background(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .disabled(viewModel.isLoading)
                    
                    // Toggle mode button
                    Button {
                        viewModel.toggleMode()
                    } label: {
                        HStack(spacing: 4) {
                            Text(viewModel.isSignUpMode ? "Already have an account?" : "Don't have an account?")
                                .foregroundColor(.secondary)
                            Text(viewModel.isSignUpMode ? "Sign In" : "Sign Up")
                                .fontWeight(.semibold)
                                .foregroundColor(.accentColor)
                        }
                        .font(.subheadline)
                    }
                    .disabled(viewModel.isLoading)
                    
                    Spacer()
                }
            }
            .navigationBarHidden(true)
            .onTapGesture {
                viewModel.dismissKeyboard()
            }
            .sheet(isPresented: $viewModel.showForgotPassword) {
                ForgotPasswordView(viewModel: viewModel)
            }
        }
        .onAppear {
            focusedField = .email
        }
    }
}

#Preview {
    AuthenticationView()
        .environmentObject(AppState())
}

