//
//  EditProfileView.swift
//  Ledstjarnan
//

import SwiftUI

struct EditProfileView: View {
    @ObservedObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var fullName = ""
    @State private var role = ""
    @State private var isSaving = false
    @State private var errorMessage: String?
    private let staffService = StaffService()
    
    private var lang: String { appState.languageCode }

    var body: some View {
        Form {
            Section {
                TextField(LocalizedString("edit_profile_name", lang), text: $fullName)
                TextField(LocalizedString("edit_profile_role", lang), text: $role)
            }
            if let error = errorMessage {
                Section {
                    Text(error)
                        .foregroundColor(AppColors.danger)
                }
            }
        }
        .navigationTitle(LocalizedString("edit_profile_title", lang))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(LocalizedString("general_save", lang)) { Task { await save() } }
                    .disabled(isSaving || fullName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .onAppear {
            if let p = appState.currentStaffProfile {
                fullName = p.fullName
                role = p.role
            }
        }
    }

    private func save() async {
        guard let staffId = appState.currentStaffProfile?.id else { return }
        isSaving = true
        errorMessage = nil
        do {
            try await staffService.updateStaffProfile(
                staffId: staffId,
                fullName: fullName.trimmingCharacters(in: .whitespaces),
                role: role.trimmingCharacters(in: .whitespaces).isEmpty ? "Behandlingsassistent" : role.trimmingCharacters(in: .whitespaces)
            )
            await appState.loadStaffProfile()
            await MainActor.run {
                isSaving = false
                dismiss()
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isSaving = false
            }
        }
    }
}

#Preview {
    NavigationView {
        EditProfileView(appState: AppState())
    }
}
