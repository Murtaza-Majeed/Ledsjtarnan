//
//  AssessmentService.swift
//  Ledstjarnan
//

import Foundation
import Supabase

struct AssessmentAnswerPayload: Encodable {
    let assessment_id: String
    let domain_key: String
    let question_key: String
    let value: AnyCodable
}

class AssessmentService {
    private let supabase = SupabaseManager.shared.client

    func getAssessments(clientId: String) async throws -> [Assessment] {
        let response: [Assessment] = try await supabase.database
            .from("assessments")
            .select()
            .eq("client_id", value: clientId)
            .order("created_at", ascending: false)
            .execute()
            .value
        return response
    }

    func getRecentAssessments(unitId: String, limit: Int = 12) async throws -> [Assessment] {
        try await supabase.database
            .from("assessments")
            .select()
            .eq("unit_id", value: unitId)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value
    }

    func createAssessment(clientId: String, unitId: String, type: String, createdByStaffId: String?) async throws -> Assessment {
        struct AssessmentInsert: Encodable {
            let client_id: String
            let unit_id: String
            let assessment_type: String
            let created_by_staff_id: String?
            let status: String
        }

        let row = AssessmentInsert(
            client_id: clientId,
            unit_id: unitId,
            assessment_type: type,
            created_by_staff_id: createdByStaffId,
            status: "draft"
        )

        let response: Assessment = try await supabase.database
            .from("assessments")
            .insert(row)
            .select()
            .single()
            .execute()
            .value
        return response
    }

    func updateAssessment(id: String, status: String?, completedAt: Date?, notes: String?) async throws {
        struct AssessmentUpdate: Encodable {
            var status: String?
            var completed_at: String?
            var notes: String?
            var hasValues: Bool {
                status != nil || completed_at != nil || notes != nil
            }

            enum CodingKeys: String, CodingKey {
                case status
                case completed_at
                case notes
            }

            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                if let status = status { try container.encode(status, forKey: .status) }
                if let completed_at = completed_at { try container.encode(completed_at, forKey: .completed_at) }
                if let notes = notes { try container.encode(notes, forKey: .notes) }
            }
        }

        let formatter = ISO8601DateFormatter()
        let payload = AssessmentUpdate(
            status: status,
            completed_at: completedAt.map { formatter.string(from: $0) },
            notes: notes
        )

        guard payload.hasValues else { return }

        try await supabase.database
            .from("assessments")
            .update(payload)
            .eq("id", value: id)
            .execute()
    }

    func getAssessmentAnswers(assessmentId: String) async throws -> [AssessmentAnswer] {
        let response: [AssessmentAnswer] = try await supabase.database
            .from("assessment_answers")
            .select()
            .eq("assessment_id", value: assessmentId)
            .execute()
            .value
        return response
    }

    /// Set one answer (insert or update).
    func setAnswer(assessmentId: String, domainKey: String, questionKey: String, value: AnyCodable) async throws {
        let existing: [AssessmentAnswer] = try await supabase.database
            .from("assessment_answers")
            .select()
            .eq("assessment_id", value: assessmentId)
            .eq("domain_key", value: domainKey)
            .eq("question_key", value: questionKey)
            .execute()
            .value
        if let first = existing.first {
            let id = first.id
            struct ValueUpdate: Encodable {
                let value: AnyCodable
            }
            try await supabase.database
                .from("assessment_answers")
                .update(ValueUpdate(value: value))
                .eq("id", value: id)
                .execute()
        } else {
            try await supabase.database
                .from("assessment_answers")
                .insert(AssessmentAnswerPayload(assessment_id: assessmentId, domain_key: domainKey, question_key: questionKey, value: value))
                .execute()
        }
    }

    /// Bulk upsert answers (used by the assessment form to avoid 100+ sequential calls).
    func upsertAnswers(_ payloads: [AssessmentAnswerPayload]) async throws {
        guard !payloads.isEmpty else { return }
        try await supabase.database
            .from("assessment_answers")
            .upsert(payloads, onConflict: "assessment_id,domain_key,question_key")
            .execute()
    }

    /// Saves computed summary fields to the assessment row for dashboards and follow-up.
    func saveSummaryFields(
        assessmentId: String,
        ptsdScore: Int,
        ptsdProbable: Bool,
        safetyFlags: [SafetyFlag],
        recommendations: [InterventionRecommendation],
        domainScores: [DomainScore]
    ) async throws {
        struct SummaryUpdate: Encodable {
            let ptsd_total_score: Int
            let ptsd_probable: Bool
            let safety_flags: [[String: AnyCodable]]
            let intervention_summary: [String: AnyCodable]
            let domain_scores: [String: AnyCodable]
        }

        let flagsArray = safetyFlags.map { flag in
            [
                "type": AnyCodable(String(describing: flag.type)),
                "message": AnyCodable(flag.message),
                "requiresAction": AnyCodable(flag.requiresImmediateAction)
            ]
        }

        let recsDict = recommendations.reduce(into: [String: AnyCodable]()) { dict, rec in
            let domainDict: [String: AnyCodable] = [
                "needLevel": AnyCodable(rec.needLevel.rawValue),
                "interventions": AnyCodable(rec.interventions.map { $0.rawValue }),
                "isUrgent": AnyCodable(rec.isUrgent),
                "notes": AnyCodable(rec.notes)
            ]
            dict[rec.domainKey] = AnyCodable(domainDict)
        }

        let domainScoresDict = domainScores.reduce(into: [String: AnyCodable]()) { dict, score in
            let payload: [String: AnyCodable] = [
                "iScore": AnyCodable(score.iScore),
                "iScoreStaff": AnyCodable(score.iScoreStaff),
                "mScore": AnyCodable(score.mScore),
                "pScore": AnyCodable(score.pScore),
                "notes": AnyCodable(score.notes),
                "scoreType": AnyCodable(score.scoreType == .salutogenic ? "salutogenic" : "pathogenic")
            ]
            dict[score.domainKey] = AnyCodable(payload)
        }

        let payload = SummaryUpdate(
            ptsd_total_score: ptsdScore,
            ptsd_probable: ptsdProbable,
            safety_flags: flagsArray,
            intervention_summary: recsDict,
            domain_scores: domainScoresDict
        )

        try await supabase.database
            .from("assessments")
            .update(payload)
            .eq("id", value: assessmentId)
            .execute()
    }
}
