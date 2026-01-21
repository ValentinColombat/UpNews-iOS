//
//  StreakService.swift
//  UpNews-iOS
//
//  Created by Valentin Colombat on 20/01/2026.
//
import Foundation
import Supabase

/// Service pour gérer le streak de connexion
class StreakService {
    
    // MARK: - Singleton
    
    static let shared = StreakService()
    
    private let client: SupabaseClient
    private let dateFormatter: DateFormatter
    
    // MARK: - Initialisation
    
    private init() {
        self.client = SupabaseConfig.client
        
        self.dateFormatter = DateFormatter()
        self.dateFormatter.dateFormat = "yyyy-MM-dd"
    }
    
    // MARK: - Mise à jour du Streak

    /// Met à jour le streak de l'utilisateur connecté
    @MainActor
    func updateStreak() async throws -> Int {
        let session = try await client.auth.session
        let userId = session.user.id.uuidString
        let today = dateFormatter.string(from: Date())
        
        // Récupérer les données actuelles
        struct UserStreak: Decodable {
            let current_streak: Int
            let last_connection_date: String?
        }
        
        let response = try await client
            .from("users")
            .select("current_streak, last_connection_date")
            .eq("id", value: userId)
            .execute()  // 
        
        //  Décoder comme un tableau
        let users = try JSONDecoder().decode([UserStreak].self, from: response.data)
        
        //  Vérifier qu'on a bien un résultat
        guard let userData = users.first else {
            throw NSError(domain: "StreakService", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Données utilisateur introuvables"])
        }
        
        // Calculer la nouvelle streak
        let newStreak = calculateNewStreak(
            currentStreak: userData.current_streak,
            lastConnectionDate: userData.last_connection_date,
            today: today
        )
        
        // Créer une struct Encodable
        struct UpdateStreak: Encodable {
            let current_streak: Int
            let last_connection_date: String
        }
        
        let updateData = UpdateStreak(
            current_streak: newStreak,
            last_connection_date: today
        )
        
        // Mettre à jour dans Supabase
        try await client
            .from("users")
            .update(updateData)
            .eq("id", value: userId)
            .execute()
        return newStreak
    }
    
    // MARK: - Calcul du Streak
    
    private func calculateNewStreak(currentStreak: Int, lastConnectionDate: String?, today: String) -> Int {
        guard let lastDate = lastConnectionDate else {
            // Première connexion
            print(" Première connexion !  Streak = 1")
            return 1
        }
        
        // Si déjà connecté aujourd'hui
        if lastDate == today {
            print(" Déjà connecté aujourd'hui, streak = \(currentStreak)")
            return currentStreak
        }
        
        // Calculer la différence de jours
        guard let last = dateFormatter.date(from: lastDate),
              let current = dateFormatter.date(from: today) else {
            print(" Erreur de parsing de date, reset streak")
            return 1
        }
        
        let daysDifference = Calendar.current.dateComponents([.day], from: last, to: current).day ?? 0
        
        switch daysDifference {
        case 1:
            // Connexion hier → Incrémenter
            let newStreak = currentStreak + 1
            print(" Streak prolongé !  \(currentStreak) → \(newStreak)")
            return newStreak
            
        case 0:
            // Même jour (normalement déjà géré)
            print(" Même jour, streak = \(currentStreak)")
            return currentStreak
            
        default:
            // Plus de 1 jour → Reset
            print(" Streak perdu ! Reset à 1 (dernier :  \(lastDate), aujourd'hui : \(today))")
            return 1
        }
    }
}
