//
//  LEDMessengerApp.swift (AUTHENTICATION REQUIRED)
//  LED MESSENGER
//
//  Fixed Device Segregation and Networking - June 17, 2025
//  SECURITY UPDATE - June 21, 2025
//  
//  CRITICAL SECURITY REQUIREMENT:
//  Authentication is MANDATORY on ALL devices:
//  - iPhone: MUST authenticate
//  - iPad: MUST authenticate  
//  - Mac Catalyst: MUST authenticate
//  - macOS: MUST authenticate
//  
//  NO BYPASSES OR DEVICE-SPECIFIC SKIPS ALLOWED
//  All users must sign in through Supabase authentication
//

import SwiftUI
import Observation
import Foundation
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

@main
struct LEDMessengerApp: App {
    
    // MARK: - Device Environment (New for 2025)
    @State private var deviceEnvironment = DeviceEnvironment()
    
    // MARK: - Navigation Router (iOS 18)
    @State private var navigationRouter = NavigationRouter()
    
    // MARK: - Shared Authentication
    @State private var authViewModel = AuthViewModel()
    
    // MARK: - App State
    @AppStorage("hasCompletedSetup") private var hasCompletedSetup = false
    @State private var currentStep: Int = 0
    @State private var isClientConnected = false
    
    // MARK: - Authentication State
    @State private var isProcessingAuth = false
    @State private var authProcessingMessage = ""
    @State private var showAuthFeedback = false
    @State private var showPasswordReset = false
    
    #if canImport(UIKit) && !targetEnvironment(macCatalyst)
    @State private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    #endif
    
    // MARK: - Core Components (Device-Aware)
    @State private var dashboardVM = DashboardViewModel()
    private let sharedAppSettings: AppSettings
    private let sharedQueueManager = QueueManager()
    @State private var appSettings: AppSettings
    @State private var queueVM: QueueViewModel
    
    init() {
        // Initialize device environment FIRST
        let deviceEnv = DeviceEnvironment()
        _deviceEnvironment = State(initialValue: deviceEnv)
        
        // Initialize Supabase
        _ = SupabaseManager.shared
        
        // Create device-aware AppSettings
        let settings = AppSettings(deviceEnvironment: deviceEnv)
        self.sharedAppSettings = settings
        _appSettings = State(initialValue: settings)
        
        // Remove skip logic - let AuthenticatedView handle the flow
        
        // Create device-aware QueueViewModel
        let queueViewModel = QueueViewModel(
            queueManager: sharedQueueManager,
            oscService: settings.oscService,
            appSettings: settings
        )
        _queueVM = State(initialValue: queueViewModel)
        
        print("🚀 LED MESSENGER initialized for \(deviceEnv.deviceType)")
        print("📱 Device capabilities: \(deviceEnv.capabilities)")
        
        // SECURITY: Verify authentication is required on ALL devices
        print("🔐 SECURITY: Authentication REQUIRED on \(deviceEnv.deviceType)")
        print("🔐 SECURITY: No authentication bypasses allowed")
    }
    
    @Environment(\.scenePhase) private var scenePhase
    
    // MARK: - Scene
    var body: some Scene {
        WindowGroup {
            ZStack {
                deviceAwareRootView
                    .onAppear {
                        setupDeviceSpecificConfiguration()
                        print("🚀 LED MESSENGER Started for \(deviceEnvironment.deviceType)")
                    }
                    .onOpenURL { url in
                        handleAuthenticationURL(url)
                    }
#if os(macOS)
                    .frame(minWidth: 430, idealWidth: 430, maxWidth: 430,
                           minHeight: 932, idealHeight: 932, maxHeight: 932)
#endif
                    // FIXED: Inject device environment first, then other dependencies
                    .environment(deviceEnvironment)
                    .environment(navigationRouter)
                    .environment(authViewModel)
                    .environment(appSettings)
                    .environment(queueVM)
                    .environment(dashboardVM)
                
                // Authentication processing overlay
                if isProcessingAuth {
                    authProcessingOverlay
                }
            }
        }
#if os(macOS)
        .windowResizability(.contentSize)
#endif
        .onChange(of: scenePhase) { _, newPhase in
            handleScenePhaseChange(newPhase)
        }
    }
    
    // MARK: - Device-Aware Root View (AUTHENTICATION REQUIRED ON ALL DEVICES)
    @ViewBuilder
    private var deviceAwareRootView: some View {
        if showPasswordReset {
            PasswordResetView(isPresented: $showPasswordReset)
                .environment(deviceEnvironment)
                .environment(navigationRouter)
                .environment(authViewModel)
                .environment(appSettings)
                .environment(queueVM)
                .environment(dashboardVM)
        } else {
            // CRITICAL: Authentication is REQUIRED on ALL devices (iPhone, iPad, Mac)
            // No bypasses or device-specific skips allowed
            AuthenticatedView()
                .environment(deviceEnvironment)
                .environment(navigationRouter)
                .environment(authViewModel)
                .environment(appSettings)
                .environment(queueVM)
                .environment(dashboardVM)
        }
    }
    
    // MARK: - Device-Specific Setup (NEW)
    private func setupDeviceSpecificConfiguration() {
        switch deviceEnvironment.deviceType {
        case .iPhone:
            setupiPhoneConfiguration()
        case .iPad:
            setupiPadConfiguration()
        case .macCatalyst:
            setupMacCatalystConfiguration()
        case .mac:
            setupMacConfiguration()
        }
    }
    
    private func setupiPhoneConfiguration() {
        print("📱 Configuring for iPhone")
        // iPhone-specific networking settings
        let networkSettings = deviceEnvironment.getNetworkingSettings()
        appSettings.applyNetworkingSettings(networkSettings)
        
        // iPhone-specific UI preferences
        #if canImport(UIKit)
        UIApplication.shared.isIdleTimerDisabled = false // Allow screen to dim
        #endif
    }
    
    private func setupiPadConfiguration() {
        print("📱 Configuring for iPad")
        // iPad-specific networking settings (more stable, longer timeouts)
        let networkSettings = deviceEnvironment.getNetworkingSettings()
        appSettings.applyNetworkingSettings(networkSettings)
        
        // iPad-specific UI preferences
        #if canImport(UIKit)
        UIApplication.shared.isIdleTimerDisabled = true // Keep screen on for LED control
        #endif
    }
    
    private func setupMacCatalystConfiguration() {
        print("💻 Configuring for Mac Catalyst")
        // Mac Catalyst networking (desktop-class)
        let networkSettings = deviceEnvironment.getNetworkingSettings()
        appSettings.applyNetworkingSettings(networkSettings)
    }
    
    private func setupMacConfiguration() {
        print("🖥️ Configuring for macOS")
        // macOS networking (full desktop networking)
        let networkSettings = deviceEnvironment.getNetworkingSettings()
        appSettings.applyNetworkingSettings(networkSettings)
    }
    
    // MARK: - Authentication Processing Overlay (Unchanged)
    @ViewBuilder
    private var authProcessingOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                
                Text("Processing Authentication...")
                    .font(.headline)
                    .foregroundColor(.white)
                
                if !authProcessingMessage.isEmpty {
                    Text(authProcessingMessage)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            .padding(40)
            .background(Color.black.opacity(0.8))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.purple.opacity(0.5), lineWidth: 1)
            )
        }
        .animation(.easeInOut, value: isProcessingAuth)
    }
    
    // MARK: - URL Handling (Device-Aware)
    private func handleAuthenticationURL(_ url: URL) {
        print("🔗 Received URL on \(deviceEnvironment.deviceType): \(url)")
        
        // Device-specific URL handling
        switch deviceEnvironment.deviceType {
        case .iPhone:
            handleiPhoneURL(url)
        case .iPad:
            handleiPadURL(url)
        case .macCatalyst, .mac:
            handleDesktopURL(url)
        }
    }
    
    private func handleiPhoneURL(_ url: URL) {
        // iPhone: Show compact processing UI
        isProcessingAuth = true
        authProcessingMessage = "Processing on iPhone..."
        processAuthenticationURL(url)
    }
    
    private func handleiPadURL(_ url: URL) {
        // iPad: Show full-screen processing UI
        isProcessingAuth = true
        authProcessingMessage = "Processing on iPad..."
        processAuthenticationURL(url)
    }
    
    private func handleDesktopURL(_ url: URL) {
        // Desktop: Show sheet processing UI
        isProcessingAuth = true
        authProcessingMessage = "Processing on Mac..."
        processAuthenticationURL(url)
    }
    
    private func processAuthenticationURL(_ url: URL) {
        guard url.scheme == "ledmessenger" else {
            authProcessingMessage = "Invalid URL scheme"
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.isProcessingAuth = false
            }
            return
        }
        
        let isPasswordRecovery = url.absoluteString.contains("type=recovery") || 
                                url.absoluteString.contains("type=invite") ||
                                (url.fragment?.contains("type=recovery") ?? false)
        
        if isPasswordRecovery {
            showPasswordReset = true
        }
        
        bringAppToForeground()
        
        Task { @MainActor in
            do {
                guard let auth = SupabaseManager.shared.auth else {
                    throw AuthenticationError.noAuthClient
                }
                
                authProcessingMessage = "Validating with Supabase..."
                try await auth.session(from: url)
                authProcessingMessage = "Authentication successful!"
                
                try await Task.sleep(for: .seconds(1.5))
                isProcessingAuth = false
                authProcessingMessage = ""
                
                await refreshAuthenticationState()
                
            } catch {
                authProcessingMessage = "Auth failed: \(error.localizedDescription)"
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    self.isProcessingAuth = false
                    self.authProcessingMessage = ""
                }
            }
        }
    }
    
    // MARK: - App Lifecycle (Device-Aware)
    private func bringAppToForeground() {
        switch deviceEnvironment.deviceType {
        case .iPhone, .iPad:
            #if canImport(UIKit)
            DispatchQueue.main.async {
                if UIApplication.shared.connectedScenes.first is UIWindowScene {
                    UIApplication.shared.requestSceneSessionActivation(nil, userActivity: nil, options: nil, errorHandler: nil)
                }
            }
            #endif
        case .macCatalyst, .mac:
            #if canImport(AppKit)
            DispatchQueue.main.async {
                NSApp.activate(ignoringOtherApps: true)
            }
            #endif
        }
    }
    
    private func refreshAuthenticationState() async {
        guard let auth = SupabaseManager.shared.auth else { return }
        
        do {
            try await auth.refreshSession()
            print("🔄 Authentication state refreshed for \(deviceEnvironment.deviceType)")
        } catch {
            print("⚠️ Failed to refresh auth state: \(error)")
        }
    }
    
    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .active:
            print("📱 \(deviceEnvironment.deviceType) app became active")
            handleActiveState()
            
        case .inactive:
            print("📱 \(deviceEnvironment.deviceType) app became inactive")
            
        case .background:
            print("📱 \(deviceEnvironment.deviceType) app entered background")
            handleBackgroundState()
            
        @unknown default:
            break
        }
    }
    
    private func handleActiveState() {
        #if canImport(UIKit) && !targetEnvironment(macCatalyst)
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
        #endif
        
        // Device-specific foreground handling
        if let oscService = appSettings.oscService as? OSCService {
            Task {
                await oscService.handleAppWillEnterForeground()
            }
        }
    }
    
    private func handleBackgroundState() {
        // Device-specific background handling
        let networkSettings = deviceEnvironment.getNetworkingSettings()
        
        if networkSettings.backgroundNetworkingAllowed {
            #if canImport(UIKit) && !targetEnvironment(macCatalyst)
            backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "OSCConnectionCleanup") {
                UIApplication.shared.endBackgroundTask(self.backgroundTask)
                self.backgroundTask = .invalid
            }
            #endif
            
            if let oscService = appSettings.oscService as? OSCService {
                Task {
                    await oscService.handleAppDidEnterBackground()
                }
            }
        } else {
            // iPhone: Disconnect immediately to save battery
            if let oscService = appSettings.oscService as? OSCService {
                Task {
                    await oscService.forceDisconnect()
                }
            }
        }
    }
}

// MARK: - Authentication Error Types (Unchanged)
enum AuthenticationError: LocalizedError {
    case noAuthClient
    case invalidURL
    case sessionProcessingFailed
    
    var errorDescription: String? {
        switch self {
        case .noAuthClient:
            return "Authentication client not available"
        case .invalidURL:
            return "Invalid authentication URL"
        case .sessionProcessingFailed:
            return "Failed to process authentication session"
        }
    }
}

