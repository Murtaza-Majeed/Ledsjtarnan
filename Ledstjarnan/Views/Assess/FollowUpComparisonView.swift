//
//  FollowUpComparisonView.swift
//  Ledstjarnan
//
//  Compare baseline vs follow-up scores per domain.
//

import SwiftUI

struct FollowUpComparisonView: View {
    @ObservedObject var appState: AppState
    let client: Client

    @State private var baseline: Assessment?
    @State private var followups: [Assessment] = []
    @State private var selectedFollowupId: String?

    @State private var baselineScores: [AssessmentDomainScore] = []
    @State private var followupScores: [AssessmentDomainScore] = []

    @State private var isLoading = true
    @State private var errorMessage: String?

    private let assessmentService = AssessmentService()
    
    private var lang: String { appState.languageCode }

    var body: some View {
        Group {
            if isLoading {
                ProgressView(LocalizedString("general_loading", lang))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage {
                Text(errorMessage)
                    .font(.subheadline)
                    .foregroundColor(AppColors.danger)
                    .padding()
            } else if baseline == nil || followups.isEmpty {
                VStack(spacing: 12) {
                    Text(LocalizedString("followup_comparison_no_pair", lang))
                        .font(.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                    Text(LocalizedString("followup_comparison_complete_message", lang))
                        .font(.footnote)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if let baselineDate = baseline?.completedAt {
                            Text(String(format: LocalizedString("followup_comparison_baseline_completed", lang), format(date: baselineDate)))
                                .font(.footnote)
                                .foregroundColor(AppColors.textSecondary)
                                .padding(.horizontal)
                        }

                        if !followups.isEmpty {
                            Picker(LocalizedString("followup_comparison_followup_label", lang), selection: $selectedFollowupId) {
                                ForEach(followups) { a in
                                    Text(followupLabel(for: a))
                                        .tag(Optional(a.id))
                                }
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text(LocalizedString("followup_comparison_domain_comparison", lang))
                                .font(.headline)
                                .padding(.horizontal)
                            Text(LocalizedString("followup_comparison_scale_description", lang))
                                .font(.caption)
                                .foregroundColor(AppColors.textSecondary)
                                .padding(.horizontal)
                        }

                        ForEach(AssessmentDefinition.domains, id: \.key) { domain in
                            if let base = baselineScores.first(where: { $0.domain.key == domain.key }),
                               let foll = followupScores.first(where: { $0.domain.key == domain.key }) {
                                DomainComparisonRow(
                                    title: domain.title,
                                    baseline: base.average,
                                    followup: foll.average,
                                    lang: lang
                                )
                                .padding(.horizontal)
                            }
                        }

                        Spacer(minLength: 24)
                    }
                    .padding(.vertical, 16)
                }
            }
        }
        .background(AppColors.background)
        .navigationTitle(LocalizedString("followup_comparison_title", lang))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadData()
        }
    }

    private func loadData() async {
        isLoading = true
        errorMessage = nil

        do {
            let assessments = try await assessmentService.getAssessments(clientId: client.id)

            let baselines = assessments.filter { $0.assessmentType == "baseline" && $0.status == "completed" }
            let followupsAll = assessments.filter { $0.assessmentType == "followup" && $0.status == "completed" }

            guard let baseline = baselines.sorted(by: { ($0.completedAt ?? $0.createdAt ?? Date.distantPast) < ($1.completedAt ?? $1.createdAt ?? Date.distantPast) }).first,
                  !followupsAll.isEmpty else {
                await MainActor.run {
                    self.baseline = baselines.first
                    self.followups = followupsAll
                    self.isLoading = false
                }
                return
            }

            let selectedFollowup = followupsAll.sorted(by: { ($0.completedAt ?? $0.createdAt ?? Date.distantPast) > ($1.completedAt ?? $1.createdAt ?? Date.distantPast) }).first!

            let baselineAnswers = try await answersDict(for: baseline.id)
            let followAnswers = try await answersDict(for: selectedFollowup.id)

            let baseScores = AssessmentDefinition.scores(from: baselineAnswers)
            let follScores = AssessmentDefinition.scores(from: followAnswers)

            await MainActor.run {
                self.baseline = baseline
                self.followups = followupsAll
                self.selectedFollowupId = selectedFollowup.id
                self.baselineScores = baseScores
                self.followupScores = follScores
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    private func answersDict(for assessmentId: String) async throws -> [String: AnyCodable] {
        let list = try await assessmentService.getAssessmentAnswers(assessmentId: assessmentId)
        var dict: [String: AnyCodable] = [:]
        for ans in list {
            let key = "\(ans.domainKey).\(ans.questionKey)"
            if let v = ans.value { dict[key] = v }
        }
        return dict
    }

    private func followupLabel(for a: Assessment) -> String {
        if let completed = a.completedAt {
            return "Follow-up \(format(date: completed))"
        }
        return "Follow-up"
    }

    private func format(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

private struct DomainComparisonRow: View {
    let title: String
    let baseline: Double?
    let followup: Double?
    let lang: String

    private var delta: Double? {
        guard let b = baseline, let f = followup else { return nil }
        return f - b
    }

    private var deltaColor: Color {
        guard let d = delta else { return AppColors.textSecondary }
        // Lower need (followup < baseline) is good → green
        if d < -0.2 { return .green }
        if d > 0.2 { return .red }
        return AppColors.textSecondary
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(AppColors.textPrimary)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(LocalizedString("followup_comparison_baseline_label", lang))
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                    Text(formatted(baseline))
                        .font(.body.bold())
                        .foregroundColor(AppColors.textPrimary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(LocalizedString("followup_comparison_followup_label", lang))
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                    Text(formatted(followup))
                        .font(.body.bold())
                        .foregroundColor(AppColors.textPrimary)
                }
                if let d = delta {
                    Text(String(format: "%+.1f", d))
                        .font(.caption.bold())
                        .foregroundColor(deltaColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(deltaColor.opacity(0.1))
                        .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(AppColors.mainSurface)
        .cornerRadius(12)
    }

    private func formatted(_ value: Double?) -> String {
        guard let v = value else { return "—" }
        return String(format: "%.1f", v)
    }
}
