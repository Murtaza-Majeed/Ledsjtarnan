//
//  AuthService.swift
//  Ledstjarnan
//

import Foundation
import Supabase

class AuthService {
    private let supabase = SupabaseManager.shared.client
    
    func signIn(email: String, password: String) async throws -> Session {
        try await supabase.auth.signIn(
            email: email,
            password: password
        )
    }
    
    func signUp(email: String, password: String) async throws -> Session {
        let response = try await supabase.auth.signUp(
            email: email,
            password: password
        )
        guard let session = response.session else {
            throw NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Sign up did not return a session"])
        }
        return session
    }
    
    func signOut() async throws {
        try await supabase.auth.signOut()
    }
    
    func resetPassword(email: String) async throws {
        try await supabase.auth.resetPasswordForEmail(email)
    }
    
    func updatePassword(newPassword: String) async throws -> User {
        let user = try await supabase.auth.update(user: UserAttributes(password: newPassword))
        return user
    }
    
    func getCurrentSession() async throws -> Session? {
        return try await supabase.auth.session
    }
    
    func getCurrentUser() async throws -> User? {
        guard let session = try await getCurrentSession() else {
            return nil
        }
        return session.user
    }
    
    /// Registers a listener for auth state changes. Returns an opaque registration (e.g. for removal).
    func onAuthStateChange(callback: @escaping (AuthChangeEvent, Session?) -> Void) async -> Any {
        await supabase.auth.onAuthStateChange { event, session in
            callback(event, session)
        }
    }
}
