//
//  CreateClientView.swift
//  Ledstjarnan
//
//  New client flow for Ledstjärnan staff app.
//

import SwiftUI

struct CreateClientView: View {
    @ObservedObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    var onCreated: ((Client) -> Void)?
    
    @State private var nameOrCode: String = ""
    @State private var availableUnits: [Unit] = []
    @State private var selectedUnitId: String?
    @State private var staffOptions: [StaffProfile] = []
    @State private var responsibleStaffId: String?
    @State private var creationError: String?
    @State private var staffLoadError: String?
    @State private var isCreating = false
    @State private var isLoadingStaff = false
    
    private let clientService = ClientService()
    private let staffService = StaffService()
    private var lang: String { appState.languageCode }
    
    private var trimmedName: String {
        nameOrCode.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private var isCreateDisabled: Bool {
        trimmedName.isEmpty || selectedUnitId == nil || responsibleStaffId == nil || isCreating || isLoadingStaff
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header
                ScrollView {
                    VStack(spacing: 24) {
                        FormFieldContainer(title: LocalizedString("create_client_name", lang)) {
                            TextField(LocalizedString("create_client_name_placeholder", lang), text: $nameOrCode)
                                .textFieldStyle(.plain)
                                .padding(.vertical, 8)
                        }
                        
                        FormFieldContainer(title: "Unit") {
                            if availableUnits.isEmpty {
                                Text("No unit available")
                                    .foregroundColor(AppColors.textSecondary)
                            } else {
                                Picker("", selection: $selectedUnitId) {
                                    ForEach(availableUnits) { unit in
                                        Text(unit.displayName).tag(Optional(unit.id))
                                    }
                                }
                                .pickerStyle(.menu)
                                .labelsHidden()
                            }
                        }
                        
                        FormFieldContainer(title: "Responsible staff") {
                            if isLoadingStaff {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(AppColors.primary)
                            } else if staffOptions.isEmpty {
                                Text("No staff in unit")
                                    .foregroundColor(AppColors.textSecondary)
                            } else {
                                Picker("", selection: $responsibleStaffId) {
                                    ForEach(staffOptions) { staff in
                                        Text(staff.fullName)
                                            .tag(Optional(staff.id))
                                    }
                                }
                                .pickerStyle(.menu)
                                .labelsHidden()
                            }
                        }
                        
                        if let staffLoadError {
                            Text(staffLoadError)
                                .font(.caption)
                                .foregroundColor(AppColors.danger)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                }
                
                if let creationError {
                    Text(creationError)
                        .font(.footnote)
                        .foregroundColor(AppColors.danger)
                        .padding(.horizontal, 20)
                }
                
                Button(action: createClient) {
                    HStack(spacing: 8) {
                        if isCreating {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(AppColors.onPrimary)
                        }
                        Text(LocalizedString("create_client_button", lang))
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isCreateDisabled ? AppColors.mutedNeutral : AppColors.primary)
                    .foregroundColor(isCreateDisabled ? AppColors.textPrimary : AppColors.onPrimary)
                    .cornerRadius(16)
                }
                .disabled(isCreateDisabled)
                .padding(20)
                .background(AppColors.mainSurface)
            }
            .background(AppColors.background.ignoresSafeArea())
            .task {
                await bootstrap()
            }
            .onChange(of: selectedUnitId) { _, newValue in
                guard let unitId = newValue else {
                    staffOptions = []
                    responsibleStaffId = nil
                    return
                }
                Task {
                    await loadStaff(for: unitId)
                }
            }
        }
    }
    
    private var header: some View {
        HStack {
            Button(action: { dismiss() }) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                    Text(LocalizedString("general_back", lang))
                }
                .font(.subheadline.weight(.semibold))
                .foregroundColor(AppColors.primary)
            }
            Spacer()
            Text(LocalizedString("create_client_title", lang))
                .font(.title2.weight(.bold))
                .foregroundColor(AppColors.textPrimary)
            Spacer()
            // Spacer button to keep layout balanced
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(AppColors.mainSurface)
    }
    
    private func bootstrap() async {
        await MainActor.run {
            if let unit = appState.currentUnit {
                availableUnits = [unit]
                selectedUnitId = unit.id
            }
        }
        if let unitId = selectedUnitId {
            await loadStaff(for: unitId)
        }
    }
    
    private func loadStaff(for unitId: String) async {
        await MainActor.run {
            isLoadingStaff = true
            staffLoadError = nil
        }
        
        do {
            let staff = try await staffService.getStaffInUnit(unitId: unitId)
            await MainActor.run {
                staffOptions = staff
                if let myId = appState.currentStaffProfile?.id, staffOptions.contains(where: { $0.id == myId }) {
                    responsibleStaffId = myId
                } else {
                    responsibleStaffId = staffOptions.first?.id
                }
                isLoadingStaff = false
            }
        } catch {
            await MainActor.run {
                staffLoadError = "Couldn't load staff list: \(error.localizedDescription)"
                isLoadingStaff = false
            }
        }
    }
    
    private func createClient() {
        guard !trimmedName.isEmpty else {
            creationError = LocalizedString("create_client_validation_name", lang)
            return
        }
        guard let unitId = selectedUnitId else {
            creationError = "Select a unit."
            return
        }
        guard let staffId = responsibleStaffId else {
            creationError = "Select responsible staff."
            return
        }
        guard let creatorId = appState.currentStaffProfile?.id else {
            creationError = "Staff profile not loaded."
            return
        }
        
        creationError = nil
        isCreating = true
        
        Task {
            do {
                let client = try await clientService.createClient(
                    unitId: unitId,
                    nameOrCode: trimmedName,
                    createdByStaffId: creatorId
                )
                try await clientService.assignStaffToClient(clientId: client.id, staffId: staffId, isPrimary: true)
                
                await MainActor.run {
                    isCreating = false
                    onCreated?(client)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    creationError = "\(LocalizedString("create_client_error", lang)). \(error.localizedDescription)"
                    isCreating = false
                }
            }
        }
    }
}

private struct FormFieldContainer<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(AppColors.textPrimary)
            content
                .padding(.horizontal, 12)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppColors.secondarySurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppColors.border, lineWidth: 1)
                )
                .cornerRadius(16)
        }
    }
}

#Preview {
    let appState = AppState()
    appState.currentUnit = Unit(
        id: "unit-123",
        name: "Västerbo HVB Malmö",
        code: "VHM",
        city: "Malmö",
        joinCode: "ABC123",
        joinCodeExpiresAt: nil,
        isActive: true,
        createdAt: Date(),
        updatedAt: Date()
    )
    appState.currentStaffProfile = StaffProfile(
        id: "staff-1",
        email: "staff@example.com",
        fullName: "Sara Staff",
        role: "Behandlingsassistent",
        unitId: "unit-123",
        unitJoinedAt: Date(),
        notificationsEnabled: true,
        notificationPrefs: nil,
        privacyAckAt: nil,
        onboardingCompletedAt: Date(),
        createdAt: Date(),
        updatedAt: Date()
    )
    return CreateClientView(appState: appState, onCreated: nil)
}
