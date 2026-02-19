//
//  ColorPalette.swift
//  Ledstjarnan
//
//  Created by Murtaza Majeed on 2026-01-29.
//

import SwiftUI

struct AppColors {
    // General UI Colors
    static let background = Color(hex: "FAF2F4")
    static let mainSurface = Color(hex: "F9EDF3")
    static let secondarySurface = Color(hex: "F3E3E9")
    static let primary = Color(hex: "C9699C")
    static let onPrimary = Color.white
    static let textPrimary = Color(hex: "181613")
    static let textSecondary = Color(hex: "7C5B63")
    static let border = Color(hex: "E6D1D9")
    static let danger = Color(hex: "FF3B30")
    static let onDanger = Color.white
    static let success = Color(hex: "34C759")
    static let onSuccess = Color.white
    static let mutedNeutral = Color(hex: "B7A8AF")
    static func shadow(_ opacity: Double = 0.05) -> Color {
        Color.black.opacity(opacity)
    }
    
    // Category Colors
    struct Category {
        static let kropOchHalsa = Color(hex: "00839c")
        static let kropOchHalsaCard = Color(hex: "c5dee6")
        static let kropOchHalsaBg = Color(hex: "dfedf1")
        
        static let sjalvstandighet = Color(hex: "cc69a6")
        static let sjalvstandighetCard = Color(hex: "f1dded")
        static let sjalvstandighetBg = Color(hex: "f7ecf6")
        
        static let identitet = Color(hex: "bccf00")
        static let identitetCard = Color(hex: "f1dded")
        static let identitetBg = Color(hex: "f7f8e6")
        
        static let alkoholDroger = Color(hex: "424241")
        static let alkoholDrogerCard = Color(hex: "E3E3E3")
        static let alkoholDrogerBg = Color(hex: "FFFFFF")
        
        static let socialKompetens = Color(hex: "702673")
        static let socialKompetensCard = Color(hex: "d7c6db")
        static let socialKompetensBg = Color(hex: "ede6f0")
        
        static let natverkRelationer = Color(hex: "80961F")
        static let natverkRelationerCard = Color(hex: "dfe2c6")
        static let natverkRelationerBg = Color(hex: "edefdf")
        
        static let utbildningArbete = Color(hex: "61b7ce")
        static let utbildningArbeteCard = Color(hex: "deedf4")
        static let utbildningArbeteBg = Color(hex: "edf5f9")
        
        static let psykiskOhalsa = Color(hex: "424241")
        static let psykiskOhalsaCard = Color(hex: "E3E3E3")
        static let psykiskOhalsaBg = Color(hex: "FFFFFF")
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
