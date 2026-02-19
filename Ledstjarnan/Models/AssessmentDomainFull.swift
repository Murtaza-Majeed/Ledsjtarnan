//
//  AssessmentDomainFull.swift
//  Ledstjarnan
//
//  Extended assessment question types and problem-area domains.
//

import Foundation

// MARK: - Extended Question Types

enum ExtendedQuestionType {
    case scale(Int, Int)           // 1-5 slider/buttons
    case yesNo                     // Yes / No
    case yesNoSpecify              // Yes/No + text field
    case multipleChoice([String])  // Select one
    case multiSelect([String])     // Select multiple
    case text                      // Free text
    case mScore                    // Receptivity 1-5
    case pScore                    // Priority: high/medium/low
}

struct ExtendedQuestion: Identifiable {
    let id = UUID()
    let key: String
    let label: String
    let type: ExtendedQuestionType
    var isSafetyQuestion: Bool = false
    var safetyTriggerValue: Any? = nil  // if answer matches this, trigger safety flag
    var subQuestions: [ExtendedQuestion] = []
}

struct ExtendedDomain: Identifiable {
    let id = UUID()
    let key: String
    let title: String
    let subtitle: String
    let icon: String
    let scoreType: DomainScore.ScoreType
    let sections: [DomainSection]
    let scoringQuestion: String   // The Del 2 scoring question label
}

struct DomainSection: Identifiable {
    let id = UUID()
    let title: String
    let questions: [ExtendedQuestion]
}

// MARK: - Problem Area Definitions

extension AssessmentDefinition {

    static let substanceDomain = ExtendedDomain(
        key: "substance",
        title: "Alkohol & Droganvändning",
        subtitle: "ASI Kriterium E",
        icon: "cross.vial",
        scoreType: .pathogenic,
        sections: [
            DomainSection(title: "Alkohol", questions: [
                ExtendedQuestion(key: "drinksAlcohol", label: "Dricker du alkohol?", type: .yesNo),
                ExtendedQuestion(key: "drinksToIntoxication", label: "Dricker du alkohol till berusning?", type: .yesNo),
                ExtendedQuestion(key: "drinksHeavily3Days", label: "Dricker du till berusning 3 eller fler dagar i veckan?", type: .yesNo),
                ExtendedQuestion(key: "alcoholLast30Days", label: "Har du druckit alkohol de senaste 30 dagarna?", type: .yesNo),
            ]),
            DomainSection(title: "Narkotika – använt mer än en gång", questions: [
                ExtendedQuestion(key: "heroin", label: "Heroin", type: .yesNo),
                ExtendedQuestion(key: "methadone", label: "Metadon", type: .yesNo),
                ExtendedQuestion(key: "buprenorphine", label: "Buprenorfin", type: .yesNo),
                ExtendedQuestion(key: "otherOpioids", label: "Andra opiater / smärtstillande", type: .yesNo),
                ExtendedQuestion(key: "sedatives", label: "Lugnande medel / sömnmedel", type: .yesNo),
                ExtendedQuestion(key: "cocaine", label: "Kokain / Crack", type: .yesNo),
                ExtendedQuestion(key: "amphetamine", label: "Amfetamin / andra stimulantia", type: .yesNo),
                ExtendedQuestion(key: "cannabis", label: "Cannabis", type: .yesNo),
                ExtendedQuestion(key: "hallucinogens", label: "Hallucinogener", type: .yesNo),
                ExtendedQuestion(key: "ecstasy", label: "Ecstasy", type: .yesNo),
                ExtendedQuestion(key: "solvents", label: "Lösningsmedel", type: .yesNo),
                ExtendedQuestion(key: "multipleSubstancesDaily", label: "Flera preparat om dagen inkl. alkohol", type: .yesNo),
            ]),
            DomainSection(title: "Historia & nuläge", questions: [
                ExtendedQuestion(key: "substanceFreePeriodNoTreatment", label: "Har du någonsin varit missbruksfri utan behandling? Hur länge?", type: .yesNoSpecify),
                ExtendedQuestion(key: "substanceFreePeriodAfterTreatment", label: "Har du kunnat vara missbruksfri efter behandling? Hur länge?", type: .yesNoSpecify),
                ExtendedQuestion(key: "currentlySubstanceFree", label: "Är du just nu helt missbruksfri? Sedan hur länge?", type: .yesNoSpecify),
                ExtendedQuestion(key: "spentMoneyAlcohol30", label: "Har du lagt pengar på alkohol de senaste 30 dagarna?", type: .yesNo),
                ExtendedQuestion(key: "spentMoneyDrugs30", label: "Har du lagt pengar på droger de senaste 30 dagarna?", type: .yesNo),
                ExtendedQuestion(key: "currentTreatmentSubstance", label: "Får du för närvarande insats för alkohol/narkotika (utöver aktuell)?", type: .yesNoSpecify),
            ]),
            DomainSection(title: "Skattning", questions: [
                ExtendedQuestion(key: "clientConcernScore", label: "Hur oroad eller besvärad har du varit över din alkohol/drogkonsumtion de senaste 30 dagarna?", type: .scale(1, 5)),
                ExtendedQuestion(key: "importanceOfHelp", label: "Hur viktigt är det för dig att få hjälp med substansanvändning (utöver pågående hjälp)?", type: .mScore),
                ExtendedQuestion(key: "staffNeedScore", label: "Bedömarens uppskattning av behov av insatser för alkohol/narkotika", type: .scale(1, 5)),
            ])
        ],
        scoringQuestion: "Problem med alkohol/droganvändning"
    )

    static let attachmentDomain = ExtendedDomain(
        key: "attachment",
        title: "Anknytning & Relationer",
        subtitle: "ASI Kriterium H",
        icon: "figure.2.arms.open",
        scoreType: .pathogenic,
        sections: [
            DomainSection(title: "Social miljö", questions: [
                ExtendedQuestion(key: "livesWithSubstanceUser", label: "Lever eller umgås du frekvent med någon som för närvarande missbrukar?", type: .yesNoSpecify),
            ]),
            DomainSection(title: "Primära kontakter", questions: [
                ExtendedQuestion(key: "spendsMostTimeWith", label: "Med vem tillbringar du större delen av din tid?", type: .multipleChoice([
                    "Familj utan alkohol/drogproblem",
                    "Familj med alkohol/drogproblem",
                    "Vänner utan alkohol/drogproblem",
                    "Vänner med alkohol/drogproblem",
                    "Ensam"
                ])),
            ]),
            DomainSection(title: "Goda relationer (tidigare och/eller senaste 30 dagarna)", questions: [
                ExtendedQuestion(key: "goodRelMother", label: "Mamma/mammor", type: .yesNo),
                ExtendedQuestion(key: "goodRelFather", label: "Pappa/pappor", type: .yesNo),
                ExtendedQuestion(key: "goodRelSiblings", label: "Syskon", type: .yesNo),
                ExtendedQuestion(key: "goodRelPartner", label: "Partner", type: .yesNo),
                ExtendedQuestion(key: "goodRelChildren", label: "Egna barn", type: .yesNo),
                ExtendedQuestion(key: "goodRelFriends", label: "Vänner", type: .yesNo),
            ]),
            DomainSection(title: "Konflikter (tidigare och/eller senaste 30 dagarna)", questions: [
                ExtendedQuestion(key: "conflictMother", label: "Mamma/mammor", type: .yesNo),
                ExtendedQuestion(key: "conflictFather", label: "Pappa/pappor", type: .yesNo),
                ExtendedQuestion(key: "conflictSiblings", label: "Syskon", type: .yesNo),
                ExtendedQuestion(key: "conflictPartner", label: "Partner", type: .yesNo),
                ExtendedQuestion(key: "conflictChildren", label: "Egna barn", type: .yesNo),
                ExtendedQuestion(key: "conflictFriends", label: "Vänner", type: .yesNo),
            ]),
            DomainSection(title: "Utsatthet för våld (tidigare och/eller senaste 30 dagarna)", questions: [
                ExtendedQuestion(key: "abusePsychological", label: "Psykiskt eller känslomässigt", type: .yesNoSpecify),
                ExtendedQuestion(key: "abusePhysical", label: "Fysiskt", type: .yesNoSpecify),
                ExtendedQuestion(key: "abuseSexual", label: "Sexuellt", type: .yesNoSpecify),
                ExtendedQuestion(key: "currentHelpRelationships", label: "Får du för närvarande hjälp med problem som rör familj och umgänge?", type: .yesNo),
            ]),
            DomainSection(title: "Skattning", questions: [
                ExtendedQuestion(key: "clientConcernScore", label: "Hur oroad eller besvärad har du varit över din familj/ditt umgänge de senaste 30 dagarna?", type: .scale(1, 5)),
                ExtendedQuestion(key: "importanceOfHelp", label: "Hur viktigt är det för dig att få hjälp med familj- och umgängesproblem?", type: .mScore),
                ExtendedQuestion(key: "staffNeedScore", label: "Bedömarens uppskattning av behov av insatser för familj och umgänge", type: .scale(1, 5)),
            ])
        ],
        scoringQuestion: "Problem med anknytning och relationer"
    )

    static let mentalHealthDomain = ExtendedDomain(
        key: "mentalHealth",
        title: "Psykisk Ohälsa",
        subtitle: "ASI Kriterium I",
        icon: "brain.head.profile",
        scoreType: .pathogenic,
        sections: [
            DomainSection(title: "Behandlingshistorik", questions: [
                ExtendedQuestion(key: "inpatientTreatment", label: "Har du någonsin fått behandling för psykiska problem i slutenvård?", type: .yesNo),
                ExtendedQuestion(key: "outpatientTreatment", label: "Har du fått behandling i öppenvård?", type: .yesNo),
                ExtendedQuestion(key: "hasDiagnosis", label: "Har du fått någon diagnos?", type: .yesNoSpecify),
                ExtendedQuestion(key: "disabilityBenefit", label: "Har du fått sjukersättning på grund av psykiska besvär?", type: .yesNo),
                ExtendedQuestion(key: "prescribedMedication", label: "Har du ordinerats läkemedel för något psykiskt eller känslomässigt problem?", type: .yesNoSpecify),
            ]),
            DomainSection(title: "Symtom (någon gång + senaste 30 dagar)", questions: [
                ExtendedQuestion(key: "seriousDepression", label: "Seriös depression?", type: .yesNo),
                ExtendedQuestion(key: "seriousAnxiety", label: "Allvarlig ångest eller spänningstillstånd?", type: .yesNo),
                ExtendedQuestion(key: "cognitiveProblems", label: "Svårigheter att förstå, minnas eller koncentrera sig?", type: .yesNo),
                ExtendedQuestion(key: "hallucinations", label: "Hallucinationer?", type: .yesNo),
            ]),
            DomainSection(title: "Skattning", questions: [
                ExtendedQuestion(key: "clientConcernScore", label: "Hur oroad eller besvärad har du varit över din psykiska hälsa de senaste 30 dagarna?", type: .scale(1, 5)),
                ExtendedQuestion(key: "importanceOfHelp", label: "Hur viktigt är det för dig att få hjälp med din psykiska hälsa?", type: .mScore),
                ExtendedQuestion(key: "staffNeedScore", label: "Bedömarens uppskattning av behov av insatser för psykisk hälsa", type: .scale(1, 5)),
            ])
        ],
        scoringQuestion: "Psykisk ohälsa"
    )

    static let severeMentalHealthDomain = ExtendedDomain(
        key: "severeMentalHealth",
        title: "Allvarlig Psykisk Ohälsa",
        subtitle: "Självskada, suicid & destruktivitet",
        icon: "exclamationmark.triangle.fill",
        scoreType: .pathogenic,
        sections: [
            DomainSection(title: "⚠️ Allvarliga symtom — kräver psykologkontakt vid JA", questions: [
                ExtendedQuestion(
                    key: "suicidalThoughts",
                    label: "Har du haft allvarligt menade självmordstankar?",
                    type: .yesNo,
                    isSafetyQuestion: true,
                    safetyTriggerValue: true
                ),
                ExtendedQuestion(
                    key: "suicideAttempt",
                    label: "Har du försökt ta ditt liv?",
                    type: .yesNo,
                    isSafetyQuestion: true,
                    safetyTriggerValue: true
                ),
                ExtendedQuestion(key: "otherSevereProblems", label: "Har du haft andra psykiska problem (t.ex. ätstörningar, manier)?", type: .yesNoSpecify),
            ]),
            DomainSection(title: "Skattning", questions: [
                ExtendedQuestion(key: "clientConcernScore", label: "Hur oroad eller besvärad har du varit över din psykiska hälsa de senaste 30 dagarna?", type: .scale(1, 5)),
                ExtendedQuestion(key: "importanceOfHelp", label: "Hur viktigt är det för dig att få hjälp?", type: .mScore),
                ExtendedQuestion(key: "staffNeedScore", label: "Bedömarens uppskattning av behov av insatser", type: .scale(1, 5)),
            ])
        ],
        scoringQuestion: "Allvarlig psykisk ohälsa / självskada"
    )

    static let allProblemDomains: [ExtendedDomain] = [
        substanceDomain,
        attachmentDomain,
        mentalHealthDomain,
        severeMentalHealthDomain
    ]
}

