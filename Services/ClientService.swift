//
//  ClientService.swift
//  Ledstjarnan
//
//  Service for client operations
//

import Foundation
import Supabase

class ClientService {
    private let supabase = SupabaseClient.shared.client
    
    // MARK: - Client CRUD
    
    /// Get all clients for a unit
    func getClients(unitId: String) async throws -> [Client] {
        let response: [Client] = try await supabase.database
            .from("clients")
            .select()
            .eq("unit_id", value: unitId)
            .order("created_at", ascending: false)
            .execute()
            .value
        return response
    }
    
    /// Get single client
    func getClient(clientId: String) async throws -> Client {
        let response: Client = try await supabase.database
            .from("clients")
            .select()
            .eq("id", value: clientId)
            .single()
            .execute()
            .value
        return response
    }
    
    /// Create new client
    func createClient(
        unitId: String,
        nameOrCode: String,
        createdByStaffId: String
    ) async throws -> Client {
        let client = [
            "unit_id": unitId,
            "name_or_code": nameOrCode,
            "created_by_staff_id": createdByStaffId
        ]
        
        let response: Client = try await supabase.database
            .from("clients")
            .insert(client)
            .select()
            .single()
            .execute()
            .value
        return response
    }
    
    /// Assign a staff member to a client (staff_client_access upsert)
    func assignStaffToClient(clientId: String, staffId: String, isPrimary: Bool = false) async throws {
        let access = [
            "staff_id": staffId,
            "client_id": clientId,
            "is_primary": isPrimary
        ] as [String : Any]
        
        try await supabase.database
            .from("staff_client_access")
            .upsert(access)
            .execute()
    }
    
    /// Update client
    func updateClient(clientId: String, nameOrCode: String) async throws -> Client {
        let updates = ["name_or_code": nameOrCode]
        
        let response: Client = try await supabase.database
            .from("clients")
            .update(updates)
            .eq("id", value: clientId)
            .select()
            .single()
            .execute()
            .value
        return response
    }

    /// Delete client and cascade related data
    func deleteClient(clientId: String) async throws {
        try await supabase.database
            .from("clients")
            .delete()
            .eq("id", value: clientId)
            .execute()
    }
    
    // MARK: - Client Details
    
    /// Get client detail with related data
    func getClientDetail(clientId: String) async throws -> ClientDetail {
        let client = try await getClient(clientId: clientId)
        
        // Get related data in parallel
        async let hasBaseline = checkHasBaseline(clientId: clientId)
        async let activePlan = getActivePlan(clientId: clientId)
        async let flags = getClientFlags(clientId: clientId)
        async let notesCount = getNotesCount(clientId: clientId)
        
        let (baseline, plan, clientFlags, notes) = try await (hasBaseline, activePlan, flags, notesCount)
        
        return ClientDetail(
            client: client,
            hasBaseline: baseline,
            activePlan: plan,
            nextFollowUpDate: plan?.nextFollowUpAt,
            flags: clientFlags,
            notesCount: notes
        )
    }
    
    /// Aggregated snapshot for the Clients tab list
    func getClientSummaries(unitId: String, staffId: String?) async throws -> [ClientListSummary] {
        let clients = try await getClients(unitId: unitId)
        guard !clients.isEmpty else { return [] }
        let clientIds = clients.map(\.id)
        
        async let baselineIdsTask = getClientsWithCompletedBaseline(clientIds: clientIds)
        async let activePlansTask = getActivePlansMap(clientIds: clientIds)
        async let flagsMapTask = getActiveFlagsMap(clientIds: clientIds)
        async let myClientIdsTask = getAssignedClientIds(staffId: staffId)
        
        let (baselineIds, planMap, flagsMap, myClientIds) = try await (
            baselineIdsTask,
            activePlansTask,
            flagsMapTask,
            myClientIdsTask
        )
        
        return clients.map { client in
            let plan = planMap[client.id]
            return ClientListSummary(
                client: client,
                hasBaseline: baselineIds.contains(client.id),
                activePlan: plan,
                flags: flagsMap[client.id] ?? [],
                isMyClient: myClientIds.contains(client.id),
                nextFollowUpDate: plan?.nextFollowUpAt
            )
        }
    }
    
    private func checkHasBaseline(clientId: String) async throws -> Bool {
        let count: Int = try await supabase.database
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
            let response: Plan = try await supabase.database
                .from("plans")
                .select()
                .eq("client_id", value: clientId)
                .eq("status", value: "active")
                .single()
                .execute()
                .value
            return response
        } catch {
            return nil
        }
    }
    
    private func getClientFlags(clientId: String) async throws -> [ClientFlag] {
        let response: [ClientFlag] = try await supabase.database
            .from("client_flags")
            .select()
            .eq("client_id", value: clientId)
            .eq("is_on", value: true)
            .execute()
            .value
        return response
    }
    
    private func getNotesCount(clientId: String) async throws -> Int {
        let count: Int = try await supabase.database
            .from("client_notes")
            .select("id", head: true, count: .exact)
            .eq("client_id", value: clientId)
            .execute()
            .count ?? 0
        return count
    }
    
    private func getClientsWithCompletedBaseline(clientIds: [String]) async throws -> Set<String> {
        guard !clientIds.isEmpty else { return [] }
        let rows: [ClientIdResult] = try await supabase.database
            .from("assessments")
            .select("client_id")
            .eq("assessment_type", value: "baseline")
            .eq("status", value: "completed")
            .in("client_id", values: clientIds)
            .execute()
            .value
        return Set(rows.map(\.clientId))
    }
    
    private func getActivePlansMap(clientIds: [String]) async throws -> [String: Plan] {
        guard !clientIds.isEmpty else { return [:] }
        let plans: [Plan] = try await supabase.database
            .from("plans")
            .select()
            .eq("status", value: "active")
            .in("client_id", values: clientIds)
            .execute()
            .value
        return plans.reduce(into: [:]) { partialResult, plan in
            guard let existing = partialResult[plan.clientId] else {
                partialResult[plan.clientId] = plan
                return
            }
            let existingDate = existing.updatedAt ?? existing.createdAt
            let candidateDate = plan.updatedAt ?? plan.createdAt
            if let candidateDate, let existingDate {
                if candidateDate > existingDate {
                    partialResult[plan.clientId] = plan
                }
            } else {
                // If timestamps are missing, prefer the most recently iterated plan
                partialResult[plan.clientId] = plan
            }
        }
    }
    
    private func getActiveFlagsMap(clientIds: [String]) async throws -> [String: [ClientFlag]] {
        guard !clientIds.isEmpty else { return [:] }
        let flags: [ClientFlag] = try await supabase.database
            .from("client_flags")
            .select()
            .eq("is_on", value: true)
            .in("client_id", values: clientIds)
            .execute()
            .value
        return Dictionary(grouping: flags, by: \.clientId)
    }
    
    private func getAssignedClientIds(staffId: String?) async throws -> Set<String> {
        guard let staffId else { return [] }
        let rows: [ClientIdResult] = try await supabase.database
            .from("staff_client_access")
            .select("client_id")
            .eq("staff_id", value: staffId)
            .execute()
            .value
        return Set(rows.map(\.clientId))
    }
    
    // MARK: - Client Linking
    
    /// Generate link code for client
    func generateLinkCode(
        clientId: String,
        unitId: String,
        createdByStaffId: String
    ) async throws -> ClientLink {
        // Generate 6-digit code
        let code = String(format: "%06d", Int.random(in: 100000...999999))
        
        // Expires in 15 minutes
        let expiresAt = Date().addingTimeInterval(15 * 60)
        
        let link = [
            "client_id": clientId,
            "unit_id": unitId,
            "code": code,
            "created_by_staff_id": createdByStaffId,
            "expires_at": ISO8601DateFormatter().string(from: expiresAt)
        ]
        
        let response: ClientLink = try await supabase.database
            .from("client_links")
            .insert(link)
            .select()
            .single()
            .execute()
            .value
        return response
    }
    
    /// Get active link code for client
    func getActiveLinkCode(clientId: String) async throws -> ClientLink? {
        do {
            let response: ClientLink = try await supabase.database
                .from("client_links")
                .select()
                .eq("client_id", value: clientId)
                .eq("status", value: "active")
                .single()
                .execute()
                .value
            return response.isExpired ? nil : response
        } catch {
            return nil
        }
    }
    
    /// Unlink client from Livbojen
    func unlinkClient(clientId: String, staffId: String) async throws {
        let updates = [
            "status": "unlinked",
            "unlinked_at": ISO8601DateFormatter().string(from: Date()),
            "unlinked_by_staff_id": staffId
        ]
        
        try await supabase.database
            .from("client_links")
            .update(updates)
            .eq("client_id", value: clientId)
            .eq("status", value: "used")
            .execute()
        
        // Also clear linked_user_id from client
        try await supabase.database
            .from("clients")
            .update(["linked_user_id": NSNull()])
            .eq("id", value: clientId)
            .execute()
    }
    
    // MARK: - Client Notes (Staff Only)
    
    /// Get notes for client
    func getNotes(clientId: String) async throws -> [ClientNote] {
        let response: [ClientNote] = try await supabase.database
            .from("client_notes")
            .select()
            .eq("client_id", value: clientId)
            .order("created_at", ascending: false)
            .execute()
            .value
        return response
    }
    
    /// Create note
    func createNote(clientId: String, staffId: String, noteText: String) async throws -> ClientNote {
        let note = [
            "client_id": clientId,
            "staff_id": staffId,
            "note_text": noteText
        ]
        
        let response: ClientNote = try await supabase.database
            .from("client_notes")
            .insert(note)
            .select()
            .single()
            .execute()
            .value
        return response
    }
    
    /// Update note
    func updateNote(noteId: String, noteText: String) async throws -> ClientNote {
        let updates = ["note_text": noteText]
        
        let response: ClientNote = try await supabase.database
            .from("client_notes")
            .update(updates)
            .eq("id", value: noteId)
            .select()
            .single()
            .execute()
            .value
        return response
    }
    
    /// Delete note
    func deleteNote(noteId: String) async throws {
        try await supabase.database
            .from("client_notes")
            .delete()
            .eq("id", value: noteId)
            .execute()
    }
    
    // MARK: - Client Flags (Staff Only)
    
    /// Toggle flag
    func toggleFlag(clientId: String, flagKey: String, isOn: Bool, staffId: String) async throws {
        let flag = [
            "client_id": clientId,
            "flag_key": flagKey,
            "is_on": isOn,
            "updated_by_staff_id": staffId
        ] as [String : Any]
        
        try await supabase.database
            .from("client_flags")
            .upsert(flag)
            .execute()
    }
    
    // MARK: - Timeline
    
    /// Get timeline events for client
    func getTimeline(clientId: String) async throws -> [ClientTimelineEvent] {
        let response: [ClientTimelineEvent] = try await supabase.database
            .from("client_timeline_events")
            .select()
            .eq("client_id", value: clientId)
            .order("created_at", ascending: false)
            .execute()
            .value
        return response
    }
    
    /// Create timeline event
    func createTimelineEvent(
        clientId: String,
        unitId: String,
        eventType: String,
        title: String,
        description: String?,
        staffId: String
    ) async throws {
        let event = [
            "client_id": clientId,
            "unit_id": unitId,
            "event_type": eventType,
            "title": title,
            "description": description as Any,
            "created_by_staff_id": staffId
        ] as [String : Any]
        
        try await supabase.database
            .from("client_timeline_events")
            .insert(event)
            .execute()
    }
}

private struct ClientIdResult: Decodable {
    let clientId: String
    
    enum CodingKeys: String, CodingKey {
        case clientId = "client_id"
    }
}
