//
//  AuthenticationViewModel.swift
//  Netfuel
//
//  ViewModel for handling authentication logic
//

import Foundation
import Combine
import Supabase
import UIKit

/// ViewModel for authentication flow
@MainActor
class AuthenticationViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var isSignUpMode: Bool = false
    @Published var showForgotPassword: Bool = false
    
    private let authService = AuthenticationService()
    internal let appState: AppState
    private var authStateObserver: AnyCancellable?
    
    init(appState: AppState) {
        self.appState = appState
        setupAuthStateObserver()
    }
    
    deinit {
        authStateObserver?.cancel()
    }
    
    /// Set up observer for auth state changes
    private func setupAuthStateObserver() {
        Task {
            authStateObserver = await authService.observeAuthState { [weak self] session in
                guard let self = self else { return }
                
                Task { @MainActor in
                    if let session = session {
                        // User is signed in, fetch profile
                        await self.fetchUserProfile(userId: session.user.id)
                    } else {
                        // User is signed out
                        await self.appState.setUser(nil)
                    }
                }
            }
        }
    }
    
    /// Sign in with email and password
    func signIn() async {
        guard validateSignIn() else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let session = try await authService.signIn(email: email, password: password)
            
            // Fetch user profile from database
            await fetchUserProfile(userId: session.user.id)
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    /// Sign up with email and password
    func signUp() async {
        guard validateSignUp() else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            print("📧 Attempting signup with email: \(email)")
            let session = try await authService.signUp(email: email, password: password)
            
            // Check if session exists (email confirmation may be required)
            if let session = session {
                print("✅ Session received, fetching user profile")
                
                // Fetch user profile from database (created by trigger)
                await fetchUserProfile(userId: session.user.id)
            } else {
                // Email confirmation required
                print("📬 Email confirmation required")
                errorMessage = "Success! Please check your email to confirm your account."
            }
            
        } catch {
            print("❌ Signup failed in ViewModel")
            print("❌ Error: \(error)")
            print("❌ Error description: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    /// Fetch user profile from database
    private func fetchUserProfile(userId: UUID) async {
        do {
            print("📥 Fetching user profile for ID: \(userId)")
            
            // Explicitly select all columns from users table
            let response = try await SupabaseClient.shared.client
                .from("users")
                .select("id, weight, height, age, gender, activity_level, bmr, tdee, created_at, updated_at")
                .eq("id", value: userId.uuidString)
                .single()
                .execute()
            
            // Debug: Print raw response data
            if let jsonString = String(data: response.data, encoding: .utf8) {
                print("📋 Raw JSON response: \(jsonString)")
            }
            
            // Use custom decoder that handles Supabase date formats
            // Don't override keyDecodingStrategy - User model has explicit CodingKeys
            let decoder = DateFormatters.supabaseDecoder
            
            let user = try decoder.decode(User.self, from: response.data)
            
            // Set email from auth if not in profile
            var updatedUser = user
            if updatedUser.email == nil {
                updatedUser.email = email
            }
            
            await appState.setUser(updatedUser)
            print("✅ User profile loaded: \(user.id)")
            
        } catch {
            print("❌ Failed to fetch user profile: \(error)")
            if let decodingError = error as? DecodingError {
                print("❌ Decoding error details: \(decodingError)")
            }
            errorMessage = "Failed to load user profile. Please try signing in again."
        }
    }
    
    /// Sign in with Google OAuth
    func signInWithGoogle() async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        do {
            print("🔵 Starting Google sign in...")
            let session = try await authService.signInWithGoogle()
            
            print("✅ Google session received, fetching user profile")
            
            // Fetch user profile (same as regular sign in)
            await fetchUserProfile(userId: session.user.id)
            
            print("✅ Google sign in complete")
            
        } catch {
            errorMessage = "Failed to sign in with Google. Please try again."
            print("❌ Google sign in failed: \(error)")
        }
        
        isLoading = false
    }
    
    /// Send password reset email
    func sendPasswordReset() async {
        guard !email.isEmpty else {
            errorMessage = "Please enter your email address"
            return
        }
        
        guard isValidEmail(email) else {
            errorMessage = "Please enter a valid email address"
            return
        }
        
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        do {
            try await authService.resetPassword(email: email)
            successMessage = "Password reset email sent! Please check your inbox."
            print("✅ Password reset email sent")
            
            // Clear form and close forgot password view after short delay
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            showForgotPassword = false
            clearForm()
        } catch {
            errorMessage = "Failed to send reset email. Please try again."
            print("❌ Password reset failed: \(error)")
        }
        
        isLoading = false
    }
    
    /// Toggle between sign in and sign up modes
    func toggleMode() {
        isSignUpMode.toggle()
        errorMessage = nil
        successMessage = nil
        clearForm()
    }
    
    /// Clear form fields
    func clearForm() {
        email = ""
        password = ""
        confirmPassword = ""
        errorMessage = nil
        successMessage = nil
    }
    
    /// Dismiss keyboard
    func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    // MARK: - Validation
    
    private func validateSignIn() -> Bool {
        guard !email.isEmpty else {
            errorMessage = "Please enter your email"
            return false
        }
        
        guard isValidEmail(email) else {
            errorMessage = "Please enter a valid email"
            return false
        }
        
        guard !password.isEmpty else {
            errorMessage = "Please enter your password"
            return false
        }
        
        return true
    }
    
    private func validateSignUp() -> Bool {
        guard validateSignIn() else { return false }
        
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            return false
        }
        
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match"
            return false
        }
        
        return true
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}

