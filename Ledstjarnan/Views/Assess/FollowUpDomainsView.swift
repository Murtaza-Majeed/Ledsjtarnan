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

    @State private var assessment: Assessment?
    @State private var answers: [String: AnyCodable] = [:]
    @State private var baselineScores: [String: Int] = [:]
    @State private var isLoading = true
    @State private var loadError: String?
    @State private var selectedDomain: BaselineDomain?
    @State private var showSummary = false
    @State private var staffNote: String = ""
    @State private var isFinishing = false

    private let assessmentService = AssessmentService()
    private let clientService = ClientService()
    private let domains = BaselineDomainFlowConfig.salutogenicDomains
    @EnvironmentObject private var logicStore: LogicReferenceStore

    private var baselineDateText: String {
        guard let baseline = baselineCompletedDate else { return "—" }
        return Self.dateFormatter.string(from: baseline)
    }

    private var followupDateText: String {
        guard let date = assessment?.createdAt else { return "—" }
        return Self.dateFormatter.string(from: date)
    }

    private var baselineCompletedDate: Date? {
        baselineCompletion
    }

    @State private var baselineCompletion: Date?

    private var missingDomainCount: Int {
        domains.reduce(0) { count, domain in
            let now = currentScore(for: domain.key)
            return now == nil ? count + 1 : count
        }
    }

    private var summaryDomains: [AssessmentSummaryDomain] {
        domains.map { domain in
            let now = currentScore(for: domain.key)
            return AssessmentSummaryDomain(
                domainKey: domain.key,
                title: logicStore.domain(forAppKey: domain.key)?.label ?? domain.title(lang: appState.languageCode),
                valueText: now.map { "\($0)/5" } ?? "—",
                isCompleted: now != nil
            )
        }
    }

    private var summaryComparisonDomains: [FollowUpSummaryDomain] {
        domains.map { domain in
            FollowUpSummaryDomain(
                title: logicStore.domain(forAppKey: domain.key)?.label ?? domain.title(lang: appState.languageCode),
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
                ProgressView(LocalizedString("followup_domains_loading", appState.languageCode))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let loadError {
                ErrorStateView(message: loadError, lang: appState.languageCode) {
                    Task { await loadData() }
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        headerCard
                        instructions
                        domainList
                    }
                    .padding(.vertical, 24)
                }
                reviewButton
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
        .sheet(isPresented: $showSummary) {
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
                canFinish: missingDomainCount == 0,
                isFinishing: isFinishing
            )
        }
    }

    private var followUpNotesSummary: String {
        var collected: [String] = []
        for domain in domains {
            let notesKey = DomainAnswerKey.notes(domain.key)
            if let note = answers[notesKey]?.value as? String,
               !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                collected.append("\(domain.title(lang: appState.languageCode)): \(note)")
            }
        }
        return collected.isEmpty ? LocalizedString("summary_no_notes", appState.languageCode) : collected.joined(separator: "\n")
    }

    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                Label(LocalizedString("general_back", appState.languageCode), systemImage: "chevron.left")
                    .font(.subheadline.weight(.semibold))
            }
            .tint(AppColors.textPrimary)
            Spacer()
            Text(LocalizedString("followup_domains_assessment_title", appState.languageCode))
                .font(.headline)
            Spacer()
            Spacer().frame(width: 44)
        }
        .padding()
        .background(AppColors.mainSurface)
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(client.displayName)
                .font(.title3.bold())
            Text(String(format: LocalizedString("followup_domains_baseline_date", appState.languageCode), baselineDateText))
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
            Text(String(format: LocalizedString("followup_domains_followup_date", appState.languageCode), followupDateText))
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.mainSurface)
        .cornerRadius(24)
        .padding(.horizontal)
    }

    private var instructions: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(LocalizedString("followup_domains_update_instruction", appState.languageCode))
                .font(.subheadline)
            Text(LocalizedString("followup_domains_previous_score_hint", appState.languageCode))
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(.horizontal)
    }

    private var domainList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizedString("followup_domains_section_title", appState.languageCode))
                .font(.headline)
                .padding(.horizontal)
            ForEach(domains) { domain in
                Button {
                    selectedDomain = domain
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(logicStore.domain(forAppKey: domain.key)?.label ?? domain.title(lang: appState.languageCode))
                                .font(.headline)
                            if let desc = logicStore.domain(forAppKey: domain.key)?.description {
                                Text(desc)
                                    .font(.caption)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            Text(String(format: LocalizedString("followup_domains_score_comparison", appState.languageCode), formattedScore(baselineScores[domain.key]), formattedScore(currentScore(for: domain.key))))
                                .font(.caption)
                                .foregroundColor(AppColors.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppColors.mainSurface)
                    .cornerRadius(18)
                    .padding(.horizontal)
                }
            }
        }
    }

    private var reviewButton: some View {
        VStack(spacing: 10) {
            Button {
                showSummary = true
            } label: {
                Text(LocalizedString("followup_domains_review_summary", appState.languageCode))
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(missingDomainCount == 0 ? AppColors.primary : AppColors.secondarySurface)
                    .foregroundColor(missingDomainCount == 0 ? AppColors.onPrimary : AppColors.textPrimary)
                    .cornerRadius(16)
            }
            .disabled(missingDomainCount > 0)
            if missingDomainCount > 0 {
                Text(String(format: LocalizedString("followup_domains_missing_count", appState.languageCode), missingDomainCount))
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .padding()
        .background(AppColors.background.ignoresSafeArea(edges: .bottom))
    }

    private func formattedScore(_ value: Int?) -> String {
        if let value {
            return "\(value)/5"
        }
        return "—/5"
    }

    private func currentScore(for domainKey: String) -> Int? {
        if let value = answers[DomainAnswerKey.readiness(domainKey)]?.value as? Int {
            return value
        }
        return nil
    }

    private func loadData() async {
        guard let unitId = appState.currentUnit?.id else {
            await MainActor.run {
                loadError = LocalizedString("followup_domains_error", appState.languageCode)
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
            let baselineScores = parseDomainScores(from: baseline)
            let followUpExisting = assessments.first { $0.assessmentType == "followup" && $0.status != "archived" }
            let currentAssessment: Assessment
            if let followUp = followUpExisting {
                currentAssessment = followUp
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
            await MainActor.run {
                self.assessment = currentAssessment
                self.answers = dict
                self.baselineScores = baselineScores
                self.baselineCompletion = baseline?.completedAt
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
        for domain in domains {
            if let scoreDict = dict[domain.key]?.value as? [String: Any],
               let score = scoreDict["iScore"] as? Int {
                result[domain.key] = score
            }
        }
        return result
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
            await MainActor.run {
                loadError = error.localizedDescription
            }
        }
    }

    private func finishFollowUp() async {
        guard missingDomainCount == 0, let assessment else { return }
        await MainActor.run { isFinishing = true }
        do {
            let now = Date()
            try await assessmentService.updateAssessment(
                id: assessment.id,
                status: "completed",
                completedAt: now,
                notes: staffNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : staffNote
            )
            if let unitId = appState.currentUnit?.id,
               let staffId = appState.currentStaffProfile?.id {
                try? await clientService.createTimelineEvent(
                    clientId: client.id,
                    unitId: unitId,
                    eventType: "followup_completed",
                    title: LocalizedString("assessment_timeline_title_followup", appState.languageCode),
                    description: "Follow-up recorded \(Self.dateFormatter.string(from: now)).",
                    staffId: staffId
                )
            }
            await MainActor.run {
                isFinishing = false
                showSummary = false
                dismiss()
            }
        } catch {
            await MainActor.run {
                loadError = error.localizedDescription
                isFinishing = false
            }
        }
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
