//
//  SplashView.swift
//  LED MESSENGER
//
//  Simple, clean splash screen with bottom-to-top black curtain
//

import SwiftUI

@available(iOS 18.0, macCatalyst 18.0, *)
struct EnhancedSplashView: View {
    let onComplete: () -> Void
    
    @State private var showBlackCurtain = false
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    // Responsive sizing based on device
    var animationSize: CGFloat {
        if horizontalSizeClass == .regular && verticalSizeClass == .regular {
            return 600  // iPad full screen
        } else {
            return 400  // iPad split view or Mac Catalyst
        }
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.black, Color(red: 0.44, green: 0.15, blue: 0.78)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Centered animation
            SmartLottieView(
                animationName: "intro",
                loop: false,
                animationSpeed: 1.0
            ) {
                // Animation fully completed - start curtain
                withAnimation(.easeInOut(duration: 1.0)) {
                    showBlackCurtain = true
                }
                
                // Notify parent after curtain is up
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    onComplete()
                }
            }
            .frame(width: animationSize, height: animationSize)
            
            // Black curtain overlay
            if showBlackCurtain {
                GeometryReader { geometry in
                    Rectangle()
                        .fill(Color.black)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .transition(.move(edge: .bottom))
                }
                .ignoresSafeArea()
            }
        }
    }
}

// MARK: - Simple Splash View (Backup)

@available(iOS 18.0, macCatalyst 18.0, *)
struct SplashView: View {
    let onComplete: () -> Void
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @State private var hasCompleted = false
    
    var animationSize: CGFloat {
        if horizontalSizeClass == .regular && verticalSizeClass == .regular {
            return 600  // iPad full screen
        } else {
            return 400  // iPad split view or Mac Catalyst
        }
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.black, Color(red: 0.44, green: 0.15, blue: 0.78)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            SmartLottieView(
                animationName: "intro",
                loop: false,
                animationSpeed: 1.0
            ) {
                if !hasCompleted {
                    hasCompleted = true
                    onComplete()
                }
            }
            .frame(width: animationSize, height: animationSize)
        }
        .onAppear {
            // Fallback timeout in case animation doesn't complete
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                if !hasCompleted {
                    hasCompleted = true
                    onComplete()
                }
            }
        }
    }
}

// MARK: - Previews

@available(iOS 18.0, macCatalyst 18.0, *)
#Preview("Enhanced Splash") {
    EnhancedSplashView {
        print("Transition complete!")
    }
}
