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
    
    private var lang: String { appState.languageCode }

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
            .navigationTitle(LocalizedString("assessment_dashboard_title", lang))
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
                if context.type == "baseline" {
                    BaselineDomainsView(appState: appState, client: context.client, openAssessmentId: context.assessmentId)
                } else {
                    FollowUpDomainsView(appState: appState, client: context.client, openAssessmentId: context.assessmentId)
                }
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
            Text(LocalizedString("assessment_select_client", lang))
                .font(.callout)
                .foregroundColor(AppColors.textSecondary)
            Button {
                showClientPicker = true
            } label: {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AppColors.textSecondary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(selectedSummary?.client.displayName ?? LocalizedString("assessment_pick_client", lang))
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(AppColors.textPrimary)
                        Text(LocalizedString("assessment_search_name_code", lang))
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
            QuickStatCard(title: LocalizedString("assessment_baseline_needed", lang), value: baselineNeededCount)
            QuickStatCard(title: LocalizedString("assessment_followups_due", lang), value: followUpsDueCount)
        }
    }

    private var selectedClientCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizedString("assessment_selected_client", lang))
                .font(.headline)
                .foregroundColor(AppColors.textPrimary)

            if let summary = selectedSummary {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(summary.client.displayName)
                                .font(.title3.weight(.semibold))
                            if let date = summary.nextFollowUpDate {
                                Text(String(format: LocalizedString("assessment_next_followup", lang), date.formatted(date: .abbreviated, time: .omitted)))
                                    .font(.caption)
                                    .foregroundColor(AppColors.textSecondary)
                            } else {
                                Text(LocalizedString("assessment_no_followup_scheduled", lang))
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
                            StatusBadge(label: LocalizedString("assessment_flags", lang), icon: "flag.fill", color: Color.orange)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppColors.mainSurface)
                .cornerRadius(24)
            } else {
                Text(isLoading ? LocalizedString("assessment_loading_clients", lang) : LocalizedString("assessment_no_clients_in_unit", lang))
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
            Text(LocalizedString("assessment_actions", lang))
                .font(.headline)
            VStack(spacing: 12) {
                Button {
                    if let client = selectedSummary?.client {
                        baselineNavigationClient = client
                    }
                } label: {
                    Text(selectedSummary?.hasBaseline == true ? LocalizedString("assessment_view_baseline", lang) : LocalizedString("assessment_start_baseline_button", lang))
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
                        followUpNavigation = AssessmentNavigationContext(client: client, type: "followup", assessmentId: nil)
                    }
                } label: {
                    Text(LocalizedString("assessment_start_followup", lang))
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
            Text(LocalizedString("assessment_recent_assessments", lang))
                .font(.headline)
            if isLoading {
                ProgressView()
            } else if recentAssessments.isEmpty {
                Text(LocalizedString("assessment_no_assessments_yet", lang))
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
                                recentNavigation = AssessmentNavigationContext(client: client, type: assessment.assessmentType, assessmentId: assessment.id)
                            }
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(assessment.assessmentType.capitalized)
                                        .font(.subheadline.weight(.semibold))
                                    Text(clientsLookup[assessment.clientId]?.displayName ?? LocalizedString("assessment_unknown_client", lang))
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
                loadError = LocalizedString("assessment_select_unit_prompt", lang)
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
            .navigationTitle(LocalizedString("assessment_select_client_sheet_title", lang))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(LocalizedString("assessment_close", lang)) { showClientPicker = false }
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
    let assessmentId: String?
}
