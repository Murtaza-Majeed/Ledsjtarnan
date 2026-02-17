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
        .navigationTitle("Contact Support")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !showSuccess {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: sendTicket) {
                        if isSending {
                            ProgressView()
                        } else {
                            Text("Send")
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
            Text("Describe what happened and we'll follow up via email.")
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
                .padding(.horizontal)
            Picker("Issue type", selection: $issueType) {
                ForEach(SupportTicket.IssueType.allCases, id: \.rawValue) { type in
                    Text(type.displayName).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            VStack(spacing: 16) {
                InputField(title: "Screen / location", placeholder: "e.g. Clients > Anna > Timeline", text: $locationPath)
                InputField(title: "Subject", placeholder: "Short summary", text: $subject)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Message")
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
            Text("Ticket submitted")
                .font(.title2.weight(.semibold))
            Text("Our team will reply to your email as soon as we’ve reviewed the issue.")
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
