//
//  AppState.swift
//  Ledstjarnan
//
//  Created by Murtaza Majeed on 2026-01-29.
//

import SwiftUI
import Combine
import Supabase
import Auth

@MainActor
class AppState: ObservableObject {
    @Published var hasSeenOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasSeenOnboarding, forKey: "has_seen_onboarding")
        }
    }
    
    @Published var isAuthenticated: Bool = false
    @Published var currentStaffProfile: StaffProfile? = nil
    @Published var currentUnit: Unit? = nil
    @Published var isLoading: Bool = false
    
    private let authService = AuthService()
    private let staffService = StaffService()
    private var authStateListener: Any?
    
    init() {
        self.hasSeenOnboarding = UserDefaults.standard.bool(forKey: "has_seen_onboarding")
        
        // Listen for auth state changes
        Task {
            await setupAuthListener()
            await checkAuthStatus()
        }
    }
    
    private func setupAuthListener() async {
        authStateListener = await authService.onAuthStateChange { [weak self] (_ event: AuthChangeEvent, _ session: Session?) in
            Task { @MainActor in
                if let session = session, !session.isExpired {
                    await self?.loadStaffProfile()
                } else {
                    self?.isAuthenticated = false
                    self?.currentStaffProfile = nil
                    self?.currentUnit = nil
                }
            }
        }
    }
    
    func checkAuthStatus() async {
        do {
            if let session = try await authService.getCurrentSession(), !session.isExpired {
                isAuthenticated = true
                await loadStaffProfile()
            }
        } catch {
            print("Error checking auth status: \(error)")
        }
    }
    
    func loadStaffProfile() async {
        guard let user = try? await authService.getCurrentUser() else { return }
        
        do {
            let profile = try await staffService.getStaffProfile(userId: user.id.uuidString)
            currentStaffProfile = profile
            
            if let unitId = profile.unitId {
                let unit = try await staffService.getUnit(unitId: unitId)
                currentUnit = unit
            }
            
            isAuthenticated = true
        } catch {
            print("Error loading staff profile: \(error)")
        }
    }

    func markOnboardingComplete() async {
        var staffId = currentStaffProfile?.id
        if staffId == nil, let user = try? await authService.getCurrentUser() {
            staffId = user.id.uuidString
        }
        guard let id = staffId else {
            hasSeenOnboarding = true
            return
        }

        do {
            try await staffService.completeOnboarding(staffId: id)
            await loadStaffProfile()
        } catch {
            print("Error completing onboarding: \(error)")
        }

        hasSeenOnboarding = true
    }
    
    func signOut() async {
        do {
            try await authService.signOut()
            isAuthenticated = false
            currentStaffProfile = nil
            currentUnit = nil
        } catch {
            print("Error signing out: \(error)")
        }
    }
}
