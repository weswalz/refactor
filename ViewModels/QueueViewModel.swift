//
//  QueueViewModel.swift
//  LEDMessenger
//
//  Created by Wesley Walz on 5/12/25.
//  Updated by Claude on 5/21/25.
//

import Foundation
import SwiftUI
import Observation
import OSLog

@MainActor
@Observable
public final class QueueViewModel: @unchecked Sendable {
    // Pass through to QueueManager's messages
    public var messages: [Message] {
        queueManager.messages
    }
    public var hasMessages: Bool {
        !messages.isEmpty
    }

    public var currentSlot: Int {
        currentClipIndex
    }
    
    // Public property to check if a message is currently being sent
    public var isSending: Bool {
        currentlySendingMessageId != nil
    }

    // Make startingSlot publicly accessible but privately settable
    // This allows DashboardView to access it but only QueueViewModel can update it
    private(set) var startingSlot: Int = 1
    private var currentClipIndex: Int = 1
    
    // Track the currently sending message ID
    private var currentlySendingMessageId: UUID? = nil
    
    // Track active auto-clear timers by clip index (one timer per clip)
    private var clipTimers: [Int: Task<Void, Never>] = [:]
    
    // Track if we've started sending messages (to preserve rotation state)
    private var hasStartedSending = false
    
    // Track if test messages have been shown to prevent duplicates
    private var hasShownTestMessages = false
    
    // Dependencies
    public let queueManager: QueueManager
    public let oscService: OSCServiceProtocol
    public let appSettings: AppSettings
    private let webhookService = WebhookService()
    // Note: SyncManager removed - P2P functionality can be added later
    
    init(queueManager: QueueManager, oscService: OSCServiceProtocol, appSettings: AppSettings) {
        // 🔧 DEBUG: AppSettings Init
        print("🔧 AppSettings Init - Layer: \(appSettings.layer), StartSlot: \(appSettings.startSlot), ClipCount: \(appSettings.clipCount)")
        
        self.queueManager = queueManager
        self.oscService = oscService
        self.appSettings = appSettings
        
        // Initialize currentClipIndex from appSettings
        self.currentClipIndex = appSettings.startSlot
        self.startingSlot = appSettings.startSlot
        
        // 🎬 DEBUG: QueueViewModel Init
        print("🎬 QueueViewModel Init - CurrentClip: \(currentClipIndex), StartingSlot: \(startingSlot)")
        
        // Set up notification observer for settings changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(settingsChanged),
            name: NSNotification.Name("SettingsChanged"),
            object: nil
        )
    }
    
    @objc private func settingsChanged() {
        refreshFromSettings()
    }

    
    // MARK: - Queue Operations
    
    func enqueue(_ message: Message) {
        Task {
            await queueManager.enqueueAsync(message)
            // Note: P2P sync functionality removed
            
            // Send webhook notification for message added
            if !appSettings.webhookUrl.isEmpty {
                await webhookService.sendWebhook(
                    to: appSettings.webhookUrl,
                    event: .messageAdded,
                    message: message
                )
            }
        }
    }
    
    func removeMessage(id: UUID) {
        // Note: Timer cancellation is now handled per clip, not per message
        
        Task {
            if let index = messages.firstIndex(where: { $0.id == id }) {
                await queueManager.removeMessageAsync(at: index)
                // Note: P2P sync functionality removed
            }
        }
    }
    
    func clearQueue() {
        // Cancel all active clip timers
        for timer in clipTimers.values {
            timer.cancel()
        }
        clipTimers.removeAll()
        
        // Clear the LED wall display before clearing the queue
        print("DEBUG: Clearing LED wall display before clearing queue")
        Task {
            await oscService.clearAsync()
        }
        
        Task {
            await queueManager.clearQueueAsync()
            // Note: P2P sync functionality removed
        }
    }
    
    // Alias for clearQueue for iPhone components
    func clearAllMessages() {
        clearQueue()
    }
    
    // MARK: - OSC Operations
    
    func sendMessage(_ message: Message) {
        // Mark that we've started sending
        hasStartedSending = true
        
        // 📤 DEBUG: SendMessage
        print("📤 SendMessage - Using clip \(currentClipIndex) for message: \(message.content)")
        
        // Check if there's a message currently being sent and revert it to pending
        if let sendingId = currentlySendingMessageId,
           let _ = messages.firstIndex(where: { $0.id == sendingId }) {
            // Revert the previously sending message back to pending
            Task {
                await queueManager.updateMessageStatusAsync(id: sendingId, status: .pending)
            }
        }
        
        // IMPORTANT: Find ALL sent/delivered messages and revert them to pending
        // since only one message can be on the wall at a time
        for msg in messages {
            if msg.status == .sent || msg.status == .delivered {
                print("DEBUG: Reverting previously sent message '\(msg.content)' back to pending")
                Task {
                    await queueManager.updateMessageStatusAsync(id: msg.id, status: .pending)
                }
                // Note: Timer cancellation is now handled per clip
            }
        }
        
        // Mark this message as currently sending
        currentlySendingMessageId = message.id
        
        // Verify we're using the latest settings before sending
        print("DEBUG: SENDING MESSAGE")
        print("DEBUG: AppSettings - Layer: \(appSettings.layer), StartSlot: \(appSettings.startSlot), ClipCount: \(appSettings.clipCount)")
        print("DEBUG: QueueViewModel - CurrentClipIndex: \(currentClipIndex), StartingSlot: \(startingSlot)")
        
        // CRITICAL FIX: Validate clip index is within configured range
        let minClip = appSettings.startSlot
        let maxClip = appSettings.startSlot + appSettings.clipCount - 1
        if currentClipIndex < minClip || currentClipIndex > maxClip {
            print("⚠️ WARNING: Clip index \(currentClipIndex) out of range [\(minClip)...\(maxClip)], resetting to startSlot \(appSettings.startSlot)")
            currentClipIndex = appSettings.startSlot
        }
        
        // Always use the layer from AppSettings - removed any hardcoding of layer value
        // CRITICAL FIX: Ensure clip index is within configured range
        let clipIndex = currentClipIndex
        let layer = appSettings.layer // Use the layer from AppSettings
        // Path includes the message text in brackets as per OSC spec
        let textPath = "/composition/layers/\(layer)/clips/\(clipIndex)/video/source/textgenerator/text/params/lines"
        let connectPath = "/composition/layers/\(layer)/clips/\(clipIndex)/connect"
        
        print("DEBUG: Using AppSettings Layer \(layer), Clip \(clipIndex)")
        print("DEBUG: Using path: \(textPath) for message")
        
        print("DEBUG: Sending to layer \(layer), clip \(clipIndex)")
        
        // Update message status IMMEDIATELY for responsive UI
        queueManager.updateMessageStatus(id: message.id, status: .sent)
        
        // Use AppSettings to format the message according to user preferences
        let finalFormattedText = appSettings.formatMessage(message.content)
        
        print("USING APPSETTINGS FORMATTING - Original: '\(message.content)', Formatted: '\(finalFormattedText)'")
        print("FORMATTING SETTINGS - ForceCaps: \(appSettings.forceCaps), LineBreakMode: \(appSettings.lineBreakMode), CharsPerLine: \(appSettings.charsPerLine)")
        
        // Send as plain OSC string argument
        oscService.send(finalFormattedText, to: textPath)
        
        // Handle the delayed clip activation in the background
        Task {
            // IMPORTANT: Give Resolume time to process the text update
            // Use configurable delay from settings
            let delayMilliseconds = Int(appSettings.oscTextDelay * 1000)
            try? await Task.sleep(for: .milliseconds(delayMilliseconds))
            
            // Now activate the clip
            oscService.send(1, to: connectPath)
            
            // Send webhook notification for message sent
            if !self.appSettings.webhookUrl.isEmpty {
                await self.webhookService.sendWebhook(
                    to: self.appSettings.webhookUrl,
                    event: .messageSent,
                    message: message
                )
            }
            
            // Clear the currently sending message ID since it's now sent
            if self.currentlySendingMessageId == message.id {
                self.currentlySendingMessageId = nil
            }
            
            // Set up auto-clear timer if enabled
            if self.appSettings.autoClearAfter > 0 {
                print("DEBUG: Setting up auto-clear timer for message sent to clip \(clipIndex)")
                // Get the updated message with sent status
                if let sentMessage = self.queueManager.messages.first(where: { $0.id == message.id }) {
                    self.startAutoClearTimer(for: sentMessage, clipIndex: clipIndex)
                } else {
                    print("DEBUG: Could not find sent message for auto-clear timer")
                }
            } else {
                print("DEBUG: Auto-clear disabled (autoClearAfter = \(self.appSettings.autoClearAfter))")
            }
        }
        
        // Update clip index for next message - use appSettings.clipCount and proper wrapping within the slot range
        let nextIndex = calculateNextClipIndex()
        currentClipIndex = nextIndex
        print("📤 Next clip will be: \(nextIndex)")
        print("Sent message to clip \(clipIndex), next message will use clip \(nextIndex)")
    }
    
    // Calculate the next clip index with proper wrapping
    private func calculateNextClipIndex() -> Int {
        let nextIndex = currentClipIndex + 1
        let maxIndex = appSettings.startSlot + appSettings.clipCount - 1
        
        if nextIndex > maxIndex {
            print("🔁 Wrapping from clip \(currentClipIndex) to startSlot \(appSettings.startSlot)")
            return appSettings.startSlot // Wrap to start
        } else {
            return nextIndex
        }
    }
    
    func triggerClearSlot(at index: Int) {
        print("DEBUG: Clearing content from clip \(index)")
        
        // To clear the display, use the OSCService's clear method which activates
        // the dedicated clear clip (which has blank content)
        // The index parameter indicates which clip we're clearing from, but we always
        // activate the clearClip to show blank content
        Task {
            await oscService.clearAsync()
        }
        
        print("DEBUG: Activated clear clip \(appSettings.clearClip) to clear content from clip \(index)")
    }
    
    // Updates an existing message in the queue
    func updateMessage(_ updatedMessage: Message) {
        // Note: Timer cancellation is now handled per clip, not per message
        
        Task {
            print("Updating message with ID: \(updatedMessage.id)")
            
            // Use the new efficient updateMessage method instead of clearing entire queue
            await queueManager.updateMessageAsync(updatedMessage)
            
            // Note: P2P sync functionality removed
            
            print("Message updated successfully")
        }
    }
    
    // Cancels a sent message and returns it to the queue
    func cancelSentMessage(_ message: Message, clearSlotIndex: Int) {
        // Note: Timer for the clip will be overwritten when a new message is sent to that clip
        
        // Clear the slot on the LED wall
        if clearSlotIndex >= 0 {
            triggerClearSlot(at: clearSlotIndex)
        }
        
        // Return message to pending status
        let returnedMessage = message.withStatus(.pending)
        updateMessage(returnedMessage)
    }
    
    // MARK: - AppSettings Observer
    
    // Method to refresh settings values
    func refreshFromSettings() {
        // 🔄 DEBUG: RefreshFromSettings
        print("🔄 RefreshFromSettings BEFORE - CurrentClip: \(currentClipIndex), HasStartedSending: \(hasStartedSending)")
        print("🔄 AppSettings - Layer: \(appSettings.layer), StartSlot: \(appSettings.startSlot), ClipCount: \(appSettings.clipCount)")
        
        // Update starting slot
        startingSlot = appSettings.startSlot
        
        // Only reset currentClipIndex if we haven't started sending messages
        // This preserves the rotation state during settings refresh
        if !hasStartedSending {
            currentClipIndex = appSettings.startSlot
        }
        
        print("🔄 RefreshFromSettings AFTER - CurrentClip: \(currentClipIndex)")
    }
    
    // MARK: - Connection Status
    
    /// Check if OSC is connected
    public var isOSCConnected: Bool {
        if let oscService = oscService as? OSCService {
            return oscService.connectionState == .connected
        }
        return false
    }
    
    /// Ensure OSC connection is established
    public func ensureOSCConnection() async -> Bool {
        guard let oscService = oscService as? OSCService else { return false }
        
        // If already connected, return true
        if oscService.connectionState == .connected {
            return true
        }
        
        print("🔌 Ensuring OSC connection...")
        
        // Try to reconnect
        await oscService.reconnect()
        
        // Wait for connection (up to 5 seconds)
        for i in 0..<50 {
            if oscService.connectionState == .connected {
                print("✅ OSC connected after \(i * 100)ms")
                return true
            }
            try? await Task.sleep(for: .milliseconds(100))
        }
        
        print("❌ Failed to establish OSC connection after 5 seconds")
        return false
    }
    
    // MARK: - Test Messages
    
    func sendTestMessages() {
        // Prevent duplicate test messages
        guard !hasShownTestMessages else {
            print("⚠️ Test messages already sent, skipping")
            return
        }
        
        hasShownTestMessages = true
        
        print("🧪 Sending test messages - Layer: \(appSettings.layer), StartSlot: \(appSettings.startSlot), ClipCount: \(appSettings.clipCount)")
        
        // Test messages
        let testMessages = [
            "LED MESSENGER",
            "CLUBKIT.IO",
            "LET'S PARTY"
        ]
        
        // Send test messages with 2.5 second delays
        Task {
            for (index, content) in testMessages.enumerated() {
                let clipIndex = appSettings.startSlot + index
                let layer = appSettings.layer
                
                // Make sure we're within configured range
                if index < appSettings.clipCount {
                    let textPath = "/composition/layers/\(layer)/clips/\(clipIndex)/video/source/textgenerator/text/params/lines"
                    let connectPath = "/composition/layers/\(layer)/clips/\(clipIndex)/connect"
                    
                    print("📤 Test message \(index + 1): '\(content)' → Layer \(layer), Clip \(clipIndex)")
                    
                    // Format the message
                    let formattedText = appSettings.formatMessage(content)
                    
                    // Send the text
                    oscService.send(formattedText, to: textPath)
                    
                    // Wait for Resolume to process the text (use configurable delay)
                    let delayMilliseconds = Int(appSettings.oscTextDelay * 1000)
                    try? await Task.sleep(for: .milliseconds(delayMilliseconds))
                    
                    // Activate the clip
                    oscService.send(1, to: connectPath)
                    
                    // Wait 2.5 seconds before sending the next message (or after the last message)
                    print("🔍 DEBUG: Waiting 2.5 seconds before next test message...")
                    try? await Task.sleep(for: .seconds(2.5))
                }
            }
            
            // After all messages and the final 2.5 second delay, trigger the clear slot
            print("🧹 Triggering clear slot after test messages")
            await oscService.clearAsync()
            
            print("✅ Test messages sent successfully and display cleared")
        }
    }
    
    // Enhanced version with connection check and better error handling
    public func sendTestMessagesWithConnection() {
        // Prevent duplicate test messages
        guard !hasShownTestMessages else {
            print("⚠️ Test messages already sent, skipping")
            return
        }
        
        print("🔍 DEBUG: sendTestMessagesWithConnection called")
        print("🧪 Preparing test messages with enhanced connection stability...")
        
        // Test messages
        let testMessages = [
            "LED MESSENGER",
            "CLUBKIT.IO",
            "LET'S PARTY"
        ]
        
        // Send test messages with enhanced connection and error handling
        Task {
            defer {
                // Always allow retry on failure
                if let oscService = oscService as? OSCService,
                   oscService.connectionState != .connected {
                    hasShownTestMessages = false
                }
            }
            
            // Ensure connection first with multiple attempts
            var connectionAttempts = 0
            var isConnected = false
            
            while connectionAttempts < 3 && !isConnected {
                connectionAttempts += 1
                print("🔌 Connection attempt \(connectionAttempts)/3...")
                
                isConnected = await ensureOSCConnection()
                
                if !isConnected {
                    print("⚠️ Connection attempt \(connectionAttempts) failed, waiting 2 seconds...")
                    try? await Task.sleep(for: .seconds(2))
                }
            }
            
            guard isConnected else {
                print("❌ Cannot send test messages - OSC connection failed after 3 attempts")
                return
            }
            
            // Now we're connected, mark as shown
            hasShownTestMessages = true
            
            print("🚀 Sending test messages - Layer: \(appSettings.layer), StartSlot: \(appSettings.startSlot)")
            
            for (index, content) in testMessages.enumerated() {
                let clipIndex = appSettings.startSlot + index
                let layer = appSettings.layer
                
                // Make sure we're within configured range
                if index < appSettings.clipCount {
                    let textPath = "/composition/layers/\(layer)/clips/\(clipIndex)/video/source/textgenerator/text/params/lines"
                    let connectPath = "/composition/layers/\(layer)/clips/\(clipIndex)/connect"
                    
                    print("📤 Test message \(index + 1): '\(content)' → Layer \(layer), Clip \(clipIndex)")
                    
                    // Double-check connection before each message
                    if let oscService = oscService as? OSCService,
                       oscService.connectionState != .connected {
                        print("⚠️ Connection lost during test messages, attempting reconnect...")
                        let reconnected = await ensureOSCConnection()
                        if !reconnected {
                            print("❌ Failed to reconnect, stopping test messages")
                            break
                        }
                    }
                    
                    // Format the message
                    let formattedText = appSettings.formatMessage(content)
                    
                    // Send the text with error handling
                    await oscService.sendAsync(formattedText, to: textPath)
                    
                    // Wait for Resolume to process the text (use configurable delay)
                    let delayMilliseconds = Int(appSettings.oscTextDelay * 1000)
                    try? await Task.sleep(for: .milliseconds(delayMilliseconds))
                    
                    // Activate the clip with error handling
                    await oscService.sendAsync(1, to: connectPath)
                    
                    // Wait 2.5 seconds before sending the next message (or after the last message)
                    try? await Task.sleep(for: .seconds(2.5))
                }
            }
            
            // After all messages and the final 2.5 second delay, trigger the clear slot
            print("🧹 Triggering clear slot after test messages")
            await oscService.clearAsync()
            
            print("✅ Test messages sequence completed successfully")
        }
    }
    
    // MARK: - Auto-Clear Timer Management
    
    private func startAutoClearTimer(for message: Message, clipIndex: Int) {
        // IMPORTANT: Only apply timer to sent messages
        guard message.status == .sent || message.status == .delivered else {
            print("DEBUG: Auto-clear timer NOT started for message '\(message.content)' - message not sent (status: \(message.status))")
            return
        }
        
        // Cancel any existing timer for this CLIP (not message)
        clipTimers[clipIndex]?.cancel()
        
        let autoClearDuration = appSettings.autoClearAfter
        print("DEBUG: Starting auto-clear timer for SENT message '\(message.content)' with duration: \(autoClearDuration) seconds (\(autoClearDuration/60) minutes)")
        
        // Create a new timer task
        let timerTask = Task { [weak self] in
            do {
                // Wait for the auto-clear duration
                try await Task.sleep(for: .seconds(autoClearDuration))
                
                // Check if task wasn't cancelled
                if !Task.isCancelled {
                    await MainActor.run { [weak self] in
                        guard let self = self else { return }
                        
                        print("DEBUG: Auto-clear timer fired! Clearing message: \(message.content) from clip \(clipIndex)")
                        
                        // Clear the slot on the LED wall
                        self.triggerClearSlot(at: clipIndex)
                        
                        // Remove the message from the queue (only for sent messages)
                        self.removeMessage(id: message.id)
                        
                        // Clean up the timer from our tracking
                        self.clipTimers.removeValue(forKey: clipIndex)
                    }
                }
            } catch {
                // Task was cancelled, which is normal when clearing manually
                print("DEBUG: Auto-clear timer cancelled for message: \(message.id)")
            }
        }
        
        // Store the timer task by clip index, not message ID
        clipTimers[clipIndex] = timerTask
        print("DEBUG: Timer stored for clip index: \(clipIndex)")
    }
}