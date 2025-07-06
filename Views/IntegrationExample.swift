//
//  IntegrationExample.swift
//  LED MESSENGER
//
//  Example showing how to integrate iPhone-optimized settings
//  Created: December 15, 2024
//

import SwiftUI
import Observation

/// Example of how to integrate the new iPhone settings system
/// into your existing LED Messenger app
struct IntegrationExample: View {
    @Environment(AppSettings.self) private var appSettings
    @State private var showingSettings = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("LED Messenger Dashboard")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
                
                Text("Your messages and controls here...")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
                
                Spacer()
                
                // Example integration methods
                VStack(spacing: 16) {
                    
                    // Method 1: Use the adaptive settings button component
                    SettingsButton {
                        print("Settings completed via SettingsButton")
                    }
                    
                    // Method 2: Manual presentation with adaptive sheet
                    Button("Open Settings Manually") {
                        showingSettings = true
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(.purple)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // Method 3: Direct UnifiedSettingsView usage
                    NavigationLink("Push Settings") {
                        UnifiedSettingsView {
                            print("Settings completed via NavigationLink")
                        }
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(.indigo)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .background(.black)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    // Method 4: Toolbar settings button
                    SettingsButton {
                        print("Settings completed via Toolbar")
                    }
                }
            }
        }
        // This automatically detects iPhone vs iPad and shows appropriate interface
        .adaptiveSettingsSheet(isPresented: $showingSettings) {
            print("Settings completed via adaptive sheet")
        }
    }
}

/// Example of updating an existing view to use the new system
struct ExistingViewUpdated: View {
    @State private var showingSettings = false
    
    var body: some View {
        VStack {
            Text("Your Existing Content")
            
            // OLD WAY (this was causing blank screens on iPhone)
            // .sheet(isPresented: $showingSettings) {
            //     SettingsWizardView()
            // }
            
            // NEW WAY (automatically adapts to device)
            Button("Settings") {
                showingSettings = true
            }
        }
        .adaptiveSettingsSheet(isPresented: $showingSettings)
    }
}

/// Example of checking device type manually if needed
struct DeviceDetectionExample: View {
    var body: some View {
        VStack {
            Text("Device Information")
                .font(.title)
            
            Group {
                Text("Is iPhone: \(DeviceDetection.isPhone ? "Yes" : "No")")
                Text("Is iPad: \(DeviceDetection.isPad ? "Yes" : "No")")
                Text("Is Mac Catalyst: \(DeviceDetection.isMacCatalyst ? "Yes" : "No")")
                Text("Is macOS: \(DeviceDetection.isMac ? "Yes" : "No")")
            }
            .font(.subheadline)
            .foregroundStyle(.gray)
            
            Spacer()
            
            // Show different content based on device
            if DeviceDetection.isPhone {
                Text("This is the iPhone-specific content")
                    .foregroundStyle(.green)
            } else {
                Text("This is the iPad/Mac content")
                    .foregroundStyle(.blue)
            }
        }
        .padding()
    }
}

/// Example of custom settings presentation
struct CustomSettingsPresentation: View {
    @State private var showingSettings = false
    
    var body: some View {
        VStack {
            Button("Custom Settings Presentation") {
                showingSettings = true
            }
        }
        .sheet(isPresented: $showingSettings) {
            // You can still use the components directly if needed
            if DeviceDetection.isPhone {
                NavigationStack {
                    iPhoneSettingsCoordinator()
                }
            } else {
                SettingsWizardView()
            }
        }
    }
}

#Preview("Integration Example") {
    IntegrationExample()
        .environment(AppSettings())
}

#Preview("Device Detection") {
    DeviceDetectionExample()
}
