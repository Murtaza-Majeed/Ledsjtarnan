//
//  ScoringEngine.swift
//  Ledstjarnan
//
//  Digital scoring logic + Insatskarta recommendations.
//

import Foundation

// MARK: - Score Types

struct DomainScore {
    let domainKey: String
    var iScore: Int        // Insatsbehov (need) 1-5
    var iScoreStaff: Int   // Staff rating 1-5
    var mScore: Int        // Mottaglighet (receptivity) 1-5
    var pScore: Int        // Prioritering (priority) 1-5
    var notes: String
    var scoreType: ScoreType

    enum ScoreType {
        case salutogenic   // INVERTED: 5=excellent, 1=urgent
        case pathogenic    // NORMAL: 1=no problem, 5=severe
    }

    // Normalised need level (0.0 = no need, 1.0 = urgent)
    var normalisedNeed: Double {
        switch scoreType {
        case .salutogenic:
            return Double(6 - iScore) / 5.0   // invert
        case .pathogenic:
            return Double(iScore - 1) / 4.0
        }
    }

    var needLevel: NeedLevel {
        let n = normalisedNeed
        switch n {
        case 0..<0.25: return .low
        case 0.25..<0.5: return .mediumLow
        case 0.5..<0.75: return .mediumHigh
        default: return .high
        }
    }
}

enum NeedLevel: String, CaseIterable {
    case low = "Inget/lågt behov"
    case mediumLow = "Medel mot lågt behov"
    case mediumHigh = "Medel mot högt behov"
    case high = "Högt behov"

    var color: String {
        switch self {
        case .low: return "green"
        case .mediumLow: return "yellow"
        case .mediumHigh: return "orange"
        case .high: return "red"
        }
    }
}

// MARK: - Intervention Types

enum Intervention: String, CaseIterable, Identifiable {
    case miljoterapeutiskVardag = "Miljöterapeutisk vardag"
    case livbojenOvergripande = "Livbojen övergripande"
    case livbojenRiktad = "Livbojen riktad"
    case livbojen2 = "Livbojen 2"
    case livlinan = "Livlinan"
    case psykolog = "Psykolog"
    case psykiater = "Psykiater"
    case arbetsterapeut = "Arbetsterapeut"
    case aCRA = "A-CRA / CRA"
    case met = "MET"
    case aterfall = "Återfallsprevention"
    case dbt = "DBT Färdighetsträning"
    case signsOfSafety = "Signs of Safety"

    var id: String { rawValue }

    var isSpecialist: Bool {
        [.psykolog, .psykiater, .aCRA, .livlinan, .dbt].contains(self)
    }
}

struct InterventionRecommendation: Identifiable {
    let id = UUID()
    let domainKey: String
    let domainTitle: String
    let needLevel: NeedLevel
    let interventions: [Intervention]
    let isUrgent: Bool
    var notes: String
}

// MARK: - Safety Flags

struct SafetyFlag: Identifiable {
    let id = UUID()
    let type: FlagType
    let message: String
    let requiresImmediateAction: Bool

    enum FlagType: String, CaseIterable {
        case suicidalIdeation
        case suicideAttempt
        case ptsdSymptoms
        case probableFullPTSD
        case partialPTSD
        case dissociation
        case highProblemScore
        case specialistRequired
    }
}

// MARK: - PTSD Criteria

struct PTSDEvaluation {
    var criterionBMet: Bool = false   // Intrusion: ≥1 item scores ≥2
    var criterionCMet: Bool = false   // Avoidance: ≥1 item scores ≥2
    var criterionDMet: Bool = false   // Cognition/Mood: ≥2 items score ≥2
    var criterionEMet: Bool = false   // Arousal: ≥2 items score ≥2
    var functionalImpairment: Bool = false
    var dissociation: Bool = false
    var totalSymptomScore: Int = 0
    var traumaticEventsAdult: Bool = false
    var traumaticEventsChild: Bool = false

    var probablePTSD: Bool {
        criterionBMet && criterionCMet && criterionDMet && criterionEMet
    }

    var partialPTSD: Bool {
        !probablePTSD && [criterionBMet, criterionCMet, criterionDMet, criterionEMet].filter { $0 }.count >= 1
    }

    var requiresPsychologist: Bool { totalSymptomScore > 1 }
}

// MARK: - Scoring Engine

final class ScoringEngine {

    // MARK: Insatskarta Logic

    static func interventions(for score: DomainScore) -> [Intervention] {
        var result: [Intervention] = [.miljoterapeutiskVardag]
        let n = score.normalisedNeed

        switch score.domainKey {
        // Salutogenic domains
        case "health", "education", "social", "independence", "relationships", "identity":
            if n < 0.25 {
                result.append(.livbojenOvergripande)
            } else if n < 0.5 {
                result.append(.livbojenRiktad)
            } else if n < 0.75 {
                result += [.livbojenRiktad, .livbojen2, .psykolog, .arbetsterapeut]
            } else {
                result += [.livbojenRiktad, .livbojen2, .livlinan, .psykolog, .psykiater, .arbetsterapeut]
            }
        // Substance use
        case "substance":
            if n >= 0.5 {
                result += [.aCRA, .met, .aterfall]
            }
            if n >= 0.75 {
                result += [.dbt]
            }
        // Mental health
        case "mentalHealth", "severeMentalHealth":
            if n >= 0.5 {
                result += [.psykolog]
            }
            if n >= 0.75 {
                result += [.psykolog, .psykiater]
            }
        // Attachment
        case "attachment":
            if n >= 0.5 {
                result += [.livbojen2, .signsOfSafety, .psykolog]
            }
            if n >= 0.75 {
                result += [.livlinan, .psykolog]
            }
        // Trauma
        case "trauma":
            result += [.psykolog]
            if n >= 0.5 {
                result.append(.livlinan)
            }
            if n >= 0.75 {
                result.append(.psykiater)
            }
        default:
            break
        }
        return Array(Set(result)).sorted { $0.rawValue < $1.rawValue }
    }

    // MARK: Safety Flag Evaluation

    static func evaluateSafetyFlags(
        answers: [String: AnyCodable],
        ptsd: PTSDEvaluation,
        problemScores: [DomainScore]
    ) -> [SafetyFlag] {
        var flags: [SafetyFlag] = []

        // Suicidal ideation - hard block
        if answers["severeMentalHealth.suicidalThoughts"]?.value as? Bool == true {
            flags.append(SafetyFlag(
                type: .suicidalIdeation,
                message: "Klienten har rapporterat allvarliga självmordstankar. Psykolog MÅSTE kontaktas omedelbart.",
                requiresImmediateAction: true
            ))
        }

        // Suicide attempt - hard block
        if answers["severeMentalHealth.suicideAttempt"]?.value as? Bool == true {
            flags.append(SafetyFlag(
                type: .suicideAttempt,
                message: "Klienten har rapporterat självmordsförsök. Psykolog MÅSTE kontaktas omedelbart.",
                requiresImmediateAction: true
            ))
        }

        // PTSD flags
        if ptsd.requiresPsychologist {
            flags.append(SafetyFlag(
                type: .ptsdSymptoms,
                message: "PTSD-symtom identifierade (totalpoäng: \(ptsd.totalSymptomScore)). Psykolog ska kontaktas för vidare bedömning.",
                requiresImmediateAction: false
            ))
        }
        if ptsd.probablePTSD {
            flags.append(SafetyFlag(
                type: .probableFullPTSD,
                message: "Sannolik PTSD: Alla kriterier B, C, D och E uppfyllda. Kräver specialist.",
                requiresImmediateAction: true
            ))
        }
        if ptsd.dissociation {
            flags.append(SafetyFlag(
                type: .dissociation,
                message: "Dissociativa symtom identifierade. Psykolog bör konsulteras.",
                requiresImmediateAction: false
            ))
        }

        // High problem scores
        for score in problemScores where score.scoreType == .pathogenic {
            if score.iScore >= 3 {
                flags.append(SafetyFlag(
                    type: .specialistRequired,
                    message: "\(score.domainKey): Poäng \(score.iScore)/5 — specialistkonsultation rekommenderas.",
                    requiresImmediateAction: score.iScore >= 5
                ))
            }
        }

        return flags.sorted { $0.requiresImmediateAction && !$1.requiresImmediateAction }
    }

    // MARK: PTSD Score Calculation

    static func evaluatePTSD(answers: [String: AnyCodable]) -> PTSDEvaluation {
        var eval = PTSDEvaluation()

        // Trauma events
        eval.traumaticEventsAdult = answers["trauma.adultEventsMultiple"]?.value as? Bool ?? false
        eval.traumaticEventsChild = answers["trauma.childEventsMultiple"]?.value as? Bool ?? false

        // Symptom scoring: Aldrig=0, 1gång=1, 2-3gånger=2, De flesta dagarna=3
        func score(_ key: String) -> Int {
            answers["trauma.\(key)"]?.value as? Int ?? 0
        }

        let totalScore = (22...46).reduce(0) { acc, n in
            acc + score("q\(n)")
        }
        eval.totalSymptomScore = totalScore

        // Criterion B — Intrusion: ≥1 item scores ≥2
        let bItems = [score("q22"), score("q23"), score("q27"),
                      max(score("q33"), score("q34")), score("q39")]
        eval.criterionBMet = bItems.contains { $0 >= 2 }

        // Criterion C — Avoidance: ≥1 item scores ≥2
        eval.criterionCMet = [score("q28"), score("q40")].contains { $0 >= 2 }

        // Criterion D — Cognition/Mood: ≥2 items score ≥2
        let dItems = [score("q24"), score("q25"),
                      max(score("q29"), score("q30")),
                      score("q31"),
                      max(score("q35"), score("q36")),
                      score("q41"), score("q44")]
        eval.criterionDMet = dItems.filter { $0 >= 2 }.count >= 2

        // Criterion E — Arousal: ≥2 items score ≥2
        let eItems = [score("q26"), score("q32"), score("q37"),
                      score("q38"), score("q42"), score("q43")]
        eval.criterionEMet = eItems.filter { $0 >= 2 }.count >= 2

        // Functional impairment: ≥1 YES on q47-52
        eval.functionalImpairment = (47...52).contains { answers["trauma.q\($0)"]?.value as? Bool == true }

        // Dissociation: DS1 or DS2 ≥ 2
        eval.dissociation = score("q45") >= 2 || score("q46") >= 2

        return eval
    }

    // MARK: Full Assessment Recommendation

    static func buildRecommendations(
        domainScores: [DomainScore],
        ptsd: PTSDEvaluation,
        store: LogicReferenceStore? = nil
    ) -> [InterventionRecommendation] {
        let recs = domainScores.map { score in
            InterventionRecommendation(
                domainKey: score.domainKey,
                domainTitle: domainTitle(for: score.domainKey, store: store),
                needLevel: score.needLevel,
                interventions: interventions(for: score),
                isUrgent: score.needLevel == .high,
                notes: score.notes
            )
        }

        return recs.sorted { $0.isUrgent && !$1.isUrgent }
    }

    static func domainTitle(for key: String, store: LogicReferenceStore? = nil) -> String {
        if let store, let info = AssessmentDefinition.moduleInfo(forKey: key, from: store) {
            return info.title
        }
        return key.capitalized
    }
}
