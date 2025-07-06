// MARK: - Supporting Types for iPhone Settings





//
//  ModerniPhoneUIComponents.swift
//  LED MESSENGER
//
//  Modern UI components for iPhone settings using 2025 SwiftUI best practices
//  Created: June 15, 2025
//

import SwiftUI

// MARK: - Supporting Types for iPhone Settings





//
//  ModerniPhoneUIComponents.swift
//  LED MESSENGER
//
//  Modern UI components for iPhone settings using 2025 SwiftUI best practices
//  Created: June 15, 2025
//

import SwiftUI

// MARK: - Modern Text Field
struct ModernTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let icon: String
    var keyboardType: UIKeyboardType = .default
    
    // Support both internal and external focus management
    @FocusState private var internalFocus: Bool
    var externalFocus: FocusState<AnyHashable?>.Binding? = nil
    var focusValue: AnyHashable? = nil
    
    @State private var showClearButton = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(.primary)
            
            HStack(spacing: 12) {
                Group {
                    if let externalFocus = externalFocus, let focusValue = focusValue {
                        TextField(placeholder, text: $text)
                            .focused(externalFocus, equals: focusValue)
                            .textFieldStyle(.plain)
                            .font(.body)
                            .keyboardType(keyboardType)
                            .submitLabel(.done)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                            .onSubmit {
                                externalFocus.wrappedValue = nil
                            }
                            // Ensure immediate tap response
                            .simultaneousGesture(
                                TapGesture().onEnded {
                                    externalFocus.wrappedValue = focusValue
                                }
                            )
                    } else {
                        TextField(placeholder, text: $text)
                            .focused($internalFocus)
                            .textFieldStyle(.plain)
                            .font(.body)
                            .keyboardType(keyboardType)
                            .submitLabel(.done)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                            .onSubmit {
                                internalFocus = false
                            }
                            // Ensure immediate tap response
                            .simultaneousGesture(
                                TapGesture().onEnded {
                                    internalFocus = true
                                }
                            )
                    }
                }
                
                // Clear button
                if !text.isEmpty && (internalFocus || (externalFocus?.wrappedValue == focusValue)) {
                    Button(action: {
                        withAnimation(.smooth(duration: 0.15)) {
                            text = ""
                        }
                        // Maintain focus
                        if let externalFocus = externalFocus, let focusValue = focusValue {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                externalFocus.wrappedValue = focusValue
                            }
                        } else {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                internalFocus = true
                            }
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .imageScale(.medium)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .transition(.scale.combined(with: .opacity))
                }
                
                // Inline done button
                if internalFocus || (externalFocus?.wrappedValue == focusValue) {
                    Button("Done") {
                        withAnimation(.smooth(duration: 0.2)) {
                            if let externalFocus = externalFocus {
                                externalFocus.wrappedValue = nil
                            } else {
                                internalFocus = false
                            }
                        }
                        #if canImport(UIKit)
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        #endif
                    }
                    .font(.subheadline.bold())
                    .foregroundStyle(.purple)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Material.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        (internalFocus || (externalFocus?.wrappedValue == focusValue)) ? .purple : .clear,
                        lineWidth: 2
                    )
            )
            .animation(.smooth(duration: 0.2), value: internalFocus)
            .animation(.smooth(duration: 0.2), value: externalFocus?.wrappedValue == focusValue)
            .animation(.smooth(duration: 0.2), value: !text.isEmpty)
        }
        // Make entire component tappable
        .contentShape(Rectangle())
        .onTapGesture {
            if let externalFocus = externalFocus, let focusValue = focusValue {
                if externalFocus.wrappedValue != focusValue {
                    externalFocus.wrappedValue = focusValue
                }
            } else if !internalFocus {
                internalFocus = true
            }
        }
    }
}

// MARK: - Modern Stepper
struct ModernStepper: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(.primary)
            
            HStack {
                Button(action: {
                    if value > range.lowerBound {
                        withAnimation(.smooth(duration: 0.2)) {
                            value -= 1
                        }
                        performHapticFeedback()
                    }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(value > range.lowerBound ? .purple : Color.secondary)
                        // FIX: Ensure the entire button area is tappable
                        .contentShape(Rectangle())
                }
                .disabled(value <= range.lowerBound)
                .buttonStyle(.plain)
                
                Spacer()
                
                Text("\(value)")
                    .font(.title2.bold())
                    .foregroundStyle(.primary)
                    .frame(minWidth: 40)
                    .contentTransition(.numericText())
                
                Spacer()
                
                Button(action: {
                    if value < range.upperBound {
                        withAnimation(.smooth(duration: 0.2)) {
                            value += 1
                        }
                        performHapticFeedback()
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(value < range.upperBound ? .purple : Color.secondary)
                        // FIX: Ensure the entire button area is tappable
                        .contentShape(Rectangle())
                }
                .disabled(value >= range.upperBound)
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Material.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private func performHapticFeedback() {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }
}

// MARK: - Modern Toggle
struct ModernToggle: View {
    let title: String
    let description: String
    @Binding var isOn: Bool
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(.primary)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Toggle("", isOn: $isOn)
                    .labelsHidden()
                    .tint(.purple)
                    .scaleEffect(1.1)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Material.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
        .onChange(of: isOn) { _, _ in
            #if canImport(UIKit)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            #endif
        }
    }
}

// MARK: - Modern Picker
struct ModernPicker: View {
    let title: String
    @Binding var selection: Int
    let options: [(Int, String)]
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(.primary)
            
            Picker(title, selection: $selection) {
                ForEach(options, id: \.0) { value, label in
                    Text(label).tag(value)
                }
            }
            .pickerStyle(.segmented)
            .background(Material.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
        .onChange(of: selection) { _, _ in
            #if canImport(UIKit)
            UISelectionFeedbackGenerator().selectionChanged()
            #endif
        }
    }
}

// MARK: - Modern Slider
struct ModernSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let format: String
    let icon: String
    
    var formattedValue: String {
        String(format: format, value)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(title, systemImage: icon)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Text(formattedValue)
                    .font(.headline)
                    .foregroundStyle(.purple)
                    .contentTransition(.numericText())
            }
            
            VStack(spacing: 12) {
                Slider(value: $value, in: range, step: step)
                    .tint(.purple)
                
                HStack {
                    Text(String(format: format, range.lowerBound))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text(String(format: format, range.upperBound))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Material.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
        .onChange(of: value) { _, _ in
            #if canImport(UIKit)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            #endif
        }
    }
}

// MARK: - Label Type Card
struct LabelTypeCard: View {
    let option: LabelTypeOption
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: {
            onSelect()
            #if canImport(UIKit)
            UISelectionFeedbackGenerator().selectionChanged()
            #endif
        }) {
            HStack(spacing: 16) {
                // Icon with selection state
                ZStack {
                    Circle()
                        .fill(isSelected ? AnyShapeStyle(.purple.gradient) : AnyShapeStyle(Material.ultraThinMaterial))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: option.icon)
                        .font(.title2)
                        .foregroundStyle(isSelected ? .white : .purple)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(option.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text(option.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? .purple : Color.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Material.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? .purple : .clear, lineWidth: 2)
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.smooth(duration: 0.3), value: isSelected)
        }
        .buttonStyle(.plain)
        // FIX: Make the entire card tappable
        .contentShape(Rectangle())
    }
}

// MARK: - Connection Result Card
struct ConnectionResultCard: View {
    let result: ConnectionResult
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.title2)
                .foregroundStyle(iconColor)
            
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(backgroundColor, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(strokeColor, lineWidth: 1)
        )
    }
    
    private var iconName: String {
        result.isSuccess ? "checkmark.circle.fill" : "xmark.circle.fill"
    }
    
    private var iconColor: Color {
        result.isSuccess ? .green : .red
    }
    
    private var backgroundColor: Color {
        result.isSuccess ? .green.opacity(0.1) : .red.opacity(0.1)
    }
    
    private var strokeColor: Color {
        result.isSuccess ? .green.opacity(0.3) : .red.opacity(0.3)
    }
    
    private var message: String {
        result.message
    }
}

// MARK: - Clip Preview Card
struct ClipPreviewCard: View {
    let layer: Int
    let startSlot: Int
    let clipCount: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Configuration Preview")
                .font(.headline)
                .foregroundStyle(.primary)
            
            VStack(spacing: 8) {
                SettingsInfoRow(title: "Layer", value: "\(layer)", icon: "square.stack")
                SettingsInfoRow(title: "Clips Used", value: "\(startSlot)-\(startSlot + clipCount - 1)", icon: "play.rectangle")
                SettingsInfoRow(title: "Clear Slot", value: "\(startSlot + clipCount)", icon: "xmark.circle")
            }
            
            // Visual representation
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(startSlot..<(startSlot + clipCount + 2), id: \.self) { slot in
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(clipColor(for: slot))
                                .frame(width: 40, height: 30)
                                .overlay(
                                    Text("\(slot)")
                                        .font(.caption.bold())
                                        .foregroundStyle(.white)
                                )
                            
                            Text(clipLabel(for: slot))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
            .frame(height: 60)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Material.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    private func clipColor(for slot: Int) -> Color {
        if slot >= startSlot && slot < startSlot + clipCount {
            return .green // Message clips
        } else if slot == startSlot + clipCount {
            return .red // Clear clip
        } else {
            return .gray.opacity(0.3) // Unused
        }
    }
    
    private func clipLabel(for slot: Int) -> String {
        if slot >= startSlot && slot < startSlot + clipCount {
            return "MSG"
        } else if slot == startSlot + clipCount {
            return "CLR"
        } else {
            return "—"
        }
    }
}

// MARK: - Label Preview Card
struct LabelPreviewCard: View {
    let labelType: Int
    let customPrefix: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Preview")
                .font(.headline)
                .foregroundStyle(.primary)
            
            VStack(alignment: .leading, spacing: 8) {
                if let exampleLabel = generateExampleLabel() {
                    Text(exampleLabel)
                        .font(.subheadline.bold())
                        .foregroundStyle(.purple)
                }
                
                Text("HAPPY BIRTHDAY VERONICA!")
                    .font(.body.bold())
                    .foregroundStyle(.primary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.black.opacity(0.3), in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.purple.opacity(0.3), lineWidth: 1)
            )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Material.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    private func generateExampleLabel() -> String? {
        switch labelType {
        case 0: return "TABLE 12"
        case 1: 
            let prefix = customPrefix.isEmpty ? "CUSTOM" : customPrefix.uppercased()
            return "\(prefix) A1"
        case 2: return nil
        default: return nil
        }
    }
}

// MARK: - Text Preview Card
struct TextPreviewCard: View {
    let text: String
    let forceCaps: Bool
    let lineBreakMode: Int
    let charactersPerLine: Int
    
    private var formattedText: String {
        var result = forceCaps ? text.uppercased() : text
        
        if lineBreakMode == 2 && charactersPerLine > 0 {
            // Character-based line breaking
            let words = result.components(separatedBy: " ")
            var lines = [String]()
            var currentLine = ""
            
            for word in words {
                if currentLine.isEmpty {
                    currentLine = word
                } else if (currentLine + " " + word).count <= charactersPerLine {
                    currentLine += " " + word
                } else {
                    lines.append(currentLine)
                    currentLine = word
                }
            }
            
            if !currentLine.isEmpty {
                lines.append(currentLine)
            }
            
            result = lines.joined(separator: "\n")
        }
        
        return result
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Live Preview")
                .font(.headline)
                .foregroundStyle(.primary)
            
            // LED display simulation
            VStack(spacing: 8) {
                // Display header
                HStack {
                    Circle()
                        .fill(.green)
                        .frame(width: 8, height: 8)
                    
                    Text("LED DISPLAY")
                        .font(.caption.bold())
                        .foregroundStyle(.green)
                    
                    Spacer()
                    
                    Text("LIVE")
                        .font(.caption.bold())
                        .foregroundStyle(.green)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.black)
                
                // Display content
                ScrollView {
                    Text(formattedText.isEmpty ? "Enter text to preview..." : formattedText)
                        .font(.system(.body, design: .monospaced, weight: .medium))
                        .foregroundStyle(formattedText.isEmpty ? Color.secondary : .green)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, minHeight: 60)
                        .padding()
                }
                .background(.black)
                .frame(maxHeight: 100)
            }
            .background(.black, in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.green.opacity(0.5), lineWidth: 2)
            )
            
            // Format info
            HStack {
                Text("Format:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(formatDescription)
                    .font(.caption.bold())
                    .foregroundStyle(.purple)
                
                Spacer()
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Material.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    private var formatDescription: String {
        var parts: [String] = []
        
        if forceCaps {
            parts.append("UPPERCASE")
        }
        
        switch lineBreakMode {
        case 1: parts.append("Word Breaks")
        case 2: parts.append("\(charactersPerLine) Chars/Line")
        default: parts.append("No Breaks")
        }
        
        return parts.joined(separator: " • ")
    }
}

// MARK: - Settings Info Row (renamed to avoid conflicts)
struct SettingsInfoRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(.purple)
                .frame(width: 20)
            
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline.bold())
                .foregroundStyle(.primary)
        }
    }
}