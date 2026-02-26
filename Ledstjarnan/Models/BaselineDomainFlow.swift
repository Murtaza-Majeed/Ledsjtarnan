//
//  BaselineDomainFlow.swift
//  Ledstjarnan
//
//  Shared config + helpers for the new baseline domain flow.
//

import Foundation

enum BaselineDomainCategory: String, Codable {
    case salutogenic
    case pathogenic

    func label(lang: String) -> String {
        switch self {
        case .salutogenic:
            return LocalizedString("baseline_category_salutogenic", lang)
        case .pathogenic:
            return LocalizedString("baseline_category_pathogenic", lang)
        }
    }
}

struct BaselineDomain: Identifiable, Hashable {
    let key: String
    let titleKey: String
    let subtitleKey: String
    let icon: String
    let questionCount: Int
    let needsOptionsKeys: [String]
    let category: BaselineDomainCategory

    var id: String { key }
    
    func title(lang: String) -> String {
        LocalizedString(titleKey, lang)
    }
    
    func subtitle(lang: String) -> String {
        LocalizedString(subtitleKey, lang)
    }
    
    func needsOptions(lang: String) -> [String] {
        needsOptionsKeys.map { LocalizedString($0, lang) }
    }
}

enum BaselineDomainFlowConfig {
    static let salutogenicDomains: [BaselineDomain] = [
        BaselineDomain(
            key: "health",
            titleKey: "domain_health_title",
            subtitleKey: "domain_health_subtitle",
            icon: "heart.text.square",
            questionCount: 3,
            needsOptionsKeys: [
                "needs_medical_followup",
                "needs_sleep_recovery",
                "needs_lifestyle_coach",
                "needs_acute_risk"
            ],
            category: .salutogenic
        ),
        BaselineDomain(
            key: "education",
            titleKey: "domain_education_title",
            subtitleKey: "domain_education_subtitle",
            icon: "book.closed.fill",
            questionCount: 3,
            needsOptionsKeys: [
                "needs_study_coach",
                "needs_daily_structure",
                "needs_internship_work",
                "needs_low_motivation"
            ],
            category: .salutogenic
        ),
        BaselineDomain(
            key: "social",
            titleKey: "domain_social_title",
            subtitleKey: "domain_social_subtitle",
            icon: "person.2.fill",
            questionCount: 3,
            needsOptionsKeys: [
                "needs_mentor",
                "needs_conflicts_relationship_risk",
                "needs_dbt_support",
                "needs_interpreter"
            ],
            category: .salutogenic
        ),
        BaselineDomain(
            key: "independence",
            titleKey: "domain_independence_title",
            subtitleKey: "domain_independence_subtitle",
            icon: "house.fill",
            questionCount: 3,
            needsOptionsKeys: [
                "needs_housing_support",
                "needs_structure_daily",
                "needs_budgeting",
                "needs_practical_adl"
            ],
            category: .salutogenic
        ),
        BaselineDomain(
            key: "relationships",
            titleKey: "domain_relationships_title",
            subtitleKey: "domain_relationships_subtitle",
            icon: "link",
            questionCount: 3,
            needsOptionsKeys: [
                "needs_network_map",
                "needs_risk_in_relationships",
                "needs_family_sessions",
                "needs_support_contact"
            ],
            category: .salutogenic
        ),
        BaselineDomain(
            key: "identity",
            titleKey: "domain_identity_title",
            subtitleKey: "domain_identity_subtitle",
            icon: "sparkles",
            questionCount: 3,
            needsOptionsKeys: [
                "needs_soc_support",
                "needs_low_self_image",
                "needs_cultural_spiritual",
                "needs_future_plan"
            ],
            category: .salutogenic
        )
    ]

    static let pathogenicDomains: [BaselineDomain] = [
        BaselineDomain(
            key: "substance",
            titleKey: "domain_substance_title",
            subtitleKey: "domain_substance_subtitle",
            icon: "cross.vial",
            questionCount: 3,
            needsOptionsKeys: [
                "needs_ongoing_use",
                "needs_acra_met",
                "needs_relapse_risk",
                "needs_detox"
            ],
            category: .pathogenic
        ),
        BaselineDomain(
            key: "attachment",
            titleKey: "domain_attachment_title",
            subtitleKey: "domain_attachment_subtitle",
            icon: "figure.2.arms.open",
            questionCount: 3,
            needsOptionsKeys: [
                "needs_violence_risk",
                "needs_family_sessions",
                "needs_low_security",
                "needs_signs_safety"
            ],
            category: .pathogenic
        ),
        BaselineDomain(
            key: "mentalHealth",
            titleKey: "domain_mental_health_title",
            subtitleKey: "domain_mental_health_subtitle",
            icon: "brain.head.profile",
            questionCount: 3,
            needsOptionsKeys: [
                "needs_psychologist",
                "needs_function_affected",
                "needs_medical_followup_psych",
                "needs_ongoing_outpatient"
            ],
            category: .pathogenic
        ),
        BaselineDomain(
            key: "severeMentalHealth",
            titleKey: "domain_severe_mental_health_title",
            subtitleKey: "domain_severe_mental_health_subtitle",
            icon: "exclamationmark.triangle.fill",
            questionCount: 3,
            needsOptionsKeys: [
                "needs_suicide_risk",
                "needs_self_harm",
                "needs_psychiatry",
                "needs_dbt_livlinan"
            ],
            category: .pathogenic
        ),
        BaselineDomain(
            key: "trauma",
            titleKey: "domain_trauma_title",
            subtitleKey: "domain_trauma_subtitle",
            icon: "shield.lefthalf.filled",
            questionCount: 3,
            needsOptionsKeys: [
                "needs_ptsd_symptoms",
                "needs_trauma_therapy",
                "needs_acute_protection",
                "needs_psych_assessment"
            ],
            category: .pathogenic
        )
    ]

    static let allDomains: [BaselineDomain] = salutogenicDomains + pathogenicDomains
}

enum DomainCompletionStatus {
    case notStarted, inProgress, completed

    var localizedLabel: String {
        switch self {
        case .notStarted:
            return LocalizedString("domain_status_not_started", "sv")
        case .inProgress:
            return LocalizedString("domain_status_in_progress", "sv")
        case .completed:
            return LocalizedString("domain_status_completed", "sv")
        }
    }

    var tint: String {
        switch self {
        case .notStarted: return "gray"
        case .inProgress: return "yellow"
        case .completed: return "green"
        }
    }
}

enum DomainAnswerKey {
    static func readiness(_ domainKey: String) -> String { "\(domainKey).readiness" }
    static func notes(_ domainKey: String) -> String { "\(domainKey).notes" }
    static func needs(_ domainKey: String) -> String { "\(domainKey).needs" }
    static func status(_ domainKey: String) -> String { "\(domainKey).__status" }
    static func interviewQuestion(_ domainKey: String, questionKey: String) -> String { "\(domainKey).\(questionKey)" }

    static let specialSuffixes: Set<String> = ["readiness", "notes", "needs", "__status"]

    static func isSpecialKey(_ key: String, forDomain domainKey: String) -> Bool {
        let prefix = "\(domainKey)."
        guard key.hasPrefix(prefix) else { return false }
        let suffix = String(key.dropFirst(prefix.count))
        return specialSuffixes.contains(suffix)
    }
}

enum AssessmentAnswerPayloadBuilder {
    static func payloads(from answers: [String: AnyCodable], assessmentId: String) -> [AssessmentAnswerPayload] {
        answers.compactMap { key, value in
            guard let dot = key.firstIndex(of: ".") else { return nil }
            let domainKey = String(key[..<dot])
            let questionKey = String(key[key.index(after: dot)...])
            return AssessmentAnswerPayload(
                assessment_id: assessmentId,
                domain_key: domainKey,
                question_key: questionKey,
                value: value
            )
        }
    }
}
