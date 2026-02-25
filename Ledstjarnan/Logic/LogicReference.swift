//
//  LogicReference.swift
//  Ledstjarnan
//
//  Value types that bundle the Ledstjärnan logic reference data used
//  throughout the app.
//

import Foundation

typealias LogicTreatmentLevel = TreatmentLevel
typealias LogicScoringDimension = ScoringDimension
typealias LogicAssessmentDomain = AssessmentDomain
typealias LogicDomainScoreSlot = DomainScoreSlot
typealias LogicAssessmentStep = AssessmentStep
typealias LogicTraumaRule = TraumaRule
typealias LogicGuidebookEntry = GuidebookEntry
typealias LogicTraumaQuestion = TraumaQuestion
typealias LogicInterviewSection = DomainInterviewSection
typealias LogicInterviewQuestion = DomainInterviewQuestion
typealias LogicProblemDomain = ProblemDomainDefinition
typealias LogicProblemSection = ProblemDomainSectionDefinition
typealias LogicProblemQuestion = ProblemDomainQuestionDefinition

struct LogicReference {
    var treatmentLevels: [LogicTreatmentLevel] = []
    var scoringDimensions: [LogicScoringDimension] = []
    var assessmentDomains: [LogicAssessmentDomain] = []
    var domainScoreSlots: [LogicDomainScoreSlot] = []
    var assessmentSteps: [LogicAssessmentStep] = []
    var traumaRules: [LogicTraumaRule] = []
    var guidebookEntries: [LogicGuidebookEntry] = []
    var traumaQuestions: [LogicTraumaQuestion] = []
    var interviewSections: [LogicInterviewSection] = []
    var problemDomains: [LogicProblemDomain] = []
}
