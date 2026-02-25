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
    var helpText: String? = nil
}

struct ExtendedDomain: Identifiable {
    let id = UUID()
    let key: String
    let title: String
    let subtitle: String
    let icon: String
    let scoreType: DomainScore.ScoreType
    let sections: [DomainSection]
    let scoringQuestion: String
}

struct DomainSection: Identifiable {
    let id = UUID()
    let title: String
    let questions: [ExtendedQuestion]
    let isScoringSection: Bool

    init(title: String, questions: [ExtendedQuestion], isScoringSection: Bool = false) {
        self.title = title
        self.questions = questions
        self.isScoringSection = isScoringSection
    }
}

// MARK: - ProblemDomainDefinition Extension

extension ProblemDomainDefinition {
    func asExtendedDomain() -> ExtendedDomain {
        let mappedSections = (sections ?? []).map { section in
            let mappedQuestions = (section.questions ?? []).map { question -> ExtendedQuestion in
                let questionType: ExtendedQuestionType
                switch question.questionType {
                case .yesNo:
                    questionType = .yesNo
                case .yesNoSpecify:
                    questionType = .yesNoSpecify
                case .text:
                    questionType = .text
                case .multipleChoice:
                    questionType = .multipleChoice(question.options ?? [])
                case .multiSelect:
                    questionType = .multiSelect(question.options ?? [])
                case .scale:
                    questionType = .scale(question.scaleMin ?? 1, question.scaleMax ?? 5)
                case .mScore:
                    questionType = .mScore
                case .pScore:
                    questionType = .pScore
                }
                
                return ExtendedQuestion(
                    key: question.questionKey,
                    label: question.label,
                    type: questionType,
                    isSafetyQuestion: question.isSafetyQuestion,
                    safetyTriggerValue: question.safetyTriggerValue?.value,
                    subQuestions: [],
                    helpText: question.helpText
                )
            }
            
            return DomainSection(
                title: section.title,
                questions: mappedQuestions,
                isScoringSection: section.isScoringSection
            )
        }
        
        let scoreTypeValue: DomainScore.ScoreType
        switch scoreType {
        case .salutogenic:
            scoreTypeValue = .salutogenic
        case .pathogenic:
            scoreTypeValue = .pathogenic
        }
        
        return ExtendedDomain(
            key: appKey,
            title: title,
            subtitle: subtitle ?? "",
            icon: icon ?? "questionmark.circle",
            scoreType: scoreTypeValue,
            sections: mappedSections,
            scoringQuestion: scoringQuestion
        )
    }
}


