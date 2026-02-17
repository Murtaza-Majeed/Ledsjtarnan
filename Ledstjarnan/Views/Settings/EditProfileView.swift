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

    var body: some View {
        Form {
            Section {
                TextField("Full name", text: $fullName)
                TextField("Role", text: $role)
            }
            if let error = errorMessage {
                Section {
                    Text(error)
                        .foregroundColor(AppColors.danger)
                }
            }
        }
        .navigationTitle("Edit profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { Task { await save() } }
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
