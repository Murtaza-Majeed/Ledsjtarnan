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
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
        }
    }
}
