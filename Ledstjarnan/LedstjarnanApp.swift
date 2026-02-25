//
//  LedstjarnanApp.swift
//  Ledstjarnan
//
//  Created by Murtaza Majeed on 2026-01-20.
//

import SwiftUI

@main
struct LedstjarnanApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var logicStore = LogicReferenceStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(logicStore)
                .environment(\.locale, Locale(identifier: appState.languageCode))
                .environment(\.languageCode, appState.languageCode)
                .id(appState.languageCode) // Force view refresh when language changes
                .onAppear {
                    print("🌍 App launched with language: \(appState.languageCode)")
                }
        }
    }
}
