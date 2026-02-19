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
    private let moduleLookup: [String: AssessmentModule] = {
        Dictionary(uniqueKeysWithValues: AssessmentDefinition.salutogenicModules.map { ($0.key, $0) })
    }()

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
                title: moduleLookup[domain.key]?.title ?? domain.title,
                valueText: now.map { "\($0)/5" } ?? "—",
                isCompleted: now != nil
            )
        }
    }

    private var summaryComparisonDomains: [FollowUpSummaryDomain] {
        domains.map { domain in
            FollowUpSummaryDomain(
                title: moduleLookup[domain.key]?.title ?? domain.title,
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
                ProgressView("Loading follow-up…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let loadError {
                ErrorStateView(message: loadError) {
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
                collected.append("\(domain.title): \(note)")
            }
        }
        return collected.isEmpty ? "No notes yet." : collected.joined(separator: "\n")
    }

    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                Label("Back", systemImage: "chevron.left")
                    .font(.subheadline.weight(.semibold))
            }
            .tint(AppColors.textPrimary)
            Spacer()
            Text("Follow-up Assessment")
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
            Text("Baseline: \(baselineDateText)")
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
            Text("Follow-up: \(followupDateText)")
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
            Text("Update the domains (same as baseline).")
                .font(.subheadline)
            Text("You can see the previous score for comparison.")
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(.horizontal)
    }

    private var domainList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Domains")
                .font(.headline)
                .padding(.horizontal)
            ForEach(domains) { domain in
                Button {
                    selectedDomain = domain
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(moduleLookup[domain.key]?.title ?? domain.title)
                                .font(.headline)
                            if let subtitle = moduleLookup[domain.key]?.subtitle {
                                Text(subtitle)
                                    .font(.caption)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            Text("Prev: \(formattedScore(baselineScores[domain.key]))   Now: \(formattedScore(currentScore(for: domain.key)))")
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
                Text("Review summary")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(missingDomainCount == 0 ? AppColors.primary : AppColors.secondarySurface)
                    .foregroundColor(missingDomainCount == 0 ? AppColors.onPrimary : AppColors.textPrimary)
                    .cornerRadius(16)
            }
            .disabled(missingDomainCount > 0)
            if missingDomainCount > 0 {
                Text("\(missingDomainCount) domains missing")
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
                loadError = "Select a unit first."
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
                    title: "Follow-up completed",
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
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text(message)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(AppColors.textSecondary)
            Button("Retry", action: retry)
                .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
