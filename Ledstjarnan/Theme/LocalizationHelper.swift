//
//  LocalizationHelper.swift
//  Ledstjarnan
//
//  Created for dynamic localization support
//

import Foundation
import SwiftUI

// Custom environment key for language code
struct LanguageCodeKey: EnvironmentKey {
    static let defaultValue: String = "sv"
}

extension EnvironmentValues {
    var languageCode: String {
        get { self[LanguageCodeKey.self] }
        set { self[LanguageCodeKey.self] = newValue }
    }
}

/// Helper function to get localized strings based on the current app language
func LocalizedString(_ key: String, _ languageCode: String, comment: String = "") -> String {
    // Get the bundle for the specific language
    guard let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
          let bundle = Bundle(path: path) else {
        print("⚠️ Could not find bundle for language: \(languageCode)")
        return key
    }
    
    let localizedString = bundle.localizedString(forKey: key, value: key, table: nil)
    return localizedString
}

/// Extension to easily access localized strings
extension String {
    func localized(_ languageCode: String) -> String {
        return LocalizedString(self, languageCode)
    }
}
