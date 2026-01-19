//
//  LibraryView.swift
//  UpNews-iOS

import SwiftUI

struct LibraryView: View {
    
    // MARK: - State
    
    @State private var articles: [Article] = []
    @State private var selectedCategory: CategoryFilter = .all
    @State private var selectedDateRange: DateRangeFilter = .all
    @State private var likedArticles: Set<UUID> = [] // Track des articles likés
    @State private var showOnlyLiked: Bool = false // Filtre articles likés
    
    enum CategoryFilter: String, CaseIterable {
        case all = "Tous"
        case ecology = "Écologie"
        case technology = "Tech"
        case science = "Science"
        case culture = "Culture"
        case social = "Social"
        
        var icon: String {
            switch self {
            case .all: return ""
            case .ecology: return "🌳"
            case .technology: return "💡"
            case .science: return "🔬"
            case .culture: return "🎨"
            case .social: return "🏛️"
            }
        }
        
        var categoryKey: String? {
            switch self {
            case .all: return nil
            case .ecology: return "ecology"
            case .technology: return "technology"
            case .science: return "science"
            case .culture: return "culture"
            case .social: return "social"
            }
        }
    }
    
    enum DateRangeFilter: String, CaseIterable {
        case all = "Tous"
        case today = "Aujourd'hui"
        case last7days = "7 derniers jours"
        case thisMonth = "Ce mois"
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.upNewsBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    headerSection
                    
                    // Filtres
                    filterSection
                    
                    // Bouton articles likés
                    likedArticlesButton
                    
                    // Liste articles
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredArticles) { article in
                                articleCard(article)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            loadMockData()
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack {
            Text("Bibliothèque")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.upNewsBlack)
                .fixedSize()
            
            Spacer()
            
            Text("\(articles.count) article\(articles.count > 1 ? "s" : "")")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 26)
        .padding(.top, 20)
        .padding(.bottom, 16)
        .background(Color.upNewsBackground)
    }
    
    // MARK: - Liked Articles Button
    
    private var likedArticlesButton: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                showOnlyLiked.toggle()
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: showOnlyLiked ? "book.pages.fill" : "book.pages")
                    .font(.system(size: 14))
                Text("Voir uniquement mes articles préférés")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                AnyView(
                    LinearGradient(
                        colors: [Color.upNewsOrange,
                                 Color.upNewsOrange.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                    )
                )
            )
            .cornerRadius(20)
            .shadow(radius: 1, x: 0, y: 1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.bottom, 10)
    }
    
    // MARK: - Filter Section
    
    private var filterSection: some View {
        HStack(spacing: 12) {
            // Menu Trier par date (pleine largeur)
            VStack(alignment: .leading, spacing: 6) {
                Text("Trier par date")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 10)
                
                Menu {
                    ForEach(DateRangeFilter.allCases, id: \.self) { dateRange in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedDateRange = dateRange
                            }
                        } label: {
                            HStack {
                                Text(dateRange.rawValue)
                                if selectedDateRange == dateRange {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.upNewsBlueMid)
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.system(size: 14))
                        Text(selectedDateRange.rawValue)
                            .font(.system(size: 14, weight: .semibold))
                            .lineLimit(1)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.upNewsBlack)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(radius: 1, x: 0, y: 1)
                }
            }
            
            // Menu Trier par catégorie (pleine largeur)
            VStack(alignment: .leading, spacing: 6) {
                Text("Trier par catégorie")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Menu {
                    ForEach(CategoryFilter.allCases, id: \.self) { category in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedCategory = category
                            }
                        } label: {
                            HStack {
                                Text("\(category.icon) \(category.rawValue)")
                                if selectedCategory == category {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.upNewsPrimary)
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "tag")
                            .font(.system(size: 14))
                        Text(selectedCategory.rawValue)
                            .font(.system(size: 14, weight: .semibold))
                            .lineLimit(1)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.upNewsBlack)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(radius: 1, x: 0, y: 1)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 10)
    }
    
    // MARK: - Article Card
    
    private func articleCard(_ article: Article) -> some View {
        ZStack(alignment: .topTrailing) {
            // Card principale (cliquable pour ouvrir l'article)
            Button {
                // Action tap article
            } label: {
                HStack(spacing: 12) {
                    // Badge catégorie
                    VStack {
                        Image(systemName: article.categoryIcon)
                            .font(.system(size: 18))
                            .foregroundColor(article.categoryColor)
                    }
                    .frame(width: 50, height: 50)
                    .background(article.categoryColor.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Contenu
                    VStack(alignment: .leading, spacing: 6) {
                        Text(article.category.capitalized)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Text(article.title)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.upNewsBlack)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        
                        Text(formatDateFR(article.publishedDate))
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    // Chevron
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                .padding(16)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(radius: 1, x: 0, y: 2)
            }
            .buttonStyle(.plain)
            
            // Bouton cœur (like/unlike) - indépendant
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    toggleLike(for: article.id)
                }
            } label: {
                Image(systemName: likedArticles.contains(article.id) ? "book.pages.fill" : "book.pages")
                    .font(.system(size: 18))
                    .foregroundColor(likedArticles.contains(article.id) ? .upNewsOrange.opacity(0.8) : .gray)
                    .padding(12)
                    .scaleEffect(likedArticles.contains(article.id) ? 1.1 : 1.0)
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Actions
    
    private func toggleLike(for articleId: UUID) {
        if likedArticles.contains(articleId) {
            likedArticles.remove(articleId)
        } else {
            likedArticles.insert(articleId)
        }
    }
    
    // MARK: - Computed Properties
    
    private var filteredArticles: [Article] {
        var result = articles
        
        // Filtre articles likés (prioritaire)
        if showOnlyLiked {
            result = result.filter { likedArticles.contains($0.id) }
        }
        
        // Filtre par catégorie
        if let categoryKey = selectedCategory.categoryKey {
            result = result.filter { $0.category == categoryKey }
        }
        
        // Filtre par date
        let calendar = Calendar.current
        let now = Date()
        
        switch selectedDateRange {
        case .all:
            break
        case .today:
            result = result.filter { article in
                guard let articleDate = parseDate(article.publishedDate) else { return false }
                return calendar.isDateInToday(articleDate)
            }
        case .last7days:
            result = result.filter { article in
                guard let articleDate = parseDate(article.publishedDate) else { return false }
                let daysAgo = calendar.dateComponents([.day], from: articleDate, to: now).day ?? 0
                return daysAgo <= 7
            }
        case .thisMonth:
            result = result.filter { article in
                guard let articleDate = parseDate(article.publishedDate) else { return false }
                return calendar.isDate(articleDate, equalTo: now, toGranularity: .month)
            }
        }
        
        // Tri par date (du plus récent au plus ancien)
        result.sort { article1, article2 in
            guard let date1 = parseDate(article1.publishedDate),
                  let date2 = parseDate(article2.publishedDate) else {
                return false
            }
            return date1 > date2
        }
        
        return result
    }
    
    private func parseDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateString)
    }
    
    private func formatDateFR(_ dateString: String) -> String {
        guard let date = parseDate(dateString) else { return dateString }
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "d MMMM" // Ex: "15 janvier"
        
        return formatter.string(from: date)
    }
    
    // MARK: - Mock Data
    
    private func loadMockData() {
        let calendar = Calendar.current
        let today = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        // Aujourd'hui
        let todayString = formatter.string(from: today)
        
        // Il y a 3 jours
        let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: today)!
        let threeDaysAgoString = formatter.string(from: threeDaysAgo)
        
        // Il y a 5 jours
        let fiveDaysAgo = calendar.date(byAdding: .day, value: -5, to: today)!
        let fiveDaysAgoString = formatter.string(from: fiveDaysAgo)
        
        // Il y a 10 jours
        let tenDaysAgo = calendar.date(byAdding: .day, value: -10, to: today)!
        let tenDaysAgoString = formatter.string(from: tenDaysAgo)
        
        articles = [
            Article(
                id: UUID(),
                publishedDate: todayString,
                language: "fr",
                title: "Des forêts urbaines fleurissent dans 50 villes européennes",
                summary: "Initiative collaborative",
                content: "",
                category: "ecology",
                imageUrl: nil,
                sourceUrl: nil,
                createdAt: ""
            ),
            Article(
                id: UUID(),
                publishedDate: todayString,
                language: "fr",
                title: "Batterie solaire recyclable à 99%",
                summary: "Innovation majeure",
                content: "",
                category: "technology",
                imageUrl: nil,
                sourceUrl: nil,
                createdAt: ""
            ),
            Article(
                id: UUID(),
                publishedDate: threeDaysAgoString,
                language: "fr",
                title: "Les abeilles sauvages reviennent dans nos jardins",
                summary: "Augmentation de 40%",
                content: "",
                category: "ecology",
                imageUrl: nil,
                sourceUrl: nil,
                createdAt: ""
            ),
            Article(
                id: UUID(),
                publishedDate: threeDaysAgoString,
                language: "fr",
                title: "Découverte d'un nouveau traitement contre le cancer",
                summary: "Avancée médicale",
                content: "",
                category: "science",
                imageUrl: nil,
                sourceUrl: nil,
                createdAt: ""
            ),
            Article(
                id: UUID(),
                publishedDate: fiveDaysAgoString,
                language: "fr",
                title: "Les coraux se régénèrent plus vite que prévu",
                summary: "Découverte encourageante",
                content: "",
                category: "science",
                imageUrl: nil,
                sourceUrl: nil,
                createdAt: ""
            ),
            Article(
                id: UUID(),
                publishedDate: fiveDaysAgoString,
                language: "fr",
                title: "Un musée gratuit pour tous les enfants",
                summary: "Initiative culturelle",
                content: "",
                category: "culture",
                imageUrl: nil,
                sourceUrl: nil,
                createdAt: ""
            ),
            Article(
                id: UUID(),
                publishedDate: tenDaysAgoString,
                language: "fr",
                title: "Un nouveau parc national en Amazonie",
                summary: "Protection biodiversité",
                content: "",
                category: "ecology",
                imageUrl: nil,
                sourceUrl: nil,
                createdAt: ""
            ),
            Article(
                id: UUID(),
                publishedDate: tenDaysAgoString,
                language: "fr",
                title: "Programme d'éducation gratuite dans 100 villages",
                summary: "Impact social",
                content: "",
                category: "social",
                imageUrl: nil,
                sourceUrl: nil,
                createdAt: ""
            )
        ]
    }
}

// MARK: - Preview

#Preview {
    LibraryView()
}
