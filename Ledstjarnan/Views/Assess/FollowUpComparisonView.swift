//
//  FollowUpComparisonView.swift
//  Ledstjarnan
//
//  Compare baseline vs follow-up scores per domain.
//

import SwiftUI

struct FollowUpComparisonView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var appState: AppState
    let client: Client
    var initialBaseline: Assessment? = nil
    var initialFollowup: Assessment? = nil
    var initialBaselineAnswers: [String: AnyCodable]? = nil
    var initialFollowupAnswers: [String: AnyCodable]? = nil

    @State private var baseline: Assessment?
    @State private var followups: [Assessment] = []
    @State private var selectedFollowupId: String?

    @State private var baselineScores: [AssessmentDomainScore] = []
    @State private var followupScores: [AssessmentDomainScore] = []

    @State private var isLoading = true
    @State private var errorMessage: String?

    private let assessmentService = AssessmentService()
    @EnvironmentObject private var logicStore: LogicReferenceStore

    private var lang: String { appState.languageCode }

    private var salutogenicDomains: [AssessmentDomainDefinition] {
        AssessmentDefinition.salutogenicDomains(from: logicStore)
    }

    var body: some View {
        NavigationStack {
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

                            if followups.count > 1 {
                                Picker(LocalizedString("followup_comparison_followup_label", lang), selection: $selectedFollowupId) {
                                    ForEach(followups) { a in
                                        Text(followupLabel(for: a))
                                            .tag(Optional(a.id))
                                    }
                                }
                                .pickerStyle(.segmented)
                                .padding(.horizontal)
                                .onChange(of: selectedFollowupId) { _, newId in
                                    if let newId, let fu = followups.first(where: { $0.id == newId }) {
                                        Task { await loadScoresForFollowup(fu) }
                                    }
                                }
                            }

                            comparisonSection(
                                title: LocalizedString("baseline_section_salutogenic", lang),
                                domainKeys: BaselineDomainFlowConfig.salutogenicDomains.map(\.key)
                            )

                            comparisonSection(
                                title: LocalizedString("baseline_section_pathogenic", lang),
                                domainKeys: BaselineDomainFlowConfig.pathogenicDomains.map(\.key)
                            )

                            Spacer(minLength: 24)
                        }
                        .padding(.vertical, 16)
                    }
                }
            }
            .background(AppColors.background)
            .navigationTitle(LocalizedString("followup_comparison_title", lang))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(LocalizedString("general_close", lang)) { dismiss() }
                }
            }
            .task {
                if let bl = initialBaseline, let fu = initialFollowup {
                    let blA = initialBaselineAnswers ?? [:]
                    let fuA = initialFollowupAnswers ?? [:]
                    await MainActor.run {
                        self.baseline = bl
                        self.followups = [fu]
                        self.selectedFollowupId = fu.id
                        self.baselineScores = scoresFromReadiness(blA, fallbackAssessment: bl)
                        self.followupScores = scoresFromReadiness(fuA, fallbackAssessment: fu)
                        self.isLoading = false
                    }
                } else {
                    await loadData()
                }
            }
        }
    }

    @ViewBuilder
    private func comparisonSection(title: String, domainKeys: [String]) -> some View {
        let matchedRows: [(String, Double?, Double?)] = domainKeys.map { key in
            let domainTitle = BaselineDomainFlowConfig.allDomains.first(where: { $0.key == key })?.title(lang: lang)
                ?? logicStore.domain(forAppKey: key)?.label
                ?? key
            let base = baselineScores.first(where: { $0.domain.key == key })?.average
            let foll = followupScores.first(where: { $0.domain.key == key })?.average
            return (domainTitle, base, foll)
        }
        if !matchedRows.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                    .padding(.horizontal)
                ForEach(matchedRows, id: \.0) { row in
                    DomainComparisonRow(
                        title: row.0,
                        baseline: row.1,
                        followup: row.2,
                        lang: lang
                    )
                    .padding(.horizontal)
                }
            }
        }
    }

    private func loadData() async {
        isLoading = true
        errorMessage = nil

        do {
            let assessments = try await assessmentService.getAssessments(clientId: client.id)

            let baselines = assessments.filter { $0.assessmentType == "baseline" && $0.status == "completed" }
            let followupsAll = assessments
                .filter { $0.assessmentType == "followup" && $0.status == "completed" }
                .sorted(by: { ($0.completedAt ?? $0.createdAt ?? Date.distantPast) > ($1.completedAt ?? $1.createdAt ?? Date.distantPast) })

            guard let baseline = baselines.sorted(by: { ($0.completedAt ?? $0.createdAt ?? Date.distantPast) < ($1.completedAt ?? $1.createdAt ?? Date.distantPast) }).first,
                  let latestFollowUp = followupsAll.first else {
                await MainActor.run {
                    self.baseline = baselines.first
                    self.followups = followupsAll
                    self.isLoading = false
                }
                return
            }

            let baselineAnswers = try await answersDict(for: baseline.id)
            let followAnswers = try await answersDict(for: latestFollowUp.id)

            let baseScores = scoresFromReadiness(baselineAnswers, fallbackAssessment: baseline)
            let follScores = scoresFromReadiness(followAnswers, fallbackAssessment: latestFollowUp)

            await MainActor.run {
                self.baseline = baseline
                self.followups = followupsAll
                self.selectedFollowupId = latestFollowUp.id
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

    private func loadScoresForFollowup(_ followup: Assessment) async {
        do {
            guard let baseline else { return }
            let baselineAnswers = try await answersDict(for: baseline.id)
            let followAnswers = try await answersDict(for: followup.id)
            let baseScores = scoresFromReadiness(baselineAnswers, fallbackAssessment: baseline)
            let follScores = scoresFromReadiness(followAnswers, fallbackAssessment: followup)
            await MainActor.run {
                self.baselineScores = baseScores
                self.followupScores = follScores
            }
        } catch {
            await MainActor.run { errorMessage = error.localizedDescription }
        }
    }

    /// Build domain scores from readiness values (domain form), with fallback to assessment.domain_scores JSONB.
    private func scoresFromReadiness(_ answers: [String: AnyCodable], fallbackAssessment: Assessment? = nil) -> [AssessmentDomainScore] {
        BaselineDomainFlowConfig.allDomains.map { domain in
            let key = domain.key
            let readinessKey = DomainAnswerKey.readiness(key)
            var value = answers[readinessKey]?.value as? Int
            if value == nil, let dict = fallbackAssessment?.domainScores, let entry = dict[key] {
                if let scoreDict = entry.value as? [String: AnyCodable], let iScoreAny = scoreDict["iScore"] {
                    value = iScoreAny.value as? Int
                }
                if value == nil, let scoreDict = entry.value as? [String: Any], let i = scoreDict["iScore"] as? Int {
                    value = i
                }
            }
            let def = AssessmentDomainDefinition(
                key: key,
                title: domain.title(lang: lang),
                subtitle: domain.subtitle(lang: lang),
                icon: domain.icon,
                questions: []
            )
            return AssessmentDomainScore(
                domain: def,
                average: value.map { Double($0) },
                answeredCount: value != nil ? 1 : 0
            )
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
            return "Uppföljning \(format(date: completed))"
        }
        return "Uppföljning"
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
