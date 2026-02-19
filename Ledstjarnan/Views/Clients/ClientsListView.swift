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
            .navigationTitle("Clients")
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
            TextField("Search name / code", text: $searchText)
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
                        label: filter.label,
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
            LoadingStateView(text: "Loading clients…")
        } else if let error = loadError {
            ErrorStateView(message: error) {
                loadClients()
            }
        } else if clientSummaries.isEmpty {
            let message = appState.currentUnit == nil
            ? "Select a unit in Settings to see your caseload."
            : "Tap the + button to add your first client."
            EmptyClientsState(
                title: appState.currentUnit == nil ? "No unit selected" : "No clients yet",
                message: message,
                actionTitle: appState.currentUnit == nil ? nil : "New client"
            ) {
                showCreateClient = true
            }
        } else if filteredClients.isEmpty {
            EmptyClientsState(
                title: "No clients match",
                message: "Try a different search or reset the filters.",
                actionTitle: "Reset filters"
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
            loadError = "No unit selected. Complete your staff profile to choose a unit."
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
            return "Next: Follow-up —"
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
    var retry: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.octagon.fill")
                .font(.system(size: 40))
                .foregroundColor(AppColors.danger)
            Text("Couldn't load clients")
                .font(.headline)
                .foregroundColor(AppColors.textPrimary)
            Text(message)
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button("Retry", action: retry)
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
        .accessibilityLabel("New client")
    }
}

private enum ClientListFilter: String, CaseIterable, Identifiable {
    case all
    case myClients
    case dueSoon
    case notLinked
    case flags
    
    var id: String { rawValue }
    
    var label: String {
        switch self {
        case .all: return "All"
        case .myClients: return "My clients"
        case .dueSoon: return "Due soon"
        case .notLinked: return "Not linked"
        case .flags: return "Flags"
        }
    }
}

#Preview {
    let appState = AppState()
    return ClientsListView(appState: appState)
}
