//
//  FAQView.swift
//  Ledstjarnan
//

import SwiftUI

struct FAQView: View {
    private let categories = FAQCategory.sampleData
    
    var body: some View {
        List {
            ForEach(categories) { category in
                NavigationLink(destination: FAQCategoryDetailView(category: category)) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(category.title)
                            .font(.headline)
                        Text(category.subtitle)
                            .font(.subheadline)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .listStyle(.insetGrouped)
        .background(AppColors.background)
        .navigationTitle("FAQs")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FAQCategoryDetailView: View {
    let category: FAQCategory
    
    var body: some View {
        List {
            ForEach(category.articles) { article in
                NavigationLink(destination: FAQArticleDetailView(article: article)) {
                    Text(article.question)
                        .foregroundColor(AppColors.textPrimary)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(category.title)
    }
}

struct FAQArticleDetailView: View {
    let article: FAQArticle
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(article.question)
                    .font(.title3.weight(.semibold))
                Text(article.answer)
                    .font(.body)
                    .foregroundColor(AppColors.textPrimary)
                Text("Last updated \(article.lastUpdated.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            .padding()
        }
        .background(AppColors.background)
        .navigationTitle("Answer")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FAQCategory: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let articles: [FAQArticle]
    
    static let sampleData: [FAQCategory] = [
        FAQCategory(
            title: "Account & access",
            subtitle: "Login, onboarding, unit access",
            articles: [
                FAQArticle(question: "How do I join a new unit?", answer: "Open Settings → Change unit and enter the 6-digit code provided by your admin. Your previous unit will be archived.", lastUpdated: Date()),
                FAQArticle(question: "Can I remove a staff member?", answer: "Only unit admins can remove staff via Supabase Auth. Contact support if you need help removing access.", lastUpdated: Date())
            ]
        ),
        FAQCategory(
            title: "Clients & assessments",
            subtitle: "Baseline, follow-up, plans",
            articles: [
                FAQArticle(question: "Where do I see drafts?", answer: "Open the Assess tab. Drafts are listed under each client context and can be resumed from the Baseline or Follow-up buttons.", lastUpdated: Date()),
                FAQArticle(question: "What if a client leaves the unit?", answer: "Archive the plan and unlink the Livbojen account. The client record remains for reporting but will be read-only.", lastUpdated: Date())
            ]
        ),
        FAQCategory(
            title: "Livbojen",
            subtitle: "Linking codes and progress",
            articles: [
                FAQArticle(question: "How long are linking codes valid?", answer: "Every code is valid for 15 minutes. If the youth doesn't enter it in time, generate a fresh code from the client profile.", lastUpdated: Date())
            ]
        )
    ]
}

struct FAQArticle: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
    let lastUpdated: Date
}
