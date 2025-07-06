//
//  GradientButtonStyle.swift
//  LEDMessenger
//

import SwiftUI

struct GradientButtonStyle: ButtonStyle {
    let color: Color          // base hue (e.g. .purple or .pink)

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.bold))
            .padding(.horizontal, 32)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: [color.opacity(0.85), color.opacity(0.6)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                .cornerRadius(24)
            )
            .foregroundStyle(.white)
            .opacity(configuration.isPressed ? 0.75 : 1)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
    }
}