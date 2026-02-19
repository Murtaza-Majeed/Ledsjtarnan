//
//  TraumaScreeningView.swift
//  Ledstjarnan
//
//  STRESS trauma screening: events (Q1–21), symptoms (Q22–46), functional impairment (Q47–52).
//

import SwiftUI

struct TraumaScreeningView: View {
    @Binding var answers: [String: AnyCodable]
    let missingKeys: Set<String>
    @State private var selectedTab = 0

    private let symptomLabels: [Int: String] = {
        var d: [Int: String] = [:]
        for n in 22...46 { d[n] = "Fråga \(n)" }
        return d
    }()
    private let impairmentLabels: [Int: String] = {
        var d: [Int: String] = [:]
        for n in 47...52 { d[n] = "Funktionsfråga \(n)" }
        return d
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("", selection: $selectedTab) {
                Text("Händelser").tag(0)
                Text("Symtom Q22–46").tag(1)
                Text("Funktion Q47–52").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            switch selectedTab {
            case 0:
                eventsSection
            case 1:
                symptomsSection
            case 2:
                impairmentSection
            default:
                eventsSection
            }
        }
        .padding(.vertical, 8)
    }

    private var eventsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Traumatiska händelser (vuxenliv)")
                .font(.subheadline.bold())
                .foregroundColor(AppColors.textPrimary)
            yesNoRow(key: "trauma.adultEventsMultiple", label: "Flera traumatiska händelser som vuxen?")

            Text("Traumatiska händelser (barn/ungdom)")
                .font(.subheadline.bold())
                .foregroundColor(AppColors.textPrimary)
                .padding(.top, 8)
            yesNoRow(key: "trauma.childEventsMultiple", label: "Flera traumatiska händelser som barn/ungdom?")
        }
        .padding()
        .background(AppColors.secondarySurface)
        .cornerRadius(12)
        .padding(.horizontal)
    }

    private var symptomsSection: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Symtom (0 = Aldrig, 1 = 1 gång, 2 = 2–3 gånger, 3 = De flesta dagarna)")
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
                ForEach(Array(22...46), id: \.self) { n in
                    symptomRow(q: n)
                }
            }
            .padding()
        }
        .frame(maxHeight: 400)
        .background(AppColors.secondarySurface)
        .cornerRadius(12)
        .padding(.horizontal)
    }

    private var impairmentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Funktionsnedsättning (Ja/Nej)")
                .font(.caption)
                .foregroundColor(AppColors.textSecondary)
            ForEach(Array(47...52), id: \.self) { n in
                yesNoRow(key: "trauma.q\(n)", label: impairmentLabels[n] ?? "Q\(n)")
            }
        }
        .padding()
        .background(AppColors.secondarySurface)
        .cornerRadius(12)
        .padding(.horizontal)
    }

    private func yesNoRow(key: String, label: String) -> some View {
        let binding: Binding<Bool?> = Binding(
            get: { answers[key]?.value as? Bool },
            set: { newValue in
                if let value = newValue {
                    answers[key] = AnyCodable(value)
                } else {
                    answers.removeValue(forKey: key)
                }
            }
        )
        let selection = binding.wrappedValue
        return HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(AppColors.textPrimary)
            Spacer()
            HStack(spacing: 8) {
                Button(action: {
                    binding.wrappedValue = (selection == true) ? nil : true
                }) {
                    Text("Ja")
                        .font(.caption)
                        .fontWeight(selection == true ? .semibold : .regular)
                        .foregroundColor(selection == true ? AppColors.onPrimary : AppColors.textPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(selection == true ? AppColors.primary : AppColors.mainSurface)
                        .cornerRadius(8)
                }
                Button(action: {
                    binding.wrappedValue = (selection == false) ? nil : false
                }) {
                    Text("Nej")
                        .font(.caption)
                        .fontWeight(selection == false ? .semibold : .regular)
                        .foregroundColor(selection == false ? AppColors.onPrimary : AppColors.textPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(selection == false ? AppColors.primary : AppColors.mainSurface)
                        .cornerRadius(8)
                }
            }
            if missingKeys.contains(key) {
                Text("Required").font(.caption2).foregroundColor(AppColors.danger)
            }
        }
        .padding(.vertical, 4)
    }

    private func symptomRow(q: Int) -> some View {
        let key = "trauma.q\(q)"
        let binding: Binding<Int?> = Binding(
            get: { answers[key]?.value as? Int },
            set: { newValue in
                if let value = newValue {
                    answers[key] = AnyCodable(value)
                } else {
                    answers.removeValue(forKey: key)
                }
            }
        )
        let labels = ["0", "1", "2", "3"]
        return HStack {
            Text(symptomLabels[q] ?? "Q\(q)")
                .font(.caption)
                .foregroundColor(AppColors.textPrimary)
                .frame(width: 70, alignment: .leading)
            ForEach(0..<4, id: \.self) { n in
                let isSelected = binding.wrappedValue == n
                Button(action: {
                    if isSelected {
                        binding.wrappedValue = nil
                    } else {
                        binding.wrappedValue = n
                    }
                }) {
                    Text(labels[n])
                        .font(.caption2)
                        .fontWeight(isSelected ? .semibold : .regular)
                        .foregroundColor(isSelected ? AppColors.onPrimary : AppColors.textPrimary)
                        .frame(width: 32, height: 28)
                        .background(isSelected ? AppColors.primary : AppColors.mainSurface)
                        .cornerRadius(6)
                }
            }
            if missingKeys.contains(key) {
                Text("Required")
                    .font(.caption2)
                    .foregroundColor(AppColors.danger)
            }
        }
        .padding(.vertical, 2)
    }
}
