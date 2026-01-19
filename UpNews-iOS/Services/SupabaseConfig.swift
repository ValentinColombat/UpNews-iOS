import Foundation
import Supabase

enum SupabaseConfig {
    static let url = URL(string: SupabaseSecrets.url)!
    static let anonKey = SupabaseSecrets.anonKey
    
    static let client = SupabaseClient(
        supabaseURL:  url,
        supabaseKey: anonKey
    )
    
    static let redirectURL = URL(string: "upnews://login-callback")!
}
