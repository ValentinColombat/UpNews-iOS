//
//  ShareArticle.swift
//  UpNews-iOS
//
//  Created by Valentin Colombat on 26/01/2026.
//
import SwiftUI


// MARK: - Bouton Natif iOS
struct ShareArticle: View {
    let article: Article
    
    var body: some View {
        ShareLink(
            item: URL(string: article.sourceUrl ?? "https://upnews.app")!,
            subject: Text("📰 \(article.title)"),
            message: Text(article.summary)
        ) {
            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 18))
                .foregroundColor(.gray)
        }
    }
}

// MARK: - Adaptation en Card pour garder le design global

struct ShareArticleEdit: View {
    let article: Article
    
    var body: some View {
        ShareLink(
            item: URL(string: article.sourceUrl ?? "https://upnews.app")!,
            subject: Text("📰 \(article.title)"),
            message: Text(article.summary)
        ) {
            VStack(spacing: 8) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 20))
                    .foregroundColor(.upNewsBlack)
                
                Text("Partager")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.upNewsBlack)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.white)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
        }
    }
}

