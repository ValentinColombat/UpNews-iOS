# UpNews-iOS 📱

Application iOS pour UpNews - Votre source d'actualités personnalisée.

## 🚀 Configuration du Projet

### Prérequis

- Xcode 14.0 ou supérieur
- iOS 15.0 ou supérieur
- CocoaPods ou Swift Package Manager
- Compte Google Cloud (pour OAuth)
- Compte Supabase

### Installation

1. **Cloner le repository**
   ```bash
   git clone https://github.com/ValentinColombat/UpNews-iOS.git
   cd UpNews-iOS
   ```

2. **Installer les dépendances**
   ```bash
   # Si vous utilisez CocoaPods
   pod install
   
   # Ou ouvrez le projet dans Xcode pour installer via Swift Package Manager
   open UpNews-iOS.xcodeproj
   ```

3. **⚠️ IMPORTANT: Configurer les Secrets**

   Le projet nécessite deux fichiers de configuration qui ne sont PAS inclus dans le repository pour des raisons de sécurité:

   #### a. Configuration Supabase
   ```bash
   cd UpNews-iOS/Services
   cp SupabaseSecrets.example.swift SupabaseSecrets.swift
   ```
   
   Éditez `SupabaseSecrets.swift` et remplacez les valeurs par vos clés Supabase:
   ```swift
   enum SupabaseSecrets {
       static let url = "https://votre-projet.supabase.co"
       static let anonKey = "votre_clé_anon"
   }
   ```

   #### b. Configuration Google OAuth
   ```bash
   cp GoogleSecrets.example.swift GoogleSecrets.swift
   ```
   
   Éditez `GoogleSecrets.swift` et remplacez la valeur par votre Client ID Google:
   ```swift
   enum GoogleSecrets {
       static let clientID = "votre-client-id.apps.googleusercontent.com"
   }
   ```

4. **Mettre à Jour Info.plist (si nécessaire)**

   Si vous utilisez un nouveau Google Client ID, mettez également à jour `Info.plist`:
   - Dans `CFBundleURLSchemes`: Remplacez le reverse Client ID
   - Dans `GIDClientID`: Remplacez le Client ID complet

5. **Lancer le projet**
   ```bash
   # Ouvrir dans Xcode
   open UpNews-iOS.xcodeproj
   
   # Ou si vous utilisez un workspace (CocoaPods)
   open UpNews-iOS.xcworkspace
   ```

## 🔐 Sécurité

Ce projet suit les meilleures pratiques de sécurité:

- ✅ Tous les secrets sont stockés dans des fichiers séparés (ignorés par Git)
- ✅ Des templates `.example.swift` sont fournis pour faciliter la configuration
- ✅ Aucune clé API ou secret n'est committé dans le code source

**Pour plus de détails**, consultez [SECURITY.md](SECURITY.md)

⚠️ **IMPORTANT**: Ne committez JAMAIS les fichiers suivants:
- `SupabaseSecrets.swift`
- `GoogleSecrets.swift`
- Tout fichier `Secrets.swift`

Ces fichiers sont automatiquement ignorés par `.gitignore`.

## 📱 Fonctionnalités

- Authentification via Google OAuth
- Authentification Email/Mot de passe via Supabase
- Lecture d'articles d'actualités
- Interface utilisateur moderne en SwiftUI

## 🛠️ Technologies Utilisées

- **SwiftUI** - Interface utilisateur
- **Supabase** - Backend et authentification
- **Google Sign-In** - Authentification Google OAuth
- **Combine** - Programmation réactive

## 📝 Obtenir vos Clés

### Supabase

1. Créez un compte sur [supabase.com](https://supabase.com)
2. Créez un nouveau projet
3. Allez dans Settings > API
4. Copiez votre `Project URL` et `anon/public key`

### Google OAuth

1. Allez sur [Google Cloud Console](https://console.cloud.google.com)
2. Créez un nouveau projet ou sélectionnez-en un existant
3. Activez l'API Google Sign-In
4. Créez des identifiants OAuth 2.0
5. Configurez l'écran de consentement OAuth
6. Ajoutez votre Bundle ID iOS
7. Copiez votre Client ID

## 🤝 Contribution

Les contributions sont les bienvenues! N'oubliez pas:

1. Ne commitez jamais de secrets ou clés API
2. Utilisez les fichiers `.example.swift` comme référence
3. Mettez à jour la documentation si nécessaire

## 📄 Licence

[Ajoutez votre licence ici]

## 👤 Auteur

Valentin Colombat

## 🆘 Support

Si vous rencontrez des problèmes de configuration:

1. Vérifiez que vous avez bien créé les fichiers `SupabaseSecrets.swift` et `GoogleSecrets.swift`
2. Assurez-vous que vos clés sont correctes
3. Vérifiez que `Info.plist` contient le bon Client ID Google
4. Consultez [SECURITY.md](SECURITY.md) pour plus de détails

---

**Note**: Ce projet est configuré pour protéger vos données sensibles. Assurez-vous de suivre les instructions de configuration ci-dessus avant de lancer l'application.
