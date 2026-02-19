//
//  AssessmentDefinition.swift
//  Ledstjarnan
//
//  In-app definition of assessment domains and questions (minimal set for MVP).
//

import Foundation

enum AssessmentModuleCategory: String {
    case salutogenic
    case pathogenic
}

struct AssessmentModule {
    let key: String
    let title: String
    let subtitle: String
    let icon: String
    let category: AssessmentModuleCategory
    let scoreType: DomainScore.ScoreType
    let clientPrompt: String
    let importancePrompt: String
    let staffPrompt: String
    let notesLabel: String
    let usesStandardIMPScores: Bool

    init(
        key: String,
        title: String,
        subtitle: String,
        icon: String,
        category: AssessmentModuleCategory,
        scoreType: DomainScore.ScoreType,
        clientPrompt: String,
        importancePrompt: String,
        staffPrompt: String,
        notesLabel: String,
        usesStandardIMPScores: Bool = true
    ) {
        self.key = key
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.category = category
        self.scoreType = scoreType
        self.clientPrompt = clientPrompt
        self.importancePrompt = importancePrompt
        self.staffPrompt = staffPrompt
        self.notesLabel = notesLabel
        self.usesStandardIMPScores = usesStandardIMPScores
    }

    fileprivate func asAssessmentDomain() -> AssessmentDomain {
        AssessmentDomain(
            key: key,
            title: title,
            subtitle: subtitle,
            icon: icon,
            questions: [
                AssessmentQuestion(
                    key: DomainQuestionKeys.clientScore,
                    label: clientPrompt,
                    type: .scale(1, 5)
                ),
                AssessmentQuestion(
                    key: DomainQuestionKeys.importance,
                    label: importancePrompt,
                    type: .scale(1, 5)
                ),
                AssessmentQuestion(
                    key: DomainQuestionKeys.staffAssessment,
                    label: staffPrompt,
                    type: .scale(1, 5)
                ),
                AssessmentQuestion(
                    key: DomainQuestionKeys.notes,
                    label: notesLabel,
                    type: .text
                )
            ]
        )
    }
}

enum DomainQuestionKeys {
    static let clientScore = "clientScore"
    static let importance = "importanceOfHelp"
    static let staffAssessment = "staffNeedScore"
    static let notes = "notes"
    static let priority = "priorityScore"
}

enum ProblemQuestionKeys {
    static let clientScore = "clientConcernScore"
    static let importance = "importanceOfHelp"
    static let staffAssessment = "staffNeedScore"
    static let notes = "notes"
    static let priority = "priorityScore"
}

struct AssessmentDefinition {
    static let domains: [AssessmentDomain] = salutogenicModules.map { $0.asAssessmentDomain() }
    
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

    static let salutogenicModules: [AssessmentModule] = [
        AssessmentModule(
            key: "health",
            title: "Kropp & hälsa",
            subtitle: "Fysisk hälsa, medicin, livsstil, stress & återhämtning",
            icon: "heart.text.square",
            category: .salutogenic,
            scoreType: .salutogenic,
            clientPrompt: "Hur nöjd har du varit med kropp och hälsa de senaste 30 dagarna?",
            importancePrompt: "Hur viktigt är det för dig att få hjälp med kropp och hälsa just nu?",
            staffPrompt: "Hur stort bedömer behandlaren behovet av insatser inom kropp och hälsa?",
            notesLabel: "Anteckningar (hälsa)"
        ),
        AssessmentModule(
            key: "education",
            title: "Utbildning & arbete",
            subtitle: "Utbildning, arbete, ekonomi & dagstruktur",
            icon: "book.closed",
            category: .salutogenic,
            scoreType: .salutogenic,
            clientPrompt: "Hur nöjd har du varit med din livssituation och ekonomi de senaste 30 dagarna?",
            importancePrompt: "Hur viktigt är det för dig att få hjälp med utbildning, arbete eller ekonomi?",
            staffPrompt: "Hur stort bedömer behandlaren behovet av insatser inom utbildning och arbete?",
            notesLabel: "Anteckningar (utbildning & arbete)"
        ),
        AssessmentModule(
            key: "social",
            title: "Social kompetens",
            subtitle: "Kommunikation, känsloreglering, DBT-färdigheter & sociala arenor",
            icon: "person.2.fill",
            category: .salutogenic,
            scoreType: .salutogenic,
            clientPrompt: "Hur nöjd har du varit med kommunikation och känslohantering de senaste 30 dagarna?",
            importancePrompt: "Hur viktigt är det för dig att få hjälp med social kompetens och relationer?",
            staffPrompt: "Hur stort bedömer behandlaren behovet av insatser inom social kompetens?",
            notesLabel: "Anteckningar (social kompetens)"
        ),
        AssessmentModule(
            key: "independence",
            title: "Självständighet & vardag",
            subtitle: "Ekonomi, boende, ADL-färdigheter & vardagsstruktur",
            icon: "house",
            category: .salutogenic,
            scoreType: .salutogenic,
            clientPrompt: "Hur nöjd har du varit med boende, vardag och trygghet de senaste 30 dagarna?",
            importancePrompt: "Hur viktigt är det för dig att få stöd med självständighet och vardag?",
            staffPrompt: "Hur stort bedömer behandlaren behovet av insatser inom självständighet och vardag?",
            notesLabel: "Anteckningar (självständighet)"
        ),
        AssessmentModule(
            key: "relationships",
            title: "Relationer & nätverk",
            subtitle: "Relationer, nätverk, stödpersoner & hantering av ensamhet",
            icon: "person.3.fill",
            category: .salutogenic,
            scoreType: .salutogenic,
            clientPrompt: "Hur nöjd har du varit med relationer och nätverk de senaste 30 dagarna?",
            importancePrompt: "Hur viktigt är det för dig att få hjälp med relationer, nätverk eller ensamhet?",
            staffPrompt: "Hur stort bedömer behandlaren behovet av insatser inom relationer och nätverk?",
            notesLabel: "Anteckningar (relationer & nätverk)"
        ),
        AssessmentModule(
            key: "identity",
            title: "Identitet & utveckling",
            subtitle: "KASAM, värderingar, kultur/andlighet & framtidstro",
            icon: "sparkles",
            category: .salutogenic,
            scoreType: .salutogenic,
            clientPrompt: "Hur nöjd har du varit med identitet, mening och framtidstro de senaste 30 dagarna?",
            importancePrompt: "Hur viktigt är det för dig att få stöd inom identitet, mening eller framtidsplaner?",
            staffPrompt: "Hur stort bedömer behandlaren behovet av insatser inom identitet och utveckling?",
            notesLabel: "Anteckningar (identitet & utveckling)"
        )
    ]

    static let pathogenicModules: [AssessmentModule] = [
        AssessmentModule(
            key: "substance",
            title: "Alkohol & droger",
            subtitle: "ASI kriterium E – konsumtion, historik, risk",
            icon: "cross.vial",
            category: .pathogenic,
            scoreType: .pathogenic,
            clientPrompt: "Hur oroad eller besvärad har du varit över alkohol/drogkonsumtion de senaste 30 dagarna?",
            importancePrompt: "Hur viktigt är det för dig att få hjälp med alkohol och droger just nu?",
            staffPrompt: "Hur stort bedömer behandlaren behovet av insatser för alkohol och droger?",
            notesLabel: "Anteckningar (alkohol & droger)"
        ),
        AssessmentModule(
            key: "attachment",
            title: "Anknytning & relationer",
            subtitle: "Nätverk, våldsutsatthet, familjekonflikter",
            icon: "figure.2.arms.open",
            category: .pathogenic,
            scoreType: .pathogenic,
            clientPrompt: "Hur oroad eller besvärad har du varit över familj och umgänge de senaste 30 dagarna?",
            importancePrompt: "Hur viktigt är det för dig att få hjälp med anknytning och relationer?",
            staffPrompt: "Hur stort bedömer behandlaren behovet av insatser för anknytning och relationer?",
            notesLabel: "Anteckningar (anknytning & relationer)"
        ),
        AssessmentModule(
            key: "mentalHealth",
            title: "Psykisk ohälsa",
            subtitle: "Diagnoser, symtom, funktionsnivå",
            icon: "brain.head.profile",
            category: .pathogenic,
            scoreType: .pathogenic,
            clientPrompt: "Hur oroad eller besvärad har du varit över din psykiska hälsa de senaste 30 dagarna?",
            importancePrompt: "Hur viktigt är det för dig att få hjälp med psykisk hälsa?",
            staffPrompt: "Hur stort bedömer behandlaren behovet av insatser för psykisk hälsa?",
            notesLabel: "Anteckningar (psykisk hälsa)"
        ),
        AssessmentModule(
            key: "severeMentalHealth",
            title: "Allvarlig psykisk ohälsa",
            subtitle: "Suicid, självskada, akuta risker",
            icon: "exclamationmark.triangle.fill",
            category: .pathogenic,
            scoreType: .pathogenic,
            clientPrompt: "Hur oroad eller besvärad har du varit över allvarliga psykiska symtom de senaste 30 dagarna?",
            importancePrompt: "Hur viktigt är det för dig att få hjälp med allvarliga psykiska symtom?",
            staffPrompt: "Hur stort bedömer behandlaren behovet av insatser för allvarlig psykisk ohälsa?",
            notesLabel: "Anteckningar (allvarlig psykisk ohälsa)"
        ),
        AssessmentModule(
            key: "trauma",
            title: "Trauma & säkerhet",
            subtitle: "STRESS, PTSD, dissociation & skydd",
            icon: "shield.lefthalf.filled",
            category: .pathogenic,
            scoreType: .pathogenic,
            clientPrompt: "Hur påverkad upplever du dig av traumatiska minnen eller symtom just nu?",
            importancePrompt: "Hur viktigt är det för dig att få hjälp med trauma eller trygghet?",
            staffPrompt: "Hur stort bedömer behandlaren behovet av insatser för trauma och säkerhet?",
            notesLabel: "Anteckningar (trauma & säkerhet)",
            usesStandardIMPScores: false
        )
    ]

    static let allModules: [AssessmentModule] = salutogenicModules + pathogenicModules

    static func module(for key: String) -> AssessmentModule? {
        allModules.first { $0.key == key }
    }
}

struct AssessmentDomain {
    let key: String
    let title: String
    let subtitle: String
    let icon: String
    let questions: [AssessmentQuestion]
}

extension AssessmentDomain: Identifiable {
    var id: String { key }
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
        case priority
    }
}
