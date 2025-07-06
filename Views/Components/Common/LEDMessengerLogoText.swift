//
//  LEDMessengerLogoText.swift
//  LED MESSENGER
//
//  Consistent LED MESSENGER text logo component for settings screens
//  Created: July 2025
//

import SwiftUI

/// Styled LED MESSENGER text logo with consistent sizing
struct LEDMessengerLogoText: View {
    /// Scale factor for the logo (default is 0.7 for 70% size)
    var scale: CGFloat = 0.7
    
    var body: some View {
        Text("LED MESSENGER")
            .font(.system(size: 28 * scale, weight: .black, design: .default))
            .tracking(2.5 * scale)
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
    }
}

/// Extension for common logo header layout
extension LEDMessengerLogoText {
    /// Creates a standard header with logo, title, and subtitle
    static func settingsHeader(
        title: String,
        subtitle: String
    ) -> some View {
        VStack(spacing: 8) {
            LEDMessengerLogoText()
                .padding(.bottom, 16)
            
            Text(title)
                .font(.title2.bold())
                .foregroundStyle(.white)
            
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        // Default size (70%)
        LEDMessengerLogoText()
        
        // Full size comparison
        LEDMessengerLogoText(scale: 1.0)
        
        // Example header
        LEDMessengerLogoText.settingsHeader(
            title: "Network Connection",
            subtitle: "Connect to Resolume Arena via OSC"
        )
    }
    .padding()
    .background(Color.black)
}
