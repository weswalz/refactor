import SwiftUI
import Supabase

struct PasswordResetView: View {
    @Binding var isPresented: Bool
    @Environment(AuthViewModel.self) private var viewModel
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var message = ""
    @State private var isSuccess = false
    
    // Add a default initializer for when no binding is provided (e.g., in previews)
    init(isPresented: Binding<Bool> = .constant(true)) {
        self._isPresented = isPresented
    }
    
    var body: some View {
        ZStack {
            // LED MESSENGER brand background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.44, green: 0.15, blue: 0.78), // Purple
                    Color(red: 0.1, green: 0.1, blue: 0.3),
                    Color.black
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Title
                VStack(spacing: 12) {
                    // LED MESSENGER Logo
                    Image("ledmwide35")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 50)
                        .shadow(color: .purple.opacity(0.3), radius: 10, x: 0, y: 5)
                    
                    Text("Reset Your Password")
                        .font(.title.bold())
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [.white, .purple.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text("Enter your new password below")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.top, 40)
                
                // Form Fields
                VStack(spacing: 24) {
                    // New Password Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("New Password")
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                        
                        SecureField("Enter new password", text: $newPassword)
                            .textFieldStyle(PlainTextFieldStyle())
                            .foregroundColor(.white)
                            .accentColor(.purple)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                            .background(Color.black.opacity(0.3))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.purple.opacity(0.4), lineWidth: 1.5)
                            )
                    }
                    
                    // Confirm Password Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Confirm Password")
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                        
                        SecureField("Confirm new password", text: $confirmPassword)
                            .textFieldStyle(PlainTextFieldStyle())
                            .foregroundColor(.white)
                            .accentColor(.purple)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                            .background(Color.black.opacity(0.3))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.purple.opacity(0.4), lineWidth: 1.5)
                            )
                    }
                }
                .padding(.horizontal)
                
                // Message
                if !message.isEmpty {
                    Text(message)
                        .font(.body)
                        .foregroundColor(isSuccess ? Color.green : Color.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .animation(.easeInOut(duration: 0.3), value: message)
                }
                
                // Reset Button
                Button(action: resetPassword) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Text("Reset Password")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.purple, .purple.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(isLoading || newPassword.isEmpty || confirmPassword.isEmpty || newPassword != confirmPassword)
                .padding(.horizontal)
                
                // Validation Message
                if !newPassword.isEmpty && !confirmPassword.isEmpty && newPassword != confirmPassword {
                    Text("Passwords don't match")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                
                Spacer()
            }
        }
    }
    
    private func resetPassword() {
        Task {
            await MainActor.run {
                isLoading = true
                message = ""
            }
            
            do {
                guard let auth = SupabaseManager.shared.auth else {
                    await MainActor.run {
                        isSuccess = false
                        message = "Authentication service not available"
                    }
                    return
                }
                
                // Update the user's password
                try await auth.update(user: UserAttributes(password: newPassword))
                
                await MainActor.run {
                    isSuccess = true
                    message = "✅ Password updated successfully! You can now sign in with your new password."
                }
                
                // Wait a moment to show the success message
                try await Task.sleep(for: .seconds(2))
                
                // Sign out to force navigation back to login screen
                // This ensures the user logs in with their new password
                try await auth.signOut()
                
                // Dismiss the password reset view
                await MainActor.run {
                    isPresented = false
                }
                
                // The auth state listener will automatically show the login screen
                
            } catch {
                await MainActor.run {
                    isSuccess = false
                    message = "Failed to update password: \(error.localizedDescription)"
                }
            }
            
            await MainActor.run {
                isLoading = false
            }
        }
    }
}

#Preview {
    PasswordResetView()
        .environment(AuthViewModel())
}
