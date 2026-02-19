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

    var label: String {
        switch self {
        case .salutogenic:
            return "Salutogena kapital"
        case .pathogenic:
            return "Patogena kapital"
        }
    }
}

struct BaselineDomain: Identifiable, Hashable {
    let key: String
    let title: String
    let subtitle: String
    let icon: String
    let questionCount: Int
    let needsOptions: [String]
    let category: BaselineDomainCategory

    var id: String { key }
}

enum BaselineDomainFlowConfig {
    static let salutogenicDomains: [BaselineDomain] = [
        BaselineDomain(
            key: "health",
            title: "Kropp & hälsa",
            subtitle: "Fysisk hälsa, medicin, livsstil, stress & återhämtning",
            icon: "heart.text.square",
            questionCount: 3,
            needsOptions: [
                "Behöver medicinsk uppföljning",
                "Sova/återhämtning",
                "Livsstilscoach",
                "Akut risk"
            ],
            category: .salutogenic
        ),
        BaselineDomain(
            key: "education",
            title: "Utbildning & arbete",
            subtitle: "Skola, praktik, motivation & daglig struktur",
            icon: "book.closed.fill",
            questionCount: 3,
            needsOptions: [
                "Studiecoach",
                "Behöver daglig struktur",
                "Praktik/arbete saknas",
                "Motivation låg"
            ],
            category: .salutogenic
        ),
        BaselineDomain(
            key: "social",
            title: "Social kompetens & arenor",
            subtitle: "Kommunikation, känsloreglering, DBT-färdigheter",
            icon: "person.2.fill",
            questionCount: 3,
            needsOptions: [
                "Behöver mentor",
                "Konflikter/relationsrisk",
                "Behöver DBT-stöd",
                "Behöver tolk"
            ],
            category: .salutogenic
        ),
        BaselineDomain(
            key: "independence",
            title: "Självständighet & vardag",
            subtitle: "Ekonomi, boende, ADL-färdigheter & vardagsstruktur",
            icon: "house.fill",
            questionCount: 3,
            needsOptions: [
                "Boendestöd",
                "Struktur i vardagen",
                "Budgetering",
                "Praktisk ADL-träning"
            ],
            category: .salutogenic
        ),
        BaselineDomain(
            key: "relationships",
            title: "Relationer & nätverk",
            subtitle: "Nätverk, stödpersoner & hantering av ensamhet",
            icon: "link",
            questionCount: 3,
            needsOptions: [
                "Behöver nätverkskarta",
                "Risk i relationer",
                "Behöver familjesamtal",
                "Stödkontakt saknas"
            ],
            category: .salutogenic
        ),
        BaselineDomain(
            key: "identity",
            title: "Identitet & utveckling",
            subtitle: "KASAM, värderingar, kultur/andlighet & framtidstro",
            icon: "sparkles",
            questionCount: 3,
            needsOptions: [
                "Behöver KASAM-stöd",
                "Självbild låg",
                "Behöver kultur/andlig kontakt",
                "Framtidsplan saknas"
            ],
            category: .salutogenic
        )
    ]

    static let pathogenicDomains: [BaselineDomain] = [
        BaselineDomain(
            key: "substance",
            title: "Alkohol & droger",
            subtitle: "ASI Kriterium E – konsumtion, historik, risk",
            icon: "cross.vial",
            questionCount: 3,
            needsOptions: [
                "Pågående bruk",
                "Behöver A-CRA/MET",
                "Risk för återfall",
                "Behöver avgiftning"
            ],
            category: .pathogenic
        ),
        BaselineDomain(
            key: "attachment",
            title: "Familj & anknytning",
            subtitle: "Relationer, konflikter, våldsutsatthet",
            icon: "figure.2.arms.open",
            questionCount: 3,
            needsOptions: [
                "Våld/risk i nätverk",
                "Behöver familjesamtal",
                "Låg trygghet",
                "Behöver Signs of Safety"
            ],
            category: .pathogenic
        ),
        BaselineDomain(
            key: "mentalHealth",
            title: "Psykisk hälsa",
            subtitle: "Diagnoser, symtom, funktionsnivå",
            icon: "brain.head.profile",
            questionCount: 3,
            needsOptions: [
                "Behöver psykolog",
                "Funktion påverkas",
                "Medicinsk uppföljning",
                "Pågående öppenvård"
            ],
            category: .pathogenic
        ),
        BaselineDomain(
            key: "severeMentalHealth",
            title: "Allvarlig psykisk ohälsa",
            subtitle: "Suicid, självskada, akuta risker",
            icon: "exclamationmark.triangle.fill",
            questionCount: 3,
            needsOptions: [
                "Suicidrisk",
                "Självskada",
                "Behöver psykiatri",
                "DBT/Livlinan"
            ],
            category: .pathogenic
        ),
        BaselineDomain(
            key: "trauma",
            title: "Trauma & säkerhet",
            subtitle: "STRESS, PTSD, dissociation & skydd",
            icon: "shield.lefthalf.filled",
            questionCount: 3,
            needsOptions: [
                "PTSD-symtom",
                "Behöver traumaterapi",
                "Akut skyddsbehov",
                "Psykologutredning"
            ],
            category: .pathogenic
        )
    ]

    static let allDomains: [BaselineDomain] = salutogenicDomains + pathogenicDomains
}

enum DomainCompletionStatus {
    case notStarted, inProgress, completed

    var label: String {
        switch self {
        case .notStarted: return "Not started"
        case .inProgress: return "In progress"
        case .completed: return "Completed"
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
