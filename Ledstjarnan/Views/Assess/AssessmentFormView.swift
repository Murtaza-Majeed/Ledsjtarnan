//
//  AssessmentFormView.swift
//  Ledstjarnan
//
//  Form for baseline or follow-up assessment. Saves to assessments + assessment_answers.
//

import SwiftUI

struct AssessmentFormView: View {
    @ObservedObject var appState: AppState
    let client: Client
    let assessmentType: String
    @Environment(\.dismiss) var dismiss
    @State private var assessment: Assessment?
    @State private var answers: [String: AnyCodable] = [:]
    @State private var notes = ""
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var completed = false
    @State private var showSummary = false
    private let assessmentService = AssessmentService()

    private var isBaseline: Bool { assessmentType == "baseline" }
    private var domainScores: [AssessmentDomainScore] {
        AssessmentDefinition.scores(from: answers)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if let error = errorMessage {
                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(AppColors.danger)
                        .padding(.horizontal)
                }
                if isLoading {
                    ProgressView("Loading…")
                        .frame(maxWidth: .infinity)
                        .padding()
                } else if let a = assessment {
                    scoresCarousel
                    HStack {
                        Text("Domains")
                            .font(.title3.weight(.semibold))
                        Spacer()
                        Button {
                            showSummary = true
                        } label: {
                            Label("Summary", systemImage: "chart.bar")
                                .font(.subheadline)
                        }
                        .disabled(domainScores.allSatisfy { $0.answeredCount == 0 })
                    }
                    .padding(.horizontal)
                    
                    ForEach(AssessmentDefinition.domains, id: \.key) { domain in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(domain.title)
                                .font(.headline)
                                .foregroundColor(AppColors.textPrimary)
                            Text(domain.subtitle)
                                .font(.subheadline)
                                .foregroundColor(AppColors.textSecondary)
                            ForEach(domain.questions, id: \.key) { q in
                                questionView(domainKey: domain.key, question: q)
                            }
                        }
                        .padding()
                        .background(AppColors.secondarySurface)
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .font(.headline)
                            .foregroundColor(AppColors.textPrimary)
                        TextField("", text: $notes, axis: .vertical)
                            .textFieldStyle(.plain)
                            .padding()
                            .background(AppColors.mainSurface)
                            .cornerRadius(8)
                            .lineLimit(3...6)
                    }
                    .padding(.horizontal)
                    HStack(spacing: 12) {
                        Button(action: { Task { await saveDraft() } }) {
                            Text("Save draft")
                                .font(.headline)
                                .foregroundColor(AppColors.primary)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(AppColors.secondarySurface)
                                .cornerRadius(12)
                        }
                        .disabled(isSaving)
                        Button(action: { Task { await completeAssessment() } }) {
                            HStack {
                                if isSaving { ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white)) }
                                else { Text("Complete") }
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppColors.primary)
                            .cornerRadius(12)
                        }
                        .disabled(isSaving)
                    }
                    .padding()
                }
            }
            .padding(.vertical, 20)
        }
        .background(AppColors.background)
        .navigationTitle(isBaseline ? "Baseline Assessment" : "Follow-up")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadOrCreateAssessment()
        }
        .sheet(isPresented: $showSummary) {
            AssessmentSummaryView(
                client: client,
                assessmentType: assessmentType,
                scores: domainScores,
                notes: notes
            )
        }
        .onChange(of: completed) { _, done in
            if done { dismiss() }
        }
    }

    @ViewBuilder
    private func questionView(domainKey: String, question: AssessmentQuestion) -> some View {
        let key = "\(domainKey).\(question.key)"
        switch question.type {
        case .scale(let low, let high):
            let binding: Binding<Int> = Binding(
                get: {
                    if let v = answers[key]?.value as? Int { return v }
                    return low
                },
                set: { answers[key] = AnyCodable($0) }
            )
            let options = Array(low...high)
            VStack(alignment: .leading, spacing: 6) {
                Text(question.label)
                    .font(.subheadline)
                    .foregroundColor(AppColors.textSecondary)
                HStack(spacing: 8) {
                    ForEach(options, id: \.self) { n in
                        let isSelected = binding.wrappedValue == n
                        Button(action: { binding.wrappedValue = n }) {
                            Text("\(n)")
                                .font(.subheadline)
                                .fontWeight(isSelected ? .semibold : .regular)
                                .foregroundColor(isSelected ? .white : AppColors.textPrimary)
                                .frame(width: 36, height: 36)
                                .background(isSelected ? AppColors.primary : AppColors.mainSurface)
                                .cornerRadius(8)
                        }
                    }
                }
            }
        case .text:
            let binding: Binding<String> = Binding(
                get: {
                    if let v = answers[key]?.value as? String { return v }
                    return ""
                },
                set: { answers[key] = AnyCodable($0) }
            )
            VStack(alignment: .leading, spacing: 6) {
                Text(question.label)
                    .font(.subheadline)
                    .foregroundColor(AppColors.textSecondary)
                TextField("", text: binding)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(AppColors.mainSurface)
                    .cornerRadius(8)
            }
        }
    }
    
    private var scoresCarousel: some View {
        Group {
            if domainScores.allSatisfy({ $0.answeredCount == 0 }) {
                EmptyView()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(domainScores) { score in
                            DomainScoreCard(score: score)
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(height: 160)
            }
        }
    }

    private func loadOrCreateAssessment() async {
        guard let unitId = appState.currentUnit?.id else {
            await MainActor.run { errorMessage = "No unit."; isLoading = false }
            return
        }
        let staffId = appState.currentStaffProfile?.id
        do {
            let list = try await assessmentService.getAssessments(clientId: client.id)
            let existing = list.first { $0.assessmentType == assessmentType && $0.status != "completed" }
            let a: Assessment
            if let e = existing {
                a = e
                let answerList = try await assessmentService.getAssessmentAnswers(assessmentId: a.id)
                var dict: [String: AnyCodable] = [:]
                for ans in answerList {
                    let key = "\(ans.domainKey).\(ans.questionKey)"
                    if let v = ans.value { dict[key] = v }
                }
                await MainActor.run {
                    assessment = a
                    answers = dict
                    notes = a.notes ?? ""
                    isLoading = false
                }
            } else {
                a = try await assessmentService.createAssessment(
                    clientId: client.id,
                    unitId: unitId,
                    type: assessmentType,
                    createdByStaffId: staffId
                )
                await MainActor.run {
                    assessment = a
                    isLoading = false
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }

    private func saveDraft() async {
        guard let a = assessment else { return }
        isSaving = true
        errorMessage = nil
        do {
            try await assessmentService.updateAssessment(id: a.id, status: "draft", completedAt: nil, notes: notes.isEmpty ? nil : notes)
            for domain in AssessmentDefinition.domains {
                for q in domain.questions {
                    let key = "\(domain.key).\(q.key)"
                    guard let val = answers[key] else { continue }
                    try await assessmentService.setAnswer(assessmentId: a.id, domainKey: domain.key, questionKey: q.key, value: val)
                }
            }
            await MainActor.run { isSaving = false }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isSaving = false
            }
        }
    }

private func completeAssessment() async {
        guard let a = assessment else { return }
        isSaving = true
        errorMessage = nil
        do {
            for domain in AssessmentDefinition.domains {
                for q in domain.questions {
                    let key = "\(domain.key).\(q.key)"
                    guard let val = answers[key] else { continue }
                    try await assessmentService.setAnswer(assessmentId: a.id, domainKey: domain.key, questionKey: q.key, value: val)
                }
            }
            try await assessmentService.updateAssessment(
                id: a.id,
                status: "completed",
                completedAt: Date(),
                notes: notes.isEmpty ? nil : notes
            )
            await MainActor.run {
                isSaving = false
                completed = true
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isSaving = false
            }
        }
    }
}

struct DomainScoreCard: View {
    let score: AssessmentDomainScore
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: score.domain.icon)
                    .foregroundColor(AppColors.primary)
                Spacer()
                Text(score.formattedAverage)
                    .font(.title.bold())
                    .foregroundColor(AppColors.textPrimary)
            }
            Text(score.domain.title)
                .font(.headline)
            Text(score.interpretation)
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
            Text("\(score.answeredCount) av \(score.domain.questions.filter { if case .scale = $0.type { return true } else { return false } }.count) frågor")
                .font(.caption)
                .foregroundColor(AppColors.textSecondary)
        }
        .padding()
        .frame(width: 220, alignment: .leading)
        .background(AppColors.mainSurface)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
}
