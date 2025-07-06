//
//  iPhoneMessageComponents.swift
//  LED MESSENGER
//
//  iPhone message display and interaction components for iOS 18+ SwiftUI
//  Created: June 16, 2025
//

import SwiftUI

// MARK: - iPhone Message List
/// Scrollable list of messages with pull-to-refresh functionality
/// Optimized for iPhone screen dimensions and touch interactions
/// Handles empty state gracefully with clean, minimal design following 2025 SwiftUI best practices
struct iPhoneMessageList: View {
    @Environment(QueueViewModel.self) var queueVM
    @Binding var messageToEdit: Message?
    @Binding var showEditModal: Bool
    let onEdit: ((Message) -> Void)?
    
    // Default initializer for backward compatibility
    init(messageToEdit: Binding<Message?>, showEditModal: Binding<Bool>) {
        self._messageToEdit = messageToEdit
        self._showEditModal = showEditModal
        self.onEdit = nil
    }
    
    // Full initializer with onEdit callback
    init(messageToEdit: Binding<Message?>, showEditModal: Binding<Bool>, onEdit: ((Message) -> Void)?) {
        self._messageToEdit = messageToEdit
        self._showEditModal = showEditModal
        self.onEdit = onEdit
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(queueVM.messages) { message in
                    iPhoneMessageCard(
                        message: message,
                        onDelete: { handleDelete(message) },
                        onSend: { handleSend(message) },
                        onEdit: { handleEdit(message) }
                    )
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .refreshable {
            performRefreshFeedback()
        }
        .accessibilityLabel(queueVM.messages.isEmpty ? "Empty message queue. Use New Message button to add messages." : "Message queue with \(queueVM.messages.count) messages")
    }
    
    /// Handles message deletion with proper cleanup and feedback
    private func handleDelete(_ message: Message) {
        performHapticFeedback(.medium)
        
        if message.status == .sent || message.status == .delivered {
            queueVM.cancelSentMessage(message, clearSlotIndex: 0)
        } else {
            queueVM.removeMessage(id: message.id)
        }
    }
    
    /// Handles message sending with feedback
    private func handleSend(_ message: Message) {
        performHapticFeedback(.light)
        queueVM.sendMessage(message)
    }
    
    /// Handles message editing by opening edit modal
    private func handleEdit(_ message: Message) {
        if let onEdit = onEdit {
            onEdit(message)
        } else {
            messageToEdit = message
            showEditModal = true
        }
        performSelectionFeedback()
    }
    
    /// Provides haptic feedback for different interaction types
    private func performHapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: style).impactOccurred()
        #endif
    }
    
    /// Provides haptic feedback for selection interactions
    private func performSelectionFeedback() {
        #if canImport(UIKit)
        UISelectionFeedbackGenerator().selectionChanged()
        #endif
    }
    
    /// Provides feedback for pull-to-refresh action
    private func performRefreshFeedback() {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        #endif
    }
}

// MARK: - iPhone Message Card
/// Individual message card with content, labels, and action buttons
/// Matches iPad design while optimized for iPhone touch targets
struct iPhoneMessageCard: View {
    let message: Message
    let onDelete: () -> Void
    let onSend: () -> Void
    let onEdit: () -> Void
    
    @Environment(QueueViewModel.self) var queueVM
    @Environment(AppSettings.self) var appSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Message Content Section
            messageContentSection
            
            // Action Buttons Section
            actionButtonsSection
        }
        .padding(14)
        .background(cardBackground)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }
    
    /// Main content display with label and message text
    private var messageContentSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Table number or label (purple like iPad)
            labelSection
            
            // Message content (white like iPad)
            Text(message.content)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.leading)
                .accessibilityLabel("Message: \(message.content)")
        }
    }
    
    /// Message label display with consistent styling
    private var labelSection: some View {
        Group {
            if let label = message.label {
                Text(formatLabel(label))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.purple)
                    .accessibilityLabel("Label: \(formatLabel(label))")
            } else {
                Text("—")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.purple)
                    .accessibilityLabel("No label")
            }
        }
    }
    

    
    /// Action buttons based on message status
    @ViewBuilder
    private var actionButtonsSection: some View {
        if message.status == .pending {
            pendingMessageButtons
        } else {
            sentMessageButton
        }
    }
    
    /// Buttons for pending messages (Send and Edit)
    private var pendingMessageButtons: some View {
        HStack(spacing: 8) {
            Button("SEND TO WALL", action: onSend)
                .buttonStyle(iPhonePrimaryCardButtonStyle())
                .accessibilityLabel("Send message to LED wall")
            
            Button("EDIT", action: onEdit)
                .buttonStyle(iPhoneSecondaryCardButtonStyle())
                .accessibilityLabel("Edit message")
        }
    }
    
    /// Button for sent messages (Cancel only)
    private var sentMessageButton: some View {
        Button("CANCEL", action: onDelete)
            .buttonStyle(iPhoneDestructiveCardButtonStyle())
            .accessibilityLabel("Cancel and remove message")
    }
    
    /// Dynamic background based on message status
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.purple.opacity(0.1))
            .stroke(
                message.status == .sent ? Color.purple : Color.clear,
                lineWidth: message.status == .sent ? 2 : 0
            )
    }
    
    /// Formats message label for display
    private func formatLabel(_ label: Message.Label) -> String {
        switch label.type {
        case .tableNumber:
            return "TABLE \(label.text)"
        case .customLabel:
            return label.text.uppercased()
        case .noLabel:
            return "—"
        }
    }
    
    /// Accessibility description for the entire card
    private var accessibilityDescription: String {
        let labelText = message.label != nil ? formatLabel(message.label!) : "No label"
        let statusText = message.status == .pending ? "pending" : "sent"
        return "\(labelText), \(message.content), \(statusText)"
    }
}

// MARK: - iPhone Card Button Styles
/// Primary button style for main actions (Send)
struct iPhonePrimaryCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .bold))
            .frame(maxWidth: .infinity)
            .frame(height: 36)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.purple)
            )
            .foregroundStyle(.white)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

/// Secondary button style for secondary actions (Edit)
struct iPhoneSecondaryCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .bold))
            .frame(maxWidth: .infinity)
            .frame(height: 36)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.blue, lineWidth: 1)
            )
            .foregroundStyle(.blue)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

/// Destructive button style for removal actions (Cancel)
struct iPhoneDestructiveCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .bold))
            .frame(maxWidth: .infinity)
            .frame(height: 36)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.red, lineWidth: 1)
            )
            .foregroundStyle(.red)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Clean Empty State Implementation
// Following 2025 SwiftUI best practices, empty states are handled gracefully
// by the message list itself without intrusive UI elements.
// This provides a cleaner, more modern user experience.

// The empty state is now handled by:
// 1. iPhoneMessageList showing an empty ScrollView when no messages
// 2. Proper accessibility labels for screen reader support
// 3. Clean interface that emphasizes the existing "New Message" button
// 4. Consistent behavior across iPhone and iPad platforms

#Preview("iPhone Message Components") {
    ScrollView {
        VStack(spacing: 16) {
            // Sample message card
            iPhoneMessageCard(
                message: Message(
                    content: "Happy Birthday Sarah!",
                    label: Message.Label(type: .tableNumber, text: "12")
                ),
                onDelete: {},
                onSend: {},
                onEdit: {}
            )
            
            // Clean empty state demonstration
            Text("Clean empty state: Just empty scrollview - no intrusive UI")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding()
        }
        .padding()
    }
    .background(.black)
    .environment(AppSettings())
    .environment(DashboardViewModel())
    .environment(QueueViewModel(queueManager: QueueManager(), oscService: OSCService(), appSettings: AppSettings()))
}
