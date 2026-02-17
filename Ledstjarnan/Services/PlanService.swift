//
//  PlanService.swift
//  Ledstjarnan
//

import Foundation
import Supabase

class PlanService {
    private let supabase = SupabaseManager.shared.client

    func getPlans(unitId: String) async throws -> [Plan] {
        let response: [Plan] = try await supabase.database
            .from("plans")
            .select()
            .eq("unit_id", value: unitId)
            .order("created_at", ascending: false)
            .execute()
            .value
        return response
    }

    func getPlans(clientId: String) async throws -> [Plan] {
        let response: [Plan] = try await supabase.database
            .from("plans")
            .select()
            .eq("client_id", value: clientId)
            .order("created_at", ascending: false)
            .execute()
            .value
        return response
    }

    func createPlan(clientId: String, unitId: String, createdByStaffId: String?, title: String?) async throws -> Plan {
        struct PlanInsert: Encodable {
            let client_id: String
            let unit_id: String
            let created_by_staff_id: String?
            let title: String?
            let status: String
        }
        let row = PlanInsert(
            client_id: clientId,
            unit_id: unitId,
            created_by_staff_id: createdByStaffId,
            title: title,
            status: "draft"
        )
        let response: Plan = try await supabase.database
            .from("plans")
            .insert(row)
            .select()
            .single()
            .execute()
            .value
        return response
    }

    func updatePlan(id: String, title: String?, focusDomains: [String]?, status: String?, nextFollowUpAt: Date?) async throws {
        struct PlanUpdate: Encodable {
            let title: String?
            let focus_domains: [String]?
            let status: String?
            let next_follow_up_at: String?
        }
        let payload = PlanUpdate(
            title: title,
            focus_domains: focusDomains,
            status: status,
            next_follow_up_at: nextFollowUpAt.map { ISO8601DateFormatter().string(from: $0) }
        )
        try await supabase.database
            .from("plans")
            .update(payload)
            .eq("id", value: id)
            .execute()
    }

    func getGoals(planId: String) async throws -> [PlanGoal] {
        let response: [PlanGoal] = try await supabase.database
            .from("plan_goals")
            .select()
            .eq("plan_id", value: planId)
            .execute()
            .value
        return response
    }

    func addGoal(planId: String, areaKey: String, goalText: String, createdByStaffId: String?) async throws -> PlanGoal {
        struct GoalInsert: Encodable {
            let plan_id: String
            let area_key: String
            let goal_text: String
            let created_by_staff_id: String?
        }
        let row = GoalInsert(
            plan_id: planId,
            area_key: areaKey,
            goal_text: goalText,
            created_by_staff_id: createdByStaffId
        )
        let response: PlanGoal = try await supabase.database
            .from("plan_goals")
            .insert(row)
            .select()
            .single()
            .execute()
            .value
        return response
    }

    func getActions(planId: String) async throws -> [PlanAction] {
        let response: [PlanAction] = try await supabase.database
            .from("plan_actions")
            .select()
            .eq("plan_id", value: planId)
            .execute()
            .value
        return response
    }

    func addAction(planId: String, areaKey: String, title: String, who: String, frequency: String?, lockedSession: Bool?, notes: String?) async throws -> PlanAction {
        struct ActionInsert: Encodable {
            let plan_id: String
            let area_key: String
            let title: String
            let who: String
            let frequency: String?
            let locked_session: Bool?
            let notes: String?
        }
        let row = ActionInsert(
            plan_id: planId,
            area_key: areaKey,
            title: title,
            who: who,
            frequency: frequency,
            locked_session: lockedSession,
            notes: notes
        )
        let response: PlanAction = try await supabase.database
            .from("plan_actions")
            .insert(row)
            .select()
            .single()
            .execute()
            .value
        return response
    }
}
