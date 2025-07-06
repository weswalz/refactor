//
//  iPhoneHeaderComponents.swift
//  LED MESSENGER
//
//  iPhone header and navigation components for iOS 18+ SwiftUI
//  Created: June 16, 2025
//

import SwiftUI

// MARK: - iPhone Header (Clean & Centered)
/// Clean, minimal header optimized for iPhone screens
/// Features logo, connection status, and settings access
struct iPhoneHeaderView: View {
    @Environment(AppSettings.self) var appSettings
    @Environment(DashboardViewModel.self) var dashboardVM
    @State private var showingSettings = false
    
    var body: some View {
        HStack {
            // LED Messenger Logo (Clean - no extra text) - LARGER SIZE
            Image("ledmwide35")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 32) // Increased from 20 to 32 (+60% larger)
                .frame(maxWidth: 260) // More space for larger logo
                .accessibilityLabel("LED Messenger Logo")
            
            // Connection Status Dot - positioned 10px to the right of logo
            HStack(spacing: 0) {
                Spacer()
                    .frame(width: 10) // Exactly 10px from logo
                ConnectionStatusDot()
           // Fill remaining space
            }
            
            // Settings Gear
            Button(action: {
                showingSettings = true
                performHapticFeedback()
            }) {
                Image(systemName: "gear")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
                    .frame(width: 44, height: 44) // Ensure proper touch target
                    .accessibilityLabel("Settings")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .frame(minHeight: 44) // Ensure minimum header height
        .sheet(isPresented: $showingSettings) {
            EnhancediPhoneSettingsCoordinator()
        }
    }
    
    /// Provides haptic feedback for user interactions
    private func performHapticFeedback() {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }
}

// MARK: - Status Dot (Color Only)
/// Minimal connection status indicator using color coding
/// Green = Connected, Orange = Connecting, Red = Disconnected
struct ConnectionStatusDot: View {
    @Environment(AppSettings.self) var appSettings
    
    /// Determines status color based on OSC connection state
    private var statusColor: Color {
        // Connect to your actual connection status
        if let oscService = appSettings.oscService as? OSCService {
            switch oscService.connectionState {
            case .connected:
                return .green
            case .connecting:
                return .orange
            case .disconnected:
                return .red.opacity(0.7)
            }
        }
        return .red.opacity(0.7)
    }
    
    var body: some View {
        Circle()
            .fill(statusColor)
            .frame(width: 10, height: 10)
            .shadow(color: statusColor.opacity(0.6), radius: 3, x: 0, y: 1)
            .animation(.easeInOut(duration: 0.3), value: statusColor)
            .accessibilityLabel("Connection Status")
            .accessibilityValue(statusDescription)
    }
    
    /// Provides accessible description of connection status
    private var statusDescription: String {
        switch statusColor {
        case .green: return "Connected"
        case .orange: return "Connecting"
        default: return "Disconnected"
        }
    }
}

// MARK: - iPhone Action Bar (Short & Wide)
/// Primary action bar with Clear and New Message buttons
/// Optimized for iPhone screen width and touch targets
struct iPhoneActionBar: View {
    @Environment(QueueViewModel.self) var queueVM
    @Environment(DashboardViewModel.self) var dashboardVM
    
    var body: some View {
        HStack(spacing: 12) {
            // Clear Button (Secondary)
            Button(action: {
                clearAllMessages()
            }) {
                Text("Clear")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.8))
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.white.opacity(0.1))
                            .stroke(.white.opacity(0.2), lineWidth: 1)
                    )
                    .accessibilityLabel("Clear all messages")
            }
            .disabled(queueVM.messages.isEmpty)
            
            // New Message Button (Primary)
            Button(action: {
                openNewMessageModal()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16))
                    Text("New Message")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.purple)
                        .shadow(color: .purple.opacity(0.4), radius: 6, y: 3)
                )
                .accessibilityLabel("Create new message")
            }
        }
        .padding(.horizontal, 16)
    }
    
    /// Clears all messages with haptic feedback
    private func clearAllMessages() {
        queueVM.clearAllMessages()
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif
    }
    
    /// Opens new message modal with haptic feedback
    private func openNewMessageModal() {
        dashboardVM.showNewMessageModal = true
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }
}

// MARK: - Simplified Instruction Banner
/// Minimal instruction text for user guidance
struct iPhoneInstructionBanner: View {
    var body: some View {
        Text("Queue → Send to LED")
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(.secondary)
            .padding(.vertical, 6)
            .accessibilityLabel("Instructions: Add messages to queue, then send to LED display")
    }
}

// MARK: - ClubKit Footer
/// Attribution footer with link to ClubKit website
struct ClubKitFooter: View {
    var body: some View {
        Link(destination: URL(string: "https://clubkit.io")!) {
            Image("ck40")
                .resizable()
                .frame(width: 18, height: 22)
                .foregroundStyle(.white.opacity(0.6))
                .accessibilityLabel("ClubKit - Visit website")
        }
        .padding(.bottom, 8)
    }
}

#Preview("iPhone Header") {
    VStack {
        iPhoneHeaderView()
        Spacer()
        iPhoneActionBar()
        ClubKitFooter()
    }
    .background(.black)
    .environment(AppSettings())
    .environment(DashboardViewModel())
    .environment(QueueViewModel(queueManager: QueueManager(), oscService: OSCService(), appSettings: AppSettings()))
}
