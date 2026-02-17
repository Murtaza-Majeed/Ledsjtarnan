//
//  ClientPlansView.swift
//  Ledstjarnan
//
//  List plans for one client; tap to detail or create new plan.
//

import SwiftUI

struct ClientPlansView: View {
    @ObservedObject var appState: AppState
    let client: Client
    @State private var plans: [Plan] = []
    @State private var loading = true
    @State private var loadError: String?
    private let planService = PlanService()

    var body: some View {
        Group {
            if loading {
                ProgressView("Loading…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = loadError {
                Text(error)
                    .font(.subheadline)
                    .foregroundColor(AppColors.danger)
                    .padding()
            } else {
                List {
                    ForEach(plans) { plan in
                        NavigationLink(destination: PlanDetailView(appState: appState, plan: plan, clientName: client.displayName)) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(plan.title ?? "Untitled plan")
                                        .font(.headline)
                                        .foregroundColor(AppColors.textPrimary)
                                    Text(plan.status)
                                        .font(.caption)
                                        .foregroundColor(AppColors.textSecondary)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowBackground(AppColors.mainSurface)
                    }
                }
                .listStyle(.plain)
            }
        }
        .background(AppColors.background)
        .navigationTitle("Plans – \(client.displayName)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink(destination: PlanBuilderView(appState: appState, client: client, plan: nil, clientName: nil)) {
                    Image(systemName: "plus")
                        .foregroundColor(AppColors.primary)
                }
            }
        }
        .task {
            await loadPlans()
        }
    }

    private func loadPlans() async {
        do {
            let list = try await planService.getPlans(clientId: client.id)
            await MainActor.run {
                plans = list
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
