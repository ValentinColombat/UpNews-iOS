//
//  LibraryView.swift
//  UpNews-iOS

import SwiftUI
import Supabase
import Auth

struct LibraryView: View {
    
    // MARK: - State
    
    @State private var articles: [Article] = []
    @State private var selectedCategory: CategoryFilter = .all
    @State private var selectedDateRange: DateRangeFilter = .all
    @State private var likedArticles: Set<UUID> = [] // Track des articles likés
    @State private var showOnlyLiked: Bool = false // Filtre articles likés
    @State private var isLoading = true // État de chargement
    
    enum CategoryFilter: String, CaseIterable {
        case all = "Tous"
        case ecology = "Écologie"
        case technology = "Tech"
        case science = "Science"
        case culture = "Culture"
        case social = "Social"
        case health = "Santé" // ✅ AJOUT
        
        var icon: String {
            switch self {
            case .all: return "list.bullet"
            case .ecology: return "leaf.fill"
            case .technology: return "lightbulb.fill"
            case .science: return "flask.fill"
            case .culture: return "paintpalette.fill"
            case .social: return "person.3.fill"
            case .health: return "cross.case.fill" // ✅ AJOUT
            }
        }
        
        var categoryKey: String? {
            switch self {
            case .all: return nil
            case .ecology: return "ecologie" // ✅ CHANGÉ (sans accent)
            case .technology: return "tech" // ✅ CHANGÉ
            case .science: return "science"
            case .culture: return "culture"
            case .social: return "social"
            case .health: return "santé" // ✅ AJOUT
            }
        }
        
        var color: Color {
            switch self {
            case .all: return .gray
            case .ecology: return .upNewsGreen
            case .technology: return .upNewsOrange
            case .science: return .upNewsBlueMid
            case .culture: return .purple
            case .social: return .upNewsBlueLight
            case .health: return .red // ✅ AJOUT
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
                
                if isLoading {
                    // Indicateur de chargement
                    LoadingView()
                            
                } else {
                    VStack(spacing: 0) {
                        // Header
                        headerSection
                        
                        // Filtres
                        filterSection
                        
                        // Bouton articles likés
                        likedArticlesButton
                        
                        // Liste articles
                        if filteredArticles.isEmpty {
                            emptyStateView
                        } else {
                            ScrollView {
                                LazyVStack(spacing: 12) {
                                    ForEach(filteredArticles) { article in
                                        NavigationLink(destination: ArticleDetailView(article: article)) {
                                            articleCard(article)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.top, 16)
                                .padding(.bottom, 100)
                            }
                        }
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .task {
            await loadArticlesFromSupabase()
        }
        .refreshable {
            await loadArticlesFromSupabase()
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
            
            Text("\(filteredArticles.count) article\(filteredArticles.count > 1 ? "s" : "")")
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
                Text(showOnlyLiked ? "Voir tous les articles" : "Voir uniquement mes articles favoris")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                LinearGradient(
                    colors: showOnlyLiked
                        ? [Color.upNewsBlueMid, Color.upNewsBlueMid.opacity(0.6)]
                        : [Color.upNewsOrange, Color.upNewsOrange.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
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
                                Text(category.rawValue)
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
        .padding(.bottom, 20)
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: showOnlyLiked ? "book.pages" : "tray")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            
            Text(showOnlyLiked ? "Aucun article préféré" : "Aucun article disponible")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.upNewsBlack)
            
            Text(showOnlyLiked
                 ? "Marque des articles en favoris pour les retrouver ici"
                 : "Ils arrivent bientôt !")
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxHeight: .infinity)
        .padding(.top, 100)
    }
    
    // MARK: - Article Card
    
    private func articleCard(_ article: Article) -> some View {
        ZStack(alignment: .topTrailing) {
            // Card principale
            HStack(spacing: 12) {
                // Badge catégorie
                Image(systemName: article.categoryIcon)
                        
                .font(. caption)
                .foregroundColor(.black)
                .frame(width: 40, height: 40)
                .background(article.categoryColor.opacity(0.6))
                .cornerRadius(8)
                
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
            
            // Bouton cœur (like/unlike) - indépendant
            Button {
                Task {
                    await toggleLike(for: article.id)
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
    
    // MARK: - Supabase Integration
    
    /// Charge tous les articles depuis Supabase
    private func loadArticlesFromSupabase() async {
        isLoading = true
        
        do {
            // Récupérer tous les articles
            let response = try await SupabaseConfig.client
                .from("articles")
                .select()
                .order("published_date", ascending: false)
                .execute()
            
            let fetchedArticles = try JSONDecoder().decode([Article].self, from: response.data)
            articles = fetchedArticles
            
            // Charger les articles likés de l'utilisateur
            await loadLikedArticles()
            
            print("\(articles.count) articles chargés depuis Supabase")
        } catch {
            print(" Erreur chargement articles: \(error)")
        }
        
        isLoading = false
    }
    
    /// Charge les articles likés (favoris) de l'utilisateur
    private func loadLikedArticles() async {
        do {
            let session = try await SupabaseConfig.client.auth.session
            
            let response = try await SupabaseConfig.client
                .from("user_article_interactions")
                .select("article_id")
                .eq("user_id", value: session.user.id.uuidString)
                .eq("is_favorite", value: true)
                .execute()
            
            struct FavoriteArticle: Decodable {
                let article_id: String
            }
            
            let favorites = try JSONDecoder().decode([FavoriteArticle].self, from: response.data)
            
            likedArticles = Set(favorites.compactMap { UUID(uuidString: $0.article_id) })
            
            print(" \(likedArticles.count) articles favoris chargés")
        } catch {
            print(" Erreur chargement favoris: \(error)")
        }
    }
    
    /// Toggle like/unlike d'un article
    private func toggleLike(for articleId: UUID) async {
        let wasLiked = likedArticles.contains(articleId)
        
        // Mise à jour optimiste de l'UI
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            if wasLiked {
                likedArticles.remove(articleId)
            } else {
                likedArticles.insert(articleId)
            }
        }
        
        // Mise à jour en base
        do {
            let session = try await SupabaseConfig.client.auth.session
            
            // Vérifier si une interaction existe
            let checkResponse = try await SupabaseConfig.client
                .from("user_article_interactions")
                .select("id")
                .eq("user_id", value: session.user.id.uuidString)
                .eq("article_id", value: articleId.uuidString)
                .execute()
            
            struct ExistingInteraction: Decodable {
                let id: String
            }
            
            let existing = try JSONDecoder().decode([ExistingInteraction].self, from: checkResponse.data)
            
            if existing.isEmpty {
                // Créer une nouvelle interaction
                struct NewInteraction: Encodable {
                    let user_id: String
                    let article_id: String
                    let is_favorite: Bool
                }
                
                let interaction = NewInteraction(
                    user_id: session.user.id.uuidString,
                    article_id: articleId.uuidString,
                    is_favorite: !wasLiked
                )
                
                try await SupabaseConfig.client
                    .from("user_article_interactions")
                    .insert(interaction)
                    .execute()
            } else {
                // Mettre à jour l'interaction existante
                struct UpdateFavorite: Encodable {
                    let is_favorite: Bool
                }
                
                let update = UpdateFavorite(is_favorite: !wasLiked)
                
                try await SupabaseConfig.client
                    .from("user_article_interactions")
                    .update(update)
                    .eq("user_id", value: session.user.id.uuidString)
                    .eq("article_id", value: articleId.uuidString)
                    .execute()
            }
            
            print(" Favori mis à jour: \(!wasLiked)")
        } catch {
            print(" Erreur toggle favori: \(error)")
            
            // Rollback en cas d'erreur
            withAnimation {
                if wasLiked {
                    likedArticles.insert(articleId)
                } else {
                    likedArticles.remove(articleId)
                }
            }
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
           
            result = result.filter { article in
                return article.category == categoryKey // ✅ Match exact
            }
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
    
    // MARK: - Helper Functions
    
    private func parseDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateString)
    }
    
    private func formatDateFR(_ dateString: String) -> String {
        guard let date = parseDate(dateString) else { return dateString }
        
        let calendar = Calendar.current
        let now = Date()
        
        // Si c'est aujourd'hui
        if calendar.isDateInToday(date) {
            return "Aujourd'hui"
        }
        
        // Si c'est hier
        if calendar.isDateInYesterday(date) {
            return "Hier"
        }
        
        // Si c'est dans les 7 derniers jours
        let daysAgo = calendar.dateComponents([.day], from: date, to: now).day ?? 0
        if daysAgo <= 7 {
            return "Il y a \(daysAgo) jour\(daysAgo > 1 ? "s" : "")"
        }
        
        // Sinon format complet
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "d MMMM" // Ex: "15 janvier"
        
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview {
    LibraryView()
}
