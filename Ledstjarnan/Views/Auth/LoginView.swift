//
//  LoginView.swift
//  Ledstjarnan
//
//  Created by Murtaza Majeed on 2026-01-29.
//

import SwiftUI

struct LoginView: View {
    @ObservedObject var appState: AppState
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showResetPassword = false
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [AppColors.primary.opacity(0.25), AppColors.background],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        VStack(spacing: 12) {
                            Circle()
                                .fill(AppColors.onPrimary.opacity(0.2))
                                .frame(width: 90, height: 90)
                                .overlay(
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 36, weight: .medium))
                                        .foregroundColor(AppColors.onPrimary)
                                )
                                .padding(.top, 40)
                            Text("Ledstjärnan")
                                .font(.largeTitle.bold())
                                .foregroundColor(AppColors.onPrimary)
                            Text("Structure, clarity and calm for every contact moment.")
                                .font(.subheadline)
                                .foregroundColor(AppColors.onPrimary.opacity(0.8))
                                .multilineTextAlignment(.center)
                        }
                        
                        VStack(spacing: 20) {
                            Text("Sign in to continue")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .foregroundColor(AppColors.textPrimary)
                            floatingField(
                                title: "Email",
                                text: $email,
                                isSecure: false,
                                keyboard: .emailAddress,
                                icon: "envelope"
                            )
                            floatingField(
                                title: "Password",
                                text: $password,
                                isSecure: true,
                                keyboard: .default,
                                icon: "lock"
                            )
                            HStack {
                                Spacer()
                                Button("Forgot password?") {
                                    showResetPassword = true
                                }
                                .font(.subheadline)
                                .foregroundColor(AppColors.primary)
                            }
                        }
                        .padding(24)
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .shadow(color: AppColors.shadow(0.08), radius: 20, y: 10)
                        .padding(.horizontal)
                        
                        if let error = errorMessage {
                            Text(error)
                                .font(.subheadline)
                                .foregroundColor(AppColors.danger)
                                .padding(.horizontal)
                        }
                        
                        Button(action: { signIn() }) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: AppColors.onPrimary))
                                } else {
                                    Text("Sign in")
                                        .font(.headline)
                                }
                            }
                            .foregroundColor(AppColors.onPrimary)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppColors.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .shadow(color: AppColors.primary.opacity(0.4), radius: 15, y: 8)
                        }
                        .disabled(isLoading || email.isEmpty || password.isEmpty)
                        .padding(.horizontal)
                        
                        Text("Need access? Contact your unit admin.")
                            .font(.footnote)
                            .foregroundColor(AppColors.onPrimary.opacity(0.8))
                            .padding(.bottom, 40)
                    }
                }
            }
            .sheet(isPresented: $showResetPassword) {
                ResetPasswordView(appState: appState)
            }
        }
    }
    
    private func signIn() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let authService = AuthService()
                _ = try await authService.signIn(email: email, password: password)
                
                // AppState will automatically load profile via auth listener
                await appState.checkAuthStatus()
                
                await MainActor.run {
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Incorrect email or password"
                    isLoading = false
                }
            }
        }
    }
    
    private func floatingField(
        title: String,
        text: Binding<String>,
        isSecure: Bool,
        keyboard: UIKeyboardType,
        icon: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(AppColors.textSecondary)
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(AppColors.mutedNeutral)
                if isSecure {
                    SecureField("", text: text)
                        .keyboardType(keyboard)
                } else {
                    TextField("", text: text)
                        .keyboardType(keyboard)
                        .autocapitalization(.none)
                }
            }
            .padding()
            .background(AppColors.secondarySurface.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
}

#Preview {
    LoginView(appState: AppState())
}
