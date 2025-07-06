import SwiftUI
import Supabase

struct ProfileView: View {
    @Environment(\.authViewModel) var authViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showingSignOutAlert = false
    @State private var showingPasswordResetAlert = false
    @State private var passwordResetMessage = ""
    
    var currentUser: User? {
        guard let authViewModel = authViewModel else { return nil }
        if case .authenticated(let user) = authViewModel.authState {
            return user
        }
        return nil
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.1, green: 0.1, blue: 0.2),
                        Color(red: 0.05, green: 0.05, blue: 0.15)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    // Profile Header - Made more compact
                    VStack(spacing: 8) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(.blue.gradient)
                        
                        if let email = currentUser?.email {
                            Text(email)
                                .font(.title3)
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.top, 16)
                        
                    // Account Info Section - Made more compact
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Account Information")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal)
                        
                        VStack(spacing: 8) {
                            ProfileInfoRow(title: "Created", value: formatDate(currentUser?.createdAt))
                            ProfileInfoRow(title: "Last Sign In", value: formatDate(currentUser?.lastSignInAt))
                        }
                        .padding(12)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal)
                        
                    // Actions Section
                    VStack(spacing: 10) {
                        // Reset Password Button
                        Button(action: {
                            Task {
                                if let email = currentUser?.email {
                                    await authViewModel?.sendPasswordReset(email: email)
                                    // Show alert after sending
                                    passwordResetMessage = "Password reset email sent to \(email). Please check your inbox."
                                    showingPasswordResetAlert = true
                                }
                            }
                        }) {
                            HStack {
                                Image(systemName: "key.fill")
                                Text("Reset Password")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.blue.opacity(0.2))
                            .foregroundColor(.blue)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                            )
                        }
                            
                        // Manage Subscription Button
                        Link(destination: URL(string: "https://billing.stripe.com/p/login/28o7w48jGaxx9Xi8ww")!) {
                            HStack {
                                Image(systemName: "creditcard.fill")
                                Text("Manage Subscription")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.green.opacity(0.2))
                            .foregroundColor(.green)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
                            )
                        }
                        
                        // Sign Out Button
                        Button(action: {
                            showingSignOutAlert = true
                        }) {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("Sign Out")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.orange.opacity(0.2))
                            .foregroundColor(.orange)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                            )
                        }
                        
                        // Delete Account Button
                        Link(destination: URL(string: "https://clubkit.io/account/delete")!) {
                            HStack {
                                Image(systemName: "trash.fill")
                                Text("Delete Account")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.red.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.red, lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)
                    
                    Spacer(minLength: 20)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
            })
        }
        .alert("Sign Out", isPresented: $showingSignOutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                Task {
                    await authViewModel?.signOut()
                    dismiss()
                }
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .alert("Password Reset", isPresented: $showingPasswordResetAlert) {
            Button("OK") { }
        } message: {
            Text(passwordResetMessage)
        }
    }
    
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "Not available" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

private struct ProfileInfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.6))
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundColor(.white)
                .multilineTextAlignment(.trailing)
        }
    }
}

#Preview {
    ProfileView()
        .preferredColorScheme(.dark)
}
