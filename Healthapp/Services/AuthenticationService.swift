//
//  AuthenticationService.swift
//  Netfuel
//
//  Service for handling user authentication with Supabase
//

import Foundation
import Supabase
import Combine

/// Service for managing user authentication
class AuthenticationService {
    
    private let supabase = SupabaseClient.shared
    private var sessionCancellable: AnyCancellable?
    
    /// Sign up a new user with email and password
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's password
    /// - Returns: Authenticated session (may be nil if email confirmation is required)
    func signUp(email: String, password: String) async throws -> Session? {
        do {
            let response = try await supabase.auth.signUp(
                email: email,
                password: password
            )
            
            print("✅ Signup successful - User ID: \(response.user.id)")
            print("✅ Session exists: \(response.session != nil)")
            
            // Session may be nil if email confirmation is enabled in Supabase
            return response.session
        } catch {
            print("❌ Signup error: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Sign in an existing user with email and password
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's password
    /// - Returns: Authenticated session
    func signIn(email: String, password: String) async throws -> Session {
        let session = try await supabase.auth.signIn(
            email: email,
            password: password
        )
        
        return session
    }
    
    /// Sign in with Google OAuth
    /// - Returns: Authenticated session
    /// - Throws: Error if OAuth flow fails
    /// - Note: Requires Google OAuth to be configured in Supabase dashboard
    func signInWithGoogle() async throws -> Session {
        do {
            // Start OAuth flow with Google
            // The URL scheme must match what's configured in Info.plist
            let session = try await supabase.auth.signInWithOAuth(
                provider: .google,
                redirectTo: URL(string: "netfuel://oauth-callback")
            )
            
            print("✅ Google sign in successful - User ID: \(session.user.id)")
            return session
        } catch {
            print("❌ Google sign in error: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Sign out the current user
    func signOut() async throws {
        try await supabase.auth.signOut()
    }
    
    /// Get the current authenticated session
    /// - Returns: Current session if authenticated, nil otherwise
    func getCurrentSession() async -> Session? {
        return try? await supabase.auth.session
    }
    
    /// Get the user ID from the current authenticated session
    /// - Returns: User ID string if authenticated, nil otherwise
    /// - Note: To get the full user profile with stats, query the users table in the database using this ID.
    func getCurrentUserId() async -> UUID? {
        guard let session = await getCurrentSession() else {
            return nil
        }
        return session.user.id
    }
    
    /// Send a password reset email to the user
    /// - Parameter email: User's email address
    /// - Throws: Error if reset email cannot be sent
    func resetPassword(email: String) async throws {
        do {
            try await supabase.auth.resetPasswordForEmail(email)
            print("✅ Password reset email sent to: \(email)")
        } catch {
            print("❌ Password reset error: \(error)")
            throw error
        }
    }
    
    /// Update the user's password
    /// - Parameter newPassword: New password to set
    /// - Throws: Error if password cannot be updated
    func updatePassword(newPassword: String) async throws {
        do {
            let user = try await supabase.auth.update(user: UserAttributes(password: newPassword))
            print("✅ Password updated for user: \(user.id)")
        } catch {
            print("❌ Password update error: \(error)")
            throw error
        }
    }
    
    /// Monitor auth state changes and handle token refresh automatically
    /// - Parameter onStateChange: Callback when auth state changes
    /// - Returns: Cancellable for cleanup
    func observeAuthState(onStateChange: @escaping (Session?) -> Void) async -> AnyCancellable {
        let listener = await supabase.auth.onAuthStateChange { event, session in
            print("🔄 Auth state changed: \(event)")
            
            switch event {
            case .signedIn:
                print("✅ User signed in")
                onStateChange(session)
                
            case .signedOut:
                print("👋 User signed out")
                onStateChange(nil)
                
            case .tokenRefreshed:
                print("🔄 Token refreshed")
                onStateChange(session)
                
            case .userUpdated:
                print("👤 User updated")
                onStateChange(session)
                
            default:
                break
            }
        }
        
        // Wrap the listener in an AnyCancellable
        return AnyCancellable {
            Task {
                await listener.remove()
            }
        }
    }
    
    /// Manually refresh the current session's access token
    /// - Returns: New session with refreshed token
    /// - Throws: Error if token cannot be refreshed
    func refreshSession() async throws -> Session {
        do {
            let session = try await supabase.auth.refreshSession()
            print("✅ Session refreshed successfully")
            return session
        } catch {
            print("❌ Session refresh error: \(error)")
            throw error
        }
    }
    
    /// Check if the current session is expired
    /// - Returns: true if session is expired or doesn't exist
    func isSessionExpired() async -> Bool {
        guard let session = await getCurrentSession() else {
            return true
        }
        
        // Check if token is expired (with 5 minute buffer)
        let expiresAt = Date(timeIntervalSince1970: TimeInterval(session.expiresAt ?? 0))
        let bufferTime: TimeInterval = 300 // 5 minutes
        
        return Date().addingTimeInterval(bufferTime) > expiresAt
    }
}

/// Authentication related errors
enum AuthError: LocalizedError {
    case emailConfirmationRequired
    case invalidCredentials
    case userNotFound
    case weakPassword
    case emailAlreadyInUse
    case passwordResetFailed
    case sessionExpired
    case noSession
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .emailConfirmationRequired:
            return "Please check your email to confirm your account before signing in."
        case .invalidCredentials:
            return "Invalid email or password."
        case .userNotFound:
            return "User not found."
        case .weakPassword:
            return "Password must be at least 6 characters long."
        case .emailAlreadyInUse:
            return "This email is already registered."
        case .passwordResetFailed:
            return "Failed to send password reset email. Please try again."
        case .sessionExpired:
            return "Your session has expired. Please sign in again."
        case .noSession:
            return "No session found. Please sign in again."
        case .networkError:
            return "Network error. Please check your connection and try again."
        }
    }
}

