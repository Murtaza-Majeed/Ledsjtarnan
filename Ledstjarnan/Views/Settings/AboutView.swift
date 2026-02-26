//
//  AboutView.swift
//  Ledstjarnan
//
//  Created by Murtaza Majeed on 2026-01-29.
//

import SwiftUI

struct AboutView: View {
    @ObservedObject var appState: AppState
    @Environment(\.languageCode) var languageCode
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image(systemName: "star.fill")
                    .font(.system(size: 60))
                    .foregroundColor(AppColors.primary)
                    .padding(.top, 40)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text(LocalizedString("app_name", languageCode))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text(LocalizedString("about_version_format", languageCode).replacingOccurrences(of: "%@", with: "0.1 (MVP)"))
                        .font(.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                    
                    Text(LocalizedString("about_build_date_format", languageCode).replacingOccurrences(of: "%@", with: "2026.01.29"))
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                    
                    Divider()
                        .background(AppColors.border)
                    
                    Text(LocalizedString("about_for_staff", languageCode))
                        .font(.subheadline)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text(LocalizedString("about_client_app", languageCode))
                        .font(.subheadline)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text(LocalizedString("about_data_protection", languageCode))
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                        .padding(.top, 4)
                }
                .padding()
                .background(AppColors.mainSurface)
                .cornerRadius(12)
                .padding(.horizontal)
                
                VStack(spacing: 0) {
                    NavigationLink(destination: Text(LocalizedString("about_privacy_policy", languageCode))) {
                        SettingsRow(icon: "lock.shield.fill", title: LocalizedString("about_privacy_policy", languageCode), color: AppColors.primary)
                            .padding()
                            .background(AppColors.mainSurface)
                    }
                    
                    Divider()
                        .background(AppColors.border)
                    
                    NavigationLink(destination: Text(LocalizedString("about_terms_of_service", languageCode))) {
                        SettingsRow(icon: "doc.text.fill", title: LocalizedString("about_terms_of_service", languageCode), color: AppColors.primary)
                            .padding()
                            .background(AppColors.mainSurface)
                    }
                    
                    Divider()
                        .background(AppColors.border)
                    
                    NavigationLink(destination: Text(LocalizedString("about_open_source_licenses", languageCode))) {
                        SettingsRow(icon: "book.fill", title: LocalizedString("about_open_source_licenses", languageCode), color: AppColors.primary)
                            .padding()
                            .background(AppColors.mainSurface)
                    }
                }
                .cornerRadius(12)
                .padding(.horizontal)
            }
            .padding(.bottom, 20)
        }
        .background(AppColors.background)
        .navigationTitle(LocalizedString("settings_about", languageCode))
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationView {
        AboutView(appState: AppState())
    }
}
