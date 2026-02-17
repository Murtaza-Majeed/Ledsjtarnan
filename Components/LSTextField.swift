//
//  LSTextField.swift
//  Ledstjarnan
//
//  Reusable text field component with label and validation
//

import SwiftUI

struct LSTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .sentences
    var errorMessage: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
            
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                        .textFieldStyle(.plain)
                } else {
                    TextField(placeholder, text: $text)
                        .textFieldStyle(.plain)
                        .keyboardType(keyboardType)
                        .textInputAutocapitalization(autocapitalization)
                }
            }
            .padding()
            .background(AppColors.secondarySurface)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(errorMessage != nil ? AppColors.danger : Color.clear, lineWidth: 1)
            )
            
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(AppColors.danger)
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        LSTextField(
            label: "Email",
            placeholder: "Enter your email",
            text: .constant("")
        )
        
        LSTextField(
            label: "Password",
            placeholder: "Enter password",
            text: .constant(""),
            isSecure: true
        )
        
        LSTextField(
            label: "Email",
            placeholder: "Enter your email",
            text: .constant("invalid@"),
            errorMessage: "Invalid email format"
        )
    }
    .padding()
}
