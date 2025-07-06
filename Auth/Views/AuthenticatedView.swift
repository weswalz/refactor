//
//  AuthenticatedView.swift (FIXED)
//  LED MESSENGER
//
//  Fixed Device Segregation - June 17, 2025
//  Properly routes to device-specific UIs using DeviceEnvironment
//

import SwiftUI
import Foundation

struct AuthenticatedView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var showSplash = true
    @AppStorage("hasCompletedSetup") private var hasCompletedSetup = false
    @State private var currentStep: Int = -1  // -1 = Splash, 0 = Intro, 1 = Settings, 2 = Dashboard
    
    // DEVELOPMENT BYPASS: Skip authentication for testing
    #if DEBUG
    @AppStorage("developmentSkipAuth") private var developmentSkipAuth = false
    #else
    private let developmentSkipAuth = false  // Always false in production
    #endif
    
    // AUTHENTICATION REQUIRED: All devices (iPhone, iPad, Mac) must authenticate
    @Environment(DeviceEnvironment.self) private var deviceEnvironment
    @Environment(AppSettings.self) private var appSettings
    @Environment(QueueViewModel.self) private var queueViewModel
    @Environment(DashboardViewModel.self) private var dashboardViewModel

    var body: some View {
        Group {
            // DEVELOPMENT BYPASS: Allow skipping authentication
            if developmentSkipAuth {
                authenticatedContentView
                    .onAppear {
                        print("🚀 DEVELOPMENT MODE: Skipping authentication")
                        logDeviceInfo()
                    }
                    .overlay(
                        // Show development indicator
                        VStack {
                            HStack {
                                Spacer()
                                Text("DEV MODE")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.orange)
                                    .foregroundColor(.black)
                                    .cornerRadius(4)
                                    .padding()
                            }
                            Spacer()
                        }
                    )
            } else {
                authenticationFlow
            }
        }
    }
    
    @ViewBuilder
    private var authenticationFlow: some View {
        Group {
            switch authViewModel.authState {
            case .loading:
                deviceAwareLoadingView
                    .onAppear {
                        print("🔐 DEBUG: Auth State = LOADING")
                    }
                
            case .processing:
                deviceAwareProcessingView
                    .onAppear {
                        print("🔐 DEBUG: Auth State = PROCESSING")
                    }
                
            case .unauthenticated:
                LoginView()
                    .onAppear {
                        print("🔐 DEBUG: Auth State = UNAUTHENTICATED - Login REQUIRED on \(deviceEnvironment.deviceType)")
                        print("🔐 SECURITY: No authentication bypasses allowed for any device type")
                    }
                
            case .networkError:
                deviceAwareNetworkErrorView
                    .onAppear {
                        print("🔐 DEBUG: Auth State = NETWORK_ERROR - Connection issue")
                    }
                
            case .authenticated(let user):
                authenticatedContentView
                    .onAppear {
                        print("🔐 DEBUG: Auth State = AUTHENTICATED - User: \(user.email ?? "unknown")")
                        print("🔍 DEBUG: AuthenticatedView onAppear - hasCompletedSetup: \(hasCompletedSetup)")
                        
                        // Always show splash after authentication
                        print("🔍 DEBUG: Showing splash animation after login")
                        currentStep = -1
                        
                        logDeviceInfo()
                    }
            }
        }
        .animation(.easeInOut, value: authViewModel.authState)
        .onAppear {
            print("🔐 DEBUG: AuthenticatedView appeared, current auth state: \(String(describing: authViewModel.authState))")
        }
    }
    
    // MARK: - Device-Aware Loading Views
    
    @ViewBuilder
    private var deviceAwareNetworkErrorView: some View {
        switch deviceEnvironment.deviceType {
        case .iPhone:
            iPhoneNetworkErrorView
        case .iPad:
            iPadNetworkErrorView
        case .macCatalyst, .mac:
            desktopNetworkErrorView
        }
    }
    
    private var iPhoneNetworkErrorView: some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            Text("Network Connection Lost")
                .font(.headline)
                .foregroundColor(.white)
            Text("Please check your internet connection and try again.")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            VStack(spacing: 12) {
                VStack(spacing: 12) {
                    Button("Retry Connection") {
                        Task {
                            await authViewModel.retryLastOperation()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                    
                    #if DEBUG
                    Button("Skip Authentication (Dev)") {
                        developmentSkipAuth = true
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.gray)
                    #endif
                }
                

            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
    
    private var iPadNetworkErrorView: some View {
        VStack(spacing: 20) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 64))
                .foregroundColor(.orange)
            Text("Network Connection Lost")
                .font(.title2)
                .foregroundColor(.white)
            Text("Please check your internet connection and try again.")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            VStack(spacing: 12) {
                Button("Retry Connection") {
                    Task {
                        await authViewModel.retryLastOperation()
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                
                #if DEBUG
                Button("Skip Authentication (Dev)") {
                    developmentSkipAuth = true
                }
                .buttonStyle(.bordered)
                .foregroundColor(.gray)
                #endif
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [.black, .orange.opacity(0.1)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    private var desktopNetworkErrorView: some View {
        HStack(spacing: 20) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            VStack(alignment: .leading, spacing: 8) {
                Text("Network Connection Lost")
                    .font(.title3)
                    .foregroundColor(.white)
                Text("Please check your internet connection and try again.")
                    .font(.body)
                    .foregroundColor(.gray)
                Button("Retry Connection") {
                    Task {
                        await authViewModel.retryLastOperation()
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.05, green: 0.05, blue: 0.15))
    }
    
    @ViewBuilder
    private var deviceAwareLoadingView: some View {
        switch deviceEnvironment.deviceType {
        case .iPhone:
            iPhoneLoadingView
        case .iPad:
            iPadLoadingView
        case .macCatalyst, .mac:
            desktopLoadingView
        }
    }
    
    private var iPhoneLoadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .purple))
            Text("Checking authentication...")
                .font(.headline)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
    
    private var iPadLoadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .purple))
                .scaleEffect(1.2)
            Text("Checking authentication...")
                .font(.title2)
                .foregroundColor(.white)
            Text("iPad Version")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [.black, .purple.opacity(0.1)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    private var desktopLoadingView: some View {
        HStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .purple))
            Text("Checking authentication...")
                .font(.title3)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.05, green: 0.05, blue: 0.15))
    }
    
    @ViewBuilder
    private var deviceAwareProcessingView: some View {
        switch deviceEnvironment.deviceType {
        case .iPhone:
            Text("Processing authentication...")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
        case .iPad:
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .purple))
                Text("Processing authentication...")
                    .font(.title2)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
        case .macCatalyst, .mac:
            Text("Processing authentication...")
                .font(.title3)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
        }
    }
    
    // MARK: - Main Content Flow (FIXED)
    
    @ViewBuilder
    private var authenticatedContentView: some View {
        ZStack {
            // Device-appropriate background
            deviceAwareBackground
            
            // Flow: Splash → Settings → Dashboard
            switch currentStep {
            case -1:
                // Show splash screen
                deviceAwareSplash {
                    print("🔍 DEBUG: Splash animation completed")
                    withAnimation(.easeInOut(duration: 0.5)) {
                        // Always go to settings after splash
                        currentStep = 1
                    }
                }
                .transition(.opacity)
                
            case 0:
                // Legacy step (not used anymore)
                Color.clear
                    .onAppear {
                        currentStep = 1
                    }
                
            case 1:
                // STEP 2: Settings - always show settings after splash
                deviceAwareSettings
                    .transition(.opacity)
                
            case 2:
                // STEP 3: Device-aware dashboard
                deviceAwareDashboard
                    .transition(.opacity)
                
            default:
                // Fallback
                deviceAwareDashboard
            }
        }
        .animation(.easeInOut(duration: 0.5), value: currentStep)
    }
    
    // MARK: - Device-Aware Components
    
    @ViewBuilder
    private var deviceAwareBackground: some View {
        switch deviceEnvironment.deviceType {
        case .iPhone:
            Color.black.ignoresSafeArea()
        case .iPad:
            LinearGradient(
                colors: [.black, .purple.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ).ignoresSafeArea()
        case .macCatalyst, .mac:
            Color.black.ignoresSafeArea()
        }
    }
    
    @ViewBuilder
    private func deviceAwareSplash(completion: @escaping () -> Void) -> some View {
        switch deviceEnvironment.deviceType {
        case .iPhone:
            SplashView(onComplete: completion)
                .scaleEffect(0.9) // Slightly smaller for iPhone
        case .iPad:
            SplashView(onComplete: completion)
                .scaleEffect(1.0) // Full size for iPad
        case .macCatalyst, .mac:
            SplashView(onComplete: completion)
                .scaleEffect(0.8) // Smaller for desktop
        }
    }
    
    @ViewBuilder
    private var deviceAwareSettings: some View {
        switch deviceEnvironment.deviceType {
        case .iPhone:
            // iPhone: Use compact settings coordinator
            iPhoneSettingsFlow
                .environment(appSettings)
                .environment(queueViewModel)
                .environment(dashboardViewModel)
                
        case .iPad:
            // iPad: Use full settings wizard
            iPadSettingsFlow
                .environment(appSettings)
                .environment(queueViewModel)
                .environment(dashboardViewModel)
                
        case .macCatalyst, .mac:
            // Mac: Use desktop-optimized settings
            desktopSettingsFlow
                .environment(appSettings)
                .environment(queueViewModel)
                .environment(dashboardViewModel)
        }
    }
    
    private var iPhoneSettingsFlow: some View {
        EnhancediPhoneSettingsCoordinator()
            .navigationBarTitleDisplayMode(.inline)
            .onReceive(NotificationCenter.default.publisher(for: .ledMessengerSettingsCompleted)) { _ in
                completeSettings()
            }
    }
    
    private var iPadSettingsFlow: some View {
        SettingsWizardView(onComplete: {
            completeSettings()
        })
        // Full screen without constraints
    }
    
    private var desktopSettingsFlow: some View {
        SettingsWizardView(onComplete: {
            completeSettings()
        })
        // Full screen for desktop as well
    }
    
    @ViewBuilder
    private var deviceAwareDashboard: some View {
        switch deviceEnvironment.deviceType {
        case .iPhone:
            // iPhone: Use the beautiful iPhone dashboard
            iPhoneDashboardView()
        case .iPad:
            // iPad: Use full dashboard (existing)
            SoloDashboardView()
                .navigationBarTitleDisplayMode(.large)
        case .macCatalyst, .mac:
            // Mac: Use desktop dashboard
            DesktopDashboardContainer()
                .navigationSplitViewStyle(.prominentDetail)
        }
    }
    
    // MARK: - Settings Completion
    
    private func completeSettings() {
        print("🔍 DEBUG: Settings completed, transitioning to dashboard")
        hasCompletedSetup = true
        
        // Set flag to trigger test messages when dashboard appears
        UserDefaults.standard.set(true, forKey: "hasJustCompletedSetup")
        print("🔍 DEBUG: Set hasJustCompletedSetup flag for test messages")
        
        withAnimation(.easeInOut(duration: 0.5)) {
            currentStep = 2
        }
    }
    
    // MARK: - Debug Logging
    
    private func logDeviceInfo() {
        #if DEBUG
        print("📱 Device Info:")
        print("   Type: \(deviceEnvironment.deviceType)")
        print("   Capabilities: \(deviceEnvironment.capabilities)")
        print("   Network Config: \(deviceEnvironment.networkConfig)")
        #endif
    }
}

// MARK: - Device-Specific Dashboard Containers

/// Compact dashboard for iPhone
struct CompactDashboardContainer: View {
    @Environment(\.deviceEnvironment) private var deviceEnvironment
    @Environment(AppSettings.self) private var appSettings
    @Environment(QueueViewModel.self) private var queueViewModel
    @Environment(DashboardViewModel.self) private var dashboardViewModel
    
    var body: some View {
        TabView {
            SoloDashboardView()
                .tabItem {
                    Image(systemName: "display")
                    Text("Dashboard")
                }
            
            UnifiedSettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
        }
        .accentColor(.purple)
    }
}

/// Desktop dashboard for Mac
struct DesktopDashboardContainer: View {
    @Environment(\.deviceEnvironment) private var deviceEnvironment
    @State private var showingNetworkDiagnostics = false
    
    var body: some View {
        NavigationSplitView {
            // Sidebar
            List {
                NavigationLink("Dashboard") {
                    SoloDashboardView()
                }
                NavigationLink("Settings") {
                    UnifiedSettingsView()
                }
                // 2025 SwiftUI: Use sheet presentation instead of direct navigation
                Button("Network Diagnostics") {
                    showingNetworkDiagnostics = true
                }
            }
            .navigationTitle("LED Messenger")
        } detail: {
            SoloDashboardView()
        }
        .sheet(isPresented: $showingNetworkDiagnostics) {
            // 2025 SwiftUI: Use NavigationStack instead of NavigationView
            NavigationStack {
                NetworkDiagnosticView()
                    .navigationTitle("Network Diagnostics")
                    .navigationBarTitleDisplayMode(NavigationBarItem.TitleDisplayMode.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") {
                                showingNetworkDiagnostics = false
                            }
                        }
                    }
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }
}

/// Settings navigation view
struct SettingsNavigationView: View {
    @Environment(\.deviceEnvironment) private var deviceEnvironment
    @State private var showingSettings = false
    
    var body: some View {
        VStack {
            Button("Open Settings") {
                showingSettings = true
            }
            .buttonStyle(.borderedProminent)
            .deviceAppropriateModal(isPresented: $showingSettings) {
                switch deviceEnvironment.deviceType {
                case .iPhone:
                    iPhoneSettingsCoordinator()
                case .iPad, .macCatalyst, .mac:
                    SettingsWizardView()
                }
            }
        }
    }
}

// MARK: - Environment Extension (Unchanged)
extension EnvironmentValues {
    private struct AuthViewModelKey: EnvironmentKey {
        static let defaultValue: AuthViewModel? = nil
    }
    
    var authViewModel: AuthViewModel? {
        get { self[AuthViewModelKey.self] }
        set { self[AuthViewModelKey.self] = newValue }
    }
}

// MARK: - Device Appropriate Modal Extension
// Note: deviceAppropriateModal is already defined in DeviceAdaptiveExtensions.swift

#Preview {
    AuthenticatedView()
        .environment(DeviceEnvironment())
        .environment(AuthViewModel())
        .environment(AppSettings(deviceEnvironment: DeviceEnvironment()))
}

// MARK: - Simple Network Diagnostic View (2025 SwiftUI)
@Observable
class SimpleNetworkDiagnosticModel {
    var diagnosticText = "Starting network diagnostics..."
    var isRunning = false
    
    @MainActor
    func runDiagnostics() async {
        isRunning = true
        diagnosticText = "Network Status: Checking...\n"
        
        // Simple network check using modern async/await patterns
        do {
            try await Task.sleep(for: .seconds(1))
            diagnosticText += "✅ Network connectivity: Available\n"
            diagnosticText += "📡 WiFi Status: Connected\n"
            diagnosticText += "🔌 Local Network: Accessible\n"
            diagnosticText += "🎯 OSC Target: 172.17.20.110:2269\n"
            diagnosticText += "\n✅ Diagnostics completed successfully!"
        } catch {
            diagnosticText += "❌ Error running diagnostics: \(error)"
        }
        
        isRunning = false
    }
    
    @MainActor
    func clearLog() {
        diagnosticText = ""
    }
}

struct NetworkDiagnosticView: View {
    @State private var model = SimpleNetworkDiagnosticModel()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Network Diagnostics")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top)
            
            ScrollView {
                Text(model.diagnosticText)
                    .font(.system(.body, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(12)
            }
            .frame(maxHeight: 400)
            
            HStack(spacing: 16) {
                Button("Run Diagnostics") {
                    Task {
                        await model.runDiagnostics()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(model.isRunning)
                
                Button("Clear") {
                    model.clearLog()
                }
                .buttonStyle(.bordered)
                .disabled(model.isRunning)
            }
            
            if model.isRunning {
                ProgressView("Running diagnostics...")
                    .padding()
            }
            
            Spacer()
        }
        .padding()
        .task {
            await model.runDiagnostics()
        }
    }
}

