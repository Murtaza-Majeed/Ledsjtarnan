//
//  LivbojenService.swift
//  Ledstjarnan
//

import Foundation
import Supabase

class LivbojenService {
    private let supabase = SupabaseManager.shared.client

    func getChapters() async throws -> [LivbojenChapter] {
        let response: [LivbojenChapter] = try await supabase.database
            .from("livbojen_chapters")
            .select()
            .eq("is_active", value: true)
            .order("order_index", ascending: true)
            .execute()
            .value
        return response
    }

    func getAssignments(clientId: String) async throws -> [ClientChapterAssignment] {
        let response: [ClientChapterAssignment] = try await supabase.database
            .from("client_chapter_assignments")
            .select()
            .eq("client_id", value: clientId)
            .execute()
            .value
        return response
    }

    func assignChapter(clientId: String, chapterId: String, staffId: String?) async throws -> ClientChapterAssignment {
        struct AssignmentInsert: Encodable {
            let client_id: String
            let chapter_id: String
            let assigned_by_staff_id: String?
            let status: String
        }
        let row = AssignmentInsert(
            client_id: clientId,
            chapter_id: chapterId,
            assigned_by_staff_id: staffId,
            status: "assigned"
        )
        let response: ClientChapterAssignment = try await supabase.database
            .from("client_chapter_assignments")
            .insert(row)
            .select()
            .single()
            .execute()
            .value
        return response
    }
}
