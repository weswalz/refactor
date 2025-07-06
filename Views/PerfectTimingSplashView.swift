//
//  PerfectTimingSplashView.swift
//  LED MESSENGER
//
//  Example of perfect timing for the black curtain transition
//

import SwiftUI

@available(iOS 18.0, macCatalyst 18.0, *)
struct PerfectTimingSplashView: View {
    let onComplete: () -> Void
    
    @State private var showBlackCurtain = false
    @State private var isAnimationComplete = false
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    // Total animation is ~1.4 seconds
    let animationDuration: Double = 1.4
    let curtainStartDelay: Double = 0.4  // Start curtain 1 second before end
    let curtainSlideDuration: Double = 1.0
    
    var animationSize: CGFloat {
        if horizontalSizeClass == .regular && verticalSizeClass == .regular {
            return 600
        } else if horizontalSizeClass == .regular {
            return 400
        } else {
            return 300
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.black, Color(red: 0.44, green: 0.15, blue: 0.78)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Animation content
                VStack(spacing: 40) {
                    Spacer()
                    
                    SmartLottieView(
                        animationName: "intro",
                        loop: false,
                        animationSpeed: 1.0
                    ) {
                        // Animation completed
                        isAnimationComplete = true
                    }
                    .frame(width: animationSize, height: animationSize)
                    .scaleEffect(horizontalSizeClass == .regular ? 1.0 : 0.8)
                    
                    Spacer()
                }
                .opacity(isAnimationComplete ? 0 : 1) // Fade out when complete
                .animation(.easeOut(duration: 0.3), value: isAnimationComplete)
                
                // Black curtain sliding up from bottom
                Rectangle()
                    .fill(Color.black)
                    .frame(height: geometry.size.height * 2)
                    .offset(y: showBlackCurtain ? 0 : geometry.size.height * 2)
                    .animation(
                        .timingCurve(0.7, 0, 0.3, 1, duration: curtainSlideDuration),
                        value: showBlackCurtain
                    )
                    .ignoresSafeArea()
            }
        }
        .onAppear {
            // Start the curtain animation after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + curtainStartDelay) {
                showBlackCurtain = true
                
                // Call completion when curtain is fully up
                DispatchQueue.main.asyncAfter(deadline: .now() + curtainSlideDuration) {
                    onComplete()
                }
            }
        }
    }
}

// MARK: - Usage Example

@available(iOS 18.0, macCatalyst 18.0, *)
struct AppRootView: View {
    @State private var showingSplash = true
    
    var body: some View {
        ZStack {
            // Main app content
            if !showingSplash {
                // Your settings/dashboard view
                VStack {
                    Text("LED MESSENGER")
                        .font(.largeTitle)
                        .bold()
                    Text("Settings Screen")
                        .font(.title2)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(UIColor.systemBackground))
                .transition(.opacity.animation(.easeIn(duration: 0.5)))
            }
            
            // Splash screen
            if showingSplash {
                PerfectTimingSplashView {
                    withAnimation {
                        showingSplash = false
                    }
                }
                .transition(.identity)
            }
        }
    }
}

@available(iOS 18.0, macCatalyst 18.0, *)
#Preview("Perfect Timing Splash") {
    AppRootView()
}
