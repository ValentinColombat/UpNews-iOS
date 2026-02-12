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
            id: "santé",
            name: "Santé",
            icon: "cross.case.fill",
            color: .categoryHealth,
            description: "Bien-être et avancées médicales"
        ),
        CategoryItem(
            id: "sciences-et-tech",
            name: "Sciences & Tech",
            icon: "flask.fill",
            color: .categoryTech,
            description: "Découvertes scientifiques et innovations tech"
        ),
        CategoryItem(
            id: "social-et-culture",
            name: "Social & Culture",
            icon: "theatermasks.fill",
            color: .categoryCulture,
            description: "Solidarité, arts et patrimoine"
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
            id: "santé",
            name: "Santé",
            icon: "cross.case.fill",
            color: .categoryHealth,
            description: "Bien-être"
        ),
        CategoryItem(
            id: "sciences-et-tech",
            name: "Sciences & Tech",
            icon: "flask.fill",
            color: .categoryTech,
            description: "Découvertes & innovations"
        ),
        CategoryItem(
            id: "social-et-culture",
            name: "Social & Culture",
            icon: "theatermasks.fill",
            color: .categoryCulture,
            description: "Solidarité & arts"
        )
    ]
}
