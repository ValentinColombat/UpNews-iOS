//
//  WidgetDataManager.swift
//  UpNews-iOS
//
//  Gestionnaire de synchronisation des données pour le widget

import Foundation
import WidgetKit

class WidgetDataManager {
    
    static let shared = WidgetDataManager()
    
    private let sharedDefaults = UserDefaults(suiteName: "group.com.upnews.shared")
    
    private init() {}
    
    // MARK: - Update Widget Data
    
    /// Met à jour toutes les données du widget
    func updateWidgetData(
        companionName: String,
        companionImage: String,
        currentStreak: Int,
        hasReadToday: Bool,
        articlesCount: Int
    ) {
        sharedDefaults?.set(companionName, forKey: "selectedCompanionName")
        sharedDefaults?.set(companionImage, forKey: "selectedCompanionImage")
        sharedDefaults?.set(currentStreak, forKey: "currentStreak")
        sharedDefaults?.set(hasReadToday, forKey: "hasReadToday")
        sharedDefaults?.set(articlesCount, forKey: "articlesCount")
        sharedDefaults?.set(Date(), forKey: "lastUpdate")
        
        // Rafraîchir tous les widgets
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    // MARK: - Individual Updates
    
    func updateCompanion(name: String, image: String) {
        sharedDefaults?.set(name, forKey: "selectedCompanionName")
        sharedDefaults?.set(image, forKey: "selectedCompanionImage")
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    func updateStreak(_ streak: Int) {
        sharedDefaults?.set(streak, forKey: "currentStreak")
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    func updateReadStatus(_ hasRead: Bool) {
        sharedDefaults?.set(hasRead, forKey: "hasReadToday")
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    func updateArticlesCount(_ count: Int) {
        sharedDefaults?.set(count, forKey: "articlesCount")
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    // MARK: - Get Widget Data
    
    func getWidgetData() -> (companionName: String, companionImage: String, streak: Int, hasRead: Bool, articlesCount: Int) {
        let name = sharedDefaults?.string(forKey: "selectedCompanionName") ?? "Mousse"
        let image = sharedDefaults?.string(forKey: "selectedCompanionImage") ?? "mousse"
        let streak = sharedDefaults?.integer(forKey: "currentStreak") ?? 0
        let hasRead = sharedDefaults?.bool(forKey: "hasReadToday") ?? false
        let count = sharedDefaults?.integer(forKey: "articlesCount") ?? 0
        
        return (name, image, streak, hasRead, count)
    }
}
