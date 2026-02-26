//
//  ClientScheduleView.swift
//  Ledstjarnan
//

import SwiftUI

struct ClientScheduleView: View {
    @ObservedObject var appState: AppState
    let client: Client
    @State private var items: [PlannerItem] = []
    @State private var loading = true
    @State private var loadError: String?
    @State private var showComposer = false
    @State private var selectedItem: PlannerItem?
    
    private let plannerService = PlannerService()
    
    var body: some View {
        VStack {
            if loading {
                ProgressView(LocalizedString("general_loading", appState.languageCode))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = loadError {
                Text(error)
                    .font(.subheadline)
                    .foregroundColor(AppColors.danger)
                    .padding()
            } else if items.isEmpty {
                ClientEmptyScheduleState(lang: appState.languageCode) {
                    showComposer = true
                }
            } else {
                List(items) { item in
                    Button(action: { selectedItem = item }) {
                        ClientPlannerItemRow(item: item, clientName: client.displayName, lang: appState.languageCode)
                    }
                    .listRowBackground(AppColors.mainSurface)
                }
                .listStyle(.insetGrouped)
            }
        }
        .background(AppColors.background)
        .navigationTitle(LocalizedString("schedule_client_title", appState.languageCode).replacingOccurrences(of: "%@", with: client.displayName))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showComposer = true }) {
                    Image(systemName: "plus")
                        .foregroundColor(AppColors.primary)
                }
            }
        }
        .sheet(isPresented: $showComposer) {
            if let unitId = appState.currentUnit?.id {
                PlannerItemComposer(
                    appState: appState,
                    unitId: unitId,
                    clientIdPreFill: client.id,
                    onSaved: {
                        showComposer = false
                        Task { await loadItems() }
                    }
                )
            }
        }
        .sheet(item: $selectedItem) { item in
            PlannerItemDetailSheet(
                appState: appState,
                item: item,
                clientName: client.displayName,
                onUpdated: {
                    Task { await loadItems() }
                }
            )
        }
        .task {
            await loadItems()
        }
    }
    
    private func loadItems() async {
        do {
            let list = try await plannerService.getItems(clientId: client.id)
            await MainActor.run {
                items = list.sorted { $0.startAt < $1.startAt }
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

private struct ClientEmptyScheduleState: View {
    let lang: String
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 44))
                .foregroundColor(AppColors.primary)
            Text(LocalizedString("schedule_client_no_items", lang))
                .font(.headline)
                .foregroundColor(AppColors.textPrimary)
            Text(LocalizedString("schedule_client_create_hint", lang))
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
            Button(LocalizedString("schedule_add_first_item", lang), action: action)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(AppColors.primary)
                .foregroundColor(AppColors.onPrimary)
                .cornerRadius(12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct ClientPlannerItemRow: View {
    let item: PlannerItem
    let clientName: String
    let lang: String
    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(item.title)
                    .font(.headline)
                Spacer()
                Text(item.type.capitalized)
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            Text(ClientPlannerItemRow.formatter.string(from: item.startAt))
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
            if let endAt = item.endAt {
                Text(LocalizedString("schedule_client_ends_at", lang).replacingOccurrences(of: "%@", with: ClientPlannerItemRow.formatter.string(from: endAt)))
                    .font(.caption)
                    .foregroundColor(AppColors.mutedNeutral)
            }
            if item.isLocked {
                Label(LocalizedString("plan_builder_responsibility_shared", lang), systemImage: "lock.fill")
                    .font(.caption)
                    .foregroundColor(AppColors.primary)
            }
        }
        .padding(.vertical, 8)
    }
}
