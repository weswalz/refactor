//
//  TextFormattingView.swift
//  LEDMessenger
//
//  Advanced text formatting view with live LED preview
//  Created: May 24, 2025
//

import SwiftUI
import Observation

struct TextFormattingView: View {
    // MARK: - Environment & State
    @Environment(AppSettings.self) private var appSettings
    
    // Local state for UI controls
    @State private var forceCaps: Bool = true
    @State private var lineBreakMode: Int = 2
    @State private var charsPerLine: Double = 12.0
    @State private var autoClearMinutes: Double = 3.0
    
    // Fixed preview text
    private let previewText: String = "LED MESSENGER IS SO AWESOME"
    
    // Preview state
    @State private var formattedPreview: String = ""
    @State private var previewLines: [String] = []
    
    
    // MARK: - View Body
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
            
            VStack(spacing: 16) {
                // Header
                header
                
                // Main Content - Scrollable
                ScrollView {
                    VStack(spacing: 24) {
                        // Live Preview Section
                        livePreviewSection
                        
                        // Formatting Options Section
                        formattingOptionsSection
                        
                        // Auto-Clear Section
                        autoClearSection
                    }
                    .padding(24)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            loadSettingsFromAppSettings()
            updatePreview()
        }
        .onChange(of: forceCaps) { _, _ in 
            updatePreview()
            saveSettings()
        }
        .onChange(of: lineBreakMode) { _, _ in 
            updatePreview()
            saveSettings()
        }
        .onChange(of: charsPerLine) { _, _ in 
            updatePreview()
            saveSettings()
        }
        .onChange(of: autoClearMinutes) { _, _ in saveSettings() }
    }
    
    // MARK: - UI Components
    
    var header: some View {
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
            
            Text("Text Formatting")
                .font(.title2.bold())
                .foregroundStyle(.white)
            
            Text("Configure how text appears on the LED wall")
                .font(.subheadline)
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.6))
                .stroke(.purple.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }
    
    
    var livePreviewSection: some View {
        VStack(spacing: 12) {
            Text("Live LED Preview")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // LED Display Simulation
            ledDisplaySimulation
            
            // Preview Info
            VStack(spacing: 4) {
                Text("Preview shows actual formatting that will be sent to LED wall")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                if previewLines.count > 1 {
                    Text("\(previewLines.count) lines • \(previewLines.map { $0.count }.max() ?? 0) max chars per line")
                        .font(.caption)
                        .foregroundColor(.cyan)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.4))
                .stroke(.purple.opacity(0.2), lineWidth: 1)
        )
    }
    
    var ledDisplaySimulation: some View {
        VStack(spacing: 2) {
            // LED Display Header
            HStack {
                Circle()
                    .fill(Color.red)
                    .frame(width: 8, height: 8)
                Text("LED DISPLAY")
                    .font(.caption.bold())
                    .foregroundColor(.white)
                Spacer()
                Text("LIVE")
                    .font(.caption.bold())
                    .foregroundColor(.green)
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.black)
            
            // LED Text Display Area
            VStack(spacing: 4) {
                if previewLines.isEmpty {
                    Text("(empty)")
                        .font(.system(.title3, design: .monospaced))
                        .foregroundColor(.gray.opacity(0.5))
                        .frame(maxWidth: .infinity, minHeight: 60, alignment: .center)
                } else {
                    ForEach(Array(previewLines.enumerated()), id: \.offset) { index, line in
                        Text(line.isEmpty ? "(blank line)" : line)
                            .font(.system(.title3, design: .monospaced, weight: .medium))
                            .foregroundColor(line.isEmpty ? .gray.opacity(0.5) : .green)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.horizontal, 8)
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: 80)
            .background(Color.black)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.green.opacity(0.5), lineWidth: 1)
            )
        }
        .background(Color.black)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.green.opacity(0.3), lineWidth: 2)
        )
    }
    
    var formattingOptionsSection: some View {
        VStack(spacing: 16) {
            Text("Formatting Options")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Force Uppercase Toggle
            HStack {
                Text("Force Uppercase")
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Toggle("", isOn: $forceCaps)
                    .tint(.purple)
            }
            
            // Line Break Mode Picker
            VStack(spacing: 8) {
                HStack {
                    Text("Line Break Mode")
                        .font(.subheadline)
                        .foregroundColor(.white)
                    Spacer()
                }
                
                Picker("Line Break Mode", selection: $lineBreakMode) {
                    Text("No Line Breaks").tag(0)
                    Text("Break After Words").tag(1)
                    Text("Break After Characters").tag(2)
                }
                .pickerStyle(.segmented)
                .background(Color.purple.opacity(0.1))
            }
            
            // Characters Per Line Slider (only show for character-based line breaks)
            if lineBreakMode == 2 {
                VStack(spacing: 8) {
                    HStack {
                        Text("Characters Per Line")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text("\(Int(charsPerLine))")
                            .font(.headline)
                            .foregroundColor(.cyan)
                            .frame(width: 30)
                    }
                    
                    Slider(value: $charsPerLine, in: 2...40, step: 1)
                        .tint(.purple)
                    
                    HStack {
                        Text("2")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Spacer()
                        Text("40")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.4))
                .stroke(.purple.opacity(0.2), lineWidth: 1)
        )
    }
    
    var autoClearSection: some View {
        VStack(spacing: 12) {
            Text("Auto-Clear Settings")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 8) {
                HStack {
                    Text("Message Display Duration")
                        .font(.subheadline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("\(Int(autoClearMinutes)) min")
                        .font(.headline)
                        .foregroundColor(.cyan)
                        .frame(width: 50)
                }
                
                Slider(value: $autoClearMinutes, in: 1...10, step: 1)
                    .tint(.purple)
                
                HStack {
                    Text("1 min")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Spacer()
                    Text("10 min")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Text("Messages will automatically clear from the LED wall after this duration")
                .font(.caption)
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.4))
                .stroke(.purple.opacity(0.2), lineWidth: 1)
        )
    }
    
    
    // MARK: - Methods
    
    private func loadSettingsFromAppSettings() {
        forceCaps = appSettings.forceCaps
        lineBreakMode = appSettings.lineBreakMode
        charsPerLine = appSettings.charsPerLine > 0 ? appSettings.charsPerLine : 12.0
        autoClearMinutes = appSettings.autoClearAfter / 60.0 // Convert seconds to minutes
    }
    
    private func updatePreview() {
        // Create a temporary settings snapshot for preview
        let tempFormattedText = formatTextForPreview(previewText)
        formattedPreview = tempFormattedText
        previewLines = tempFormattedText.components(separatedBy: "\n")
    }
    
    private func formatTextForPreview(_ text: String) -> String {
        // Apply forced capitalization if enabled
        let formattedText = forceCaps ? text.uppercased() : text
        
        // Apply line breaks based on the lineBreakMode setting
        var result = formattedText
        
        switch lineBreakMode {
        case 0: // No line breaks
            break
            
        case 1: // Break after a certain number of words
            let words = formattedText.components(separatedBy: " ")
            var lines = [String]()
            var currentLine = [String]()
            var wordCount = 0
            let wordsPerLineLimit = max(1, Int(charsPerLine) / 5)
            
            for word in words {
                currentLine.append(word)
                wordCount += 1
                
                if wordCount >= wordsPerLineLimit {
                    lines.append(currentLine.joined(separator: " "))
                    currentLine = []
                    wordCount = 0
                }
            }
            
            if !currentLine.isEmpty {
                lines.append(currentLine.joined(separator: " "))
            }
            
            result = lines.joined(separator: "\n")
            
        case 2: // Break after a certain number of characters
            let charLimit = max(1, Int(charsPerLine))
            var lines = [String]()
            let words = formattedText.components(separatedBy: " ")
            var currentLine = ""
            
            for word in words {
                if currentLine.count + word.count + 1 > charLimit && !currentLine.isEmpty {
                    lines.append(currentLine)
                    currentLine = word
                } else if currentLine.isEmpty {
                    currentLine = word
                } else {
                    currentLine += " " + word
                }
            }
            
            if !currentLine.isEmpty {
                lines.append(currentLine)
            }
            
            result = lines.joined(separator: "\n")
            
        default:
            break
        }
        
        return result
    }
    
    private func saveSettings() {
        // Save all formatting settings to AppSettings
        appSettings.setForceCaps(forceCaps)
        appSettings.setLineBreakMode(lineBreakMode)
        appSettings.setCharsPerLine(charsPerLine)
        appSettings.setAutoClearAfter(autoClearMinutes * 60.0) // Convert minutes to seconds
        
        print("DEBUG: Text formatting settings saved")
    }
    
    private func sendTestToWall() {
        guard !previewText.isEmpty else { return }
        
        // Function no longer needed since we removed the test button
        print("DEBUG: Test message would be sent to LED wall: \(self.formattedPreview)")
    }
    
    private func clearWall() {
        print("DEBUG: Clearing LED wall")
        // Simulate clearing the wall
    }
}

// MARK: - Preview
#Preview {
    TextFormattingView()
        .background(Color.black)
        .environment(AppSettings())
}