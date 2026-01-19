import SwiftUI

extension Color {
    
    // MARK: - Palette principale UpNews
    
    /// Bleu clair pastel - Backgrounds doux
    static let upNewsBlueLight = Color(red: 195/255, green: 229/255, blue: 238/255)  // C3E5EE
    
    /// Noir - Tech primary
    static let upNewsBlack = Color(red: 0/255, green: 0/255, blue: 0/255)
    
    /// Vert clair pastel - Ecology backgrounds
    static let upNewsLightGreen = Color(red: 216/255, green: 243/255, blue: 177/255) // D8F3B1
    
    /// Rose & Rouge - Social/Health backgrounds
    static let upNewsLightPink = Color(red: 249/255, green: 225/255, blue: 225/255)  // F9E1E1
    static let UpNewsRed = Color(red: 237/255, green: 106/255, blue: 90/255) // ED6A5A
    
    /// Violet clair pastel - Culture backgrounds
    static let upNewsLightPurple = Color(red: 196/255, green: 193/255, blue: 242/255) // C4C1F2
    
    /// Jaune & bleu clair - Science/Accent
    static let upNewsYellow = Color(red: 254/255, green: 225/255, blue: 85/255)      // FEE155
    static let upNewsBlueMid = Color (red: 121/255, green: 173/255, blue: 220/255) // 79ADDC
    
    /// Vert vif - Ecology primary
    static let upNewsGreen = Color(red: 108/255, green: 194/255, blue: 65/255)       // 6CC241
    
    /// Orange vif - Social/CTA primary
    static let upNewsOrange = Color(red: 254/255, green: 129/255, blue: 60/255)      // FE813C
    
    // MARK: - Couleurs sémantiques
    
    /// Background principal de l'app
    static let upNewsBackground = Color(red: 249/255, green: 248/255, blue: 245/255) // F9F8F5 (beige clair)
    
    /// Couleur primaire (boutons, accents)
    static let upNewsPrimary = upNewsGreen  // 6CC241
    
    // MARK: - Couleurs par catégorie
    
    static let categoryEcology = upNewsGreen
    static let categoryTech = upNewsBlack
    static let categorySocial = upNewsOrange
    static let categoryCulture = upNewsLightPurple
    static let categoryScience = upNewsBlueMid
    static let categoryHealth = UpNewsRed
    static let categoryDefault = Color(red: 44/255, green: 62/255, blue: 53/255) // 2C3E35 - Gris foncé
}
