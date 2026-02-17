//
//  PlannerService.swift
//  Ledstjarnan
//

import Foundation
import Supabase

class PlannerService {
    private let supabase = SupabaseManager.shared.client

    func getItems(unitId: String) async throws -> [PlannerItem] {
        let response: [PlannerItem] = try await supabase.database
            .from("planner_items")
            .select()
            .eq("unit_id", value: unitId)
            .order("start_at", ascending: true)
            .execute()
            .value
        return response
    }

    func getItems(clientId: String) async throws -> [PlannerItem] {
        let response: [PlannerItem] = try await supabase.database
            .from("planner_items")
            .select()
            .eq("client_id", value: clientId)
            .order("start_at", ascending: true)
            .execute()
            .value
        return response
    }

    func createItem(
        unitId: String,
        clientId: String?,
        type: String,
        title: String,
        startAt: Date,
        endAt: Date?,
        locked: Bool,
        createdByUserId: String?
    ) async throws -> PlannerItem {
        struct ItemInsert: Encodable {
            let unit_id: String
            let client_id: String?
            let created_by_role: String
            let created_by_user_id: String?
            let type: String
            let title: String
            let start_at: String
            let end_at: String?
            let locked: Bool
        }
        let row = ItemInsert(
            unit_id: unitId,
            client_id: clientId,
            created_by_role: "staff",
            created_by_user_id: createdByUserId,
            type: type,
            title: title,
            start_at: ISO8601DateFormatter().string(from: startAt),
            end_at: endAt.map { ISO8601DateFormatter().string(from: $0) },
            locked: locked
        )
        let response: PlannerItem = try await supabase.database
            .from("planner_items")
            .insert(row)
            .select()
            .single()
            .execute()
            .value
        return response
    }

    func updateItem(id: String, status: String?) async throws {
        guard let status else { return }
        struct ItemUpdate: Encodable {
            let status: String
        }
        let payload = ItemUpdate(status: status)
        try await supabase.database
            .from("planner_items")
            .update(payload)
            .eq("id", value: id)
            .execute()
    }

    func cancelItem(id: String) async throws {
        try await updateItem(id: id, status: "cancelled")
    }
    
    func updateStatus(itemId: String, status: String) async throws {
        try await updateItem(id: itemId, status: status)
    }
}
