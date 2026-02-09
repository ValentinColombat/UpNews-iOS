//
//  NotificationManager.swift
//  UpNews-iOS
//
//  Gestion des permissions et notifications locales quotidiennes

import Foundation
import UserNotifications

@MainActor
class NotificationManager {
    
    static let shared = NotificationManager()
    
    private init() {}
    
    // MARK: - Permission Status
    
    /// Vérifie si les notifications sont autorisées
    func checkAuthorizationStatus() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        return settings.authorizationStatus == .authorized
    }
    
    /// Demande la permission système (pop-up iOS)
    func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            
            return granted
        } catch {
            print("Erreur demande autorisation notifications: \(error)")
            return false
        }
    }
    
    // MARK: - Schedule Notification
    
    /// Programme une notification quotidienne à l'heure choisie
    func scheduleDailyNotification(at time: String) async {
        // Format attendu: "09:00"
        guard let (hour, minute) = parseTime(time) else {
            
            return
        }
        
        // Annuler les anciennes notifications
        cancelAllNotifications()
        
        // Créer le contenu
        let content = UNMutableNotificationContent()
        content.title = "Ta bonne nouvelle t'attend ! ☀️"
        content.body = "Découvre l'article du jour sur UpNews"
        content.sound = .default
        content.badge = 1
        
        // Créer le trigger (tous les jours à l'heure choisie)
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        // Créer la requête
        let request = UNNotificationRequest(
            identifier: "daily-article-notification",
            content: content,
            trigger: trigger
        )
        
        // Programmer
        let center = UNUserNotificationCenter.current()
        
        do {
            try await center.add(request)
           
        } catch {
            print("Erreur programmation notification quotidienne: \(error)")
        }
    }
    
    /// Annule toutes les notifications programmées
    func cancelAllNotifications() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        
    }
    
    // MARK: - Helpers
    
    /// Parse "09:00" -> (9, 0)
    private func parseTime(_ time: String) -> (hour: Int, minute: Int)? {
        let components = time.split(separator: ":").compactMap { Int($0) }
        guard components.count == 2 else { return nil }
        return (components[0], components[1])
    }
}
