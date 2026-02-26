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
            Section(LocalizedString("settings_section_help", appState.languageCode)) {
                NavigationLink(destination: ContactSupportView(appState: appState)) {
                    SettingsRow(icon: "envelope.fill", title: LocalizedString("settings_contact_support", appState.languageCode), color: AppColors.primary)
                }
                NavigationLink(destination: StatusUpdatesView()) {
                    SettingsRow(icon: "exclamationmark.triangle.fill", title: LocalizedString("status_updates_title", appState.languageCode), color: AppColors.primary)
                }
            }
            
            Section(LocalizedString("help_user_guide", appState.languageCode)) {
                NavigationLink(destination: FAQView()) {
                    SettingsRow(icon: "questionmark.circle.fill", title: LocalizedString("settings_faq", appState.languageCode), color: AppColors.primary)
                }
                NavigationLink(destination: PrivacyAccessView()) {
                    SettingsRow(icon: "lock.shield", title: LocalizedString("settings_privacy_access", appState.languageCode), color: AppColors.primary)
                }
            }
        }
        .listStyle(.insetGrouped)
        .background(AppColors.background)
        .navigationTitle(LocalizedString("help_title", appState.languageCode))
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationView {
        HelpView(appState: AppState())
    }
}
