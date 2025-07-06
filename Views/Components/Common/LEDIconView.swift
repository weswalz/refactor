//
//  LEDIconView.swift
//  LED MESSENGER
//
//  Reusable LED logo icon component for consistent branding
//  Created: July 2025
//

import SwiftUI

/// Standardized LED logo icon view
/// Uses ledmwide35 asset from Assets.xcassets
struct LEDIconView: View {
    /// Height of the icon (width scales proportionally)
    var height: CGFloat = 15
    
    /// Optional tint color
    var tintColor: Color? = nil
    
    /// Opacity for inactive states
    var opacity: Double = 1.0
    
    var body: some View {
        Image("ledmwide35")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: height)
            .foregroundColor(tintColor)
            .opacity(opacity)
    }
}

/// Convenience extension for tab headers
extension LEDIconView {
    /// Creates an icon optimized for tab headers
    static func tabIcon(isSelected: Bool) -> some View {
        LEDIconView(
            height: 15,
            tintColor: isSelected ? .purple : nil,
            opacity: isSelected ? 1.0 : 0.6
        )
    }
    
    /// Creates an icon optimized for view headers
    static func headerIcon(size: CGFloat = 40, gradient: Bool = true) -> some View {
        Group {
            if gradient {
                LEDIconView(height: size)
                    .overlay(
                        LinearGradient(
                            colors: [.purple, .purple.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .mask(
                            Image("ledmwide35")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        )
                    )
            } else {
                LEDIconView(height: size, tintColor: .purple)
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        // Tab icon examples
        HStack(spacing: 20) {
            LEDIconView.tabIcon(isSelected: true)
            LEDIconView.tabIcon(isSelected: false)
        }
        
        // Header icon examples
        LEDIconView.headerIcon(size: 40)
        LEDIconView.headerIcon(size: 60, gradient: false)
        
        // Custom examples
        LEDIconView(height: 30, tintColor: .blue)
        LEDIconView(height: 20, opacity: 0.5)
    }
    .padding()
    .background(Color.black)
}
