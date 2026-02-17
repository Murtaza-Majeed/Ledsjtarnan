//
//  LSBadge.swift
//  Ledstjarnan
//
//  Reusable badge component for status indicators
//

import SwiftUI

enum LSBadgeStyle {
    case success
    case warning
    case danger
    case info
    case neutral
    case custom(backgroundColor: Color, textColor: Color)
}

struct LSBadge: View {
    let text: String
    let style: LSBadgeStyle
    var icon: String? = nil
    
    var body: some View {
        HStack(spacing: 4) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.caption2)
            }
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(textColor)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(backgroundColor)
        .cornerRadius(6)
    }
    
    private var backgroundColor: Color {
        switch style {
        case .success:
            return AppColors.success.opacity(0.2)
        case .warning:
            return Color.orange.opacity(0.2)
        case .danger:
            return AppColors.danger.opacity(0.2)
        case .info:
            return AppColors.primary.opacity(0.2)
        case .neutral:
            return AppColors.mutedNeutral.opacity(0.2)
        case .custom(let bg, _):
            return bg
        }
    }
    
    private var textColor: Color {
        switch style {
        case .success:
            return AppColors.success
        case .warning:
            return Color.orange
        case .danger:
            return AppColors.danger
        case .info:
            return AppColors.primary
        case .neutral:
            return AppColors.textSecondary
        case .custom(_, let text):
            return text
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        LSBadge(text: "Baseline", style: .success)
        LSBadge(text: "Due soon", style: .warning, icon: "clock")
        LSBadge(text: "Not linked", style: .danger)
        LSBadge(text: "Linked", style: .info, icon: "link")
        LSBadge(text: "Active", style: .neutral)
        LSBadge(
            text: "Custom",
            style: .custom(
                backgroundColor: AppColors.Category.kropOchHalsaCard,
                textColor: AppColors.Category.kropOchHalsa
            )
        )
    }
    .padding()
}
