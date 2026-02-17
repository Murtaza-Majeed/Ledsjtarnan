//
//  LivbojenChapter.swift
//  Ledstjarnan
//
//  Matches livbojen_chapters and client_chapter_assignments tables.
//

import Foundation

struct LivbojenChapter: Identifiable, Codable {
    let id: String
    let category: String
    let title: String
    let description: String?
    let orderIndex: Int?
    let isActive: Bool?
    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case category
        case title
        case description
        case orderIndex = "order_index"
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct ClientChapterAssignment: Identifiable, Codable {
    let id: String
    let clientId: String
    let chapterId: String
    let assignedByStaffId: String?
    let assignedAt: Date?
    let status: String

    enum CodingKeys: String, CodingKey {
        case id
        case clientId = "client_id"
        case chapterId = "chapter_id"
        case assignedByStaffId = "assigned_by_staff_id"
        case assignedAt = "assigned_at"
        case status
    }
}
