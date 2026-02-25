//
//  LogicService.swift
//  Ledstjarnan
//
//  Fetches the reference data that describes the Ledstjarnan logic
//  (levels, scoring dimensions, domains, trauma rules, guidebook copy).
//

import Foundation
import Supabase

final class LogicService {
    private let supabase = SupabaseManager.shared.client

    func fetchFullReference() async throws -> LogicReference {
        async let treatmentLevels = fetchTreatmentLevels()
        async let scoringDimensions = fetchScoringDimensions()
        async let assessmentDomains = fetchAssessmentDomains()
        async let domainScoreSlots = fetchDomainScoreSlots()
        async let assessmentSteps = fetchAssessmentSteps()
        async let traumaRules = fetchTraumaRules()
        async let guidebookEntries = fetchGuidebookEntries()
        async let traumaQuestions = fetchTraumaQuestions()
        async let interviewSections = fetchInterviewSections()
        async let problemDomains = fetchProblemDomains()

        return LogicReference(
            treatmentLevels: try await treatmentLevels,
            scoringDimensions: try await scoringDimensions,
            assessmentDomains: try await assessmentDomains,
            domainScoreSlots: try await domainScoreSlots,
            assessmentSteps: try await assessmentSteps,
            traumaRules: try await traumaRules,
            guidebookEntries: try await guidebookEntries,
            traumaQuestions: try await traumaQuestions,
            interviewSections: try await interviewSections,
            problemDomains: try await problemDomains
        )
    }

    func fetchTreatmentLevels() async throws -> [TreatmentLevel] {
        try await supabase
            .from("treatment_levels")
            .select()
            .order("code", ascending: true)
            .execute()
            .value
    }

    func fetchScoringDimensions() async throws -> [ScoringDimension] {
        try await supabase
            .from("scoring_dimensions")
            .select()
            .order("code", ascending: true)
            .execute()
            .value
    }

    func fetchAssessmentDomains() async throws -> [AssessmentDomain] {
        try await supabase
            .from("assessment_domains")
            .select()
            .order("life_area_order", ascending: true)
            .execute()
            .value
    }

    func fetchDomainScoreSlots() async throws -> [DomainScoreSlot] {
        try await supabase
            .from("domain_score_slots")
            .select()
            .execute()
            .value
    }

    func fetchAssessmentSteps() async throws -> [AssessmentStep] {
        try await supabase
            .from("assessment_steps")
            .select()
            .order("step_number")
            .execute()
            .value
    }

    func fetchTraumaRules() async throws -> [TraumaRule] {
        try await supabase
            .from("trauma_rules")
            .select()
            .order("rule_code")
            .execute()
            .value
    }

    func fetchGuidebookEntries() async throws -> [GuidebookEntry] {
        try await supabase
            .from("guidebook_entries")
            .select()
            .order("slug")
            .execute()
            .value
    }

    func fetchTraumaQuestions() async throws -> [TraumaQuestion] {
        try await supabase
            .from("trauma_questions")
            .select()
            .order("question_number")
            .execute()
            .value
    }

    func fetchInterviewSections() async throws -> [DomainInterviewSection] {
        try await supabase
            .from("domain_interview_sections")
            .select("*, domain_interview_questions(*)")
            .order("display_order")
            .execute()
            .value
    }

    func fetchProblemDomains() async throws -> [ProblemDomainDefinition] {
        try await supabase
            .from("problem_domains")
            .select("*, problem_domain_sections(*, problem_domain_questions(*))")
            .order("code")
            .execute()
            .value
    }
}

