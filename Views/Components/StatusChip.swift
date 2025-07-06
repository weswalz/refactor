//
//  StatusChip.swift
//  LED MESSENGER
//
//  Connection status indicator with reconnect functionality
//  STRATEGIC FIX: Simplified approach without problematic availability constraints
//

import SwiftUI

struct StatusChip: View {
    @Environment(AppSettings.self) var appSettings
    @State private var isReconnecting = false
    @State private var pulseAnimation = false
    
    // STRATEGIC FIX: Direct access to OSCService without complex casting
    private var connectionState: OSCConnectionState {
        if let oscService = appSettings.oscService as? OSCService {
            return oscService.connectionState
        }
        // Fallback: Determine state from settings
        return appSettings.isConfigured ? .connected : .disconnected
    }
    
    private var oscService: (any OSCServiceProtocol)? {
        appSettings.oscService
    }
    
    var body: some View {
        HStack(spacing: 8) {
            // Status indicator with icon and text
            Label(connectionState.rawValue, systemImage: iconName)
                .labelStyle(.titleAndIcon)
                .font(.caption2.bold())
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(Material.thick, in: Capsule())
                .foregroundStyle(statusColor)
                .overlay(
                    // Pulse animation when connecting
                    Circle()
                        .stroke(statusColor.opacity(0.3), lineWidth: pulseAnimation ? 8 : 0)
                        .scaleEffect(pulseAnimation ? 2 : 1)
                        .opacity(pulseAnimation ? 0 : 1)
                        .animation(
                            connectionState == OSCConnectionState.connecting ?
                            Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: false) : .default,
                            value: pulseAnimation
                        )
                        .allowsHitTesting(false)
                )
            
            // Reconnect button (only shown when disconnected)
            if connectionState == OSCConnectionState.disconnected {
                Button(action: reconnect) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption.bold())
                            .rotationEffect(.degrees(isReconnecting ? 360 : 0))
                            .animation(
                                isReconnecting ? .linear(duration: 1).repeatForever(autoreverses: false) : .default,
                                value: isReconnecting
                            )
                        
                        Text("Reconnect")
                            .font(.caption.bold())
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.purple.opacity(0.2))
                            .overlay(
                                Capsule()
                                    .stroke(Color.purple, lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
                .disabled(isReconnecting)
                .opacity(isReconnecting ? 0.6 : 1)
            }
        }
        .onAppear {
            updatePulseAnimation()
        }
        .onReceive(Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()) { _ in
            // Periodically update the connection state display
            updatePulseAnimation()
        }
    }
    
    private var iconName: String {
        switch connectionState {
        case .connected:
            return "circle.fill"
        case .connecting:
            return "circle.dotted"
        case .disconnected:
            return "circle.slash"
        }
    }
    
    private var statusColor: Color {
        switch connectionState {
        case .connected:
            return .green
        case .connecting:
            return .orange
        case .disconnected:
            return .red
        }
    }
    
    private func updatePulseAnimation() {
        let shouldPulse = (connectionState == OSCConnectionState.connecting)
        if pulseAnimation != shouldPulse {
            pulseAnimation = shouldPulse
        }
    }
    
    private func reconnect() {
        guard let oscService = oscService else { 
            print("⚠️ StatusChip: No OSC service available for reconnection")
            return 
        }
        
        isReconnecting = true
        print("🔄 StatusChip: Initiating reconnection...")
        
        Task { @MainActor in
            // Use the modern OSCService reconnect method if available
            if let modernOscService = oscService as? OSCService {
                await modernOscService.reconnect()
            } else {
                // Fallback: Force reconfigure the service
                let config = OSCConfiguration(
                    host: appSettings.oscHost,
                    port: appSettings.oscPort,
                    layer: appSettings.layer,
                    clipCount: appSettings.clipCount,
                    clearClip: appSettings.startSlot + appSettings.clipCount
                )
                await oscService.configure(config)
            }
            
            // 2025 SwiftUI: Direct assignment on MainActor
            isReconnecting = false
            print("✅ StatusChip: Reconnection attempt completed")
        }
    }
}

// Simple version for displaying other info (like IP:Port)
struct InfoChip: View {
    let text: String
    let icon: String = "network"
    let color: Color = .secondary
    
    var body: some View {
        Label(text, systemImage: icon)
            .labelStyle(.titleAndIcon)
            .font(.caption2.bold())
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(Material.thick, in: Capsule())
            .foregroundStyle(color)
    }
}

#Preview("Connection Status") {
    VStack(spacing: 20) {
        Text("Connection States:")
            .font(.headline)
        
        StatusChip()
            .environment(AppSettings())
        
        Text("Info Display:")
            .font(.headline)
        
        InfoChip(text: "192.168.1.250:2269")
    }
    .padding()
}
