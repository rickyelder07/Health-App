//
//  AppState.swift
//  Health App
//
//  Global app state management
//

import Foundation
import Combine
import Supabase

/// Global application state manager
class AppState: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: User?
    
    private var cancellables = Set<AnyCancellable>()
    private var sessionRefreshTimer: Timer?
    private let authService = AuthenticationService()
    
    init() {
        checkAuthenticationStatus()
        setupSessionRefreshTimer()
    }
    
    deinit {
        sessionRefreshTimer?.invalidate()
    }
    
    /// Check if user is currently authenticated with Supabase
    func checkAuthenticationStatus() {
        Task { @MainActor in
            if let session = await authService.getCurrentSession() {
                // User has active session, fetch their profile
                print("✅ Active session found for user: \(session.user.id)")
                
                // Fetch user profile from database
                do {
                    let response = try await SupabaseClient.shared.client
                        .from("users")
                        .select("id, name, weight, height, age, gender, activity_level, bmr, tdee, created_at, updated_at")
                        .eq("id", value: session.user.id.uuidString)
                        .single()
                        .execute()
                    
                    let decoder = JSONDecoder()
                    // Don't use convertFromSnakeCase - User model has explicit CodingKeys
                    decoder.dateDecodingStrategy = .iso8601
                    
                    var user = try decoder.decode(User.self, from: response.data)
                    user.email = session.user.email
                    
                    self.currentUser = user
                    self.isAuthenticated = true
                    print("✅ User profile loaded: \(user.id)")
                    
                } catch {
                    print("❌ Failed to fetch user profile: \(error)")
                    // Session exists but no profile - sign out
                    await self.signOut()
                }
            } else {
                // No active session
                self.isAuthenticated = false
                self.currentUser = nil
                print("ℹ️ No active session found")
            }
        }
    }
    
    /// Set up timer to check and refresh session periodically
    private func setupSessionRefreshTimer() {
        // Check session every 5 minutes
        sessionRefreshTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            Task {
                await self.checkAndRefreshSession()
            }
        }
    }
    
    /// Check if session is expired and refresh if needed
    @MainActor
    func checkAndRefreshSession() async {
        guard isAuthenticated else { return }
        
        let isExpired = await authService.isSessionExpired()
        
        if isExpired {
            print("⏰ Session expired, attempting refresh...")
            
            do {
                let newSession = try await authService.refreshSession()
                print("✅ Session refreshed successfully")
                
                // Session is refreshed, auth state observer will handle the update
                
            } catch {
                print("❌ Failed to refresh session: \(error)")
                // Session refresh failed, sign out user
                await signOut()
            }
        }
    }
    
    /// Set the current authenticated user
    @MainActor
    func setUser(_ user: User?) {
        self.currentUser = user
        self.isAuthenticated = user != nil
    }
    
    /// Sign out the current user
    @MainActor
    func signOut() async {
        do {
            try await authService.signOut()
            self.currentUser = nil
            self.isAuthenticated = false
            print("👋 User signed out successfully")
        } catch {
            print("❌ Sign out error: \(error)")
            // Even if API call fails, clear local state
            self.currentUser = nil
            self.isAuthenticated = false
        }
    }
}

