//
//  StatusUpdatesView.swift
//  Ledstjarnan
//

import SwiftUI

struct StatusUpdatesView: View {
    private let updates = StatusUpdate.sampleData
    
    var body: some View {
        List {
            ForEach(updates) { update in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label(update.status.displayName, systemImage: update.status.icon)
                            .labelStyle(.titleAndIcon)
                            .foregroundColor(update.status.tint)
                        Spacer()
                        Text(update.date.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    Text(update.title)
                        .font(.headline)
                    Text(update.description)
                        .font(.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                }
                .padding(.vertical, 6)
            }
        }
        .listStyle(.insetGrouped)
        .background(AppColors.background)
        .navigationTitle("Status & Updates")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct StatusUpdate: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let status: SystemStatus
    let date: Date
    
    static let sampleData: [StatusUpdate] = [
        StatusUpdate(
            title: "Livbojen sync queue clear",
            description: "Earlier delays in syncing chapters are resolved. No action required.",
            status: .operational,
            date: Date()
        ),
        StatusUpdate(
            title: "Assessments export bug",
            description: "Some staff noticed duplicate rows in PDF exports. Fix rolling out tonight (v1.0.3).",
            status: .degraded,
            date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        ),
        StatusUpdate(
            title: "Scheduled maintenance",
            description: "Supabase maintenance window on Saturday 02:00–04:00 CET. Login may be temporarily unavailable.",
            status: .planned,
            date: Calendar.current.date(byAdding: .day, value: -3, to: Date())!
        )
    ]
}

enum SystemStatus {
    case operational
    case degraded
    case planned
    
    var displayName: String {
        switch self {
        case .operational: return "Operational"
        case .degraded: return "Degraded"
        case .planned: return "Planned"
        }
    }
    
    var icon: String {
        switch self {
        case .operational: return "checkmark.seal.fill"
        case .degraded: return "exclamationmark.triangle.fill"
        case .planned: return "clock.fill"
        }
    }
    
    var tint: Color {
        switch self {
        case .operational: return AppColors.success
        case .degraded: return AppColors.danger
        case .planned: return AppColors.textSecondary
        }
    }
}
