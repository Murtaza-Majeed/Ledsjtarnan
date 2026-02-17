//
//  PlanDetailView.swift
//  Ledstjarnan
//

import SwiftUI

struct PlanDetailView: View {
    @ObservedObject var appState: AppState
    let plan: Plan
    let clientName: String
    @State private var goals: [PlanGoal] = []
    @State private var actions: [PlanAction] = []
    @State private var assignments: [ClientChapterAssignment] = []
    @State private var chapters: [LivbojenChapter] = []
    @State private var loading = true
    private let planService = PlanService()
    private let livbojenService = LivbojenService()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(clientName)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.textPrimary)
                    Text(plan.title ?? "Untitled plan")
                        .font(.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                    Text(plan.status)
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppColors.primary)
                        .cornerRadius(6)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(AppColors.mainSurface)
                .cornerRadius(12)
                .padding(.horizontal)

                if loading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    if !goals.isEmpty {
                        sectionTitle("Goals")
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(goals) { g in
                                Text(g.goalText)
                                    .font(.subheadline)
                                    .foregroundColor(AppColors.textPrimary)
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(AppColors.secondarySurface)
                                    .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal)
                    }
                    if !actions.isEmpty {
                        sectionTitle("Actions")
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(actions) { a in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(a.title)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(AppColors.textPrimary)
                                        Text("\(a.who) · \(a.frequency ?? "—")")
                                            .font(.caption)
                                            .foregroundColor(AppColors.textSecondary)
                                    }
                                    Spacer()
                                }
                                .padding()
                                .background(AppColors.secondarySurface)
                                .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal)
                    }
                    if !assignments.isEmpty {
                        sectionTitle("Livbojen chapters")
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(assignments) { a in
                                if let ch = chapters.first(where: { $0.id == a.chapterId }) {
                                    Text(ch.title)
                                        .font(.subheadline)
                                        .foregroundColor(AppColors.textPrimary)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical, 20)
        }
        .background(AppColors.background)
        .navigationTitle("Plan")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink(destination: PlanBuilderView(appState: appState, client: nil, plan: plan, clientName: clientName)) {
                    Text("Edit")
                        .foregroundColor(AppColors.primary)
                }
            }
        }
        .task {
            await loadDetail()
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundColor(AppColors.textPrimary)
            .padding(.horizontal)
    }

    private func loadDetail() async {
        do {
            async let g = planService.getGoals(planId: plan.id)
            async let a = planService.getActions(planId: plan.id)
            async let asn = livbojenService.getAssignments(clientId: plan.clientId)
            async let ch = livbojenService.getChapters()
            let (goalsList, actionsList, assignList, chaptersList) = try await (g, a, asn, ch)
            await MainActor.run {
                goals = goalsList
                actions = actionsList
                assignments = assignList
                chapters = chaptersList
                loading = false
            }
        } catch {
            await MainActor.run { loading = false }
        }
    }
}
