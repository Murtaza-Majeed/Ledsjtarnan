//
//  ScheduleDashboardView.swift
//  Ledstjarnan
//

import SwiftUI

struct ScheduleDashboardView: View {
    @ObservedObject var appState: AppState
    @State private var items: [PlannerItem] = []
    @State private var groupedItems: [Date: [PlannerItem]] = [:]
    @State private var clientNames: [String: String] = [:]
    @State private var loading = true
    @State private var loadError: String?
    @State private var showAddItem = false
    @State private var selectedItem: PlannerItem?
    private let plannerService = PlannerService()
    private let clientService = ClientService()
    
    private var lang: String { appState.languageCode }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                header
                if loading {
                    ProgressView(LocalizedString("schedule_loading", lang))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = loadError {
                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(AppColors.danger)
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if items.isEmpty {
                    EmptyScheduleState(lang: lang) {
                        showAddItem = true
                    }
                } else {
                    scheduleList
                }
            }
            .background(AppColors.background)
            .navigationTitle(LocalizedString("schedule_title", lang))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showAddItem = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(AppColors.primary)
                    }
                }
            }
            .sheet(isPresented: $showAddItem) {
                if let unitId = appState.currentUnit?.id {
                    PlannerItemComposer(
                        appState: appState,
                        unitId: unitId,
                        onSaved: {
                            showAddItem = false
                            Task { await loadItems() }
                        }
                    )
                }
            }
            .sheet(item: $selectedItem) { item in
                PlannerItemDetailSheet(
                    appState: appState,
                    item: item,
                    clientName: clientNames[item.clientId ?? ""] ?? "—",
                    onUpdated: {
                        Task { await loadItems() }
                    }
                )
            }
            .task {
                await loadItems()
            }
            .refreshable {
                await loadItems()
            }
        }
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LocalizedString("schedule_upcoming", lang))
                .font(.headline)
                .foregroundColor(AppColors.textSecondary)
            HStack {
                Text(String(format: LocalizedString("schedule_planned_items_count", lang), items.count))
                    .font(.title2.weight(.semibold))
                Spacer()
                Button(action: { showAddItem = true }) {
                    Label(LocalizedString("general_new", lang), systemImage: "plus.circle.fill")
                        .labelStyle(.titleAndIcon)
                        .foregroundColor(AppColors.primary)
                }
            }
        }
        .padding(.horizontal)
        .padding(.top)
    }
    
    private var scheduleList: some View {
        List {
            ForEach(groupedItems.keys.sorted(), id: \.self) { date in
                Section(header: Text(date, style: .date).font(.subheadline)) {
                    ForEach(groupedItems[date] ?? []) { item in
                        Button {
                            selectedItem = item
                        } label: {
                            PlannerItemRow(
                                item: item,
                                clientName: item.clientId.flatMap { clientNames[$0] } ?? "—"
                            )
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    private func loadItems() async {
        guard let unitId = appState.currentUnit?.id else {
            await MainActor.run {
                loadError = LocalizedString("plans_error_no_unit", lang)
                loading = false
            }
            return
        }
        loading = true
        loadError = nil
        do {
            let list = try await plannerService.getItems(unitId: unitId)
            let clientIds = Set(list.compactMap(\.clientId))
            var names: [String: String] = [:]
            if !clientIds.isEmpty {
                let clients = try await clientService.getClients(unitId: unitId)
                for c in clients where clientIds.contains(c.id) {
                    names[c.id] = c.displayName
                }
            }
            let grouped = Dictionary(grouping: list) { item in
                Calendar.current.startOfDay(for: item.startAt)
            }
            await MainActor.run {
                items = list.sorted { $0.startAt < $1.startAt }
                clientNames = names
                groupedItems = grouped
                loading = false
            }
        } catch {
            await MainActor.run {
                loadError = error.localizedDescription
                loading = false
            }
        }
    }
}

// MARK: - Subviews

private struct EmptyScheduleState: View {
    let lang: String
    let onAdd: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(AppColors.primary)
            Text(LocalizedString("schedule_no_items", lang))
                .font(.headline)
                .foregroundColor(AppColors.textPrimary)
            Text(LocalizedString("schedule_no_items_hint", lang))
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button(LocalizedString("schedule_add_first_item", lang), action: onAdd)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(AppColors.primary)
                .foregroundColor(AppColors.onPrimary)
                .cornerRadius(12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Planner Item Composer

struct PlannerItemComposer: View {
    @ObservedObject var appState: AppState
    let unitId: String
    var clientIdPreFill: String? = nil
    var onSaved: () -> Void
    @Environment(\.dismiss) var dismiss
    
    @State private var clients: [Client] = []
    @State private var clientId: String = ""
    @State private var type = PlannerItemType.session
    @State private var title = ""
    @State private var startAt = Date()
    @State private var duration: TimeInterval = 60 * 60
    @State private var locked = false
    @State private var notes: String = ""
    @State private var errorMessage: String?
    @State private var isSaving = false
    
    private let plannerService = PlannerService()
    private let clientService = ClientService()
    
    var body: some View {
        NavigationView {
            Form {
                Section(LocalizedString("general_unknown", appState.languageCode)) {
                    Picker(LocalizedString("general_unknown", appState.languageCode), selection: $clientId) {
                        Text(LocalizedString("schedule_item_unit_wide", appState.languageCode)).tag("")
                        ForEach(clients) { client in
                            Text(client.displayName).tag(client.id)
                        }
                    }
                }
                Section(LocalizedString("client_profile_basic_info", appState.languageCode)) {
                    Picker(LocalizedString("client_profile_assessment_type", appState.languageCode), selection: $type) {
                        ForEach(PlannerItemType.allCases, id: \.rawValue) { option in
                            Text(option.displayName).tag(option)
                        }
                    }
                    TextField(LocalizedString("schedule_item_title", appState.languageCode), text: $title)
                    DatePicker(LocalizedString("schedule_event_date", appState.languageCode), selection: $startAt, displayedComponents: [.date, .hourAndMinute])
                    DurationPicker(duration: $duration, showEndTime: type == .session)
                    Toggle(LocalizedString("plan_builder_responsibility_shared", appState.languageCode), isOn: $locked)
                    TextField(LocalizedString("schedule_item_notes", appState.languageCode), text: $notes, axis: .vertical)
                }
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(AppColors.danger)
                    }
                }
            }
            .navigationTitle(LocalizedString("schedule_new_item_title", appState.languageCode))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(LocalizedString("general_cancel", appState.languageCode)) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(LocalizedString("general_save", appState.languageCode)) { Task { await saveItem() } }
                        .disabled(isSaving || title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .task {
                await loadClients()
                if let prefill = clientIdPreFill {
                    clientId = prefill
                }
            }
        }
    }
    
    private func loadClients() async {
        do {
            let list = try await clientService.getClients(unitId: unitId)
            await MainActor.run { clients = list }
        } catch {
            await MainActor.run { errorMessage = error.localizedDescription }
        }
    }
    
    private func saveItem() async {
        guard let staffId = appState.currentStaffProfile?.id else { return }
        isSaving = true
        errorMessage = nil
        let endDate = type == .session ? startAt.addingTimeInterval(duration) : nil
        do {
            _ = try await plannerService.createItem(
                unitId: unitId,
                clientId: clientId.isEmpty ? nil : clientId,
                type: type.rawValue,
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                startAt: startAt,
                endAt: endDate,
                locked: locked,
                createdByUserId: staffId
            )
            await MainActor.run {
                isSaving = false
                onSaved()
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isSaving = false
            }
        }
    }
}

// MARK: - Planner Item Detail

struct PlannerItemDetailSheet: View {
    @ObservedObject var appState: AppState
    let item: PlannerItem
    let clientName: String
    let onUpdated: () -> Void
    @Environment(\.dismiss) var dismiss
    
    @State private var status: PlannerItemStatus
    @State private var showConflictWarning = false
    @State private var isUpdatingStatus = false
    
    private let plannerService = PlannerService()
    
    init(appState: AppState, item: PlannerItem, clientName: String, onUpdated: @escaping () -> Void) {
        self.appState = appState
        self.item = item
        self.clientName = clientName
        self.onUpdated = onUpdated
        self._status = State(initialValue: PlannerItemStatus(rawValue: item.status) ?? .planned)
    }
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading) {
                        Text(item.title)
                            .font(.title3.weight(.semibold))
                        Text(clientName)
                            .font(.subheadline)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    Spacer()
                    if item.isLocked {
                        Label(LocalizedString("plan_builder_responsibility_shared", appState.languageCode), systemImage: "lock.fill")
                            .font(.caption)
                            .padding(6)
                            .background(AppColors.primary.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                DetailRow(label: LocalizedString("client_profile_assessment_type", appState.languageCode), value: item.type.capitalized)
                DetailRow(label: LocalizedString("schedule_event_date", appState.languageCode), value: plannerDateFormatter.string(from: item.startAt))
                if let endAt = item.endAt {
                    DetailRow(label: LocalizedString("schedule_event_time", appState.languageCode), value: plannerDateFormatter.string(from: endAt))
                    if endAt < item.startAt {
                        ConflictWarningView(reason: LocalizedString("error_generic", appState.languageCode))
                    }
                } else {
                    DetailRow(label: LocalizedString("schedule_event_time", appState.languageCode), value: LocalizedString("general_none", appState.languageCode))
                }
                DetailRow(label: LocalizedString("client_profile_status", appState.languageCode), value: status.displayName)
                if let notes = item.notes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(LocalizedString("schedule_item_notes", appState.languageCode))
                            .font(.headline)
                        Text(notes)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                Spacer()
                Picker(LocalizedString("client_profile_status", appState.languageCode), selection: $status) {
                    ForEach(PlannerItemStatus.allCases, id: \.rawValue) { option in
                        Text(option.displayName).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                Button(LocalizedString("schedule_update_status", appState.languageCode)) {
                    Task { await updateStatus() }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isUpdatingStatus)
            }
            .padding()
            .navigationTitle(LocalizedString("schedule_item_title", appState.languageCode))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(LocalizedString("general_close", appState.languageCode)) { dismiss() }
                }
            }
        }
    }
    
    private func updateStatus() async {
        do {
            try await plannerService.updateStatus(itemId: item.id, status: status.rawValue)
            await MainActor.run {
                onUpdated()
                dismiss()
            }
        } catch {
            await MainActor.run {
                showConflictWarning = true
            }
        }
    }
}

// MARK: - Helpers

private let plannerDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter
}()

private struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(AppColors.textSecondary)
            Spacer()
            Text(value)
                .foregroundColor(AppColors.textPrimary)
        }
    }
}

private struct PlannerItemRow: View {
    let item: PlannerItem
    let clientName: String
    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(item.title)
                        .font(.headline)
                    if item.isLocked {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                            .foregroundColor(AppColors.primary)
                    }
                }
                Text(clientName)
                    .font(.subheadline)
                    .foregroundColor(AppColors.textSecondary)
                Text(Self.formatter.string(from: item.startAt))
                    .font(.caption)
                    .foregroundColor(AppColors.mutedNeutral)
            }
            Spacer()
            Text(item.type.capitalized)
                .font(.caption)
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(.vertical, 8)
    }
}

private struct ConflictWarningView: View {
    let reason: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(AppColors.danger)
            Text(reason)
                .font(.caption)
                .foregroundColor(AppColors.danger)
        }
        .padding(8)
        .background(AppColors.danger.opacity(0.1))
        .cornerRadius(8)
    }
}

private enum PlannerItemType: String, CaseIterable {
    case session, task, activity
    
    var displayName: String {
        switch self {
        case .session: return "Session"
        case .task: return "Task"
        case .activity: return "Activity"
        }
    }
}

private enum PlannerItemStatus: String, CaseIterable {
    case planned, done, cancelled
    
    var displayName: String {
        switch self {
        case .planned: return "Planned"
        case .done: return "Done"
        case .cancelled: return "Cancelled"
        }
    }
}

private struct DurationPicker: View {
    @Binding var duration: TimeInterval
    let showEndTime: Bool
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(LocalizedString("schedule_duration", "en"))
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
            HStack {
                ForEach([30, 60, 90, 120], id: \.self) { minutes in
                    Button(action: { duration = Double(minutes * 60) }) {
                        Text(LocalizedString("schedule_duration_minutes", "en").replacingOccurrences(of: "%d", with: "\(minutes)"))
                            .font(.caption)
                            .padding(6)
                            .frame(maxWidth: .infinity)
                            .background(duration == Double(minutes * 60) ? AppColors.primary : AppColors.mainSurface)
                            .foregroundColor(duration == Double(minutes * 60) ? .white : AppColors.textPrimary)
                            .cornerRadius(8)
                    }
                }
            }
            if showEndTime {
                Text(LocalizedString("schedule_end_time", "en").replacingOccurrences(of: "%@", with: endTimeString))
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
    }
    
    private var endTimeString: String {
        let date = Date().addingTimeInterval(duration)
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
