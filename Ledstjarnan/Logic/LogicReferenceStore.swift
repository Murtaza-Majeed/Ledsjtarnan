//
//  LogicReferenceStore.swift
//  Ledstjarnan
//
//  Centralized store for the Ledstjarnan logic reference fetched from Supabase.
//

import Foundation
import Combine

@MainActor
final class LogicReferenceStore: ObservableObject {
    @Published private(set) var reference: LogicReference = LogicReference()
    var problemDomains: [LogicProblemDomain] { reference.problemDomains }
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var lastUpdatedAt: Date?

    private let logicService = LogicService()
    private let domainLogicCodes: [String: String] = [
        "health": "KROPP_HÄLSA",
        "education": "UTBILDNING_ARBETE",
        "social": "SOCIAL_KOMPETENS",
        "independence": "SJALVSTANDIGHET_VARDAG",
        "relationships": "RELATIONER_NATVERK",
        "identity": "IDENTITET_UTVECKLING",
        "substance": "ALKOHOL_DROGER",
        "attachment": "ANKNYTNING_RELATIONER",
        "mentalHealth": "PSYKISK_OHALSA",
        "severeMentalHealth": "ALLVARLIG_PSYKISK_OHALSA",
        "trauma": "TRAUMA"
    ]

    private static let domainIcons: [String: String] = [
        "health": "heart.text.square",
        "education": "book.closed.fill",
        "social": "person.2.fill",
        "independence": "house.fill",
        "relationships": "link",
        "identity": "sparkles",
        "substance": "cross.vial",
        "attachment": "figure.2.arms.open",
        "mentalHealth": "brain.head.profile",
        "severeMentalHealth": "exclamationmark.triangle.fill",
        "trauma": "shield.lefthalf.filled"
    ]

        private let traumaPseudoDomain = LogicAssessmentDomain(
        id: UUID(),
        dimensionId: UUID(),
        code: "TRAUMA",
        label: "Trauma & STRESS",
        description: "Strukturerad traumakartläggning.",
        lifeAreaOrder: nil,
        questionSetRef: "trauma",
        createdAt: nil
    )

    private let cacheTTL: TimeInterval = 60 * 15 // 15 minutes
    private var hasLoadedOnce: Bool {
        !reference.assessmentDomains.isEmpty
    }

    init() {
        Task { await loadReferenceIfNeeded() }
    }

    func refreshReference() async {
        await loadReferenceIfNeeded(force: true)
    }

    func loadReferenceIfNeeded(force: Bool = false) async {
        guard !isLoading else { return }
        if !force,
           hasLoadedOnce,
           let lastUpdatedAt,
           Date().timeIntervalSince(lastUpdatedAt) < cacheTTL {
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            let ref = try await logicService.fetchFullReference()
            reference = ref
            lastUpdatedAt = Date()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func getDomain(byCode code: String) -> LogicAssessmentDomain? {
        reference.assessmentDomains.first { $0.code == code }
    }

    func domain(forAppKey key: String) -> LogicAssessmentDomain? {
        guard let logicCode = domainLogicCodes[key] else { return nil }
        if logicCode == "TRAUMA" {
            return traumaPseudoDomain
        }
        return getDomain(byCode: logicCode)
    }

    func scoreSlots(forAppKey key: String) -> [LogicDomainScoreSlot] {
        guard let domain = domain(forAppKey: key),
              domain.code != "TRAUMA" else { return [] }
        return reference.domainScoreSlots
            .filter { $0.domainId == domain.id }
            .sorted { slotSortOrder($0.slotCode) < slotSortOrder($1.slotCode) }
    }

    func interviewSections(forAppKey key: String) -> [LogicInterviewSection] {
        guard let domain = domain(forAppKey: key) else { return [] }
        return reference.interviewSections
            .filter { $0.domainId == domain.id }
            .map { section in
                var copy = section
                let sortedQuestions = (section.questions ?? [])
                    .sorted { $0.displayOrder < $1.displayOrder }
                copy.questions = sortedQuestions
                return copy
            }
            .sorted { $0.displayOrder < $1.displayOrder }
    }

    func traumaQuestions(for group: String) -> [LogicTraumaQuestion] {
        reference.traumaQuestions
            .filter { $0.groupCode == group }
            .sorted { ($0.questionNumber ?? 0) < ($1.questionNumber ?? 0) }
    }

    private func slotSortOrder(_ code: String) -> Int {
        switch code {
        case "SCORE": return 0
        case "CLIENT": return 0
        case "I": return 1
        case "SCORE_STAFF": return 1
        case "STAFF": return 1
        case "I_STAFF": return 2
        case "M": return 3
        case "P": return 4
        default: return 10
        }
    }

    func guidebookEntry(slug: String) -> LogicGuidebookEntry? {
        reference.guidebookEntries.first { $0.slug == slug }
    }

    func problemDomain(forAppKey key: String) -> LogicProblemDomain? {
        return reference.problemDomains.first { $0.appKey == key }
    }

    func problemSections(forAppKey key: String) -> [LogicProblemSection] {
        guard let domain = problemDomain(forAppKey: key) else { return [] }
        return (domain.sections ?? [])
            .map { section in
                var copy = section
                copy.questions = (section.questions ?? []).sorted { $0.displayOrder < $1.displayOrder }
                return copy
            }
            .sorted { $0.displayOrder < $1.displayOrder }
    }

    var salutogenicDomains: [LogicAssessmentDomain] {
        guard let salutoDimension = reference.scoringDimensions.first(where: { $0.code == "SALUTOGENES" }) else {
            return []
        }
        return reference.assessmentDomains
            .filter { $0.dimensionId == salutoDimension.id }
            .sorted { ($0.lifeAreaOrder ?? 0) < ($1.lifeAreaOrder ?? 0) }
    }
    
    var pathogenicDomains: [LogicAssessmentDomain] {
        guard let dimension = reference.scoringDimensions.first(where: { $0.code == "PATOGENES" }) else {
            return []
        }
        return reference.assessmentDomains
            .filter { $0.dimensionId == dimension.id }
            .sorted { $0.code < $1.code }
    }

    func appKey(forDomainCode code: String) -> String? {
        domainLogicCodes.first { $0.value == code }?.key
    }

    func icon(forAppKey key: String) -> String {
        Self.domainIcons[key] ?? "questionmark.circle"
    }

    func domainScoreType(forAppKey key: String) -> DomainScore.ScoreType {
        guard let domain = domain(forAppKey: key) else { return .salutogenic }
        if let dim = reference.scoringDimensions.first(where: { $0.id == domain.dimensionId }) {
            return dim.scaleDirection == .inverted ? .salutogenic : .pathogenic
        }
        return .salutogenic
    }
}
