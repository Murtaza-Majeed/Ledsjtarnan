//
//  CreateClientView.swift
//  Ledstjarnan
//
//  Created by Murtaza Majeed on 2026-01-29.
//

import SwiftUI

struct CreateClientView: View {
    @ObservedObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    var onCreated: (() -> Void)?
    
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var dateOfBirth = Date()
    @State private var isCreating = false
    @State private var errorMessage: String?
    
    private let clientService = ClientService()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(AppColors.primary)
                    }
                    
                    Text("Create client")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Spacer()
                }
                .padding()
                .background(AppColors.mainSurface)
                
                ScrollView {
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("First name")
                                .font(.subheadline)
                                .foregroundColor(AppColors.textSecondary)
                            TextField("", text: $firstName)
                                .textFieldStyle(.plain)
                                .padding()
                                .background(AppColors.secondarySurface)
                                .cornerRadius(8)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Last name")
                                .font(.subheadline)
                                .foregroundColor(AppColors.textSecondary)
                            TextField("", text: $lastName)
                                .textFieldStyle(.plain)
                                .padding()
                                .background(AppColors.secondarySurface)
                                .cornerRadius(8)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Date of birth")
                                .font(.subheadline)
                                .foregroundColor(AppColors.textSecondary)
                            DatePicker("", selection: $dateOfBirth, displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .padding()
                                .background(AppColors.secondarySurface)
                                .cornerRadius(8)
                        }
                    }
                    .padding()
                }
                
                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(AppColors.danger)
                        .padding(.horizontal)
                }
                
                // Actions
                Button(action: {
                    createClient()
                }) {
                    HStack {
                        if isCreating {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Create")
                                .font(.headline)
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppColors.primary)
                    .cornerRadius(12)
                }
                .padding()
                .background(AppColors.mainSurface)
                .disabled(isCreating || firstName.isEmpty || lastName.isEmpty)
            }
            .background(AppColors.background)
        }
    }
    
    private func createClient() {
        guard let unitId = appState.currentUnit?.id else {
            errorMessage = "No unit. Complete your profile first."
            return
        }
        guard let staffId = appState.currentStaffProfile?.id else {
            errorMessage = "Staff profile not loaded."
            return
        }
        let nameOrCode = "\(firstName.trimmingCharacters(in: .whitespaces)) \(lastName.trimmingCharacters(in: .whitespaces))".trimmingCharacters(in: .whitespaces)
        guard !nameOrCode.isEmpty else { return }
        
        errorMessage = nil
        isCreating = true
        Task {
            do {
                _ = try await clientService.createClient(unitId: unitId, nameOrCode: nameOrCode, createdByStaffId: staffId)
                await MainActor.run {
                    isCreating = false
                    onCreated?()
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isCreating = false
                }
            }
        }
    }
}

#Preview {
    CreateClientView(appState: AppState(), onCreated: nil)
}
