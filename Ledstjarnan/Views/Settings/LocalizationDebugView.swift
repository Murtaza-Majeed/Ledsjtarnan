//
//  LocalizationDebugView.swift
//  Ledstjarnan
//
//  Debug view to test localization
//

import SwiftUI

struct LocalizationDebugView: View {
    @ObservedObject var appState: AppState
    
    var body: some View {
        List {
            Section("Current Language") {
                Text("AppState languageCode: \(appState.languageCode)")
            }
            
            Section("Bundle Information") {
                Text("Main bundle path: \(Bundle.main.bundlePath)")
                
                if let svPath = Bundle.main.path(forResource: "sv", ofType: "lproj") {
                    Text("✅ sv.lproj found at: \(svPath)")
                } else {
                    Text("❌ sv.lproj NOT found")
                }
                
                if let enPath = Bundle.main.path(forResource: "en", ofType: "lproj") {
                    Text("✅ en.lproj found at: \(enPath)")
                } else {
                    Text("❌ en.lproj NOT found")
                }
            }
            
            Section("Test Strings (Swedish)") {
                Text("general_back: \(LocalizedString("general_back", "sv"))")
                Text("general_save: \(LocalizedString("general_save", "sv"))")
                Text("settings_about: \(LocalizedString("settings_about", "sv"))")
            }
            
            Section("Test Strings (English)") {
                Text("general_back: \(LocalizedString("general_back", "en"))")
                Text("general_save: \(LocalizedString("general_save", "en"))")
                Text("settings_about: \(LocalizedString("settings_about", "en"))")
            }
            
            Section("Test Current Language") {
                let lang = appState.languageCode
                Text("general_back: \(LocalizedString("general_back", lang))")
                Text("general_save: \(LocalizedString("general_save", lang))")
                Text("settings_about: \(LocalizedString("settings_about", lang))")
            }
        }
        .navigationTitle("Localization Debug")
    }
}
