//
//  Assessment.swift
//  Ledstjarnan
//
//  Assessment and domain models
//

import Foundation

enum AssessmentType: String, Codable {
    case baseline
    case followup
}

enum AssessmentStatus: String, Codable {
    case draft
    case inProgress = "in_progress"
    case completed
}

struct Assessment: Identifiable, Codable {
    let id: String
    let clientId: String
    let unitId: String
    let assessmentType: AssessmentType
    let createdByStaffId: String?
    var status: AssessmentStatus
    var completedAt: Date?
    var assessmentDate: Date?
    var domainScores: [String: DomainScore]?
    var notes: String?
    let createdAt: Date
    let updatedAt: Date
    
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
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct DomainScore: Codable {
    let domainKey: String
    var readinessScore: Int // 1-5
    var notes: String?
    var needs: [String]?
    var completedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case domainKey = "domain_key"
        case readinessScore = "readiness_score"
        case notes
        case needs
        case completedAt = "completed_at"
    }
}

// Domain definitions
enum AssessmentDomain: String, CaseIterable {
    case housing = "housing"
    case health = "health"
    case education = "education"
    case economy = "economy"
    case social = "social"
    case selfCare = "self_care"
    
    var displayName: String {
        switch self {
        case .housing: return "Boende"
        case .health: return "Kropp & hälsa"
        case .education: return "Utbildning & arbete"
        case .economy: return "Ekonomi"
        case .social: return "Social kompetens"
        case .selfCare: return "Självständighet"
        }
    }
    
    var icon: String {
        switch self {
        case .housing: return "house.fill"
        case .health: return "heart.fill"
        case .education: return "book.fill"
        case .economy: return "creditcard.fill"
        case .social: return "person.2.fill"
        case .selfCare: return "star.fill"
        }
    }
    
    var color: (primary: String, card: String, bg: String) {
        switch self {
        case .housing:
            return ("00839c", "c5dee6", "dfedf1")
        case .health:
            return ("00839c", "c5dee6", "dfedf1")
        case .education:
            return ("61b7ce", "deedf4", "edf5f9")
        case .economy:
            return ("bccf00", "f1dded", "f7f8e6")
        case .social:
            return ("702673", "d7c6db", "ede6f0")
        case .selfCare:
            return ("cc69a6", "f1dded", "f7ecf6")
        }
    }
}

struct AssessmentAnswer: Identifiable, Codable {
    let id: String
    let assessmentId: String
    let domainKey: String
    let questionKey: String
    var value: AnyCodable // Flexible value type
    let createdAt: Date
    let updatedAt: Date
    
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

// Helper for flexible JSON encoding
struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else if let arrayValue = try? container.decode([String].self) {
            value = arrayValue
        } else {
            value = ""
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        if let intValue = value as? Int {
            try container.encode(intValue)
        } else if let doubleValue = value as? Double {
            try container.encode(doubleValue)
        } else if let stringValue = value as? String {
            try container.encode(stringValue)
        } else if let boolValue = value as? Bool {
            try container.encode(boolValue)
        } else if let arrayValue = value as? [String] {
            try container.encode(arrayValue)
        }
    }
}
