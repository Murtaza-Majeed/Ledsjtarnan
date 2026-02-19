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

    @State private var assessment: Assessment?
    @State private var answers: [String: AnyCodable] = [:]
    @State private var isLoading = true
    @State private var loadError: String?
    @State private var saveError: String?
    @State private var isSavingDraft = false
    @State private var selectedDomain: BaselineDomain?

    private let assessmentService = AssessmentService()
    private let salutogenicDomains = BaselineDomainFlowConfig.salutogenicDomains
    private let pathogenicDomains = BaselineDomainFlowConfig.pathogenicDomains

    private var completedCount: Int {
        BaselineDomainFlowConfig.allDomains.filter { status(for: $0) == .completed }.count
    }

    private var totalCount: Int { BaselineDomainFlowConfig.allDomains.count }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            if isLoading {
                ProgressView("Loading baseline…")
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
                        domainSection(title: "Salutogena kapital", domains: salutogenicDomains)
                        domainSection(title: "Patogena kapital", domains: pathogenicDomains)
                    }
                    .padding(.vertical, 16)
                }
                finishLaterButton
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
    }

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Label("Back", systemImage: "chevron.left")
                    .font(.subheadline.weight(.semibold))
            }
            .tint(AppColors.textPrimary)

            Spacer()
            VStack(spacing: 2) {
                Text("Baseline domains")
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
            Text("Progress: \(completedCount)/\(totalCount) completed")
                .font(.subheadline.weight(.semibold))
            ProgressView(value: Double(completedCount), total: Double(totalCount))
                .accentColor(AppColors.primary)
            if let assessment, assessment.status == "completed" {
                Label("Baseline completed \(formattedDate(assessment.completedAt))", systemImage: "checkmark.seal.fill")
                    .font(.caption)
                    .foregroundColor(AppColors.success)
            } else {
                Text("Baseline stays in draft until all domains are completed.")
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

    private func domainSection(title: String, domains: [BaselineDomain]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title3.bold())
                .padding(.horizontal)
            VStack(spacing: 12) {
                ForEach(domains) { domain in
                    Button {
                        if assessment != nil {
                            selectedDomain = domain
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
                                Text(status(for: domain).label)
                                    .font(.caption2)
                                    .foregroundColor(color(for: status(for: domain)))
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
                    Text("Finish later")
                        .font(.headline)
                        .foregroundColor(AppColors.primary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppColors.secondarySurface)
                .cornerRadius(16)
            }
            .disabled(isSavingDraft)
            Text("Saves your progress and returns to Assess dashboard.")
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
            let existing = list.first { $0.assessmentType == "baseline" && $0.status != "completed" }
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
