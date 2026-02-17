//
//  AuthService.swift
//  Ledstjarnan
//
//  Authentication service using Supabase Auth
//

import Foundation
import Supabase

class AuthService {
    private let supabase = SupabaseClient.shared.client
    
    // MARK: - Authentication
    
    /// Sign in with email and password
    func signIn(email: String, password: String) async throws -> Session {
        let session = try await supabase.auth.signIn(
            email: email,
            password: password
        )
        return session
    }
    
    /// Sign up new user
    func signUp(email: String, password: String) async throws -> Session {
        let session = try await supabase.auth.signUp(
            email: email,
            password: password
        )
        return session
    }
    
    /// Sign out current user
    func signOut() async throws {
        try await supabase.auth.signOut()
    }
    
    /// Send password reset email
    func resetPassword(email: String) async throws {
        try await supabase.auth.resetPasswordForEmail(email)
    }
    
    /// Update password (when user has reset token)
    func updatePassword(newPassword: String) async throws -> User {
        let user = try await supabase.auth.update(user: UserAttributes(password: newPassword))
        return user
    }
    
    /// Get current session
    func getCurrentSession() async throws -> Session? {
        return try await supabase.auth.session
    }
    
    /// Get current user
    func getCurrentUser() async throws -> User? {
        guard let session = try await getCurrentSession() else {
            return nil
        }
        return session.user
    }
    
    // MARK: - Session Management
    
    /// Listen for auth state changes
    func onAuthStateChange(callback: @escaping (AuthChangeEvent, Session?) -> Void) -> AuthStateChangeListener {
        return supabase.auth.onAuthStateChange { event, session in
            callback(event, session)
        }
    }
}
