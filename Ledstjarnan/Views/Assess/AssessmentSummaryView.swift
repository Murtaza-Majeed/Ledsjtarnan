//
//  AssessmentSummaryView.swift
//  Ledstjarnan
//

import SwiftUI

struct AssessmentSummaryDomain: Identifiable {
    let id = UUID()
    let domainKey: String
    let title: String
    let valueText: String
    let isCompleted: Bool
}

struct AssessmentSummaryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.languageCode) var lang

    let client: Client
    let assessmentType: String
    let completedCount: Int
    let totalCount: Int
    let domains: [AssessmentSummaryDomain]
    let problemDomains: [AssessmentSummaryDomain]
    let keyNotes: String
    let missingDomainCount: Int
    let canViewRecommendation: Bool
    let onDomainTapped: (String) -> Void
    let onViewRecommendation: () -> Void
    let onFinish: () -> Void
    let isFinishing: Bool
    let showsFinishButton: Bool

    init(
        client: Client,
        assessmentType: String,
        completedCount: Int,
        totalCount: Int,
        domains: [AssessmentSummaryDomain],
        keyNotes: String,
        problemDomains: [AssessmentSummaryDomain] = [],
        missingDomainCount: Int,
        canViewRecommendation: Bool,
        onDomainTapped: @escaping (String) -> Void,
        onViewRecommendation: @escaping () -> Void,
        onFinish: @escaping () -> Void,
        isFinishing: Bool,
        showsFinishButton: Bool = true
    ) {
        self.client = client
        self.assessmentType = assessmentType
        self.completedCount = completedCount
        self.totalCount = totalCount
        self.domains = domains
        self.problemDomains = problemDomains
        self.keyNotes = keyNotes
        self.missingDomainCount = missingDomainCount
        self.canViewRecommendation = canViewRecommendation
        self.onDomainTapped = onDomainTapped
        self.onViewRecommendation = onViewRecommendation
        self.onFinish = onFinish
        self.isFinishing = isFinishing
        self.showsFinishButton = showsFinishButton
    }

    private var completionLabel: String {
        "\(completedCount)/\(totalCount) domains"
    }

    private var assessmentLabel: String {
        assessmentType.capitalized
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if missingDomainCount > 0 {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(AppColors.onDanger)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(LocalizedString("summary_complete_all_domains_title", lang))
                                    .font(.headline)
                                Text(LocalizedString("summary_complete_all_domains_message", lang))
                                    .font(.subheadline)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .foregroundColor(AppColors.onDanger)
                        }
                        .padding()
                        .background(AppColors.danger)
                        .cornerRadius(16)
                    }

                    clientCard
                    domainSection(title: LocalizedString("summary_domain_results", lang), domains: domains)
                    if !problemDomains.isEmpty {
                        domainSection(title: LocalizedString("summary_problem_areas", lang), domains: problemDomains)
                    }
                    keyNotesSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            .background(AppColors.background.ignoresSafeArea())
            .safeAreaInset(edge: .bottom) {
                actionButtons
                    .padding(20)
                    .background(AppColors.background.opacity(0.95))
            }
            .navigationTitle(LocalizedString("summary_title", lang))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(LocalizedString("summary_close", lang)) { dismiss() }
                }
            }
        }
    }

    private var clientCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(client.displayName)
                .font(.title3.bold())
            Text(String(format: LocalizedString("summary_assessment_label", lang), assessmentLabel))
                .foregroundColor(AppColors.textSecondary)
                .font(.subheadline)
            Text(String(format: LocalizedString("summary_completed_label", lang), completionLabel))
                .foregroundColor(AppColors.textSecondary)
                .font(.subheadline)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.mainSurface)
        .cornerRadius(24)
    }

    private func domainSection(title: String, domains: [AssessmentSummaryDomain]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            VStack(spacing: 0) {
                ForEach(domains) { domain in
                    Button {
                        onDomainTapped(domain.domainKey)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(domain.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(AppColors.textPrimary)
                                Text(domain.isCompleted ? LocalizedString("summary_domain_completed", lang) : LocalizedString("summary_domain_not_started", lang))
                                    .font(.caption)
                                    .foregroundColor(domain.isCompleted ? AppColors.textSecondary : AppColors.danger)
                            }
                            Spacer()
                            Text(domain.valueText)
                                .font(.headline)
                                .foregroundColor(AppColors.textPrimary)
                            Image(systemName: "chevron.right")
                                .foregroundColor(AppColors.textSecondary)
                        }
                        .padding()
                        .background(AppColors.secondarySurface)
                    }
                    .buttonStyle(.plain)
                    .overlay(
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(AppColors.border),
                        alignment: .bottom
                    )
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
    }

    private var keyNotesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LocalizedString("assessment_summary_key_notes", lang))
                .font(.headline)
            Text(keyNotes.isEmpty ? LocalizedString("summary_no_notes", lang) : keyNotes)
                .font(.body)
                .foregroundColor(AppColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(AppColors.secondarySurface)
                .cornerRadius(16)
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                onViewRecommendation()
            } label: {
                Text(LocalizedString("summary_view_recommendation", lang))
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppColors.secondarySurface)
                    .cornerRadius(16)
            }
            .disabled(!canViewRecommendation)
            .opacity(canViewRecommendation ? 1 : 0.5)

            if showsFinishButton {
                Button {
                    onFinish()
                } label: {
                    HStack {
                        if isFinishing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: AppColors.onPrimary))
                        } else {
                            Text(LocalizedString("assessment_summary_finish", lang))
                        }
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(missingDomainCount == 0 ? AppColors.primary : AppColors.textSecondary.opacity(0.4))
                    .foregroundColor(missingDomainCount == 0 ? AppColors.onPrimary : AppColors.textPrimary)
                    .cornerRadius(16)
                }
                .disabled(missingDomainCount > 0 || isFinishing)
            }
        }
    }
}
