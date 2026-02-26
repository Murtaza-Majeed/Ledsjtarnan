//
//  InsatskartraView.swift
//  Ledstjarnan
//
//  Insatskarta results screen — shows after assessment completion.
//  Displays safety flags, PTSD summary, and intervention recommendations per domain.
//

import SwiftUI

struct InsatskartraView: View {
    let recommendations: [InterventionRecommendation]
    let safetyFlags: [SafetyFlag]
    let ptsd: PTSDEvaluation
    let clientName: String
    @Environment(\.dismiss) var dismiss
    @Environment(\.languageCode) var lang

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // Safety flags first — always at top
                    if !safetyFlags.isEmpty {
                        safetyFlagsSection
                    }

                    // PTSD summary
                    if ptsd.requiresPsychologist {
                        ptsdSummaryCard
                    }

                    // Intervention recommendations
                    Text(LocalizedString("insatskarta_recommendations", lang))
                        .font(.title2.bold())
                        .padding(.horizontal)

                    ForEach(recommendations) { rec in
                        RecommendationCard(recommendation: rec)
                    }

                    Spacer(minLength: 40)
                }
                .padding(.vertical)
            }
            .background(AppColors.background)
            .navigationTitle(String(format: LocalizedString("insatskarta_title", lang), clientName))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizedString("insatskarta_close", lang)) { dismiss() }
                }
            }
        }
    }

    private var safetyFlagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(LocalizedString("insatskarta_safety_required", lang), systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundColor(AppColors.onDanger)
                .padding(.horizontal)

            ForEach(safetyFlags) { flag in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: flag.requiresImmediateAction ?
                          "exclamationmark.circle.fill" : "bell.badge.fill")
                        .foregroundColor(flag.requiresImmediateAction ? .red : .orange)
                        .font(.title3)
                    Text(flag.message)
                        .font(.subheadline)
                        .foregroundColor(AppColors.textPrimary)
                }
                .padding()
                .background(flag.requiresImmediateAction ?
                    Color.red.opacity(0.1) : Color.orange.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 16)
        .background(Color.red.opacity(0.05))
        .cornerRadius(16)
        .padding(.horizontal)
    }

    private var ptsdSummaryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(LocalizedString("insatskarta_stress_trauma", lang), systemImage: "brain")
                .font(.headline)
                .foregroundColor(AppColors.textPrimary)

            HStack(spacing: 16) {
                PTSDCriterionBadge(label: "B", met: ptsd.criterionBMet, description: LocalizedString("insatskarta_criterion_b", lang))
                PTSDCriterionBadge(label: "C", met: ptsd.criterionCMet, description: LocalizedString("insatskarta_criterion_c", lang))
                PTSDCriterionBadge(label: "D", met: ptsd.criterionDMet, description: LocalizedString("insatskarta_criterion_d", lang))
                PTSDCriterionBadge(label: "E", met: ptsd.criterionEMet, description: LocalizedString("insatskarta_criterion_e", lang))
            }

            HStack {
                Text(LocalizedString("insatskarta_total_symptom_score", lang))
                    .font(.subheadline)
                    .foregroundColor(AppColors.textSecondary)
                Text("\(ptsd.totalSymptomScore)")
                    .font(.subheadline.bold())
            }

            if ptsd.probablePTSD {
                Label(LocalizedString("insatskarta_ptsd_probable", lang), systemImage: "exclamationmark.triangle")
                    .font(.subheadline.bold())
                    .foregroundColor(.red)
            } else if ptsd.partialPTSD {
                let metCount = [ptsd.criterionBMet, ptsd.criterionCMet, ptsd.criterionDMet, ptsd.criterionEMet].filter { $0 }.count
                Label(String(format: LocalizedString("insatskarta_ptsd_partial", lang), metCount), systemImage: "exclamationmark.circle")
                    .font(.subheadline)
                    .foregroundColor(.orange)
            }
        }
        .padding()
        .background(AppColors.mainSurface)
        .cornerRadius(14)
        .padding(.horizontal)
    }
}

struct PTSDCriterionBadge: View {
    let label: String
    let met: Bool
    let description: String

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.headline.bold())
                .foregroundColor(met ? AppColors.onDanger : AppColors.textSecondary)
                .frame(width: 36, height: 36)
                .background(met ? AppColors.danger : AppColors.secondarySurface)
                .cornerRadius(8)
            Text(description)
                .font(.caption2)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }
}

struct RecommendationCard: View {
    let recommendation: InterventionRecommendation

    private var needColor: Color {
        switch recommendation.needLevel {
        case .low: return .green
        case .mediumLow: return .yellow
        case .mediumHigh: return .orange
        case .high: return .red
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(recommendation.domainTitle)
                        .font(.headline)
                        .foregroundColor(AppColors.textPrimary)
                    Text(recommendation.needLevel.rawValue)
                        .font(.caption)
                        .foregroundColor(needColor)
                        .bold()
                }
                Spacer()
                if recommendation.isUrgent {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.red)
                }
            }

            FlowLayout(spacing: 6) {
                ForEach(recommendation.interventions) { intervention in
                    Text(intervention.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(intervention.isSpecialist ?
                            Color.red.opacity(0.12) : AppColors.secondarySurface)
                        .foregroundColor(intervention.isSpecialist ? .red : AppColors.textPrimary)
                        .cornerRadius(20)
                }
            }

            if !recommendation.notes.isEmpty {
                Text(recommendation.notes)
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .padding()
        .background(AppColors.mainSurface)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(recommendation.isUrgent ? Color.red.opacity(0.4) : Color.clear, lineWidth: 1.5)
        )
        .padding(.horizontal)
    }
}

// MARK: - Flow layout for intervention tags

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var totalHeight: CGFloat = 0
        var maxWidth: CGFloat = 0
        for row in rows {
            let rowHeight = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            let rowWidth = row.reduce(CGFloat(0)) { $0 + $1.sizeThatFits(.unspecified).width + spacing } - spacing
            maxWidth = max(maxWidth, rowWidth)
            totalHeight += rowHeight + spacing
        }
        if !rows.isEmpty { totalHeight -= spacing }
        return CGSize(width: max(maxWidth, 0), height: max(totalHeight, 0))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var origin = bounds.origin
        let rows = computeRows(proposal: proposal, subviews: subviews)
        for row in rows {
            origin.x = bounds.origin.x
            let rowHeight = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            for view in row {
                let size = view.sizeThatFits(.unspecified)
                view.place(at: origin, proposal: ProposedViewSize(size))
                origin.x += size.width + spacing
            }
            origin.y += rowHeight + spacing
        }
    }

    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [[LayoutSubviews.Element]] {
        var rows: [[LayoutSubviews.Element]] = [[]]
        var currentX: CGFloat = 0
        let maxWidth = proposal.width ?? .infinity
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth && !rows[rows.endIndex - 1].isEmpty {
                rows.append([])
                currentX = 0
            }
            rows[rows.endIndex - 1].append(view)
            currentX += size.width + spacing
        }
        return rows
    }
}
