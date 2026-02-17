//
//  LSNavigationBar.swift
//  Ledstjarnan
//
//  Custom navigation bar for consistent header styling
//

import SwiftUI

struct LSNavigationBar: View {
    let title: String
    var leftAction: (() -> Void)? = nil
    var leftIcon: String? = nil
    var leftText: String? = nil
    var rightAction: (() -> Void)? = nil
    var rightIcon: String? = nil
    var rightText: String? = nil
    
    var body: some View {
        HStack {
            // Left button
            if let action = leftAction {
                Button(action: action) {
                    HStack(spacing: 4) {
                        if let icon = leftIcon {
                            Image(systemName: icon)
                                .font(.body)
                        }
                        if let text = leftText {
                            Text(text)
                                .font(.body)
                        }
                    }
                    .foregroundColor(AppColors.primary)
                }
            } else {
                Spacer()
                    .frame(width: 44)
            }
            
            Spacer()
            
            // Title
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.textPrimary)
            
            Spacer()
            
            // Right button
            if let action = rightAction {
                Button(action: action) {
                    HStack(spacing: 4) {
                        if let text = rightText {
                            Text(text)
                                .font(.body)
                        }
                        if let icon = rightIcon {
                            Image(systemName: icon)
                                .font(.body)
                        }
                    }
                    .foregroundColor(AppColors.primary)
                }
            } else {
                Spacer()
                    .frame(width: 44)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(AppColors.mainSurface)
    }
}

#Preview {
    VStack(spacing: 0) {
        LSNavigationBar(
            title: "Client Profile",
            leftAction: {},
            leftIcon: "chevron.left",
            leftText: "Back",
            rightAction: {},
            rightIcon: "ellipsis"
        )
        
        Spacer()
    }
    .background(AppColors.background)
}
