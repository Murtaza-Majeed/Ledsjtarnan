//
//  LivbojenChapter.swift
//  Ledstjarnan
//
//  Livbojen chapter and assignment models
//

import Foundation

struct LivbojenChapter: Identifiable, Codable {
    let id: String
    var category: String
    var title: String
    var description: String?
    var orderIndex: Int
    var isActive: Bool
    let createdAt: Date
    
    var categoryDisplayName: String {
        switch category.lowercased() {
        case "kropp_halsa": return "Kropp & hälsa"
        case "utbildning_arbete": return "Utbildning & arbete"
        case "social_kompetens": return "Social kompetens"
        case "sjalvstandighet": return "Självständighet"
        case "relationer": return "Relationer & nätverk"
        case "identitet": return "Identitet & utveckling"
        default: return category
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case category
        case title
        case description
        case orderIndex = "order_index"
        case isActive = "is_active"
        case createdAt = "created_at"
    }
}

enum ChapterAssignmentStatus: String, Codable {
    case assigned
    case unlocked
    case inProgress = "in_progress"
    case completed
}

struct ClientChapterAssignment: Identifiable, Codable {
    let id: String
    let clientId: String
    let chapterId: String
    let assignedByStaffId: String?
    let assignedAt: Date
    var status: ChapterAssignmentStatus
    
    enum CodingKeys: String, CodingKey {
        case id
        case clientId = "client_id"
        case chapterId = "chapter_id"
        case assignedByStaffId = "assigned_by_staff_id"
        case assignedAt = "assigned_at"
        case status
    }
}

// Extended assignment with chapter details
struct ChapterAssignmentDetail {
    let assignment: ClientChapterAssignment
    let chapter: LivbojenChapter
    
    var displayTitle: String {
        chapter.title
    }
    
    var categoryName: String {
        chapter.categoryDisplayName
    }
}
