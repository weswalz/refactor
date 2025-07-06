//
//  SoloDashboardView.swift
//  LED MESSENGER
//
//  Dashboard view for Solo mode operation
//  Updated: June 07, 2025 - Removed debug elements, added ClubKit hyperlink
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

// MARK: - Color Extensions
fileprivate extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red:   Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >>  8) & 0xFF) / 255,
            blue:  Double( hex        & 0xFF) / 255,
            opacity: alpha
        )
    }
}

struct SoloDashboardView: View {
    @Environment(QueueViewModel.self) var queueVM
    @Environment(DashboardViewModel.self) var dashboardVM
    @Environment(AppSettings.self) var appSettings
    
    @State private var messageToEdit: Message? = nil
    @State private var showEditModal = false
    @AppStorage("hasJustCompletedSetup") private var hasJustCompletedSetup = false
    
    var body: some View {
        ZStack {
            RadialGradient(
                gradient: Gradient(colors: [Color.purple.opacity(0.45), Color.black]),
                center: .center,
                startRadius: 0,
                endRadius: 700
            )
            .ignoresSafeArea()
            
            mainContent
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: .init(get: { dashboardVM.showNewMessageModal }, set: { dashboardVM.showNewMessageModal = $0 })) {
            NewMessageModal(
                onSubmit: { newMessage in
                    queueVM.enqueue(newMessage)
                    dashboardVM.closeModal()
                },
                onCancel: {
                    dashboardVM.closeModal()
                }
            )
            .environment(appSettings)
            .environment(queueVM)
            .environment(dashboardVM)
        }
        .sheet(isPresented: $showEditModal, onDismiss: {
            messageToEdit = nil
        }) {
            MessageEditSheet(message: $messageToEdit, showEditModal: $showEditModal)
                .environment(appSettings)
                .environment(queueVM)
                .environment(dashboardVM)
        }
    }
    
    private var mainContent: some View {
        VStack(spacing: 0) {
            DashboardHeaderView()
            
            Divider().background(.white.opacity(0.1))
            
            Text("INSTRUCTIONS: Queue message → Send to LED wall")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.vertical, 6)
            
            MessageListView(
                messages: queueVM.messages,
                onDelete: handleDelete,
                onSend: handleSend,
                onEdit: handleEdit
            )
            
            Spacer()
            
            // ClubKit hyperlink button
            Link(destination: URL(string: "https://clubkit.io")!) {
                Image("ck40")
                    .resizable()
                    .frame(width: 24, height: 30)
                    .foregroundStyle(.white)
            }
            .padding(.bottom, 16)
        }
        .padding(.top, 12)
        .onAppear {
            print("📱 SoloDashboardView appeared")
            
            // FIXED: More robust automatic connection with iOS 18 permission handling
            print("🔌 Attempting automatic OSC connection with iOS 18 safeguards...")
            Task {
                // Give the app time to fully initialize before connecting
                try? await Task.sleep(for: .milliseconds(1000))
                
                // Attempt to establish OSC connection with better error handling
                let isConnected = await queueVM.ensureOSCConnection()
                
                if isConnected {
                    print("✅ OSC connection established - waiting for iOS permission settling...")
                    
                    // CRITICAL: Wait for iOS 18 local network permission to settle
                    // The first OSC send triggers permission dialog which can disrupt connection
                    try? await Task.sleep(for: .seconds(3))
                    
                    // Verify connection is still active after permission prompt
                    let stillConnected = await queueVM.ensureOSCConnection()
                    
                    if stillConnected {
                        print("✅ Connection verified stable after permission handling")
                        
                        // Mark connection as validated since it worked
                        await MainActor.run {
                            appSettings.markConnectionAsValidated()
                        }
                        
                        // Send test messages if this is post-setup
                        if shouldSendTestMessages() {
                            print("🔍 Sending test messages with stable connection")
                            // Add small delay before test messages to ensure everything is ready
                            try? await Task.sleep(for: .milliseconds(500))
                            queueVM.sendTestMessagesWithConnection()
                        }
                    } else {
                        print("⚠️ Connection lost after permission handling - user needs to manually reconnect")
                    }
                } else {
                    print("⚠️ Failed to establish initial OSC connection")
                    print("💡 User can manually reconnect or check settings")
                }
            }
        }
        #if canImport(UIKit)
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            Task {
                // iOS/iPad: Only reconnect if connection was previously validated
                if appSettings.hasValidatedConnection {
                    print("📦 App entering foreground, ensuring validated OSC connection...")
                    let isConnected = await queueVM.ensureOSCConnection()
                    if !isConnected {
                        print("⚠️ Failed to reconnect after returning to foreground")
                    }
                } else {
                    print("📦 App entering foreground, but connection not validated - skipping auto-reconnect")
                }
            }
        }
        #elseif canImport(AppKit)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            Task {
                // macOS: Only reconnect if connection was previously validated
                if appSettings.hasValidatedConnection {
                    print("🖥️ App became active, ensuring validated OSC connection...")
                    let isConnected = await queueVM.ensureOSCConnection()
                    if !isConnected {
                        print("⚠️ Failed to reconnect after app became active")
                    }
                } else {
                    print("🖥️ App became active, but connection not validated - skipping auto-reconnect")
                }
            }
        }
        #endif
    }
    
    private func handleDelete(_ clearSlotIndex: Int, _ message: Message) {
        if message.status == .sent || message.status == .delivered {
            // For sent messages (CANCEL button), use the cancelSentMessage method
            // which properly cancels auto-clear timers
            queueVM.cancelSentMessage(message, clearSlotIndex: clearSlotIndex)
        } else {
            // For unsent messages (DELETE button), remove from queue
            queueVM.removeMessage(id: message.id)
        }
    }
    
    private func handleSend(_ message: Message) {
        queueVM.sendMessage(message)
    }
    
    private func handleEdit(_ message: Message) {
        messageToEdit = message
        showEditModal = true
    }
    
    private func shouldSendTestMessages() -> Bool {
        // Only send test messages if we've just completed setup
        print("🔍 DEBUG: shouldSendTestMessages - hasJustCompletedSetup: \(hasJustCompletedSetup)")
        if hasJustCompletedSetup {
            // Reset the flag so test messages only play once
            hasJustCompletedSetup = false
            print("🔍 DEBUG: Resetting hasJustCompletedSetup flag")
            return true
        }
        return false
    }
}

#Preview {
    let appSettings = AppSettings()
    let oscService = OSCService()
    let queueManager = QueueManager()
    let queueViewModel = QueueViewModel(queueManager: queueManager, oscService: oscService, appSettings: appSettings)
    
    return SoloDashboardView()
        .environment(queueViewModel)
        .environment(DashboardViewModel())
        .environment(appSettings)
}
