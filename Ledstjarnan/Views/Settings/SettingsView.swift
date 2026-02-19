//
//  SettingsView.swift
//  Ledstjarnan
//
//  Created by Murtaza Majeed on 2026-01-29.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var appState: AppState
    @State private var showLogoutConfirmation = false
    @State private var showChangeUnit = false

    var body: some View {
        NavigationView {
            List {
                Section {
                    if let profile = appState.currentStaffProfile {
                        HStack {
                            Circle()
                                .fill(AppColors.primary.opacity(0.2))
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Text(String(profile.fullName.prefix(1)))
                                        .font(.headline)
                                        .foregroundColor(AppColors.primary)
                                )
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(profile.fullName)
                                    .font(.headline)
                                    .foregroundColor(AppColors.textPrimary)
                                Text(profile.email)
                                    .font(.subheadline)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 8)
                        NavigationLink(destination: EditProfileView(appState: appState)) {
                            SettingsRow(icon: "person.crop.circle", title: "Edit profile", color: AppColors.primary)
                        }
                        NavigationLink(destination: NotificationPreferencesView(appState: appState)) {
                            SettingsRow(icon: "bell", title: "Notifications", color: AppColors.primary)
                        }
                    }
                }

                Section("Unit") {
                    if let unit = appState.currentUnit {
                        HStack {
                            Text(unit.displayName)
                                .foregroundColor(AppColors.textPrimary)
                            Spacer()
                        }
                    }
                    Button(action: { showChangeUnit = true }) {
                        SettingsRow(icon: "building.2", title: "Change unit", color: AppColors.primary)
                    }
                }

                Section("Security & Privacy") {
                    NavigationLink(destination: PrivacyAccessView()) {
                        SettingsRow(icon: "lock.shield", title: "Privacy & Access", color: AppColors.primary)
                    }
                }

                Section("Help & Support") {
                    NavigationLink(destination: HelpView(appState: appState)) {
                        SettingsRow(icon: "questionmark.circle.fill", title: "Help", color: AppColors.primary)
                    }
                    
                    NavigationLink(destination: AboutView(appState: appState)) {
                        SettingsRow(icon: "info.circle.fill", title: "About", color: AppColors.primary)
                    }
                }
                
                Section {
                    Button(action: {
                        showLogoutConfirmation = true
                    }) {
                        SettingsRow(icon: "arrow.right.square.fill", title: "Log out", color: AppColors.danger)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .background(AppColors.background)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .confirmationDialog("Log out?", isPresented: $showLogoutConfirmation) {
                Button("Log out", role: .destructive) {
                    Task {
                        await appState.signOut()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("You will need to sign in again with your email and password.")
            }
            .sheet(isPresented: $showChangeUnit) {
                ChangeUnitSheet(appState: appState) {
                    showChangeUnit = false
                }
            }
        }
    }
}

// MARK: - Change unit sheet (join by code)
struct ChangeUnitSheet: View {
    @ObservedObject var appState: AppState
    var onDismiss: () -> Void
    @State private var joinCode = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    private let staffService = StaffService()

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Unit code")
                        .font(.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                    TextField("", text: $joinCode)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(AppColors.secondarySurface)
                        .cornerRadius(8)
                        .autocapitalization(.allCharacters)
                        .disableAutocorrection(true)
                }
                .padding(.horizontal)

                if let error = errorMessage {
                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(AppColors.danger)
                        .padding(.horizontal)
                }

                Button(action: joinUnit) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: AppColors.onPrimary))
                        } else {
                            Text("Join unit")
                                .font(.headline)
                        }
                    }
                    .foregroundColor(AppColors.onPrimary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppColors.primary)
                    .cornerRadius(12)
                }
                .disabled(isLoading || joinCode.trimmingCharacters(in: .whitespaces).isEmpty)
                .padding(.horizontal)

                Spacer()
            }
            .padding(.top, 24)
            .background(AppColors.background)
            .navigationTitle("Change unit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onDismiss() }
                }
            }
        }
    }

    private func joinUnit() {
        errorMessage = nil
        isLoading = true
        Task {
            do {
                guard let staffId = appState.currentStaffProfile?.id else {
                    throw StaffServiceError.invalidJoinCode
                }
                let unit = try await staffService.getUnitByJoinCode(joinCode)
                try await staffService.updateStaffUnit(staffId: staffId, unitId: unit.id)
                await appState.loadStaffProfile()
                await MainActor.run {
                    isLoading = false
                    onDismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            Text(title)
                .foregroundColor(AppColors.textPrimary)
        }
    }
}

#Preview {
    SettingsView(appState: AppState())
}
