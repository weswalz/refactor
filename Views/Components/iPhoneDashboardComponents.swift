//
//  iPhoneDashboardComponents.swift
//  LED MESSENGER
//
//  iPhone dashboard view and modal components for iOS 18+ SwiftUI
//  Created: June 16, 2025
//

import SwiftUI

// MARK: - iPhone Dashboard View
/// Main dashboard optimized for iPhone screens
/// Provides clean interface for message management and LED control
struct iPhoneDashboardView: View {
    @Environment(QueueViewModel.self) var queueVM
    @Environment(DashboardViewModel.self) var dashboardVM
    @Environment(AppSettings.self) var appSettings
    
    @State private var messageToEdit: Message? = nil
    @State private var showEditModal = false
    @State private var isEditingMode = false
    
    var body: some View {
        ZStack {
            // iPhone-optimized background gradient
            backgroundGradient
            
            VStack(spacing: 0) {
                // iPhone Header (Clean!)
                iPhoneHeaderView()
                
                // Subtle divider
                headerDivider
                
                // Simplified Instructions
                iPhoneInstructionBanner()
                
                // Message List or Empty State
                mainContentArea
                
                // Action Bar (positioned above footer)
                iPhoneActionBar()
                    .padding(.bottom, 23)
                
                // ClubKit Footer
                ClubKitFooter()
            }
        }
        .onAppear {
            print("📱 iPhone Dashboard appeared")
            
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
                        
                        // Send test messages after stable connection
                        print("🔍 Sending test messages with stable connection")
                        // Add small delay before test messages to ensure everything is ready
                        try? await Task.sleep(for: .milliseconds(500))
                        queueVM.sendTestMessagesWithConnection()
                    } else {
                        print("⚠️ Connection lost after permission handling - user needs to manually reconnect")
                    }
                } else {
                    print("⚠️ Failed to establish initial OSC connection")
                    print("💡 User can manually reconnect or check settings")
                }
            }
        }
        .sheet(isPresented: .init(
            get: { dashboardVM.showNewMessageModal || showEditModal },
            set: { newValue in
                if !newValue {
                    dashboardVM.showNewMessageModal = false
                    showEditModal = false
                    isEditingMode = false
                    messageToEdit = nil
                }
            }
        )) {
            iPhoneNewMessageModal(
                messageToEdit: isEditingMode ? messageToEdit : nil,
                onSubmit: isEditingMode ? handleEditMessage : handleNewMessage,
                onCancel: handleModalCancel
            )
        }
        .accessibilityLabel("LED Messenger Dashboard")
    }
    
    /// Elegant gradient background optimized for iPhone
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.purple.opacity(0.3),
                Color.indigo.opacity(0.2),
                Color.black
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    /// Subtle divider between header and content
    private var headerDivider: some View {
        Divider()
            .background(.white.opacity(0.1))
    }
    
    /// Main content area showing clean message list (handles empty state gracefully)
    @ViewBuilder
    private var mainContentArea: some View {
        // Clean empty queue - no intrusive empty state UI
        // Follows 2025 SwiftUI best practices for minimal, uncluttered interfaces
        iPhoneMessageList(
            messageToEdit: $messageToEdit,
            showEditModal: $showEditModal,
            onEdit: { message in
                messageToEdit = message
                isEditingMode = true
                showEditModal = true
            }
        )
    }
    
    /// Handles new message submission
    private func handleNewMessage(_ newMessage: Message) {
        queueVM.enqueue(newMessage)
        dashboardVM.closeModal()
        performSuccessFeedback()
    }
    
    /// Handles message edit submission
    private func handleEditMessage(_ editedMessage: Message) {
        if let originalMessage = messageToEdit {
            let updatedMessage = Message(
                id: originalMessage.id,
                content: editedMessage.content,
                timestamp: originalMessage.timestamp,
                status: originalMessage.status,
                priority: originalMessage.priority,
                label: editedMessage.label
            )
            queueVM.updateMessage(updatedMessage)
            
            // If the message was already sent, resend it to update the LED wall
            if originalMessage.status == .sent || originalMessage.status == .delivered {
                queueVM.sendMessage(updatedMessage)
            }
        }
        
        showEditModal = false
        isEditingMode = false
        messageToEdit = nil
        performSuccessFeedback()
    }
    
    /// Handles modal cancellation
    private func handleModalCancel() {
        dashboardVM.closeModal()
        showEditModal = false
        isEditingMode = false
        messageToEdit = nil
        performSelectionFeedback()
    }
    
    /// Provides success haptic feedback
    private func performSuccessFeedback() {
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
    }
    
    /// Provides selection haptic feedback
    private func performSelectionFeedback() {
        #if canImport(UIKit)
        UISelectionFeedbackGenerator().selectionChanged()
        #endif
    }
}

// MARK: - iPhone New Message Modal
/// Beautiful slide-up modal for creating new messages
/// Matches iPad design with iPhone-specific optimizations
struct iPhoneNewMessageModal: View {
    let messageToEdit: Message?
    let onSubmit: (Message) -> Void
    let onCancel: () -> Void
    
    @Environment(AppSettings.self) private var appSettings
    
    @State private var messageText = ""
    @State private var labelValue = ""
    @FocusState private var messageFieldFocused: Bool
    @FocusState private var labelFieldFocused: Bool
    
    // Default initializer for new messages
    init(onSubmit: @escaping (Message) -> Void, onCancel: @escaping () -> Void) {
        self.messageToEdit = nil
        self.onSubmit = onSubmit
        self.onCancel = onCancel
    }
    
    // Initializer for editing messages
    init(messageToEdit: Message?, onSubmit: @escaping (Message) -> Void, onCancel: @escaping () -> Void) {
        self.messageToEdit = messageToEdit
        self.onSubmit = onSubmit
        self.onCancel = onCancel
    }
    
    /// Binding that ensures text input is always uppercase for LED displays
    private var messageBinding: Binding<String> {
        Binding(
            get: { messageText },
            set: { newValue in
                // Always store text in uppercase for LED messaging
                messageText = newValue.uppercased()
            }
        )
    }
    
    var body: some View {
        ZStack {
            // Beautiful purple gradient matching iPad design
            modalBackground
            
            VStack(spacing: 24) {
                // Simple header
                modalHeader
                
                // Content with iPad styling
                modalContent
                
                // Action buttons with iPad gradients - removed spacer to bring buttons up
                modalActionButtons
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40) // Added bottom padding to keep buttons away from edge
        }
        .presentationDetents([.fraction(0.6), .large]) // Reverted back to 0.6
        .presentationDragIndicator(.visible)
        .presentationBackground(.clear) // Force clear background so our gradient shows
        .accessibilityLabel(messageToEdit != nil ? "Edit Message" : "New Message Creation")
        .onAppear {
            // Pre-populate fields when editing
            if let editMessage = messageToEdit {
                messageText = editMessage.content
                if let label = editMessage.label {
                    labelValue = label.text
                }
            }
        }
    }
    
    /// Beautiful purple gradient with full opacity to block underlying content
    private var modalBackground: some View {
        RadialGradient(
            gradient: Gradient(colors: [
                Color.purple.opacity(1.0),
                Color.black
            ]),
            center: .center,
            startRadius: 0,
            endRadius: 400
        )
        .ignoresSafeArea()
    }
    
    /// Header with title and description
    private var modalHeader: some View {
        VStack(spacing: 8) {
            Text(messageToEdit != nil ? "Edit Message" : "New Message")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
                .accessibilityAddTraits(.isHeader)
            
            Text(messageToEdit != nil ? "Update your message" : "Create message labels for organization")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.top, 60) // Increased from 40 to 60 to push content down more
    }
    
    /// Main content form
    private var modalContent: some View {
        VStack(spacing: 20) {
            // Label input (if enabled)
            if appSettings.defaultLabelType != 2 {
                labelInputSection
            }
            
            // Message input
            messageInputSection
        }
        .padding(20)
        .background(contentBackground)
    }
    
    /// Label input field with dynamic title
    private var labelInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(getLabelFieldTitle())
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))
            
            ZStack(alignment: .leading) {
                if labelValue.isEmpty {
                    Text(getLabelFieldPlaceholder())
                        .foregroundColor(.white.opacity(0.8))
                        .font(.system(size: 16))
                        .padding(.leading, 16)
                }
                
                TextField("", text: $labelValue)
                    .focused($labelFieldFocused)
                    .font(.system(size: 16))
                    .padding(16)
                    .background(inputFieldBackground)
                    .foregroundColor(.white)
                    .accessibilityLabel(getLabelFieldTitle())
            }
        }
    }
    
    /// Message input field with caps indicator
    private var messageInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Message")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))
            
            ZStack(alignment: .bottomTrailing) {
                ZStack(alignment: .topLeading) {
                    if messageText.isEmpty {
                        Text("Enter your message")
                            .foregroundColor(.white.opacity(0.8))
                            .font(.system(size: 16))
                            .padding(.leading, 16)
                            .padding(.top, 16)
                    }
                    
                    TextField("", text: messageBinding, axis: .vertical)
                        .focused($messageFieldFocused)
                        #if os(iOS)
                        .textInputAutocapitalization(.characters)
                        .disableAutocorrection(true)
                        #endif
                        .font(.system(size: 16))
                        .padding(16)
                        .background(inputFieldBackground)
                        .foregroundColor(.white)
                        .lineLimit(3...6)
                        .accessibilityLabel("Message content - typing in uppercase")
                }
                
                // CAPS indicator - shows when typing (always uppercase now)
                if !messageText.isEmpty {
                    capsIndicator
                }
            }
        }
    }
    
    /// Visual indicator when caps mode is active
    private var capsIndicator: some View {
        Text("CAPS")
            .font(.system(size: 9, weight: .bold))
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(Color.purple.opacity(0.8))
            )
            .foregroundColor(.white)
            .padding(8)
            .accessibilityLabel("Uppercase mode - text automatically capitalized")
    }
    
    /// Background styling for content area
    private var contentBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.black.opacity(0.4))
            .stroke(Color.purple.opacity(0.3), lineWidth: 1)
    }
    
    /// Background styling for input fields
    private var inputFieldBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.black.opacity(0.3))
            .stroke(Color.purple.opacity(0.6), lineWidth: 1.5)
    }
    
    /// Action buttons with gradient styling
    private var modalActionButtons: some View {
        HStack(spacing: 12) {
            Button("CANCEL") {
                onCancel()
                performCancelFeedback()
            }
            .buttonStyle(CancelButtonStyle())
            .accessibilityLabel("Cancel message creation")
                
            Button(messageToEdit != nil ? "Update Message" : "ADD MESSAGE") {
            submitMessage()
            }
            .buttonStyle(SubmitButtonStyle(isEnabled: !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty))
            .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .accessibilityLabel("Add message to queue")
        }
    }
    
    /// Submits the message and provides feedback
    private func submitMessage() {
        let message = Message(
            content: messageText, // Already in uppercase from binding
            label: createLabel()
        )
        onSubmit(message)
        performSubmitFeedback()
    }
    
    /// Provides feedback for cancel action
    private func performCancelFeedback() {
        #if canImport(UIKit)
        UISelectionFeedbackGenerator().selectionChanged()
        #endif
    }
    
    /// Provides feedback for submit action
    private func performSubmitFeedback() {
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
    }
    
    // MARK: - Helper Methods
    
    /// Gets the appropriate label field title based on settings
    private func getLabelFieldTitle() -> String {
        switch appSettings.defaultLabelType {
        case 0: return "Table Number"
        case 1: return appSettings.customLabelPrefix.isEmpty ? "Custom Label" : "\(appSettings.customLabelPrefix) Label"
        default: return ""
        }
    }
    
    /// Gets the appropriate placeholder text for label field
    private func getLabelFieldPlaceholder() -> String {
        switch appSettings.defaultLabelType {
        case 0: return "Enter table number"
        case 1: return "Enter label value"
        default: return ""
        }
    }
    
    /// Creates a label object based on current settings and input
    private func createLabel() -> Message.Label? {
        guard appSettings.defaultLabelType != 2, 
              !labelValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { 
            return nil 
        }
        
        let labelType: Message.MessageLabelType = appSettings.defaultLabelType == 0 ? .tableNumber : .customLabel
        let finalText = appSettings.defaultLabelType == 1 && !appSettings.customLabelPrefix.isEmpty 
            ? "\(appSettings.customLabelPrefix) \(labelValue)" 
            : labelValue
        
        return Message.Label(type: labelType, text: finalText)
    }
}

// MARK: - Modal Button Styles

/// Cancel button style with pink gradient
struct CancelButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .bold))
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [Color.pink.opacity(0.8), Color.purple.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.purple.opacity(0.6), lineWidth: 1.5)
            )
            .foregroundColor(.white)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

/// Submit button style with conditional gradient
struct SubmitButtonStyle: ButtonStyle {
    let isEnabled: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .bold))
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(buttonGradient)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.purple.opacity(0.6), lineWidth: 1.5)
            )
            .foregroundColor(.white)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
    
    /// Dynamic gradient based on enabled state
    private var buttonGradient: LinearGradient {
        if isEnabled {
            return LinearGradient(
                colors: [Color.purple.opacity(0.9), Color.blue.opacity(0.8)],
                startPoint: .leading,
                endPoint: .trailing
            )
        } else {
            return LinearGradient(
                colors: [Color.gray.opacity(0.5), Color.gray.opacity(0.3)],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
}

/*
#Preview("iPhone Dashboard") {
    iPhoneDashboardView()
        .environment(AppSettings())
        .environment(DashboardViewModel())
        .environment(QueueViewModel(queueManager: QueueManager(), oscService: OSCService(), appSettings: AppSettings()))
}
*/
