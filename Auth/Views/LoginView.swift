import SwiftUI

struct LoginView: View {
    @Environment(AuthViewModel.self) private var viewModel
    @State private var email = ""
    @State private var password = ""
    @State private var showingPasswordReset = false
    @State private var passwordResetEmail = ""
    
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
                // Logos and Title
                VStack(spacing: 20) {
                    // Clubkit Logo
                    Image("ck40")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 60)
                        .shadow(color: .white.opacity(0.2), radius: 5, x: 0, y: 2)
                    
                    // LED MESSENGER Logo
                    Image("ledmwide35")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 25)
                        .shadow(color: .purple.opacity(0.3), radius: 10, x: 0, y: 5)
                    
                    Text("Welcome Back")
                        .font(.title2.bold())
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [.white, .purple.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
                .padding(.top, 40)
                
                // Form Fields
                VStack(spacing: 24) {
                    // Email Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email Address")
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                        
                        ZStack(alignment: .leading) {
                            if email.isEmpty {
                                Text("Enter your email")
                                    .foregroundColor(.white.opacity(0.35))
                                    .padding(.horizontal, 16)
                            }
                            
                            TextField("", text: $email)
                                .textFieldStyle(PlainTextFieldStyle())
                                .foregroundColor(.white)
                                .accentColor(.purple)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.emailAddress)
                                .autocorrectionDisabled()
                                .padding(.horizontal, 16)
                                .padding(.vertical, 16)
                        }
                            .background(Color.black.opacity(0.2))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.purple.opacity(0.4), lineWidth: 1.5)
                            )
                            .contentShape(Rectangle())
                    }
                    
                    // Password Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                        
                        ZStack(alignment: .leading) {
                            if password.isEmpty {
                                Text("Enter your password")
                                    .foregroundColor(.white.opacity(0.35))
                                    .padding(.horizontal, 16)
                            }
                            
                            SecureField("", text: $password)
                                .textFieldStyle(PlainTextFieldStyle())
                                .foregroundColor(.white)
                                .accentColor(.purple)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 16)
                        }
                            .background(Color.black.opacity(0.2))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.purple.opacity(0.4), lineWidth: 1.5)
                            )
                            .contentShape(Rectangle())
                    }
                }
                .padding(.horizontal)
                
                // Error/Success Message with 2025 Network Handling
                if let errorMessage = viewModel.errorMessage {
                    VStack(spacing: 12) {
                        Text(errorMessage)
                            .font(errorMessage.contains("check your email") ? .body.bold() : .caption)
                            .foregroundColor(
                                errorMessage.contains("check your email") 
                                    ? Color.cyan  // Electric blue for success
                                    : errorMessage.contains("Network") 
                                        ? Color.orange  // Orange for network issues
                                        : Color.red   // Red for other errors
                            )
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity)
                            .animation(.easeInOut(duration: 0.3), value: viewModel.errorMessage)
                        
                        // 2025: Network Retry Button
                        if viewModel.isNetworkError {
                            Button("Retry Connection") {
                                Task {
                                    await viewModel.retryLastOperation()
                                }
                            }
                            .font(.caption.bold())
                            .foregroundColor(.cyan)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.cyan.opacity(0.1))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal, 40)
                }
                
                // Action Buttons - Side by Side
                HStack(spacing: 16) {
                    // Sign Up Button (Left)
                    Button(action: {
                        if let url = URL(string: "https://clubkit.io") {
                            #if canImport(UIKit)
                            UIApplication.shared.open(url)
                            #elseif canImport(AppKit)
                            NSWorkspace.shared.open(url)
                            #endif
                        }
                    }) {
                        Text("SIGN UP")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.clear)
                            .foregroundColor(.purple)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.purple, lineWidth: 2)
                            )
                    }
                    
                    // Sign In Button (Right)
                    Button(action: {
                        Task {
                            await viewModel.signIn(email: email, password: password)
                        }
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Text("SIGN IN")
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
                    .disabled(viewModel.isLoading || email.isEmpty || password.isEmpty || viewModel.isNetworkError)
                }
                .padding(.horizontal)
                
                // Forgot Password Link
                Button(action: {
                    passwordResetEmail = email // Pre-fill with current email if any
                    showingPasswordReset = true
                }) {
                    Text("Forgot Password?")
                        .font(.subheadline)
                        .foregroundColor(.purple.opacity(0.8))
                        .underline()
                }
                .padding(.bottom, 20)
                
                Spacer()
            }
        }
        .sheet(isPresented: $showingPasswordReset) {
            PasswordResetRequestView(email: $passwordResetEmail, isPresented: $showingPasswordReset)
        }
    }

}

#Preview {
    LoginView()
        .environment(AuthViewModel())
}
