//
//  NotificationPreferencesView.swift
//  Ledstjarnan
//

import SwiftUI

struct NotificationPreferencesView: View {
    @ObservedObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var followupsDue = true
    @State private var sessions = true
    @State private var scheduleChanges = true
    @State private var quietStart = "22:00"
    @State private var quietEnd = "07:00"
    @State private var isSaving = false
    @State private var errorMessage: String?
    private let staffService = StaffService()
    
    private var lang: String { appState.languageCode }

    var body: some View {
        Form {
            Section {
                Toggle(LocalizedString("notifications_followups", lang), isOn: $followupsDue)
                Toggle("Sessions", isOn: $sessions)
                Toggle(LocalizedString("schedule_event_type", lang), isOn: $scheduleChanges)
            }
            Section("Quiet hours") {
                TextField("Start (e.g. 22:00)", text: $quietStart)
                    .keyboardType(.numbersAndPunctuation)
                TextField("End (e.g. 07:00)", text: $quietEnd)
                    .keyboardType(.numbersAndPunctuation)
            }
            if let error = errorMessage {
                Section {
                    Text(error)
                        .foregroundColor(AppColors.danger)
                }
            }
        }
        .navigationTitle(LocalizedString("notifications_title", lang))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(LocalizedString("general_save", lang)) { Task { await save() } }
                    .disabled(isSaving)
            }
        }
        .onAppear {
            if let prefs = appState.currentStaffProfile?.notificationPrefs {
                followupsDue = prefs.followupsDue
                sessions = prefs.sessions
                scheduleChanges = prefs.scheduleChanges
                quietStart = prefs.quietStart
                quietEnd = prefs.quietEnd
            }
        }
    }

    private func save() async {
        guard let staffId = appState.currentStaffProfile?.id else { return }
        isSaving = true
        errorMessage = nil
        let prefs = NotificationPreferences(
            followupsDue: followupsDue,
            sessions: sessions,
            scheduleChanges: scheduleChanges,
            quietStart: quietStart,
            quietEnd: quietEnd
        )
        do {
            try await staffService.updateNotificationPreferences(staffId: staffId, prefs: prefs)
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
        NotificationPreferencesView(appState: AppState())
    }
}
