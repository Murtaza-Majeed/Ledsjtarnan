//
//  LSEmptyState.swift
//  Ledstjarnan
//
//  Empty state component for lists and content areas
//

import SwiftUI

struct LSEmptyState: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(AppColors.mutedNeutral)
            
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.textPrimary)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            if let actionTitle = actionTitle, let action = action {
                LSButton(
                    title: actionTitle,
                    style: .primary,
                    action: action
                )
                .padding(.horizontal, 60)
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
    }
}

#Preview {
    LSEmptyState(
        icon: "person.2.slash",
        title: "No clients found",
        message: "Create your first client to get started with Ledstjarnan",
        actionTitle: "Create Client",
        action: {}
    )
}
