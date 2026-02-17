//
//  Schedule.swift
//  Ledstjarnan
//
//  Schedule and planner models
//

import Foundation

enum PlannerItemType: String, Codable {
    case session
    case task
    case activity
}

enum PlannerItemStatus: String, Codable {
    case planned
    case done
    case cancelled
}

enum PlannerVisibility: String, Codable {
    case shared
    case staffOnly = "staff_only"
    case clientOnly = "client_only"
}

enum CreatedByRole: String, Codable {
    case staff
    case client
}

struct PlannerItem: Identifiable, Codable {
    let id: String
    var clientId: String?
    let unitId: String
    let createdByRole: CreatedByRole
    let createdByUserId: String?
    var type: PlannerItemType
    var title: String
    var startAt: Date
    var endAt: Date?
    var locked: Bool
    var visibility: PlannerVisibility
    var status: PlannerItemStatus
    var notes: String?
    var conflictOverride: Bool
    var cancelledAt: Date?
    var cancelledBy: String?
    let createdAt: Date
    let updatedAt: Date
    
    // Computed properties
    var isLocked: Bool {
        locked
    }
    
    var duration: TimeInterval? {
        guard let end = endAt else { return nil }
        return end.timeIntervalSince(startAt)
    }
    
    var durationMinutes: Int? {
        guard let duration = duration else { return nil }
        return Int(duration / 60)
    }
    
    var formattedTimeRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let start = formatter.string(from: startAt)
        if let end = endAt {
            let endStr = formatter.string(from: end)
            return "\(start) – \(endStr)"
        }
        return start
    }
    
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
        case conflictOverride = "conflict_override"
        case cancelledAt = "cancelled_at"
        case cancelledBy = "cancelled_by"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// Extended planner item with client info
struct PlannerItemDetail {
    let item: PlannerItem
    var clientName: String?
    
    var displayTitle: String {
        if let client = clientName {
            return "\(item.title) • \(client)"
        }
        return item.title
    }
}
