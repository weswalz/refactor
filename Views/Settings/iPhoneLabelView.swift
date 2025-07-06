//
//  iPhoneLabelView.swift
//  LED MESSENGER
//
//  iPhone-optimized label settings with 2025 SwiftUI design
//  Created: December 15, 2024
//

import SwiftUI
import Observation
import Foundation

struct iPhoneLabelView: View {
    @Environment(AppSettings.self) private var appSettings
    
    @State private var defaultLabelType: Message.MessageLabelType = .noLabel
    @State private var showTableNumbers: Bool = true
    @State private var showCustomerNames: Bool = false
    @State private var defaultTablePrefix: String = "Table"
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                labelTypeSection
                displayOptionsSection
                customizationSection
                exampleSection
            }
            .padding(20)
        }
        .background(.black)
        .onAppear {
            loadCurrentSettings()
        }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("LED MESSENGER")
                .font(.system(size: 19.6, weight: .black, design: .default))
                .tracking(1.75)
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(red: 0.8, green: 0.2, blue: 0.8),  // Pink
                            Color(red: 0.6, green: 0.2, blue: 0.9)   // Purple
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .padding(.bottom, 16)
            
            Text("Label Settings")
                .font(.title2.bold())
                .foregroundStyle(.white)
            
            Text("Configure message labels for organization")
                .font(.subheadline)
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Label Type Section
    private var labelTypeSection: some View {
        VStack(spacing: 16) {
            Text("Default Label Type")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                labelTypeOption(Message.MessageLabelType.noLabel, "No Label", "Messages appear without labels")
                labelTypeOption(Message.MessageLabelType.tableNumber, "Table Number", "Show table numbers for organization")
                // Note: Customer names not currently supported in architecture
                labelTypeOption(Message.MessageLabelType.customLabel, "Custom Label", "Use custom text labels")
            }
        }
    }
    
    private func labelTypeOption(_ type: Message.MessageLabelType, _ title: String, _ subtitle: String) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                defaultLabelType = type
                saveSettings()
            }
        } label: {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
                
                Spacer()
                
                Image(systemName: defaultLabelType == type ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(defaultLabelType == type ? .purple : .gray)
                    .font(.title3)
            }
            .padding(16)
            .background(defaultLabelType == type ? .purple.opacity(0.1) : .gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(defaultLabelType == type ? .purple : .clear, lineWidth: 2)
            )
        }
    }
    
    // MARK: - Display Options
    private var displayOptionsSection: some View {
        VStack(spacing: 16) {
            Text("Display Options")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            toggleOption(
                title: "Show Table Numbers",
                subtitle: "Display table numbers in message queue",
                isOn: $showTableNumbers
            )
            
            // Customer names toggle removed - not supported in current architecture
        }
    }
    
    private func toggleOption(title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
                
                Spacer()
                
                Toggle("", isOn: isOn)
                    .tint(.purple)
                    .onChange(of: isOn.wrappedValue) { _, _ in
                        saveSettings()
                    }
            }
        }
        .padding(16)
        .background(.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Customization
    private var customizationSection: some View {
        VStack(spacing: 16) {
            Text("Customization")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Table Prefix")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                
                TextField("Table", text: $defaultTablePrefix)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: defaultTablePrefix) { _, _ in
                        saveSettings()
                    }
                
                Text("Customize the text that appears before table numbers")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
            .padding(16)
            .background(.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Example Section
    private var exampleSection: some View {
        VStack(spacing: 16) {
            Text("Preview Examples")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                exampleMessage(
                    label: generateExampleLabel(Message.MessageLabelType.noLabel),
                    message: "Order ready for pickup"
                )
                
                if showTableNumbers {
                    exampleMessage(
                        label: generateExampleLabel(Message.MessageLabelType.tableNumber),
                        message: "Your food is ready"
                    )
                }
                
                // Customer names example removed - not supported in current architecture
                
                exampleMessage(
                    label: generateExampleLabel(Message.MessageLabelType.customLabel),
                    message: "Special announcement"
                )
            }
            .padding(16)
            .background(.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private func exampleMessage(label: String?, message: String) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                if let label = label, !label.isEmpty {
                    Text(label)
                        .font(.caption.bold())
                        .foregroundStyle(.cyan)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(.cyan.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.white)
            }
            
            Spacer()
        }
        .padding(12)
        .background(.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    // MARK: - Methods
    private func loadCurrentSettings() {
        // Map AppSettings Int values to Message.MessageLabelType enum
        let labelTypeInt = appSettings.defaultLabelType
        defaultLabelType = intToLabelType(labelTypeInt)
        defaultTablePrefix = appSettings.customLabelPrefix
        
        // Set display options based on label type
        showTableNumbers = (defaultLabelType == Message.MessageLabelType.tableNumber)
        showCustomerNames = false // Not supported in current architecture
    }
    
    private func saveSettings() {
        // Map enum to Int and save to AppSettings
        let labelTypeInt = labelTypeToInt(defaultLabelType)
        appSettings.updateLabelConfig(
            defaultLabelType: labelTypeInt,
            customLabelPrefix: defaultTablePrefix
        )
    }
    
    // MARK: - Type Conversion Helpers
    private func labelTypeToInt(_ type: Message.MessageLabelType) -> Int {
        switch type {
        case .tableNumber: return 0
        case .customLabel: return 1
        case .noLabel: return 2
        }
    }
    
    private func intToLabelType(_ value: Int) -> Message.MessageLabelType {
        switch value {
        case 0: return .tableNumber
        case 1: return .customLabel
        case 2: return .noLabel
        default: return .noLabel
        }
    }
    
    private func generateExampleLabel(_ type: Message.MessageLabelType) -> String? {
        switch type {
        case .noLabel:
            return nil
        case .tableNumber:
            return "\(defaultTablePrefix) 5"
        case .customLabel:
            return "VIP"
        }
    }
}

#Preview {
    iPhoneLabelView()
        .environment(AppSettings())
}
