//
//  Timeline.swift
//  Ledstjarnan
//
//  Timeline and support ticket models
//

import Foundation

struct ClientTimelineEvent: Identifiable, Codable {
    let id: String
    let clientId: String
    let unitId: String
    var eventType: String
    var title: String
    var description: String?
    var metadata: [String: String]?
    let createdByStaffId: String?
    let createdAt: Date
    
    var icon: String {
        switch eventType {
        case "baseline_completed":
            return "checkmark.circle.fill"
        case "followup_completed":
            return "arrow.triangle.2.circlepath.circle.fill"
        case "plan_activated":
            return "list.bullet.clipboard.fill"
        case "chapters_assigned":
            return "book.fill"
        case "link_created":
            return "link"
        case "link_removed":
            return "link.badge.plus"
        case "session_booked":
            return "calendar.badge.plus"
        case "session_cancelled":
            return "calendar.badge.minus"
        default:
            return "circle.fill"
        }
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case clientId = "client_id"
        case unitId = "unit_id"
        case eventType = "event_type"
        case title
        case description
        case metadata
        case createdByStaffId = "created_by_staff_id"
        case createdAt = "created_at"
    }
}

enum IssueType: String, Codable, CaseIterable {
    case bug
    case data
    case sync
    case other
    
    var displayName: String {
        rawValue.capitalized
    }
}

enum TicketStatus: String, Codable {
    case new
    case inProgress = "in_progress"
    case resolved
}

struct SupportTicket: Identifiable, Codable {
    let id: String
    let createdByStaffId: String?
    let unitId: String?
    var issueType: IssueType
    var locationPath: String?
    var description: String
    var attachmentUrl: String?
    var appVersion: String?
    var deviceModel: String?
    var status: TicketStatus
    let createdAt: Date
    
    var ticketNumber: String {
        let shortId = String(id.prefix(8))
        return "#LS-\(shortId)"
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case createdByStaffId = "created_by_staff_id"
        case unitId = "unit_id"
        case issueType = "issue_type"
        case locationPath = "location_path"
        case description
        case attachmentUrl = "attachment_url"
        case appVersion = "app_version"
        case deviceModel = "device_model"
        case status
        case createdAt = "created_at"
    }
}
