//
//  LedstjarnanLogic.swift
//  Ledstjarnan
//
//  Codable structs mirroring the reference tables that power
//  Ledstjarnan's treatment logic.
//

import Foundation

struct TreatmentLevel: Identifiable, Codable {
    let id: UUID
    let code: String
    let name: String
    let description: String?
    let requiresBaseline: Bool
    let autoAssignmentLogic: [String: AnyCodable]?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case code
        case name
        case description
        case requiresBaseline = "requires_baseline"
        case autoAssignmentLogic = "auto_assignment_logic"
        case createdAt = "created_at"
    }
}

struct ScoringDimension: Identifiable, Codable {
    let id: UUID
    let code: String
    let description: String?
    let scaleDirection: ScaleDirection
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case code
        case description
        case scaleDirection = "scale_direction"
        case createdAt = "created_at"
    }

    enum ScaleDirection: String, Codable {
        case normal = "NORMAL"
        case inverted = "INVERTED"
    }
}

struct AssessmentDomain: Identifiable, Codable {
    let id: UUID
    let dimensionId: UUID
    let code: String
    let label: String
    let description: String?
    let lifeAreaOrder: Int?
    let questionSetRef: String?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case dimensionId = "dimension_id"
        case code
        case label
        case description
        case lifeAreaOrder = "life_area_order"
        case questionSetRef = "question_set_ref"
        case createdAt = "created_at"
    }
}

struct DomainScoreSlot: Identifiable, Codable {
    let id: UUID
    let domainId: UUID
    let slotCode: String
    let label: String
    let description: String?
    let actor: SlotActor
    let scaleMin: Int
    let scaleMax: Int

    enum CodingKeys: String, CodingKey {
        case id
        case domainId = "domain_id"
        case slotCode = "slot_code"
        case label
        case description
        case actor
        case scaleMin = "scale_min"
        case scaleMax = "scale_max"
    }

    enum SlotActor: String, Codable {
        case client = "CLIENT"
        case staff = "STAFF"
        case system = "SYSTEM"
    }
}

struct AssessmentStep: Identifiable, Codable {
    let id: Int
    let stepNumber: Int
    let title: String
    let description: String

    enum CodingKeys: String, CodingKey {
        case id
        case stepNumber = "step_number"
        case title
        case description
    }
}

struct TraumaRule: Identifiable, Codable {
    let id: Int
    let ruleCode: String
    let description: String
    let logic: [String: AnyCodable]

    enum CodingKeys: String, CodingKey {
        case id
        case ruleCode = "rule_code"
        case description
        case logic
    }
}

struct GuidebookEntry: Identifiable, Codable {
    let id: UUID
    let slug: String
    let category: String?
    let contentMarkdown: String
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case slug
        case category
        case contentMarkdown = "content_md"
        case createdAt = "created_at"
    }
}

struct TraumaQuestion: Identifiable, Codable {
    let id: Int
    let code: String
    let questionNumber: Int?
    let label: String
    let questionType: QuestionType
    let groupCode: String
    let scaleMin: Int?
    let scaleMax: Int?
    let helpText: String?

    enum CodingKeys: String, CodingKey {
        case id
        case code
        case questionNumber = "question_number"
        case label
        case questionType = "question_type"
        case groupCode = "group_code"
        case scaleMin = "scale_min"
        case scaleMax = "scale_max"
        case helpText = "help_text"
    }

    enum QuestionType: String, Codable {
        case boolean = "BOOLEAN"
        case scale = "SCALE"
        case text = "TEXT"
    }
}

struct DomainInterviewSection: Identifiable, Codable {
    let id: UUID
    let domainId: UUID
    let sectionCode: String?
    let title: String
    let description: String?
    let displayOrder: Int
    var questions: [DomainInterviewQuestion]? = []

    enum CodingKeys: String, CodingKey {
        case id
        case domainId = "domain_id"
        case sectionCode = "section_code"
        case title
        case description
        case displayOrder = "display_order"
        case questions = "domain_interview_questions"
    }
}

struct DomainInterviewQuestion: Identifiable, Codable {
    let id: UUID
    let sectionId: UUID
    let questionKey: String
    let label: String
    let questionType: QuestionType
    let options: [String]?
    let scaleMin: Int?
    let scaleMax: Int?
    let helpText: String?
    let displayOrder: Int

    enum CodingKeys: String, CodingKey {
        case id
        case sectionId = "section_id"
        case questionKey = "question_key"
        case label
        case questionType = "question_type"
        case options
        case scaleMin = "scale_min"
        case scaleMax = "scale_max"
        case helpText = "help_text"
        case displayOrder = "display_order"
    }

    enum QuestionType: String, Codable {
        case yesNo = "YES_NO"
        case yesNoSpecify = "YES_NO_SPECIFY"
        case text = "TEXT"
        case multipleChoice = "MULTIPLE_CHOICE"
        case multiSelect = "MULTI_SELECT"
        case scale = "SCALE"
    }
}

struct ProblemDomainDefinition: Identifiable, Codable {
    let id: UUID
    let code: String
    let appKey: String
    let title: String
    let subtitle: String?
    let icon: String?
    let scoreType: ProblemScoreType
    let scoringQuestion: String
    var sections: [ProblemDomainSectionDefinition]? = []

    enum CodingKeys: String, CodingKey {
        case id
        case code
        case appKey = "app_key"
        case title
        case subtitle
        case icon
        case scoreType = "score_type"
        case scoringQuestion = "scoring_question"
        case sections = "problem_domain_sections"
    }

    enum ProblemScoreType: String, Codable {
        case salutogenic = "SALUTOGENIC"
        case pathogenic = "PATHOGENIC"
    }
}

struct ProblemDomainSectionDefinition: Identifiable, Codable {
    let id: UUID
    let domainId: UUID
    let sectionCode: String?
    let title: String
    let description: String?
    let displayOrder: Int
    let isScoringSection: Bool
    var questions: [ProblemDomainQuestionDefinition]? = []

    enum CodingKeys: String, CodingKey {
        case id
        case domainId = "domain_id"
        case sectionCode = "section_code"
        case title
        case description
        case displayOrder = "display_order"
        case isScoringSection = "is_scoring_section"
        case questions = "problem_domain_questions"
    }
}

struct ProblemDomainQuestionDefinition: Identifiable, Codable {
    let id: UUID
    let sectionId: UUID
    let questionKey: String
    let label: String
    let questionType: QuestionType
    let options: [String]?
    let scaleMin: Int?
    let scaleMax: Int?
    let helpText: String?
    let isSafetyQuestion: Bool
    let safetyTriggerValue: AnyCodable?
    let displayOrder: Int

    enum CodingKeys: String, CodingKey {
        case id
        case sectionId = "section_id"
        case questionKey = "question_key"
        case label
        case questionType = "question_type"
        case options
        case scaleMin = "scale_min"
        case scaleMax = "scale_max"
        case helpText = "help_text"
        case isSafetyQuestion = "is_safety_question"
        case safetyTriggerValue = "safety_trigger_value"
        case displayOrder = "display_order"
    }

    enum QuestionType: String, Codable {
        case yesNo = "YES_NO"
        case yesNoSpecify = "YES_NO_SPECIFY"
        case text = "TEXT"
        case multipleChoice = "MULTIPLE_CHOICE"
        case multiSelect = "MULTI_SELECT"
        case scale = "SCALE"
        case mScore = "M_SCORE"
        case pScore = "P_SCORE"
    }
}
