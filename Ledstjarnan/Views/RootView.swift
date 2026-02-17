//
//  RootView.swift
//  Ledstjarnan
//
//  Created by Murtaza Majeed on 2026-01-29.
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        Group {
            if !appState.hasSeenOnboarding {
                FirstLaunchView(appState: appState)
            } else if !appState.isAuthenticated {
                LoginView(appState: appState)
            } else if appState.currentStaffProfile == nil {
                ProgressView("Loading…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if appState.currentUnit == nil {
                UnitJoinView(appState: appState)
            } else {
                MainTabView(appState: appState)
            }
        }
    }
}

#Preview {
    RootView()
        .environmentObject(AppState())
}
