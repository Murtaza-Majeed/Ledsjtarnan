//
//  AssessmentSummaryView.swift
//  Ledstjarnan
//

import SwiftUI

struct AssessmentSummaryView: View {
    @Environment(\.dismiss) private var dismiss
    let client: Client
    let assessmentType: String
    let scores: [AssessmentDomainScore]
    let notes: String
    
    private var title: String {
        assessmentType == "baseline" ? "Baseline summary" : "Follow-up summary"
    }
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Client")) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(client.displayName)
                            .font(.headline)
                        Text(assessmentType.capitalized)
                            .font(.subheadline)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                
                Section(header: Text("Domains")) {
                    ForEach(scores) { score in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(score.domain.title)
                                    .font(.headline)
                                Spacer()
                                Text(score.formattedAverage)
                                    .font(.headline)
                            }
                            Text(score.domain.subtitle)
                                .font(.caption)
                                .foregroundColor(AppColors.textSecondary)
                            Text(score.interpretation)
                                .font(.subheadline)
                                .foregroundColor(AppColors.textPrimary)
                        }
                        .padding(.vertical, 6)
                    }
                }
                
                if !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Section(header: Text("Notes")) {
                        Text(notes)
                            .font(.body)
                            .foregroundColor(AppColors.textPrimary)
                            .padding(.vertical, 4)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
