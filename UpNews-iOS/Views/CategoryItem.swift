//
//  CategoryItem.swift
//  UpNews-iOS
//
//  Created by Valentin Colombat on 31/01/2026.
//

import SwiftUI

/// Modèle pour représenter une catégorie d'articles
struct CategoryItem: Identifiable {
    let id: String
    let name: String
    let icon: String
    let color: Color
    let description: String
}

// MARK: - Categories Constants

extension CategoryItem {
    /// Liste de toutes les catégories disponibles
    static let allCategories: [CategoryItem] = [
        CategoryItem(
            id: "ecologie",
            name: "Écologie",
            icon: "leaf.fill",
            color: .categoryEcology,
            description: "Environnement, nature et biodiversité"
        ),
        CategoryItem(
            id: "tech",
            name: "Tech",
            icon: "cpu.fill",
            color: .categoryTech,
            description: "Innovations et nouvelles technologies"
        ),
        CategoryItem(
            id: "science",
            name: "Science",
            icon: "flask.fill",
            color: .categoryScience,
            description: "Découvertes et recherches scientifiques"
        ),
        CategoryItem(
            id: "culture",
            name: "Culture",
            icon: "theatermasks.fill",
            color: .categoryCulture,
            description: "Arts, spectacles et patrimoine"
        ),
        CategoryItem(
            id: "social",
            name: "Social",
            icon: "heart.fill",
            color: .categorySocial,
            description: "Solidarité et initiatives citoyennes"
        ),
        CategoryItem(
            id: "santé",
            name: "Santé",
            icon: "cross.case.fill",
            color: .categoryHealth,
            description: "Bien-être et avancées médicales"
        )
    ]
    
    /// Version compacte pour les descriptions courtes (utilisée dans ProfileView)
    static let allCategoriesCompact: [CategoryItem] = [
        CategoryItem(
            id: "ecologie",
            name: "Écologie",
            icon: "leaf.fill",
            color: .categoryEcology,
            description: "Environnement & nature"
        ),
        CategoryItem(
            id: "tech",
            name: "Tech",
            icon: "cpu.fill",
            color: .categoryTech,
            description: "Innovations"
        ),
        CategoryItem(
            id: "science",
            name: "Science",
            icon: "flask.fill",
            color: .categoryScience,
            description: "Découvertes"
        ),
        CategoryItem(
            id: "culture",
            name: "Culture",
            icon: "theatermasks.fill",
            color: .categoryCulture,
            description: "Arts & spectacles"
        ),
        CategoryItem(
            id: "social",
            name: "Social",
            icon: "heart.fill",
            color: .categorySocial,
            description: "Solidarité"
        ),
        CategoryItem(
            id: "santé",
            name: "Santé",
            icon: "cross.case.fill",
            color: .categoryHealth,
            description: "Bien-être"
        )
    ]
}
