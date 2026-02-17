//
//  LSCard.swift
//  Ledstjarnan
//
//  Reusable card component for consistent styling
//

import SwiftUI

struct LSCard<Content: View>: View {
    let content: Content
    var backgroundColor: Color = AppColors.mainSurface
    var padding: CGFloat = 16
    
    init(
        backgroundColor: Color = AppColors.mainSurface,
        padding: CGFloat = 16,
        @ViewBuilder content: () -> Content
    ) {
        self.backgroundColor = backgroundColor
        self.padding = padding
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(backgroundColor)
            .cornerRadius(12)
    }
}

#Preview {
    VStack(spacing: 16) {
        LSCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Card Title")
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary)
                Text("This is some content inside a card")
                    .font(.subheadline)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        
        LSCard(backgroundColor: AppColors.secondarySurface) {
            Text("Secondary surface card")
                .foregroundColor(AppColors.textPrimary)
        }
    }
    .padding()
    .background(AppColors.background)
}
