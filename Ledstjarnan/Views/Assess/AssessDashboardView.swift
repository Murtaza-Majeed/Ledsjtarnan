//
//  AssessDashboardView.swift
//  Ledstjarnan
//
//  Assessment hub aligned with the new Ledstjärnan flow.
//

import SwiftUI

struct AssessDashboardView: View {
    @ObservedObject var appState: AppState

    @State private var clientSummaries: [ClientListSummary] = []
    @State private var recentAssessments: [Assessment] = []
    @State private var selectedClientId: String?
    @State private var isLoading = false
    @State private var loadError: String?
    @State private var showClientPicker = false
    @State private var pickerSearchText = ""

    @State private var baselineNavigationClient: Client?
    @State private var followUpNavigation: AssessmentNavigationContext?
    @State private var recentNavigation: AssessmentNavigationContext?

    private let clientService = ClientService()
    private let assessmentService = AssessmentService()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    clientSelectorSection
                    quickStatsSection
                    selectedClientCard
                    primaryActions
                    recentAssessmentsSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
            .background(AppColors.background.ignoresSafeArea())
            .navigationTitle("Assess")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showClientPicker) {
                clientPickerSheet
            }
            .navigationDestination(item: $baselineNavigationClient) { client in
                BaselineDomainsView(appState: appState, client: client)
            }
            .navigationDestination(item: $followUpNavigation) { context in
                FollowUpDomainsView(appState: appState, client: context.client)
            }
            .navigationDestination(item: $recentNavigation) { context in
                AssessmentFormView(
                    appState: appState,
                    client: context.client,
                    assessmentType: context.type
                )
            }
            .task {
                await loadData()
            }
            .refreshable {
                await loadData()
            }
            .onChange(of: appState.currentUnit?.id) { _, _ in
                Task { await loadData() }
            }
            .onChange(of: appState.currentStaffProfile?.id) { _, _ in
                Task { await loadData() }
            }
        }
    }

    private var selectedSummary: ClientListSummary? {
        guard let id = selectedClientId else { return clientSummaries.first }
        return clientSummaries.first(where: { $0.client.id == id }) ?? clientSummaries.first
    }

    private var clientsLookup: [String: Client] {
        Dictionary(uniqueKeysWithValues: clientSummaries.map { ($0.client.id, $0.client) })
    }

    private var baselineNeededCount: Int {
        clientSummaries.filter { !$0.hasBaseline }.count
    }

    private var followUpsDueCount: Int {
        clientSummaries.filter { $0.isOverdue || $0.isDueSoon }.count
    }

    // MARK: - Sections

    private var clientSelectorSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Select client")
                .font(.callout)
                .foregroundColor(AppColors.textSecondary)
            Button {
                showClientPicker = true
            } label: {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AppColors.textSecondary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(selectedSummary?.client.displayName ?? "Pick a client")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(AppColors.textPrimary)
                        Text("Search name / code")
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(AppColors.textSecondary)
                }
                .padding(16)
                .frame(maxWidth: .infinity)
                .background(AppColors.secondarySurface)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(AppColors.border, lineWidth: 1)
                )
            }
            if let error = loadError {
                Text(error)
                    .font(.footnote)
                    .foregroundColor(AppColors.danger)
            }
        }
    }

    private var quickStatsSection: some View {
        HStack(spacing: 16) {
            QuickStatCard(title: "Baseline needed", value: baselineNeededCount)
            QuickStatCard(title: "Follow-ups due", value: followUpsDueCount)
        }
    }

    private var selectedClientCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Selected client")
                .font(.headline)
                .foregroundColor(AppColors.textPrimary)

            if let summary = selectedSummary {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(summary.client.displayName)
                                .font(.title3.weight(.semibold))
                            if let date = summary.nextFollowUpDate {
                                Text("Next follow-up: \(date.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.caption)
                                    .foregroundColor(AppColors.textSecondary)
                            } else {
                                Text("No follow-up scheduled")
                                    .font(.caption)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                        }
                        Spacer()
                        StatusBadge(
                            label: summary.baselineStatusLabel,
                            icon: summary.hasBaseline ? "checkmark.seal.fill" : "exclamationmark.triangle.fill",
                            color: summary.hasBaseline ? AppColors.success : Color.orange
                        )
                    }
                    HStack(spacing: 8) {
                        StatusBadge(label: summary.planStatusLabel, icon: "list.clipboard", color: AppColors.primary)
                        StatusBadge(
                            label: summary.linkStatusLabel,
                            icon: summary.isLinked ? "link" : "link.slash",
                            color: summary.isLinked ? AppColors.primary : AppColors.textSecondary
                        )
                        if summary.hasFlags {
                            StatusBadge(label: "Flags", icon: "flag.fill", color: Color.orange)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppColors.mainSurface)
                .cornerRadius(24)
            } else {
                Text(isLoading ? "Loading clients…" : "No clients in this unit.")
                    .font(.subheadline)
                    .foregroundColor(AppColors.textSecondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppColors.mainSurface)
                    .cornerRadius(24)
            }
        }
    }

    private var primaryActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Actions")
                .font(.headline)
            VStack(spacing: 12) {
                Button {
                    if let client = selectedSummary?.client {
                        baselineNavigationClient = client
                    }
                } label: {
                    Text(selectedSummary?.hasBaseline == true ? "View baseline" : "Start baseline")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedSummary?.hasBaseline == true ? AppColors.secondarySurface : AppColors.primary)
                        .foregroundColor(selectedSummary?.hasBaseline == true ? AppColors.textPrimary : AppColors.onPrimary)
                        .cornerRadius(18)
                }
                .disabled(selectedSummary == nil)

                Button {
                    if let client = selectedSummary?.client {
                        followUpNavigation = AssessmentNavigationContext(client: client, type: "followup")
                    }
                } label: {
                    Text("Start follow-up")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColors.primary.opacity(selectedSummary?.hasBaseline == true ? 1 : 0.3))
                        .foregroundColor(AppColors.onPrimary)
                        .cornerRadius(18)
                }
                .disabled(selectedSummary == nil || selectedSummary?.hasBaseline == false)
            }
        }
    }

    private var recentAssessmentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent assessments")
                .font(.headline)
            if isLoading {
                ProgressView()
            } else if recentAssessments.isEmpty {
                Text("No assessments yet.")
                    .font(.subheadline)
                    .foregroundColor(AppColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(AppColors.secondarySurface)
                    .cornerRadius(16)
            } else {
                VStack(spacing: 12) {
                    ForEach(recentAssessments) { assessment in
                        Button {
                            if let client = clientsLookup[assessment.clientId] {
                                recentNavigation = AssessmentNavigationContext(client: client, type: assessment.assessmentType)
                            }
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(assessment.assessmentType.capitalized)
                                        .font(.subheadline.weight(.semibold))
                                    Text(clientsLookup[assessment.clientId]?.displayName ?? "Unknown client")
                                        .font(.subheadline)
                                        .foregroundColor(AppColors.textPrimary)
                                    Text(assessment.createdAt?.formatted(date: .abbreviated, time: .omitted) ?? "—")
                                        .font(.caption)
                                        .foregroundColor(AppColors.textSecondary)
                                }
                                Spacer()
                                Text(assessment.status.capitalized)
                                    .font(.caption2.weight(.bold))
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 8)
                                    .background(AppColors.secondarySurface)
                                    .cornerRadius(10)
                                Image(systemName: "chevron.right")
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(AppColors.mainSurface)
                            .cornerRadius(18)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Data loading

    private func loadData() async {
        guard let unitId = appState.currentUnit?.id else {
            await MainActor.run {
                loadError = "Select a unit in Settings to see assessments."
                clientSummaries = []
                recentAssessments = []
                selectedClientId = nil
                isLoading = false
            }
            return
        }
        isLoading = true
        loadError = nil
        let staffId = appState.currentStaffProfile?.id
        do {
            async let summariesTask = clientService.getClientSummaries(unitId: unitId, staffId: staffId)
            async let assessmentsTask = assessmentService.getRecentAssessments(unitId: unitId, limit: 12)
            let (snapshots, assessments) = try await (summariesTask, assessmentsTask)
            await MainActor.run {
                clientSummaries = snapshots
                recentAssessments = assessments
                if selectedClientId == nil {
                    selectedClientId = snapshots.first?.client.id
                } else if !snapshots.contains(where: { $0.client.id == selectedClientId }) {
                    selectedClientId = snapshots.first?.client.id
                }
                isLoading = false
            }
        } catch {
            await MainActor.run {
                loadError = error.localizedDescription
                clientSummaries = []
                recentAssessments = []
                selectedClientId = nil
                isLoading = false
            }
        }
    }

    // MARK: - Client picker

    private var clientPickerSheet: some View {
        NavigationStack {
            List(filteredPickerClients) { summary in
                Button {
                    selectClient(summary.client.id)
                    showClientPicker = false
                } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(summary.client.displayName)
                                .foregroundColor(AppColors.textPrimary)
                            Text(summary.baselineStatusLabel)
                                .font(.caption)
                                .foregroundColor(AppColors.textSecondary)
                        }
                        Spacer()
                        if summary.client.id == selectedClientId {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(AppColors.primary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .searchable(text: $pickerSearchText)
            .navigationTitle("Select client")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { showClientPicker = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var filteredPickerClients: [ClientListSummary] {
        guard !pickerSearchText.isEmpty else { return clientSummaries }
        return clientSummaries.filter {
            $0.client.displayName.localizedCaseInsensitiveContains(pickerSearchText)
        }
    }

    private func selectClient(_ id: String) {
        selectedClientId = id
    }
}

// MARK: - Supporting Views / Models

private struct QuickStatCard: View {
    let title: String
    let value: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(AppColors.textSecondary)
            Text("\(value)")
                .font(.title2.bold())
                .foregroundColor(AppColors.textPrimary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.secondarySurface)
        .cornerRadius(20)
    }
}

private struct StatusBadge: View {
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
            Text(label)
                .font(.caption.bold())
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(color.opacity(0.15))
        .foregroundColor(color)
        .cornerRadius(10)
    }
}

private struct AssessmentNavigationContext: Identifiable, Hashable {
    let id = UUID()
    let client: Client
    let type: String
}
