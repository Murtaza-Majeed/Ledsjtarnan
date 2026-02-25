//
//  DomainFormView.swift
//  Ledstjarnan
//
//  Single baseline domain form (readiness, notes, needs/risks).
//

import SwiftUI

struct DomainFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.languageCode) var lang
    @EnvironmentObject private var logicStore: LogicReferenceStore
    let client: Client
    let assessmentId: String
    let domain: BaselineDomain
    @Binding var allAnswers: [String: AnyCodable]
    let previousScore: Int?

    @State private var readiness: Int?
    @State private var notes: String = ""
    @State private var selectedNeeds: Set<String> = []
    @State private var interviewAnswers: [String: AnyCodable] = [:]
    @State private var savedInterviewSnapshot: [String: AnyCodable] = [:]
    @State private var interviewDirty = false
    @State private var clearedInterviewKeys: Set<String> = []
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

        var interviewSeed: [String: AnyCodable] = [:]
        let prefix = "\(domain.key)."
        answers.wrappedValue.forEach { key, value in
            guard key.hasPrefix(prefix),
                  !DomainAnswerKey.isSpecialKey(key, forDomain: domain.key) else { return }
            let questionKey = String(key.dropFirst(prefix.count))
            interviewSeed[questionKey] = value
        }

        _readiness = State(initialValue: readinessValue)
        _notes = State(initialValue: savedNotes)
        _selectedNeeds = State(initialValue: needsSeed)
        _interviewAnswers = State(initialValue: interviewSeed)
        _savedInterviewSnapshot = State(initialValue: interviewSeed)
        _clearedInterviewKeys = State(initialValue: [])
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
                    interviewSectionList()
                    readinessSection
                    notesSection
                    needsSection
                    if saveSuccess {
                Label(LocalizedString("label_saved", lang), systemImage: "checkmark.circle.fill")
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
        .confirmationDialog(LocalizedString("dialog_discard_title", lang), isPresented: $showDiscardAlert) {
            Button(LocalizedString("general_discard", lang), role: .destructive) { dismiss() }
            Button(LocalizedString("general_cancel", lang), role: .cancel) { }
        }
        .task {
            let hasSections = !logicStore.interviewSections(forAppKey: domain.key).isEmpty
            await logicStore.loadReferenceIfNeeded(force: !hasSections)
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
                Label(LocalizedString("general_back", lang), systemImage: "chevron.left")
                    .font(.subheadline.weight(.semibold))
            }
            .tint(AppColors.textPrimary)

            Spacer()
            Text(LocalizedString("domain_nav_title", lang))
                .font(.headline)
                .foregroundColor(AppColors.textPrimary)
            Spacer()
            Button(action: { Task { await saveDraft(markCompleted: false) } }) {
                if isSaving {
                    ProgressView()
                } else {
                    Text(LocalizedString("general_save", lang))
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
                    let count = interviewQuestionCount
                    Text(String(format: LocalizedString("domain_question_meta", lang), count, client.displayName))
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                    if let previousScore {
                        Text(String(format: LocalizedString("domain_previous_score", lang), previousScore))
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
        }
    }

    private var interviewQuestionCount: Int {
        let sections = interviewSections
        if sections.isEmpty { return domain.questionCount }
        return sections.reduce(0) { $0 + ($1.questions?.count ?? 0) }
    }

    private var interviewSections: [LogicInterviewSection] {
        logicStore.interviewSections(forAppKey: domain.key)
    }

    @ViewBuilder
    private func interviewSectionList() -> some View {
        let sections = interviewSections
        if logicStore.isLoading && sections.isEmpty {
            ProgressView(LocalizedString("domain_loading_questions", lang))
        } else if sections.isEmpty {
            Text(LocalizedString("domain_no_questions", lang))
                .font(.footnote)
                .foregroundColor(AppColors.textSecondary)
        } else {
            VStack(alignment: .leading, spacing: 20) {
                ForEach(sections) { section in
                    VStack(alignment: .leading, spacing: 12) {
                        Text(section.title)
                            .font(.headline)
                            .foregroundColor(AppColors.textPrimary)
                        if let description = section.description, !description.isEmpty {
                            Text(description)
                                .font(.caption)
                                .foregroundColor(AppColors.textSecondary)
                        }
                        ForEach(section.questions ?? []) { question in
                            interviewQuestionView(question)
                        }
                    }
                    .padding()
                    .background(AppColors.secondarySurface)
                    .cornerRadius(12)
                }
            }
        }
    }

    @ViewBuilder
    private func interviewQuestionView(_ question: LogicInterviewQuestion) -> some View {
        switch question.questionType {
        case .yesNo:
            yesNoView(for: question)
        case .yesNoSpecify:
            yesNoSpecifyView(for: question)
        case .text:
            textResponseView(for: question)
        case .multipleChoice:
            multipleChoiceView(for: question)
        case .multiSelect:
            multiSelectView(for: question)
        case .scale:
            scaleResponseView(for: question)
        }
    }

    @ViewBuilder
    private func questionHeader(_ question: LogicInterviewQuestion) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(question.label)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(AppColors.textPrimary)
            if let help = question.helpText, !help.isEmpty {
                Text(help)
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
    }

    private func yesNoView(for question: LogicInterviewQuestion) -> some View {
        let selection = answerValue(question.questionKey, as: Bool.self)
        return VStack(alignment: .leading, spacing: 8) {
            questionHeader(question)
            HStack(spacing: 12) {
                yesNoButton(label: LocalizedString("general_yes", lang), isSelected: selection == true) {
                    if selection == true {
                        setInterviewAnswer(nil, for: question.questionKey)
                    } else {
                        setInterviewAnswer(true, for: question.questionKey)
                    }
                }
                yesNoButton(label: LocalizedString("general_no", lang), isSelected: selection == false) {
                    if selection == false {
                        setInterviewAnswer(nil, for: question.questionKey)
                    } else {
                        setInterviewAnswer(false, for: question.questionKey)
                    }
                }
            }
        }
    }

    private func yesNoSpecifyView(for question: LogicInterviewQuestion) -> some View {
        let selection = answerValue(question.questionKey, as: Bool.self)
        let detailKey = "\(question.questionKey)_detail"
        let detailText = Binding<String>(
            get: { answerValue(detailKey, as: String.self) ?? "" },
            set: { newValue in
                let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.isEmpty {
                    setInterviewAnswer(nil, for: detailKey)
                } else {
                    setInterviewAnswer(newValue, for: detailKey)
                }
            }
        )
        return VStack(alignment: .leading, spacing: 8) {
            questionHeader(question)
            HStack(spacing: 12) {
                yesNoButton(label: LocalizedString("general_yes", lang), isSelected: selection == true) {
                    if selection == true {
                        setInterviewAnswer(nil, for: question.questionKey)
                        setInterviewAnswer(nil, for: detailKey)
                    } else {
                        setInterviewAnswer(true, for: question.questionKey)
                    }
                }
                yesNoButton(label: LocalizedString("general_no", lang), isSelected: selection == false) {
                    if selection == false {
                        setInterviewAnswer(nil, for: question.questionKey)
                        setInterviewAnswer(nil, for: detailKey)
                    } else {
                        setInterviewAnswer(false, for: question.questionKey)
                        setInterviewAnswer(nil, for: detailKey)
                    }
                }
            }
            if selection == true {
                TextField(LocalizedString("placeholder_describe", lang), text: detailText)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }

    private func textResponseView(for question: LogicInterviewQuestion) -> some View {
        let binding = Binding<String>(
            get: { answerValue(question.questionKey, as: String.self) ?? "" },
            set: { newValue in
                let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.isEmpty {
                    setInterviewAnswer(nil, for: question.questionKey)
                } else {
                    setInterviewAnswer(newValue, for: question.questionKey)
                }
            }
        )
        return VStack(alignment: .leading, spacing: 8) {
            questionHeader(question)
            TextEditor(text: binding)
                .frame(minHeight: 100)
                .padding(8)
                .background(AppColors.mainSurface)
                .cornerRadius(8)
        }
    }

    private func multipleChoiceView(for question: LogicInterviewQuestion) -> some View {
        let options = question.options ?? []
        let current = answerValue(question.questionKey, as: String.self)
        return VStack(alignment: .leading, spacing: 8) {
            questionHeader(question)
            VStack(spacing: 8) {
                ForEach(options, id: \.self) { option in
                    let isSelected = current == option
                    Button {
                        if isSelected {
                            setInterviewAnswer(nil, for: question.questionKey)
                        } else {
                            setInterviewAnswer(option, for: question.questionKey)
                        }
                    } label: {
                        HStack {
                            Text(option)
                                .font(.subheadline)
                                .foregroundColor(isSelected ? AppColors.onPrimary : AppColors.textPrimary)
                            Spacer()
                        }
                        .padding()
                        .background(isSelected ? AppColors.primary : AppColors.mainSurface)
                        .cornerRadius(10)
                    }
                }
            }
        }
    }

    private func multiSelectView(for question: LogicInterviewQuestion) -> some View {
        let options = question.options ?? []
        let current = Set(answerValue(question.questionKey, as: [String].self) ?? [])
        return VStack(alignment: .leading, spacing: 8) {
            questionHeader(question)
            let columns = [GridItem(.adaptive(minimum: 140), spacing: 8)]
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(options, id: \.self) { option in
                    let isSelected = current.contains(option)
                    Button {
                        var updated = current
                        if isSelected { updated.remove(option) } else { updated.insert(option) }
                        if updated.isEmpty {
                            setInterviewAnswer(nil, for: question.questionKey)
                        } else {
                            setInterviewAnswer(Array(updated), for: question.questionKey)
                        }
                    } label: {
                        Text(option)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .frame(maxWidth: .infinity)
                            .background(isSelected ? AppColors.primary.opacity(0.85) : AppColors.mainSurface)
                            .foregroundColor(isSelected ? AppColors.onPrimary : AppColors.textPrimary)
                            .cornerRadius(10)
                    }
                }
            }
        }
    }

    private func scaleResponseView(for question: LogicInterviewQuestion) -> AnyView {
        let min = question.scaleMin ?? 1
        let max = question.scaleMax ?? 5
        if min > max { return AnyView(EmptyView()) }
        let value = answerValue(question.questionKey, as: Int.self)
        return AnyView(
            VStack(alignment: .leading, spacing: 8) {
                questionHeader(question)
                HStack(spacing: 8) {
                    ForEach(min...max, id: \.self) { number in
                        let isSelected = value == number
                        Button {
                            if isSelected {
                                setInterviewAnswer(nil, for: question.questionKey)
                            } else {
                                setInterviewAnswer(number, for: question.questionKey)
                            }
                        } label: {
                            Text("\(number)")
                                .font(.subheadline)
                                .frame(width: 36, height: 36)
                                .background(isSelected ? AppColors.primary : AppColors.mainSurface)
                                .foregroundColor(isSelected ? AppColors.onPrimary : AppColors.textPrimary)
                                .cornerRadius(8)
                        }
                    }
                }
            }
        )
    }

    private func yesNoButton(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isSelected ? AppColors.primary : AppColors.mainSurface)
                .foregroundColor(isSelected ? AppColors.onPrimary : AppColors.textPrimary)
                .cornerRadius(10)
        }
    }

    private func answerValue<T>(_ questionKey: String, as type: T.Type = T.self) -> T? {
        interviewAnswers[questionKey]?.value as? T
    }

    private func setInterviewAnswer(_ value: Any?, for questionKey: String) {
        if let value {
            interviewAnswers[questionKey] = AnyCodable(value)
        } else {
            interviewAnswers.removeValue(forKey: questionKey)
        }
        interviewDirty = true
    }

    private var readinessSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizedString("readiness_title", lang))
                .font(.headline)
            Text(LocalizedString("readiness_help", lang))
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
                Text(LocalizedString("domain_required_message", lang))
                    .font(.caption2)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LocalizedString("notes_optional", lang))
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
            Text(LocalizedString("needs_title", lang))
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
                Text(LocalizedString("mark_completed", lang))
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
            Text(LocalizedString("mark_completed_subtext", lang))
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
        let interviewsChanged = interviewDirty || 
            interviewAnswers.count != savedInterviewSnapshot.count ||
            Set(interviewAnswers.keys) != Set(savedInterviewSnapshot.keys)
        return existingReadiness != readiness ||
            existingNotes != notes ||
            Set(existingNeeds) != selectedNeeds ||
            interviewsChanged
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
                errorMessage = LocalizedString("error_fill_readiness", lang)
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

        interviewAnswers.forEach { questionKey, value in
            let storageKey = DomainAnswerKey.interviewQuestion(domain.key, questionKey: questionKey)
            payloadDict[storageKey] = value
        }

        let payloads = AssessmentAnswerPayloadBuilder.payloads(from: payloadDict, assessmentId: assessmentId)
        do {
            try await assessmentService.upsertAnswers(payloads)
            await MainActor.run {
                payloadDict.forEach { key, value in
                    allAnswers[key] = value
                    if key.hasPrefix("\(domain.key)."),
                       !DomainAnswerKey.isSpecialKey(key, forDomain: domain.key) {
                        let questionKey = String(key.dropFirst(domain.key.count + 1))
                        interviewAnswers[questionKey] = value
                    }
                }
                savedInterviewSnapshot = interviewAnswers
                interviewDirty = false
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
