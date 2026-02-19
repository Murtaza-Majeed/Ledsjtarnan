//
//  UnitJoinView.swift
//  Ledstjarnan
//
//  Shown when staff is authenticated but has no unit. Join by enterering unit join code.
//

import SwiftUI

struct UnitJoinView: View {
    @ObservedObject var appState: AppState
    @State private var joinCode = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    private let staffService = StaffService()

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [AppColors.background, AppColors.secondarySurface],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Text("Connect to your home")
                            .font(.title.bold())
                            .foregroundColor(AppColors.textPrimary)
                            .multilineTextAlignment(.center)
                        Text("Ask your unit lead for the current 6-digit join code.")
                            .font(.subheadline)
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    .padding(.horizontal)

                    VStack(spacing: 20) {
                        HStack {
                            Image(systemName: "number.circle")
                                .foregroundColor(AppColors.primary)
                            Text("Unit join code")
                                .font(.headline)
                                .foregroundColor(AppColors.textPrimary)
                            Spacer()
                        }

                        TextField("e.g. 123456", text: $joinCode)
                            .keyboardType(.numberPad)
                            .textInputAutocapitalization(.characters)
                            .disableAutocorrection(true)
                            .padding()
                            .background(.thinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(AppColors.primary.opacity(0.3), lineWidth: 1)
                            )

                        if let error = errorMessage {
                            Text(error)
                                .font(.subheadline)
                                .foregroundColor(AppColors.danger)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Button(action: joinUnit) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: AppColors.onPrimary))
                                } else {
                                    Text("Join unit")
                                        .font(.headline)
                                }
                            }
                            .foregroundColor(AppColors.onPrimary)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppColors.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .shadow(color: AppColors.primary.opacity(0.35), radius: 12, y: 8)
                        }
                        .disabled(isLoading || joinCode.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    .padding(24)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .padding(.horizontal)

                    Spacer()
                }
            }
            .navigationBarHidden(true)
        }
    }

    private func joinUnit() {
        errorMessage = nil
        isLoading = true
        let code = joinCode.trimmingCharacters(in: .whitespacesAndNewlines)
        Task {
            do {
                guard let staffId = appState.currentStaffProfile?.id else {
                    throw StaffServiceError.invalidJoinCode
                }
                let unit = try await staffService.getUnitByJoinCode(code)
                try await staffService.updateStaffUnit(staffId: staffId, unitId: unit.id)
                await appState.loadStaffProfile()
                await MainActor.run {
                    appState.hasSeenOnboarding = true
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

#Preview {
    UnitJoinView(appState: AppState())
}
