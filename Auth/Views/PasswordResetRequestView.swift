import SwiftUI

struct PasswordResetRequestView: View {
    @Binding var email: String
    @Binding var isPresented: Bool
    @Environment(AuthViewModel.self) private var viewModel
    @State private var isLoading = false
    @State private var message = ""
    @State private var isSuccess = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.44, green: 0.15, blue: 0.78).opacity(0.3),
                        Color.black
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // Icon and Title
                    VStack(spacing: 16) {
                        // LED MESSENGER Logo
                        Image("ledmwide35")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 50)
                            .shadow(color: .purple.opacity(0.3), radius: 10, x: 0, y: 5)
                        
                        Text("Reset Password")
                            .font(.title.bold())
                            .foregroundColor(.white)
                        
                        Text("Enter your email address and we'll send you a link to reset your password.")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 20)
                    
                    // Email Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email Address")
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                        
                        TextField("Enter your email", text: $email)
                            .textFieldStyle(PlainTextFieldStyle())
                            .foregroundColor(.white)
                            .accentColor(.purple)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled()
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                            .background(Color.black.opacity(0.3))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.purple.opacity(0.4), lineWidth: 1.5)
                            )
                    }
                    .padding(.horizontal)
                    
                    // Status Message
                    if !message.isEmpty {
                        HStack {
                            Image(systemName: isSuccess ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                .foregroundColor(isSuccess ? .green : .red)
                            
                            Text(message)
                                .font(.body)
                                .foregroundColor(isSuccess ? .green : .red)
                                .multilineTextAlignment(.leading)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill((isSuccess ? Color.green : Color.red).opacity(0.1))
                        )
                        .padding(.horizontal)
                        .animation(.easeInOut(duration: 0.3), value: message)
                    }
                    
                    // Send Reset Email Button
                    Button(action: sendResetEmail) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "paperplane.fill")
                                Text("Send Reset Email")
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
                    .disabled(isLoading || email.isEmpty || !email.contains("@"))
                    .padding(.horizontal)
                    
                    // Instructions
                    VStack(spacing: 8) {
                        Text("After clicking the button:")
                            .font(.caption.bold())
                            .foregroundColor(.white.opacity(0.8))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Label("Check your email inbox", systemImage: "1.circle.fill")
                            Label("Click the reset link", systemImage: "2.circle.fill")
                            Label("Create a new password", systemImage: "3.circle.fill")
                        }
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.top, 10)
                    
                    Spacer()
                }
            }
            .navigationBarItems(
                trailing: Button("Cancel") {
                    isPresented = false
                }
                .foregroundColor(.purple)
            )
        }
    }
    
    private func sendResetEmail() {
        Task {
            await MainActor.run {
                isLoading = true
                message = ""
                isSuccess = false
            }
            
            await viewModel.sendPasswordReset(email: email)
            
            await MainActor.run {
                // Check the viewModel's error message to determine success
                if let errorMsg = viewModel.errorMessage {
                    if errorMsg.contains("Password reset email sent") || errorMsg.contains("check your email") {
                        isSuccess = true
                        message = "Success! Check your email for the reset link."
                        
                        // Auto-dismiss after success
                        Task {
                            try? await Task.sleep(for: .seconds(3))
                            isPresented = false
                        }
                    } else {
                        isSuccess = false
                        message = errorMsg
                    }
                } else {
                    // If no error message, assume success
                    isSuccess = true
                    message = "If an account exists for \(email), you will receive a password reset email shortly."
                    
                    // Auto-dismiss after success
                    Task {
                        try? await Task.sleep(for: .seconds(3))
                        isPresented = false
                    }
                }
                
                isLoading = false
            }
        }
    }
}

#Preview {
    PasswordResetRequestView(
        email: .constant("test@example.com"),
        isPresented: .constant(true)
    )
    .environment(AuthViewModel())
}