# Rapport de Sécurité - Données Sensibles

## 📋 Résumé de l'Audit de Sécurité

Ce document résume l'audit de sécurité effectué sur le repository UpNews-iOS pour identifier et sécuriser les données sensibles.

## 🔍 Résultats de l'Audit

### ✅ Données Sensibles Correctement Protégées

1. **Identifiants Supabase** - ✅ MAINTENANT SÉCURISÉ
   - Fichier: `SupabaseSecrets.swift` (retiré du tracking Git et correctement ignoré par `.gitignore`)
   - Template fourni: `SupabaseSecrets.example.swift`
   - Utilisation: Via `SupabaseConfig.swift`
   - **⚠️ IMPORTANT**: Les credentials Supabase ont été exposés dans l'historique Git et DOIVENT être rotés

2. **Identifiant Google OAuth** - ✅ MAINTENANT SÉCURISÉ
   - Fichier: `GoogleSecrets.swift` (ajouté au `.gitignore`)
   - Template fourni: `GoogleSecrets.example.swift`
   - Utilisation: Via `UpNews_iOSApp.swift`

### ⚠️ Données Sensibles Trouvées (CORRIGÉES)

#### 1. Credentials Supabase (CRITIQUE - Février 2026)
- **Statut Précédent**: ❌ Exposé dans Git
- **Statut Actuel**: ✅ Retiré du tracking Git
- **Fichiers Concernés**:
  - `UpNews-iOS/Services/SupabaseSecrets.swift` - RETIRÉ du tracking Git via `git rm --cached`

**Actions Prises**:
1. ✅ Retrait de `SupabaseSecrets.swift` du tracking Git (`git rm --cached`)
2. ✅ Vérification que `.gitignore` contient bien `SupabaseSecrets.swift`
3. ✅ Template `SupabaseSecrets.example.swift` existe avec valeurs masquées

**🔴 ACTION REQUISE IMMÉDIATEMENT**:
Le fichier `SupabaseSecrets.swift` contenait des credentials réels qui ont été exposés dans l'historique Git:
- **URL Supabase**: `https://twqxlizczyntiicjjndu.supabase.co`
- **Anon Key**: Token JWT exposé

**Il est IMPÉRATIF de**:
1. Se connecter à la console Supabase
2. Générer une nouvelle `anon key`
3. Mettre à jour votre fichier local `SupabaseSecrets.swift`
4. Révoquer l'ancienne clé exposée

#### 2. Google OAuth Client ID
- **Statut Précédent**: ❌ Exposé dans le code
- **Statut Actuel**: ✅ Sécurisé
- **Fichiers Concernés**:
  - `UpNews-iOS/UpNews_iOSApp.swift` - CORRIGÉ (déplacé vers GoogleSecrets.swift)
  - `UpNews-iOS/Info.plist` (CFBundleURLSchemes et GIDClientID) - COMMENTÉ avec avertissement

**Actions Prises**:
1. Création de `GoogleSecrets.swift` pour stocker le Client ID
2. Ajout de `GoogleSecrets.swift` au `.gitignore`
3. Mise à jour de `UpNews_iOSApp.swift` pour utiliser `GoogleSecrets.clientID`
4. Création de `GoogleSecrets.example.swift` comme template
5. Ajout de commentaires dans `Info.plist` pour documenter la dépendance

**Note**: Le Client ID Google OAuth reste dans `Info.plist` car c'est requis par iOS pour gérer les URL schemes (lignes CFBundleURLSchemes et GIDClientID). Cependant, un commentaire a été ajouté pour rappeler de maintenir la cohérence avec `GoogleSecrets.swift`.

### ✅ Aucune Autre Donnée Sensible Détectée

- ❌ Pas de clés API supplémentaires
- ❌ Pas de mots de passe en dur
- ❌ Pas de tokens OAuth non protégés
- ❌ Pas de clés privées ou certificats
- ❌ Pas de chaînes de connexion à des bases de données

## 🔒 Bonnes Pratiques Appliquées

### Configuration Actuelle

1. **Fichiers `.gitignore`** - Configuré pour exclure:
   ```
   SupabaseSecrets.swift
   GoogleSecrets.swift
   Secrets.swift
   ```

2. **Fichiers Template** - Fournis pour faciliter la configuration:
   - `SupabaseSecrets.example.swift`
   - `GoogleSecrets.example.swift`

3. **Séparation des Secrets** - Les secrets sont isolés dans des fichiers dédiés:
   - `SupabaseSecrets.swift` pour les identifiants Supabase
   - `GoogleSecrets.swift` pour les identifiants Google

### Instructions pour les Nouveaux Développeurs

1. **Cloner le Repository**
   ```bash
   git clone https://github.com/ValentinColombat/UpNews-iOS.git
   cd UpNews-iOS
   ```

2. **Configurer les Secrets Supabase**
   ```bash
   cd UpNews-iOS/Services
   cp SupabaseSecrets.example.swift SupabaseSecrets.swift
   ```
   Puis éditer `SupabaseSecrets.swift` avec vos vraies clés Supabase.

3. **Configurer les Secrets Google**
   ```bash
   cp GoogleSecrets.example.swift GoogleSecrets.swift
   ```
   Puis éditer `GoogleSecrets.swift` avec votre vrai Client ID Google.

4. **Mettre à Jour Info.plist (si nécessaire)**
   Si vous changez le Google Client ID, mettez à jour également `Info.plist`:
   - Ligne 17: `com.googleusercontent.apps.[VOTRE_CLIENT_ID]`
   - Ligne 29: `[VOTRE_CLIENT_ID].apps.googleusercontent.com`

## 📊 Niveau de Risque

| Catégorie | Avant | Après |
|-----------|-------|-------|
| Exposition des Secrets | 🔴 ÉLEVÉ | 🟢 FAIBLE |
| Clés API Hardcodées | 🔴 OUI | 🟢 NON |
| Protection .gitignore | 🟡 PARTIELLE | 🟢 COMPLÈTE |

## 🎯 Recommandations Futures

1. **🔴 URGENT - Rotation des Secrets Supabase**: 
   - **Action immédiate requise**: Générer une nouvelle `anon key` dans la console Supabase
   - Révoquer l'ancienne clé qui a été exposée dans Git
   - Mettre à jour le fichier local `SupabaseSecrets.swift`

2. **Rotation Google OAuth Client ID**: Si ce repository était public, il est recommandé de:
   - Générer un nouveau Google OAuth Client ID
   - Révoquer l'ancien Client ID exposé

3. **Nettoyage de l'Historique Git** (optionnel mais recommandé):
   - Envisager d'utiliser `git filter-repo` ou BFG Repo-Cleaner pour supprimer complètement `SupabaseSecrets.swift` de l'historique Git
   - Note: Cela nécessite une coordination avec tous les contributeurs car cela réécrit l'historique

4. **CI/CD**: Considérer l'utilisation de secrets d'environnement pour les pipelines CI/CD

5. **Scan Automatique**: Mettre en place un outil de scan automatique (comme GitGuardian ou TruffleHog) pour détecter les secrets accidentellement committés

6. **Variables d'Environnement**: Pour un projet en production, considérer l'utilisation de variables d'environnement ou d'un gestionnaire de secrets (comme AWS Secrets Manager, Azure Key Vault, etc.)

## ✅ Conclusion

L'audit a identifié plusieurs problèmes de sécurité qui ont été corrigés:

1. **Credentials Supabase exposés** (CRITIQUE):
   - Problème: Le fichier `SupabaseSecrets.swift` contenant des credentials réels était tracké par Git
   - Solution: Retiré du tracking Git via `git rm --cached`
   - **Action requise**: ROTATION IMMÉDIATE des credentials Supabase

2. **Google OAuth Client ID exposé**:
   - Problème: Client ID hardcodé dans le code
   - Solution: Déplacé vers `GoogleSecrets.swift` (ignoré par Git)

Le repository suit maintenant les meilleures pratiques de sécurité pour la gestion des secrets dans les applications iOS.

**⚠️ IMPORTANT**: Les credentials Supabase ayant été exposés dans l'historique Git, il est impératif de les faire pivoter immédiatement.

---

**Date de l'Audit**: 2026-01-19 (Mise à jour: 2026-02-09)
**Auditeur**: GitHub Copilot Security Scan
