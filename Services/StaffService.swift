//
//  StaffService.swift
//  Ledstjarnan
//
//  Service for staff profile and unit operations
//

import Foundation
import Supabase

class StaffService {
    private let supabase = SupabaseClient.shared.client
    
    // MARK: - Staff Profile
    
    /// Get staff profile for current user
    func getStaffProfile(userId: String) async throws -> StaffProfile {
        let response: StaffProfile = try await supabase.database
            .from("staff_profiles")
            .select()
            .eq("id", value: userId)
            .single()
            .execute()
            .value
        return response
    }
    
    /// Create staff profile
    func createStaffProfile(
        userId: String,
        email: String,
        fullName: String,
        role: String = "Behandlingsassistent",
        unitId: String
    ) async throws -> StaffProfile {
        let profile = [
            "id": userId,
            "email": email,
            "full_name": fullName,
            "role": role,
            "unit_id": unitId,
            "unit_joined_at": ISO8601DateFormatter().string(from: Date())
        ]
        
        let response: StaffProfile = try await supabase.database
            .from("staff_profiles")
            .insert(profile)
            .select()
            .single()
            .execute()
            .value
        return response
    }
    
    /// Update staff profile
    func updateStaffProfile(
        userId: String,
        fullName: String? = nil,
        notificationsEnabled: Bool? = nil,
        notificationPrefs: NotificationPreferences? = nil
    ) async throws -> StaffProfile {
        var updates: [String: Any] = [:]
        
        if let fullName = fullName {
            updates["full_name"] = fullName
        }
        if let notificationsEnabled = notificationsEnabled {
            updates["notifications_enabled"] = notificationsEnabled
        }
        if let prefs = notificationPrefs {
            updates["notification_prefs"] = try JSONEncoder().encode(prefs)
        }
        
        let response: StaffProfile = try await supabase.database
            .from("staff_profiles")
            .update(updates)
            .eq("id", value: userId)
            .select()
            .single()
            .execute()
            .value
        return response
    }
    
    /// Complete onboarding
    func completeOnboarding(userId: String) async throws {
        let updates = ["onboarding_completed_at": ISO8601DateFormatter().string(from: Date())]
        
        try await supabase.database
            .from("staff_profiles")
            .update(updates)
            .eq("id", value: userId)
            .execute()
    }
    
    // MARK: - Unit Operations
    
    /// Get unit by ID
    func getUnit(unitId: String) async throws -> Unit {
        let response: Unit = try await supabase.database
            .from("units")
            .select()
            .eq("id", value: unitId)
            .single()
            .execute()
            .value
        return response
    }
    
    /// Verify unit join code
    func verifyUnitCode(_ code: String) async throws -> Unit? {
        do {
            let response: Unit = try await supabase.database
                .from("units")
                .select()
                .eq("join_code", value: code)
                .eq("is_active", value: true)
                .single()
                .execute()
                .value
            return response
        } catch {
            return nil
        }
    }
    
    /// Join unit with code
    func joinUnit(userId: String, unitId: String) async throws -> StaffProfile {
        let updates = [
            "unit_id": unitId,
            "unit_joined_at": ISO8601DateFormatter().string(from: Date())
        ]
        
        let response: StaffProfile = try await supabase.database
            .from("staff_profiles")
            .update(updates)
            .eq("id", value: userId)
            .select()
            .single()
            .execute()
            .value
        return response
    }
    
    /// Change unit (requires new code)
    func changeUnit(userId: String, newUnitId: String) async throws -> StaffProfile {
        let updates = [
            "unit_id": newUnitId,
            "unit_changed_at": ISO8601DateFormatter().string(from: Date())
        ]
        
        let response: StaffProfile = try await supabase.database
            .from("staff_profiles")
            .update(updates)
            .eq("id", value: userId)
            .select()
            .single()
            .execute()
            .value
        return response
    }
}
