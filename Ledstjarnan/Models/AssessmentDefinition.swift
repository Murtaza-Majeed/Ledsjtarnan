//
//  AssessmentDefinition.swift
//  Ledstjarnan
//
//  In-app definition of assessment domains and questions (minimal set for MVP).
//

import Foundation

struct AssessmentDefinition {
    static let domains: [AssessmentDomain] = [
        AssessmentDomain(
            key: "health",
            title: "Kropp & hälsa",
            subtitle: "Sleep, routines, medical needs",
            icon: "heart.text.square",
            questions: [
                AssessmentQuestion(key: "sleep", label: "Sleep quality", type: .scale(1, 5)),
                AssessmentQuestion(key: "nutrition", label: "Eating regularly", type: .scale(1, 5)),
                AssessmentQuestion(key: "medical", label: "Able to follow medical advice", type: .scale(1, 5)),
                AssessmentQuestion(key: "health_notes", label: "Notes", type: .text)
            ]
        ),
        AssessmentDomain(
            key: "education",
            title: "Utbildning & arbete",
            subtitle: "School, work, daytime structure",
            icon: "book.closed",
            questions: [
                AssessmentQuestion(key: "attendance", label: "Attendance/engagement", type: .scale(1, 5)),
                AssessmentQuestion(key: "motivation", label: "Motivation for goals", type: .scale(1, 5)),
                AssessmentQuestion(key: "structure", label: "Daily structure", type: .scale(1, 5)),
                AssessmentQuestion(key: "education_notes", label: "Notes", type: .text)
            ]
        ),
        AssessmentDomain(
            key: "social",
            title: "Social kompetens",
            subtitle: "Relationships & prosocial skills",
            icon: "person.2.fill",
            questions: [
                AssessmentQuestion(key: "communication", label: "Expressing needs", type: .scale(1, 5)),
                AssessmentQuestion(key: "conflict", label: "Managing conflicts", type: .scale(1, 5)),
                AssessmentQuestion(key: "support_network", label: "Supportive network", type: .scale(1, 5)),
                AssessmentQuestion(key: "social_notes", label: "Notes", type: .text)
            ]
        ),
        AssessmentDomain(
            key: "independence",
            title: "Självständighet & vardag",
            subtitle: "Economy, housing & daily living",
            icon: "house",
            questions: [
                AssessmentQuestion(key: "housing", label: "Maintains housing routines", type: .scale(1, 5)),
                AssessmentQuestion(key: "economy", label: "Handles money/budget", type: .scale(1, 5)),
                AssessmentQuestion(key: "selfcare", label: "Self-care & executive skills", type: .scale(1, 5)),
                AssessmentQuestion(key: "independence_notes", label: "Notes", type: .text)
            ]
        ),
        AssessmentDomain(
            key: "relationships",
            title: "Relationer & nätverk",
            subtitle: "Family, friends, safe adults",
            icon: "person.3.fill",
            questions: [
                AssessmentQuestion(key: "family", label: "Family contact quality", type: .scale(1, 5)),
                AssessmentQuestion(key: "trust", label: "Trust in adults/professionals", type: .scale(1, 5)),
                AssessmentQuestion(key: "boundaries", label: "Sets and respects boundaries", type: .scale(1, 5)),
                AssessmentQuestion(key: "relationships_notes", label: "Notes", type: .text)
            ]
        ),
        AssessmentDomain(
            key: "identity",
            title: "Identitet & utveckling",
            subtitle: "Sense of self & coping",
            icon: "sparkles",
            questions: [
                AssessmentQuestion(key: "selfimage", label: "Positive self-image", type: .scale(1, 5)),
                AssessmentQuestion(key: "coping", label: "Coping strategies", type: .scale(1, 5)),
                AssessmentQuestion(key: "vision", label: "Future vision/hope", type: .scale(1, 5)),
                AssessmentQuestion(key: "identity_notes", label: "Notes", type: .text)
            ]
        )
    ]
    
    static func scores(from answers: [String: AnyCodable]) -> [AssessmentDomainScore] {
        domains.map { domain in
            var total = 0
            var count = 0
            domain.questions.forEach { question in
                guard case let .scale(_, _) = question.type else { return }
                let key = "\(domain.key).\(question.key)"
                if let value = answers[key]?.value as? Int {
                    total += value
                    count += 1
                }
            }
            let average = count > 0 ? Double(total) / Double(count) : nil
            return AssessmentDomainScore(domain: domain, average: average, answeredCount: count)
        }
    }
}

struct AssessmentDomain {
    let key: String
    let title: String
    let subtitle: String
    let icon: String
    let questions: [AssessmentQuestion]
}

struct AssessmentDomainScore: Identifiable {
    let id = UUID()
    let domain: AssessmentDomain
    let average: Double?
    let answeredCount: Int
    
    var formattedAverage: String {
        guard let average else { return "—" }
        return String(format: "%.1f", average)
    }
    
    var interpretation: String {
        guard let avg = average else { return "Needs rating" }
        switch avg {
        case ..<2: return "Acute support"
        case 2..<3.5: return "Stöttning behövs"
        case 3.5...5: return "Styrka"
        default: return "Needs rating"
        }
    }
}

struct AssessmentQuestion {
    let key: String
    let label: String
    let type: QuestionType

    enum QuestionType {
        case scale(Int, Int)
        case text
    }
}
