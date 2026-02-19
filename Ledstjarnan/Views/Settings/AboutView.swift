//
//  AboutView.swift
//  Ledstjarnan
//
//  Created by Murtaza Majeed on 2026-01-29.
//

import SwiftUI

struct AboutView: View {
    @ObservedObject var appState: AppState
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image(systemName: "star.fill")
                    .font(.system(size: 60))
                    .foregroundColor(AppColors.primary)
                    .padding(.top, 40)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Ledstjarnan")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("Version 0.1 (MVP)")
                        .font(.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                    
                    Text("Build date: 2026.01.29")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                    
                    Divider()
                        .background(AppColors.border)
                    
                    Text("For staff at Västerbo Social Omsorg")
                        .font(.subheadline)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("Client app: Livbojen")
                        .font(.subheadline)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("Data is protected and scoped by unit.")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                        .padding(.top, 4)
                }
                .padding()
                .background(AppColors.mainSurface)
                .cornerRadius(12)
                .padding(.horizontal)
                
                VStack(spacing: 0) {
                    NavigationLink(destination: Text("Privacy Policy")) {
                        SettingsRow(icon: "lock.shield.fill", title: "Privacy policy", color: AppColors.primary)
                            .padding()
                            .background(AppColors.mainSurface)
                    }
                    
                    Divider()
                        .background(AppColors.border)
                    
                    NavigationLink(destination: Text("Terms of Use")) {
                        SettingsRow(icon: "doc.text.fill", title: "Terms of use", color: AppColors.primary)
                            .padding()
                            .background(AppColors.mainSurface)
                    }
                    
                    Divider()
                        .background(AppColors.border)
                    
                    NavigationLink(destination: Text("Open Source Licenses")) {
                        SettingsRow(icon: "book.fill", title: "Open source licenses", color: AppColors.primary)
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
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationView {
        AboutView(appState: AppState())
    }
}
