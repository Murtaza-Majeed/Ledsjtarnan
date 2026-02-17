//
//  Plan.swift
//  Ledstjarnan
//
//  Care plan models
//

import Foundation

enum PlanStatus: String, Codable {
    case draft
    case active
    case archived
}

struct Plan: Identifiable, Codable {
    let id: String
    let clientId: String
    let unitId: String
    let createdByStaffId: String?
    var title: String?
    var focusDomains: [String]
    var status: PlanStatus
    var nextFollowUpAt: Date?
    var activatedAt: Date?
    var archivedAt: Date?
    let createdAt: Date
    let updatedAt: Date
    
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
    var goalText: String
    let createdByStaffId: String?
    let createdAt: Date
    let updatedAt: Date
    
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

enum ActionWho: String, Codable {
    case staff
    case client
    case shared
}

struct PlanAction: Identifiable, Codable {
    let id: String
    let planId: String
    let areaKey: String
    var title: String
    var who: ActionWho
    var frequency: String?
    var lockedSession: Bool
    var defaultDuration: Int? // minutes
    var notes: String?
    let createdAt: Date
    let updatedAt: Date
    
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

// Extended plan with related data
struct PlanDetail {
    let plan: Plan
    var goals: [PlanGoal] = []
    var actions: [PlanAction] = []
    var assignedChapters: [ClientChapterAssignment] = []
    
    var goalsCount: Int {
        goals.count
    }
    
    var actionsCount: Int {
        actions.count
    }
    
    var chaptersCount: Int {
        assignedChapters.count
    }
}
