//
//  PlanBuilderView.swift
//  Ledstjarnan
//

import SwiftUI

struct PlanBuilderView: View {
    @ObservedObject var appState: AppState
    let client: Client?
    let plan: Plan?
    let clientName: String?
    let prefilledFocusDomains: Set<String>
    
    @Environment(\.dismiss) var dismiss
    
    @State private var currentPlan: Plan?
    @State private var titleInput: String = ""
    @State private var selectedFocusDomains: Set<String> = []
    
    @State private var goals: [PlanGoal] = []
    @State private var actions: [PlanAction] = []
    @State private var assignments: [ClientChapterAssignment] = []
    @State private var chapters: [LivbojenChapter] = []
    
    @State private var newGoalText = ""
    @State private var newActionTitle = ""
    @State private var newActionWho: String = "staff"
    
    @State private var isLoading = true
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var step: PlanBuilderStep
    
    private let planService = PlanService()
    private let livbojenService = LivbojenService()
    private let assessmentService = AssessmentService()
    
    private var focusOptions: [FocusOption] {
        AssessmentDefinition.domains.map { FocusOption(key: $0.key, title: $0.title, subtitle: $0.subtitle, icon: $0.icon) }
    }
    
    private var focusSelectionDescription: String {
        selectedFocusDomains.isEmpty ? "No focus areas selected" : selectedFocusDomains.count == 1 ? "1 focus area selected" : "\(selectedFocusDomains.count) focus areas selected"
    }
    
    private var clientDisplayName: String {
        client?.displayName ?? clientName ?? "Client"
    }
    
    init(
        appState: AppState,
        client: Client?,
        plan: Plan?,
        clientName: String?,
        startStep: PlanBuilderStep = .focus,
        prefilledFocusDomains: Set<String> = []
    ) {
        self.appState = appState
        self.client = client
        self.plan = plan
        self.clientName = clientName
        self.prefilledFocusDomains = prefilledFocusDomains
        _step = State(initialValue: startStep)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            PlanBuilderProgress(step: step)
                .padding()
            if let error = errorMessage {
                Text(error)
                    .font(.subheadline)
                    .foregroundColor(AppColors.danger)
                    .padding()
            }
            if isLoading {
                ProgressView("Loading plan…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        stepContent
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
            }
            Divider()
            footer
                .padding()
                .background(AppColors.mainSurface)
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationTitle(plan != nil ? "Edit plan" : "New plan")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await setupPlan()
        }
    }
    
    // MARK: - Step Content
    
    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case .focus:
            focusStep
        case .goals:
            goalsStep
        case .actions:
            actionsStep
        case .chapters:
            chaptersStep
        }
    }
    
    private var focusStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Step 1 of 4")
                .font(.caption)
                .foregroundColor(AppColors.textSecondary)
            Text("Name the plan and choose what to focus on.")
                .font(.title3.weight(.semibold))
            TextField("Plan title", text: $titleInput)
                .textFieldStyle(.plain)
                .padding()
                .background(AppColors.mainSurface)
                .cornerRadius(14)
            Text("Focus areas")
                .font(.headline)
            Text(focusSelectionDescription)
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(focusOptions) { option in
                    FocusChip(option: option, isSelected: selectedFocusDomains.contains(option.key)) {
                        if selectedFocusDomains.contains(option.key) {
                            selectedFocusDomains.remove(option.key)
                        } else {
                            selectedFocusDomains.insert(option.key)
                        }
                    }
                }
            }
        }
    }
    
    private var goalsStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Step 2 of 4")
                .font(.caption)
                .foregroundColor(AppColors.textSecondary)
            Text("Define goals to reach the desired outcome.")
                .font(.title3.weight(.semibold))
            if goals.isEmpty {
                Text("No goals yet. Add the first goal below.")
                    .font(.subheadline)
                    .foregroundColor(AppColors.textSecondary)
            } else {
                ForEach(goals) { goal in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(goal.goalText)
                            .font(.headline)
                        Text("Created \(GoalFormatter.shared.string(goal.createdAt))")
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .padding()
                    .background(AppColors.mainSurface)
                    .cornerRadius(14)
                }
            }
            HStack {
                TextField("New goal", text: $newGoalText)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(AppColors.mainSurface)
                    .cornerRadius(14)
                Button("Add") {
                    Task { await addGoal() }
                }
                .disabled(newGoalText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
    
    private var actionsStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Step 3 of 4")
                .font(.caption)
                .foregroundColor(AppColors.textSecondary)
            Text("Break goals into actionable steps.")
                .font(.title3.weight(.semibold))
            if actions.isEmpty {
                Text("No actions yet. Add tasks or sessions below.")
                    .font(.subheadline)
                    .foregroundColor(AppColors.textSecondary)
            } else {
                ForEach(actions) { action in
                    ActionRow(action: action)
                }
            }
            VStack(spacing: 12) {
                TextField("Action title", text: $newActionTitle)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(AppColors.mainSurface)
                    .cornerRadius(14)
                Picker("Who owns this action?", selection: $newActionWho) {
                    Text("Staff").tag("staff")
                    Text("Client").tag("client")
                    Text("Shared").tag("shared")
                }
                .pickerStyle(.segmented)
                Button("Add action") {
                    Task { await addAction() }
                }
                .disabled(newActionTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
    
    private var chaptersStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Step 4 of 4")
                .font(.caption)
                .foregroundColor(AppColors.textSecondary)
            Text("Assign Livbojen chapters.")
                .font(.title3.weight(.semibold))
            Text("Assigned \(assignments.count) chapters")
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
            ForEach(chapters) { chapter in
                let assigned = assignments.contains { $0.chapterId == chapter.id }
                VStack(alignment: .leading, spacing: 6) {
                    Text(chapter.title)
                        .font(.headline)
                    if let description = chapter.description {
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    HStack {
                        if assigned {
                            Text("Assigned")
                                .font(.caption)
                                .foregroundColor(AppColors.success)
                        } else if let cid = clientId, let sid = appState.currentStaffProfile?.id {
                            Button("Assign") {
                                Task { await assignChapter(chapterId: chapter.id, clientId: cid, staffId: sid) }
                            }
                            .font(.subheadline)
                            .foregroundColor(AppColors.primary)
                        }
                        Spacer()
                    }
                }
                .padding()
                .background(AppColors.mainSurface)
                .cornerRadius(14)
            }
        }
    }
    
    private var footer: some View {
        HStack {
            if step != .focus {
                Button("Back") {
                    step = step.previous ?? step
                }
                .buttonStyle(.bordered)
            }
            Spacer()
            Button(primaryButtonTitle) {
                Task { await handlePrimaryAction() }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isProcessing || isLoading)
        }
    }
    
    private var primaryButtonTitle: String {
        switch step {
        case .focus: return "Continue"
        case .goals: return "Continue"
        case .actions: return "Continue"
        case .chapters: return "Activate plan"
        }
    }
    
    // MARK: - Helpers
    
    private var clientId: String? {
        currentPlan?.clientId ?? client?.id
    }
    
    private func setupPlan() async {
        if let existing = plan {
            await loadExistingPlan(existing)
        } else if let client = client, let unitId = appState.currentUnit?.id {
            await createDraftPlan(for: client, unitId: unitId)
        } else {
            await MainActor.run { isLoading = false }
        }
    }
    
    private func loadExistingPlan(_ plan: Plan) async {
        await MainActor.run {
            self.currentPlan = plan
            self.titleInput = plan.title ?? ""
            self.selectedFocusDomains = Set(plan.focusDomains ?? [])
        }
        await loadSupportingData()
    }
    
    private func createDraftPlan(for client: Client, unitId: String) async {
        let staffId = appState.currentStaffProfile?.id
        do {
            let plan = try await planService.createPlan(clientId: client.id, unitId: unitId, createdByStaffId: staffId, title: "Plan för \(client.displayName)")
            await MainActor.run {
                self.currentPlan = plan
                self.titleInput = plan.title ?? ""
                if self.prefilledFocusDomains.isEmpty == false {
                    self.selectedFocusDomains = self.prefilledFocusDomains
                }
            }
            if self.prefilledFocusDomains.isEmpty {
                await autoSelectFocusAreas(from: client.id)
            }
            await loadSupportingData()
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    private func loadSupportingData() async {
        guard let plan = currentPlan, let cid = clientId else { return }
        do {
            async let goalsTask = planService.getGoals(planId: plan.id)
            async let actionsTask = planService.getActions(planId: plan.id)
            async let assignmentsTask = livbojenService.getAssignments(clientId: cid)
            async let chaptersTask = livbojenService.getChapters()
            let (goals, actions, assignments, chapters) = try await (goalsTask, actionsTask, assignmentsTask, chaptersTask)
            await MainActor.run {
                self.goals = goals
                self.actions = actions
                self.assignments = assignments
                self.chapters = chapters
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    private func autoSelectFocusAreas(from clientId: String) async {
        do {
            let assessments = try await assessmentService.getAssessments(clientId: clientId)
            let latest = assessments
                .filter { $0.status == "completed" }
                .sorted {
                    ($0.completedAt ?? Date.distantPast) > ($1.completedAt ?? Date.distantPast)
                }
                .first
            guard
                let domainScores = latest?.domainScores,
                !domainScores.isEmpty
            else { return }

            let allowedKeys = Set(focusOptions.map { $0.key })
            var priorities: [(String, Int)] = []
            for (key, value) in domainScores where allowedKeys.contains(key) {
                if let dict = value.value as? [String: Any],
                   let priority = dict["pScore"] as? Int {
                    priorities.append((key, priority))
                }
            }
            let selection = pickFocusKeys(from: priorities)
            guard !selection.isEmpty else { return }
            await MainActor.run {
                if self.selectedFocusDomains.isEmpty {
                    self.selectedFocusDomains = selection
                }
            }
        } catch {
            // Ignore autofill failures; user can still select manually.
        }
    }

    private func pickFocusKeys(from priorities: [(String, Int)]) -> Set<String> {
        guard !priorities.isEmpty else { return [] }
        let high = priorities.filter { $0.1 <= 1 }
        if !high.isEmpty {
            return Set(high.prefix(3).map { $0.0 })
        }
        let mediumHigh = priorities.filter { $0.1 <= 2 }
        if !mediumHigh.isEmpty {
            return Set(mediumHigh.prefix(3).map { $0.0 })
        }
        let sorted = priorities.sorted { $0.1 < $1.1 }
        return Set(sorted.prefix(3).map { $0.0 })
    }
    
    private func handlePrimaryAction() async {
        guard let planId = currentPlan?.id else { return }
        isProcessing = true
        defer { isProcessing = false }
        switch step {
        case .focus:
            do {
                try await planService.updatePlan(
                    id: planId,
                    title: titleInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : titleInput.trimmingCharacters(in: .whitespacesAndNewlines),
                    focusDomains: selectedFocusDomains.isEmpty ? nil : Array(selectedFocusDomains),
                    status: nil,
                    nextFollowUpAt: nil
                )
                step = .goals
            } catch {
                await MainActor.run { self.errorMessage = error.localizedDescription }
            }
        case .goals:
            step = .actions
        case .actions:
            step = .chapters
        case .chapters:
            await activatePlan()
        }
    }
    
    private func addGoal() async {
        guard let plan = currentPlan else { return }
        let trimmed = newGoalText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        do {
            let goal = try await planService.addGoal(planId: plan.id, areaKey: "general", goalText: trimmed, createdByStaffId: appState.currentStaffProfile?.id)
            await MainActor.run {
                goals.append(goal)
                newGoalText = ""
            }
        } catch {
            await MainActor.run { errorMessage = error.localizedDescription }
        }
    }
    
    private func addAction() async {
        guard let plan = currentPlan else { return }
        let trimmed = newActionTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        do {
            let action = try await planService.addAction(planId: plan.id, areaKey: "general", title: trimmed, who: newActionWho, frequency: nil, lockedSession: false, notes: nil)
            await MainActor.run {
                actions.append(action)
                newActionTitle = ""
            }
        } catch {
            await MainActor.run { errorMessage = error.localizedDescription }
        }
    }
    
    private func assignChapter(chapterId: String, clientId: String, staffId: String) async {
        do {
            let assignment = try await livbojenService.assignChapter(clientId: clientId, chapterId: chapterId, staffId: staffId)
            await MainActor.run {
                assignments.append(assignment)
            }
        } catch {
            await MainActor.run { errorMessage = error.localizedDescription }
        }
    }
    
    private func activatePlan() async {
        guard let plan = currentPlan else { return }
        do {
            try await planService.updatePlan(
                id: plan.id,
                title: titleInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : titleInput.trimmingCharacters(in: .whitespacesAndNewlines),
                focusDomains: selectedFocusDomains.isEmpty ? nil : Array(selectedFocusDomains),
                status: "active",
                nextFollowUpAt: nil
            )
            await MainActor.run {
                dismiss()
            }
        } catch {
            await MainActor.run { errorMessage = error.localizedDescription }
        }
    }
    
    // MARK: - Types
    
    enum PlanBuilderStep: Int, CaseIterable {
        case focus, goals, actions, chapters
        
        var title: String {
            switch self {
            case .focus: return "Focus"
            case .goals: return "Goals"
            case .actions: return "Actions"
            case .chapters: return "Chapters"
            }
        }
        
        var subtitle: String {
            switch self {
            case .focus: return "Set title & focus"
            case .goals: return "Define goals"
            case .actions: return "Plan actions"
            case .chapters: return "Assign Livbojen"
            }
        }
        
        var previous: PlanBuilderStep? {
            PlanBuilderStep(rawValue: rawValue - 1)
        }
    }
    
    struct FocusOption: Identifiable {
        var id: String { key }
        let key: String
        let title: String
        let subtitle: String
        let icon: String
    }
}

// MARK: - Subviews

private struct PlanBuilderProgress: View {
    let step: PlanBuilderView.PlanBuilderStep
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Plan builder")
                .font(.caption)
                .foregroundColor(AppColors.textSecondary)
            HStack(spacing: 12) {
                ForEach(PlanBuilderView.PlanBuilderStep.allCases, id: \.rawValue) { current in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Circle()
                                .fill(current.rawValue <= step.rawValue ? AppColors.primary : AppColors.secondarySurface)
                                .frame(width: 12, height: 12)
                            Text(current.title)
                                .font(.footnote.weight(.semibold))
                                .foregroundColor(current.rawValue <= step.rawValue ? AppColors.textPrimary : AppColors.textSecondary)
                        }
                        Text(current.subtitle)
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
        }
    }
}

private struct FocusChip: View {
    let option: PlanBuilderView.FocusOption
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: option.icon)
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(AppColors.onPrimary)
                    }
                }
                Text(option.title)
                    .font(.headline)
                Text(option.subtitle)
                    .font(.caption)
                    .foregroundColor(isSelected ? AppColors.onPrimary.opacity(0.8) : AppColors.textSecondary)
                    .lineLimit(2)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? AppColors.primary : AppColors.secondarySurface)
            .foregroundColor(isSelected ? AppColors.onPrimary : AppColors.textPrimary)
            .cornerRadius(14)
            .shadow(color: isSelected ? AppColors.primary.opacity(0.3) : .clear, radius: 8, y: 4)
        }
    }
}

private struct ActionRow: View {
    let action: PlanAction
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(action.title)
                .font(.headline)
            Text(action.who.capitalized)
                .font(.caption)
                .foregroundColor(AppColors.textSecondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.mainSurface)
        .cornerRadius(14)
    }
}

private final class GoalFormatter {
    static let shared = GoalFormatter()
    private let formatter: DateFormatter
    private init() {
        formatter = DateFormatter()
        formatter.dateStyle = .medium
    }
    
    func string(_ date: Date?) -> String {
        guard let date else { return "Unknown date" }
        return formatter.string(from: date)
    }
}
