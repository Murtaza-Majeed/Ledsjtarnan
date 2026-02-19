//
//  DomainFormView.swift
//  Ledstjarnan
//
//  Single baseline domain form (readiness, notes, needs/risks).
//

import SwiftUI

struct DomainFormView: View {
    @Environment(\.dismiss) private var dismiss
    let client: Client
    let assessmentId: String
    let domain: BaselineDomain
    @Binding var allAnswers: [String: AnyCodable]
    let previousScore: Int?

    @State private var readiness: Int?
    @State private var notes: String = ""
    @State private var selectedNeeds: Set<String> = []
    @State private var isSaving = false
    @State private var saveSuccess = false
    @State private var errorMessage: String?
    @State private var showDiscardAlert = false

    private let assessmentService = AssessmentService()

    init(
        client: Client,
        assessmentId: String,
        domain: BaselineDomain,
        answers: Binding<[String: AnyCodable]>,
        previousScore: Int? = nil
    ) {
        self.client = client
        self.assessmentId = assessmentId
        self.domain = domain
        self._allAnswers = answers
        self.previousScore = previousScore

        let readinessValue = answers.wrappedValue[DomainAnswerKey.readiness(domain.key)]?.value as? Int
        let savedNotes = answers.wrappedValue[DomainAnswerKey.notes(domain.key)]?.value as? String ?? ""
        var needsSeed: Set<String> = []
        if let saved = answers.wrappedValue[DomainAnswerKey.needs(domain.key)]?.value as? [String] {
            needsSeed = Set(saved)
        } else if let anyArray = answers.wrappedValue[DomainAnswerKey.needs(domain.key)]?.value as? [Any] {
            let items = anyArray.compactMap { $0 as? String }
            needsSeed = Set(items)
        }

        _readiness = State(initialValue: readinessValue)
        _notes = State(initialValue: savedNotes)
        _selectedNeeds = State(initialValue: needsSeed)
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundColor(AppColors.danger)
                    .padding()
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    domainMeta
                    readinessSection
                    notesSection
                    needsSection
                    if saveSuccess {
                        Label("Saved", systemImage: "checkmark.circle.fill")
                            .font(.footnote.weight(.semibold))
                            .foregroundColor(AppColors.success)
                            .padding(.vertical, 4)
                    }
                }
                .padding()
            }
            markCompletedButton
        }
        .background(AppColors.background.ignoresSafeArea())
        .confirmationDialog("Discard changes?", isPresented: $showDiscardAlert) {
            Button("Discard", role: .destructive) { dismiss() }
            Button("Cancel", role: .cancel) { }
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                if hasUnsavedChanges {
                    showDiscardAlert = true
                } else {
                    dismiss()
                }
            } label: {
                Label("Back", systemImage: "chevron.left")
                    .font(.subheadline.weight(.semibold))
            }
            .tint(AppColors.textPrimary)

            Spacer()
            Text("Domain")
                .font(.headline)
                .foregroundColor(AppColors.textPrimary)
            Spacer()
            Button(action: { Task { await saveDraft(markCompleted: false) } }) {
                if isSaving {
                    ProgressView()
                } else {
                    Text("Save")
                        .font(.subheadline.weight(.semibold))
                }
            }
            .disabled(isSaving)
        }
        .padding()
        .background(AppColors.mainSurface)
    }

    private var domainMeta: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: domain.icon)
                    .font(.title2)
                    .foregroundColor(AppColors.primary)
                    .frame(width: 44, height: 44)
                    .background(AppColors.primary.opacity(0.12))
                    .cornerRadius(12)
            VStack(alignment: .leading, spacing: 4) {
                Text(domain.title)
                    .font(.title3.weight(.semibold))
                    .foregroundColor(AppColors.textPrimary)
                Text(domain.subtitle)
                    .font(.footnote)
                    .foregroundColor(AppColors.textSecondary)
                Text("\(domain.questionCount) questions • \(client.displayName)")
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
                if let previousScore {
                    Text("Previous score: \(previousScore)/5")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
    }
    }

    private var readinessSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Readiness (1–5)")
                .font(.headline)
            Text("1 = stort behov av stöd, 5 = självständig")
                .font(.caption)
                .foregroundColor(AppColors.textSecondary)

            HStack(spacing: 12) {
                ForEach(1...5, id: \.self) { value in
                    Button {
                        readiness = readiness == value ? nil : value
                    } label: {
                        Text("\(value)")
                            .font(.headline)
                            .frame(width: 48, height: 48)
                            .background(readiness == value ? AppColors.primary : AppColors.secondarySurface)
                            .foregroundColor(readiness == value ? AppColors.onPrimary : AppColors.textPrimary)
                            .cornerRadius(12)
                    }
                }
            }
            if readiness == nil {
                Text("Required to complete domain")
                    .font(.caption2)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes (optional)")
                .font(.headline)
            TextEditor(text: $notes)
                .frame(minHeight: 120)
                .padding(12)
                .background(AppColors.mainSurface)
                .cornerRadius(12)
        }
    }

    private var needsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Needs / risks (multi-select)")
                .font(.headline)
            let columns = [GridItem(.adaptive(minimum: 150), spacing: 12)]
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(domain.needsOptions, id: \.self) { option in
                    SelectableChip(title: option, isSelected: selectedNeeds.contains(option)) {
                        if selectedNeeds.contains(option) {
                            selectedNeeds.remove(option)
                        } else {
                            selectedNeeds.insert(option)
                        }
                    }
                }
            }
        }
    }

    private var markCompletedButton: some View {
        VStack(spacing: 8) {
            Button(action: { Task { await saveDraft(markCompleted: true) } }) {
                HStack {
                    if isSaving {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppColors.onPrimary))
                    } else {
                        Text("Mark as completed")
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(readiness == nil ? AppColors.textSecondary.opacity(0.3) : AppColors.primary)
                .foregroundColor(readiness == nil ? AppColors.textPrimary : AppColors.onPrimary)
                .cornerRadius(16)
            }
            .disabled(isSaving || readiness == nil)
            Text("You can always come back and edit later.")
                .font(.caption)
                .foregroundColor(AppColors.textSecondary)
        }
        .padding()
        .background(AppColors.background)
    }

    private var hasUnsavedChanges: Bool {
        let existingReadiness = allAnswers[DomainAnswerKey.readiness(domain.key)]?.value as? Int
        let existingNotes = allAnswers[DomainAnswerKey.notes(domain.key)]?.value as? String ?? ""
        let existingNeeds = savedNeeds()
        return existingReadiness != readiness ||
            existingNotes != notes ||
            Set(existingNeeds) != selectedNeeds
    }

    private func savedNeeds() -> [String] {
        if let saved = allAnswers[DomainAnswerKey.needs(domain.key)]?.value as? [String] {
            return saved
        }
        if let any = allAnswers[DomainAnswerKey.needs(domain.key)]?.value as? [Any] {
            return any.compactMap { $0 as? String }
        }
        return []
    }

    private func saveDraft(markCompleted: Bool) async {
        guard !isSaving else { return }
        if markCompleted && readiness == nil {
            await MainActor.run {
                errorMessage = "Fill readiness before completing."
            }
            return
        }
        isSaving = true
        errorMessage = nil
        var payloadDict: [String: AnyCodable] = [:]
        if let readiness {
            payloadDict[DomainAnswerKey.readiness(domain.key)] = AnyCodable(readiness)
        }
        payloadDict[DomainAnswerKey.notes(domain.key)] = AnyCodable(notes)
        payloadDict[DomainAnswerKey.needs(domain.key)] = AnyCodable(Array(selectedNeeds))
        payloadDict[DomainAnswerKey.status(domain.key)] = AnyCodable(markCompleted ? "completed" : "in_progress")

        let payloads = AssessmentAnswerPayloadBuilder.payloads(from: payloadDict, assessmentId: assessmentId)
        do {
            try await assessmentService.upsertAnswers(payloads)
            await MainActor.run {
                payloadDict.forEach { key, value in
                    allAnswers[key] = value
                }
                isSaving = false
                saveSuccess = true
                if markCompleted {
                    dismiss()
                } else {
                    Task {
                        try await Task.sleep(nanoseconds: 1_000_000_000)
                        await MainActor.run {
                            saveSuccess = false
                        }
                    }
                }
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isSaving = false
            }
        }
    }
}

private struct SelectableChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity)
                .background(isSelected ? AppColors.primary.opacity(0.85) : AppColors.secondarySurface)
                .foregroundColor(isSelected ? AppColors.onPrimary : AppColors.textPrimary)
                .cornerRadius(12)
        }
    }
}
