//
//  AccountDeletionInfoView.swift
//  UpNews-iOS
//
//  Created on 03/02/2026.
//

import SwiftUI

/// Vue d'information sur la suppression de compte (recommandé par Apple)
struct AccountDeletionInfoView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.red)
                        
                        Text("Supprimer votre compte")
                            .font(.system(size: 24, weight: .bold))
                        
                        Text("Cette action est définitive et irréversible")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 20)
                    .padding(.bottom, 10)
                    
                    Divider()
                        .padding(.horizontal, 20)
                    
                    // Ce qui sera supprimé
                    VStack(alignment: .center, spacing: 16) {
                        Text("Données qui seront supprimées")
                            .font(.system(size: 18, weight: .bold))
                            .frame(maxWidth: .infinity, alignment: .center)
                        
                        VStack(alignment: .leading, spacing: 16) {
                            InfoItem(
                                icon: "person.fill",
                                title: "Profil utilisateur",
                                description: "Votre nom, email et préférences"
                            )
                            
                            InfoItem(
                                icon: "flame.fill",
                                title: "Progression",
                                description: "Votre série, XP et niveau"
                            )
                            
                            InfoItem(
                                icon: "book.fill",
                                title: "Historique de lecture",
                                description: "Tous vos articles lus et interactions"
                            )
                            
                            InfoItem(
                                icon: "star.fill",
                                title: "Préférences",
                                description: "Vos catégories et réglages personnalisés"
                            )
                        }
                        .frame(maxWidth: 500)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    .padding(.horizontal, 20)
                    
                    // Alternative
                    VStack(spacing: 12) {
                        Text("Vous hésitez ?")
                            .font(.system(size: 18, weight: .bold))
                            .frame(maxWidth: .infinity, alignment: .center)
                        
                        Text("Si vous souhaitez simplement faire une pause, vous pouvez :")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity, alignment: .center)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 12) {
                                Image(systemName: "bell.slash.fill")
                                    .foregroundColor(.upNewsGreen)
                                Text("Désactiver les notifications")
                                    .font(.system(size: 15))
                            }
                            
                            HStack(spacing: 12) {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .foregroundColor(.upNewsGreen)
                                Text("Simplement vous déconnecter")
                                    .font(.system(size: 15))
                            }
                        }
                        .frame(maxWidth: 500)
                    }
                    .padding()
                    .background(Color.upNewsGreen.opacity(0.1))
                    .cornerRadius(16)
                    .padding(.horizontal, 20)
                    
                    // Process
                    VStack(spacing: 12) {
                        Text("Comment supprimer votre compte ?")
                            .font(.system(size: 18, weight: .bold))
                            .frame(maxWidth: .infinity, alignment: .center)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            ProcessStep(
                                number: 1,
                                text: "Appuyez sur 'Supprimer mon compte' dans Réglages"
                            )
                            
                            ProcessStep(
                                number: 2,
                                text: "Confirmez votre décision"
                            )
                            
                            ProcessStep(
                                number: 3,
                                text: "Vos données seront supprimées immédiatement"
                            )
                        }
                        .frame(maxWidth: 500)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    .padding(.horizontal, 20)
                    
                    // Contact
                    VStack(spacing: 12) {
                        Text("Besoin d'aide ?")
                            .font(.system(size: 18, weight: .bold))
                            .frame(maxWidth: .infinity, alignment: .center)
                        
                        Text("Si vous rencontrez des problèmes ou avez des questions, contactez-nous à :")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Link("support@upnews.app", destination: URL(string: "mailto:support@upnews.app")!)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.upNewsGreen)
                    }
                    .padding()
                    .background(Color.upNewsLightPurple.opacity(0.1))
                    .cornerRadius(16)
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 40)
                }
                .frame(maxWidth: .infinity)
            }
            .navigationTitle("Suppression de compte")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Info Item Component

struct InfoItem: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.red)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Process Step Component

struct ProcessStep: View {
    let number: Int
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.upNewsGreen)
                    .frame(width: 28, height: 28)
                
                Text("\(number)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Text(text)
                .font(.system(size: 15))
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Preview

#Preview {
    AccountDeletionInfoView()
}
