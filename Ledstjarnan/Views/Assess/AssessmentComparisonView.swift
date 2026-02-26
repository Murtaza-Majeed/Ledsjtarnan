import SwiftUI

struct AssessmentComparisonView: View {
    let client: Client
    let baselineAssessment: Assessment
    let currentAssessment: Assessment
    @State private var baselineAnswers: [String: AnyCodable] = [:]
    @State private var currentAnswers: [String: AnyCodable] = [:]
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    @Environment(\.languageCode) var lang

    private let assessmentService = AssessmentService()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let error = errorMessage {
                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(.red)
                        .padding()
                }

                if isLoading {
                    ProgressView("Loading comparison...")
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    headerSection
                    ptsdComparisonSection
                    safetyFlagsSection
                    domainComparisonSection
                    recommendationsSection
                }
            }
            .padding(.vertical)
        }
        .background(AppColors.background)
        .navigationTitle(String(format: LocalizedString("comparison_progress_title", lang), client.displayName))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadData()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(LocalizedString("comparison_baseline", lang))
                        .font(.caption.bold())
                        .foregroundColor(AppColors.textSecondary)
                    Text(baselineAssessment.assessmentDate ?? "—")
                        .font(.subheadline)
                }
                Spacer()
                Image(systemName: "arrow.right")
                    .foregroundColor(AppColors.textSecondary)
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(LocalizedString("comparison_followup", lang))
                        .font(.caption.bold())
                        .foregroundColor(AppColors.textSecondary)
                    Text(currentAssessment.assessmentDate ?? "—")
                        .font(.subheadline)
                }
            }

            let daysBetween = daysBetween(
                start: baselineAssessment.completedAt,
                end: currentAssessment.completedAt
            )
            if let days = daysBetween {
                Text(String(format: LocalizedString("comparison_days_between", lang), days))
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .padding()
        .background(AppColors.mainSurface)
        .cornerRadius(12)
        .padding(.horizontal)
    }

    // MARK: - PTSD Comparison

    private var ptsdComparisonSection: some View {
        Group {
            if let baseScore = baselineAssessment.ptsdTotalScore,
               let currScore = currentAssessment.ptsdTotalScore {
                VStack(alignment: .leading, spacing: 12) {
                    Text(LocalizedString("comparison_ptsd_title", lang))
                        .font(.headline)
                        .padding(.horizontal)

                    HStack(spacing: 20) {
                        AssessmentPTSDScoreCard(
                            label: LocalizedString("comparison_baseline", lang),
                            score: baseScore,
                            isProbable: baselineAssessment.ptsdProbable ?? false,
                            lang: lang
                        )

                        Image(systemName: scoreChangeIcon(old: baseScore, new: currScore))
                            .foregroundColor(scoreChangeColor(old: baseScore, new: currScore))
                            .font(.title2)

                        AssessmentPTSDScoreCard(
                            label: LocalizedString("comparison_followup", lang),
                            score: currScore,
                            isProbable: currentAssessment.ptsdProbable ?? false,
                            lang: lang
                        )

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text(scoreDelta(old: baseScore, new: currScore))
                                .font(.title3.bold())
                                .foregroundColor(scoreChangeColor(old: baseScore, new: currScore))
                            Text(LocalizedString("comparison_change", lang))
                                .font(.caption2)
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                    .padding()
                    .background(AppColors.secondarySurface)
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
            }
        }
    }

    // MARK: - Safety Flags

    private var safetyFlagsSection: some View {
        Group {
            let currentFlags = parseSafetyFlags(currentAssessment.safetyFlags)
            if !currentFlags.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Label(LocalizedString("comparison_safety_warnings", lang), systemImage: "exclamationmark.triangle.fill")
                        .font(.headline)
                        .foregroundColor(.red)
                        .padding(.horizontal)

                    ForEach(currentFlags, id: \.message) { flag in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: flag.requiresAction ? "exclamationmark.circle.fill" : "bell.badge")
                                .foregroundColor(flag.requiresAction ? .red : .orange)
                            Text(flag.message)
                                .font(.subheadline)
                                .foregroundColor(AppColors.textPrimary)
                        }
                        .padding()
                        .background(flag.requiresAction ? Color.red.opacity(0.08) : Color.orange.opacity(0.08))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                }
            }
        }
    }

    // MARK: - Domain Comparison Table

    private var domainComparisonSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizedString("comparison_domains_change", lang))
                .font(.headline)
                .padding(.horizontal)

            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Text(LocalizedString("comparison_domain_header", lang))
                        .font(.caption.bold())
                        .foregroundColor(AppColors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(LocalizedString("comparison_baseline_short", lang))
                        .font(.caption.bold())
                        .foregroundColor(AppColors.textSecondary)
                        .frame(width: 40)
                    Text(LocalizedString("comparison_current_short", lang))
                        .font(.caption.bold())
                        .foregroundColor(AppColors.textSecondary)
                        .frame(width: 40)
                    Text(LocalizedString("comparison_delta", lang))
                        .font(.caption.bold())
                        .foregroundColor(AppColors.textSecondary)
                        .frame(width: 50)
                }
                .padding()
                .background(AppColors.mainSurface)

                Divider()

                ForEach(salutogenicComparisons, id: \.domainKey) { comp in
                    AssessmentDomainComparisonRow(comparison: comp, lang: lang)
                    Divider()
                }

                ForEach(problemComparisons, id: \.domainKey) { comp in
                    AssessmentDomainComparisonRow(comparison: comp, lang: lang)
                    Divider()
                }
            }
            .background(AppColors.secondarySurface)
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }

    // MARK: - Recommendations

    private var recommendationsSection: some View {
        Group {
            if let summary = currentAssessment.interventionSummary,
               !summary.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text(LocalizedString("comparison_recommendations", lang))
                        .font(.headline)
                        .padding(.horizontal)

                    ForEach(Array(summary.keys.sorted()), id: \.self) { key in
                        if let recDict = summary[key]?.value as? [String: Any] {
                            AssessmentRecommendationSummaryCard(domainKey: key, data: recDict, lang: lang)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Data Loading

    private func loadData() async {
        isLoading = true
        errorMessage = nil
        do {
            let baseAnswers = try await assessmentService.getAssessmentAnswers(assessmentId: baselineAssessment.id)
            let currAnswers = try await assessmentService.getAssessmentAnswers(assessmentId: currentAssessment.id)

            var baseDict: [String: AnyCodable] = [:]
            var currDict: [String: AnyCodable] = [:]

            for ans in baseAnswers {
                let key = "\(ans.domainKey).\(ans.questionKey)"
                if let v = ans.value { baseDict[key] = v }
            }

            for ans in currAnswers {
                let key = "\(ans.domainKey).\(ans.questionKey)"
                if let v = ans.value { currDict[key] = v }
            }

            await MainActor.run {
                baselineAnswers = baseDict
                currentAnswers = currDict
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }

    // MARK: - Comparison Data

    private var salutogenicComparisons: [AssessmentDomainComparison] {
        AssessmentDefinition.domains.map { domain in
            let baseScore = baselineAnswers["\(domain.key).staffNeedScore"]?.value as? Int ?? 3
            let currScore = currentAnswers["\(domain.key).staffNeedScore"]?.value as? Int ?? 3
            return AssessmentDomainComparison(
                domainKey: domain.key,
                domainTitle: domain.title,
                baselineScore: baseScore,
                currentScore: currScore,
                isSalutogenic: true
            )
        }
    }

    private var problemComparisons: [AssessmentDomainComparison] {
        AssessmentDefinition.pathogenicModules.map { module in
            let baseScore = baselineAnswers["\(module.key).staffNeedScore"]?.value as? Int ?? 1
            let currScore = currentAnswers["\(module.key).staffNeedScore"]?.value as? Int ?? 1
            return AssessmentDomainComparison(
                domainKey: module.key,
                domainTitle: module.title,
                baselineScore: baseScore,
                currentScore: currScore,
                isSalutogenic: false
            )
        }
    }

    // MARK: - Helpers

    private func daysBetween(start: Date?, end: Date?) -> Int? {
        guard let s = start, let e = end else { return nil }
        return Calendar.current.dateComponents([.day], from: s, to: e).day
    }

    private func scoreChangeIcon(old: Int, new: Int) -> String {
        if new < old { return "arrow.down.circle.fill" }
        if new > old { return "arrow.up.circle.fill" }
        return "minus.circle.fill"
    }

    private func scoreChangeColor(old: Int, new: Int) -> Color {
        if new < old { return .green }  // Lower PTSD score = improvement
        if new > old { return .red }
        return .gray
    }

    private func scoreDelta(old: Int, new: Int) -> String {
        let delta = new - old
        if delta > 0 { return "+\(delta)" }
        if delta < 0 { return "\(delta)" }
        return "0"
    }

    private func parseSafetyFlags(_ jsonb: [[String: AnyCodable]]?) -> [(message: String, requiresAction: Bool)] {
        guard let flags = jsonb else { return [] }
        return flags.compactMap { dict in
            guard let msg = dict["message"]?.value as? String,
                  let req = dict["requiresAction"]?.value as? Bool else { return nil }
            return (msg, req)
        }
    }
}

// MARK: - Supporting Views

struct AssessmentPTSDScoreCard: View {
    let label: String
    let score: Int
    let isProbable: Bool
    let lang: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(AppColors.textSecondary)
            Text("\(score)")
                .font(.title.bold())
                .foregroundColor(isProbable ? .red : AppColors.textPrimary)
            if isProbable {
                Text(LocalizedString("comparison_probable_ptsd", lang))
                    .font(.caption2.bold())
                    .foregroundColor(.red)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct AssessmentDomainComparison: Identifiable {
    let id = UUID()
    let domainKey: String
    let domainTitle: String
    let baselineScore: Int
    let currentScore: Int
    let isSalutogenic: Bool

    var delta: Int { currentScore - baselineScore }

    // For salutogenic: increase is good (5 is best)
    // For pathogenic: decrease is good (1 is best)
    var normalisedDelta: Int { isSalutogenic ? delta : -delta }

    var icon: String {
        if normalisedDelta > 0 { return "arrow.up.circle.fill" }
        if normalisedDelta < 0 { return "arrow.down.circle.fill" }
        return "minus.circle.fill"
    }

    var iconColor: Color {
        if normalisedDelta > 0 { return .green }
        if normalisedDelta < 0 { return .red }
        return .gray
    }

    var isWorsenedBy2Plus: Bool {
        isSalutogenic ? delta <= -2 : delta >= 2
    }

    var needsAttentionNow: Bool {
        isSalutogenic ? currentScore <= 2 : currentScore >= 4
    }
}

struct AssessmentDomainComparisonRow: View {
    let comparison: AssessmentDomainComparison
    let lang: String

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(comparison.domainTitle)
                        .font(.subheadline)
                        .foregroundColor(AppColors.textPrimary)
                    if comparison.isWorsenedBy2Plus {
                        Text("⚠︎")
                            .font(.caption.bold())
                            .foregroundColor(.red)
                            .accessibilityLabel(LocalizedString("comparison_worsened_warning", lang))
                    }
                }
                if comparison.needsAttentionNow {
                    Text(LocalizedString("comparison_needs_attention", lang))
                        .font(.caption2)
                        .foregroundColor(.red)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text("\(comparison.baselineScore)")
                .font(.subheadline.monospacedDigit())
                .foregroundColor(AppColors.textSecondary)
                .frame(width: 40)

            Text("\(comparison.currentScore)")
                .font(.subheadline.bold().monospacedDigit())
                .foregroundColor(comparison.needsAttentionNow ? .red : AppColors.textPrimary)
                .frame(width: 40)

            HStack(spacing: 4) {
                Image(systemName: comparison.icon)
                    .foregroundColor(comparison.iconColor)
                    .font(.caption)
                Text(comparison.delta > 0 ? "+\(comparison.delta)" : "\(comparison.delta)")
                    .font(.caption.monospacedDigit())
                    .foregroundColor(comparison.iconColor)
            }
            .frame(width: 50)
        }
        .padding(.vertical, 12)
        .padding(.horizontal)
        .background(comparison.isWorsenedBy2Plus ? Color.red.opacity(0.06) : Color.clear)
    }
}

struct AssessmentRecommendationSummaryCard: View {
    let domainKey: String
    let data: [String: Any]
    let lang: String

    private var interventions: [String] {
        data["interventions"] as? [String] ?? []
    }

    private var isUrgent: Bool {
        data["isUrgent"] as? Bool ?? false
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(domainTitle)
                    .font(.subheadline.bold())
                Spacer()
                if isUrgent {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }

            FlowLayout(spacing: 6) {
                ForEach(interventions, id: \.self) { intervention in
                    Text(intervention)
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppColors.secondarySurface)
                        .foregroundColor(AppColors.textPrimary)
                        .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(AppColors.mainSurface)
        .cornerRadius(10)
        .padding(.horizontal)
    }

    private var domainTitle: String {
        switch domainKey {
        case "health": return LocalizedString("domain_health", lang)
        case "education": return LocalizedString("domain_education", lang)
        case "social": return LocalizedString("domain_social", lang)
        case "independence": return LocalizedString("domain_independence", lang)
        case "relationships": return LocalizedString("domain_relationships", lang)
        case "identity": return LocalizedString("domain_identity", lang)
        case "substance": return LocalizedString("domain_substance", lang)
        case "attachment": return LocalizedString("domain_attachment", lang)
        case "mentalHealth": return LocalizedString("domain_mental_health", lang)
        case "severeMentalHealth": return LocalizedString("domain_severe_mental_health", lang)
        case "trauma": return LocalizedString("domain_trauma", lang)
        default: return domainKey
        }
    }
}
