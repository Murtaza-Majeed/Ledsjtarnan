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

    var priorityLabel: String {
        switch needLevel {
        case .high: return "High priority"
        case .mediumHigh: return "Medium priority"
        case .mediumLow: return "Medium-low"
        case .low: return "Low priority"
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

    @State private var selectedDomains: Set<String> = []

    private var headerSubtitle: String {
        assessmentType == "baseline" ? "Based on baseline results" : "Based on follow-up results"
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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    headerCard
                    focusList
                    chapterSuggestions
                    if let onOpenInsatskarta {
                        Button("Open Insatskarta (detailed)") {
                            onOpenInsatskarta()
                        }
                        .font(.subheadline)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .foregroundColor(AppColors.primary)
                    }
                }
                .padding(24)
            }
            .background(AppColors.background.ignoresSafeArea())
            .safeAreaInset(edge: .bottom) {
                bottomActions
                    .padding(20)
                    .background(AppColors.background.opacity(0.95))
            }
            .navigationTitle("Recommendation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { onClose() }
                }
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
            Text("Recommended focus areas")
                .font(.headline)
            if focusSuggestions.isEmpty {
                Text("Complete the assessment to generate recommendations.")
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
                Text(suggestion.priorityLabel)
                    .font(.caption)
                    .foregroundColor(suggestion.priorityColor)
            }
            Spacer()
            Button(isSelected ? "Added" : "Add to plan") {
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
            Text("Suggested Livbojen chapters")
                .font(.headline)
            if suggestedChapters.isEmpty {
                Text("Assign Livbojen chapters after you select focus areas.")
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
                    Text("Tap Assign to send chapters to Livbojen.")
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
                Text("Go to plan builder")
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
                Text("Assign chapters (picker)")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isClientLinked ? AppColors.secondarySurface : AppColors.secondarySurface.opacity(0.6))
                    .foregroundColor(AppColors.textPrimary)
                    .cornerRadius(16)
            }
            .disabled(!isClientLinked)
            if !isClientLinked {
                Text("Link the client to Livbojen to assign chapters.")
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
    }
}
