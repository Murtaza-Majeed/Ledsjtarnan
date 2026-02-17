//
//  AssessDashboardView.swift
//  Ledstjarnan
//
//  Created by Murtaza Majeed on 2026-01-29.
//

import SwiftUI

struct AssessDashboardView: View {
    @ObservedObject var appState: AppState
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Assessment Dashboard")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.textPrimary)
                        .padding(.top, 20)
                    
                    VStack(spacing: 12) {
                        NavigationLink(destination: ClientPickerView(appState: appState, assessmentType: "baseline")) {
                            DashboardCard(
                                icon: "doc.text.fill",
                                title: "Baseline Assessment",
                                subtitle: "Initial client assessment",
                                color: AppColors.primary
                            )
                        }
                        
                        NavigationLink(destination: ClientPickerView(appState: appState, assessmentType: "followup")) {
                            DashboardCard(
                                icon: "arrow.clockwise",
                                title: "Follow-up Assessment",
                                subtitle: "Track progress over time",
                                color: AppColors.primary
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 20)
            }
            .background(AppColors.background)
            .navigationTitle("Assess")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct DashboardCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)
                .frame(width: 50)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(AppColors.mutedNeutral)
        }
        .padding()
        .background(AppColors.mainSurface)
        .cornerRadius(12)
    }
}

#Preview {
    AssessDashboardView(appState: AppState())
}
