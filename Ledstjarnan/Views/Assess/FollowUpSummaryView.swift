//
//  FollowUpSummaryView.swift
//  Ledstjarnan
//
//  Follow-up summary comparing baseline vs follow-up scores.
//

import SwiftUI

struct FollowUpSummaryDomain: Identifiable {
    let id = UUID()
    let title: String
    let previousScore: Int?
    let currentScore: Int?

    var deltaText: String {
        guard let prev = previousScore, let current = currentScore else { return "—" }
        let delta = current - prev
        if delta > 0 { return "+\(delta)" }
        if delta < 0 { return "\(delta)" }
        return "0"
    }

    var deltaColor: Color {
        guard let prev = previousScore, let current = currentScore else { return AppColors.textSecondary }
        if current > prev { return .green }
        if current < prev { return .red }
        return AppColors.textSecondary
    }
}

struct FollowUpSummaryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.languageCode) private var lang

    let client: Client
    let followUpDate: Date?
    let domains: [FollowUpSummaryDomain]
    @Binding var staffNote: String
    let onSaveDraft: () -> Void
    let onFinish: () -> Void
    let canFinish: Bool
    let isFinishing: Bool

    private var formattedDate: String {
        guard let followUpDate else { return "—" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: followUpDate)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerCard
                    domainChanges
                    staffNoteField
                }
                .padding(24)
            }
            .background(AppColors.background.ignoresSafeArea())
            .safeAreaInset(edge: .bottom) {
                finishButton
                    .padding(20)
                    .background(AppColors.background.opacity(0.95))
            }
            .navigationTitle(LocalizedString("followup_summary_title", lang))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(LocalizedString("general_close", lang)) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(LocalizedString("general_save", lang)) {
                        onSaveDraft()
                    }
                }
            }
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(client.displayName)
                .font(.title3.bold())
            Text(LocalizedString("followup_summary_baseline_vs_followup", lang))
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
            Text(String(format: LocalizedString("followup_summary_date", lang), formattedDate))
                .font(.caption)
                .foregroundColor(AppColors.textSecondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.mainSurface)
        .cornerRadius(24)
    }

    private var domainChanges: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizedString("followup_summary_changes_by_domain", lang))
                .font(.headline)
            VStack(spacing: 12) {
                ForEach(domains) { domain in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(domain.title)
                                .font(.subheadline.weight(.semibold))
                            Text(String(format: LocalizedString("followup_summary_score_comparison", lang), formattedScore(domain.previousScore), formattedScore(domain.currentScore)))
                                .font(.caption)
                                .foregroundColor(AppColors.textSecondary)
                        }
                        Spacer()
                        Text(domain.deltaText)
                            .font(.headline)
                            .foregroundColor(domain.deltaColor)
                            .frame(width: 44, height: 32)
                            .background(AppColors.secondarySurface)
                            .cornerRadius(12)
                    }
                    .padding()
                    .background(AppColors.mainSurface)
                    .cornerRadius(18)
                }
            }
        }
    }

    private func formattedScore(_ value: Int?) -> String {
        guard let value else { return "—/5" }
        return "\(value)/5"
    }

    private var staffNoteField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LocalizedString("followup_summary_staff_note", lang))
                .font(.headline)
            TextField(LocalizedString("followup_summary_staff_note_placeholder", lang), text: $staffNote, axis: .vertical)
                .textFieldStyle(.plain)
                .padding()
                .background(AppColors.secondarySurface)
                .cornerRadius(14)
                .lineLimit(3...6)
        }
    }

    private var finishButton: some View {
        Button {
            onFinish()
        } label: {
            HStack {
                if isFinishing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: AppColors.onPrimary))
                } else {
                    Text(LocalizedString("followup_summary_finish", lang))
                        .font(.headline)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(canFinish ? AppColors.primary : AppColors.secondarySurface)
            .foregroundColor(canFinish ? AppColors.onPrimary : AppColors.textSecondary)
            .cornerRadius(16)
        }
        .disabled(!canFinish || isFinishing)
    }
}
