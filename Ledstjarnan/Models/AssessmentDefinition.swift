//
//  AssessmentDefinition.swift
//  Ledstjarnan
//
//  Domain definitions and scoring helpers driven by LogicReferenceStore.
//

import Foundation

// MARK: - Answer Key Constants

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

// MARK: - View-Model Types

struct AssessmentDomainDefinition: Identifiable {
    let key: String
    let title: String
    let subtitle: String
    let icon: String
    let questions: [AssessmentQuestion]

    var id: String { key }
}

struct AssessmentDomainScore: Identifiable {
    let id = UUID()
    let domain: AssessmentDomainDefinition
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
    let helpText: String?
    let type: QuestionType

    init(key: String, label: String, helpText: String? = nil, type: QuestionType) {
        self.key = key
        self.label = label
        self.helpText = helpText
        self.type = type
    }

    enum QuestionType {
        case scale(Int, Int)
        case text
        case priority
    }
}

// MARK: - Module Info (bridge for scoring pipeline)

struct DomainModuleInfo {
    let key: String
    let title: String
    let subtitle: String
    let icon: String
    let scoreType: DomainScore.ScoreType
    let usesStandardIMPScores: Bool
}

// MARK: - Factory (builds definitions from LogicReferenceStore)

enum AssessmentDefinition {

    static func salutogenicDomains(from store: LogicReferenceStore) -> [AssessmentDomainDefinition] {
        store.salutogenicDomains.compactMap { domain -> AssessmentDomainDefinition? in
            guard let appKey = store.appKey(forDomainCode: domain.code) else { return nil }
            let questions = buildQuestions(from: store.scoreSlots(forAppKey: appKey))
            return AssessmentDomainDefinition(
                key: appKey,
                title: domain.label,
                subtitle: domain.description ?? "",
                icon: store.icon(forAppKey: appKey),
                questions: questions
            )
        }
    }

    static func salutogenicModuleInfos(from store: LogicReferenceStore) -> [DomainModuleInfo] {
        store.salutogenicDomains.compactMap { domain -> DomainModuleInfo? in
            guard let appKey = store.appKey(forDomainCode: domain.code) else { return nil }
            return DomainModuleInfo(
                key: appKey,
                title: domain.label,
                subtitle: domain.description ?? "",
                icon: store.icon(forAppKey: appKey),
                scoreType: .salutogenic,
                usesStandardIMPScores: true
            )
        }
    }

    static func pathogenicModuleInfos(from store: LogicReferenceStore) -> [DomainModuleInfo] {
        var infos: [DomainModuleInfo] = store.problemDomains.map { pd in
            DomainModuleInfo(
                key: pd.appKey,
                title: pd.title,
                subtitle: pd.subtitle ?? "",
                icon: pd.icon ?? store.icon(forAppKey: pd.appKey),
                scoreType: .pathogenic,
                usesStandardIMPScores: true
            )
        }
        infos.append(DomainModuleInfo(
            key: "trauma",
            title: store.domain(forAppKey: "trauma")?.label ?? "Trauma & säkerhet",
            subtitle: store.domain(forAppKey: "trauma")?.description ?? "STRESS, PTSD, dissociation & skydd",
            icon: store.icon(forAppKey: "trauma"),
            scoreType: .pathogenic,
            usesStandardIMPScores: false
        ))
        return infos
    }

    static func allModuleInfos(from store: LogicReferenceStore) -> [DomainModuleInfo] {
        salutogenicModuleInfos(from: store) + pathogenicModuleInfos(from: store)
    }

    static func moduleInfo(forKey key: String, from store: LogicReferenceStore) -> DomainModuleInfo? {
        allModuleInfos(from: store).first { $0.key == key }
    }

    static func scores(
        from answers: [String: AnyCodable],
        domains: [AssessmentDomainDefinition]
    ) -> [AssessmentDomainScore] {
        domains.map { domain in
            var total = 0
            var count = 0
            domain.questions.forEach { question in
                guard case .scale = question.type else { return }
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

    // MARK: - Private Helpers

    private static func buildQuestions(from slots: [LogicDomainScoreSlot]) -> [AssessmentQuestion] {
        slots.compactMap { question(from: $0) }
    }

    private static func question(from slot: LogicDomainScoreSlot) -> AssessmentQuestion? {
        let helpText = slot.description
        switch slot.slotCode {
        case "I", "CLIENT", "SCORE":
            return AssessmentQuestion(
                key: DomainQuestionKeys.clientScore,
                label: slot.label,
                helpText: helpText,
                type: .scale(slot.scaleMin, slot.scaleMax)
            )
        case "I_STAFF", "STAFF", "SCORE_STAFF":
            return AssessmentQuestion(
                key: DomainQuestionKeys.staffAssessment,
                label: slot.label,
                helpText: helpText,
                type: .scale(slot.scaleMin, slot.scaleMax)
            )
        case "M":
            return AssessmentQuestion(
                key: DomainQuestionKeys.importance,
                label: slot.label,
                helpText: helpText,
                type: .scale(slot.scaleMin, slot.scaleMax)
            )
        case "P":
            return AssessmentQuestion(
                key: DomainQuestionKeys.priority,
                label: slot.label,
                helpText: helpText,
                type: .priority
            )
        default:
            return nil
        }
    }
}
