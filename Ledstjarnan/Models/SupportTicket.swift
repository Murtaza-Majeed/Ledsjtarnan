//
//  SupportTicket.swift
//  Ledstjarnan
//

import Foundation

struct SupportTicket: Identifiable, Codable {
    let id: String
    let createdByStaffId: String?
    let unitId: String?
    let issueType: IssueType
    let locationPath: String?
    let description: String
    let attachmentUrl: String?
    let appVersion: String?
    let deviceModel: String?
    let status: TicketStatus
    let createdAt: Date
    
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
    
    enum IssueType: String, Codable, CaseIterable {
        case bug
        case data
        case sync
        case other
        
        var displayName: String {
            switch self {
            case .bug: return "Bug"
            case .data: return "Data issue"
            case .sync: return "Sync issue"
            case .other: return "Other"
            }
        }
        
        var icon: String {
            switch self {
            case .bug: return "ant"
            case .data: return "square.stack.3d.up"
            case .sync: return "arrow.triangle.2.circlepath"
            case .other: return "questionmark.circle"
            }
        }
    }
    
    enum TicketStatus: String, Codable {
        case new
        case inProgress = "in_progress"
        case resolved
        
        var displayName: String {
            switch self {
            case .new: return "New"
            case .inProgress: return "In progress"
            case .resolved: return "Resolved"
            }
        }
    }
}
