//
//  FollowUpDomainsView.swift
//  Ledstjarnan
//
//  Follow-up domain overview comparing baseline vs current scores.
//

import SwiftUI

struct FollowUpDomainsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var appState: AppState
    let client: Client
    var openAssessmentId: String? = nil
    @EnvironmentObject private var logicStore: LogicReferenceStore

    @State private var assessment: Assessment?
    @State private var answers: [String: AnyCodable] = [:]
    @State private var baselineScores: [String: Int] = [:]
    @State private var baselineAnswers: [String: AnyCodable] = [:]
    @State private var isLoading = true
    @State private var loadError: String?
    @State private var saveError: String?
    @State private var selectedDomain: BaselineDomain?
    @State private var showSummary = false
    @State private var staffNote: String = ""
    @State private var isFinishing = false
    @State private var baselineCompletion: Date?
    @State private var baselineAssessment: Assessment?
    @State private var showComparison = false
    @State private var recommendations: [InterventionRecommendation] = []
    @State private var domainScoresResult: [DomainScore] = []

    private let assessmentService = AssessmentService()
    private let clientService = ClientService()

    private var lang: String { appState.languageCode }

    private var allDomains: [BaselineDomain] { BaselineDomainFlowConfig.allDomains }
    private var salutogenicDomains: [BaselineDomain] { BaselineDomainFlowConfig.salutogenicDomains }
    private var pathogenicDomains: [BaselineDomain] { BaselineDomainFlowConfig.pathogenicDomains }

    private var completedCount: Int {
        allDomains.filter { domainStatus(for: $0) == .completed }.count
    }
    private var totalCount: Int { allDomains.count }
    private var allDomainsCompleted: Bool { completedCount == totalCount && totalCount > 0 }
    private var isAlreadyCompleted: Bool { assessment?.status == "completed" }

    private var baselineDateText: String {
        guard let baseline = baselineCompletion else { return "—" }
        return Self.dateFormatter.string(from: baseline)
    }

    private var followupDateText: String {
        guard let date = assessment?.createdAt else { return "—" }
        return Self.dateFormatter.string(from: date)
    }

    private var summaryComparisonDomains: [FollowUpSummaryDomain] {
        allDomains.map { domain in
            FollowUpSummaryDomain(
                title: domain.title(lang: lang),
                previousScore: baselineScores[domain.key],
                currentScore: currentScore(for: domain.key)
            )
        }
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }()

    var body: some View {
        VStack(spacing: 0) {
            topBar
            if isLoading {
                ProgressView(LocalizedString("followup_domains_loading", lang))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let loadError {
                ErrorStateView(message: loadError, lang: lang) {
                    Task { await loadData() }
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        if let saveError {
                            Text(saveError)
                                .font(.footnote)
                                .foregroundColor(AppColors.danger)
                                .padding(.horizontal)
                        }
                        headerCard
                        progressCard
                        instructions
                        domainSection(
                            title: LocalizedString("baseline_section_salutogenic", lang),
                            domains: salutogenicDomains
                        )
                        domainSection(
                            title: LocalizedString("baseline_section_pathogenic", lang),
                            domains: pathogenicDomains
                        )
                    }
                    .padding(.vertical, 24)
                }
                bottomButton
            }
        }
        .background(AppColors.background.ignoresSafeArea())
        .task {
            await loadData()
        }
        .sheet(item: $selectedDomain) { domain in
            if let assessment {
                DomainFormView(
                    client: client,
                    assessmentId: assessment.id,
                    domain: domain,
                    answers: $answers,
                    previousScore: baselineScores[domain.key]
                )
            }
        }
        .sheet(isPresented: $showSummary, onDismiss: {
            if isAlreadyCompleted { dismiss() }
        }) {
            FollowUpSummaryView(
                client: client,
                followUpDate: assessment?.createdAt,
                domains: summaryComparisonDomains,
                staffNote: $staffNote,
                onSaveDraft: {
                    Task { await saveDraftNote() }
                },
                onFinish: {
                    Task { await finishFollowUp() }
                },
                canFinish: allDomainsCompleted,
                isFinishing: isFinishing
            )
        }
        .sheet(isPresented: $showComparison, onDismiss: { dismiss() }) {
            FollowUpComparisonView(
                appState: appState,
                client: client,
                initialBaseline: baselineAssessment,
                initialFollowup: assessment,
                initialBaselineAnswers: baselineAnswers,
                initialFollowupAnswers: answers
            )
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                Label(LocalizedString("general_back", lang), systemImage: "chevron.left")
                    .font(.subheadline.weight(.semibold))
            }
            .tint(AppColors.textPrimary)
            Spacer()
            VStack(spacing: 2) {
                Text(LocalizedString("followup_domains_assessment_title", lang))
                    .font(.headline)
                Text(client.displayName)
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            Spacer()
            Spacer().frame(width: 44)
        }
        .padding()
        .background(AppColors.mainSurface)
    }

    // MARK: - Header & Progress

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(client.displayName)
                .font(.title3.bold())
            Text(String(format: LocalizedString("followup_domains_baseline_date", lang), baselineDateText))
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
            Text(String(format: LocalizedString("followup_domains_followup_date", lang), followupDateText))
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.mainSurface)
        .cornerRadius(24)
        .padding(.horizontal)
    }

    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(format: LocalizedString("baseline_progress", lang), completedCount, totalCount))
                .font(.subheadline.weight(.semibold))
            ProgressView(value: Double(completedCount), total: Double(totalCount))
                .accentColor(AppColors.primary)
            if isAlreadyCompleted {
                Label(
                    String(format: LocalizedString("baseline_completed_label", lang), formattedDate(assessment?.completedAt)),
                    systemImage: "checkmark.seal.fill"
                )
                .font(.caption)
                .foregroundColor(AppColors.success)
            } else {
                Text(LocalizedString("followup_domains_draft_notice", lang))
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

    private var instructions: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(LocalizedString("followup_domains_update_instruction", lang))
                .font(.subheadline)
            Text(LocalizedString("followup_domains_previous_score_hint", lang))
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(.horizontal)
    }

    // MARK: - Domain Sections

    private func domainSection(title: String, domains: [BaselineDomain]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title3.bold())
                .padding(.horizontal)
            VStack(spacing: 12) {
                ForEach(domains) { domain in
                    domainRow(domain)
                }
            }
            .padding(.horizontal)
        }
    }

    private func domainRow(_ domain: BaselineDomain) -> some View {
        let status = domainStatus(for: domain)
        return Button {
            selectedDomain = domain
        } label: {
            HStack(spacing: 16) {
                Image(systemName: domain.icon)
                    .font(.title2)
                    .foregroundColor(AppColors.primary)
                    .frame(width: 44, height: 44)
                    .background(AppColors.primary.opacity(0.12))
                    .cornerRadius(12)
                VStack(alignment: .leading, spacing: 4) {
                    Text(domain.title(lang: lang))
                        .font(.headline)
                        .foregroundColor(AppColors.textPrimary)
                    Text(String(format: LocalizedString("followup_domains_score_comparison", lang), formattedScore(baselineScores[domain.key]), formattedScore(currentScore(for: domain.key))))
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                    Text(status.localizedLabel)
                        .font(.caption2)
                        .foregroundColor(statusColor(for: status))
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

    // MARK: - Bottom Button

    private var bottomButton: some View {
        Group {
            if isAlreadyCompleted {
                viewComparisonButton
            } else if allDomainsCompleted {
                completeFollowUpButton
            } else {
                saveAndFinishLaterButton
            }
        }
    }

    private var completeFollowUpButton: some View {
        VStack(spacing: 10) {
            Button(action: { showSummary = true }) {
                Text(LocalizedString("followup_domains_review_summary", lang))
                    .font(.headline)
                    .foregroundColor(AppColors.onPrimary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppColors.primary)
                    .cornerRadius(16)
            }
            Text(LocalizedString("followup_complete_subtext", lang))
                .font(.caption)
                .foregroundColor(AppColors.textSecondary)
        }
        .padding()
        .background(AppColors.background.ignoresSafeArea(edges: .bottom))
    }

    private var saveAndFinishLaterButton: some View {
        VStack(spacing: 10) {
            Button(action: { Task { await saveDraftAndDismiss() } }) {
                Text(LocalizedString("baseline_finish_later", lang))
                    .font(.headline)
                    .foregroundColor(AppColors.primary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppColors.secondarySurface)
                    .cornerRadius(16)
            }
            let remaining = totalCount - completedCount
            if remaining > 0 {
                Text(String(format: LocalizedString("followup_domains_missing_count", lang), remaining))
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .padding()
        .background(AppColors.background.ignoresSafeArea(edges: .bottom))
    }

    private var viewComparisonButton: some View {
        VStack(spacing: 10) {
            Button(action: { showComparison = true }) {
                Text(LocalizedString("followup_view_comparison", lang))
                    .font(.headline)
                    .foregroundColor(AppColors.primary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppColors.secondarySurface)
                    .cornerRadius(16)
            }
        }
        .padding()
        .background(AppColors.background.ignoresSafeArea(edges: .bottom))
    }

    // MARK: - Status helpers

    private func domainStatus(for domain: BaselineDomain) -> DomainCompletionStatus {
        let statusKey = DomainAnswerKey.status(domain.key)
        if let value = answers[statusKey]?.value as? String, value == "completed" {
            return .completed
        }
        let prefix = "\(domain.key)."
        let hasAnyAnswer = answers.keys.contains(where: { $0.hasPrefix(prefix) })
        return hasAnyAnswer ? .inProgress : .notStarted
    }

    private func statusColor(for status: DomainCompletionStatus) -> Color {
        switch status {
        case .notStarted: return AppColors.textSecondary
        case .inProgress: return Color.orange
        case .completed: return AppColors.success
        }
    }

    private func currentScore(for domainKey: String) -> Int? {
        answers[DomainAnswerKey.readiness(domainKey)]?.value as? Int
    }

    private func formattedScore(_ value: Int?) -> String {
        value.map { "\($0)/5" } ?? "—/5"
    }

    private func formattedDate(_ date: Date?) -> String {
        guard let date else { return "--" }
        return Self.dateFormatter.string(from: date)
    }

    // MARK: - Data Loading

    private func loadData() async {
        guard let unitId = appState.currentUnit?.id else {
            await MainActor.run {
                loadError = LocalizedString("followup_domains_error", lang)
                isLoading = false
            }
            return
        }
        do {
            let assessments = try await assessmentService.getAssessments(clientId: client.id)

            let baseline = assessments
                .filter { $0.assessmentType == "baseline" && $0.status == "completed" }
                .sorted(by: { ($0.completedAt ?? Date.distantPast) > ($1.completedAt ?? Date.distantPast) })
                .first

            let scores = parseDomainScores(from: baseline)
            var blAnswers: [String: AnyCodable] = [:]
            if scores.isEmpty, let baseline {
                let answerList = try await assessmentService.getAssessmentAnswers(assessmentId: baseline.id)
                for ans in answerList {
                    let key = "\(ans.domainKey).\(ans.questionKey)"
                    if let v = ans.value { blAnswers[key] = v }
                }
            }

            let currentAssessment: Assessment
            if let openId = openAssessmentId, let openAssessment = assessments.first(where: { $0.id == openId && $0.assessmentType == "followup" }) {
                currentAssessment = openAssessment
            } else if let draft = assessments.first(where: { $0.assessmentType == "followup" && ($0.status == "draft" || $0.status == "in_progress") }) {
                currentAssessment = draft
            } else {
                let staffId = appState.currentStaffProfile?.id
                currentAssessment = try await assessmentService.createAssessment(
                    clientId: client.id,
                    unitId: unitId,
                    type: "followup",
                    createdByStaffId: staffId
                )
            }

            let answerList = try await assessmentService.getAssessmentAnswers(assessmentId: currentAssessment.id)
            var dict: [String: AnyCodable] = [:]
            for ans in answerList {
                let key = "\(ans.domainKey).\(ans.questionKey)"
                if let v = ans.value { dict[key] = v }
            }

            var resolvedScores = scores
            if resolvedScores.isEmpty {
                for domain in allDomains {
                    let readinessKey = DomainAnswerKey.readiness(domain.key)
                    if let val = blAnswers[readinessKey]?.value as? Int {
                        resolvedScores[domain.key] = val
                    }
                }
            }

            await MainActor.run {
                self.assessment = currentAssessment
                self.answers = dict
                self.baselineScores = resolvedScores
                self.baselineAnswers = blAnswers
                self.baselineCompletion = baseline?.completedAt
                self.baselineAssessment = baseline
                self.isLoading = false
                self.staffNote = currentAssessment.notes ?? ""
            }
        } catch {
            await MainActor.run {
                loadError = error.localizedDescription
                isLoading = false
            }
        }
    }

    private func parseDomainScores(from assessment: Assessment?) -> [String: Int] {
        guard let dict = assessment?.domainScores else { return [:] }
        var result: [String: Int] = [:]
        for domain in allDomains {
            if let scoreDict = dict[domain.key]?.value as? [String: Any],
               let score = scoreDict["iScore"] as? Int {
                result[domain.key] = score
            }
        }
        return result
    }

    // MARK: - Actions

    private func saveDraftAndDismiss() async {
        guard let assessment else { return }
        saveError = nil
        let payloads = AssessmentAnswerPayloadBuilder.payloads(from: answers, assessmentId: assessment.id)
        do {
            try await assessmentService.upsertAnswers(payloads)
            await MainActor.run { dismiss() }
        } catch {
            await MainActor.run { saveError = error.localizedDescription }
        }
    }

    private func saveDraftNote() async {
        guard let assessment else { return }
        do {
            try await assessmentService.updateAssessment(
                id: assessment.id,
                status: nil,
                completedAt: nil,
                notes: staffNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : staffNote
            )
        } catch {
            await MainActor.run { saveError = error.localizedDescription }
        }
    }

    private func finishFollowUp() async {
        guard allDomainsCompleted, let assessment else { return }
        await MainActor.run { isFinishing = true }
        do {
            let payloads = AssessmentAnswerPayloadBuilder.payloads(from: answers, assessmentId: assessment.id)
            try await assessmentService.upsertAnswers(payloads)

            let now = Date()
            try await assessmentService.updateAssessment(
                id: assessment.id,
                status: "completed",
                completedAt: now,
                notes: staffNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : staffNote
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
                    eventType: "followup_completed",
                    title: LocalizedString("assessment_timeline_title_followup", lang),
                    description: String(format: LocalizedString("followup_timeline_description", lang), completedCount, totalCount),
                    staffId: staffId
                )
            }

            await MainActor.run {
                self.recommendations = recs
                self.domainScoresResult = scores
                self.isFinishing = false
                self.showSummary = false
                self.showComparison = true
            }
        } catch {
            await MainActor.run {
                saveError = error.localizedDescription
                isFinishing = false
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
}

private struct ErrorStateView: View {
    let message: String
    let lang: String
    let retry: () -> Void

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
