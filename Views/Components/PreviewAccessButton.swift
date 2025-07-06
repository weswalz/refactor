//
//  PreviewAccessButton.swift
//  LED MESSENGER
//
//  Simple button to access iPhone layout preview
//  Add this to your existing settings or header
//

import SwiftUI

struct PreviewAccessButton: View {
    @State private var showingPreview = false
    
    var body: some View {
        Button(action: {
            showingPreview = true
        }) {
            HStack(spacing: 8) {
                Image(systemName: "iphone")
                    .font(.system(size: 16, weight: .medium))
                
                Text("iPhone Preview")
                    .font(.caption.bold())
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(.purple.opacity(0.8))
                    .stroke(.purple, lineWidth: 1)
            )
        }
        .sheet(isPresented: $showingPreview) {
            PhoneLayoutPreview()
        }
    }
}

// MARK: - Integration Examples

// Example 1: Add to your existing DashboardHeaderView
extension DashboardHeaderView {
    var withPreviewButton: some View {
        HStack {
            // Your existing header content
            self
            
            Spacer()
            
            // Add preview button
            PreviewAccessButton()
        }
    }
}

// Example 2: Add to your settings views
struct SettingsPreviewSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("App Store Expansion")
                .font(.headline)
                .foregroundStyle(.primary)
            
            Text("Preview how LED Messenger would look on iPhone to reach more users in the App Store.")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            PreviewAccessButton()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        )
    }
}

#Preview("Preview Button") {
    PreviewAccessButton()
        .padding()
        .background(Color.black)
}

#Preview("Settings Section") {
    SettingsPreviewSection()
        .padding()
        .background(Color.black)
}
