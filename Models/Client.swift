//
//  Client.swift
//  Ledstjarnan
//
//  Client data model
//

import Foundation

struct Client: Identifiable, Codable {
    let id: String
    let unitId: String
    let nameOrCode: String
    var linkedUserId: String?
    let createdByStaffId: String?
    let createdAt: Date
    let updatedAt: Date
    
    // Computed properties for UI
    var isLinked: Bool {
        linkedUserId != nil
    }
    
    var displayName: String {
        nameOrCode
    }
    
    var initials: String {
        let components = nameOrCode.components(separatedBy: " ")
        if components.count > 1 {
            return String((components.first?.prefix(1) ?? "") + (components.last?.prefix(1) ?? ""))
        }
        return String(nameOrCode.prefix(1))
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

// Extended client info with related data
struct ClientDetail {
    let client: Client
    var hasBaseline: Bool = false
    var activePlan: Plan?
    var nextFollowUpDate: Date?
    var flags: [ClientFlag] = []
    var notesCount: Int = 0
    
    var statusBadges: [String] {
        var badges: [String] = []
        if hasBaseline {
            badges.append("Baseline")
        }
        if activePlan != nil {
            badges.append("Plan")
        }
        if client.isLinked {
            badges.append("Linked")
        } else {
            badges.append("Not linked")
        }
        return badges
    }
    
    var isDueSoon: Bool {
        guard let followUp = nextFollowUpDate else { return false }
        let daysUntil = Calendar.current.dateComponents([.day], from: Date(), to: followUp).day ?? 0
        return daysUntil >= 0 && daysUntil <= 14
    }
}
