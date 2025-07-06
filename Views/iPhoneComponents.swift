//
//  iPhoneComponents.swift
//  LED MESSENGER
//
//  iPhone component imports and integration for iOS 18+ SwiftUI
//  This file serves as the main entry point for iPhone-specific components
//  Created: June 16, 2025
//

import SwiftUI

// MARK: - Component Imports
// All iPhone-specific components are now organized in separate files:
// - iPhoneHeaderComponents.swift: Header, status, and action bar components
// - iPhoneMessageComponents.swift: Message cards, lists, and interaction components
// - iPhoneDashboardComponents.swift: Main dashboard view and modals
// - iPhoneSettingsComponents.swift: Settings UI components

// This file maintains backward compatibility while keeping components organized
// Each component file is under 500 lines as per project requirements

// MARK: - Component Imports
// iPhone components are imported and available from their respective files:
// - iPhoneDashboardView from iPhoneDashboardComponents.swift
// - iPhoneHeaderView from iPhoneHeaderComponents.swift  
// - iPhoneActionBar from iPhoneHeaderComponents.swift
// - iPhoneMessageList from iPhoneMessageComponents.swift
// - iPhoneSettingsView from iPhoneSettingsComponents.swift
//
// No type aliases needed - components use their actual names directly

// MARK: - Integration Helpers

/// Helper extension for consistent haptic feedback across iPhone components
extension View {
    /// Provides standardized haptic feedback for iPhone interactions
    /// - Parameter style: The feedback style to use
    func withHapticFeedback(_ style: HapticFeedbackStyle = .light) -> some View {
        self.onTapGesture {
            performHapticFeedback(style)
        }
    }
    
    /// Performs haptic feedback with the specified style
    /// - Parameter style: The feedback style to use
    private func performHapticFeedback(_ style: HapticFeedbackStyle) {
        #if canImport(UIKit)
        switch style {
        case .light:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .medium:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .heavy:
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
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

/// Standardized haptic feedback styles for iPhone components
enum HapticFeedbackStyle {
    case light
    case medium
    case heavy
    case selection
    case success
    case error
}

// MARK: - iPhone-Specific Constants

/// Design constants for iPhone components
enum iPhoneDesignConstants {
    /// Standard padding values for iPhone layouts
    enum Padding {
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let extraLarge: CGFloat = 32
    }
    
    /// Standard corner radius values for iPhone components
    enum CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let extraLarge: CGFloat = 20
    }
    
    /// Standard heights for iPhone touch targets
    enum TouchTarget {
        static let minimum: CGFloat = 44
        static let preferred: CGFloat = 50
        static let large: CGFloat = 56
    }
    
    /// iPhone-optimized color scheme
    enum Colors {
        static let primary = Color.purple
        static let secondary = Color.blue
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
        static let background = Color.black
    }
}

// MARK: - Preview Helpers

/// Preview provider for iPhone components
struct iPhoneComponentsPreview: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("iPhone Components")
                .font(.title.bold())
                .foregroundStyle(.white)
            
            Text("All components have been split into separate files:")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("• iPhoneHeaderComponents.swift")
                Text("• iPhoneMessageComponents.swift") 
                Text("• iPhoneDashboardComponents.swift")
                Text("• iPhoneSettingsComponents.swift")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [.purple.opacity(0.3), .black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

#Preview("iPhone Components Overview") {
    iPhoneComponentsPreview()
}
