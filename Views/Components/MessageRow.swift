//
//  MessageRow.swift
//  LEDMessenger
//
//  Updated on May 21, 2025
//

import SwiftUI

// MARK: - Color Extensions
// Using fileprivate extension to avoid conflicts with other files
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

// MARK: - MessageRow Implementation
// Note: Using safe() extension from SafeLayoutExtensions.swift

struct MessageRow: View {
    // MARK: - Properties
    
    /// Table number or identifier to display
    let tableNumber: String
    
    /// Message content to display
    let message: String
    
    /// Starting slot for LED wall configuration
    let startingSlot: Int
    
    /// Number of clips configured for LED wall
    let clipCount: Int
    
    /// Callback when delete button is pressed, receives clear slot index
    var onDelete: (_ clearSlotIndex: Int) -> Void
    
    /// Callback when send button is pressed
    var onSend: () -> Void
    
    /// Optional callback when edit button is pressed
    var onEdit: (() -> Void)? = nil
    
    /// Whether the message has been sent (controls UI state)
    var isSent: Bool = false
    
    /// Whether any message is currently being sent (disables send button)
    var isSending: Bool = false
    
    // Define colors for glow effect
    private let glowColor = Color(hex: 0x7428c6)

    // MARK: - Body
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                // Dynamic label (TABLE 3, CUSTOMER NAME, etc.) in lighter purple
                Text(tableNumber.uppercased())
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color(hex: 0xaf34cb)) // Lighter purple like New Message button
                
                // Message content
                Text(message)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
            }
            
            Spacer()
            
            // Right side buttons based on sent status
            if isSent {
                // Show EDIT and CANCEL buttons for sent messages
                HStack(spacing: 12) {
                    Button(action: {
                        if let editHandler = onEdit {
                            editHandler()
                        }
                    }) {
                        Text("EDIT")
                            .font(.system(size: 14, weight: .semibold))
                            .frame(minWidth: 60, minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.white)
                    .tint(Color(hex: 0x8837db))
                    .contentShape(Rectangle())
                    
                    Button(action: {
                        // Use onDelete for cancel functionality
                        // Clear slot should be calculated from the actual start slot, not current slot
                        onDelete(startingSlot + clipCount)
                    }) {
                        Text("CANCEL")
                            .font(.system(size: 14, weight: .semibold))
                            .frame(minWidth: 70, minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(hex: 0xe04c63))
                    .contentShape(Rectangle())
                }
            } else {
                // Show EDIT, DELETE, and SEND TO WALL buttons for unsent messages
                HStack(spacing: 12) {
                    Button(action: {
                        if let editHandler = onEdit {
                            editHandler()
                        }
                    }) {
                        Text("EDIT")
                            .font(.system(size: 14, weight: .semibold))
                            .frame(minWidth: 60, minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.white)
                    .tint(Color(hex: 0x8837db))
                    .contentShape(Rectangle())
                    
                    Button(action: {
                        // Call onDelete without clear slot since it's not sent yet
                        onDelete(-1) // Pass -1 to indicate deletion without clear slot
                    }) {
                        Text("DELETE")
                            .font(.system(size: 14, weight: .semibold))
                            .frame(minWidth: 70, minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.white)
                    .tint(Color(hex: 0xe04c63))
                    .contentShape(Rectangle())
                    
                    Button(action: onSend) {
                        Text("SEND TO WALL")
                            .font(.system(size: 14, weight: .semibold))
                            .frame(minWidth: 110, minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(hex: 0x7428c6))
                    .disabled(isSending)
                    .opacity(isSending ? 0.6 : 1.0)
                    .contentShape(Rectangle())
                }
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.purple.opacity(0.1))
        )
        // Add the glow effect with overlay when message is sent
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(isSent ? glowColor : .clear, lineWidth: 2)
                .shadow(color: isSent ? glowColor.opacity(0.6) : .clear, radius: 4, x: 0, y: 0)
        )
        .frame(minHeight: 80) // Ensure minimum row height to prevent invalid dimensions
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        MessageRow(
            tableNumber: "Table 12", 
            message: "UNSENT MESSAGE", 
            startingSlot: 0, 
            clipCount: 3,
            onDelete: { _ in }, 
            onSend: {}, 
            onEdit: { print("Edit tapped") }
        )
        MessageRow(
            tableNumber: "Table 14", 
            message: "SENT MESSAGE", 
            startingSlot: 0, 
            clipCount: 3,
            onDelete: { _ in }, 
            onSend: {}, 
            onEdit: { print("Edit tapped") }, 
            isSent: true
        )
    }
    .padding()
    .background(Color.black)
}