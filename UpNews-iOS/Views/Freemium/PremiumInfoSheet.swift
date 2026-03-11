//
//  PremiumInfoSheet.swift
//  UpNews-iOS

import SwiftUI

struct PremiumInfoSheet: View {
    
    let onDismiss: () -> Void
    @State private var showContent = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissView()
                }
            
            VStack(spacing: 0) {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 8) {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.upNewsOrange)
                                
                                Text("Tu es Premium !")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.upNewsBlack)
                            }
                        }
                        
                        Spacer()
                        
                        Button {
                            dismissView()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.gray)
                                .padding(8)
                                .background(Circle().fill(Color.gray.opacity(0.1)))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    
                    // Features
                    VStack(spacing: 16) {
                        featureRow(
                            icon: "newspaper.fill",
                            color: .upNewsOrange,
                            title: "Articles illimités",
                            description: "Accès à tous les articles sans restriction"
                        )
                        
                        featureRow(
                            icon: "headphones",
                            color: .upNewsOrange,
                            title: "Audio haute qualité",
                            description: "Écoute intégrale de tous les articles"
                        )
                        
                        featureRow(
                            icon: "book.fill",
                            color: .upNewsOrange,
                            title: "Bibliothèque complète",
                            description: "Sauvegarde et consulte tous tes articles"
                        )
                        
                        featureRow(
                            icon: "pawprint.fill",
                            color: .upNewsOrange,
                            title: "Tous les compagnons",
                            description: "Accède à tous les compagnons"
                        )
                        
                        featureRow(
                            icon: "bolt.fill",
                            color: .upNewsOrange,
                            title: "XP bonus x2",
                            description: "Gagne 40 XP par article au lieu de 20"
                        )
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
                .background(
                    RoundedRectangle(cornerRadius: 28)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.15), radius: 20, y: 10)
                )
                .padding(.horizontal, 20)
                .scaleEffect(showContent ? 1 : 0.9)
                .opacity(showContent ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showContent = true
            }
        }
    }
    
    private func dismissView() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            showContent = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onDismiss()
        }
    }
    
    private func featureRow(icon: String, color: Color, title: String, description: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.upNewsBlack)
                
                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    PremiumInfoSheet(onDismiss: {})
}
