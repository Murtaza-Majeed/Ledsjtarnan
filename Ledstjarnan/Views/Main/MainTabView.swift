//
//  MainTabView.swift
//  Ledstjarnan
//
//  Created by Murtaza Majeed on 2026-01-29.
//

import SwiftUI

struct MainTabView: View {
    @ObservedObject var appState: AppState
    
    var body: some View {
        TabView {
            ClientsListView(appState: appState)
                .tabItem {
                    Label("Clients", systemImage: "person.2.fill")
                }
            
            AssessDashboardView(appState: appState)
                .tabItem {
                    Label("Assess", systemImage: "doc.text.fill")
                }
            
            PlanListView(appState: appState)
                .tabItem {
                    Label("Plans", systemImage: "list.bullet.clipboard.fill")
                }
            
            ScheduleDashboardView(appState: appState)
                .tabItem {
                    Label("Schedule", systemImage: "calendar.badge.clock")
                }
            
            SettingsView(appState: appState)
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .accentColor(AppColors.primary)
    }
}

#Preview {
    MainTabView(appState: AppState())
}
