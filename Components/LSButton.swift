//
//  LSButton.swift
//  Ledstjarnan
//
//  Reusable button component with primary, secondary, and destructive styles
//

import SwiftUI

enum LSButtonStyle {
    case primary
    case secondary
    case destructive
    case ghost
}

struct LSButton: View {
    let title: String
    let style: LSButtonStyle
    let action: () -> Void
    var isLoading: Bool = false
    var isDisabled: Bool = false
    var icon: String? = nil
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: textColor))
                        .scaleEffect(0.8)
                } else {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.headline)
                    }
                    Text(title)
                        .font(.headline)
                }
            }
            .foregroundColor(textColor)
            .frame(maxWidth: .infinity)
            .padding()
            .background(backgroundColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: style == .secondary || style == .ghost ? 1 : 0)
            )
        }
        .disabled(isDisabled || isLoading)
        .opacity(isDisabled ? 0.5 : 1.0)
    }
    
    private var backgroundColor: Color {
        switch style {
        case .primary:
            return AppColors.primary
        case .secondary:
            return AppColors.secondarySurface
        case .destructive:
            return AppColors.danger
        case .ghost:
            return Color.clear
        }
    }
    
    private var textColor: Color {
        switch style {
        case .primary, .destructive:
            return .white
        case .secondary:
            return AppColors.primary
        case .ghost:
            return AppColors.primary
        }
    }
    
    private var borderColor: Color {
        switch style {
        case .secondary, .ghost:
            return AppColors.primary
        default:
            return .clear
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        LSButton(title: "Primary Button", style: .primary, action: {})
        LSButton(title: "Secondary Button", style: .secondary, action: {})
        LSButton(title: "Destructive Button", style: .destructive, action: {})
        LSButton(title: "Ghost Button", style: .ghost, action: {})
        LSButton(title: "Loading", style: .primary, action: {}, isLoading: true)
        LSButton(title: "Disabled", style: .primary, action: {}, isDisabled: true)
        LSButton(title: "With Icon", style: .primary, action: {}, icon: "plus")
    }
    .padding()
}
