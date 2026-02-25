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
        let lang = appState.languageCode
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
                            SettingsRow(icon: "person.crop.circle", title: LocalizedString("settings_edit_profile", lang), color: AppColors.primary)
                        }
                        NavigationLink(destination: NotificationPreferencesView(appState: appState)) {
                            SettingsRow(icon: "bell", title: LocalizedString("settings_notifications", lang), color: AppColors.primary)
                        }
                    }
                }

                Section(header: Text(LocalizedString("settings_section_unit", lang))) {
                    if let unit = appState.currentUnit {
                        HStack {
                            Text(unit.displayName)
                                .foregroundColor(AppColors.textPrimary)
                            Spacer()
                        }
                    }
                    Button(action: { showChangeUnit = true }) {
                        SettingsRow(icon: "building.2", title: LocalizedString("settings_change_unit", lang), color: AppColors.primary)
                    }
                }

                Section(header: Text(LocalizedString("settings_section_security", lang))) {
                    NavigationLink(destination: PrivacyAccessView()) {
                        SettingsRow(icon: "lock.shield", title: LocalizedString("settings_privacy_access", lang), color: AppColors.primary)
                    }
                }

                Section(header: Text(LocalizedString("settings_section_help", lang))) {
                    NavigationLink(destination: HelpView(appState: appState)) {
                        SettingsRow(icon: "questionmark.circle.fill", title: LocalizedString("settings_help", lang), color: AppColors.primary)
                    }

                    NavigationLink(destination: AboutView(appState: appState)) {
                        SettingsRow(icon: "info.circle.fill", title: LocalizedString("settings_about", lang), color: AppColors.primary)
                    }
                    
                    NavigationLink(destination: LocalizationDebugView(appState: appState)) {
                        SettingsRow(icon: "ant.fill", title: "Debug Localization", color: AppColors.danger)
                    }
                }

                Section(header: Text(LocalizedString("settings_section_language", lang))) {
                    Picker(LocalizedString("language_picker_label", lang), selection: Binding(
                        get: { appState.languageCode },
                        set: { appState.setLanguage($0) }
                    )) {
                        Text(LocalizedString("language_option_sv", lang))
                            .tag("sv")
                        Text(LocalizedString("language_option_en", lang))
                            .tag("en")
                    }
                    .pickerStyle(.segmented)
                }
                
                Section {
                    Button(action: {
                        showLogoutConfirmation = true
                    }) {
                        SettingsRow(icon: "arrow.right.square.fill", title: LocalizedString("settings_logout", lang), color: AppColors.danger)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .background(AppColors.background)
            .navigationTitle(LocalizedString("settings_nav_title", lang))
            .navigationBarTitleDisplayMode(.inline)
            .confirmationDialog(LocalizedString("settings_logout_prompt", lang), isPresented: $showLogoutConfirmation) {
                Button(LocalizedString("settings_logout", lang), role: .destructive) {
                    Task {
                        await appState.signOut()
                    }
                }
                Button(LocalizedString("general_cancel", lang), role: .cancel) {}
            } message: {
                Text(LocalizedString("settings_logout_detail", lang))
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
        let lang = appState.languageCode
        NavigationView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(LocalizedString("settings_unit_code_label", lang))
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
                    Text(LocalizedString("settings_join_unit_button", lang))
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
            .navigationTitle(LocalizedString("settings_join_unit_title", lang))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(LocalizedString("general_cancel", lang)) { onDismiss() }
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
