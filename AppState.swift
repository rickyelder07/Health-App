//
//  AppState.swift
//  Health App
//
//  Global app state management
//

import Foundation
import Combine

/// Global application state manager
class AppState: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: User?
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        checkAuthenticationStatus()
    }
    
    /// Check if user is currently authenticated with Supabase
    func checkAuthenticationStatus() {
        // Will be implemented when Supabase session management is ready
        // For now, defaults to false
        isAuthenticated = false
    }
    
    /// Set the current authenticated user
    func setUser(_ user: User?) {
        self.currentUser = user
        self.isAuthenticated = user != nil
    }
    
    /// Sign out the current user
    func signOut() {
        self.currentUser = nil
        self.isAuthenticated = false
    }
}

