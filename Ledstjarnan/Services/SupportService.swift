//
//  SupportService.swift
//  Ledstjarnan
//

import Foundation
import Supabase

final class SupportService {
    private let supabase = SupabaseManager.shared.client
    private let isoFormatter = ISO8601DateFormatter()
    
    func createTicket(
        createdByStaffId: String?,
        unitId: String?,
        issueType: SupportTicket.IssueType,
        locationPath: String?,
        description: String,
        appVersion: String?,
        deviceModel: String?
    ) async throws -> SupportTicket {
        struct TicketInsert: Encodable {
            let created_by_staff_id: String?
            let unit_id: String?
            let issue_type: String
            let location_path: String?
            let description: String
            let app_version: String?
            let device_model: String?
        }
        let payload = TicketInsert(
            created_by_staff_id: createdByStaffId,
            unit_id: unitId,
            issue_type: issueType.rawValue,
            location_path: locationPath,
            description: description,
            app_version: appVersion,
            device_model: deviceModel
        )
        return try await supabase.database
            .from("support_tickets")
            .insert(payload)
            .select()
            .single()
            .execute()
            .value
    }
}
