import Foundation
import Supabase

enum SupabaseConfig {
    static let url = URL(string: SupabaseSecrets.url)!
    static let anonKey = SupabaseSecrets.anonKey
    
    static let client = SupabaseClient(
        supabaseURL: url,
        supabaseKey: anonKey
    )
    
    // URL de redirection pour Google OAuth
    static let redirectURL = URL(string: "upnews://login-callback")!
}
