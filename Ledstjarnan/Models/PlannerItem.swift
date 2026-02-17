//
//  PlannerItem.swift
//  Ledstjarnan
//
//  Matches planner_items table.
//

import Foundation

struct PlannerItem: Identifiable, Codable {
    let id: String
    let clientId: String?
    let unitId: String
    let createdByRole: String
    let createdByUserId: String?
    let type: String
    let title: String
    let startAt: Date
    let endAt: Date?
    let locked: Bool?
    let visibility: String?
    let status: String
    let notes: String?
    let createdAt: Date?
    let updatedAt: Date?

    var isSession: Bool { type == "session" }
    var isLocked: Bool { locked == true }

    enum CodingKeys: String, CodingKey {
        case id
        case clientId = "client_id"
        case unitId = "unit_id"
        case createdByRole = "created_by_role"
        case createdByUserId = "created_by_user_id"
        case type
        case title
        case startAt = "start_at"
        case endAt = "end_at"
        case locked
        case visibility
        case status
        case notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
