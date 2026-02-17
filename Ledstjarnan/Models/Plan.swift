//
//  Plan.swift
//  Ledstjarnan
//
//  Matches plans, plan_goals, plan_actions tables.
//

import Foundation

struct Plan: Identifiable, Codable {
    let id: String
    let clientId: String
    let unitId: String
    let createdByStaffId: String?
    let title: String?
    let focusDomains: [String]?
    let status: String
    let nextFollowUpAt: Date?
    let activatedAt: Date?
    let archivedAt: Date?
    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case clientId = "client_id"
        case unitId = "unit_id"
        case createdByStaffId = "created_by_staff_id"
        case title
        case focusDomains = "focus_domains"
        case status
        case nextFollowUpAt = "next_follow_up_at"
        case activatedAt = "activated_at"
        case archivedAt = "archived_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct PlanGoal: Identifiable, Codable {
    let id: String
    let planId: String
    let areaKey: String
    let goalText: String
    let createdByStaffId: String?
    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case planId = "plan_id"
        case areaKey = "area_key"
        case goalText = "goal_text"
        case createdByStaffId = "created_by_staff_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct PlanAction: Identifiable, Codable {
    let id: String
    let planId: String
    let areaKey: String
    let title: String
    let who: String
    let frequency: String?
    let lockedSession: Bool?
    let defaultDuration: Int?
    let notes: String?
    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case planId = "plan_id"
        case areaKey = "area_key"
        case title
        case who
        case frequency
        case lockedSession = "locked_session"
        case defaultDuration = "default_duration"
        case notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
