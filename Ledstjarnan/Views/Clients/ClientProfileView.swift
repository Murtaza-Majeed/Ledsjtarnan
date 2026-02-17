//
//  ClientProfileView.swift
//  Ledstjarnan
//
//  Created by Murtaza Majeed on 2026-01-29.
//

import SwiftUI

struct ClientProfileView: View {
    @ObservedObject var appState: AppState
    let client: Client
    
    @State private var detail: ClientDetail?
    @State private var detailError: String?
    @State private var isDetailLoading = true
    
    @State private var notes: [ClientNote] = []
    @State private var notesError: String?
    @State private var isNotesLoading = true
    @State private var showAddNote = false
    @State private var newNoteText = ""
    @State private var isSavingNote = false
    
    @State private var timelineEvents: [ClientTimelineEvent] = []
    @State private var timelineLoading = true
    @State private var timelineError: String?
    
    @State private var activeLink: ClientLink?
    @State private var showingLinkSheet = false
    @State private var linkError: String?
    @State private var isGeneratingLink = false
    
    private let clientService = ClientService()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection
                statusSection
                flagsSection
                notesSection
                quickActionsSection
                livbojenSection
                timelineSection
            }
            .padding(.bottom, 24)
        }
        .background(AppColors.background)
        .navigationTitle(client.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadAllData()
        }
        .sheet(isPresented: $showAddNote) {
            NavigationView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Staff note")
                        .font(.headline)
                        .foregroundColor(AppColors.textPrimary)
                    TextEditor(text: $newNoteText)
                        .padding()
                        .background(AppColors.secondarySurface)
                        .cornerRadius(12)
                        .frame(minHeight: 160)
                    if isSavingNote {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    Spacer()
                }
                .padding()
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showAddNote = false
                            newNoteText = ""
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            Task { await addNote() }
                        }
                        .disabled(newNoteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSavingNote)
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showingLinkSheet) {
            LinkCodeSheet(link: activeLink)
        }
    }
    
    // MARK: Sections
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Circle()
                .fill(AppColors.primary.opacity(0.2))
                .frame(width: 90, height: 90)
                .overlay(
                    Text(String(client.displayName.prefix(1)))
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundColor(AppColors.primary)
                )
            Text(client.displayName)
                .font(.title2.weight(.semibold))
                .foregroundColor(AppColors.textPrimary)
            Text(client.statusLabel)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(AppColors.secondarySurface)
                .cornerRadius(14)
        }
        .padding(.top, 24)
    }
    
    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Status overview")
                    .font(.headline)
                Spacer()
                if isDetailLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                }
            }
            if let error = detailError {
                Text(error)
                    .font(.subheadline)
                    .foregroundColor(AppColors.danger)
            } else if let detail = detail {
                VStack(alignment: .leading, spacing: 12) {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(detail.statusBadges) { badge in
                            StatusBadgeView(badge: badge)
                        }
                    }
                    Divider().padding(.vertical, 4)
                    HStack {
                        Image(systemName: "note.text")
                            .foregroundColor(AppColors.primary)
                        Text("\(detail.notesCount) staff notes")
                            .foregroundColor(AppColors.textSecondary)
                            .font(.subheadline)
                        Spacer()
                    }
                }
            } else {
                Text("Fetching client data…")
                    .font(.subheadline)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .padding()
        .background(AppColors.mainSurface)
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    private var flagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Flags")
                .font(.headline)
            if let detail = detail {
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
            } else if isDetailLoading {
                ProgressView()
            }
        }
        .padding()
        .background(AppColors.secondarySurface)
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Staff notes")
                    .font(.headline)
                Spacer()
                Button {
                    newNoteText = ""
                    showAddNote = true
                } label: {
                    Label("Add", systemImage: "plus")
                        .labelStyle(.titleAndIcon)
                }
                .tint(AppColors.primary)
            }
            if let err = notesError {
                Text(err)
                    .font(.subheadline)
                    .foregroundColor(AppColors.danger)
            } else if isNotesLoading {
                ProgressView()
            } else if notes.isEmpty {
                Text("No notes yet.")
                    .font(.subheadline)
                    .foregroundColor(AppColors.textSecondary)
            } else {
                ForEach(notes.prefix(3)) { note in
                    NoteRow(note: note)
                    Divider()
                }
                if notes.count > 3 {
                    Text("View all notes in the upcoming Notes screen.")
                        .font(.footnote)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
        .padding()
        .background(AppColors.mainSurface)
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    private var quickActionsSection: some View {
        VStack(spacing: 12) {
            NavigationLink(destination: AssessmentFormView(appState: appState, client: client, assessmentType: "baseline")) {
                ActionCard(icon: "doc.text.fill", title: "Baseline assessment", color: AppColors.primary)
            }
            NavigationLink(destination: AssessmentFormView(appState: appState, client: client, assessmentType: "followup")) {
                ActionCard(icon: "arrow.clockwise", title: "Follow-up", color: AppColors.primary)
            }
            NavigationLink(destination: ClientPlansView(appState: appState, client: client)) {
                ActionCard(icon: "list.bullet.clipboard.fill", title: "Plans", color: AppColors.primary)
            }
            NavigationLink(destination: ClientScheduleView(appState: appState, client: client)) {
                ActionCard(icon: "calendar", title: "Schedule", color: AppColors.primary)
            }
        }
        .padding(.horizontal)
    }
    
    private var livbojenSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Livbojen linking")
                    .font(.headline)
                Spacer()
                if isGeneratingLink {
                    ProgressView().scaleEffect(0.8)
                }
            }
            Text("Generate a 6-digit code for the youth to enter in Livbojen. Codes expire after 15 minutes.")
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
            if let error = linkError {
                Text(error)
                    .font(.footnote)
                    .foregroundColor(AppColors.danger)
            }
            Button {
                Task { await generateLink() }
            } label: {
                Text("Generate link code")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppColors.primary)
                    .cornerRadius(12)
            }
            .disabled(isGeneratingLink)
        }
        .padding()
        .background(AppColors.secondarySurface)
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Timeline")
                .font(.headline)
            if timelineLoading {
                ProgressView()
            } else if let error = timelineError {
                Text(error)
                    .font(.subheadline)
                    .foregroundColor(AppColors.danger)
            } else if timelineEvents.isEmpty {
                Text("No events yet.")
                    .font(.subheadline)
                    .foregroundColor(AppColors.textSecondary)
            } else {
                VStack(spacing: 0) {
                    ForEach(timelineEvents) { event in
                        TimelineEventRow(event: event)
                    }
                }
            }
        }
        .padding()
        .background(AppColors.mainSurface)
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    // MARK: - Data
    
    private func loadAllData() async {
        await loadDetail()
        await loadNotes()
        await loadTimeline()
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
        } catch {
            await MainActor.run {
                self.notesError = error.localizedDescription
                self.isNotesLoading = false
            }
        }
    }
    
    private func loadTimeline() async {
        timelineLoading = true
        timelineError = nil
        do {
            let events = try await clientService.getTimeline(clientId: client.id)
            await MainActor.run {
                self.timelineEvents = events
                self.timelineLoading = false
            }
        } catch {
            await MainActor.run {
                self.timelineError = error.localizedDescription
                self.timelineLoading = false
            }
        }
    }
    
    // MARK: - Actions
    
    private func toggleFlag(type: ClientFlagType, currentlyOn: Bool) {
        guard let staffId = appState.currentStaffProfile?.id else { return }
        Task {
            try? await clientService.toggleFlag(clientId: client.id, flagKey: type.rawValue, isOn: !currentlyOn, staffId: staffId)
            await loadDetail()
        }
    }
    
    private func addNote() async {
        guard let staffId = appState.currentStaffProfile?.id else { return }
        let trimmed = newNoteText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        isSavingNote = true
        do {
            _ = try await clientService.createNote(clientId: client.id, staffId: staffId, noteText: trimmed)
            await loadNotes()
            await MainActor.run {
                newNoteText = ""
                showAddNote = false
                isSavingNote = false
            }
        } catch {
            await MainActor.run {
                notesError = error.localizedDescription
                isSavingNote = false
            }
        }
    }
    
    private func generateLink() async {
        guard let staffId = appState.currentStaffProfile?.id,
              let unitId = appState.currentUnit?.id else {
            linkError = "Missing staff or unit context."
            return
        }
        isGeneratingLink = true
        linkError = nil
        do {
            let link = try await clientService.generateLinkCode(clientId: client.id, unitId: unitId, createdByStaffId: staffId)
            await MainActor.run {
                self.activeLink = link
                self.showingLinkSheet = true
                self.isGeneratingLink = false
            }
        } catch {
            await MainActor.run {
                self.linkError = error.localizedDescription
                self.isGeneratingLink = false
            }
        }
    }
}

struct TimelineEventRow: View {
    let event: ClientTimelineEvent
    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(event.title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(AppColors.textPrimary)
            if let desc = event.description, !desc.isEmpty {
                Text(desc)
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            if let date = event.createdAt {
                Text(Self.dateFormatter.string(from: date))
                    .font(.caption2)
                    .foregroundColor(AppColors.mutedNeutral)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(AppColors.mainSurface)
        .cornerRadius(8)
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
    }
}

struct ActionCard: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 40)
            
            Text(title)
                .font(.headline)
                .foregroundColor(AppColors.textPrimary)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(AppColors.mutedNeutral)
        }
        .padding()
        .background(AppColors.mainSurface)
        .cornerRadius(12)
    }
}

struct StatusBadgeView: View {
    let badge: ClientDetail.StatusBadge
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: badge.icon)
                    .foregroundColor(AppColors.primary)
                Text(badge.label)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(AppColors.textPrimary)
            }
            if let detail = badge.detail {
                Text(detail)
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .padding()
        .background(AppColors.secondarySurface)
        .cornerRadius(14)
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
            .foregroundColor(isActive ? .white : AppColors.textPrimary)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(isActive ? AppColors.primary : AppColors.mainSurface)
            .cornerRadius(12)
            .shadow(color: isActive ? AppColors.primary.opacity(0.25) : .clear, radius: 6, y: 4)
        }
    }
}

struct NoteRow: View {
    let note: ClientNote
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(note.noteText)
                .font(.subheadline)
                .foregroundColor(AppColors.textPrimary)
            Text(note.formattedDate)
                .font(.caption)
                .foregroundColor(AppColors.textSecondary)
        }
    }
}

struct LinkCodeSheet: View {
    let link: ClientLink?
    private let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if let link {
                    Text("Share this code with the youth. It expires at \(formatter.string(from: link.expiresAt)).")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundColor(AppColors.textSecondary)
                    HStack(spacing: 12) {
                        ForEach(Array(link.code), id: \.self) { digit in
                            Text(String(digit))
                                .font(.title.bold())
                                .frame(width: 44, height: 60)
                                .background(AppColors.mainSurface)
                                .cornerRadius(10)
                        }
                    }
                    Text(link.displayStatus)
                        .font(.footnote)
                        .foregroundColor(AppColors.textSecondary)
                } else {
                    Text("No active link code.")
                        .font(.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                }
                Spacer()
            }
            .padding()
            .navigationTitle("Livbojen link")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    let sampleClient = Client(
        id: "1",
        unitId: "unit-1",
        nameOrCode: "Anna Andersson",
        linkedUserId: nil,
        createdByStaffId: nil,
        createdAt: Date(),
        updatedAt: Date()
    )
    return NavigationView {
        ClientProfileView(appState: AppState(), client: sampleClient)
    }
}
