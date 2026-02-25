//
//  ClientsListView.swift
//  Ledstjarnan
//
//  Updated clients hub that matches the Ledstjärnan flow.
//

import SwiftUI

struct ClientsListView: View {
    @ObservedObject var appState: AppState
    @State private var searchText = ""
    @State private var showCreateClient = false
    @State private var clientSummaries: [ClientListSummary] = []
    @State private var isLoading = false
    @State private var loadError: String?
    @State private var selectedFilter: ClientListFilter = .all
    @FocusState private var isSearchFocused: Bool
    @State private var navigationClient: Client?
    
    private let clientService = ClientService()
    private var lang: String { appState.languageCode }
    
    private var filteredClients: [ClientListSummary] {
        var list = clientSummaries
        
        if !searchText.isEmpty {
            list = list.filter { summary in
                summary.client.displayName.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        switch selectedFilter {
        case .all:
            break
        case .myClients:
            list = list.filter(\.isMyClient)
        case .dueSoon:
            list = list.filter { $0.isDueSoon }
        case .notLinked:
            list = list.filter(\.isNotLinked)
        case .flags:
            list = list.filter(\.hasFlags)
        }
        
        return list
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                VStack(alignment: .leading, spacing: 16) {
                    searchBar
                    filterChips
                    contentState
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 32)
                
                FloatingAddButton(
                    isDisabled: appState.currentUnit == nil,
                    action: { showCreateClient = true }
                )
                .padding(.trailing, 24)
                .padding(.bottom, 32)
            }
            .background(AppColors.background.ignoresSafeArea())
            .navigationTitle(LocalizedString("clients_title", lang))
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showCreateClient) {
                CreateClientView(appState: appState) { newClient in
                    loadClients()
                    navigationClient = newClient
                }
            }
            .navigationDestination(item: $navigationClient) { client in
                ClientProfileView(appState: appState, client: client) {
                    navigationClient = nil
                    loadClients()
                }
            }
            .task {
                loadClients()
            }
            .onChange(of: appState.currentUnit?.id) { _, _ in
                loadClients()
            }
            .onChange(of: appState.currentStaffProfile?.id) { _, _ in
                loadClients()
            }
        }
    }
    
    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppColors.textSecondary)
            TextField(LocalizedString("clients_search_placeholder", lang), text: $searchText)
                .textFieldStyle(.plain)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($isSearchFocused)
        }
        .padding(14)
        .background(AppColors.secondarySurface)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(AppColors.border, lineWidth: 1)
        )
        .cornerRadius(18)
    }
    
    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(ClientListFilter.allCases) { filter in
                    let isDisabled = (filter == .myClients && appState.currentStaffProfile == nil)
                    FilterChip(
                        label: filter.label(lang: lang),
                        isSelected: selectedFilter == filter,
                        isDisabled: isDisabled
                    ) {
                        guard !(isDisabled && selectedFilter == filter) else { return }
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                            selectedFilter = filter
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    @ViewBuilder
    private var contentState: some View {
        if isLoading {
            LoadingStateView(text: LocalizedString("clients_loading", lang))
        } else if let error = loadError {
            ErrorStateView(message: error, lang: lang) {
                loadClients()
            }
        } else if clientSummaries.isEmpty {
            let message = appState.currentUnit == nil
            ? LocalizedString("clients_empty_no_unit_message", lang)
            : LocalizedString("clients_empty_no_clients_message", lang)
            EmptyClientsState(
                title: appState.currentUnit == nil ? LocalizedString("clients_empty_no_unit_title", lang) : LocalizedString("clients_empty_no_clients_title", lang),
                message: message,
                actionTitle: appState.currentUnit == nil ? nil : LocalizedString("clients_empty_action_new", lang)
            ) {
                showCreateClient = true
            }
        } else if filteredClients.isEmpty {
            EmptyClientsState(
                title: LocalizedString("clients_empty_no_match_title", lang),
                message: LocalizedString("clients_empty_no_match_message", lang),
                actionTitle: LocalizedString("clients_empty_action_reset", lang)
            ) {
                searchText = ""
                selectedFilter = .all
            }
        } else {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(filteredClients) { summary in
                        NavigationLink(
                            destination: ClientProfileView(appState: appState, client: summary.client) {
                                navigationClient = nil
                                loadClients()
                            }
                        ) {
                            ClientListCard(summary: summary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 6)
            }
            .scrollIndicators(.hidden)
            .refreshable {
                loadClients()
            }
        }
    }
    
    private func loadClients() {
        guard let unitId = appState.currentUnit?.id else {
            loadError = LocalizedString("clients_error_no_unit", lang)
            clientSummaries = []
            isLoading = false
            return
        }
        loadError = nil
        isLoading = true
        let staffId = appState.currentStaffProfile?.id
        
        Task {
            do {
                let snapshots = try await clientService.getClientSummaries(unitId: unitId, staffId: staffId)
                await MainActor.run {
                    clientSummaries = snapshots
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    loadError = error.localizedDescription
                    clientSummaries = []
                    isLoading = false
                }
            }
        }
    }
}

private struct ClientListCard: View {
    let summary: ClientListSummary
    
    private static let followUpFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        return formatter
    }()
    
    private var followUpText: String {
        guard let date = summary.nextFollowUpDate else {
            return "Next: Follow-up —"  // This will need appState to localize properly
        }
        return "Next: Follow-up " + Self.followUpFormatter.string(from: date)
    }
    
    private var followUpColor: Color {
        if summary.isOverdue {
            return AppColors.danger
        }
        if summary.isDueSoon {
            return AppColors.primary
        }
        return AppColors.textSecondary
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 12) {
                Text(summary.client.displayName)
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary)
                
                HStack(spacing: 8) {
                    StatusBadge(text: summary.baselineStatusLabel, tone: summary.hasBaseline ? .highlight : .outline)
                    StatusBadge(text: summary.planStatusLabel, tone: summary.hasPlan ? .highlight : .outline)
                    StatusBadge(text: summary.linkStatusLabel, tone: summary.isLinked ? .highlight : .alert)
                }
                
                Text(followUpText)
                    .font(.footnote)
                    .foregroundColor(followUpColor)
            }
            
            Spacer(minLength: 8)
            
            VStack(alignment: .trailing, spacing: 8) {
                if summary.hasFlags {
                    ForEach(summary.flagTypes, id: \.self) { type in
                        FlagBadge(type: type)
                    }
                }
                
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(AppColors.mutedNeutral)
            }
        }
        .padding(16)
        .background(AppColors.mainSurface)
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(AppColors.border, lineWidth: 1)
        )
        .cornerRadius(22)
        .shadow(color: AppColors.shadow(0.03), radius: 8, x: 0, y: 4)
    }
}

private struct StatusBadge: View {
    enum Tone {
        case highlight
        case outline
        case alert
    }
    
    let text: String
    let tone: Tone
    
    private var foreground: Color {
        switch tone {
        case .highlight: return AppColors.primary
        case .outline: return AppColors.textSecondary
        case .alert: return AppColors.danger
        }
    }
    
    private var fill: Color {
        switch tone {
        case .highlight: return AppColors.primary.opacity(0.15)
        case .outline: return AppColors.secondarySurface
        case .alert: return AppColors.danger.opacity(0.15)
        }
    }
    
    private var border: Color {
        switch tone {
        case .highlight: return AppColors.primary.opacity(0.5)
        case .outline: return AppColors.border
        case .alert: return AppColors.danger.opacity(0.6)
        }
    }
    
    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .foregroundColor(foreground)
            .background(
                Capsule()
                    .fill(fill)
            )
            .overlay(
                Capsule()
                    .stroke(border, lineWidth: 1)
            )
    }
}

private struct FlagBadge: View {
    let type: ClientFlagType
    
    var body: some View {
        Text(type.title)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .foregroundColor(AppColors.textPrimary)
            .background(
                Capsule()
                    .fill(AppColors.secondarySurface)
            )
            .overlay(
                Capsule()
                    .stroke(AppColors.border, lineWidth: 1)
            )
    }
}

private struct LoadingStateView: View {
    let text: String
    
    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(AppColors.primary)
            Text(text)
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}

private struct ErrorStateView: View {
    let message: String
    let lang: String
    var retry: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.octagon.fill")
                .font(.system(size: 40))
                .foregroundColor(AppColors.danger)
            Text(LocalizedString("clients_error_load", lang))
                .font(.headline)
                .foregroundColor(AppColors.textPrimary)
            Text(message)
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button(LocalizedString("button_retry", lang), action: retry)
                .buttonStyle(.borderedProminent)
                .tint(AppColors.primary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}

private struct EmptyClientsState: View {
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.2")
                .font(.system(size: 40))
                .foregroundColor(AppColors.mutedNeutral)
            Text(title)
                .font(.headline)
                .foregroundColor(AppColors.textPrimary)
            Text(message)
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            if let title = actionTitle, let action {
                Button(title, action: action)
                    .buttonStyle(.borderedProminent)
                    .tint(AppColors.primary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}

private struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let isDisabled: Bool
    var action: () -> Void
    
    private var background: Color {
        isSelected ? AppColors.primary.opacity(0.15) : AppColors.secondarySurface
    }
    
    private var border: Color {
        isSelected ? AppColors.primary : AppColors.border
    }
    
    private var textColor: Color {
        isSelected ? AppColors.primary : AppColors.textSecondary
    }
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .foregroundColor(textColor)
                .background(
                    Capsule()
                        .fill(background)
                )
                .overlay(
                    Capsule()
                        .stroke(border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.4 : 1.0)
    }
}

private struct FloatingAddButton: View {
    let isDisabled: Bool
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.title2.weight(.semibold))
                .foregroundColor(AppColors.onPrimary)
                .frame(width: 58, height: 58)
                .background(
                    Circle()
                        .fill(AppColors.primary)
                )
                .shadow(color: AppColors.primary.opacity(0.35), radius: 10, x: 0, y: 6)
        }
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.4 : 1.0)
        .accessibilityLabel(LocalizedString("accessibility_new_client", "en"))  // Accessibility uses fixed language
    }
}

private enum ClientListFilter: String, CaseIterable, Identifiable {
    case all
    case myClients
    case dueSoon
    case notLinked
    case flags
    
    var id: String { rawValue }
    
    func label(lang: String) -> String {
        switch self {
        case .all: return LocalizedString("clients_filter_all", lang)
        case .myClients: return LocalizedString("clients_filter_my_clients", lang)
        case .dueSoon: return LocalizedString("clients_filter_due_soon", lang)
        case .notLinked: return LocalizedString("clients_filter_not_linked", lang)
        case .flags: return LocalizedString("clients_filter_flags", lang)
        }
    }
}

#Preview {
    let appState = AppState()
    return ClientsListView(appState: appState)
}
