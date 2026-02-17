//
//  ClientService.swift
//  Ledstjarnan
//

import Foundation
import Supabase

final class ClientService {
    private let supabase = SupabaseManager.shared.client
    private let isoFormatter = ISO8601DateFormatter()
    
    // MARK: - Clients
    
    func getClients(unitId: String) async throws -> [Client] {
        try await supabase.database
            .from("clients")
            .select()
            .eq("unit_id", value: unitId)
            .order("created_at", ascending: false)
            .execute()
            .value
    }
    
    func getClient(clientId: String) async throws -> Client {
        try await supabase.database
            .from("clients")
            .select()
            .eq("id", value: clientId)
            .single()
            .execute()
            .value
    }
    
    func createClient(unitId: String, nameOrCode: String, createdByStaffId: String) async throws -> Client {
        struct ClientInsert: Encodable {
            let unit_id: String
            let name_or_code: String
            let created_by_staff_id: String
        }
        let payload = ClientInsert(unit_id: unitId, name_or_code: nameOrCode, created_by_staff_id: createdByStaffId)
        return try await supabase.database
            .from("clients")
            .insert(payload)
            .select()
            .single()
            .execute()
            .value
    }
    
    // MARK: - Client Detail
    
    func getClientDetail(clientId: String) async throws -> ClientDetail {
        let client = try await getClient(clientId: clientId)
        async let hasBaselineTask = checkHasBaseline(clientId: clientId)
        async let planTask = getActivePlan(clientId: clientId)
        async let flagsTask = getClientFlags(clientId: clientId)
        async let notesCountTask = getNotesCount(clientId: clientId)
        
        let plan = try await planTask
        return ClientDetail(
            client: client,
            hasBaseline: try await hasBaselineTask,
            activePlan: plan,
            nextFollowUpDate: plan?.nextFollowUpAt,
            flags: try await flagsTask,
            notesCount: try await notesCountTask
        )
    }
    
    private func checkHasBaseline(clientId: String) async throws -> Bool {
        let count = try await supabase.database
            .from("assessments")
            .select("id", head: true, count: .exact)
            .eq("client_id", value: clientId)
            .eq("assessment_type", value: "baseline")
            .eq("status", value: "completed")
            .execute()
            .count ?? 0
        return count > 0
    }
    
    private func getActivePlan(clientId: String) async throws -> Plan? {
        do {
            return try await supabase.database
                .from("plans")
                .select()
                .eq("client_id", value: clientId)
                .eq("status", value: "active")
                .single()
                .execute()
                .value
        } catch {
            return nil
        }
    }
    
    private func getClientFlags(clientId: String) async throws -> [ClientFlag] {
        try await supabase.database
            .from("client_flags")
            .select()
            .eq("client_id", value: clientId)
            .eq("is_on", value: true)
            .execute()
            .value
    }
    
    private func getNotesCount(clientId: String) async throws -> Int {
        try await supabase.database
            .from("client_notes")
            .select("id", head: true, count: .exact)
            .eq("client_id", value: clientId)
            .execute()
            .count ?? 0
    }
    
    // MARK: - Livbojen linking
    
    func generateLinkCode(clientId: String, unitId: String, createdByStaffId: String) async throws -> ClientLink {
        struct LinkInsert: Encodable {
            let client_id: String
            let unit_id: String
            let code: String
            let created_by_staff_id: String
            let expires_at: String
        }
        let code = String(format: "%06d", Int.random(in: 100000...999999))
        let expiresAt = Date().addingTimeInterval(15 * 60)
        let payload = LinkInsert(
            client_id: clientId,
            unit_id: unitId,
            code: code,
            created_by_staff_id: createdByStaffId,
            expires_at: isoFormatter.string(from: expiresAt)
        )
        return try await supabase.database
            .from("client_links")
            .insert(payload)
            .select()
            .single()
            .execute()
            .value
    }
    
    func getActiveLinkCode(clientId: String) async throws -> ClientLink? {
        do {
            let link: ClientLink = try await supabase.database
                .from("client_links")
                .select()
                .eq("client_id", value: clientId)
                .eq("status", value: "active")
                .single()
                .execute()
                .value
            return link.isExpired ? nil : link
        } catch {
            return nil
        }
    }
    
    func unlinkClient(clientId: String, staffId: String) async throws {
        struct UpdatePayload: Encodable {
            let status: String
            let unlinked_at: String
            let unlinked_by_staff_id: String
        }
        let payload = UpdatePayload(
            status: "unlinked",
            unlinked_at: isoFormatter.string(from: Date()),
            unlinked_by_staff_id: staffId
        )
        try await supabase.database
            .from("client_links")
            .update(payload)
            .eq("client_id", value: clientId)
            .eq("status", value: "used")
            .execute()
        struct UnlinkClientPayload: Encodable {
            let linked_user_id: String?
        }
        try await supabase.database
            .from("clients")
            .update(UnlinkClientPayload(linked_user_id: nil))
            .eq("id", value: clientId)
            .execute()
    }
    
    // MARK: - Notes
    
    func getNotes(clientId: String) async throws -> [ClientNote] {
        try await supabase.database
            .from("client_notes")
            .select()
            .eq("client_id", value: clientId)
            .order("created_at", ascending: false)
            .execute()
            .value
    }
    
    func createNote(clientId: String, staffId: String, noteText: String) async throws -> ClientNote {
        struct NoteInsert: Encodable {
            let client_id: String
            let staff_id: String
            let note_text: String
        }
        let payload = NoteInsert(client_id: clientId, staff_id: staffId, note_text: noteText)
        return try await supabase.database
            .from("client_notes")
            .insert(payload)
            .select()
            .single()
            .execute()
            .value
    }
    
    func updateNote(noteId: String, noteText: String) async throws -> ClientNote {
        struct NoteUpdate: Encodable {
            let note_text: String
        }
        let payload = NoteUpdate(note_text: noteText)
        return try await supabase.database
            .from("client_notes")
            .update(payload)
            .eq("id", value: noteId)
            .select()
            .single()
            .execute()
            .value
    }
    
    func deleteNote(noteId: String) async throws {
        try await supabase.database
            .from("client_notes")
            .delete()
            .eq("id", value: noteId)
            .execute()
    }
    
    // MARK: - Flags
    
    func toggleFlag(clientId: String, flagKey: String, isOn: Bool, staffId: String) async throws {
        struct FlagUpsert: Encodable {
            let client_id: String
            let flag_key: String
            let is_on: Bool
            let updated_by_staff_id: String
        }
        let payload = FlagUpsert(client_id: clientId, flag_key: flagKey, is_on: isOn, updated_by_staff_id: staffId)
        try await supabase.database
            .from("client_flags")
            .upsert(payload)
            .execute()
    }
    
    // MARK: - Timeline
    
    func getTimeline(clientId: String) async throws -> [ClientTimelineEvent] {
        try await supabase.database
            .from("client_timeline_events")
            .select()
            .eq("client_id", value: clientId)
            .order("created_at", ascending: false)
            .execute()
            .value
    }
    
    func createTimelineEvent(clientId: String, unitId: String, eventType: String, title: String, description: String?, staffId: String) async throws {
        struct EventInsert: Encodable {
            let client_id: String
            let unit_id: String
            let event_type: String
            let title: String
            let description: String?
            let created_by_staff_id: String
        }
        let payload = EventInsert(
            client_id: clientId,
            unit_id: unitId,
            event_type: eventType,
            title: title,
            description: description,
            created_by_staff_id: staffId
        )
        try await supabase.database
            .from("client_timeline_events")
            .insert(payload)
            .execute()
    }
}
