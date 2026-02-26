//
//  ContactSupportView.swift
//  Ledstjarnan
//
//  Created by Murtaza Majeed on 2026-01-29.
//

import SwiftUI
import UIKit

struct ContactSupportView: View {
    @ObservedObject var appState: AppState
    @State private var issueType: SupportTicket.IssueType = .bug
    @State private var locationPath = ""
    @State private var subject = ""
    @State private var message = ""
    @State private var isSending = false
    @State private var showSuccess = false
    @State private var errorMessage: String?
    private let supportService = SupportService()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if showSuccess {
                    SuccessCard()
                        .padding(.top, 60)
                } else {
                    formContent
                }
            }
            .padding(.bottom, 20)
        }
        .background(AppColors.background)
        .navigationTitle(LocalizedString("contact_support_title", appState.languageCode))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !showSuccess {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: sendTicket) {
                        if isSending {
                            ProgressView()
                        } else {
                            Text(LocalizedString("general_send", appState.languageCode))
                        }
                    }
                    .disabled(!canSubmit)
                }
            }
        }
    }
    
    private var canSubmit: Bool {
        !subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !isSending
    }
    
    private var formContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(LocalizedString("contact_support_message_hint", appState.languageCode))
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
                .padding(.horizontal)
            Picker(LocalizedString("contact_support_subject", appState.languageCode), selection: $issueType) {
                ForEach(SupportTicket.IssueType.allCases, id: \.rawValue) { type in
                    Text(type.displayName).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            VStack(spacing: 16) {
                InputField(title: LocalizedString("schedule_title", appState.languageCode), placeholder: "e.g. Clients > Anna > Timeline", text: $locationPath)
                InputField(title: LocalizedString("contact_support_subject", appState.languageCode), placeholder: LocalizedString("contact_support_subject", appState.languageCode), text: $subject)
                VStack(alignment: .leading, spacing: 8) {
                    Text(LocalizedString("contact_support_message", appState.languageCode))
                        .font(.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                    TextEditor(text: $message)
                        .frame(minHeight: 180)
                        .padding(8)
                        .background(AppColors.secondarySurface)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal)
            
            if let error = errorMessage {
                Text(error)
                    .font(.subheadline)
                    .foregroundColor(AppColors.danger)
                    .padding(.horizontal)
            }
            
            Spacer(minLength: 40)
        }
    }
    
    private func sendTicket() {
        guard canSubmit else { return }
        isSending = true
        errorMessage = nil
        Task {
            do {
                let staffId = appState.currentStaffProfile?.id
                let unitId = appState.currentUnit?.id
                _ = try await supportService.createTicket(
                    createdByStaffId: staffId,
                    unitId: unitId,
                    issueType: issueType,
                    locationPath: locationPath.isEmpty ? nil : locationPath,
                    description: "\(subject)\n\n\(message)",
                    appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
                    deviceModel: UIDevice.current.model
                )
                await MainActor.run {
                    showSuccess = true
                    isSending = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isSending = false
                }
            }
        }
    }
}

private struct SuccessCard: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 64))
                .foregroundColor(AppColors.success)
            Text(LocalizedString("contact_support_ticket_submitted", "en"))
                .font(.title2.weight(.semibold))
            Text(LocalizedString("contact_support_ticket_message", "en"))
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
}

private struct InputField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .padding()
                .background(AppColors.secondarySurface)
                .cornerRadius(12)
        }
    }
}

#Preview {
    NavigationView {
        ContactSupportView(appState: AppState())
    }
}
