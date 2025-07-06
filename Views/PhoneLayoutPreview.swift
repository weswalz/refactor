//
//  PhoneLayoutPreview.swift
//  LED MESSENGER
//
//  Preview toggle for iPhone layout without affecting core app
//  Created: June 15, 2025
//

import SwiftUI

struct PhoneLayoutPreview: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(QueueViewModel.self) var queueVM
    @Environment(DashboardViewModel.self) var dashboardVM
    @Environment(AppSettings.self) var appSettings
    
    @State private var showingPreview = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "iphone")
                        .font(.system(size: 60))
                        .foregroundStyle(.purple)
                    
                    Text("iPhone Layout Preview")
                        .font(.title2.bold())
                    
                    Text("See how LED Messenger would look on iPhone using iOS 18's latest SwiftUI components")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Feature highlights
                VStack(alignment: .leading, spacing: 16) {
                    FeatureRow(
                        icon: "tab.selection",
                        title: "Adaptive Tab Navigation",
                        description: "iOS 18 TabView with sidebar on iPad, bottom tabs on iPhone"
                    )
                    
                    FeatureRow(
                        icon: "hand.tap",
                        title: "Touch Optimized",
                        description: "Haptic feedback, pull-to-refresh, and compact layouts"
                    )
                    
                    FeatureRow(
                        icon: "rectangle.3.group",
                        title: "Modern Components",
                        description: "Enhanced scroll views, size class adaptation, and iOS 18 features"
                    )
                    
                    FeatureRow(
                        icon: "shield.checkered",
                        title: "Safe Preview",
                        description: "Your main app remains unchanged - this is just a preview"
                    )
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 12) {
                    Button("Preview iPhone Layout") {
                        showingPreview = true
                    }
                    .buttonStyle(PreviewButtonStyle())
                    
                    Button("Back to Main App") {
                        dismiss()
                    }
                    .buttonStyle(SecondaryPreviewButtonStyle())
                }
                .padding(.horizontal)
            }
            .padding()
            .navigationTitle("Layout Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showingPreview) {
            PhoneAdaptiveView()
                .environment(queueVM)
                .environment(dashboardVM)
                .environment(appSettings)
                .overlay(alignment: .topTrailing) {
                    Button("Exit Preview") {
                        showingPreview = false
                    }
                    .buttonStyle(ExitPreviewButtonStyle())
                    .padding()
                }
        }
    }
}

// MARK: - Feature Row Component
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.purple)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Button Styles
struct PreviewButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.purple)
                    .shadow(color: .purple.opacity(0.3), radius: 8, y: 4)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryPreviewButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .stroke(.white.opacity(0.2), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct ExitPreviewButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(.black.opacity(0.7))
                    .stroke(.white.opacity(0.3), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Preview
#Preview {
    let appSettings = AppSettings()
    let oscService = OSCService()
    let queueManager = QueueManager()
    let queueViewModel = QueueViewModel(queueManager: queueManager, oscService: oscService, appSettings: appSettings)
    
    return PhoneLayoutPreview()
        .environment(queueViewModel)
        .environment(DashboardViewModel())
        .environment(appSettings)
}
