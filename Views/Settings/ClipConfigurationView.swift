//
//  ClipConfigurationView.swift
//  LEDMessenger
//  Updated on May 27, 2025
//  Redesigned with functional controls and full canvas utilization
//

import SwiftUI
import Observation

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

struct ClipConfigurationView: View {
    // Use AppSettings to properly persist values
    @Environment(AppSettings.self) private var appSettings
    
    // Default values match AppSettings defaults (Layer 3, Slot 1, Clip Count 3)
    @State private var layer = 3
    @State private var startSlot = 1
    @State private var clipCount = 3
    @State private var selectedSlot: Int? = nil
    
    var onDismiss: (() -> Void)? = nil

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
            
            VStack(spacing: 0) {
                // Header
                header
                
                // Main Content Area - Uses full available space
                ScrollView {
                    VStack(spacing: 30) {
                        // Primary Controls Section
                        primaryControlsSection
                        
                        // Visual Preview Section
                        visualPreviewSection
                        
                        // Instructions Section
                        instructionsSection
                    }
                    .padding(24)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            // Load current values from settings
            loadFromAppSettings()
        }
        .onChange(of: layer) { _, _ in saveSettings() }
        .onChange(of: startSlot) { _, _ in saveSettings() }
        .onChange(of: clipCount) { _, _ in saveSettings() }
    }
    
    // Load the actual values from AppSettings
    private func loadFromAppSettings() {
        self.layer = appSettings.layer
        self.startSlot = appSettings.startSlot
        self.clipCount = appSettings.clipCount
    }
    
    // MARK: - UI Components
    
    var header: some View {
        HStack {
            Text("Clip Configuration")
                .font(.headline.bold())
                .foregroundColor(.primary)
            
            Spacer()
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
    
    // Primary Controls Section
    var primaryControlsSection: some View {
        VStack(spacing: 16) {
            Text("Settings")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Layer Control
            HStack {
                Text("Layer")
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                    .frame(width: 100, alignment: .leading)
                
                Spacer()
                
                HStack(spacing: 16) {
                    Button(action: { layer = max(1, layer - 1) }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.title3)
                            .foregroundColor(.purple)
                    }
                    .buttonStyle(.plain)
                    
                    Text("\(layer)")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 40)
                    
                    Button(action: { layer = min(20, layer + 1) }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(.purple)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.4))
                    .stroke(.purple.opacity(0.2), lineWidth: 1)
            )
            
            // Start Slot Control
            HStack {
                Text("Start Slot")
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                    .frame(width: 100, alignment: .leading)
                
                Spacer()
                
                HStack(spacing: 16) {
                    Button(action: { startSlot = max(1, startSlot - 1) }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.title3)
                            .foregroundColor(.purple)
                    }
                    .buttonStyle(.plain)
                    
                    Text("\(startSlot)")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 40)
                    
                    Button(action: { startSlot = min(255, startSlot + 1) }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(.purple)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.4))
                    .stroke(.purple.opacity(0.2), lineWidth: 1)
            )
            
            // Clip Count Control
            HStack {
                Text("Clip Count")
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                    .frame(width: 100, alignment: .leading)
                
                Spacer()
                
                HStack(spacing: 16) {
                    Button(action: { clipCount = max(1, clipCount - 1) }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.title3)
                            .foregroundColor(.purple)
                    }
                    .buttonStyle(.plain)
                    
                    Text("\(clipCount)")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 40)
                    
                    Button(action: { clipCount = min(5, clipCount + 1) }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(.purple)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.4))
                    .stroke(.purple.opacity(0.2), lineWidth: 1)
            )
        }
    }
    
    // Visual Preview Section
    var visualPreviewSection: some View {
        VStack(spacing: 16) {
            // Visual slot representation
            resolumePreview
        }
    }
    
    // Resolume interface preview
    var resolumePreview: some View {
        VStack(spacing: 12) {
            Text("Slot Visualization")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Scrollable slot grid
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHGrid(rows: [GridItem(.fixed(60))], spacing: 8) {
                    ForEach(1...255, id: \.self) { slot in
                        slotCell(slot: slot)
                    }
                }
                .padding(.horizontal)
            }
            .frame(height: 80)
            .background(Color.black)
            .cornerRadius(12)
            
            // Legend
            HStack(spacing: 20) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 12, height: 12)
                    Text("Message slots")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 12, height: 12)
                    Text("Clear slot")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 12, height: 12)
                    Text("Available")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
        }
    }
    
    // Individual slot cell
    func slotCell(slot: Int) -> some View {
        let isInRange = slot >= startSlot && slot < (startSlot + clipCount)
        let isClearSlot = slot == (startSlot + clipCount)
        let isSelected = selectedSlot == slot
        
        return VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 8)
                .fill(isClearSlot ? Color.red.opacity(0.6) : (isInRange ? Color.green.opacity(0.8) : Color.gray.opacity(0.2)))
                .frame(width: 50, height: 50)
                .overlay(
                    VStack(spacing: 2) {
                        if isClearSlot {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title3)
                                .foregroundColor(.white)
                        }
                        Text("\(slot)")
                            .font(isClearSlot ? .caption : .headline)
                            .foregroundColor(isClearSlot || isInRange ? .white : .gray)
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.yellow : Color.clear, lineWidth: 3)
                )
        }
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
        .onTapGesture {
            withAnimation {
                selectedSlot = slot
            }
        }
    }
    
    // Instructions Section
    var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Setup Instructions")
                .font(.title2.bold())
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 12) {
                instructionRow(number: "1", text: "Add Text Animator effects to slots \(startSlot)-\(startSlot + clipCount - 1) (\(clipCount) clips)")
                instructionRow(number: "2", text: "Leave slot \(startSlot + clipCount) empty - this is the CLEAR slot")
                instructionRow(number: "3", text: "Ensure layer \(layer) opacity is up and the layer is active")
                instructionRow(number: "4", text: "Messages will cycle through the \(clipCount) text clips")
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.4))
                    .stroke(.purple.opacity(0.2), lineWidth: 1)
            )
        }
    }
    
    func instructionRow(number: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.headline)
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(Circle().fill(Color.purple))
            
            Text(text)
                .font(.body)
                .foregroundColor(.gray)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    
    private func testConnection() {
        // Send a test message to verify the configuration
        print("Testing Resolume connection with Layer \(layer), Slots \(startSlot)-\(startSlot + clipCount - 1)")
    }
    
    private func saveSettings() {
        // Save the current UI values to AppSettings
        appSettings.updateClipConfig(layer: layer, startSlot: startSlot, clipCount: clipCount)
        appSettings.forceSave()
        
        // Notify all view models to refresh their settings
        NotificationCenter.default.post(name: NSNotification.Name("SettingsChanged"), object: nil)
        
        print("Clip configuration saved: Layer \(layer), StartSlot \(startSlot), ClipCount \(clipCount)")
    }
}

// MARK: - Preview
#Preview {
    ClipConfigurationView()
        .background(Color.black)
        .environment(AppSettings())
}