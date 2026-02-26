//
//  PlanListView.swift
//  Ledstjarnan
//

import SwiftUI

struct PlanListView: View {
    @ObservedObject var appState: AppState
    @State private var plans: [Plan] = []
    @State private var clientNames: [String: String] = [:]
    @State private var loading = true
    @State private var loadError: String?
    @State private var selectedTab: PlanTab = .active
    @State private var searchText = ""
    private let planService = PlanService()
    private let clientService = ClientService()
    
    private var lang: String { appState.languageCode }

    enum PlanTab: CaseIterable {
        case active
        case past
        
        func label(lang: String) -> String {
            switch self {
            case .active: return LocalizedString("plans_filter_active", lang)
            case .past: return LocalizedString("plans_filter_completed", lang)
            }
        }
    }

    var filteredPlans: [Plan] {
        let list = selectedTab == .active
            ? plans.filter { $0.status == "active" || $0.status == "draft" }
            : plans.filter { $0.status == "archived" }
        if searchText.isEmpty { return list }
        let lower = searchText.lowercased()
        return list.filter {
            (clientNames[$0.clientId] ?? "").lowercased().contains(lower) ||
            ($0.title ?? "").lowercased().contains(lower)
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                HStack {
                    Text(LocalizedString("plans_title", lang))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.textPrimary)
                    Spacer()
                }
                .padding()
                .background(AppColors.mainSurface)

                HStack(spacing: 0) {
                    ForEach(PlanTab.allCases, id: \.self) { tab in
                        Button(action: { selectedTab = tab }) {
                            Text(tab.label(lang: lang))
                                .font(.subheadline)
                                .fontWeight(selectedTab == tab ? .semibold : .regular)
                                .foregroundColor(selectedTab == tab ? AppColors.primary : AppColors.textSecondary)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)

                if loading {
                    ProgressView(LocalizedString("plans_loading", lang))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = loadError {
                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(AppColors.danger)
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(filteredPlans) { plan in
                            NavigationLink(destination: PlanDetailView(appState: appState, plan: plan, clientName: clientNames[plan.clientId] ?? "Client")) {
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(clientNames[plan.clientId] ?? "—")
                                            .font(.headline)
                                            .foregroundColor(AppColors.textPrimary)
                                        Text(plan.title ?? LocalizedString("plans_untitled", lang))
                                            .font(.subheadline)
                                            .foregroundColor(AppColors.textSecondary)
                                    }
                                    Spacer()
                                    Text(plan.status)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(plan.status == "active" ? AppColors.onSuccess : AppColors.textPrimary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(plan.status == "active" ? AppColors.success : AppColors.secondarySurface)
                                        .cornerRadius(6)
                                }
                                .padding(.vertical, 4)
                            }
                            .listRowBackground(AppColors.mainSurface)
                        }
                    }
                    .listStyle(.plain)
                    .background(AppColors.background)
                }
            }
            .background(AppColors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    NavigationLink(destination: PlanClientPickerView(appState: appState)) {
                        Image(systemName: "plus")
                            .foregroundColor(AppColors.primary)
                    }
                }
            }
            .task {
                await loadPlans()
            }
            .refreshable {
                await loadPlans()
            }
        }
    }

    private func loadPlans() async {
        guard let unitId = appState.currentUnit?.id else {
            await MainActor.run { loadError = "No unit."; loading = false }
            return
        }
        loading = true
        loadError = nil
        do {
            let planList = try await planService.getPlans(unitId: unitId)
            let clientList = try await clientService.getClients(unitId: unitId)
            var names: [String: String] = [:]
            for c in clientList { names[c.id] = c.displayName }
            await MainActor.run {
                plans = planList
                clientNames = names
                loading = false
            }
        } catch {
            await MainActor.run {
                loadError = error.localizedDescription
                loading = false
            }
        }
    }
}

struct PlanClientPickerView: View {
    @ObservedObject var appState: AppState
    @State private var clients: [Client] = []
    @State private var loading = true
    @State private var loadError: String?
    private let clientService = ClientService()

    var body: some View {
        Group {
            if loading {
                ProgressView(LocalizedString("general_loading", appState.languageCode))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = loadError {
                Text(error)
                    .font(.subheadline)
                    .foregroundColor(AppColors.danger)
                    .padding()
            } else {
                List(clients) { client in
                    NavigationLink(destination: PlanBuilderView(appState: appState, client: client, plan: nil, clientName: client.displayName)) {
                        HStack {
                            Text(client.displayName)
                                .foregroundColor(AppColors.textPrimary)
                        }
                    }
                    .listRowBackground(AppColors.mainSurface)
                }
                .listStyle(.plain)
            }
        }
        .background(AppColors.background)
        .navigationTitle(LocalizedString("plans_new_plan_title", appState.languageCode))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadClients()
        }
    }

    private func loadClients() async {
        guard let unitId = appState.currentUnit?.id else {
            await MainActor.run { loadError = "No unit."; loading = false }
            return
        }
        do {
            let list = try await clientService.getClients(unitId: unitId)
            await MainActor.run { clients = list; loading = false }
        } catch {
            await MainActor.run { loadError = error.localizedDescription; loading = false }
        }
    }
}

#Preview {
    PlanListView(appState: AppState())
}
