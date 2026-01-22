//
//  CategoryTag.swift
//  UpNews-iOS
//
//  Created by Valentin Colombat on 21/01/2026.
//
import SwiftUI

struct CategoryTagView: View {
    let article: Article
    
    var body: some View {
        HStack {
            Image(systemName: article.categoryIcon)
                .font(.caption)
            Text(article.category.capitalized)
                .font(.system(size: 13, weight:  .semibold))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(article.categoryColor.opacity(0.6))
        .foregroundColor(.black)
        .cornerRadius(8)
    }
}
