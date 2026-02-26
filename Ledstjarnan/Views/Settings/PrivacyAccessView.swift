//
//  PrivacyAccessView.swift
//  Ledstjarnan
//

import SwiftUI

struct PrivacyAccessView: View {
    var body: some View {
        List {
            Section(header: Text(LocalizedString("privacy_data_sharing", "en"))) {
                InfoRow(
                    title: "Livbojen link",
                    detail: "Only active plans share goals/actions with the youth. Staff-only notes stay in Ledstjärnan."
                )
                InfoRow(
                    title: "Row Level Security",
                    detail: "Every query is scoped to your unit automatically. Staff can only see data for the unit they joined."
                )
            }
            
            Section(header: Text(LocalizedString("privacy_role_permissions", "en"))) {
                InfoRow(
                    title: "Contact persons",
                    detail: "Standard staff can create clients, assessments, plans, and schedule items."
                )
                InfoRow(
                    title: "Admins",
                    detail: "Admins manage units, staff access, and Livbojen chapter libraries."
                )
            }
            
            Section(header: Text(LocalizedString("privacy_device_security", "en"))) {
                InfoRow(
                    title: "Biometric lock",
                    detail: "Enable Face ID / Touch ID in iOS Settings → Ledstjärnan to require biometrics when reopening the app."
                )
                InfoRow(
                    title: "Offline data",
                    detail: "Assessments and notes are encrypted on-device. Logging out clears cached data."
                )
            }
        }
        .listStyle(.insetGrouped)
        .background(AppColors.background)
        .navigationTitle(LocalizedString("privacy_access_title", "en"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct InfoRow: View {
    let title: String
    let detail: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
                .foregroundColor(AppColors.textPrimary)
            Text(detail)
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(.vertical, 4)
    }
}
