//
//  UnifiedSettingsView.swift
//  LED MESSENGER
//
//  Unified settings entry point with device-adaptive UI
//  Shows iPhone-optimized interface on iPhone, full interface on iPad
//  Created: December 15, 2024
//

import SwiftUI
import Observation

/// Main entry point for settings that adapts to device type
struct UnifiedSettingsView: View {
    var onComplete: (() -> Void)?
    @Environment(AppSettings.self) private var appSettings
    
    var body: some View {
        Group {
            if DeviceDetection.isPhone {
                // iPhone gets the simplified, optimized interface
                iPhoneSettingsCoordinator()
            } else {
                // iPad and Mac get the full-featured interface
                SettingsWizardView(onComplete: onComplete)
            }
        }
        .onAppear {
            // FIXED: Maintain OSC connection during settings navigation
            if let oscService = appSettings.oscService as? OSCService {
                oscService.maintainConnection()
            }
        }
    }
}

/// Button to present settings that adapts to device
struct SettingsButton: View {
    @State private var showingSettings = false
    var onComplete: (() -> Void)?
    
    var body: some View {
        Button {
            showingSettings = true
        } label: {
            Image(systemName: "gear")
                .font(.title2)
                .foregroundStyle(.white)
        }
        .adaptiveSettingsSheet(isPresented: $showingSettings, onComplete: onComplete)
    }
}

/// Presentation style modifier that adapts to device
struct AdaptiveSettingsPresentation: ViewModifier {
    @Binding var isPresented: Bool
    var onComplete: (() -> Void)?
    @Environment(AppSettings.self) private var appSettings
    
    func body(content: Content) -> some View {
        if DeviceDetection.isPhone {
            content
                .sheet(isPresented: $isPresented) {
                    NavigationStack {
                        iPhoneSettingsCoordinator()
                    }
                    .onAppear {
                        // FIXED: Maintain OSC connection during settings presentation
                        if let oscService = appSettings.oscService as? OSCService {
                            oscService.maintainConnection()
                        }
                    }
                }
        } else {
            content
                .fullScreenCover(isPresented: $isPresented) {
                    SettingsWizardView(onComplete: onComplete)
                        .onAppear {
                            // FIXED: Maintain OSC connection during settings presentation
                            if let oscService = appSettings.oscService as? OSCService {
                                oscService.maintainConnection()
                            }
                        }
                }
        }
    }
}

extension View {
    /// Present settings with device-adaptive presentation style
    func adaptiveSettingsSheet(isPresented: Binding<Bool>, onComplete: (() -> Void)? = nil) -> some View {
        modifier(AdaptiveSettingsPresentation(isPresented: isPresented, onComplete: onComplete))
    }
}

#Preview("iPhone Settings") {
    iPhoneSettingsCoordinator()
        .environment(AppSettings())
}

#Preview("iPad Settings") {
    SettingsWizardView()
        .environment(AppSettings())
}
