//
//  ClientsListView.swift
//  Ledstjarnan
//
//  Created by Murtaza Majeed on 2026-01-29.
//

import SwiftUI

struct ClientsListView: View {
    @ObservedObject var appState: AppState
    @State private var searchText = ""
    @State private var showCreateClient = false
    @State private var clients: [Client] = []
    @State private var isLoading = false
    @State private var loadError: String?
    
    private let clientService = ClientService()
    
    var filteredClients: [Client] {
        if searchText.isEmpty {
            return clients
        }
        return clients.filter { $0.displayName.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AppColors.textSecondary)
                    TextField("Search clients...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding()
                .background(AppColors.secondarySurface)
                .cornerRadius(8)
                .padding()
                
                // Content
                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                            .tint(AppColors.primary)
                        Text("Loading clients...")
                            .font(.subheadline)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = loadError {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(AppColors.danger)
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Button("Retry") {
                            loadClients()
                        }
                        .foregroundColor(AppColors.primary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredClients.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "person.2.slash")
                            .font(.system(size: 50))
                            .foregroundColor(AppColors.mutedNeutral)
                        Text(clients.isEmpty ? "No clients yet" : "No clients found")
                            .font(.headline)
                            .foregroundColor(AppColors.textSecondary)
                        if clients.isEmpty, appState.currentUnit != nil {
                            Text("Add a client with the + button")
                                .font(.subheadline)
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(filteredClients) { client in
                        NavigationLink(destination: ClientProfileView(appState: appState, client: client)) {
                            ClientRow(client: client)
                        }
                        .listRowBackground(AppColors.mainSurface)
                    }
                    .listStyle(.plain)
                    .background(AppColors.background)
                }
            }
            .background(AppColors.background)
            .navigationTitle("Clients")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showCreateClient = true
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(AppColors.primary)
                    }
                }
            }
            .sheet(isPresented: $showCreateClient) {
                CreateClientView(appState: appState) {
                    loadClients()
                }
            }
            .task {
                loadClients()
            }
            .onChange(of: appState.currentUnit?.id) { _, _ in
                loadClients()
            }
            .refreshable {
                loadClients()
            }
        }
    }
    
    private func loadClients() {
        guard let unitId = appState.currentUnit?.id else {
            loadError = "No unit selected. Complete your profile."
            clients = []
            return
        }
        loadError = nil
        isLoading = true
        Task {
            do {
                let list = try await clientService.getClients(unitId: unitId)
                await MainActor.run {
                    clients = list
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    loadError = error.localizedDescription
                    clients = []
                    isLoading = false
                }
            }
        }
    }
}

struct ClientRow: View {
    let client: Client
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(AppColors.primary.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(String(client.displayName.prefix(1)))
                        .font(.headline)
                        .foregroundColor(AppColors.primary)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(client.displayName)
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary)
                
                Text(client.statusLabel)
                    .font(.subheadline)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(AppColors.mutedNeutral)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    ClientsListView(appState: AppState())
}
