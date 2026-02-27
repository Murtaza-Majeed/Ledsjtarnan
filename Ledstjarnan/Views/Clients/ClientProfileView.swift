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
    /// Called when user taps back (so list can clear navigationClient if needed).
    let onDismiss: (() -> Void)?
    
    @EnvironmentObject private var logicStore: LogicReferenceStore
    
    @State private var detail: ClientDetail?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showDeleteConfirm = false
    @State private var isDeletingClient = false
    @State private var assessments: [Assessment] = []
    @State private var assessmentForInsatskarta: Assessment?
    @State private var showInsatskartaNoData = false
    
    private let clientService = ClientService()
    private let assessmentService = AssessmentService()
    private var lang: String { appState.languageCode }
    
    private var latestCompletedWithInsatskarta: Assessment? {
        assessments
            .filter { $0.status == "completed" && $0.interventionSummary != nil && !(($0.interventionSummary ?? [:]).isEmpty) }
            .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
            .first
    }
    
    /// Use detail's client when loaded so link status and data stay fresh (e.g. after returning from Link screen).
    private var effectiveClient: Client {
        detail?.client ?? client
    }

    init(appState: AppState, client: Client, onDeleted: (() -> Void)? = nil, onDismiss: (() -> Void)? = nil) {
        self._appState = ObservedObject(initialValue: appState)
        self.client = client
        self.onDeleted = onDeleted
        self.onDismiss = onDismiss
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
        .task { await loadAssessments() }
        .onAppear { Task { await loadDetail() } }
        .navigationBarBackButtonHidden(true)
        .confirmationDialog(
            LocalizedString("client_profile_delete_confirm", lang),
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button(LocalizedString("client_profile_delete", lang), role: .destructive) {
                Task { await deleteClientRecord() }
            }
            Button(LocalizedString("general_cancel", lang), role: .cancel) {}
        } message: {
            Text(LocalizedString("client_profile_delete_warning", lang))
        }
        .fullScreenCover(isPresented: $showInsatskartaNoData) {
            NavigationStack {
                VStack(spacing: 16) {
                    Text(LocalizedString("insatskarta_no_data", lang))
                        .font(.headline)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding()
                    Button(LocalizedString("insatskarta_close", lang)) {
                        showInsatskartaNoData = false
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppColors.primary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppColors.background)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(LocalizedString("insatskarta_close", lang)) {
                            showInsatskartaNoData = false
                        }
                    }
                }
            }
        }
        .fullScreenCover(item: $assessmentForInsatskarta) { assessment in
            if let (recs, flags, ptsd) = parseInsatskartaData(assessment: assessment) {
                InsatskartraView(
                    recommendations: recs,
                    safetyFlags: flags,
                    ptsd: ptsd,
                    clientName: client.displayName
                )
            } else {
                NavigationStack {
                    VStack(spacing: 16) {
                        Text(LocalizedString("insatskarta_no_data", lang))
                            .font(.headline)
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding()
                        Button(LocalizedString("insatskarta_close", lang)) {
                            assessmentForInsatskarta = nil
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(AppColors.primary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppColors.background)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button(LocalizedString("insatskarta_close", lang)) {
                                assessmentForInsatskarta = nil
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var topBar: some View {
        HStack {
            Button {
                onDismiss?()
                dismiss()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                    Text(LocalizedString("general_back", lang))
                }
                .font(.subheadline.weight(.semibold))
                .foregroundColor(AppColors.primary)
            }
            Spacer()
            Text(LocalizedString("client_profile_title", lang))
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
            Text(LocalizedString("client_profile_unit", lang).replacingOccurrences(of: "%@", with: unitDisplayName))
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
            Text("Link: \(effectiveClient.isLinked ? LocalizedString("clients_status_linked", lang) : LocalizedString("clients_status_not_linked", lang))")
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
            
            HStack(spacing: 8) {
                StatusPill(
                    text: LocalizedString("clients_status_baseline", lang),
                    style: (detail?.hasBaseline == true) ? .active : .inactive
                )
                StatusPill(
                    text: LocalizedString("clients_status_plan", lang),
                    style: (detail?.activePlan != nil) ? .active : .inactive
                )
                StatusPill(
                    text: effectiveClient.isLinked ? LocalizedString("clients_status_linked", lang) : LocalizedString("clients_status_not_linked", lang),
                    style: effectiveClient.isLinked ? .active : .alert
                )
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.mainSurface)
        .cornerRadius(24)
        .shadow(color: AppColors.shadow(0.05), radius: 12, x: 0, y: 6)
    }
    
    private var assessmentsCard: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(LocalizedString("client_profile_assessments", lang))
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                StatusPill(
                    text: (detail?.hasBaseline == true) ? LocalizedString("clients_status_baseline", lang) : LocalizedString("client_profile_no_assessments", lang),
                    style: (detail?.hasBaseline == true) ? .active : .inactive
                )
            }
            .padding(.horizontal)
            .padding(.top, 14)
            .padding(.bottom, 10)
            
            Divider().padding(.leading, 16)
            
            // Visa baslinje
            NavigationLink(destination: BaselineDomainsView(appState: appState, client: client)) {
                HStack(spacing: 12) {
                    Image(systemName: "doc.text")
                        .foregroundColor(AppColors.primary)
                        .frame(width: 24)
                    Text(LocalizedString("baseline_view", lang))
                        .font(.subheadline)
                        .foregroundColor(AppColors.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(AppColors.mutedNeutral)
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
            
            Divider().padding(.leading, 52)
            
            // Visa uppföljning
            NavigationLink(destination: FollowUpDomainsView(appState: appState, client: client)) {
                HStack(spacing: 12) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(AppColors.primary)
                        .frame(width: 24)
                    Text(LocalizedString("followup_view", lang))
                        .font(.subheadline)
                        .foregroundColor(AppColors.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(AppColors.mutedNeutral)
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
            
            Divider().padding(.leading, 52)
            
            // Visa Insatskarta
            Button {
                if let assessment = latestCompletedWithInsatskarta {
                    assessmentForInsatskarta = assessment
                } else {
                    showInsatskartaNoData = true
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "map")
                        .foregroundColor(AppColors.primary)
                        .frame(width: 24)
                    Text(LocalizedString("assessment_form_view_insatskarta", lang))
                        .font(.subheadline)
                        .foregroundColor(AppColors.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(AppColors.mutedNeutral)
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
        }
        .background(AppColors.mainSurface)
        .cornerRadius(18)
    }
    
    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizedString("client_profile_quick_actions", lang))
                .font(.headline)
                .foregroundColor(AppColors.textPrimary)
            
            QuickActionRow(
                title: LocalizedString("client_profile_link_title", lang),
                subtitle: LocalizedString("client_profile_link_code_description", lang),
                badge: QuickActionRow.Badge(
                    text: effectiveClient.isLinked ? LocalizedString("clients_status_linked", lang) : LocalizedString("clients_status_not_linked", lang),
                    style: effectiveClient.isLinked ? .active : .alert
                ),
                destination: ClientLinkingView(appState: appState, client: effectiveClient)
            )
            
            assessmentsCard
            
            QuickActionRow(
                title: LocalizedString("client_profile_plans", lang),
                subtitle: LocalizedString("plans_empty_message", lang),
                badge: QuickActionRow.Badge(
                    text: detail?.activePlan != nil ? LocalizedString("clients_status_plan", lang) : LocalizedString("plans_empty_title", lang),
                    style: detail?.activePlan != nil ? .active : .inactive
                ),
                destination: ClientPlansView(appState: appState, client: client)
            )
            
            QuickActionRow(
                title: LocalizedString("schedule_title", lang),
                subtitle: LocalizedString("schedule_no_items_hint", lang),
                badge: nil,
                destination: ClientScheduleView(appState: appState, client: client)
            )
            
            QuickActionRow(
                title: LocalizedString("client_profile_notes_flags_title", lang),
                subtitle: LocalizedString("client_profile_staff_only", lang),
                badge: detail?.flags.isEmpty == false
                ? QuickActionRow.Badge(text: LocalizedString("client_profile_flags", lang), style: .alert)
                : nil,
                destination: ClientNotesFlagsView(appState: appState, client: client)
            )
            
            QuickActionRow(
                title: LocalizedString("client_profile_timeline", lang),
                subtitle: LocalizedString("client_profile_quick_actions_description", lang),
                badge: nil,
                destination: ClientTimelineView(client: client)
            )
        }
    }
    
    private var dangerZoneCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizedString("client_profile_danger_zone", lang))
                .font(.headline)
                .foregroundColor(AppColors.danger)
            Text(LocalizedString("client_profile_danger_description", lang))
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
            Button(action: { showDeleteConfirm = true }) {
                HStack(spacing: 10) {
                    if isDeletingClient {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppColors.onDanger))
                    }
                    Text(isDeletingClient ? LocalizedString("general_loading", lang) : LocalizedString("client_profile_delete", lang))
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

    private func loadAssessments() async {
        do {
            let list = try await assessmentService.getAssessments(clientId: client.id)
            await MainActor.run { assessments = list }
        } catch {
            // Non-critical — card still shows navigation links
        }
    }
    
    private func parseInsatskartaData(assessment: Assessment) -> ([InterventionRecommendation], [SafetyFlag], PTSDEvaluation)? {
        guard let summary = assessment.interventionSummary, !summary.isEmpty else { return nil }
        var recommendations: [InterventionRecommendation] = []
        for (domainKey, anyVal) in summary {
            let dict: [String: Any]
            if let d = anyVal.value as? [String: AnyCodable] {
                dict = d.mapValues(\.value)
            } else if let d = anyVal.value as? [String: Any] {
                dict = d
            } else {
                continue
            }
            let needLevelRaw = dict["needLevel"] as? String ?? ""
            let needLevel = NeedLevel(rawValue: needLevelRaw) ?? .low
            let interventionRaw = dict["interventions"] as? [String] ?? []
            let interventions = interventionRaw.compactMap { Intervention(rawValue: $0) }
            let isUrgent = dict["isUrgent"] as? Bool ?? false
            let notes = dict["notes"] as? String ?? ""
            let domainTitle = AssessmentDefinition.moduleInfo(forKey: domainKey, from: logicStore)?.title ?? domainKey.capitalized
            recommendations.append(InterventionRecommendation(
                domainKey: domainKey,
                domainTitle: domainTitle,
                needLevel: needLevel,
                interventions: interventions.isEmpty ? [.miljoterapeutiskVardag] : interventions,
                isUrgent: isUrgent,
                notes: notes
            ))
        }
        let flags: [SafetyFlag] = (assessment.safetyFlags ?? []).compactMap { flagDict in
            let d: [String: Any]
            if let wrapped = flagDict as? [String: AnyCodable] {
                d = wrapped.mapValues(\.value)
            } else {
                d = flagDict.mapValues(\.value)
            }
            guard let typeRaw = d["type"] as? String,
                  let type = SafetyFlag.FlagType(rawValue: typeRaw),
                  let message = d["message"] as? String else { return nil }
            let requiresAction = d["requiresAction"] as? Bool ?? false
            return SafetyFlag(type: type, message: message, requiresImmediateAction: requiresAction)
        }
        var ptsd = PTSDEvaluation()
        ptsd.totalSymptomScore = assessment.ptsdTotalScore ?? 0
        if assessment.ptsdProbable == true {
            ptsd.criterionBMet = true
            ptsd.criterionCMet = true
            ptsd.criterionDMet = true
            ptsd.criterionEMet = true
        }
        return (recommendations.sorted { $0.isUrgent && !$1.isUrgent }, flags, ptsd)
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
    @Environment(\.languageCode) var lang
    
    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(AppColors.primary)
            Text(LocalizedString("client_profile_loading", lang))
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
    @Environment(\.languageCode) var lang
    
    var body: some View {
        VStack(spacing: 12) {
            Text(LocalizedString("error_generic", lang))
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(AppColors.textSecondary)
            Button(LocalizedString("general_retry", lang), action: retry)
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
    private var lang: String { appState.languageCode }
    
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
                Text(LocalizedString("client_profile_link_code_description", lang))
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
        .navigationTitle(LocalizedString("client_profile_link_title", lang))
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadPage() }
        .navigationDestination(isPresented: $showSuccessScreen) {
            LinkSuccessView(appState: appState, client: latestLinkedClient ?? client)
        }
        .navigationDestination(isPresented: $showUnlinkedSuccess) {
            UnlinkSuccessView(
                lang: appState.languageCode,
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
                lang: appState.languageCode,
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
            Text(LocalizedString("client_profile_client_name", appState.languageCode).replacingOccurrences(of: "%@", with: client.displayName))
                .font(.headline)
            HStack(spacing: 8) {
                Text(LocalizedString("client_profile_status", lang))
                    .font(.subheadline)
                    .foregroundColor(AppColors.textSecondary)
                StatusPill(text: isLinked ? LocalizedString("clients_status_linked", appState.languageCode) : LocalizedString("clients_status_not_linked", appState.languageCode), style: isLinked ? .active : .alert)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(AppColors.mainSurface)
        .cornerRadius(18)
    }
    
    private var codeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizedString("client_profile_link_code", lang))
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
                Text(LocalizedString("client_profile_code_expires", lang).replacingOccurrences(of: "%@", with: countdownText))
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
            } else {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(AppColors.border, style: StrokeStyle(lineWidth: 1, dash: [6]))
                    .frame(height: 72)
                    .overlay(
                        Text(LocalizedString("client_profile_no_code", lang))
                            .font(.headline)
                            .foregroundColor(AppColors.textSecondary)
                    )
                Text(LocalizedString("client_profile_code_expired", lang))
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
            Text(LocalizedString("client_profile_copy_code", lang))
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
                Text(LocalizedString("client_profile_generate_code", lang))
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
            Text(LocalizedString("client_profile_client_steps", lang))
                .font(.headline)
            VStack(alignment: .leading, spacing: 8) {
                Text(LocalizedString("client_profile_step_1", lang))
                Text(LocalizedString("client_profile_step_2", lang))
                Text(LocalizedString("client_profile_step_3", lang))
                Text(LocalizedString("client_profile_step_4", lang))
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
                    Text(LocalizedString("client_profile_unlink_confirm", lang))
                        .font(.headline)
                    Text(LocalizedString("client_profile_unlink_description", lang))
                        .font(.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                }
                Spacer()
                StatusPill(text: LocalizedString("clients_status_linked", appState.languageCode), style: .active)
            }
            Text(LocalizedString("client_profile_unlink_note", lang))
                .font(.footnote)
                .foregroundColor(AppColors.textSecondary)
            Button(role: .destructive) {
                showUnlinkConfirm = true
            } label: {
                Text(LocalizedString("client_profile_unlink_button", lang))
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
            errorMessage = LocalizedString("error_generic", appState.languageCode)
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
            unlinkError = LocalizedString("error_generic", appState.languageCode)
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
    let lang: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(AppColors.primary)
            Text(LocalizedString("client_profile_linked_success", lang))
                .font(.headline)
            Text(client.displayName)
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
            VStack(alignment: .leading, spacing: 8) {
                Text(LocalizedString("client_profile_linked_can_now", lang))
                    .font(.subheadline.weight(.semibold))
                Text(LocalizedString("client_profile_linked_assign_chapters", lang))
                Text(LocalizedString("client_profile_linked_share_schedule", lang))
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
                LinkSuccessCard(client: client, lang: appState.languageCode)
                VStack(spacing: 12) {
                    Button(LocalizedString("client_profile_open_profile", appState.languageCode)) {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppColors.primary)
                    
                    Button(LocalizedString("client_profile_assign_chapters", appState.languageCode)) {
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
        .navigationTitle(LocalizedString("client_profile_link_success_title", appState.languageCode))
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct UnlinkSuccessView: View {
    let lang: String
    let onBackToProfile: () -> Void
    let onGenerateNewCode: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 56))
                        .foregroundColor(AppColors.primary)
                    Text(LocalizedString("client_profile_unlinked", lang))
                        .font(.title3.weight(.semibold))
                    Text(LocalizedString("client_profile_unlinked_message", lang))
                        .font(.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(24)
                .background(AppColors.mainSurface)
                .cornerRadius(24)
                
                VStack(spacing: 12) {
                    Button(LocalizedString("client_profile_back_to_profile", lang)) {
                        onBackToProfile()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppColors.primary)
                    
                    Button(LocalizedString("client_profile_generate_new_code", lang)) {
                        onGenerateNewCode()
                    }
                    .buttonStyle(.bordered)
                    .tint(AppColors.primary)
                }
            }
            .padding(24)
        }
        .navigationTitle(LocalizedString("client_profile_unlinked_title", lang))
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct UnlinkConfirmationSheet: View {
    let lang: String
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
            Text(LocalizedString("client_profile_unlink_confirm", lang))
                .font(.headline)
            Text(LocalizedString("client_profile_unlink_confirm_message", lang))
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
                Button(LocalizedString("general_cancel", lang)) {
                    onCancel()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppColors.secondarySurface)
                .cornerRadius(16)
                
                Button(LocalizedString("client_profile_unlink", lang)) {
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
    @EnvironmentObject private var logicStore: LogicReferenceStore
    
    @State private var assessments: [Assessment] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedAssessment: Assessment?
    @State private var assessmentForInsatskarta: Assessment?
    @State private var showInsatskartaNoData = false
    
    private let assessmentService = AssessmentService()
    
    private var lang: String { appState.languageCode }
    
    private var latestCompletedWithInsatskarta: Assessment? {
        assessments
            .filter { $0.status == "completed" && $0.interventionSummary != nil && !(($0.interventionSummary ?? [:]).isEmpty) }
            .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
            .first
    }
    
    var body: some View {
        List {
            Section {
                NavigationLink(destination: BaselineDomainsView(appState: appState, client: client)) {
                    Label(LocalizedString("baseline_view", appState.languageCode), systemImage: "doc.text")
                }
                NavigationLink(destination: FollowUpDomainsView(appState: appState, client: client)) {
                    Label(LocalizedString("followup_view", appState.languageCode), systemImage: "chart.line.uptrend.xyaxis")
                }
                Button {
                    if let assessment = latestCompletedWithInsatskarta {
                        assessmentForInsatskarta = assessment
                    } else {
                        showInsatskartaNoData = true
                    }
                } label: {
                    Label(LocalizedString("assessment_form_view_insatskarta", appState.languageCode), systemImage: "map")
                }
                .foregroundColor(AppColors.primary)
            }
        }
        .navigationTitle(LocalizedString("client_profile_assessments_title", appState.languageCode))
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadAssessments() }
        .sheet(item: $selectedAssessment) { assessment in
            AssessmentDetailSheet(client: client, assessment: assessment)
        }
        .fullScreenCover(isPresented: $showInsatskartaNoData) {
            NavigationStack {
                VStack(spacing: 16) {
                    Text(LocalizedString("insatskarta_no_data", lang))
                        .font(.headline)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding()
                    Button(LocalizedString("insatskarta_close", lang)) {
                        showInsatskartaNoData = false
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppColors.primary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppColors.background)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(LocalizedString("insatskarta_close", lang)) {
                            showInsatskartaNoData = false
                        }
                    }
                }
            }
        }
        .fullScreenCover(item: $assessmentForInsatskarta) { assessment in
            if let (recs, flags, ptsd) = parseInsatskartaData(assessment: assessment, store: logicStore) {
                InsatskartraView(
                    recommendations: recs,
                    safetyFlags: flags,
                    ptsd: ptsd,
                    clientName: client.displayName
                )
            } else {
                NavigationStack {
                    VStack(spacing: 16) {
                        Text(LocalizedString("insatskarta_no_data", lang))
                            .font(.headline)
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding()
                        Button(LocalizedString("insatskarta_close", lang)) {
                            assessmentForInsatskarta = nil
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(AppColors.primary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppColors.background)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button(LocalizedString("insatskarta_close", lang)) {
                                assessmentForInsatskarta = nil
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func parseInsatskartaData(assessment: Assessment, store: LogicReferenceStore) -> ([InterventionRecommendation], [SafetyFlag], PTSDEvaluation)? {
        guard let summary = assessment.interventionSummary, !summary.isEmpty else { return nil }
        var recommendations: [InterventionRecommendation] = []
        for (domainKey, anyVal) in summary {
            let dict: [String: Any]
            if let d = anyVal.value as? [String: AnyCodable] {
                dict = d.mapValues(\.value)
            } else if let d = anyVal.value as? [String: Any] {
                dict = d
            } else {
                continue
            }
            let needLevelRaw = dict["needLevel"] as? String ?? ""
            let needLevel = NeedLevel(rawValue: needLevelRaw) ?? .low
            let interventionRaw = dict["interventions"] as? [String] ?? []
            let interventions = interventionRaw.compactMap { Intervention(rawValue: $0) }
            let isUrgent = dict["isUrgent"] as? Bool ?? false
            let notes = dict["notes"] as? String ?? ""
            let domainTitle = AssessmentDefinition.moduleInfo(forKey: domainKey, from: store)?.title ?? domainKey.capitalized
            recommendations.append(InterventionRecommendation(
                domainKey: domainKey,
                domainTitle: domainTitle,
                needLevel: needLevel,
                interventions: interventions.isEmpty ? [.miljoterapeutiskVardag] : interventions,
                isUrgent: isUrgent,
                notes: notes
            ))
        }
        let flags: [SafetyFlag] = (assessment.safetyFlags ?? []).compactMap { flagDict in
            let d: [String: Any]
            if let wrapped = flagDict as? [String: AnyCodable] {
                d = wrapped.mapValues(\.value)
            } else {
                d = flagDict.mapValues(\.value)
            }
            guard let typeRaw = d["type"] as? String,
                  let type = SafetyFlag.FlagType(rawValue: typeRaw),
                  let message = d["message"] as? String else { return nil }
            let requiresAction = d["requiresAction"] as? Bool ?? false
            return SafetyFlag(type: type, message: message, requiresImmediateAction: requiresAction)
        }
        var ptsd = PTSDEvaluation()
        ptsd.totalSymptomScore = assessment.ptsdTotalScore ?? 0
        if assessment.ptsdProbable == true {
            ptsd.criterionBMet = true
            ptsd.criterionCMet = true
            ptsd.criterionDMet = true
            ptsd.criterionEMet = true
        }
        return (recommendations.sorted { $0.isUrgent && !$1.isUrgent }, flags, ptsd)
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
                Text(LocalizedString("client_profile_add_note", appState.languageCode))
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
        .navigationTitle(LocalizedString("client_profile_notes_flags_title", appState.languageCode))
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
        .alert(LocalizedString("client_profile_delete_note", appState.languageCode), isPresented: Binding(
            get: { notePendingDelete != nil },
            set: { if !$0 { notePendingDelete = nil } }
        )) {
            Button(LocalizedString("general_delete", appState.languageCode), role: .destructive) {
                if let note = notePendingDelete {
                    Task { await deleteNote(note: note) }
                }
                notePendingDelete = nil
            }
            Button(LocalizedString("general_cancel", appState.languageCode), role: .cancel) {
                notePendingDelete = nil
            }
        }
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(client.displayName)
                .font(.title3.weight(.semibold))
            Text(LocalizedString("client_profile_staff_only", appState.languageCode))
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
            if let updated = detail?.flags.first?.updatedAt ?? notes.first?.updatedAt {
                Text(LocalizedString("client_profile_last_updated", appState.languageCode).replacingOccurrences(of: "%@", with: dateFormatter.string(from: updated)))
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
            Text(LocalizedString("client_profile_flags", appState.languageCode))
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
            Text(LocalizedString("client_profile_notes", appState.languageCode))
                .font(.headline)
            if let err = notesError {
                Text(err)
                    .foregroundColor(AppColors.danger)
            } else if isNotesLoading {
                ProgressView()
            } else if notes.isEmpty {
                Text(LocalizedString("client_profile_no_notes", appState.languageCode))
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
                Text(LocalizedString("client_profile_note", appState.languageCode))
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
                    Text(LocalizedString("client_profile_delete_note", appState.languageCode))
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
        .navigationTitle(mode == .create ? LocalizedString("client_profile_add_note", appState.languageCode) : LocalizedString("general_edit", appState.languageCode))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(LocalizedString("general_save", appState.languageCode)) {
                    Task { await saveNote() }
                }
                .disabled(!canSave)
            }
        }
        .alert(LocalizedString("client_profile_delete_note", appState.languageCode), isPresented: $showDeleteConfirm) {
            Button(LocalizedString("general_delete", appState.languageCode), role: .destructive) {
                Task { await deleteNote() }
            }
            Button(LocalizedString("general_cancel", appState.languageCode), role: .cancel) {}
        } message: {
            Text(LocalizedString("client_profile_delete_note_confirm", appState.languageCode))
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
                Text(LocalizedString("client_profile_note_metadata", appState.languageCode).replacingOccurrences(of: "%1$@", with: staffName).replacingOccurrences(of: "%2$@", with: note.formattedDate))
                    .font(.subheadline)
                    .foregroundColor(AppColors.textSecondary)
            } else {
                Text(LocalizedString("client_profile_notes_staff_only", appState.languageCode))
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
            Text(LocalizedString("client_profile_visibility", appState.languageCode))
                .font(.headline)
            Text(LocalizedString("client_profile_visibility_staff_only", appState.languageCode))
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
        .navigationTitle(LocalizedString("client_profile_timeline_title", client.displayName))
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
                title: LocalizedString("error_generic", client.displayName),
                subtitle: errorMessage,
                buttonTitle: LocalizedString("general_retry", client.displayName),
                action: { Task { await loadTimeline() } }
            )
        } else if events.isEmpty {
            TimelineMessageCard(
                iconName: "clock.arrow.circlepath",
                title: LocalizedString("client_profile_history", client.displayName),
                subtitle: LocalizedString("client_profile_quick_actions_description", client.displayName),
                buttonTitle: LocalizedString("button_refresh", client.displayName),
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
            Text(LocalizedString("client_profile_quick_actions_description", client.displayName))
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
            Text(LocalizedString("client_profile_history", client.displayName))
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
            title: LocalizedString("general_loading", "en"),
            subtitle: LocalizedString("client_profile_loading", "en"),
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
                    Button(LocalizedString("general_edit", "en"), action: onEdit)
                        .font(.caption.weight(.semibold))
                    Button(LocalizedString("general_delete", "en"), action: onDelete)
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
                Section(header: Text(LocalizedString("client_profile_assessment_overview", "en"))) {
                    HStack {
                        Text(LocalizedString("client_profile_assessment_type", "en"))
                        Spacer()
                        Text(assessment.isBaseline ? "Baseline" : "Follow-up")
                    }
                    HStack {
                        Text(LocalizedString("client_profile_assessment_date", "en"))
                        Spacer()
                        Text(assessment.assessmentDate ?? "—")
                    }
                    HStack {
                        Text(LocalizedString("client_profile_assessment_stress_total", "en"))
                        Spacer()
                        Text("\(assessment.ptsdTotalScore ?? 0)")
                            .bold()
                    }
                    if let probable = assessment.ptsdProbable {
                        Label(
                            probable ? LocalizedString("comparison_probable_ptsd", "en") : LocalizedString("insatskarta_no_action", "en"),
                            systemImage: probable ? "exclamationmark.triangle" : "checkmark.seal"
                        )
                        .foregroundColor(probable ? .red : .green)
                    }
                }
            }
            .navigationTitle(LocalizedString("client_profile_assessment_title", "en"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(LocalizedString("general_done", "en")) { dismiss() }
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
