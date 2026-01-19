import SwiftUI

/// Modèle de données pour l'onboarding propre (nouvelle version)
struct OnboardingPage: Identifiable {
    let id: Int
    let title: String
    let description: String
    let imageName: String // Nom de l'image du personnage
}

extension OnboardingPage {
    static let pages: [OnboardingPage] = [
        OnboardingPage(
            id: 0,
            title: "Une bonne nouvelle\nchaque matin",
            description: "Commence ta journée avec une dose d'optimisme. 3 minutes pour voir le monde autrement.",
            imageName: "mousse"
        ),
        OnboardingPage(
            id: 1,
            title: "Construis ton rituel\npositif",
            description: "Chaque lecture te rapproche d'un nouveau niveau. Plus tu lis, plus tu progresses.",
            imageName: "givre_et_plume"
        ),
        OnboardingPage(
            id: 2,
            title: "Collectionne tes\ncompagnons",
            description: "Débloque de nouveaux personnages en lisant régulièrement. Choisis ton préféré et personnalise ton profil.",
            imageName: "mochi"
        ),
        OnboardingPage(
            id: 3,
            title: "Ta dose de positivité\nt'attend",
            description: "Prêt à transformer tes matins ? C'est parti !",
            imageName: "cannelle"
        )
    ]
}
