//
//  ClientPickerView.swift
//  Ledstjarnan
//
//  Pick a client from the current unit (e.g. to start an assessment).
//

import SwiftUI

struct ClientPickerView: View {
    @ObservedObject var appState: AppState
    let assessmentType: String
    @State private var clients: [Client] = []
    @State private var loading = true
    @State private var loadError: String?
    private let clientService = ClientService()

    var body: some View {
        Group {
            if loading {
                ProgressView("Loading clients…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = loadError {
                VStack(spacing: 12) {
                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(AppColors.danger)
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else if clients.isEmpty {
                Text("No clients in this unit.")
                    .font(.subheadline)
                    .foregroundColor(AppColors.textSecondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(clients) { client in
                    NavigationLink(destination: AssessmentFormView(appState: appState, client: client, assessmentType: assessmentType)) {
                        HStack {
                            Circle()
                                .fill(AppColors.primary.opacity(0.2))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Text(String(client.displayName.prefix(1)))
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(AppColors.primary)
                                )
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
        .navigationTitle("Select client")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadClients()
        }
    }

    private func loadClients() async {
        guard let unitId = appState.currentUnit?.id else {
            await MainActor.run {
                loadError = "No unit selected."
                loading = false
            }
            return
        }
        loading = true
        loadError = nil
        do {
            let list = try await clientService.getClients(unitId: unitId)
            await MainActor.run {
                clients = list
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
