import Foundation
import Observation
import Supabase

@Observable
@MainActor
final class SupabaseService {
    static let shared = SupabaseService()
    
    let client: SupabaseClient?
    private(set) var isConfigured: Bool = false
    private(set) var lastError: String?
    
    private init() {
        let urlString = Config.allValues["EXPO_PUBLIC_SUPABASE_URL"] ?? ""
        let anonKey = Config.allValues["EXPO_PUBLIC_SUPABASE_ANON_KEY"] ?? ""
        
        guard
            !urlString.isEmpty,
            !anonKey.isEmpty,
            let url = URL(string: urlString),
            url.scheme?.hasPrefix("http") == true
        else {
            self.client = nil
            self.isConfigured = false
            self.lastError = "Supabase URL or anon key missing."
            return
        }
        
        self.client = SupabaseClient(supabaseURL: url, supabaseKey: anonKey)
        self.isConfigured = true
    }
    
    // MARK: - Auth helpers
    
    func signInWithOTP(email: String) async {
        guard let client else { return }
        do {
            try await client.auth.signInWithOTP(email: email)
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }
    
    func signOut() async {
        guard let client else { return }
        do {
            try await client.auth.signOut()
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }
    
    func currentUserID() async -> String? {
        guard let client else { return nil }
        return try? await client.auth.session.user.id.uuidString
    }
    
    // MARK: - Generic data helpers
    
    func fetch<T: Decodable & Sendable>(
        from table: String,
        as type: T.Type
    ) async -> [T] {
        guard let client else { return [] }
        do {
            let rows: [T] = try await client
                .from(table)
                .select()
                .execute()
                .value
            return rows
        } catch {
            lastError = error.localizedDescription
            return []
        }
    }
    
    func insert<T: Encodable & Sendable>(
        _ value: T,
        into table: String
    ) async -> Bool {
        print("🟡 Tentative insertion Supabase dans table:", table)
        print("📦 Données envoyées:", value)
        
        guard let client else {
            print("❌ Supabase client nil")
            lastError = "Supabase client nil"
            return false
        }
        
        do {
            try await client.from(table).insert(value).execute()
            print("✅ Insertion Supabase réussie dans:", table)
            lastError = nil
            return true
        } catch {
            print("❌ Erreur insertion Supabase dans \(table):", error)
            print("❌ Erreur localisée:", error.localizedDescription)
            lastError = error.localizedDescription
            return false
        }
    }
}
