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
    
    /// Met à jour les données du widget
    func updateWidgetData(
        companionName: String,
        companionImage: String,
        currentStreak: Int,
        hasReadToday: Bool,
        articlesCount: Int
    ) {
        sharedDefaults?.set(hasReadToday, forKey: "hasReadToday")
        sharedDefaults?.set(Date(), forKey: "lastUpdate")
        
        WidgetCenter.shared.reloadAllTimelines()
    }
}
