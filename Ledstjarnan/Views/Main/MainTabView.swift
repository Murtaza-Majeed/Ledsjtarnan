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
        let lang = appState.languageCode
        TabView {
            ClientsListView(appState: appState)
                .tabItem {
                    Label(LocalizedString("tab_clients", lang), systemImage: "person.2.fill")
                }
            
            AssessDashboardView(appState: appState)
                .tabItem {
                    Label(LocalizedString("tab_assess", lang), systemImage: "doc.text.fill")
                }
            
            PlanListView(appState: appState)
                .tabItem {
                    Label(LocalizedString("tab_plans", lang), systemImage: "list.bullet.clipboard.fill")
                }
            
            ScheduleDashboardView(appState: appState)
                .tabItem {
                    Label(LocalizedString("tab_schedule", lang), systemImage: "calendar.badge.clock")
                }
            
            SettingsView(appState: appState)
                .tabItem {
                    Label(LocalizedString("tab_settings", lang), systemImage: "gearshape.fill")
                }
        }
        .accentColor(AppColors.primary)
    }
}

#Preview {
    MainTabView(appState: AppState())
}
