//
//  StaffProfile.swift
//  Ledstjarnan
//
//  Staff profile and unit models (for app target)
//

import Foundation

struct StaffProfile: Identifiable, Codable {
    let id: String
    let email: String
    var fullName: String
    var role: String
    var unitId: String?
    var unitJoinedAt: Date?
    var notificationsEnabled: Bool
    var notificationPrefs: NotificationPreferences?
    var privacyAckAt: Date?
    var onboardingCompletedAt: Date?
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case fullName = "full_name"
        case role
        case unitId = "unit_id"
        case unitJoinedAt = "unit_joined_at"
        case notificationsEnabled = "notifications_enabled"
        case notificationPrefs = "notification_prefs"
        case privacyAckAt = "privacy_ack_at"
        case onboardingCompletedAt = "onboarding_completed_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct NotificationPreferences: Codable {
    var followupsDue: Bool
    var sessions: Bool
    var scheduleChanges: Bool
    var quietStart: String
    var quietEnd: String
    
    enum CodingKeys: String, CodingKey {
        case followupsDue = "followups_due"
        case sessions
        case scheduleChanges = "schedule_changes"
        case quietStart = "quiet_start"
        case quietEnd = "quiet_end"
    }
    
    static var `default`: NotificationPreferences {
        NotificationPreferences(
            followupsDue: true,
            sessions: true,
            scheduleChanges: true,
            quietStart: "22:00",
            quietEnd: "07:00"
        )
    }
}

struct Unit: Identifiable, Codable {
    let id: String
    var name: String
    var code: String
    var city: String?
    var joinCode: String
    var joinCodeExpiresAt: Date?
    var isActive: Bool
    let createdAt: Date
    let updatedAt: Date
    
    var displayName: String {
        if let city = city {
            return "\(name) • \(city)"
        }
        return name
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case code
        case city
        case joinCode = "join_code"
        case joinCodeExpiresAt = "join_code_expires_at"
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
