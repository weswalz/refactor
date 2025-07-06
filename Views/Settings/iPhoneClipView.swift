//
//  iPhoneClipView.swift
//  LED MESSENGER
//
//  iPhone-optimized clip configuration with 2025 SwiftUI design
//  Created: December 15, 2024
//

import SwiftUI
import Observation

struct iPhoneClipView: View {
    @Environment(AppSettings.self) private var appSettings
    
    @State private var layer: Int = 3
    @State private var startSlot: Int = 1
    @State private var clipCount: Int = 3
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                configurationSection
                visualPreviewSection
                quickSetupSection
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
            
            Text("Clip Configuration")
                .font(.title2.bold())
                .foregroundStyle(.white)
            
            Text("Configure Resolume Arena layers and clips")
                .font(.subheadline)
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Configuration Controls
    private var configurationSection: some View {
        VStack(spacing: 16) {
            // Layer Control
            configurationRow(
                title: "Layer",
                value: layer,
                range: 1...20,
                onIncrement: { 
                    layer = min(20, layer + 1)
                    saveSettings()
                },
                onDecrement: { 
                    layer = max(1, layer - 1)
                    saveSettings()
                }
            )
            
            // Start Slot Control
            configurationRow(
                title: "Start Slot",
                value: startSlot,
                range: 1...255,
                onIncrement: { 
                    startSlot = min(255, startSlot + 1)
                    saveSettings()
                },
                onDecrement: { 
                    startSlot = max(1, startSlot - 1)
                    saveSettings()
                }
            )
            
            // Clip Count Control
            configurationRow(
                title: "Clip Count",
                value: clipCount,
                range: 1...10,
                onIncrement: { 
                    clipCount = min(10, clipCount + 1)
                    saveSettings()
                },
                onDecrement: { 
                    clipCount = max(1, clipCount - 1)
                    saveSettings()
                }
            )
        }
    }
    
    private func configurationRow(
        title: String,
        value: Int,
        range: ClosedRange<Int>,
        onIncrement: @escaping () -> Void,
        onDecrement: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
            
            HStack(spacing: 16) {
                Button {
                    onDecrement()
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(value > range.lowerBound ? .purple : .gray)
                }
                .disabled(value <= range.lowerBound)
                
                Text("\(value)")
                    .font(.title.bold())
                    .foregroundStyle(.white)
                    .frame(minWidth: 60)
                    .multilineTextAlignment(.center)
                
                Button {
                    onIncrement()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(value < range.upperBound ? .purple : .gray)
                }
                .disabled(value >= range.upperBound)
                
                Spacer()
            }
        }
        .padding(16)
        .background(.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Visual Preview
    private var visualPreviewSection: some View {
        VStack(spacing: 16) {
            Text("Slot Preview")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Simplified slot visualization
            VStack(spacing: 12) {
                // Message slots
                HStack(spacing: 8) {
                    ForEach(startSlot..<(startSlot + clipCount), id: \.self) { slot in
                        slotView(slot: slot, type: .message)
                    }
                    
                    if clipCount < 5 {
                        ForEach((startSlot + clipCount)..<(startSlot + 5), id: \.self) { slot in
                            slotView(slot: slot, type: .unused)
                        }
                    }
                }
                
                // Clear slot
                HStack {
                    slotView(slot: startSlot + clipCount, type: .clear)
                    Spacer()
                }
                
                // Legend
                legendView
            }
            .padding(16)
            .background(.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private func slotView(slot: Int, type: SlotType) -> some View {
        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 8)
                .fill(type.color)
                .frame(width: 50, height: 50)
                .overlay(
                    VStack(spacing: 2) {
                        if type == .clear {
                            Image(systemName: "xmark")
                                .foregroundStyle(.white)
                                .font(.caption)
                        }
                        Text("\(slot)")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                    }
                )
            
            Text(type.label)
                .font(.caption2)
                .foregroundStyle(.gray)
                .lineLimit(1)
        }
    }
    
    private var legendView: some View {
        HStack(spacing: 16) {
            legendItem(color: .green, text: "Message")
            legendItem(color: .red, text: "Clear")
            legendItem(color: .gray.opacity(0.3), text: "Unused")
            Spacer()
        }
    }
    
    private func legendItem(color: Color, text: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            Text(text)
                .font(.caption)
                .foregroundStyle(.gray)
        }
    }
    
    // MARK: - Quick Setup
    private var quickSetupSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Setup")
                .font(.headline)
                .foregroundStyle(.white)
            
            VStack(spacing: 12) {
                quickSetupButton(
                    title: "Standard Setup",
                    subtitle: "Layer 3, Slots 1-3",
                    action: {
                        layer = 3
                        startSlot = 1
                        clipCount = 3
                        saveSettings()
                    }
                )
                
                quickSetupButton(
                    title: "Extended Setup",
                    subtitle: "Layer 2, Slots 1-5",
                    action: {
                        layer = 2
                        startSlot = 1
                        clipCount = 5
                        saveSettings()
                    }
                )
            }
        }
        .padding(16)
        .background(.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func quickSetupButton(title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                action()
            }
        } label: {
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
                
                Image(systemName: "arrow.right.circle.fill")
                    .foregroundStyle(.purple)
                    .font(.title3)
            }
            .padding(12)
            .background(.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
    
    // MARK: - Methods
    private func loadCurrentSettings() {
        layer = appSettings.layer
        startSlot = appSettings.startSlot
        clipCount = appSettings.clipCount
    }
    
    private func saveSettings() {
        appSettings.updateClipConfig(layer: layer, startSlot: startSlot, clipCount: clipCount)
    }
}

// MARK: - Slot Type
enum SlotType {
    case message, clear, unused
    
    var color: Color {
        switch self {
        case .message: return .green
        case .clear: return .red
        case .unused: return .gray.opacity(0.3)
        }
    }
    
    var label: String {
        switch self {
        case .message: return "MSG"
        case .clear: return "CLR"
        case .unused: return ""
        }
    }
}

#Preview {
    iPhoneClipView()
        .environment(AppSettings())
}
