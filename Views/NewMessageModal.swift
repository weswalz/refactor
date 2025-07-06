import SwiftUI

// Note: Using safe layout extensions from SafeLayoutExtensions.swift

struct NewMessageModal: View {
    // Access app settings through environment
    @Environment(AppSettings.self) private var appSettings
    
    @State private var labelValue: String = ""
    // We'll use rawMessageText for input, and messageText for the formatted version
    @State private var rawMessageText: String = ""
    @State private var messageText: String = ""
    
    @FocusState private var labelFieldFocused: Bool
    @FocusState private var messageFieldFocused: Bool

    var onSubmit: (Message) -> Void
    var onCancel: () -> Void
    
    // Computed binding that applies formatting as the user types and shows it in the field
    private var messageTextBinding: Binding<String> {
        Binding(
            get: {
                // Show the formatted text (with caps applied) in the text field
                let result = appSettings.forceCaps ? rawMessageText.uppercased() : rawMessageText
                print("🔤 MessageTextBinding GET - forceCaps: \(appSettings.forceCaps), raw: '\(rawMessageText)', result: '\(result)'")
                return result
            },
            set: { newValue in
                // Store the raw text input
                rawMessageText = newValue
                // Update the formatted version for submission
                if appSettings.forceCaps {
                    messageText = newValue.uppercased()
                } else {
                    messageText = newValue
                }
                print("🔤 MessageTextBinding SET - forceCaps: \(appSettings.forceCaps), newValue: '\(newValue)', messageText: '\(messageText)'")
            }
        )
    }

    @ViewBuilder
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Themed background that matches the app
                backgroundGradient(for: geometry)
                
                ScrollView {
                    mainContent
                }
            }
        }
        .presentationDetents([.large])
        .onAppear(perform: handleOnAppear)
        .onChange(of: appSettings.forceCaps) { oldValue, newValue in
            handleForceCapsChange(oldValue: oldValue, newValue: newValue)
        }
        .onChange(of: appSettings.defaultLabelType) { oldValue, newValue in
            handleLabelTypeChange(oldValue: oldValue, newValue: newValue)
        }
        .onChange(of: appSettings.customLabelPrefix) { oldValue, newValue in
            handleLabelPrefixChange(oldValue: oldValue, newValue: newValue)
        }
    }
    
    // Extract complex gradient calculation
    @ViewBuilder
    private func backgroundGradient(for geometry: GeometryProxy) -> some View {
        let width = geometry.size.width
        let height = geometry.size.height
        let maxDimension = max(width, height)
        let safeRadius = min(400, maxDimension).safe()
        
        RadialGradient(
            gradient: Gradient(colors: [Color.purple.opacity(0.45), Color.black]),
            center: .center,
            startRadius: 0,
            endRadius: safeRadius
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Header Section
    @ViewBuilder
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("NEW MESSAGE")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
            
            Text("Create message labels for organization")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.top, 32)
    }
    
    // MARK: - Label Input Section
    @ViewBuilder
    private var labelInputSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(getLabelFieldTitle())
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))
            
            TextField(getLabelFieldPlaceholder(), text: $labelValue)
                .focused($labelFieldFocused)
                #if os(iOS)
                .keyboardType(.numbersAndPunctuation)
                .disableAutocorrection(true)
                .textInputAutocapitalization(.never)
                #endif
                .font(.system(size: 18))
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.3))
                        .stroke(Color.purple.opacity(0.6), lineWidth: 1.5)
                )
                .foregroundColor(.white)
                .onTapGesture {
                    labelFieldFocused = true
                }
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") {
                            labelFieldFocused = false
                            messageFieldFocused = false
                        }
                        .foregroundColor(.purple)
                    }
                }
        }
    }
    
    // MARK: - Message Input Components
    @ViewBuilder
    private var capsIndicator: some View {
        Text("CAPS ON")
            .font(.system(size: 10, weight: .medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Color.purple.opacity(0.8))
            )
            .foregroundColor(.white)
            .padding(.all, 8)
    }
    
    @ViewBuilder
    private var messageInputField: some View {
        ZStack(alignment: .bottomTrailing) {
            TextField("Enter your message for the LED wall", text: messageTextBinding, axis: .vertical)
                .focused($messageFieldFocused)
                #if os(iOS)
                .disableAutocorrection(true)
                .submitLabel(.done)
                .textInputAutocapitalization(appSettings.forceCaps ? .characters : .never)
                .autocapitalization(appSettings.forceCaps ? .allCharacters : .none)
                #endif
                .font(.system(size: 18))
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.3))
                        .stroke(Color.purple.opacity(0.6), lineWidth: 1.5)
                )
                .foregroundColor(.white)
                .lineLimit(4...8)
                .onTapGesture {
                    messageFieldFocused = true
                }
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") {
                            labelFieldFocused = false
                            messageFieldFocused = false
                        }
                        .foregroundColor(.purple)
                    }
                }
            
            if appSettings.forceCaps && !rawMessageText.isEmpty {
                capsIndicator
            }
        }
        .onChange(of: appSettings.forceCaps) { oldValue, newValue in
            if newValue {
                messageText = rawMessageText.uppercased()
            } else {
                messageText = rawMessageText
            }
        }
    }
    
    @ViewBuilder
    private var messageInputSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("MESSAGE")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))
            
            messageInputField
        }
    }
    
    // Main content extracted to reduce complexity
    @ViewBuilder
    private var mainContent: some View {
        VStack(spacing: 32) {
            headerSection
            contentCard
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Content Card
    @ViewBuilder
    private var contentCard: some View {
        VStack(spacing: 32) {
            VStack(alignment: .leading, spacing: 28) {
                // Only show label input if not "No Label"
                if appSettings.defaultLabelType != 2 {
                    labelInputSection
                }
                messageInputSection
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.4))
                    .stroke(Color.purple.opacity(0.3), lineWidth: 1)
            )
            
            actionButtonsSection
                .padding(.bottom, 24)
        }
    }
    
    // MARK: - Action Button Components
    @ViewBuilder
    private var cancelButton: some View {
        Button("CANCEL") {
            onCancel()
        }
        .font(.system(size: 16, weight: .bold))
        .frame(maxWidth: .infinity)
        .frame(height: 56)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.3))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    LinearGradient(
                        colors: [Color.pink, Color.purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 2
                )
        )
        .foregroundColor(.white)
    }
    
    @ViewBuilder
    private var queueMessageButton: some View {
        Button("QUEUE MESSAGE") {
            let label = createLabel()
            let finalText = messageText
            
            print("Submitting message - raw: '\(rawMessageText)', formatted: '\(finalText)'")
            print("Settings - forceCaps: \(appSettings.forceCaps)")
            
            let message = Message(
                content: finalText,
                priority: .normal,
                label: label
            )
            
            onSubmit(message)
        }
        .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        .font(.system(size: 16, weight: .bold))
        .frame(maxWidth: .infinity)
        .frame(height: 56)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?
                    Color.gray.opacity(0.15) :
                    Color.purple.opacity(0.15)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?
                    LinearGradient(
                        colors: [Color.gray.opacity(0.5), Color.gray.opacity(0.5)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ) :
                    LinearGradient(
                        colors: [Color.purple, Color.blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 2
                )
        )
        .foregroundColor(.white)
    }
    
    @ViewBuilder
    private var actionButtonsSection: some View {
        HStack(spacing: 16) {
            cancelButton
            queueMessageButton
        }
    }
    
    // MARK: - State Change Handlers
    
    private func handleOnAppear() {
        // Initialize with correct formatting on appear
        print("🔤 Modal appeared with forceCaps: \(appSettings.forceCaps)")
        print("🔤 Modal appeared with defaultLabelType: \(appSettings.defaultLabelType)")
        print("🔤 Modal appeared with customLabelPrefix: '\(appSettings.customLabelPrefix)'")
        print("🔤 AppSettings instance: \(ObjectIdentifier(appSettings))")
        print("🔤 Current forceCaps value in storage: \(appSettings.forceCaps)")
        
        // Apply caps if needed
        if appSettings.forceCaps && !rawMessageText.isEmpty {
            messageText = rawMessageText.uppercased()
        }
        
        // Auto-focus on appropriate field
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if appSettings.defaultLabelType != 2 {
                // Focus on label field if label is required
                labelFieldFocused = true
            } else {
                // Focus on message field if no label needed
                messageFieldFocused = true
            }
        }
    }
    
    private func handleForceCapsChange(oldValue: Bool, newValue: Bool) {
        // When the forceCaps setting changes, reapply formatting
        if newValue {
            messageText = rawMessageText.uppercased()
        } else {
            messageText = rawMessageText
        }
        // Force UI update by updating binding
        print("Force caps changed to: \(newValue)")
    }
    
    private func handleLabelTypeChange(oldValue: Int, newValue: Int) {
        // Clear label value when label type changes
        labelValue = ""
        print("Label type changed from \(oldValue) to \(newValue)")
    }
    
    private func handleLabelPrefixChange(oldValue: String, newValue: String) {
        // UI will automatically refresh to show new custom prefix
        print("Custom label prefix changed from '\(oldValue)' to '\(newValue)'")
    }
    
    // MARK: - Helper Methods
    
    private func getLabelTypeDescription() -> String {
        let result: String
        switch appSettings.defaultLabelType {
        case 0:
            result = "Table • Number"
        case 1:
            let prefix = appSettings.customLabelPrefix.isEmpty ? "Custom" : appSettings.customLabelPrefix
            result = "\(prefix) Label"
        default:
            result = ""
        }
        return result
    }
    
    private func getLabelFieldTitle() -> String {
        switch appSettings.defaultLabelType {
        case 0:
            return "TABLE  NUMBER"
        case 1:
            let prefix = appSettings.customLabelPrefix.isEmpty ? "CUSTOM" : appSettings.customLabelPrefix.uppercased()
            return "\(prefix) LABEL"
        default:
            return ""
        }
    }
    
    private func getLabelFieldPlaceholder() -> String {
        switch appSettings.defaultLabelType {
        case 0:
            return "Enter table number"
        case 1:
            return "Enter label value"
        default:
            return ""
        }
    }
    
    private func createLabel() -> Message.Label? {
        guard appSettings.defaultLabelType != 2 else { return nil }
        
        let labelType: Message.MessageLabelType
        switch appSettings.defaultLabelType {
        case 0:
            labelType = .tableNumber
        case 1:
            labelType = .customLabel
        default:
            return nil
        }
        
        // For custom label, prepend the custom prefix if it exists
        let finalLabelText: String
        if appSettings.defaultLabelType == 1 && !appSettings.customLabelPrefix.isEmpty {
            finalLabelText = "\(appSettings.customLabelPrefix) \(labelValue)"
            print("Creating custom label: prefix='\(appSettings.customLabelPrefix)', value='\(labelValue)', final='\(finalLabelText)'")
        } else {
            finalLabelText = labelValue
            print("Creating \(labelType) label with text='\(finalLabelText)'")
        }
        
        return Message.Label(type: labelType, text: finalLabelText)
    }
}