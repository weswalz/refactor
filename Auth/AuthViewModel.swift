import Foundation
import SwiftUI
import Supabase

// MARK: - Profile Data Model
struct ProfileData: Codable {
    let id: String
    let email: String
    let first_name: String
    let last_name: String
    let full_name: String
}

@Observable
@MainActor
final class AuthViewModel {
    enum AuthState: Equatable {
        case loading
        case unauthenticated
        case authenticated(User)
        case processing  // Processing authentication callback
        case networkError(String)  // NEW: Specific network error state
        
        static func == (lhs: AuthState, rhs: AuthState) -> Bool {
            switch (lhs, rhs) {
            case (.loading, .loading):
                return true
            case (.unauthenticated, .unauthenticated):
                return true
            case (.processing, .processing):
                return true
            case (.authenticated(let user1), .authenticated(let user2)):
                return user1.id == user2.id
            case (.networkError(let msg1), .networkError(let msg2)):
                return msg1 == msg2
            default:
                return false
            }
        }
    }
    
    enum AuthError: LocalizedError {
        case signInFailed(String)
        case signUpFailed(String)
        case signOutFailed(String)
        case sessionRestoreFailed(String)
        case emailConfirmationRequired
        case deleteFailed(String)
        case networkConnectionLost  // NEW: Specific error for HTTP/3 issues
        
        var errorDescription: String? {
            switch self {
            case .signInFailed(let message):
                return "Sign in failed: \(message)"
            case .signUpFailed(let message):
                return "Sign up failed: \(message)"
            case .signOutFailed(let message):
                return "Sign out failed: \(message)"
            case .sessionRestoreFailed(let message):
                return "Session restore failed: \(message)"
            case .emailConfirmationRequired:
                return "Please check your email to confirm your account before signing in."
            case .deleteFailed(let message):
                return "Failed to delete account: \(message)"
            case .networkConnectionLost:
                return "Network connection issue. Please check your internet connection and try again."
            }
        }
    }
    
    var authState: AuthState = .loading
    var isLoading = false
    var errorMessage: String?
    var isProcessingCallback = false
    var lastAuthenticationTime: Date?
    private var retryCount = 0
    private let maxRetries = 3
    
    // Store last operation for retry
    private var lastOperationType: LastOperationType?
    private var lastOperationCredentials: (email: String, password: String)?
    
    private enum LastOperationType {
        case signIn
        case signUp
    }
    
    private var authStateListener: Task<Void, Never>?
    
    // Computed property to check if current state is network error
    var isNetworkError: Bool {
        if case .networkError = authState {
            return true
        }
        return false
    }
    
    init() {
        setupAuthListener()
        checkCurrentSession()
    }
    
    deinit {
        MainActor.assumeIsolated {
            authStateListener?.cancel()
        }
    }
    
    private func setupAuthListener() {
        guard let auth = SupabaseManager.shared.auth else { return }
        
        authStateListener = Task {
            for await (event, session) in auth.authStateChanges {
                print("🔄 Auth state changed: \(event.rawValue)")
                
                await MainActor.run {
                    switch event {
                    case .signedIn:
                        if let user = session?.user {
                            self.authState = .authenticated(user)
                            self.lastAuthenticationTime = Date()
                            self.errorMessage = nil
                            self.retryCount = 0  // Reset retry count on success
                            print("✅ User authenticated: \(user.email ?? "unknown")")
                        }
                    case .signedOut:
                        self.authState = .unauthenticated
                        self.lastAuthenticationTime = nil
                        print("👋 User signed out")
                    case .tokenRefreshed:
                        if let user = session?.user {
                            self.authState = .authenticated(user)
                            print("🔄 Token refreshed for user: \(user.email ?? "unknown")")
                        }
                    case .userUpdated:
                        if let user = session?.user {
                            self.authState = .authenticated(user)
                            print("👤 User updated: \(user.email ?? "unknown")")
                        }
                    default:
                        break
                    }
                }
            }
        }
    }
    
    private func checkCurrentSession() {
        Task {
            guard let auth = SupabaseManager.shared.auth else {
                await MainActor.run {
                    self.authState = .unauthenticated
                }
                return
            }
            
            do {
                let session = try await auth.session
                await MainActor.run {
                    self.authState = .authenticated(session.user)
                    self.lastAuthenticationTime = Date()
                }
                print("🔄 Restored existing session for user: \(session.user.id)")
            } catch {
                // Check if it's a network error
                if isNetworkError(error) {
                    print("📶 Network error during session check - showing login screen")
                    await MainActor.run {
                        self.authState = .unauthenticated
                        self.errorMessage = "Network connection issue. Please check your internet connection."
                    }
                } else {
                    print("ℹ️ No existing session found or network error - showing login screen")
                    await MainActor.run {
                        self.authState = .unauthenticated
                    }
                }
            }
        }
    }
    
    // NEW: Check if error is a network connection error
    private func isNetworkError(_ error: Error) -> Bool {
        let nsError = error as NSError
        return nsError.code == -1005 || // Network connection lost
               nsError.code == -1009 || // No internet connection
               nsError.code == -1001 || // Request timeout
               nsError.code == -1004    // Cannot connect to host
    }
    
    // NEW: Force refresh authentication state (for URL callbacks)
    func refreshAuthenticationState() async {
        guard let auth = SupabaseManager.shared.auth else { return }
        
        self.authState = .processing
        
        do {
            // Try to get current session
            let session = try await auth.session
            self.authState = .authenticated(session.user)
            self.lastAuthenticationTime = Date()
            self.errorMessage = nil
            self.retryCount = 0
            print("✅ Authentication state refreshed successfully")
        } catch {
            if isNetworkError(error) {
                print("⚠️ Network error during authentication refresh")
                self.authState = .networkError("Connection issue - HTTP/3 disabled, trying HTTP/2")
                self.errorMessage = "Network connection issue. Retrying..."
                // Wait briefly then try again
                try? await Task.sleep(for: .seconds(2))
                checkCurrentSession()
            } else {
                print("⚠️ Failed to refresh authentication state: \(error)")
                self.authState = .unauthenticated
                self.errorMessage = "Please try signing in again."
            }
        }
    }
    
    func signIn(email: String, password: String) async {
        guard let auth = SupabaseManager.shared.auth else { return }
        
        self.isLoading = true
        self.errorMessage = nil
        
        // Log the authentication attempt
        print("🔐 Attempting sign in for: \(email)")
        
        do {
            print("🔐 Attempting Supabase authentication")
            let response = try await auth.signIn(email: email, password: password)
            print("✅ User signed in: \(response.user.id)")
            
            self.lastAuthenticationTime = Date()
            self.retryCount = 0
            self.lastOperationType = .signIn
            self.lastOperationCredentials = (email, password)
        } catch {
            let nsError = error as NSError
            print("❌ Sign in failed with error: \(error)")
            print("❌ Error type: \(type(of: error))")
            print("❌ NSError code: \(nsError.code)")
            print("❌ Localized description: \(error.localizedDescription)")
            
            await MainActor.run {
                if self.isNetworkError(error) {
                    print("🔐 DEBUG: Auth State = NETWORK_ERROR - Connection issue")
                    
                    // If we haven't exceeded retry count, retry automatically
                    if self.retryCount < self.maxRetries {
                        self.retryCount += 1
                        self.errorMessage = "Connection error. Retry \(self.retryCount)/\(self.maxRetries)..."
                        print("🔄 Retry \(self.retryCount)/\(self.maxRetries) after \(Double(self.retryCount))s delay")
                        
                        Task {
                            try? await Task.sleep(for: .seconds(Double(self.retryCount)))
                            await self.signIn(email: email, password: password)
                        }
                        return
                    } else {
                        self.errorMessage = AuthError.networkConnectionLost.localizedDescription
                        self.authState = .networkError("Connection failed after \(self.maxRetries) attempts")
                        self.retryCount = 0
                    }
                } else if error.localizedDescription.lowercased().contains("email") || 
                          error.localizedDescription.lowercased().contains("confirm") {
                    self.errorMessage = AuthError.emailConfirmationRequired.localizedDescription
                } else {
                    self.errorMessage = AuthError.signInFailed(error.localizedDescription).localizedDescription
                }
            }
        }
        
        self.isLoading = false
    }
    
    func signUp(email: String, password: String, firstName: String = "", lastName: String = "") async {
        guard let auth = SupabaseManager.shared.auth, let client = SupabaseManager.shared.client else { return }
        
        self.isLoading = true
        self.errorMessage = nil
        
        // Store operation for retry
        self.lastOperationType = .signUp
        self.lastOperationCredentials = (email, password)
        
        do {
            let response = try await auth.signUp(email: email, password: password)
            print("✅ User signed up: \(response.user.id.uuidString)")
            
            // Create profile with first and last name
            if !firstName.isEmpty || !lastName.isEmpty {
                let profileData = ProfileData(
                    id: response.user.id.uuidString,
                    email: email,
                    first_name: firstName,
                    last_name: lastName,
                    full_name: "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
                )
                
                do {
                    try await client
                        .from("profiles")
                        .insert(profileData)
                        .execute()
                    print("✅ Profile created for user: \(firstName) \(lastName)")
                } catch {
                    print("⚠️ Failed to create profile: \(error)")
                    // Don't fail the signup for profile creation errors
                }
            }
            
            // Check if email confirmation is required by checking session
            if response.session == nil {
                self.errorMessage = "🎉 Account created! Please check your email to confirm your account, then return to the app."
            } else {
                self.lastAuthenticationTime = Date()
            }
            self.retryCount = 0
        } catch {
            print("❌ Sign up failed: \(error)")
            if self.isNetworkError(error) {
                self.errorMessage = AuthError.networkConnectionLost.localizedDescription
            } else {
                self.errorMessage = AuthError.signUpFailed(error.localizedDescription).localizedDescription
            }
        }
        
        self.isLoading = false
    }
    
    func signOut() async {
        guard let auth = SupabaseManager.shared.auth else { return }
        
        self.isLoading = true
        self.errorMessage = nil
        
        do {
            try await auth.signOut()
            print("👋 User signed out")
            self.lastAuthenticationTime = nil
            self.retryCount = 0
        } catch {
            print("❌ Sign out failed: \(error)")
            self.errorMessage = AuthError.signOutFailed(error.localizedDescription).localizedDescription
        }
        
        self.isLoading = false
    }
    
    // NEW: Check if recently authenticated (useful for preventing duplicate processing)
    var isRecentlyAuthenticated: Bool {
        guard let lastAuth = lastAuthenticationTime else { return false }
        return Date().timeIntervalSince(lastAuth) < 10 // Within last 10 seconds
    }
    
    // Retry last operation (for network errors)
    func retryLastOperation() async {
        guard let lastOp = lastOperationType,
              let credentials = lastOperationCredentials else {
            print("⚠️ No last operation to retry")
            return
        }
        
        switch lastOp {
        case .signIn:
            await signIn(email: credentials.email, password: credentials.password)
        case .signUp:
            await signUp(email: credentials.email, password: credentials.password)
        }
    }
    
    // Send password reset email
    func sendPasswordReset(email: String) async {
        guard let auth = SupabaseManager.shared.auth else { return }
        
        self.isLoading = true
        self.errorMessage = nil
        
        do {
            try await auth.resetPasswordForEmail(email)
            print("✅ Password reset email sent to: \(email)")
            
            self.errorMessage = "🎉 Password reset email sent! Please check your email for instructions."
        } catch {
            print("❌ Failed to send password reset email: \(error)")
            if self.isNetworkError(error) {
                self.errorMessage = AuthError.networkConnectionLost.localizedDescription
            } else {
                self.errorMessage = "Failed to send reset email: \(error.localizedDescription)"
            }
        }
        
        self.isLoading = false
    }
    
    // Delete the current user's account
    func deleteAccount() async {
        // Ensure there is a Supabase manager instance
        guard SupabaseManager.shared.client != nil else {
            self.errorMessage = AuthError.deleteFailed("Supabase client not available.").localizedDescription
            return
        }
        
        self.isLoading = true
        self.errorMessage = nil
        
        do {
            // Call the user deletion function in SupabaseManager
            try await SupabaseManager.shared.deleteUser()
            print("✅ Account deleted successfully.")
            
            // After successful deletion, sign the user out to clear the session
            await signOut()
            
        } catch {
            // Handle any errors during the deletion process
            print("❌ Account deletion failed: \(error)")
            self.errorMessage = AuthError.deleteFailed(error.localizedDescription).localizedDescription
        }
        
        self.isLoading = false
    }
}
