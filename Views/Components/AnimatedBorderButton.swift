//
//  AnimatedBorderButton.swift
//  LED MESSENGER
//
//  Animated border button component
//  Created: May 28, 2025
//

import SwiftUI

/// A button with a seamlessly looping animated gradient border
/// Features a beautiful rotating rainbow border with no visible seams or jumps
struct AnimatedBorderButton<Label: View>: View {
    // MARK: - Properties
    
    /// The action to perform when the button is tapped
    let action: () -> Void
    
    /// The button's label content
    @ViewBuilder let label: () -> Label
    
    /// The button's corner radius
    let cornerRadius: CGFloat
    
    /// The border line width
    let lineWidth: CGFloat
    
    /// The primary tint color for the button
    let tintColor: Color
    
    /// Animation state for the rotating border
    @State private var rotationAngle: Double = 0
    
    // MARK: - Initializer
    
    init(
        cornerRadius: CGFloat = 8,
        lineWidth: CGFloat = 2,
        tintColor: Color = .purple,
        action: @escaping () -> Void,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.cornerRadius = cornerRadius
        self.lineWidth = lineWidth
        self.tintColor = tintColor
        self.action = action
        self.label = label
    }
    
    // MARK: - Body
    
    var body: some View {
        Button(action: action) {
            label()
        }
        .buttonStyle(.borderedProminent)
        .tint(tintColor)
        .overlay(
            // Seamlessly rotating animated gradient border
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(
                    angularGradient(rotation: rotationAngle),
                    lineWidth: lineWidth * 2
                )
                .blur(radius: 1)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(
                            angularGradient(rotation: rotationAngle),
                            lineWidth: lineWidth
                        )
                )
        )
        .onAppear {
            startAnimation()
        }
    }
    
    // MARK: - Private Methods
    
    /// Creates an angular gradient with proper color looping for seamless animation
    private func angularGradient(rotation: Double) -> AngularGradient {
        AngularGradient(
            gradient: Gradient(colors: [
                Color(red: 0.69, green: 0.20, blue: 0.80),  // Purple
                Color(red: 0.91, green: 0.26, blue: 0.73),  // Pink
                Color(red: 0.49, green: 0.60, blue: 0.97),  // Blue
                Color(red: 0.91, green: 0.26, blue: 0.73),  // Pink
                Color(red: 0.69, green: 0.20, blue: 0.80)   // Purple (seamless loop)
            ]),
            center: .center,
            startAngle: .degrees(rotation),
            endAngle: .degrees(rotation + 360)
        )
    }
    
    /// Starts the seamless rotating border animation
    private func startAnimation() {
        // Seamless infinite rotation
        withAnimation(
            .linear(duration: 4.0)
            .repeatForever(autoreverses: false)
        ) {
            rotationAngle = 360
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 30) {
        AnimatedBorderButton(
            cornerRadius: 8,
            lineWidth: 2,
            tintColor: Color(red: 0.68, green: 0.20, blue: 0.80), // #af34cb
            action: { print("Button tapped!") }
        ) {
            Text("New Message")
        }
        
        AnimatedBorderButton(
            cornerRadius: 12,
            lineWidth: 3,
            tintColor: .blue,
            action: { print("Custom button tapped!") }
        ) {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Add Item")
            }
        }
    }
    .padding()
    .background(Color.black)
}