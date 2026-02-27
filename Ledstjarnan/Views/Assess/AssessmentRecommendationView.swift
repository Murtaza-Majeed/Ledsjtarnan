//
//  AssessmentRecommendationView.swift
//  Ledstjarnan
//
//  Shows actionable recommendations after an assessment is summarised.
//

import SwiftUI

struct AssessmentRecommendationFocus: Identifiable {
    let id = UUID()
    let domainKey: String
    let title: String
    let needLevel: NeedLevel

    func priorityLabel(lang: String) -> String {
        switch needLevel {
        case .high: return LocalizedString("assessment_recommendation_priority_high", lang)
        case .mediumHigh: return LocalizedString("assessment_recommendation_priority_medium", lang)
        case .mediumLow: return LocalizedString("assessment_recommendation_priority_medium_low", lang)
        case .low: return LocalizedString("assessment_recommendation_priority_low", lang)
        }
    }

    var priorityColor: Color {
        switch needLevel {
        case .high: return .red
        case .mediumHigh: return .orange
        case .mediumLow: return .yellow
        case .low: return .green
        }
    }
}

struct AssessmentRecommendationView: View {
    let client: Client
    let assessmentType: String
    let focusSuggestions: [AssessmentRecommendationFocus]
    let suggestedChapters: [String]
    let isClientLinked: Bool
    let onClose: () -> Void
    let onGoToPlanBuilder: (Set<String>) -> Void
    let onAssignChapters: () -> Void
    let onOpenInsatskarta: (() -> Void)?
    /// When provided, the "Öppna Insatskarta" button presents InsatskartraView in a sheet from this view (so it opens on top).
    var insatskartaRecommendations: [InterventionRecommendation]? = nil
    var insatskartaSafetyFlags: [SafetyFlag]? = nil
    var insatskartaPTSD: PTSDEvaluation? = nil
    var insatskartaClientName: String? = nil

    @State private var selectedDomains: Set<String> = []
    @State private var showInsatskartaSheet = false
    @Environment(\.languageCode) var lang

    private var headerSubtitle: String {
        assessmentType == "baseline" ? LocalizedString("assessment_recommendation_subtitle_baseline", lang) : LocalizedString("assessment_recommendation_subtitle_followup", lang)
    }

    private var defaultSelection: Set<String> {
        let high = focusSuggestions.filter { $0.needLevel == .high }.map { $0.domainKey }
        if !high.isEmpty { return Set(high) }
        let mediumHigh = focusSuggestions.filter { $0.needLevel == .mediumHigh }.map { $0.domainKey }
        if !mediumHigh.isEmpty { return Set(mediumHigh) }
        return Set(focusSuggestions.prefix(1).map { $0.domainKey })
    }

    private var resolvedSelection: Set<String> {
        selectedDomains.isEmpty ? defaultSelection : selectedDomains
    }

    private var canShowInsatskarta: Bool {
        if let r = insatskartaRecommendations, let s = insatskartaSafetyFlags, let p = insatskartaPTSD, let n = insatskartaClientName, !n.isEmpty {
            return true
        }
        return onOpenInsatskarta != nil
    }

    private func openInsatskarta() {
        if insatskartaRecommendations != nil, insatskartaSafetyFlags != nil, insatskartaPTSD != nil, let n = insatskartaClientName, !n.isEmpty {
            showInsatskartaSheet = true
        } else {
            onOpenInsatskarta?()
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    headerCard
                    focusList
                    chapterSuggestions
                }
                .padding(24)
            }
            .background(AppColors.background.ignoresSafeArea())
            .safeAreaInset(edge: .bottom) {
                bottomActions
                    .padding(20)
                    .background(AppColors.background.opacity(0.95))
            }
            .navigationTitle(LocalizedString("assessment_recommendation_title", lang))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(LocalizedString("general_close", lang)) { onClose() }
                }
            }
        }
        .fullScreenCover(isPresented: $showInsatskartaSheet) {
            if let recs = insatskartaRecommendations, let flags = insatskartaSafetyFlags, let ptsd = insatskartaPTSD, let name = insatskartaClientName {
                InsatskartraView(
                    recommendations: recs,
                    safetyFlags: flags,
                    ptsd: ptsd,
                    clientName: name
                )
            }
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(client.displayName)
                .font(.title3.bold())
            Text(headerSubtitle)
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.mainSurface)
        .cornerRadius(24)
    }

    private var focusList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizedString("assessment_recommendation_focus_areas", lang))
                .font(.headline)
            if focusSuggestions.isEmpty {
                Text(LocalizedString("assessment_recommendation_complete_message", lang))
                    .font(.subheadline)
                    .foregroundColor(AppColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(spacing: 12) {
                    ForEach(focusSuggestions) { suggestion in
                        focusRow(for: suggestion)
                    }
                }
            }
        }
    }

    private func focusRow(for suggestion: AssessmentRecommendationFocus) -> some View {
        let isSelected = selectedDomains.contains(suggestion.domainKey)
        return HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(suggestion.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(AppColors.textPrimary)
                Text(suggestion.priorityLabel(lang: lang))
                    .font(.caption)
                    .foregroundColor(suggestion.priorityColor)
            }
            Spacer()
            Button(isSelected ? LocalizedString("assessment_recommendation_button_added", lang) : LocalizedString("assessment_recommendation_button_add", lang)) {
                toggleSelection(for: suggestion.domainKey)
            }
            .font(.caption.bold())
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? AppColors.primary : AppColors.secondarySurface)
            .foregroundColor(isSelected ? AppColors.onPrimary : AppColors.textPrimary)
            .cornerRadius(16)
        }
        .padding()
        .background(AppColors.mainSurface)
        .cornerRadius(18)
    }

    private func toggleSelection(for domainKey: String) {
        if selectedDomains.contains(domainKey) {
            selectedDomains.remove(domainKey)
        } else {
            selectedDomains.insert(domainKey)
        }
    }

    private var chapterSuggestions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizedString("assessment_recommendation_suggested_chapters", lang))
                .font(.headline)
            if suggestedChapters.isEmpty {
                Text(LocalizedString("assessment_recommendation_assign_after_selection", lang))
                    .font(.subheadline)
                    .foregroundColor(AppColors.textSecondary)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(suggestedChapters, id: \.self) { chapter in
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                            Text(chapter)
                                .foregroundColor(AppColors.textPrimary)
                                .font(.subheadline)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    Text(LocalizedString("assessment_recommendation_tap_assign_hint", lang))
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                        .padding(.top, 4)
                }
            }
        }
        .padding()
        .background(AppColors.secondarySurface)
        .cornerRadius(24)
    }

    private var bottomActions: some View {
        VStack(spacing: 12) {
            Button {
                onGoToPlanBuilder(resolvedSelection)
            } label: {
                Text(LocalizedString("assessment_recommendation_go_to_plan_builder", lang))
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppColors.primary)
                    .foregroundColor(AppColors.onPrimary)
                    .cornerRadius(16)
            }
            .disabled(focusSuggestions.isEmpty)
            .opacity(focusSuggestions.isEmpty ? 0.5 : 1)

            Button {
                onAssignChapters()
            } label: {
                Text(LocalizedString("assessment_recommendation_assign_chapters_picker", lang))
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isClientLinked ? AppColors.secondarySurface : AppColors.secondarySurface.opacity(0.6))
                    .foregroundColor(AppColors.textPrimary)
                    .cornerRadius(16)
            }
            .disabled(!isClientLinked)
            if !isClientLinked {
                Text(LocalizedString("assessment_recommendation_link_client_message", lang))
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            if canShowInsatskarta {
                Button {
                    openInsatskarta()
                } label: {
                    Text(LocalizedString("assessment_recommendation_open_insatskarta", lang))
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(AppColors.primary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
        }
    }
}
