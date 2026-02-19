//
//  Client.swift
//  Ledstjarnan
//
//  Client data model (matches DB clients table).
//  Display name always comes from name_or_code in the database.
//

import Foundation

struct Client: Identifiable, Codable, Hashable {
    let id: String
    let unitId: String
    /// From DB column `name_or_code` – this is the real client name/code we display.
    let nameOrCode: String
    var linkedUserId: String?
    let createdByStaffId: String?
    let createdAt: Date?
    let updatedAt: Date?
    
    var isLinked: Bool {
        linkedUserId != nil
    }
    
    /// Always use this for UI – comes from DB `name_or_code`.
    var displayName: String {
        let raw = nameOrCode.trimmingCharacters(in: .whitespacesAndNewlines)
        return raw.isEmpty ? "Unnamed" : raw
    }
    
    var statusLabel: String {
        isLinked ? "Linked" : "Active"
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case unitId = "unit_id"
        case nameOrCode = "name_or_code"
        case linkedUserId = "linked_user_id"
        case createdByStaffId = "created_by_staff_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct ClientDetail {
    let client: Client
    var hasBaseline: Bool
    var activePlan: Plan?
    var nextFollowUpDate: Date?
    var flags: [ClientFlag]
    var notesCount: Int
    
    var statusBadges: [StatusBadge] {
        var badges: [StatusBadge] = []
        if client.isLinked {
            badges.append(.init(label: "Linked", icon: "link"))
        }
        if hasBaseline {
            badges.append(.init(label: "Baseline done", icon: "checkmark.seal"))
        }
        if let plan = activePlan {
            let subtitle = plan.nextFollowUpAt.flatMap { Self.followUpFormatter.string(from: $0) }
            badges.append(.init(label: "Plan active", icon: "list.bullet.rectangle", detail: subtitle))
        }
        return badges
    }
    
    struct StatusBadge: Identifiable {
        let id = UUID()
        let label: String
        let icon: String
        var detail: String? = nil
    }
    
    private static let followUpFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }()
}

struct ClientListSummary: Identifiable {
    let client: Client
    var hasBaseline: Bool
    var activePlan: Plan?
    var flags: [ClientFlag]
    var isMyClient: Bool
    var nextFollowUpDate: Date?
    
    var id: String { client.id }
    var isLinked: Bool { client.isLinked }
    var hasPlan: Bool { activePlan != nil }
    var hasFlags: Bool { !flags.isEmpty }
    var isNotLinked: Bool { !client.isLinked }
    
    var baselineStatusLabel: String {
        hasBaseline ? "Baseline" : "No baseline"
    }
    
    var planStatusLabel: String {
        hasPlan ? "Plan" : "No plan"
    }
    
    var linkStatusLabel: String {
        isLinked ? "Linked" : "Not linked"
    }
    
    var flagTypes: [ClientFlagType] {
        flags.map(\.type)
    }
    
    var isDueSoon: Bool {
        guard let nextFollowUpDate else { return false }
        let daysUntil = Calendar.current.dateComponents([.day], from: Date(), to: nextFollowUpDate).day ?? .max
        return (0...Self.dueSoonThresholdDays).contains(daysUntil)
    }
    
    var isOverdue: Bool {
        guard let nextFollowUpDate else { return false }
        return nextFollowUpDate < Date()
    }
    
    static let dueSoonThresholdDays = 14
}

struct ClientFlag: Identifiable, Codable {
    let id: String
    let clientId: String
    var flagKey: String
    var isOn: Bool
    let updatedByStaffId: String?
    let updatedAt: Date?
    let createdAt: Date?
    
    var type: ClientFlagType {
        ClientFlagType(rawValue: flagKey) ?? .other
    }
    
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
    case other
    
    var title: String {
        switch self {
        case .trauma: return "Trauma"
        case .lowReadiness: return "Low readiness"
        case .risk: return "Risk"
        case .needsInterpreter: return "Needs interpreter"
        case .other: return "Flag"
        }
    }
    
    var icon: String {
        switch self {
        case .trauma: return "heart.text.square"
        case .lowReadiness: return "tortoise"
        case .risk: return "exclamationmark.triangle"
        case .needsInterpreter: return "globe"
        case .other: return "flag"
        }
    }
}

struct ClientNote: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let clientId: String
    let staffId: String
    var noteText: String
    let createdAt: Date?
    let updatedAt: Date?
    
    var formattedDate: String {
        guard let createdAt else { return "--" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case clientId = "client_id"
        case staffId = "staff_id"
        case noteText = "note_text"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct ClientLink: Identifiable, Codable {
    let id: String
    let clientId: String
    let unitId: String
    let code: String
    let createdByStaffId: String?
    let expiresAt: Date
    let isUsed: Bool
    let usedAt: Date?
    let linkedUserId: String?
    var status: String
    let unlinkedAt: Date?
    let unlinkedByStaffId: String?
    let createdAt: Date
    
    var isExpired: Bool {
        expiresAt < Date()
    }
    
    var displayStatus: String {
        if isUsed { return "Used" }
        if isExpired { return "Expired" }
        if status == "unlinked" { return "Unlinked" }
        return "Active"
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
