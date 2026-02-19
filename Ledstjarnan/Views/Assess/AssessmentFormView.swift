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
    @State private var showSummary = false
    @State private var showInsatskartra = false
    @State private var showRecommendations = false
    @State private var missingKeys: Set<String> = []
    @State private var insatsRecommendations: [InterventionRecommendation] = []
    @State private var insatsSafetyFlags: [SafetyFlag] = []
    @State private var insatsPTSD: PTSDEvaluation?
    @State private var dismissAfterResult = false
    @State private var isFinishingAssessment = false
    @State private var pendingScrollDomainKey: String?
    @State private var planBuilderStartStep: PlanBuilderView.PlanBuilderStep = .focus
    @State private var planBuilderFocusSelection: Set<String> = []
    @State private var navigateToPlanBuilder = false
    private let assessmentService = AssessmentService()
    private let clientService = ClientService()
    private let chapterSuggestionMap: [String: [String]] = [
        "health": ["Kropp & Hälsa – KrisKlar", "Sömn & rutiner"],
        "education": ["Utbildning & arbete – Startplan", "Struktur i vardagen"],
        "social": ["Relationer & kommunikation", "DBT-färdigheter"],
        "independence": ["Självständighet – Budget basics", "Vardag & ADL"],
        "relationships": ["Nätverk & stödpersoner", "Familjekarta"],
        "identity": ["Identitet & framtidstro", "Min berättelse"],
        "substance": ["Livlinan – Återfallsprevention", "Motivationsplan A-CRA"],
        "attachment": ["Trygga relationer", "Signs of Safety"],
        "mentalHealth": ["Må bra-plan", "Känslohantering"],
        "severeMentalHealth": ["Krisplan & säkerhet", "Psykologkontakt"],
        "trauma": ["Traumasäker start", "Livlinan – PTSD-stöd"]
    ]
    private var requiredSalutogenicScaleKeys: [String] {
        AssessmentDefinition.domains.flatMap { domain in
            domain.questions.compactMap { question -> String? in
                if case .scale = question.type {
                    return "\(domain.key).\(question.key)"
                }
                return nil
            }
        }
    }

    private var requiredProblemScoreKeys: [String] {
            AssessmentDefinition.pathogenicModules
            .filter { $0.usesStandardIMPScores }
            .flatMap { module in
                [
                    ProblemQuestionKeys.clientScore,
                    ProblemQuestionKeys.importance,
                    ProblemQuestionKeys.staffAssessment
                ].map { "\(module.key).\($0)" }
            }
    }

    private var requiredTraumaSymptomKeys: [String] {
        (22...46).map { "trauma.q\($0)" }
    }

    private var requiredTraumaBooleanKeys: [String] {
        ["trauma.adultEventsMultiple", "trauma.childEventsMultiple"] + (47...52).map { "trauma.q\($0)" }
    }

    private var requiredKeys: [String] {
        Array(Set(requiredSalutogenicScaleKeys + requiredProblemScoreKeys + requiredTraumaSymptomKeys + requiredTraumaBooleanKeys))
    }

    private var answerKeysSignature: [String] {
        Array(answers.keys).sorted()
    }

    private var isBaseline: Bool { assessmentType == "baseline" }
    private var domainScores: [AssessmentDomainScore] {
        AssessmentDefinition.scores(from: answers)
    }

    private var summaryDomains: [AssessmentSummaryDomain] {
        AssessmentDefinition.domains.map { domain in
            let score = domainScores.first { $0.domain.id == domain.id }
            return AssessmentSummaryDomain(
                domainKey: domain.key,
                title: domain.title,
                valueText: score?.formattedAverage ?? "—",
                isCompleted: (score?.answeredCount ?? 0) > 0
            )
        }
    }

    private var problemSummaryDomains: [AssessmentSummaryDomain] {
        let lookup = Dictionary(uniqueKeysWithValues: buildDomainScores(from: answers).map { ($0.domainKey, $0) })
        return AssessmentDefinition.pathogenicModules.map { module in
            let score = lookup[module.key]
            let valueText = score.map { "\($0.iScore)/5" } ?? "—"
            return AssessmentSummaryDomain(
                domainKey: module.key,
                title: module.title,
                valueText: valueText,
                isCompleted: score != nil
            )
        }
    }

    private var completedDomainCount: Int {
        summaryDomains.filter { $0.isCompleted }.count
    }

    private var missingDomainCount: Int {
        max(summaryDomains.count - completedDomainCount, 0)
    }

    private var summaryKeyNotes: String {
        let manual = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        var allNotes: [String] = []
        if !manual.isEmpty { allNotes.append(manual) }
        for (key, value) in answers {
            guard key.lowercased().hasSuffix("notes"),
                  let text = value.value as? String else { continue }
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                allNotes.append(trimmed)
            }
        }
        if allNotes.isEmpty {
            return "No notes yet."
        }
        return allNotes.map { "• \($0)" }.joined(separator: "\n")
    }

    private var recommendationFocuses: [AssessmentRecommendationFocus] {
        insatsRecommendations
            .sorted { $0.needLevel.priorityScore > $1.needLevel.priorityScore }
            .map { AssessmentRecommendationFocus(domainKey: $0.domainKey, title: $0.domainTitle, needLevel: $0.needLevel) }
    }

    private var suggestedChaptersList: [String] {
        chapterSuggestions(from: insatsRecommendations)
    }

    @ViewBuilder
    private var assessmentContent: some View {
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
        } else {
            assessmentBody
        }
    }

    @ViewBuilder
    private var assessmentBody: some View {
        if let currentAssessment = assessment {
            domainsHeader
            if currentAssessment.status == "completed", insatsPTSD != nil {
                Button {
                    showInsatskartra = true
                } label: {
                    Label("View Insatskarta", systemImage: "map")
                        .font(.subheadline.bold())
                        .foregroundColor(AppColors.onPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(AppColors.primary)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            if !missingKeys.isEmpty {
                ValidationBannerView(
                    missingCount: missingKeys.count,
                    totalCount: requiredKeys.count
                )
                .padding(.horizontal)
            }
            salutogenicSection
            problemAreasSection
            traumaSection
            notesSection
            saveCompleteButtons
        }
    }

    private var domainsHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            scoresCarousel
            HStack {
                Text("Domains")
                    .font(.title3.weight(.semibold))
                Spacer()
                Button {
                    Task { await presentSummary() }
                } label: {
                    Label("Summary", systemImage: "chart.bar")
                        .font(.subheadline)
                }
            }
        }
        .padding(.horizontal)
    }

    private var salutogenicSection: some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Del 1: Salutogena livsområden")
                    .font(.title2.bold())
                    .foregroundColor(AppColors.textPrimary)
                Text("Skala: 1 = stort behov av stöd, 5 = inget behov av stöd")
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            .padding(.horizontal)

            ForEach(AssessmentDefinition.domains, id: \.key) { domain in
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: domain.icon)
                            .foregroundColor(AppColors.primary)
                            .font(.title3)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(domain.title)
                                .font(.headline)
                                .foregroundColor(AppColors.textPrimary)
                            Text(domain.subtitle)
                                .font(.subheadline)
                                .foregroundColor(AppColors.textSecondary)
                        }
                        Spacer()
                    }

                    ForEach(domain.questions, id: \.key) { q in
                        questionView(domainKey: domain.key, question: q)
                    }
                    priorityPicker(
                        storageKey: "\(domain.key).\(DomainQuestionKeys.priority)",
                        title: "Prioritering",
                        helpText: "Styr vilka områden som bör prioriteras i planen."
                    )
                }
                .padding()
                .background(AppColors.secondarySurface)
                .cornerRadius(12)
                .padding(.horizontal)
                .id("domain-\(domain.key)")
            }
        }
    }

    private var problemAreasSection: some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Del 2: Problemområden")
                    .font(.title2.bold())
                    .foregroundColor(AppColors.textPrimary)
                    .padding(.top, 20)
                Text("Skala: 1 = inget problem, 5 = allvarligt problem")
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            .padding(.horizontal)

            ForEach(AssessmentDefinition.allProblemDomains, id: \.key) { domain in
                ProblemAreaFormView(domain: domain, answers: $answers, missingKeys: missingKeys)
                    .padding([.top, .bottom], 8)
            }
        }
    }

    private var traumaSection: some View {
        VStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("Del 3: Traumabedömning (STRESS)")
                    .font(.title2.bold())
                    .foregroundColor(AppColors.textPrimary)
                    .padding(.top, 20)
                Text("Strukturerad intervju om traumatiska erfarenheter och PTSD-symtom")
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            .padding(.horizontal)

            TraumaScreeningView(answers: $answers, missingKeys: missingKeys)
                .padding([.top, .bottom], 8)
            priorityPicker(
                storageKey: "trauma.\(ProblemQuestionKeys.priority)",
                title: "Prioritering (trauma)",
                helpText: "Sätt prioritet för traumarelaterade insatser."
            )
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Anteckningar")
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
        .padding(.top, 20)
    }

    private var saveCompleteButtons: some View {
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
            Button(action: { Task { await presentSummary() } }) {
                Text("Complete")
                    .font(.headline)
                    .foregroundColor(AppColors.onPrimary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppColors.primary)
                    .cornerRadius(12)
            }
            .disabled(isSaving)
        }
        .padding()
    }

    var body: some View {
        ZStack {
            NavigationLink(
                destination: PlanBuilderView(
                    appState: appState,
                    client: client,
                    plan: nil,
                    clientName: client.displayName,
                    startStep: planBuilderStartStep,
                    prefilledFocusDomains: planBuilderFocusSelection
                ),
                isActive: $navigateToPlanBuilder
            ) { EmptyView() }
            .hidden()

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        assessmentContent
                    }
                }
                .padding(.vertical, 20)
                .onChange(of: pendingScrollDomainKey) { newValue in
                    guard let key = newValue else { return }
                    withAnimation(.easeInOut) {
                        proxy.scrollTo(key, anchor: .top)
                    }
                    pendingScrollDomainKey = nil
                }
            }
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
                completedCount: completedDomainCount,
                totalCount: summaryDomains.count,
                domains: summaryDomains,
                keyNotes: summaryKeyNotes,
                problemDomains: problemSummaryDomains,
                missingDomainCount: missingDomainCount,
                canViewRecommendation: !recommendationFocuses.isEmpty,
                onDomainTapped: { domainKey in
                    pendingScrollDomainKey = "domain-\(domainKey)"
                    showSummary = false
                },
                onViewRecommendation: {
                    showSummary = false
                    showRecommendations = true
                },
                onFinish: {
                    Task { await completeAssessment() }
                },
                isFinishing: isFinishingAssessment
            )
        }
        .sheet(isPresented: $showRecommendations, onDismiss: {
            if dismissAfterResult {
                dismissAfterResult = false
                dismiss()
            }
        }) {
            AssessmentRecommendationView(
                client: client,
                assessmentType: assessmentType,
                focusSuggestions: recommendationFocuses,
                suggestedChapters: suggestedChaptersList,
                isClientLinked: client.isLinked,
                onClose: { showRecommendations = false },
                onGoToPlanBuilder: { domains in
                    openPlanBuilder(with: domains, step: .focus)
                },
                onAssignChapters: {
                    openPlanBuilder(with: [], step: .chapters)
                },
                onOpenInsatskarta: insatsRecommendations.isEmpty ? nil : {
                    showRecommendations = false
                    showInsatskartra = true
                }
            )
        }
        .sheet(isPresented: $showInsatskartra, onDismiss: {
            if dismissAfterResult {
                dismissAfterResult = false
                dismiss()
            }
        }) {
            if let ptsd = insatsPTSD {
                InsatskartraView(
                    recommendations: insatsRecommendations,
                    safetyFlags: insatsSafetyFlags,
                    ptsd: ptsd,
                    clientName: client.displayName
                )
            } else {
                ProgressView()
                    .padding()
            }
        }
        .onChange(of: answerKeysSignature) { _ in
            updateValidationState()
        }
    }

    @ViewBuilder
    private func questionView(domainKey: String, question: AssessmentQuestion) -> some View {
        let key = "\(domainKey).\(question.key)"
        switch question.type {
        case .scale(let low, let high):
            let binding: Binding<Int?> = Binding(
                get: { answers[key]?.value as? Int },
                set: { newValue in
                    if let value = newValue {
                        answers[key] = AnyCodable(value)
                    } else {
                        answers.removeValue(forKey: key)
                    }
                }
            )
            let options = Array(low...high)
            VStack(alignment: .leading, spacing: 6) {
                Text(question.label)
                    .font(.subheadline)
                    .foregroundColor(AppColors.textSecondary)
                HStack(spacing: 8) {
                    ForEach(options, id: \.self) { n in
                        let isSelected = binding.wrappedValue == n
                        Button(action: {
                            if isSelected {
                                binding.wrappedValue = nil
                            } else {
                                binding.wrappedValue = n
                            }
                        }) {
                            Text("\(n)")
                                .font(.subheadline)
                                .fontWeight(isSelected ? .semibold : .regular)
                                .foregroundColor(isSelected ? AppColors.onPrimary : AppColors.textPrimary)
                                .frame(width: 36, height: 36)
                                .background(isSelected ? AppColors.primary : AppColors.mainSurface)
                                .cornerRadius(8)
                        }
                    }
                }
                if isKeyMissing(key) {
                    Text("Required")
                        .font(.caption2)
                        .foregroundColor(AppColors.danger)
                }
            }
        case .text:
            let binding: Binding<String> = Binding(
                get: { answers[key]?.value as? String ?? "" },
                set: { newValue in
                    if newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        answers.removeValue(forKey: key)
                    } else {
                        answers[key] = AnyCodable(newValue)
                    }
                }
            )
            VStack(alignment: .leading, spacing: 6) {
                Text(question.label)
                    .font(.subheadline)
                    .foregroundColor(AppColors.textSecondary)
                TextField("", text: binding)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(isKeyMissing(key) ? AppColors.danger.opacity(0.1) : AppColors.mainSurface)
                    .cornerRadius(8)
            }
        case .priority:
            priorityPicker(
                storageKey: key,
                title: question.label,
                helpText: "Hög = direkt fokus, Låg = kan avvakta."
            )
        }
    }

    private func priorityPicker(storageKey: String, title: String, helpText: String) -> some View {
        let binding: Binding<Int> = Binding(
            get: { answers[storageKey]?.value as? Int ?? 2 },
            set: { newValue in
                answers[storageKey] = AnyCodable(newValue)
            }
        )
        let options: [(label: String, value: Int)] = [("Hög", 1), ("Medel", 2), ("Låg", 3)]
        return VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundColor(AppColors.textPrimary)
            Text(helpText)
                .font(.caption)
                .foregroundColor(AppColors.textSecondary)
            HStack(spacing: 8) {
                ForEach(options, id: \.value) { option in
                    let isSelected = binding.wrappedValue == option.value
                    Button {
                        binding.wrappedValue = option.value
                    } label: {
                        Text(option.label)
                            .font(.subheadline.weight(isSelected ? .semibold : .regular))
                            .foregroundColor(isSelected ? AppColors.onPrimary : AppColors.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(isSelected ? AppColors.primary : AppColors.mainSurface)
                            .cornerRadius(10)
                    }
                }
            }
        }
        .padding(.top, 4)
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
                    updateValidationState()
                }
                if a.status == "completed" {
                    try await runSummaryPipeline(assessmentId: a.id, answersSnapshot: dict, persist: false)
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
                    updateValidationState()
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
        guard assessment != nil else { return }
        isSaving = true
        errorMessage = nil
        do {
            try await persistAssessment(status: "draft", completedAt: nil)
            await MainActor.run { isSaving = false }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isSaving = false
            }
        }
    }

    private func presentSummary() async {
        guard let a = assessment else { return }
        do {
            try await runSummaryPipeline(assessmentId: a.id, persist: false)
            await MainActor.run {
                showSummary = true
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func completeAssessment() async {
        guard let a = assessment else { return }
        updateValidationState()
        guard missingKeys.isEmpty else {
            errorMessage = "Complete all required fields before submitting."
            return
        }
        await MainActor.run {
            isFinishingAssessment = true
            errorMessage = nil
        }
        do {
            let completionDate = Date()
            try await persistAssessment(status: "completed", completedAt: completionDate)
            try await runSummaryPipeline(assessmentId: a.id)

            if let unitId = appState.currentUnit?.id,
               let staffId = appState.currentStaffProfile?.id {
                let title = assessmentType == "baseline" ? "Baseline completed" : "Follow-up completed"
                let description = "Completed \(completedDomainCount)/\(summaryDomains.count) domains."
                try? await clientService.createTimelineEvent(
                    clientId: client.id,
                    unitId: unitId,
                    eventType: "assessment_completed",
                    title: title,
                    description: description,
                    staffId: staffId
                )
            }

            await MainActor.run {
                isFinishingAssessment = false
                showSummary = false
                dismissAfterResult = true
                showRecommendations = true
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isFinishingAssessment = false
            }
        }
    }

    private func persistAssessment(status: String, completedAt: Date?) async throws {
        guard let a = assessment else { return }
        let payloads = buildAnswerPayloads(assessmentId: a.id)
        try await assessmentService.upsertAnswers(payloads)
        try await assessmentService.updateAssessment(
            id: a.id,
            status: status,
            completedAt: completedAt,
            notes: notePayload
        )
    }

    private func buildAnswerPayloads(assessmentId: String) -> [AssessmentAnswerPayload] {
        answers.compactMap { key, value in
            let parts = key.split(separator: ".", maxSplits: 1).map(String.init)
            guard parts.count == 2 else { return nil }
            return AssessmentAnswerPayload(
                assessment_id: assessmentId,
                domain_key: parts[0],
                question_key: parts[1],
                value: value
            )
        }
    }

    private var notePayload: String? {
        let trimmed = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : notes
    }

    private func runSummaryPipeline(
        assessmentId: String,
        answersSnapshot: [String: AnyCodable]? = nil,
        persist: Bool = true
    ) async throws {
        let snapshot = answersSnapshot ?? answers
        let ptsd = ScoringEngine.evaluatePTSD(answers: snapshot)
        let domainScores = buildDomainScores(from: snapshot, ptsd: ptsd)
        let safetyFlags = ScoringEngine.evaluateSafetyFlags(
            answers: snapshot,
            ptsd: ptsd,
            problemScores: domainScores.filter { $0.scoreType == .pathogenic }
        )
        let recommendations = ScoringEngine.buildRecommendations(domainScores: domainScores, ptsd: ptsd)

        if persist {
            try await assessmentService.saveSummaryFields(
                assessmentId: assessmentId,
                ptsdScore: ptsd.totalSymptomScore,
                ptsdProbable: ptsd.probablePTSD,
                safetyFlags: safetyFlags,
                recommendations: recommendations,
                domainScores: domainScores
            )
        }

        await MainActor.run {
            insatsRecommendations = recommendations
            insatsSafetyFlags = safetyFlags
            insatsPTSD = ptsd
        }
    }

    private func buildDomainScores(from data: [String: AnyCodable], ptsd: PTSDEvaluation? = nil) -> [DomainScore] {
        var results: [DomainScore] = []
        let ptsdEvaluation = ptsd ?? ScoringEngine.evaluatePTSD(answers: data)

        for module in AssessmentDefinition.salutogenicModules {
            let base = "\(module.key)."
            let clientKey = base + DomainQuestionKeys.clientScore
            let importanceKey = base + DomainQuestionKeys.importance
            let staffKey = base + DomainQuestionKeys.staffAssessment
            let priorityKey = base + DomainQuestionKeys.priority
            let noteKey = base + DomainQuestionKeys.notes
            let noteValue = trimmedString(for: noteKey, in: data) ?? ""

            let hasScores = data[clientKey] != nil ||
                data[importanceKey] != nil ||
                data[staffKey] != nil ||
                !noteValue.isEmpty
            guard hasScores else { continue }

            results.append(DomainScore(
                domainKey: module.key,
                iScore: intAnswer(forKey: clientKey, defaultValue: 3, in: data),
                iScoreStaff: intAnswer(forKey: staffKey, defaultValue: 3, in: data),
                mScore: intAnswer(forKey: importanceKey, defaultValue: 3, in: data),
                pScore: intAnswer(forKey: priorityKey, defaultValue: 2, in: data),
                notes: noteValue,
                scoreType: module.scoreType
            ))
        }

        for module in AssessmentDefinition.pathogenicModules where module.usesStandardIMPScores {
            let prefix = "\(module.key)."
            let clientKey = prefix + ProblemQuestionKeys.clientScore
            let importanceKey = prefix + ProblemQuestionKeys.importance
            let staffKey = prefix + ProblemQuestionKeys.staffAssessment
            let priorityKey = prefix + ProblemQuestionKeys.priority
            let note = collectProblemNotes(for: module, in: data)

            let hasScoringData = data[clientKey] != nil ||
                data[importanceKey] != nil ||
                data[staffKey] != nil ||
                !note.isEmpty
            guard hasScoringData else { continue }

            results.append(DomainScore(
                domainKey: module.key,
                iScore: intAnswer(forKey: clientKey, defaultValue: 1, in: data),
                iScoreStaff: intAnswer(forKey: staffKey, defaultValue: 1, in: data),
                mScore: intAnswer(forKey: importanceKey, defaultValue: 3, in: data),
                pScore: intAnswer(forKey: priorityKey, defaultValue: 2, in: data),
                notes: note,
                scoreType: module.scoreType
            ))
        }

        if let traumaModule = AssessmentDefinition.pathogenicModules.first(where: { !$0.usesStandardIMPScores }) {
            let traumaPrefix = "\(traumaModule.key)."
            let hasTraumaAnswers = data.keys.contains { $0.hasPrefix("trauma.") }
            if hasTraumaAnswers {
                let priorityKey = traumaPrefix + ProblemQuestionKeys.priority
                let traumaScore = DomainScore(
                    domainKey: traumaModule.key,
                    iScore: traumaNeedScore(from: ptsdEvaluation),
                    iScoreStaff: traumaStaffScore(from: ptsdEvaluation),
                    mScore: 3,
                    pScore: intAnswer(forKey: priorityKey, defaultValue: 1, in: data),
                    notes: traumaNotes(from: ptsdEvaluation),
                    scoreType: traumaModule.scoreType
                )
                results.append(traumaScore)
            }
        }

        return results
    }

    private func traumaNeedScore(from eval: PTSDEvaluation) -> Int {
        switch eval.totalSymptomScore {
        case 0: return 1
        case 1...8: return 2
        case 9...20: return 3
        case 21...35: return 4
        default: return 5
        }
    }

    private func traumaStaffScore(from eval: PTSDEvaluation) -> Int {
        if eval.probablePTSD { return 5 }
        if eval.requiresPsychologist { return 4 }
        return 2
    }

    private func traumaNotes(from eval: PTSDEvaluation) -> String {
        [
            "Totalpoäng: \(eval.totalSymptomScore)",
            "Probable PTSD: \(eval.probablePTSD ? "Ja" : "Nej")",
            "Symtomkriterier: B \(eval.criterionBMet ? "✓" : "–"), C \(eval.criterionCMet ? "✓" : "–"), D \(eval.criterionDMet ? "✓" : "–"), E \(eval.criterionEMet ? "✓" : "–")",
            eval.functionalImpairment ? "Funktionspåverkan rapporterad" : nil,
            eval.dissociation ? "Dissociation rapporterad" : nil
        ]
        .compactMap { $0 }
        .joined(separator: "\n")
    }

    private func collectProblemNotes(for module: AssessmentModule, in data: [String: AnyCodable]) -> String {
        let prefix = "\(module.key)."
        var noteValues: [String] = []

        if let manual = trimmedString(for: prefix + ProblemQuestionKeys.notes, in: data) {
            noteValues.append(manual)
        }

        let specifyValues = data
            .filter { $0.key.hasPrefix(prefix) && $0.key.hasSuffix("_specify") }
            .compactMap { ($0.value.value as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        noteValues.append(contentsOf: specifyValues)
        return noteValues.joined(separator: "\n")
    }

    private func intAnswer(forKey key: String, defaultValue: Int, in data: [String: AnyCodable]) -> Int {
        if let value = data[key]?.value as? Int {
            return value
        }
        return defaultValue
    }

    private func trimmedString(for key: String, in data: [String: AnyCodable]) -> String? {
        guard let raw = data[key]?.value as? String else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func chapterSuggestions(from recs: [InterventionRecommendation]) -> [String] {
        guard !recs.isEmpty else { return [] }
        var results: [String] = []
        let sorted = recs.sorted { $0.needLevel.priorityScore > $1.needLevel.priorityScore }
        for rec in sorted {
            let options = chapterSuggestionMap[rec.domainKey] ?? [rec.domainTitle]
            for chapter in options where !results.contains(chapter) {
                results.append(chapter)
                if results.count >= 5 { return results }
            }
        }
        return results
    }

    private func openPlanBuilder(with domains: Set<String>, step: PlanBuilderView.PlanBuilderStep) {
        planBuilderStartStep = step
        planBuilderFocusSelection = step == .focus ? domains : []
        dismissAfterResult = false
        showRecommendations = false
        navigateToPlanBuilder = true
    }

    private func updateValidationState(source: [String: AnyCodable]? = nil) {
        let data = source ?? answers
        let missing = requiredKeys.filter { !hasValue(forKey: $0, in: data) }
        missingKeys = Set(missing)
    }

    private func hasValue(forKey key: String, in data: [String: AnyCodable]) -> Bool {
        guard let value = data[key]?.value else { return false }
        if let intValue = value as? Int {
            return true
        }
        if let boolValue = value as? Bool {
            return true
        }
        if let arrayValue = value as? [Any] {
            return !arrayValue.isEmpty
        }
        if let stringValue = value as? String {
            return !stringValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        return true
    }

    private func isKeyMissing(_ key: String) -> Bool {
        missingKeys.contains(key)
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
        .shadow(color: AppColors.shadow(), radius: 8, y: 4)
    }
}

struct ValidationBannerView: View {
    let missingCount: Int
    let totalCount: Int

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(AppColors.onDanger)
                .padding(8)
                .background(AppColors.danger)
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text("Complete required fields")
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary)
                Text("\(missingCount) of \(totalCount) questions still need attention.")
                    .font(.subheadline)
                    .foregroundColor(AppColors.textSecondary)
            }
            Spacer()
        }
        .padding()
        .background(AppColors.danger.opacity(0.1))
        .cornerRadius(14)
    }
}

private extension NeedLevel {
    var priorityScore: Int {
        switch self {
        case .high: return 4
        case .mediumHigh: return 3
        case .mediumLow: return 2
        case .low: return 1
        }
    }
}
