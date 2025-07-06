import Foundation
import Supabase

@Observable
final class SupabaseManager {
    static let shared = SupabaseManager()
    
    private(set) var client: SupabaseClient?
    private(set) var adminClient: SupabaseClient?
    
    private init() {
        setupClient()
        setupAdminClient()
    }
    
    private func setupClient() {
        guard let supabaseURL = Bundle.main.object(forInfoDictionaryKey: "SupabaseURL") as? String,
              let supabaseAnonKey = Bundle.main.object(forInfoDictionaryKey: "SupabaseAnonKey") as? String,
              let url = URL(string: supabaseURL) else {
            print("Failed to load Supabase configuration from Info.plist")
            return
        }
        
        // CRITICAL FIX: Create custom URLSession configuration
        let configuration = URLSessionConfiguration.default
        configuration.multipathServiceType = .none
        
        // Additional stability settings for iOS 18
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        configuration.waitsForConnectivity = true
        configuration.allowsConstrainedNetworkAccess = true
        configuration.allowsExpensiveNetworkAccess = true
        
        // Create custom URLSession with our configuration
        let customSession = URLSession(configuration: configuration)
        
        self.client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: supabaseAnonKey,
            options: SupabaseClientOptions(
                auth: SupabaseClientOptions.AuthOptions(
                    redirectToURL: URL(string: "ledmessenger://auth-callback"),
                    flowType: .implicit,  // CRITICAL: Set to implicit flow to match email templates
                    autoRefreshToken: true
                ),
                global: SupabaseClientOptions.GlobalOptions(
                    // Use custom URLSession for all Supabase requests
                    session: customSession,
                    logger: nil
                )
            )
        )
        
        print("Supabase client initialized with custom URLSession")
    }
    
    var auth: AuthClient? {
        return client?.auth
    }
    
    private func setupAdminClient() {
        guard let supabaseURL = Bundle.main.object(forInfoDictionaryKey: "SupabaseURL") as? String,
              let serviceRoleKey = Bundle.main.object(forInfoDictionaryKey: "SupabaseServiceRoleKey") as? String,
              let url = URL(string: supabaseURL) else {
            print("Failed to load Supabase admin configuration from Info.plist")
            return
        }
        
        // Use same configuration for admin client
        let configuration = URLSessionConfiguration.default
        configuration.multipathServiceType = .none
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        configuration.waitsForConnectivity = true
        
        let customSession = URLSession(configuration: configuration)
        
        self.adminClient = SupabaseClient(
            supabaseURL: url,
            supabaseKey: serviceRoleKey,
            options: SupabaseClientOptions(
                global: SupabaseClientOptions.GlobalOptions(
                    headers: ["Authorization": "Bearer \(serviceRoleKey)"],
                    session: customSession
                )
            )
        )
        print("Supabase admin client initialized with custom URLSession")
    }
    
    func signOut() async throws {
        try await client?.auth.signOut()
    }
    
    func deleteUser() async throws {
        // It's assumed that you have an RPC function in Supabase `delete_user_account`
        // that handles the deletion of a user.
        guard let supabase = client else {
            // Handle the case where the client is not initialized
            throw URLError(.cannotFindHost)
        }
        try await supabase.rpc("delete_user_account").execute()
        
        // After deletion, sign the user out
        try await signOut()
    }
}
