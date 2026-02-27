//
//  BaselineDomainsView.swift
//  Ledstjarnan
//
//  Shows the six baseline domains and progress for the new flow.
//

import SwiftUI

struct BaselineDomainsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var appState: AppState
    let client: Client
    var openAssessmentId: String? = nil
    @EnvironmentObject private var logicStore: LogicReferenceStore
    
    private var lang: String { appState.languageCode }

    @State private var assessment: Assessment?
    @State private var answers: [String: AnyCodable] = [:]
    @State private var isLoading = true
    @State private var loadError: String?
    @State private var saveError: String?
    @State private var isSavingDraft = false
    @State private var selectedDomain: BaselineDomain?
    @State private var isCompleting = false
    @State private var showRecommendations = false
    @State private var recommendations: [InterventionRecommendation] = []
    @State private var safetyFlags: [SafetyFlag] = []
    @State private var ptsdEval: PTSDEvaluation?
    @State private var domainScoresResult: [DomainScore] = []
    @State private var showInsatskarta = false

    private let assessmentService = AssessmentService()
    private let clientService = ClientService()

    private var completedCount: Int {
        BaselineDomainFlowConfig.allDomains.filter { status(for: $0) == .completed }.count
    }

    private var totalCount: Int { BaselineDomainFlowConfig.allDomains.count }
    private var allDomainsCompleted: Bool { completedCount == totalCount && totalCount > 0 }
    private var isAlreadyCompleted: Bool { assessment?.status == "completed" }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            if isLoading {
                ProgressView(LocalizedString("baseline_loading", lang))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let loadError {
                ErrorStateView(message: loadError) {
                    Task { await loadOrCreateAssessment() }
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        if let saveError {
                            Text(saveError)
                                .font(.footnote)
                                .foregroundColor(AppColors.danger)
                                .padding(.horizontal)
                        }
                        progressCard
                        domainSection(title: LocalizedString("baseline_section_salutogenic", lang), domains: displayDomains(in: BaselineDomainFlowConfig.salutogenicDomains))
                        domainSection(title: LocalizedString("baseline_section_pathogenic", lang), domains: displayDomains(in: BaselineDomainFlowConfig.pathogenicDomains))
                    }
                    .padding(.vertical, 16)
                }
                if isAlreadyCompleted {
                    // Already completed; no action needed
                } else if allDomainsCompleted {
                    completeBaselineButton
                } else {
                    finishLaterButton
                }
            }
        }
        .background(AppColors.background.ignoresSafeArea())
        .task {
            await loadOrCreateAssessment()
        }
        .sheet(item: $selectedDomain) { domain in
            if let assessment {
                DomainFormView(
                    client: client,
                    assessmentId: assessment.id,
                    domain: domain,
                    answers: $answers
                )
            }
        }
        .sheet(isPresented: $showRecommendations, onDismiss: { dismiss() }) {
            AssessmentRecommendationView(
                client: client,
                assessmentType: "baseline",
                focusSuggestions: recommendations
                    .sorted { $0.needLevel.rawValue > $1.needLevel.rawValue }
                    .map { AssessmentRecommendationFocus(domainKey: $0.domainKey, title: $0.domainTitle, needLevel: $0.needLevel) },
                suggestedChapters: [],
                isClientLinked: client.isLinked,
                onClose: { showRecommendations = false },
                onGoToPlanBuilder: { _ in showRecommendations = false },
                onAssignChapters: { showRecommendations = false },
                onOpenInsatskarta: { showInsatskarta = true },
                insatskartaRecommendations: recommendations,
                insatskartaSafetyFlags: safetyFlags,
                insatskartaPTSD: ptsdEval,
                insatskartaClientName: client.displayName
            )
        }
        .sheet(isPresented: $showInsatskarta) {
            if let ptsd = ptsdEval {
                InsatskartraView(
                    recommendations: recommendations,
                    safetyFlags: safetyFlags,
                    ptsd: ptsd,
                    clientName: client.displayName
                )
            }
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Label(LocalizedString("general_back", lang), systemImage: "chevron.left")
                    .font(.subheadline.weight(.semibold))
            }
            .tint(AppColors.textPrimary)

            Spacer()
            VStack(spacing: 2) {
            Text(LocalizedString("baseline_title", lang))
                    .font(.headline)
                Text(client.displayName)
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            Spacer()
            Spacer()
                .frame(width: 44)
        }
        .padding()
        .background(AppColors.mainSurface)
    }

    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(format: LocalizedString("baseline_progress", lang), completedCount, totalCount))
                .font(.subheadline.weight(.semibold))
            ProgressView(value: Double(completedCount), total: Double(totalCount))
                .accentColor(AppColors.primary)
            if let assessment, assessment.status == "completed" {
                Label(String(format: LocalizedString("baseline_completed_label", lang), formattedDate(assessment.completedAt)), systemImage: "checkmark.seal.fill")
                    .font(.caption)
                    .foregroundColor(AppColors.success)
            } else {
                Text(LocalizedString("baseline_draft_notice", lang))
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(AppColors.secondarySurface)
        .cornerRadius(20)
        .padding(.horizontal)
    }

    private func domainSection(title: String, domains: [BaselineDisplayDomain]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title3.bold())
                .padding(.horizontal)
            VStack(spacing: 12) {
                ForEach(domains) { domain in
                    Button {
                        if assessment != nil {
                            selectedDomain = domain.base
                        }
                    } label: {
                        HStack(spacing: 16) {
                            Image(systemName: domain.icon)
                                .font(.title2)
                                .foregroundColor(AppColors.primary)
                                .frame(width: 44, height: 44)
                                .background(AppColors.primary.opacity(0.12))
                                .cornerRadius(12)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(domain.title)
                                    .font(.headline)
                                    .foregroundColor(AppColors.textPrimary)
                                Text(domain.subtitle)
                                    .font(.caption)
                                    .foregroundColor(AppColors.textSecondary)
                                if domain.questionCount > 0 {
                                Text(String(format: LocalizedString("domain_question_count_short", lang), domain.questionCount))
                                        .font(.caption2)
                                        .foregroundColor(AppColors.textSecondary)
                                }
                                Text(status(for: domain.base).localizedLabel)
                                    .font(.caption2)
                                    .foregroundColor(color(for: status(for: domain.base)))
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(AppColors.textSecondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(AppColors.mainSurface)
                        .cornerRadius(18)
                    }
                    .disabled(assessment == nil)
                }
            }
            .padding(.horizontal)
        }
    }

    private var finishLaterButton: some View {
        VStack(spacing: 10) {
            Button(action: { Task { await finishLater() } }) {
                HStack {
                    if isSavingDraft {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primary))
                    }
                    Text(LocalizedString("baseline_finish_later", lang))
                        .font(.headline)
                        .foregroundColor(AppColors.primary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppColors.secondarySurface)
                .cornerRadius(16)
            }
            .disabled(isSavingDraft)
            Text(LocalizedString("baseline_finish_later_subtext", lang))
                .font(.caption)
                .foregroundColor(AppColors.textSecondary)
        }
        .padding()
        .background(AppColors.background.ignoresSafeArea(edges: .bottom))
    }

    private func status(for domain: BaselineDomain) -> DomainCompletionStatus {
        let statusKey = DomainAnswerKey.status(domain.key)
        if let value = answers[statusKey]?.value as? String, value == "completed" {
            return .completed
        }
        let prefix = "\(domain.key)."
        let hasAnyAnswer = answers.keys.contains(where: { $0.hasPrefix(prefix) })
        return hasAnyAnswer ? .inProgress : .notStarted
    }

    private func color(for status: DomainCompletionStatus) -> Color {
        switch status {
        case .notStarted: return AppColors.textSecondary
        case .inProgress: return Color.orange
        case .completed: return AppColors.success
        }
    }

    private func formattedDate(_ date: Date?) -> String {
        guard let date else { return "--" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func loadOrCreateAssessment() async {
        guard let unitId = appState.currentUnit?.id else {
            await MainActor.run {
                loadError = "No unit connected."
                isLoading = false
            }
            return
        }
        let staffId = appState.currentStaffProfile?.id
        isLoading = true
        loadError = nil
        do {
            let list = try await assessmentService.getAssessments(clientId: client.id)
            if let openId = openAssessmentId, let openAssessment = list.first(where: { $0.id == openId }) {
                let fetchedAnswers = try await answersDictionary(assessmentId: openAssessment.id)
                await MainActor.run {
                    self.assessment = openAssessment
                    self.answers = fetchedAnswers
                    self.isLoading = false
                }
                return
            }
            let baselines = list.filter { $0.assessmentType == "baseline" }
            let completed = baselines.filter { $0.status == "completed" }
                .sorted(by: { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) })
                .first
            let draft = baselines.first { $0.status != "completed" }
            let existing = completed ?? draft
            if let assessment = existing {
                let fetchedAnswers = try await answersDictionary(assessmentId: assessment.id)
                await MainActor.run {
                    self.assessment = assessment
                    self.answers = fetchedAnswers
                    self.isLoading = false
                }
            } else {
                let new = try await assessmentService.createAssessment(
                    clientId: client.id,
                    unitId: unitId,
                    type: "baseline",
                    createdByStaffId: staffId
                )
                await MainActor.run {
                    self.assessment = new
                    self.answers = [:]
                    self.isLoading = false
                }
            }
        } catch {
            await MainActor.run {
                self.loadError = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    private func answersDictionary(assessmentId: String) async throws -> [String: AnyCodable] {
        let answerList = try await assessmentService.getAssessmentAnswers(assessmentId: assessmentId)
        return answerList.reduce(into: [String: AnyCodable]()) { dict, answer in
            let key = "\(answer.domainKey).\(answer.questionKey)"
            if let value = answer.value {
                dict[key] = value
            }
        }
    }

    private func finishLater() async {
        guard let assessment else { return }
        isSavingDraft = true
        saveError = nil
        let payloads = AssessmentAnswerPayloadBuilder.payloads(from: answers, assessmentId: assessment.id)
        do {
            try await assessmentService.upsertAnswers(payloads)
            await MainActor.run {
                isSavingDraft = false
                dismiss()
            }
        } catch {
            await MainActor.run {
                saveError = error.localizedDescription
                isSavingDraft = false
            }
        }
    }

    private var completeBaselineButton: some View {
        VStack(spacing: 10) {
            Button(action: { Task { await completeBaseline() } }) {
                HStack {
                    if isCompleting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppColors.onPrimary))
                    }
                    Text(LocalizedString("baseline_complete_button", lang))
                        .font(.headline)
                        .foregroundColor(AppColors.onPrimary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppColors.primary)
                .cornerRadius(16)
            }
            .disabled(isCompleting)
            Text(LocalizedString("baseline_complete_subtext", lang))
                .font(.caption)
                .foregroundColor(AppColors.textSecondary)
        }
        .padding()
        .background(AppColors.background.ignoresSafeArea(edges: .bottom))
    }

    private func completeBaseline() async {
        guard let assessment else { return }
        isCompleting = true
        saveError = nil
        do {
            let payloads = AssessmentAnswerPayloadBuilder.payloads(from: answers, assessmentId: assessment.id)
            try await assessmentService.upsertAnswers(payloads)

            let now = Date()
            try await assessmentService.updateAssessment(
                id: assessment.id,
                status: "completed",
                completedAt: now,
                notes: nil
            )

            let ptsd = ScoringEngine.evaluatePTSD(answers: answers)
            let scores = buildDomainScores(from: answers, ptsd: ptsd)
            let flags = ScoringEngine.evaluateSafetyFlags(
                answers: answers,
                ptsd: ptsd,
                problemScores: scores.filter { $0.scoreType == .pathogenic }
            )
            let recs = ScoringEngine.buildRecommendations(
                domainScores: scores,
                ptsd: ptsd,
                store: logicStore
            )

            try await assessmentService.saveSummaryFields(
                assessmentId: assessment.id,
                ptsdScore: ptsd.totalSymptomScore,
                ptsdProbable: ptsd.probablePTSD,
                safetyFlags: flags,
                recommendations: recs,
                domainScores: scores
            )

            if let unitId = appState.currentUnit?.id,
               let staffId = appState.currentStaffProfile?.id {
                try? await clientService.createTimelineEvent(
                    clientId: client.id,
                    unitId: unitId,
                    eventType: "assessment_completed",
                    title: LocalizedString("assessment_timeline_title_baseline", lang),
                    description: String(format: LocalizedString("baseline_timeline_description", lang), completedCount, totalCount),
                    staffId: staffId
                )
            }

            await MainActor.run {
                self.recommendations = recs
                self.safetyFlags = flags
                self.ptsdEval = ptsd
                self.domainScoresResult = scores
                self.isCompleting = false
                self.showRecommendations = true
            }
        } catch {
            await MainActor.run {
                saveError = error.localizedDescription
                isCompleting = false
            }
        }
    }

    private func buildDomainScores(from data: [String: AnyCodable], ptsd: PTSDEvaluation) -> [DomainScore] {
        var results: [DomainScore] = []

        for info in AssessmentDefinition.salutogenicModuleInfos(from: logicStore) {
            let base = "\(info.key)."
            let clientKey = base + DomainQuestionKeys.clientScore
            let readinessKey = DomainAnswerKey.readiness(info.key)
            let importanceKey = base + DomainQuestionKeys.importance
            let staffKey = base + DomainQuestionKeys.staffAssessment
            let noteKey = DomainAnswerKey.notes(info.key)
            let noteValue = (data[noteKey]?.value as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            let readinessScore = data[readinessKey]?.value as? Int
            let clientScore = data[clientKey]?.value as? Int
            let iScore = clientScore ?? readinessScore ?? 3

            results.append(DomainScore(
                domainKey: info.key,
                iScore: iScore,
                iScoreStaff: (data[staffKey]?.value as? Int) ?? 3,
                mScore: (data[importanceKey]?.value as? Int) ?? 3,
                pScore: 2,
                notes: noteValue,
                scoreType: info.scoreType
            ))
        }

        for info in AssessmentDefinition.pathogenicModuleInfos(from: logicStore) where info.usesStandardIMPScores {
            let prefix = "\(info.key)."
            let clientKey = prefix + ProblemQuestionKeys.clientScore
            let readinessKey = DomainAnswerKey.readiness(info.key)
            let importanceKey = prefix + ProblemQuestionKeys.importance
            let staffKey = prefix + ProblemQuestionKeys.staffAssessment
            let noteKey = DomainAnswerKey.notes(info.key)
            let noteValue = (data[noteKey]?.value as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            let readinessScore = data[readinessKey]?.value as? Int
            let clientScore = data[clientKey]?.value as? Int
            let iScore = clientScore ?? readinessScore ?? 1

            results.append(DomainScore(
                domainKey: info.key,
                iScore: iScore,
                iScoreStaff: (data[staffKey]?.value as? Int) ?? 1,
                mScore: (data[importanceKey]?.value as? Int) ?? 3,
                pScore: 2,
                notes: noteValue,
                scoreType: info.scoreType
            ))
        }

        let hasTraumaAnswers = data.keys.contains { $0.hasPrefix("trauma.") }
        if hasTraumaAnswers {
            let traumaNeed: Int
            switch ptsd.totalSymptomScore {
            case 0: traumaNeed = 1
            case 1...8: traumaNeed = 2
            case 9...20: traumaNeed = 3
            case 21...35: traumaNeed = 4
            default: traumaNeed = 5
            }
            results.append(DomainScore(
                domainKey: "trauma",
                iScore: traumaNeed,
                iScoreStaff: ptsd.probablePTSD ? 5 : (ptsd.requiresPsychologist ? 4 : 2),
                mScore: 3,
                pScore: 1,
                notes: "",
                scoreType: .pathogenic
            ))
        }

        return results
    }

    private func displayDomains(in domains: [BaselineDomain]) -> [BaselineDisplayDomain] {
        domains.map { domain in
            let logic = logicStore.domain(forAppKey: domain.key)
            let sections = logicStore.interviewSections(forAppKey: domain.key)
            let questionCount = sections.reduce(0) { result, section in
                result + (section.questions?.count ?? 0)
            }
            return BaselineDisplayDomain(
                base: domain,
                logic: logic,
                questionCount: questionCount > 0 ? questionCount : domain.questionCount,
                lang: lang
            )
        }
    }
}

private struct ErrorStateView: View {
    let message: String
    let retry: () -> Void
    @Environment(\.languageCode) var lang

    var body: some View {
        VStack(spacing: 12) {
            Text(message)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(AppColors.textSecondary)
            Button(LocalizedString("general_retry", lang), action: retry)
                .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct BaselineDisplayDomain: Identifiable {
    let base: BaselineDomain
    let logic: LogicAssessmentDomain?
    let questionCount: Int
    let lang: String

    var id: String { base.id }
    var title: String { base.title(lang: lang) }
    var subtitle: String { base.subtitle(lang: lang) }
    var icon: String { base.icon }
}
