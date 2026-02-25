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
    @EnvironmentObject private var logicStore: LogicReferenceStore
    @Environment(\.languageCode) var lang

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("", selection: $selectedTab) {
                Text(LocalizedString("trauma_tab_events", lang)).tag(0)
                Text(LocalizedString("trauma_tab_symptoms", lang)).tag(1)
                Text(LocalizedString("trauma_tab_function", lang)).tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            currentTab
        }
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var currentTab: some View {
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

    private var eventsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizedString("trauma_events_header", lang))
                .font(.subheadline.bold())
                .foregroundColor(AppColors.textPrimary)
            if baseEventQuestions.isEmpty {
                Text(LocalizedString("trauma_events_manual_hint", lang))
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
            } else {
                ForEach(baseEventQuestions, id: \.code) { question in
                    traumaQuestionRow(question)
                }
            }

            if !parentEventQuestions.isEmpty {
                Text(LocalizedString("trauma_events_parent_only", lang))
                    .font(.subheadline.bold())
                    .foregroundColor(AppColors.textPrimary)
                ForEach(parentEventQuestions, id: \.code) { question in
                    traumaQuestionRow(question)
                }
            }

            Text(LocalizedString("trauma_events_adult_header", lang))
                .font(.subheadline.bold())
                .foregroundColor(AppColors.textPrimary)
            if adultEventFlags.isEmpty {
                yesNoRow(key: "trauma.adultEventsMultiple", label: LocalizedString("trauma_events_adult_question", lang))
            } else {
                ForEach(adultEventFlags, id: \.code) { question in
                    traumaQuestionRow(question)
                }
            }

            Text(LocalizedString("trauma_events_child_header", lang))
                .font(.subheadline.bold())
                .foregroundColor(AppColors.textPrimary)
                .padding(.top, 8)
            if childEventFlags.isEmpty {
                yesNoRow(key: "trauma.childEventsMultiple", label: LocalizedString("trauma_events_child_question", lang))
            } else {
                ForEach(childEventFlags, id: \.code) { question in
                    traumaQuestionRow(question)
                }
            }
        }
        .padding()
        .background(AppColors.secondarySurface)
        .cornerRadius(12)
        .padding(.horizontal)
    }

    private var symptomsSection: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(LocalizedString("trauma_symptoms_header", lang))
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
                if symptomQuestions.isEmpty {
                    ForEach(Array(22...46), id: \.self) { n in
                        defaultSymptomRow(q: n)
                    }
                } else {
                    ForEach(symptomQuestions, id: \.code) { question in
                        traumaQuestionRow(question)
                    }
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
            Text(LocalizedString("trauma_function_header", lang))
                .font(.caption)
                .foregroundColor(AppColors.textSecondary)
            if impairmentQuestions.isEmpty {
                ForEach(Array(47...52), id: \.self) { n in
                    yesNoRow(key: "trauma.q\(n)", label: String(format: LocalizedString("trauma_function_question", lang), n))
                }
            } else {
                ForEach(impairmentQuestions, id: \.code) { question in
                    traumaQuestionRow(question)
                }
            }
        }
        .padding()
        .background(AppColors.secondarySurface)
        .cornerRadius(12)
        .padding(.horizontal)
    }

    private func yesNoRow(key: String, label: String, helpText: String? = nil) -> some View {
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
        return VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(AppColors.textPrimary)
            if let helpText, !helpText.isEmpty {
                Text(helpText)
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
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

    private func defaultSymptomRow(q: Int) -> some View {
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
            Text("Q\(q)")
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

    private func traumaQuestionRow(_ question: LogicTraumaQuestion) -> some View {
        let key = "trauma.\(question.code)"
        switch question.questionType {
        case .boolean:
            return AnyView(yesNoRow(key: key, label: question.label, helpText: question.helpText))
        case .text:
            return AnyView(textRow(key: key, label: question.label, helpText: question.helpText))
        case .scale:
            let minVal = question.scaleMin ?? 0
            let maxVal = question.scaleMax ?? 3
            return AnyView(scaleRow(key: key, label: question.label, range: minVal...maxVal, helpText: question.helpText))
        }
    }

    private func scaleRow(key: String, label: String, range: ClosedRange<Int>, helpText: String? = nil) -> some View {
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
        return VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption)
                .foregroundColor(AppColors.textPrimary)
            if let helpText, !helpText.isEmpty {
                Text(helpText)
                    .font(.caption2)
                    .foregroundColor(AppColors.textSecondary)
            }
            HStack {
                ForEach(Array(range), id: \.self) { value in
                    let isSelected = binding.wrappedValue == value
                    Button(action: {
                        binding.wrappedValue = isSelected ? nil : value
                    }) {
                        Text("\(value)")
                            .font(.caption2)
                            .fontWeight(isSelected ? .semibold : .regular)
                            .foregroundColor(isSelected ? AppColors.onPrimary : AppColors.textPrimary)
                            .frame(width: 32, height: 28)
                            .background(isSelected ? AppColors.primary : AppColors.mainSurface)
                            .cornerRadius(6)
                    }
                }
            }
            if missingKeys.contains(key) {
                Text("Required")
                    .font(.caption2)
                    .foregroundColor(AppColors.danger)
            }
        }
        .padding(.vertical, 4)
    }

    private func textRow(key: String, label: String, helpText: String? = nil) -> some View {
        let binding: Binding<String> = Binding(
            get: { answers[key]?.value as? String ?? "" },
            set: { newValue in
                if newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    answers.removeValue(forKey: key)
                } else {
                    answers[key] = AnyCodable(newValue)
                }
            }
        )
        return VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(AppColors.textPrimary)
            if let helpText, !helpText.isEmpty {
                Text(helpText)
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            TextField("", text: binding)
                .textFieldStyle(.roundedBorder)
            if missingKeys.contains(key) {
                Text("Required")
                    .font(.caption2)
                    .foregroundColor(AppColors.danger)
            }
        }
        .padding(.vertical, 2)
    }

    private var baseEventQuestions: [LogicTraumaQuestion] {
        logicStore.traumaQuestions(for: "EVENTS")
    }

    private var parentEventQuestions: [LogicTraumaQuestion] {
        logicStore.traumaQuestions(for: "EVENTS_PARENT")
    }

    private var adultEventFlags: [LogicTraumaQuestion] {
        logicStore.traumaQuestions(for: "EVENTS_ADULT")
    }

    private var childEventFlags: [LogicTraumaQuestion] {
        logicStore.traumaQuestions(for: "EVENTS_CHILD")
    }

    private var symptomQuestions: [LogicTraumaQuestion] {
        let groupPrefixes = ["SYMPTOMS_B", "SYMPTOMS_C", "SYMPTOMS_D", "SYMPTOMS_E"]
        return groupPrefixes.flatMap { logicStore.traumaQuestions(for: $0) }
    }

    private var impairmentQuestions: [LogicTraumaQuestion] {
        logicStore.traumaQuestions(for: "FUNCTION")
    }
}
