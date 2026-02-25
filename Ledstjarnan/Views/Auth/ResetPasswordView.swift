//
//  ResetPasswordView.swift
//  Ledstjarnan
//
//  Created by Murtaza Majeed on 2026-01-29.
//

import SwiftUI

struct ResetPasswordView: View {
    @ObservedObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var email = ""
    @State private var isSending = false
    @State private var showSuccess = false
    
    private var lang: String { appState.languageCode }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(AppColors.primary)
                    }
                    
                    Text(LocalizedString("auth_reset_title", lang))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Spacer()
                }
                .padding()
                .background(AppColors.mainSurface)
                
                ScrollView {
                    VStack(spacing: 24) {
                        if showSuccess {
                            VStack(spacing: 16) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(AppColors.success)
                                
                                Text("Email sent")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(AppColors.textPrimary)
                                
                                Text(LocalizedString("auth_reset_success", lang))
                                    .font(.subheadline)
                                    .foregroundColor(AppColors.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.top, 60)
                        } else {
                            VStack(alignment: .leading, spacing: 16) {
                                Text(LocalizedString("auth_reset_subtitle", lang))
                                    .font(.body)
                                    .foregroundColor(AppColors.textPrimary)
                                    .padding(.top, 40)
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(LocalizedString("auth_reset_email", lang))
                                        .font(.subheadline)
                                        .foregroundColor(AppColors.textSecondary)
                                    TextField("", text: $email)
                                        .textFieldStyle(.plain)
                                        .padding()
                                        .background(AppColors.secondarySurface)
                                        .cornerRadius(8)
                                        .autocapitalization(.none)
                                        .keyboardType(.emailAddress)
                                }
                                
                                // Note box
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("• Check spam/junk folder")
                                    Text("• Link expires after 1 hour")
                                }
                                .font(.caption)
                                .foregroundColor(AppColors.textSecondary)
                                .padding()
                                .background(AppColors.secondarySurface)
                                .cornerRadius(8)
                            }
                            .padding(.horizontal)
                        }
                        
                        Spacer()
                    }
                }
                
                // Actions
                VStack(spacing: 12) {
                    if showSuccess {
                        Button(action: { dismiss() }) {
                            Text(LocalizedString("auth_reset_back_to_login", lang))
                                .font(.headline)
                                .foregroundColor(AppColors.onPrimary)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(AppColors.primary)
                                .cornerRadius(12)
                        }
                    } else {
                        Button(action: {
                            sendResetLink()
                        }) {
                            HStack {
                                if isSending {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: AppColors.onPrimary))
                                } else {
                                    Text(LocalizedString("auth_reset_button", lang))
                                        .font(.headline)
                                }
                            }
                            .foregroundColor(AppColors.onPrimary)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppColors.primary)
                            .cornerRadius(12)
                        }
                        .disabled(isSending || email.isEmpty)
                        
                        Button(action: { dismiss() }) {
                            Text(LocalizedString("auth_reset_back_to_login", lang))
                                .font(.subheadline)
                                .foregroundColor(AppColors.primary)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.clear)
                        }
                    }
                }
                .padding()
                .background(AppColors.mainSurface)
            }
            .background(AppColors.background)
        }
    }
    
    private func sendResetLink() {
        isSending = true
        
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            showSuccess = true
            isSending = false
        }
    }
}

#Preview {
    ResetPasswordView(appState: AppState())
}
