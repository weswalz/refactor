//
//  AwardWinningButton.swift
//  LED MESSENGER
//
//  A sleek, award-winning button with fluid gradient animation
//  Created: May 28, 2025
//

import SwiftUI

/// A button with a fluid, animated gradient border that flows around the perimeter
struct AwardWinningButton<Label: View>: View {
    // MARK: - Properties
    
    /// The action to perform when the button is tapped
    let action: () -> Void
    
    /// The button's label content
    @ViewBuilder let label: () -> Label
    
    /// Animation progress states
    @State private var animationPhase: Double = 0
    @State private var glowIntensity: Double = 0.6
    @State private var isPressed: Bool = false
    
    // MARK: - Body
    
    var body: some View {
        Button(action: action) {
            label()
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    // Base gradient background
                    LinearGradient(
                        colors: [
                            Color(red: 0.08, green: 0.08, blue: 0.12),
                            Color(red: 0.12, green: 0.12, blue: 0.18)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    // Animated gradient border
                    GeometryReader { geometry in
                        
                        ZStack {
                            // Outer glow layer
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    seamlessGradient(phase: animationPhase),
                                    lineWidth: 3
                                )
                                .blur(radius: 8)
                                .opacity(glowIntensity)
                                .scaleEffect(isPressed ? 1.02 : 1.0)
                            
                            // Main gradient border
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    seamlessGradient(phase: animationPhase),
                                    lineWidth: 2
                                )
                                .shadow(color: Color(red: 0.91, green: 0.26, blue: 0.73).opacity(0.5), radius: 4)
                            
                            // Inner accent line
                            RoundedRectangle(cornerRadius: 11)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.3),
                                            Color.white.opacity(0.1)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 0.5
                                )
                                .padding(1)
                        }
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .scaleEffect(isPressed ? 0.98 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            startAnimations()
        }
        ._onButtonGesture { pressing in
            isPressed = pressing
        } perform: {
            action()
        }
    }
    
    // MARK: - Private Methods
    
    /// Creates a seamless angular gradient that can be animated continuously
    private func seamlessGradient(phase: Double) -> AngularGradient {
        // Create a gradient with colors that loop seamlessly
        let colors = [
            Color(red: 0.69, green: 0.20, blue: 0.80),  // Purple
            Color(red: 0.91, green: 0.26, blue: 0.73),  // Pink
            Color(red: 0.49, green: 0.60, blue: 0.97),  // Blue
            Color(red: 0.91, green: 0.26, blue: 0.73),  // Pink (repeat)
            Color(red: 0.69, green: 0.20, blue: 0.80)   // Purple (close the loop)
        ]
        
        return AngularGradient(
            gradient: Gradient(colors: colors),
            center: .center,
            startAngle: .degrees(phase),
            endAngle: .degrees(phase + 360)
        )
    }
    
    /// Starts all the continuous animations
    private func startAnimations() {
        // Main rotation animation - continuous and smooth
        withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
            animationPhase = 360
        }
        
        // Glow pulse animation
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            glowIntensity = 0.9
        }
    }
}

// MARK: - Button Gesture Modifier

extension View {
    func _onButtonGesture(
        pressing: @escaping (Bool) -> Void,
        perform action: @escaping () -> Void
    ) -> some View {
        self.simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    pressing(true)
                }
                .onEnded { _ in
                    pressing(false)
                }
        )
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        VStack(spacing: 40) {
            AwardWinningButton(
                action: { print("New Message tapped!") }
            ) {
                HStack {
                    Image(systemName: "plus.message.fill")
                        .font(.system(size: 16, weight: .medium))
                    Text("New Message")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
            }
            
            // Alternative style
            AwardWinningButton(
                action: { print("Create tapped!") }
            ) {
                Text("Create Something Amazing")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .padding()
    }
}