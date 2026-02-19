//
//  FirstLaunchView.swift
//  Ledstjarnan
//
//  Created by Murtaza Majeed on 2026-01-29.
//

import SwiftUI

struct FirstLaunchView: View {
    @ObservedObject var appState: AppState
    @State private var notificationsEnabled = true
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    private let features: [(icon: String, title: String, detail: String)] = [
        ("doc.text.fill", "Structured baseline & follow-up", "Assess each domain with the Ledstjärnan scale."),
        ("list.bullet.clipboard.fill", "Plans that connect to Livbojen", "Assign goals, chapters and locked sessions."),
        ("calendar", "Joint schedule", "Plan sessions and tasks with one calm view."),
        ("bell.badge", "Gentle reminders", "Keep contact persons ahead of follow-ups.")
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [AppColors.primary.opacity(0.2), AppColors.background],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        VStack(spacing: 10) {
                            Text("Hej!")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(AppColors.onPrimary.opacity(0.8))
                            Text("Welcome to Ledstjärnan")
                                .font(.largeTitle.bold())
                                .foregroundColor(AppColors.onPrimary)
                                .multilineTextAlignment(.center)
                            Text("A structured operating system for HVB teams and support apartments.")
                                .font(.subheadline)
                                .foregroundColor(AppColors.onPrimary.opacity(0.85))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(.top, 40)
                        
                        VStack(spacing: 20) {
                            ForEach(features, id: \.title) { feature in
                                FeatureCard(icon: feature.icon, title: feature.title, detail: feature.detail)
                            }
                        }
                        .padding(.horizontal)
                        
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "bell.badge")
                                    .foregroundColor(AppColors.primary)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Stay on top of sessions")
                                        .font(.headline)
                                    Text("Allow notifications for gentle follow-up reminders.")
                                        .font(.subheadline)
                                        .foregroundColor(AppColors.textSecondary)
                                }
                                Spacer()
                                Toggle("", isOn: $notificationsEnabled)
                                    .labelsHidden()
                            }
                        }
                        .padding(20)
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .padding(.horizontal)
                        
                        if let message = errorMessage {
                            Text(message)
                                .font(.subheadline)
                                .foregroundColor(AppColors.danger)
                        }
                        
                        VStack(spacing: 12) {
                            Button(action: completeOnboarding) {
                                HStack(spacing: 10) {
                                    if isSubmitting {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: AppColors.onPrimary))
                                    } else {
                                        Image(systemName: "sparkles")
                                            .font(.headline)
                                            .foregroundColor(AppColors.onPrimary)
                                    }
                                    Text("Let's get started")
                                        .font(.headline)
                                }
                                .foregroundColor(AppColors.onPrimary)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(AppColors.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .shadow(color: AppColors.primary.opacity(0.35), radius: 12, y: 8)
                            }
                            .disabled(isSubmitting)
                            
                            Button("Maybe later") {
                                Task { await appState.markOnboardingComplete() }
                            }
                            .font(.subheadline)
                            .foregroundColor(AppColors.onPrimary.opacity(0.8))
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 32)
                    }
                }
            }
        }
    }
    
    private func completeOnboarding() {
        errorMessage = nil
        isSubmitting = true
        Task {
            await appState.markOnboardingComplete()
            await MainActor.run { isSubmitting = false }
        }
    }
}

struct FeatureCard: View {
    let icon: String
    let title: String
    let detail: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(AppColors.secondarySurface.opacity(0.6))
                    .frame(width: 48, height: 48)
                Image(systemName: icon)
                    .foregroundColor(AppColors.primary)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary)
                Text(detail)
                    .font(.subheadline)
                    .foregroundColor(AppColors.textSecondary)
            }
            Spacer()
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: AppColors.shadow(), radius: 15, y: 8)
    }
}

#Preview {
    FirstLaunchView(appState: AppState())
}
