//
//  ClientProfileView.swift
//  Ledstjarnan
//
//  Redesigned client hub with quick navigation to key flows.
//

import SwiftUI
import Combine
import UIKit

struct ClientProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var appState: AppState
    let client: Client
    let onDeleted: (() -> Void)?
    
    @State private var detail: ClientDetail?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showDeleteConfirm = false
    @State private var isDeletingClient = false
    
    private let clientService = ClientService()

    init(appState: AppState, client: Client, onDeleted: (() -> Void)? = nil) {
        self._appState = ObservedObject(initialValue: appState)
        self.client = client
        self.onDeleted = onDeleted
    }
    
    var body: some View {
        VStack(spacing: 0) {
            topBar
            ScrollView {
                VStack(spacing: 24) {
                    if isLoading {
                        LoadingStateCard()
                    } else if let errorMessage {
                        ErrorStateCard(message: errorMessage) {
                            Task { await loadDetail() }
                        }
                    } else {
                        headerCard
                        quickActions
                        dangerZoneCard
                    }
                }
                .padding(20)
            }
        }
        .background(AppColors.background.ignoresSafeArea())
        .task { await loadDetail() }
        .navigationBarBackButtonHidden(true)
        .confirmationDialog(
            "Delete client?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete client", role: .destructive) {
                Task { await deleteClientRecord() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes the client, all assessments, plans, schedule items, and notes. This action cannot be undone.")
        }
    }
    
    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundColor(AppColors.primary)
            }
            Spacer()
            Text("Client Profile")
                .font(.title3.weight(.bold))
                .foregroundColor(AppColors.textPrimary)
            Spacer()
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(AppColors.mainSurface)
    }
    
    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(client.displayName)
                .font(.title2.weight(.semibold))
                .foregroundColor(AppColors.textPrimary)
            Text("Unit: \(unitDisplayName)")
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
            Text("Link: \(client.isLinked ? "Linked" : "Not linked")")
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
            
            HStack(spacing: 8) {
                StatusPill(
                    text: "Baseline",
                    style: (detail?.hasBaseline == true) ? .active : .inactive
                )
                StatusPill(
                    text: "Plan",
                    style: (detail?.activePlan != nil) ? .active : .inactive
                )
                StatusPill(
                    text: client.isLinked ? "Linked" : "Not linked",
                    style: client.isLinked ? .active : .alert
                )
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.mainSurface)
        .cornerRadius(24)
        .shadow(color: AppColors.shadow(0.05), radius: 12, x: 0, y: 6)
    }
    
    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick actions")
                .font(.headline)
                .foregroundColor(AppColors.textPrimary)
            
            QuickActionRow(
                title: "Link to Livbojen",
                subtitle: "Generate code for the client",
                badge: QuickActionRow.Badge(
                    text: client.isLinked ? "Linked" : "Not linked",
                    style: client.isLinked ? .active : .alert
                ),
                destination: ClientLinkingView(appState: appState, client: client)
            )
            
            QuickActionRow(
                title: "Assessments",
                subtitle: "Baseline + follow-up history",
                badge: QuickActionRow.Badge(
                    text: (detail?.hasBaseline == true) ? "Baseline" : "No baseline",
                    style: (detail?.hasBaseline == true) ? .active : .inactive
                ),
                destination: ClientAssessmentsView(appState: appState, client: client)
            )
            
            QuickActionRow(
                title: "Plan",
                subtitle: "View or create plan",
                badge: QuickActionRow.Badge(
                    text: detail?.activePlan != nil ? "Plan" : "No plan",
                    style: detail?.activePlan != nil ? .active : .inactive
                ),
                destination: ClientPlansView(appState: appState, client: client)
            )
            
            QuickActionRow(
                title: "Schedule",
                subtitle: "Shared planner and tasks",
                badge: nil,
                destination: ClientScheduleView(appState: appState, client: client)
            )
            
            QuickActionRow(
                title: "Notes & Flags",
                subtitle: "Staff-only notes",
                badge: detail?.flags.isEmpty == false
                ? QuickActionRow.Badge(text: "Flags", style: .alert)
                : nil,
                destination: ClientNotesFlagsView(appState: appState, client: client)
            )
            
            QuickActionRow(
                title: "Timeline / History",
                subtitle: "Event log",
                badge: nil,
                destination: ClientTimelineView(client: client)
            )
        }
    }
    
    private var dangerZoneCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Danger zone")
                .font(.headline)
                .foregroundColor(AppColors.danger)
            Text("Permanently deletes this client and all related data. Use this when you need to remove test records.")
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
            Button(action: { showDeleteConfirm = true }) {
                HStack(spacing: 10) {
                    if isDeletingClient {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppColors.onDanger))
                    }
                    Text(isDeletingClient ? "Deleting…" : "Delete client")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppColors.danger.opacity(isDeletingClient ? 0.8 : 1))
                .foregroundColor(AppColors.onDanger)
                .cornerRadius(16)
            }
            .disabled(isDeletingClient)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.mainSurface)
        .cornerRadius(22)
        .shadow(color: AppColors.shadow(0.04), radius: 10, y: 4)
    }

    private var unitDisplayName: String {
        if let unit = appState.currentUnit {
            return unit.displayName
        }
        return "Unit \(client.unitId)"
    }
    
    private func loadDetail() async {
        isLoading = true
        errorMessage = nil
        do {
            let detail = try await clientService.getClientDetail(clientId: client.id)
            await MainActor.run {
                self.detail = detail
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    private func deleteClientRecord() async {
        guard !isDeletingClient else { return }
        await MainActor.run {
            isDeletingClient = true
            errorMessage = nil
        }
        do {
            try await clientService.deleteClient(clientId: client.id)
            await MainActor.run {
                isDeletingClient = false
                onDeleted?()
                dismiss()
            }
        } catch {
            await MainActor.run {
                isDeletingClient = false
                errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - Reusable cards

private struct LoadingStateCard: View {
    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(AppColors.primary)
            Text("Loading client…")
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(AppColors.mainSurface)
        .cornerRadius(20)
    }
}

private struct ErrorStateCard: View {
    let message: String
    let retry: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Couldn't load client")
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(AppColors.textSecondary)
            Button("Retry", action: retry)
                .buttonStyle(.borderedProminent)
                .tint(AppColors.primary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(AppColors.mainSurface)
        .cornerRadius(20)
    }
}

private struct StatusPill: View {
    enum Style {
        case active
        case inactive
        case alert
    }
    
    let text: String
    let style: Style
    
    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .overlay(
                Capsule().stroke(borderColor, lineWidth: 1)
            )
            .clipShape(Capsule())
    }
    
    private var backgroundColor: Color {
        switch style {
        case .active: return AppColors.primary.opacity(0.15)
        case .inactive: return AppColors.secondarySurface
        case .alert: return AppColors.danger.opacity(0.15)
        }
    }
    
    private var foregroundColor: Color {
        switch style {
        case .active: return AppColors.primary
        case .inactive: return AppColors.textSecondary
        case .alert: return AppColors.danger
        }
    }
    
    private var borderColor: Color {
        switch style {
        case .active: return AppColors.primary.opacity(0.5)
        case .inactive: return AppColors.border
        case .alert: return AppColors.danger.opacity(0.6)
        }
    }
}

private struct QuickActionRow<Destination: View>: View {
    struct Badge {
        let text: String
        let style: StatusPill.Style
    }
    
    let title: String
    let subtitle: String
    let badge: Badge?
    let destination: Destination
    
    var body: some View {
        NavigationLink(destination: destination) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(AppColors.textPrimary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                Spacer()
                if let badge {
                    StatusPill(text: badge.text, style: badge.style)
                }
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(AppColors.mutedNeutral)
            }
            .padding()
            .background(AppColors.mainSurface)
            .cornerRadius(18)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Link to Livbojen

private struct ClientLinkingView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var appState: AppState
    let client: Client
    
    @State private var activeLink: ClientLink?
    @State private var isLoading = true
    @State private var isGenerating = false
    @State private var errorMessage: String?
    @State private var isLinked: Bool
    @State private var countdownText: String = "--"
    @State private var hasPresentedSuccess: Bool
    @State private var showSuccessScreen = false
    @State private var latestLinkedClient: Client?
    @State private var showUnlinkConfirm = false
    @State private var isUnlinking = false
    @State private var unlinkError: String?
    @State private var showUnlinkedSuccess = false
    
    private let countdownTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private let statusTimer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    
    private let clientService = ClientService()
    
    init(appState: AppState, client: Client) {
        self.appState = appState
        self.client = client
        _isLinked = State(initialValue: client.isLinked)
        _hasPresentedSuccess = State(initialValue: client.isLinked)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                clientHeader
                Text("Generate a 6-digit code for the youth to enter in Livbojen. Codes expire after 15 minutes.")
                    .font(.subheadline)
                    .foregroundColor(AppColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                codeCard
                copyButton
                generateButton
                helpCard
                if isLinked {
                    unlinkCard
                }
            }
            .padding(20)
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationTitle("Link to Livbojen")
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadPage() }
        .navigationDestination(isPresented: $showSuccessScreen) {
            LinkSuccessView(appState: appState, client: latestLinkedClient ?? client)
        }
        .navigationDestination(isPresented: $showUnlinkedSuccess) {
            UnlinkSuccessView(
                onBackToProfile: {
                    showUnlinkedSuccess = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        dismiss()
                    }
                },
                onGenerateNewCode: {
                    showUnlinkedSuccess = false
                    Task { await generateLink() }
                }
            )
        }
        .onReceive(countdownTimer) { _ in updateCountdown() }
        .onReceive(statusTimer) { _ in
            if !isLinked {
                Task { await refreshLinkStatus() }
            }
        }
        .sheet(isPresented: $showUnlinkConfirm) {
            UnlinkConfirmationSheet(
                isProcessing: isUnlinking,
                errorMessage: unlinkError,
                onCancel: {
                    showUnlinkConfirm = false
                    unlinkError = nil
                },
                onConfirm: {
                    Task { await unlinkClient() }
                }
            )
            .presentationDetents([.fraction(0.55), .large])
        }
    }
    
    private var clientHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Client: \(client.displayName)")
                .font(.headline)
            HStack(spacing: 8) {
                Text("Status:")
                    .font(.subheadline)
                    .foregroundColor(AppColors.textSecondary)
                StatusPill(text: isLinked ? "Linked" : "Not linked", style: isLinked ? .active : .alert)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(AppColors.mainSurface)
        .cornerRadius(18)
    }
    
    private var codeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Link code (6 digits)")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(AppColors.textPrimary)
            if isLoading {
                RoundedRectangle(cornerRadius: 18)
                    .fill(AppColors.secondarySurface)
                    .frame(height: 72)
                    .overlay(ProgressView().tint(AppColors.primary))
            } else if let link = activeLink, !link.isExpired {
                HStack(spacing: 12) {
                    ForEach(Array(link.code), id: \.self) { digit in
                        Text(String(digit))
                            .font(.title.bold())
                            .frame(width: 44, height: 64)
                            .background(AppColors.mainSurface)
                            .cornerRadius(12)
                    }
                }
                Text("Expires in \(countdownText)")
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
            } else {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(AppColors.border, style: StrokeStyle(lineWidth: 1, dash: [6]))
                    .frame(height: 72)
                    .overlay(
                        Text("No active code")
                            .font(.headline)
                            .foregroundColor(AppColors.textSecondary)
                    )
                Text("Code expired. Generate a new one.")
                    .font(.caption)
                    .foregroundColor(AppColors.danger)
            }
            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(AppColors.danger)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var copyButton: some View {
        Button(action: copyCode) {
            Text("Copy code")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(canCopy ? AppColors.secondarySurface : AppColors.secondarySurface.opacity(0.5))
                .cornerRadius(16)
        }
        .disabled(!canCopy)
    }
    
    private var generateButton: some View {
        Button(action: { Task { await generateLink() } }) {
            HStack {
                if isGenerating {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(AppColors.onPrimary)
                }
                Text("Generate new code")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isGenerating ? AppColors.mutedNeutral : AppColors.primary)
            .foregroundColor(isGenerating ? AppColors.textPrimary : AppColors.onPrimary)
            .cornerRadius(16)
        }
        .disabled(isGenerating)
    }
    
    private var helpCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Client steps")
                .font(.headline)
            VStack(alignment: .leading, spacing: 8) {
                Text("1) Open Livbojen app")
                Text("2) Go to Settings → Link")
                Text("3) Enter the 6-digit code")
                Text("4) Confirm")
            }
            .font(.subheadline)
            .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(AppColors.secondarySurface)
        .cornerRadius(18)
    }

    private var unlinkCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Unlink client?")
                        .font(.headline)
                    Text("Stop syncing schedule items and chapter assignments.")
                        .font(.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                }
                Spacer()
                StatusPill(text: "Linked", style: .active)
            }
            Text("Staff notes and flags remain in Ledstjarnan.")
                .font(.footnote)
                .foregroundColor(AppColors.textSecondary)
            Button(role: .destructive) {
                showUnlinkConfirm = true
            } label: {
                Text("Unlink client")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppColors.mainSurface)
                    .cornerRadius(16)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.mainSurface)
        .cornerRadius(22)
        .shadow(color: AppColors.shadow(0.04), radius: 10, y: 4)
    }
    
    private var canCopy: Bool {
        guard let link = activeLink else { return false }
        return !link.isExpired
    }
    
    private func loadPage() async {
        await loadLink()
        await refreshLinkStatus()
    }
    
    private func loadLink() async {
        isLoading = true
        errorMessage = nil
        do {
            let link = try await clientService.getActiveLinkCode(clientId: client.id)
            await MainActor.run {
                self.activeLink = link
                self.isLoading = false
                self.updateCountdown()
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    private func generateLink() async {
        guard let staffId = appState.currentStaffProfile?.id,
              let unitId = appState.currentUnit?.id else {
            errorMessage = "Missing staff or unit context."
            return
        }
        isGenerating = true
        errorMessage = nil
        do {
            let link = try await clientService.generateLinkCode(clientId: client.id, unitId: unitId, createdByStaffId: staffId)
            await MainActor.run {
                self.activeLink = link
                self.isGenerating = false
                self.isLinked = false
                self.hasPresentedSuccess = false
                self.updateCountdown()
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isGenerating = false
            }
        }
    }
    
    private func refreshLinkStatus() async {
        do {
            let latest = try await clientService.getClient(clientId: client.id)
            await MainActor.run {
                let becameLinked = !self.isLinked && latest.isLinked
                self.isLinked = latest.isLinked
                if becameLinked || (latest.isLinked && !hasPresentedSuccess) {
                    self.activeLink = nil
                    self.hasPresentedSuccess = true
                    self.latestLinkedClient = latest
                    self.showSuccessScreen = true
                }
            }
        } catch {
            // ignore polling errors
        }
    }
    
    private func copyCode() {
        guard canCopy, let code = activeLink?.code else { return }
        UIPasteboard.general.string = code
    }
    
    private func updateCountdown() {
        guard let link = activeLink, !link.isExpired else {
            countdownText = "--"
            return
        }
        let remaining = Int(link.expiresAt.timeIntervalSinceNow)
        if remaining <= 0 {
            countdownText = "expired"
            return
        }
        let minutes = remaining / 60
        let seconds = remaining % 60
        countdownText = String(format: "%02dm %02ds", minutes, seconds)
    }
    
    private func unlinkClient() async {
        guard let staffId = appState.currentStaffProfile?.id else {
            unlinkError = "Missing staff context."
            return
        }
        await MainActor.run {
            isUnlinking = true
            unlinkError = nil
        }
        do {
            try await clientService.unlinkClient(clientId: client.id, staffId: staffId)
            await MainActor.run {
                isLinked = false
                activeLink = nil
                isUnlinking = false
                showUnlinkConfirm = false
                showUnlinkedSuccess = true
            }
        } catch {
            await MainActor.run {
                unlinkError = error.localizedDescription
                isUnlinking = false
            }
        }
    }
}

private struct LinkSuccessCard: View {
    let client: Client
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(AppColors.primary)
            Text("Client is now linked to Livbojen")
                .font(.headline)
            Text(client.displayName)
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
            VStack(alignment: .leading, spacing: 8) {
                Text("You can now:")
                    .font(.subheadline.weight(.semibold))
                Text("• Assign Livbojen chapters")
                Text("• Share schedule items")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(AppColors.secondarySurface)
            .cornerRadius(16)
        }
        .padding()
        .background(AppColors.mainSurface)
        .cornerRadius(24)
    }
}

private struct LinkSuccessView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var appState: AppState
    let client: Client
    @State private var goToChapters = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                LinkSuccessCard(client: client)
                VStack(spacing: 12) {
                    Button("Open Client Profile") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppColors.primary)
                    
                    Button("Assign chapters now") {
                        goToChapters = true
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppColors.primary)
                }
                NavigationLink(
                    "",
                    destination: PlanBuilderView(
                        appState: appState,
                        client: client,
                        plan: nil,
                        clientName: client.displayName,
                        startStep: .chapters
                    ),
                    isActive: $goToChapters
                )
                .hidden()
            }
            .padding(24)
        }
        .navigationTitle("Link success")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct UnlinkSuccessView: View {
    let onBackToProfile: () -> Void
    let onGenerateNewCode: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 56))
                        .foregroundColor(AppColors.primary)
                    Text("Client unlinked")
                        .font(.title3.weight(.semibold))
                    Text("This client is no longer connected to Livbojen. Chapters and schedule will no longer sync.")
                        .font(.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(24)
                .background(AppColors.mainSurface)
                .cornerRadius(24)
                
                VStack(spacing: 12) {
                    Button("Back to profile") {
                        onBackToProfile()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppColors.primary)
                    
                    Button("Generate new link code") {
                        onGenerateNewCode()
                    }
                    .buttonStyle(.bordered)
                    .tint(AppColors.primary)
                }
            }
            .padding(24)
        }
        .navigationTitle("Client unlinked")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct UnlinkConfirmationSheet: View {
    let isProcessing: Bool
    let errorMessage: String?
    let onCancel: () -> Void
    let onConfirm: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Capsule()
                .fill(AppColors.border)
                .frame(width: 40, height: 4)
                .padding(.top, 8)
            Text("Unlink client?")
                .font(.headline)
            Text("This will stop syncing schedule items and Livbojen chapters for this client. Notes and flags stay in Ledstjarnan.")
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundColor(AppColors.danger)
                    .multilineTextAlignment(.center)
            }
            HStack(spacing: 16) {
                Button("Cancel") {
                    onCancel()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppColors.secondarySurface)
                .cornerRadius(16)
                
                Button("Unlink") {
                    onConfirm()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppColors.danger)
                .foregroundColor(AppColors.onDanger)
                .cornerRadius(16)
                .overlay {
                    if isProcessing {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(AppColors.onDanger)
                    }
                }
                .disabled(isProcessing)
            }
            .padding(.bottom, 20)
        }
        .padding(.horizontal, 24)
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Assessments screen

private struct ClientAssessmentsView: View {
    @ObservedObject var appState: AppState
    let client: Client
    
    @State private var assessments: [Assessment] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedAssessment: Assessment?
    
    private let assessmentService = AssessmentService()
    
    var body: some View {
        List {
            Section {
                NavigationLink(destination: AssessmentFormView(appState: appState, client: client, assessmentType: "baseline")) {
                    Label("Start new baseline", systemImage: "doc.text")
                }
                NavigationLink(destination: AssessmentFormView(appState: appState, client: client, assessmentType: "followup")) {
                    Label("Start follow-up", systemImage: "chart.line.uptrend.xyaxis")
                }
            }
            
            Section(header: Text("History")) {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .center)
                } else if let errorMessage {
                    Text(errorMessage)
                        .foregroundColor(AppColors.danger)
                } else if assessments.isEmpty {
                    Text("No assessments yet.")
                        .foregroundColor(AppColors.textSecondary)
                } else {
                    ForEach(assessments) { assessment in
                        Button {
                            if assessment.status == "completed" {
                                selectedAssessment = assessment
                            }
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(assessment.isBaseline ? "Baseline" : "Follow-up")
                                        .font(.subheadline.weight(.semibold))
                                    Text(assessment.assessmentDate ?? "—")
                                        .font(.caption)
                                        .foregroundColor(AppColors.textSecondary)
                                }
                                Spacer()
                                if assessment.status == "completed" {
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(AppColors.mutedNeutral)
                                } else {
                                    Text("Draft")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .disabled(assessment.status != "completed")
                    }
                }
            }
        }
        .navigationTitle("Assessments")
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadAssessments() }
        .sheet(item: $selectedAssessment) { assessment in
            AssessmentDetailSheet(client: client, assessment: assessment)
        }
    }
    
    private func loadAssessments() async {
        isLoading = true
        errorMessage = nil
        do {
            let list = try await assessmentService.getAssessments(clientId: client.id)
            await MainActor.run {
                assessments = list
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
}

// MARK: - Notes & Flags screen

private struct ClientNotesFlagsView: View {
    @ObservedObject var appState: AppState
    let client: Client
    
    @State private var detail: ClientDetail?
    @State private var detailError: String?
    @State private var isDetailLoading = true
    
    @State private var notes: [ClientNote] = []
    @State private var notesError: String?
    @State private var isNotesLoading = true
    @State private var isPresentingAdd = false
    @State private var editingNote: ClientNote?
    @State private var staffNames: [String: String] = [:]
    @State private var notePendingDelete: ClientNote?
    
    private let clientService = ClientService()
    private let staffService = StaffService()
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    flagsSection
                    notesSection
                }
                .padding(20)
            }
            Divider()
            Button {
                isPresentingAdd = true
            } label: {
                Text("+ Add note")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppColors.primary)
                    .foregroundColor(AppColors.onPrimary)
                    .cornerRadius(16)
            }
            .padding(20)
            .background(AppColors.mainSurface)
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationTitle("Notes & Flags")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadDetail()
            await loadNotes()
        }
        .navigationDestination(isPresented: $isPresentingAdd) {
            ClientNoteEditorView(
                appState: appState,
                client: client,
                mode: .create,
                note: nil,
                staffName: appState.currentStaffProfile?.fullName ?? "Staff",
                onComplete: {
                    Task { await loadNotes() }
                }
            )
        }
        .navigationDestination(item: $editingNote) { note in
            ClientNoteEditorView(
                appState: appState,
                client: client,
                mode: .edit,
                note: note,
                staffName: staffNames[note.staffId] ?? "Staff",
                onComplete: {
                    editingNote = nil
                    Task { await loadNotes() }
                }
            )
        }
        .alert("Delete note?", isPresented: Binding(
            get: { notePendingDelete != nil },
            set: { if !$0 { notePendingDelete = nil } }
        )) {
            Button("Delete", role: .destructive) {
                if let note = notePendingDelete {
                    Task { await deleteNote(note: note) }
                }
                notePendingDelete = nil
            }
            Button("Cancel", role: .cancel) {
                notePendingDelete = nil
            }
        }
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(client.displayName)
                .font(.title3.weight(.semibold))
            Text("Staff-only view")
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
            if let updated = detail?.flags.first?.updatedAt ?? notes.first?.updatedAt {
                Text("Last updated: \(dateFormatter.string(from: updated))")
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(AppColors.mainSurface)
        .cornerRadius(20)
    }
    
    private var flagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Flags")
                .font(.headline)
            if isDetailLoading {
                ProgressView()
            } else if let error = detailError {
                Text(error)
                    .foregroundColor(AppColors.danger)
            } else if let detail = detail {
                let activeKeys = Set(detail.flags.map { $0.flagKey })
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(ClientFlagType.allCases.filter { $0 != .other }, id: \.rawValue) { type in
                        FlagChip(
                            type: type,
                            isActive: activeKeys.contains(type.rawValue),
                            action: { toggleFlag(type: type, currentlyOn: activeKeys.contains(type.rawValue)) }
                        )
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notes")
                .font(.headline)
            if let err = notesError {
                Text(err)
                    .foregroundColor(AppColors.danger)
            } else if isNotesLoading {
                ProgressView()
            } else if notes.isEmpty {
                Text("No notes yet.")
                    .foregroundColor(AppColors.textSecondary)
            } else {
                ForEach(notes) { note in
                    NoteCard(
                        note: note,
                        authorName: staffNames[note.staffId] ?? "Staff",
                        canManage: true,
                        onEdit: {
                            editingNote = note
                        },
                        onDelete: {
                            notePendingDelete = note
                        }
                    )
                }
                .animation(.spring(), value: notes)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func loadDetail() async {
        isDetailLoading = true
        detailError = nil
        do {
            let detail = try await clientService.getClientDetail(clientId: client.id)
            await MainActor.run {
                self.detail = detail
                self.isDetailLoading = false
            }
        } catch {
            await MainActor.run {
                self.detailError = error.localizedDescription
                self.isDetailLoading = false
            }
        }
    }
    
    private func loadNotes() async {
        isNotesLoading = true
        notesError = nil
        do {
            let notes = try await clientService.getNotes(clientId: client.id)
            await MainActor.run {
                self.notes = notes
                self.isNotesLoading = false
            }
            await loadStaffNames(for: notes)
        } catch {
            await MainActor.run {
                self.notesError = error.localizedDescription
                self.isNotesLoading = false
            }
        }
    }
    
    private func toggleFlag(type: ClientFlagType, currentlyOn: Bool) {
        guard let staffId = appState.currentStaffProfile?.id else { return }
        Task {
            try? await clientService.toggleFlag(clientId: client.id, flagKey: type.rawValue, isOn: !currentlyOn, staffId: staffId)
            await loadDetail()
        }
    }
    
    private func deleteNote(note: ClientNote) async {
        do {
            try await clientService.deleteNote(noteId: note.id)
            await loadNotes()
        } catch {
            await MainActor.run {
                notesError = error.localizedDescription
            }
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
    
    private func loadStaffNames(for notes: [ClientNote]) async {
        let ids = Set(notes.map(\.staffId))
        let missing = ids.filter { staffNames[$0] == nil }
        guard !missing.isEmpty else { return }
        for id in missing {
            do {
                let profile = try await staffService.getStaffProfile(userId: id)
                await MainActor.run {
                    staffNames[id] = profile.fullName
                }
            } catch {
                // ignore
            }
        }
    }
}

private struct ClientNoteEditorView: View {
    enum Mode {
        case create
        case edit
    }
    
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var appState: AppState
    let client: Client
    let mode: Mode
    let note: ClientNote?
    let staffName: String
    var onComplete: () -> Void
    
    @State private var text: String
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showDeleteConfirm = false
    
    private let clientService = ClientService()
    
    init(appState: AppState, client: Client, mode: Mode, note: ClientNote?, staffName: String, onComplete: @escaping () -> Void) {
        self.appState = appState
        self.client = client
        self.mode = mode
        self.note = note
        self.staffName = staffName
        self.onComplete = onComplete
        _text = State(initialValue: note?.noteText ?? "")
    }
    
    var body: some View {
        VStack(spacing: 20) {
            headerCard
            VStack(alignment: .leading, spacing: 8) {
                Text("Note")
                    .font(.headline)
                TextEditor(text: $text)
                    .padding()
                    .frame(minHeight: 180)
                    .background(AppColors.secondarySurface)
                    .cornerRadius(16)
            }
            visibilityInfo
            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundColor(AppColors.danger)
            }
            Spacer()
            if mode == .edit {
                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    Text("Delete note")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColors.secondarySurface)
                        .cornerRadius(16)
                }
            }
        }
        .padding(20)
        .background(AppColors.background.ignoresSafeArea())
        .navigationTitle(mode == .create ? "Add note" : "Edit note")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task { await saveNote() }
                }
                .disabled(!canSave)
            }
        }
        .alert("Delete note?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                Task { await deleteNote() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This note will be permanently deleted.")
        }
    }
    
    private var canSave: Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3 && !isSaving
    }
    
    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Client: \(client.displayName)")
                .font(.headline)
            if let note, mode == .edit {
                Text("\(staffName) • \(note.formattedDate)")
                    .font(.subheadline)
                    .foregroundColor(AppColors.textSecondary)
            } else {
                Text("Notes are staff-only")
                    .font(.subheadline)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(AppColors.mainSurface)
        .cornerRadius(18)
    }
    
    private var visibilityInfo: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Visibility")
                .font(.headline)
            Text("Staff-only (not shared to Livbojen)")
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(AppColors.secondarySurface)
        .cornerRadius(16)
    }
    
    private func saveNote() async {
        guard canSave, let staffId = appState.currentStaffProfile?.id else { return }
        isSaving = true
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            switch mode {
            case .create:
                _ = try await clientService.createNote(clientId: client.id, staffId: staffId, noteText: trimmed)
            case .edit:
                if let note {
                    _ = try await clientService.updateNote(noteId: note.id, noteText: trimmed)
                }
            }
            await MainActor.run {
                onComplete()
                dismiss()
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isSaving = false
            }
        }
    }
    
    private func deleteNote() async {
        guard let note else { return }
        do {
            try await clientService.deleteNote(noteId: note.id)
            await MainActor.run {
                onComplete()
                dismiss()
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - Timeline screen

private struct ClientTimelineView: View {
    let client: Client
    
    @State private var events: [ClientTimelineEvent] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    private let clientService = ClientService()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                header
                content
            }
            .padding(20)
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationTitle("Timeline / History")
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadTimeline() }
        .refreshable { await loadTimeline() }
    }
    
    @ViewBuilder
    private var content: some View {
        if isLoading {
            TimelineLoadingCard()
        } else if let errorMessage {
            TimelineMessageCard(
                iconName: "exclamationmark.triangle.fill",
                title: "Couldn't load history",
                subtitle: errorMessage,
                buttonTitle: "Retry",
                action: { Task { await loadTimeline() } }
            )
        } else if events.isEmpty {
            TimelineMessageCard(
                iconName: "clock.arrow.circlepath",
                title: "No history yet",
                subtitle: "When assessments, plans, or schedules are created they will appear here.",
                buttonTitle: "Refresh",
                action: { Task { await loadTimeline() } }
            )
        } else {
            historySection
        }
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(client.displayName)
                .font(.title3.weight(.semibold))
                .foregroundColor(AppColors.textPrimary)
            Text("All key actions in one place")
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(AppColors.mainSurface)
        .cornerRadius(20)
    }
    
    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("History")
                .font(.headline)
                .foregroundColor(AppColors.textPrimary)
            LazyVStack(spacing: 12) {
                ForEach(events) { event in
                    TimelineEventCard(event: event)
                }
            }
        }
    }
    
    private func loadTimeline() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        do {
            let items = try await clientService.getTimeline(clientId: client.id)
            await MainActor.run {
                events = items
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
}

// MARK: - Timeline helper views

private struct TimelineEventCard: View {
    let event: ClientTimelineEvent
    
    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let date = event.createdAt {
                Text(Self.dateFormatter.string(from: date))
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            Text(event.title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(AppColors.textPrimary)
            if let desc = event.description, !desc.isEmpty {
                Text(desc)
                    .font(.footnote)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(AppColors.mainSurface)
        .cornerRadius(20)
        .shadow(color: AppColors.shadow(0.04), radius: 8, x: 0, y: 4)
    }
}

private struct TimelineLoadingCard: View {
    var body: some View {
        TimelineMessageCard(
            iconName: "hourglass",
            title: "Loading history",
            subtitle: "Fetching the latest actions for this client…",
            showSpinner: true
        )
    }
}

private struct TimelineMessageCard: View {
    let iconName: String
    let title: String
    let subtitle: String
    var buttonTitle: String? = nil
    var action: (() -> Void)? = nil
    var showSpinner = false
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.system(size: 28))
                .foregroundColor(AppColors.primary)
            if showSpinner {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(AppColors.primary)
            }
            Text(title)
                .font(.headline)
                .multilineTextAlignment(.center)
            Text(subtitle)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(AppColors.textSecondary)
            if let buttonTitle, let action {
                Button(buttonTitle, action: action)
                    .buttonStyle(.borderedProminent)
                    .tint(AppColors.primary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(AppColors.mainSurface)
        .cornerRadius(20)
    }
}

struct FlagChip: View {
    let type: ClientFlagType
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: type.icon)
                Text(type.title)
                    .font(.subheadline)
            }
            .foregroundColor(isActive ? AppColors.onPrimary : AppColors.textPrimary)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(isActive ? AppColors.primary : AppColors.mainSurface)
            .cornerRadius(12)
            .shadow(color: isActive ? AppColors.primary.opacity(0.25) : .clear, radius: 6, y: 4)
        }
    }
}

struct NoteCard: View {
    let note: ClientNote
    let authorName: String
    let canManage: Bool
    var onEdit: () -> Void
    var onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(authorName)
                    .font(.subheadline.weight(.semibold))
                Text(note.formattedDate)
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
                Spacer()
                if canManage {
                    Button("Edit", action: onEdit)
                        .font(.caption.weight(.semibold))
                    Button("Delete", action: onDelete)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(AppColors.danger)
                }
            }
            Text(note.noteText)
                .font(.body)
                .foregroundColor(AppColors.textPrimary)
        }
        .padding()
        .background(AppColors.mainSurface)
        .cornerRadius(16)
    }
}

struct AssessmentDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let client: Client
    let assessment: Assessment

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Overview")) {
                    HStack {
                        Text("Type")
                        Spacer()
                        Text(assessment.isBaseline ? "Baseline" : "Follow-up")
                    }
                    HStack {
                        Text("Date")
                        Spacer()
                        Text(assessment.assessmentDate ?? "—")
                    }
                    HStack {
                        Text("Stress total")
                        Spacer()
                        Text("\(assessment.ptsdTotalScore ?? 0)")
                            .bold()
                    }
                    if let probable = assessment.ptsdProbable {
                        Label(
                            probable ? "Probable PTSD" : "Not probable",
                            systemImage: probable ? "exclamationmark.triangle" : "checkmark.seal"
                        )
                        .foregroundColor(probable ? .red : .green)
                    }
                }
            }
            .navigationTitle("Assessment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    ClientProfileView(appState: AppState(), client: Client(
        id: "client-1",
        unitId: "unit-1",
        nameOrCode: "A12 • Noor",
        linkedUserId: nil,
        createdByStaffId: nil,
        createdAt: Date(),
        updatedAt: Date()
    ))
}
