//
//  LottieView.swift
//  LED MESSENGER
//
//  Real Lottie implementation for iOS 18 and SwiftUI
//  Uses Lottie 4.5.2 from lottie-spm package
//

import SwiftUI
import Lottie

@available(iOS 18.0, macCatalyst 18.0, *)
struct LottieView: UIViewRepresentable {
    let animationName: String
    let loop: Bool
    var animationSpeed: CGFloat = 1.0
    var onAnimationComplete: (() -> Void)?
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        
        // Create the Lottie animation view
        let animationView = LottieAnimationView(name: animationName)
        animationView.translatesAutoresizingMaskIntoConstraints = false
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = loop ? .loop : .playOnce
        animationView.animationSpeed = animationSpeed
        
        // Add to container view
        view.addSubview(animationView)
        
        // Add constraints
        NSLayoutConstraint.activate([
            animationView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            animationView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            animationView.topAnchor.constraint(equalTo: view.topAnchor),
            animationView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Play the animation
        animationView.play { finished in
            if finished && !loop {
                // Keep the animation on the last frame
                animationView.pause()
                animationView.currentProgress = 1.0
                onAnimationComplete?()
            }
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Find the animation view and update if needed
        if let animationView = uiView.subviews.first as? LottieAnimationView {
            animationView.loopMode = loop ? .loop : .playOnce
            animationView.animationSpeed = animationSpeed
        }
    }
}

// MARK: - Convenience Extensions

@available(iOS 18.0, macCatalyst 18.0, *)
extension LottieView {
    static func splash(animationName: String, onComplete: @escaping () -> Void) -> LottieView {
        return LottieView(
            animationName: animationName,
            loop: false,
            animationSpeed: 1.0,
            onAnimationComplete: onComplete
        )
    }
}

// MARK: - Fallback View (if Lottie fails to load)

@available(iOS 18.0, macCatalyst 18.0, *)
struct LottieFallbackView: View {
    let animationName: String
    let onAnimationComplete: (() -> Void)?
    
    // Animation states for the fallback LED letters
    @State private var showL = false
    @State private var showE1 = false
    @State private var showD = false
    @State private var showBottomText = false
    @State private var animationTask: Task<Void, Never>?
    
    var body: some View {
        ZStack {
            VStack(spacing: -30) {
                // LED Letters
                HStack(spacing: -20) {
                    // L
                    Text("L")
                        .font(.system(size: 200, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.673, green: 0.384, blue: 0.653))
                        .scaleEffect(showL ? 1 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showL)
                    
                    // E
                    Text("E")
                        .font(.system(size: 200, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.725, green: 0.464, blue: 0.694))
                        .scaleEffect(showE1 ? 1 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.15), value: showE1)
                    
                    // D
                    Text("D")
                        .font(.system(size: 200, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.673, green: 0.384, blue: 0.653))
                        .scaleEffect(showD ? 1 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.3), value: showD)
                }
                
                // MESSENGER text
                if showBottomText {
                    Text("MESSENGER")
                        .font(.system(size: 40, weight: .medium, design: .rounded))
                        .foregroundColor(.white)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .onAppear {
            startAnimation()
        }
        .onDisappear {
            animationTask?.cancel()
        }
    }
    
    private func startAnimation() {
        animationTask = Task { @MainActor in
            showL = true
            try? await Task.sleep(for: .seconds(0.15))
            
            showE1 = true
            try? await Task.sleep(for: .seconds(0.15))
            
            showD = true
            try? await Task.sleep(for: .seconds(0.3))
            
            withAnimation(.easeInOut(duration: 0.3)) {
                showBottomText = true
            }
            
            try? await Task.sleep(for: .seconds(1.0))
            
            onAnimationComplete?()
        }
    }
}

// MARK: - Smart Lottie View with Automatic Fallback

@available(iOS 18.0, macCatalyst 18.0, *)
struct SmartLottieView: View {
    let animationName: String
    let loop: Bool
    var animationSpeed: CGFloat = 1.0
    var onAnimationComplete: (() -> Void)?
    @State private var isLottieAvailable = true
    
    var body: some View {
        Group {
            if isLottieAvailable {
                LottieView(
                    animationName: animationName,
                    loop: loop,
                    animationSpeed: animationSpeed,
                    onAnimationComplete: onAnimationComplete
                )
                .onAppear {
                    // Check if animation file exists
                    if Bundle.main.path(forResource: animationName, ofType: "json") == nil {
                        print("⚠️ Lottie file '\(animationName).json' not found, using fallback")
                        isLottieAvailable = false
                    }
                }
            } else {
                LottieFallbackView(
                    animationName: animationName,
                    onAnimationComplete: onAnimationComplete
                )
            }
        }
    }
}

// MARK: - Previews

@available(iOS 18.0, macCatalyst 18.0, *)
#Preview("Lottie Animation") {
    ZStack {
        Color.black.ignoresSafeArea()
        
        LottieView(animationName: "intro", loop: false)
            .frame(width: 300, height: 300)
    }
}

@available(iOS 18.0, macCatalyst 18.0, *)
#Preview("Smart Lottie with Fallback") {
    ZStack {
        Color.black.ignoresSafeArea()
        
        SmartLottieView(animationName: "intro", loop: false)
            .frame(width: 300, height: 300)
    }
}
