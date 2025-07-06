//
//  LabelSettingsView.swift
//  LEDMessenger
//
//  Configure message label settings
//  Created: May 28, 2025
//

import SwiftUI
import Observation

struct LabelSettingsView: View {
    @Environment(AppSettings.self) private var appSettings
    
    // Focus state binding from parent
    var focusedField: FocusState<SettingsWizardView.Field?>.Binding
    
    // Local state for editing
    @State private var selectedLabelType: Int = 0
    @State private var customPrefix: String = ""
    @State private var hasChanges: Bool = false
    
    // Map Int values to descriptive names
    private let labelTypes = [
        (0, "Table Number", "Add table numbers to messages (e.g., 'Table 12')"),
        (1, "Custom Label", "Add custom prefix to messages"),
        (2, "No Label", "Messages without any labels")
    ]
    
    var body: some View {
        ZStack {
            // IMMEDIATE BLACK BACKGROUND
            Color.black
                .ignoresSafeArea()
            
            // iOS 18 Material background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.purple.opacity(0.15),
                    Color.indigo.opacity(0.1),
                    Color.black.opacity(0.3)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header Section
                    headerSection
                    
                    // Label Type Selection
                    labelTypeSection
                    
                    // Custom Prefix Input (shown only for custom label)
                    if selectedLabelType == 1 {
                        customPrefixSection
                    }
                    
                    // Preview Section
                    previewSection
                    
                    // Save Button
                    saveButton
                }
                .padding()
                .frame(maxWidth: 800)
            }
        }
        .navigationTitle("Label Settings")
        .onAppear {
            loadCurrentSettings()
        }
    }
    
    // MARK: - UI Components
    
    var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "tag.fill")
                    .font(.largeTitle)
                    .foregroundColor(.purple)
                
                Text("LABEL CONFIGURATION")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
            }
            
            Text("Configure how labels appear with your messages")
                .font(.headline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, 20)
    }
    
    var labelTypeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("LABEL TYPE")
                .font(.subheadline.bold())
                .foregroundColor(.white.opacity(0.8))
            
            VStack(spacing: 12) {
                ForEach(labelTypes, id: \.0) { type, name, description in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedLabelType = type
                            hasChanges = true
                        }
                    }) {
                        HStack {
                            // Radio button
                            Circle()
                                .fill(selectedLabelType == type ? Color.purple : Color.clear)
                                .frame(width: 20, height: 20)
                                .overlay(
                                    Circle()
                                        .stroke(Color.purple, lineWidth: 2)
                                )
                                .overlay(
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 8, height: 8)
                                        .opacity(selectedLabelType == type ? 1 : 0)
                                )
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(name)
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                Text(description)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedLabelType == type ? Color.black.opacity(0.6) : Color.black.opacity(0.3))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(selectedLabelType == type ? Color.purple : Color.clear, lineWidth: 2)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    var customPrefixSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CUSTOM PREFIX")
                .font(.subheadline.bold())
                .foregroundColor(.white.opacity(0.8))
            
            HStack {
                TextField("Enter custom prefix", text: $customPrefix)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(Color.black.opacity(0.4))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.purple, lineWidth: 1)
                    )
                    .foregroundColor(.white)
                    .focused(focusedField, equals: SettingsWizardView.Field.customLabel)
                    .onChange(of: customPrefix) { _, _ in
                        hasChanges = true
                    }
                
                // Clear button
                if !customPrefix.isEmpty {
                    Button(action: {
                        customPrefix = ""
                        hasChanges = true
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Text("This prefix will be added before the label value")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
    
    var previewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PREVIEW")
                .font(.subheadline.bold())
                .foregroundColor(.white.opacity(0.8))
            
            // Message Queue Preview (shows how labels appear in the UI)
            VStack(spacing: 16) {
                Text("Message Queue Organization")
                    .font(.headline)
                    .foregroundColor(.white)
                
                // Example of how it appears in the message list
                VStack(spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            if let label = getExampleLabel() {
                                Text(label)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.purple)
                            }
                            
                            Text("HAPPY BIRTHDAY VERONICA")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        // Mock buttons
                        HStack(spacing: 8) {
                            Text("EDIT")
                                .font(.caption.bold())
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.gray.opacity(0.3))
                                .cornerRadius(4)
                                .foregroundColor(.white)
                            
                            Text("SEND")
                                .font(.caption.bold())
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.purple.opacity(0.8))
                                .cornerRadius(4)
                                .foregroundColor(.white)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.black.opacity(0.3))
                    )
                }
                
                Text("Labels help organize messages in your queue - they do not appear on the LED display")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    var saveButton: some View {
        Button(action: saveSettings) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                Text("SAVE SETTINGS")
            }
            .font(.headline.bold())
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    colors: hasChanges ? [.purple, .pink] : [.gray, .gray.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
        }
        .disabled(!hasChanges)
    }
    
    // MARK: - Helper Methods
    
    private func loadCurrentSettings() {
        selectedLabelType = appSettings.defaultLabelType
        customPrefix = appSettings.customLabelPrefix
        hasChanges = false
    }
    
    private func saveSettings() {
        appSettings.updateLabelConfig(
            defaultLabelType: selectedLabelType,
            customLabelPrefix: customPrefix
        )
        hasChanges = false
        
        // Visual feedback
        withAnimation(.easeInOut(duration: 0.3)) {
            // Settings saved
        }
    }
    
    private func getExampleLabel() -> String? {
        switch selectedLabelType {
        case 0: // Table Number
            return "TABLE 12"
        case 1: // Custom Label
            let prefix = customPrefix.isEmpty ? "CUSTOM" : customPrefix.uppercased()
            return "\(prefix) A1"
        case 2: // No Label
            return nil
        default:
            return nil
        }
    }
}

#Preview {
    @FocusState var focusedField: SettingsWizardView.Field?
    return LabelSettingsView(focusedField: $focusedField)
        .environment(AppSettings())
}