//
//  Assessment.swift
//  Ledstjarnan
//
//  Matches assessments and assessment_answers tables.
//

import Foundation

struct Assessment: Identifiable, Codable {
    let id: String
    let clientId: String
    let unitId: String
    let assessmentType: String
    let createdByStaffId: String?
    let status: String
    let completedAt: Date?
    let assessmentDate: String?
    let domainScores: [String: AnyCodable]?
    let notes: String?
    let ptsdTotalScore: Int?
    let ptsdProbable: Bool?
    let safetyFlags: [[String: AnyCodable]]?
    let interventionSummary: [String: AnyCodable]?
    let createdAt: Date?
    let updatedAt: Date?

    var isBaseline: Bool { assessmentType == "baseline" }
    var isFollowUp: Bool { assessmentType == "followup" }
    var isCompleted: Bool { status == "completed" }

    enum CodingKeys: String, CodingKey {
        case id
        case clientId = "client_id"
        case unitId = "unit_id"
        case assessmentType = "assessment_type"
        case createdByStaffId = "created_by_staff_id"
        case status
        case completedAt = "completed_at"
        case assessmentDate = "assessment_date"
        case domainScores = "domain_scores"
        case notes
        case ptsdTotalScore = "ptsd_total_score"
        case ptsdProbable = "ptsd_probable"
        case safetyFlags = "safety_flags"
        case interventionSummary = "intervention_summary"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        clientId = try c.decode(String.self, forKey: .clientId)
        unitId = try c.decode(String.self, forKey: .unitId)
        assessmentType = try c.decode(String.self, forKey: .assessmentType)
        createdByStaffId = try c.decodeIfPresent(String.self, forKey: .createdByStaffId)
        status = try c.decodeIfPresent(String.self, forKey: .status) ?? "draft"
        completedAt = try c.decodeIfPresent(Date.self, forKey: .completedAt)
        assessmentDate = try c.decodeIfPresent(String.self, forKey: .assessmentDate)
        notes = try c.decodeIfPresent(String.self, forKey: .notes)
        createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt)
        updatedAt = try c.decodeIfPresent(Date.self, forKey: .updatedAt)
        domainScores = try? c.decodeIfPresent([String: AnyCodable].self, forKey: .domainScores)
        ptsdTotalScore = try c.decodeIfPresent(Int.self, forKey: .ptsdTotalScore)
        ptsdProbable = try c.decodeIfPresent(Bool.self, forKey: .ptsdProbable)
        safetyFlags = try? c.decodeIfPresent([[String: AnyCodable]].self, forKey: .safetyFlags)
        interventionSummary = try? c.decodeIfPresent([String: AnyCodable].self, forKey: .interventionSummary)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(clientId, forKey: .clientId)
        try c.encode(unitId, forKey: .unitId)
        try c.encode(assessmentType, forKey: .assessmentType)
        try c.encodeIfPresent(createdByStaffId, forKey: .createdByStaffId)
        try c.encode(status, forKey: .status)
        try c.encodeIfPresent(completedAt, forKey: .completedAt)
        try c.encodeIfPresent(assessmentDate, forKey: .assessmentDate)
        try c.encodeIfPresent(notes, forKey: .notes)
        try c.encodeIfPresent(createdAt, forKey: .createdAt)
        try c.encodeIfPresent(updatedAt, forKey: .updatedAt)
        try c.encodeIfPresent(domainScores, forKey: .domainScores)
        try c.encodeIfPresent(ptsdTotalScore, forKey: .ptsdTotalScore)
        try c.encodeIfPresent(ptsdProbable, forKey: .ptsdProbable)
        try c.encodeIfPresent(safetyFlags, forKey: .safetyFlags)
        try c.encodeIfPresent(interventionSummary, forKey: .interventionSummary)
    }
}

struct AssessmentAnswer: Codable {
    let id: String?
    let assessmentId: String
    let domainKey: String
    let questionKey: String
    let value: AnyCodable?
    let createdAt: Date?
    let updatedAt: Date?

    init(id: String?, assessmentId: String, domainKey: String, questionKey: String, value: AnyCodable?, createdAt: Date?, updatedAt: Date?) {
        self.id = id
        self.assessmentId = assessmentId
        self.domainKey = domainKey
        self.questionKey = questionKey
        self.value = value
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case assessmentId = "assessment_id"
        case domainKey = "domain_key"
        case questionKey = "question_key"
        case value
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
