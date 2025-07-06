//
//  EnhancediPhoneDashboardIntegration.swift
//  LED MESSENGER
//
//  Enhanced iPhone dashboard with integrated modern settings access
//  Created: June 15, 2025
//

import SwiftUI

/// Enhanced iPhone dashboard that intelligently routes to appropriate UI based on device
struct EnhancediPhoneDashboardIntegration: View {
    @Environment(QueueViewModel.self) var queueVM
    @Environment(DashboardViewModel.self) var dashboardVM
    @Environment(AppSettings.self) var appSettings
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    private var isCompactDevice: Bool {
        horizontalSizeClass == .compact
    }
    
    var body: some View {
        Group {
            if isCompactDevice {
                // iPhone: Enhanced dashboard with modern settings integration
                EnhancediPhoneDashboard()
            } else {
                // iPad: Keep existing solo dashboard (no changes)
                SoloDashboardView()
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Enhanced iPhone Dashboard
struct EnhancediPhoneDashboard: View {
    @Environment(QueueViewModel.self) var queueVM
    @Environment(DashboardViewModel.self) var dashboardVM
    @Environment(AppSettings.self) var appSettings
    
    @State private var messageToEdit: Message? = nil
    @State private var showEditModal = false
    @State private var showingSettings = false
    @State private var showingQuickSettings = false
    
    var body: some View {
        ZStack {
            // Enhanced background with iOS 18 materials
            modernBackground
            
            VStack(spacing: 0) {
                // Enhanced header with quick settings access
                enhancedHeader
                
                // Status bar with connection info
                connectionStatusBar
                
                // Main content area
                mainContentArea
                
                // Enhanced action bar with quick settings
                enhancedActionBar
                
                // Footer with attribution
                attributionFooter
            }
        }
        .sheet(isPresented: $showingSettings) {
            EnhancediPhoneSettingsCoordinator()
                .environment(appSettings)
        }
        .sheet(isPresented: $showingQuickSettings) {
            QuickSettingsSheet()
                .environment(appSettings)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: .init(
            get: { dashboardVM.showNewMessageModal },
            set: { dashboardVM.showNewMessageModal = $0 }
        )) {
            EnhancedNewMessageModal(
                onSubmit: { newMessage in
                    queueVM.enqueue(newMessage)
                    dashboardVM.closeModal()
                    performHapticFeedback(.success)
                },
                onCancel: { 
                    dashboardVM.closeModal()
                    performHapticFeedback(.selection)
                }
            )
            .environment(appSettings)
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showEditModal) {
            MessageEditSheet(message: $messageToEdit, showEditModal: $showEditModal)
                .environment(appSettings)
                .environment(queueVM)
                .environment(dashboardVM)
        }
    }
    
    // MARK: - UI Components
    
    private var modernBackground: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.purple.opacity(0.4),
                    Color.indigo.opacity(0.3),
                    Color.black
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Subtle texture overlay
            Rectangle()
                .fill(.ultraThinMaterial.opacity(0.3))
                .ignoresSafeArea()
        }
    }
    
    private var enhancedHeader: some View {
        HStack(spacing: 12) {
            // Logo with better sizing
            Image("ledmwide35")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 24)
            
            Spacer()
            
            // Quick settings button
            Button(action: {
                showingQuickSettings = true
                performHapticFeedback(.selection)
            }) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
                    .frame(width: 32, height: 32)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(.plain)
            
            // Full settings button
            Button(action: {
                showingSettings = true
                performHapticFeedback(.selection)
            }) {
                Image(systemName: "gear")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
                    .frame(width: 32, height: 32)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
    
    private var connectionStatusBar: some View {
        HStack {
            // Connection indicator
            HStack(spacing: 6) {
                Circle()
                    .fill(connectionColor)
                    .frame(width: 8, height: 8)
                
                Text(connectionStatus)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Queue count
            Text("\(queueVM.messages.count) messages")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial.opacity(0.5))
    }
    
    private var mainContentArea: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if queueVM.messages.isEmpty {
                    emptyStateView
                } else {
                    ForEach(queueVM.messages) { message in
                        EnhancedMessageCard(
                            message: message,
                            onDelete: { handleDelete(message) },
                            onSend: { handleSend(message) },
                            onEdit: { handleEdit(message) }
                        )
                        .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .refreshable {
            performHapticFeedback(.impact(.soft))
            // Refresh logic here
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "text.bubble")
                .font(.system(size: 50))
                .foregroundStyle(.purple.opacity(0.6))
            
            Text("No Messages")
                .font(.title2.bold())
                .foregroundStyle(.primary)
            
            Text("Tap 'New Message' to create your first LED message")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Create Message") {
                dashboardVM.showNewMessageModal = true
                performHapticFeedback(.selection)
            }
            .buttonStyle(ModernPrimaryButtonStyle())
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 60)
    }
    
    private var enhancedActionBar: some View {
        HStack(spacing: 16) {
            // Clear button with enhanced styling
            Button(action: {
                withAnimation(.smooth(duration: 0.3)) {
                    queueVM.clearAllMessages()
                }
                performHapticFeedback(.impact(.medium))
            }) {
                Label("Clear", systemImage: "trash")
                    .labelStyle(.iconOnly)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.white.opacity(0.2), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .disabled(queueVM.messages.isEmpty)
            
            // New message button with enhanced styling
            Button(action: {
                dashboardVM.showNewMessageModal = true
                performHapticFeedback(.impact(.light))
            }) {
                Label("New Message", systemImage: "plus.circle.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        LinearGradient(
                            colors: [.purple, .purple.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: RoundedRectangle(cornerRadius: 16)
                    )
                    .shadow(color: .purple.opacity(0.4), radius: 8, y: 4)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
    
    private var attributionFooter: some View {
        Link(destination: URL(string: "https://clubkit.io")!) {
            Image("ck40")
                .resizable()
                .frame(width: 18, height: 22)
                .foregroundStyle(.white.opacity(0.4))
        }
        .padding(.bottom, 8)
    }
    
    // MARK: - Helper Properties
    
    private var connectionColor: Color {
        // This would connect to actual OSC service status
        .green // Placeholder - connect to real status
    }
    
    private var connectionStatus: String {
        // This would show actual connection status
        "Connected" // Placeholder
    }
    
    // MARK: - Actions
    
    private func handleDelete(_ message: Message) {
        withAnimation(.smooth(duration: 0.3)) {
            if message.status == .sent || message.status == .delivered {
                queueVM.cancelSentMessage(message, clearSlotIndex: 0)
            } else {
                queueVM.removeMessage(id: message.id)
            }
        }
        performHapticFeedback(.impact(.medium))
    }
    
    private func handleSend(_ message: Message) {
        queueVM.sendMessage(message)
        performHapticFeedback(.impact(.light))
    }
    
    private func handleEdit(_ message: Message) {
        messageToEdit = message
        showEditModal = true
        performHapticFeedback(.selection)
    }
    
    private func performHapticFeedback(_ type: HapticFeedbackType) {
        #if canImport(UIKit)
        switch type {
        case .impact(let style):
            UIImpactFeedbackGenerator(style: style).impactOccurred()
        case .selection:
            UISelectionFeedbackGenerator().selectionChanged()
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .error:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
        #endif
    }
}

// MARK: - Enhanced Message Card
struct EnhancedMessageCard: View {
    let message: Message
    let onDelete: () -> Void
    let onSend: () -> Void
    let onEdit: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Message header
            messageHeader
            
            // Message content
            messageContent
            
            // Action buttons
            actionButtons
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(borderColor, lineWidth: borderWidth)
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.smooth(duration: 0.2), value: isPressed)
        .onTapGesture {
            // Optional: Add tap behavior
        }
        .onLongPressGesture(
            minimumDuration: 0.1,
            maximumDistance: 50,
            perform: {},
            onPressingChanged: { pressing in
                withAnimation(.smooth(duration: 0.1)) {
                    isPressed = pressing
                }
            }
        )
    }
    
    private var messageHeader: some View {
        HStack {
            // Label (if present)
            if let label = message.label {
                Text(formatLabel(label))
                    .font(.caption.bold())
                    .foregroundStyle(.purple)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.purple.opacity(0.2), in: Capsule())
            }
            
            Spacer()
            
            // Status indicator
            statusIndicator
            
            // Timestamp
            Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    private var messageContent: some View {
        Text(message.content)
            .font(.body.weight(.medium))
            .foregroundStyle(.primary)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder
    private var actionButtons: some View {
        if message.status == .pending {
            HStack(spacing: 12) {
                Button("EDIT", action: onEdit)
                    .buttonStyle(ModernSecondaryButtonStyle())
                
                Button("SEND TO WALL", action: onSend)
                    .buttonStyle(ModernPrimaryButtonStyle())
            }
        } else {
            Button("CANCEL", action: onDelete)
                .buttonStyle(ModernDestructiveButtonStyle())
                .frame(maxWidth: .infinity)
        }
    }
    
    private var statusIndicator: some View {
        Group {
            switch message.status {
            case .pending:
                Image(systemName: "clock.circle.fill")
                    .foregroundStyle(.orange)
            case .sent:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            case .delivered:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.blue)
            case .failed:
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.red)
            }
        }
        .font(.caption)
    }
    
    private var borderColor: Color {
        switch message.status {
        case .sent, .delivered: return .purple.opacity(0.6)
        case .failed: return .red.opacity(0.6)
        default: return .clear
        }
    }
    
    private var borderWidth: CGFloat {
        message.status == .sent || message.status == .delivered ? 1.5 : 0
    }
    
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
}

// MARK: - Quick Settings Sheet
struct QuickSettingsSheet: View {
    @Environment(AppSettings.self) private var appSettings
    @Environment(\.dismiss) private var dismiss
    
    @State private var forceCaps: Bool = false
    @State private var autoClearMinutes: Double = 3.0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Quick Settings")
                        .font(.title2.bold())
                        .foregroundStyle(.primary)
                    
                    Text("Frequently used options")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 20)
                
                // Quick options
                VStack(spacing: 20) {
                    ModernToggle(
                        title: "Force Uppercase",
                        description: "Convert all text to uppercase",
                        isOn: $forceCaps,
                        icon: "textformat.abc.uppercase"
                    )
                    
                    ModernSlider(
                        title: "Auto-Clear Duration",
                        value: $autoClearMinutes,
                        range: 1...10,
                        step: 1,
                        format: "%.0f min",
                        icon: "timer"
                    )
                }
                
                Spacer()
                
                // Done button
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(ModernPrimaryButtonStyle())
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 24)
            .navigationBarHidden(true)
        }
        .onAppear {
            forceCaps = appSettings.forceCaps
            autoClearMinutes = appSettings.autoClearAfter / 60.0
        }
        .onChange(of: forceCaps) { _, _ in
            appSettings.setForceCaps(forceCaps)
        }
        .onChange(of: autoClearMinutes) { _, _ in
            appSettings.setAutoClearAfter(autoClearMinutes * 60.0)
        }
    }
}

// MARK: - Enhanced New Message Modal
struct EnhancedNewMessageModal: View {
    let onSubmit: (Message) -> Void
    let onCancel: () -> Void
    
    @Environment(AppSettings.self) private var appSettings
    @State private var messageText = ""
    @State private var labelValue = ""
    @FocusState private var messageFieldFocused: Bool
    @FocusState private var labelFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    colors: [.purple.opacity(0.3), .indigo.opacity(0.2), .black],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Text("New Message")
                                .font(.title.bold())
                                .foregroundStyle(.primary)
                            
                            Text("Create a message for the LED display")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 20)
                        
                        // Form
                        VStack(spacing: 20) {
                            // Label input (if enabled)
                            if appSettings.defaultLabelType != 2 {
                                ModernTextField(
                                    title: getLabelFieldTitle(),
                                    text: $labelValue,
                                    placeholder: getLabelFieldPlaceholder(),
                                    icon: "tag"
                                )
                                .focused($labelFieldFocused)
                            }
                            
                            // Message input
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Message", systemImage: "text.bubble")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                
                                ZStack(alignment: .bottomTrailing) {
                                    TextField("Enter your message", text: $messageText, axis: .vertical)
                                        .focused($messageFieldFocused)
                                        .textFieldStyle(.plain)
                                        .font(.body)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(messageFieldFocused ? .purple : .clear, lineWidth: 2)
                                        )
                                        .lineLimit(3...6)
                                    
                                    // CAPS indicator
                                    if appSettings.forceCaps && !messageText.isEmpty {
                                        Text("CAPS")
                                            .font(.caption2.bold())
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 3)
                                            .background(.purple, in: Capsule())
                                            .foregroundStyle(.white)
                                            .padding(8)
                                    }
                                }
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel", action: onCancel)
                        .foregroundStyle(.secondary)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        let message = Message(
                            content: appSettings.forceCaps ? messageText.uppercased() : messageText,
                            label: createLabel()
                        )
                        onSubmit(message)
                    }
                    .foregroundStyle(.purple)
                    .fontWeight(.semibold)
                    .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func getLabelFieldTitle() -> String {
        switch appSettings.defaultLabelType {
        case 0: return "Table Number"
        case 1: return "Custom Label"
        default: return ""
        }
    }
    
    private func getLabelFieldPlaceholder() -> String {
        switch appSettings.defaultLabelType {
        case 0: return "12"
        case 1: return "A1"
        default: return ""
        }
    }
    
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

// MARK: - Button Styles
struct ModernPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.bold())
            .foregroundStyle(.white)
            .frame(height: 44)
            .frame(maxWidth: .infinity)
            .background(.purple.gradient, in: RoundedRectangle(cornerRadius: 12))
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.smooth(duration: 0.1), value: configuration.isPressed)
    }
}

struct ModernSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.bold())
            .foregroundStyle(.purple)
            .frame(height: 44)
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.purple, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.smooth(duration: 0.1), value: configuration.isPressed)
    }
}

struct ModernDestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.bold())
            .foregroundStyle(.red)
            .frame(height: 44)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.red, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.smooth(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Haptic Feedback Types
private enum HapticFeedbackType {
    case impact(UIImpactFeedbackGenerator.FeedbackStyle)
    case selection
    case success
    case error
}

#Preview {
    EnhancediPhoneDashboardIntegration()
        .environment(AppSettings())
        .environment(QueueViewModel(queueManager: QueueManager(), oscService: OSCService(), appSettings: AppSettings()))
        .environment(DashboardViewModel())
}