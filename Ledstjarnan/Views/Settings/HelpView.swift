//
//  HelpView.swift
//  Ledstjarnan
//
//  Created by Murtaza Majeed on 2026-01-29.
//

import SwiftUI

struct HelpView: View {
    @ObservedObject var appState: AppState
    
    var body: some View {
        List {
            Section("Get support") {
                NavigationLink(destination: ContactSupportView(appState: appState)) {
                    SettingsRow(icon: "envelope.fill", title: "Contact Support", color: AppColors.primary)
                }
                NavigationLink(destination: StatusUpdatesView()) {
                    SettingsRow(icon: "exclamationmark.triangle.fill", title: "Status & Updates", color: AppColors.primary)
                }
            }
            
            Section("Guides") {
                NavigationLink(destination: FAQView()) {
                    SettingsRow(icon: "questionmark.circle.fill", title: "FAQs", color: AppColors.primary)
                }
                NavigationLink(destination: PrivacyAccessView()) {
                    SettingsRow(icon: "lock.shield", title: "Privacy & Access", color: AppColors.primary)
                }
            }
        }
        .listStyle(.insetGrouped)
        .background(AppColors.background)
        .navigationTitle("Help")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationView {
        HelpView(appState: AppState())
    }
}
