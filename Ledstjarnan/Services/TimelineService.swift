//
//  TimelineService.swift
//  Ledstjarnan
//

import Foundation
import Supabase

class TimelineService {
    private let supabase = SupabaseManager.shared.client

    /// Fetch timeline events for a client, newest first. RLS scoped by unit.
    func getTimelineEvents(clientId: String) async throws -> [ClientTimelineEvent] {
        let response: [ClientTimelineEvent] = try await supabase.database
            .from("client_timeline_events")
            .select()
            .eq("client_id", value: clientId)
            .order("created_at", ascending: false)
            .execute()
            .value
        return response
    }
}
