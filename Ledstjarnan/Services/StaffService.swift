//
//  StaffService.swift
//  Ledstjarnan
//

import Foundation
import Supabase

class StaffService {
    private let supabase = SupabaseManager.shared.client
    
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

    /// Look up a unit by its join code (for onboarding / change unit). Only returns active units.
    func getUnitByJoinCode(_ code: String) async throws -> Unit {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw StaffServiceError.invalidJoinCode
        }
        let response: Unit = try await supabase.database
            .from("units")
            .select()
            .eq("join_code", value: trimmed)
            .eq("is_active", value: true)
            .single()
            .execute()
            .value
        return response
    }

    /// Update staff profile (full name, role). RLS: update own profile.
    func updateStaffProfile(staffId: String, fullName: String, role: String) async throws {
        struct UpdatePayload: Encodable {
            let full_name: String
            let role: String
        }
        try await supabase.database
            .from("staff_profiles")
            .update(UpdatePayload(full_name: fullName, role: role))
            .eq("id", value: staffId)
            .execute()
    }

    /// Update notification preferences (JSONB).
    func updateNotificationPreferences(staffId: String, prefs: NotificationPreferences) async throws {
        struct PrefsPayload: Encodable {
            let notification_prefs: NotificationPreferences
        }
        try await supabase.database
            .from("staff_profiles")
            .update(PrefsPayload(notification_prefs: prefs))
            .eq("id", value: staffId)
            .execute()
    }

    /// Update staff's unit and set onboarding_completed_at. Caller must be the staff member (RLS: update own profile).
    func updateStaffUnit(staffId: String, unitId: String) async throws {
        struct UpdatePayload: Encodable {
            let unit_id: String
            let unit_joined_at: String
            let onboarding_completed_at: String
        }
        let now = ISO8601DateFormatter().string(from: Date())
        let payload = UpdatePayload(unit_id: unitId, unit_joined_at: now, onboarding_completed_at: now)
        try await supabase.database
            .from("staff_profiles")
            .update(payload)
            .eq("id", value: staffId)
            .execute()
    }

    /// Mark onboarding + privacy acknowledgement complete without changing unit.
    func completeOnboarding(staffId: String) async throws {
        struct UpdatePayload: Encodable {
            let onboarding_completed_at: String
            let privacy_ack_at: String
        }
        let now = ISO8601DateFormatter().string(from: Date())
        let payload = UpdatePayload(onboarding_completed_at: now, privacy_ack_at: now)
        try await supabase.database
            .from("staff_profiles")
            .update(payload)
            .eq("id", value: staffId)
            .execute()
    }
}

enum StaffServiceError: LocalizedError {
    case invalidJoinCode
    case unitNotFound

    var errorDescription: String? {
        switch self {
        case .invalidJoinCode: return "Please enter a unit code."
        case .unitNotFound: return "No active unit found for this code."
        }
    }
}
