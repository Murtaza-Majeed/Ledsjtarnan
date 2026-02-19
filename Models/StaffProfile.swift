//
//  StaffProfile.swift
//  Ledstjarnan
//
//  Staff profile and unit models
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
    var quietStart: String // "22:00"
    var quietEnd: String // "07:00"
    
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

struct ClientLink: Identifiable, Codable {
    let id: String
    let clientId: String
    let unitId: String
    var code: String
    let createdByStaffId: String?
    var expiresAt: Date
    var isUsed: Bool
    var usedAt: Date?
    var linkedUserId: String?
    var status: LinkStatus
    var unlinkedAt: Date?
    var unlinkedByStaffId: String?
    let createdAt: Date
    
    var isExpired: Bool {
        expiresAt < Date()
    }
    
    var isActive: Bool {
        status == .active && !isExpired
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case clientId = "client_id"
        case unitId = "unit_id"
        case code
        case createdByStaffId = "created_by_staff_id"
        case expiresAt = "expires_at"
        case isUsed = "is_used"
        case usedAt = "used_at"
        case linkedUserId = "linked_user_id"
        case status
        case unlinkedAt = "unlinked_at"
        case unlinkedByStaffId = "unlinked_by_staff_id"
        case createdAt = "created_at"
    }
}

enum LinkStatus: String, Codable {
    case active
    case used
    case expired
    case unlinked
}

struct ClientFlag: Identifiable, Codable {
    let id: String
    let clientId: String
    var flagKey: String
    var isOn: Bool
    let updatedByStaffId: String?
    let updatedAt: Date
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case clientId = "client_id"
        case flagKey = "flag_key"
        case isOn = "is_on"
        case updatedByStaffId = "updated_by_staff_id"
        case updatedAt = "updated_at"
        case createdAt = "created_at"
    }
}

enum ClientFlagType: String, CaseIterable {
    case trauma
    case lowReadiness = "low_readiness"
    case risk
    case needsInterpreter = "needs_interpreter"
    
    var displayName: String {
        switch self {
        case .trauma: return "Trauma"
        case .lowReadiness: return "Low readiness"
        case .risk: return "Risk"
        case .needsInterpreter: return "Needs interpreter"
        }
    }
}

struct ClientNote: Identifiable, Codable, Hashable {
    let id: String
    let clientId: String
    let staffId: String
    var noteText: String
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case clientId = "client_id"
        case staffId = "staff_id"
        case noteText = "note_text"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
