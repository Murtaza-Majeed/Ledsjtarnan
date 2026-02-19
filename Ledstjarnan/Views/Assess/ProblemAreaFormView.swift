//
//  ProblemAreaFormView.swift
//  Ledstjarnan
//
//  Renders one problem domain (ExtendedDomain) with sections and extended question types.
//

import SwiftUI

struct ProblemAreaFormView: View {
    let domain: ExtendedDomain
    @Binding var answers: [String: AnyCodable]
    let missingKeys: Set<String>

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: domain.icon)
                    .foregroundColor(AppColors.primary)
                    .font(.title3)
                VStack(alignment: .leading, spacing: 2) {
                    Text(domain.title)
                        .font(.headline)
                        .foregroundColor(AppColors.textPrimary)
                    Text(domain.subtitle)
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                Spacer()
            }
            .padding(.horizontal)

            ForEach(domain.sections) { section in
                VStack(alignment: .leading, spacing: 12) {
                    Text(section.title)
                        .font(.subheadline.bold())
                        .foregroundColor(AppColors.textPrimary)
                    ForEach(section.questions) { q in
                        extendedQuestionView(domainKey: domain.key, question: q)
                    }
                }
                .padding()
                .background(AppColors.secondarySurface)
                .cornerRadius(12)
                .padding(.horizontal)
            }

            priorityPicker
        }
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private func extendedQuestionView(domainKey: String, question: ExtendedQuestion) -> some View {
        let key = "\(domainKey).\(question.key)"
        switch question.type {
        case .scale(let low, let high):
            scaleView(key: key, label: question.label, low: low, high: high)
        case .yesNo:
            yesNoView(key: key, label: question.label, isSafety: question.isSafetyQuestion)
        case .yesNoSpecify:
            yesNoSpecifyView(key: key, label: question.label)
        case .multipleChoice(let options):
            multipleChoiceView(key: key, label: question.label, options: options)
        case .multiSelect(let options):
            multiSelectView(key: key, label: question.label, options: options)
        case .text:
            textView(key: key, label: question.label)
        case .mScore:
            scaleView(key: key, label: question.label, low: 1, high: 5)
        case .pScore:
            pScoreView(key: key, label: question.label)
        }
    }

    private var priorityPicker: some View {
        let key = "\(domain.key).\(ProblemQuestionKeys.priority)"
        let binding: Binding<Int> = Binding(
            get: { answers[key]?.value as? Int ?? 2 },
            set: { newValue in
                answers[key] = AnyCodable(newValue)
            }
        )
        let options: [(String, Int)] = [("Hög", 1), ("Medel", 2), ("Låg", 3)]
        return VStack(alignment: .leading, spacing: 6) {
            Text("Prioritering")
                .font(.subheadline.bold())
                .foregroundColor(AppColors.textPrimary)
            Text("Styr behandlingsplanen för \(domain.title).")
                .font(.caption)
                .foregroundColor(AppColors.textSecondary)
            HStack(spacing: 8) {
                ForEach(options, id: \.1) { option in
                    let isSelected = binding.wrappedValue == option.1
                    Button {
                        binding.wrappedValue = option.1
                    } label: {
                        Text(option.0)
                            .font(.subheadline.weight(isSelected ? .semibold : .regular))
                            .foregroundColor(isSelected ? AppColors.onPrimary : AppColors.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(isSelected ? AppColors.primary : AppColors.mainSurface)
                            .cornerRadius(10)
                    }
                }
            }
        }
        .padding()
        .background(AppColors.secondarySurface)
        .cornerRadius(12)
        .padding(.horizontal)
    }

    private func scaleView(key: String, label: String, low: Int, high: Int) -> some View {
        let binding: Binding<Int?> = Binding(
            get: { answers[key]?.value as? Int },
            set: { newValue in
                setAnswer(newValue, for: key)
            }
        )
        let options = Array(low...high)
        return VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
            HStack(spacing: 8) {
                ForEach(options, id: \.self) { n in
                    let isSelected = binding.wrappedValue == n
                    Button(action: {
                        if isSelected {
                            binding.wrappedValue = nil
                        } else {
                            binding.wrappedValue = n
                        }
                    }) {
                        Text("\(n)")
                            .font(.subheadline)
                            .fontWeight(isSelected ? .semibold : .regular)
                            .foregroundColor(isSelected ? AppColors.onPrimary : AppColors.textPrimary)
                            .frame(width: 36, height: 36)
                            .background(isSelected ? AppColors.primary : AppColors.mainSurface)
                            .cornerRadius(8)
                    }
                }
            }
            if isMissing(key) {
                Text("Required")
                    .font(.caption2)
                    .foregroundColor(AppColors.danger)
            }
        }
    }

    private func yesNoView(key: String, label: String, isSafety: Bool) -> some View {
        let binding: Binding<Bool?> = Binding(
            get: { answers[key]?.value as? Bool },
            set: { newValue in
                setAnswer(newValue, for: key)
            }
        )
        let selection = binding.wrappedValue
        return VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(isSafety ? .red : AppColors.textSecondary)
            HStack(spacing: 12) {
                Button(action: {
                    binding.wrappedValue = (selection == true) ? nil : true
                }) {
                    Text("Ja")
                        .font(.subheadline)
                        .fontWeight(selection == true ? .semibold : .regular)
                        .foregroundColor(selection == true ? AppColors.onPrimary : AppColors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(selection == true ? AppColors.primary : AppColors.mainSurface)
                        .cornerRadius(8)
                }
                Button(action: {
                    binding.wrappedValue = (selection == false) ? nil : false
                }) {
                    Text("Nej")
                        .font(.subheadline)
                        .fontWeight(selection == false ? .semibold : .regular)
                        .foregroundColor(selection == false ? AppColors.onPrimary : AppColors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(selection == false ? AppColors.primary : AppColors.mainSurface)
                        .cornerRadius(8)
                }
            }
            if isMissing(key) {
                Text("Required")
                    .font(.caption2)
                    .foregroundColor(AppColors.danger)
            }
        }
    }

    private func yesNoSpecifyView(key: String, label: String) -> some View {
        let yesNoKey = key
        let specifyKey = "\(key)_specify"
        let yesNoBinding: Binding<Bool?> = Binding(
            get: { answers[yesNoKey]?.value as? Bool },
            set: { newValue in
                setAnswer(newValue, for: yesNoKey)
                if newValue != true {
                    answers.removeValue(forKey: specifyKey)
                }
            }
        )
        let specifyBinding: Binding<String> = Binding(
            get: { answers[specifyKey]?.value as? String ?? "" },
            set: { newValue in
                if newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    answers.removeValue(forKey: specifyKey)
                } else {
                    answers[specifyKey] = AnyCodable(newValue)
                }
            }
        )
        let selection = yesNoBinding.wrappedValue
        return VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
            HStack(spacing: 12) {
                Button(action: {
                    yesNoBinding.wrappedValue = (selection == true) ? nil : true
                }) {
                    Text("Ja")
                        .font(.subheadline)
                        .fontWeight(selection == true ? .semibold : .regular)
                        .foregroundColor(selection == true ? AppColors.onPrimary : AppColors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(selection == true ? AppColors.primary : AppColors.mainSurface)
                        .cornerRadius(8)
                }
                Button(action: {
                    yesNoBinding.wrappedValue = (selection == false) ? nil : false
                }) {
                    Text("Nej")
                        .font(.subheadline)
                        .fontWeight(selection == false ? .semibold : .regular)
                        .foregroundColor(selection == false ? AppColors.onPrimary : AppColors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(selection == false ? AppColors.primary : AppColors.mainSurface)
                        .cornerRadius(8)
                }
            }
            if yesNoBinding.wrappedValue == true {
                TextField("Beskriv (valfritt)", text: specifyBinding)
                    .textFieldStyle(.roundedBorder)
                    .font(.subheadline)
            }
            if isMissing(yesNoKey) {
                Text("Required")
                    .font(.caption2)
                    .foregroundColor(AppColors.danger)
            }
        }
    }

    private func multipleChoiceView(key: String, label: String, options: [String]) -> some View {
        let binding: Binding<String> = Binding(
            get: { answers[key]?.value as? String ?? "" },
            set: { newValue in
                if newValue.isEmpty {
                    answers.removeValue(forKey: key)
                } else {
                    answers[key] = AnyCodable(newValue)
                }
            }
        )
        return VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
            Picker("", selection: binding) {
                Text("—").tag("")
                ForEach(options, id: \.self) { opt in
                    Text(opt).tag(opt)
                }
            }
            .pickerStyle(.menu)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isMissing(key) ? AppColors.danger : .clear, lineWidth: 1)
            )
            if isMissing(key) {
                Text("Required")
                    .font(.caption2)
                    .foregroundColor(AppColors.danger)
            }
        }
    }

    private func multiSelectView(key: String, label: String, options: [String]) -> some View {
        let binding: Binding<[String]> = Binding(
            get: {
                if let v = answers[key]?.value as? [String] { return v }
                if let v = answers[key]?.value as? [Any] { return v.compactMap { $0 as? String } }
                return []
            },
            set: { newValue in
                if newValue.isEmpty {
                    answers.removeValue(forKey: key)
                } else {
                    answers[key] = AnyCodable(newValue)
                }
            }
        )
        return VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
            ForEach(options, id: \.self) { opt in
                let isOn = binding.wrappedValue.contains(opt)
                Button(action: {
                    var next = binding.wrappedValue
                    if isOn { next.removeAll { $0 == opt } }
                    else { next.append(opt) }
                    binding.wrappedValue = next.sorted()
                }) {
                    HStack {
                        Image(systemName: isOn ? "checkmark.square.fill" : "square")
                            .foregroundColor(isOn ? AppColors.primary : AppColors.textSecondary)
                        Text(opt)
                            .font(.subheadline)
                            .foregroundColor(AppColors.textPrimary)
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
            if isMissing(key) {
                Text("Required")
                    .font(.caption2)
                    .foregroundColor(AppColors.danger)
            }
        }
    }

    private func textView(key: String, label: String) -> some View {
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
                .foregroundColor(AppColors.textSecondary)
            TextField("", text: binding, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(2...4)
            if isMissing(key) {
                Text("Required")
                    .font(.caption2)
                    .foregroundColor(AppColors.danger)
            }
        }
    }

    private func pScoreView(key: String, label: String) -> some View {
        let options = ["Hög", "Medel", "Låg"]
        let binding: Binding<String> = Binding(
            get: { answers[key]?.value as? String ?? "" },
            set: { newValue in
                if newValue.isEmpty {
                    answers.removeValue(forKey: key)
                } else {
                    answers[key] = AnyCodable(newValue)
                }
            }
        )
        return VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
            Picker("", selection: binding) {
                Text("—").tag("")
                ForEach(options, id: \.self) { opt in
                    Text(opt).tag(opt)
                }
            }
            .pickerStyle(.segmented)
            if isMissing(key) {
                Text("Required")
                    .font(.caption2)
                    .foregroundColor(AppColors.danger)
            }
        }
    }

    private func setAnswer(_ value: Any?, for key: String) {
        if let value {
            answers[key] = AnyCodable(value)
        } else {
            answers.removeValue(forKey: key)
        }
    }

    private func isMissing(_ key: String) -> Bool {
        missingKeys.contains(key)
    }
}
