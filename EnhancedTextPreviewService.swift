//
//  EnhancedTextPreviewService.swift
//  LEDMessenger
//
//  Enhanced text preview with multiple modes, colors, and animations
//  Created: May 26, 2025
//

import Foundation
import SwiftUI
import Observation

// MARK: - LED Display Models
public struct LEDDisplayMode: Identifiable, Hashable {
    public let id = UUID()
    public let name: String
    public let width: Int
    public let height: Int
    public let pixelSize: CGFloat
    public let backgroundColor: Color
    public let textColor: Color
    
    public static let presets: [LEDDisplayMode] = [
        LEDDisplayMode(name: "Small LED (16x8)", width: 16, height: 8, pixelSize: 8, backgroundColor: .black, textColor: .green),
        LEDDisplayMode(name: "Medium LED (32x16)", width: 32, height: 16, pixelSize: 6, backgroundColor: .black, textColor: .green),
        LEDDisplayMode(name: "Large LED (64x32)", width: 64, height: 32, pixelSize: 4, backgroundColor: .black, textColor: .green),
        LEDDisplayMode(name: "Ultra Wide (96x16)", width: 96, height: 16, pixelSize: 5, backgroundColor: .black, textColor: .green),
        LEDDisplayMode(name: "Stadium Display", width: 128, height: 64, pixelSize: 3, backgroundColor: .black, textColor: .red)
    ]
}

public struct LEDColorScheme: Identifiable, Hashable {
    public let id = UUID()
    public let name: String
    public let backgroundColor: Color
    public let primaryColor: Color
    public let secondaryColor: Color
    public let accentColor: Color
    
    public static let presets: [LEDColorScheme] = [
        LEDColorScheme(name: "Classic Green", backgroundColor: .black, primaryColor: .green, secondaryColor: .green.opacity(0.7), accentColor: .white),
        LEDColorScheme(name: "Bright Red", backgroundColor: .black, primaryColor: .red, secondaryColor: .orange, accentColor: .yellow),
        LEDColorScheme(name: "Electric Blue", backgroundColor: .black, primaryColor: .blue, secondaryColor: .cyan, accentColor: .white),
        LEDColorScheme(name: "Neon Purple", backgroundColor: .black, primaryColor: .purple, secondaryColor: .pink, accentColor: .white),
        LEDColorScheme(name: "Amber Classic", backgroundColor: .black, primaryColor: .orange, secondaryColor: .yellow, accentColor: .white),
        LEDColorScheme(name: "Rainbow", backgroundColor: .black, primaryColor: .red, secondaryColor: .blue, accentColor: .green)
    ]
}

public enum AnimationStyle: String, CaseIterable, Identifiable {
    case none = "Static"
    case scrollLeft = "Scroll Left"
    case scrollRight = "Scroll Right"
    case scrollUp = "Scroll Up"
    case scrollDown = "Scroll Down"
    case fadeIn = "Fade In"
    case flash = "Flash"
    case typewriter = "Typewriter"
    case matrix = "Matrix Effect"
    
    public var id: String { rawValue }
    
    public var duration: Double {
        switch self {
        case .none: return 0
        case .scrollLeft, .scrollRight: return 3.0
        case .scrollUp, .scrollDown: return 2.0
        case .fadeIn: return 1.5
        case .flash: return 0.5
        case .typewriter: return 2.0
        case .matrix: return 4.0
        }
    }
}

// MARK: - Enhanced Text Preview Service
@Observable
@available(iOS 18.0, *)
public final class EnhancedTextPreviewService: @unchecked Sendable {
    
    // MARK: - Published Properties
    public private(set) var currentDisplayMode: LEDDisplayMode = LEDDisplayMode.presets[1]
    public private(set) var currentColorScheme: LEDColorScheme = LEDColorScheme.presets[0]
    public private(set) var currentAnimation: AnimationStyle = .none
    public private(set) var previewText: String = ""
    public private(set) var formattedLines: [String] = []
    public private(set) var isAnimating: Bool = false
    public private(set) var exportData: Data?
    
    // Animation state
    @ObservationIgnored private var animationTimer: Timer?
    @ObservationIgnored private var animationOffset: CGFloat = 0
    @ObservationIgnored private var animationProgress: Double = 0
    
    // MARK: - Initialization
    public init() {
        // Default setup
    }
    
    deinit {
        stopAnimation()
    }
    
    // MARK: - Configuration Methods
    
    public func setDisplayMode(_ mode: LEDDisplayMode) {
        currentDisplayMode = mode
        updatePreview()
    }
    
    public func setColorScheme(_ scheme: LEDColorScheme) {
        currentColorScheme = scheme
        updatePreview()
    }
    
    public func setAnimation(_ animation: AnimationStyle) {
        currentAnimation = animation
        if animation != .none {
            startAnimation()
        } else {
            stopAnimation()
        }
    }
    
    public func updateText(_ text: String, with settings: TextFormattingSettings) {
        previewText = text
        formattedLines = formatTextToLines(text, settings: settings)
        updatePreview()
    }
    
    // MARK: - Animation Control
    
    private func startAnimation() {
        stopAnimation()
        isAnimating = true
        animationProgress = 0
        
        let frameRate = 30.0 // 30 FPS
        let interval = 1.0 / frameRate
        
        animationTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.updateAnimationFrame()
        }
    }
    
    private func stopAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
        isAnimating = false
        animationProgress = 0
        animationOffset = 0
    }
    
    private func updateAnimationFrame() {
        let frameTime = 1.0 / 30.0 // 30 FPS
        animationProgress += frameTime / currentAnimation.duration
        
        if animationProgress >= 1.0 {
            if currentAnimation == .flash || currentAnimation == .fadeIn {
                // Non-looping animations
                stopAnimation()
                return
            } else {
                // Looping animations
                animationProgress = 0
            }
        }
        
        updateAnimationOffset()
        updatePreview()
    }
    
    private func updateAnimationOffset() {
        switch currentAnimation {
        case .scrollLeft:
            animationOffset = -animationProgress * CGFloat(currentDisplayMode.width + 20)
        case .scrollRight:
            animationOffset = animationProgress * CGFloat(currentDisplayMode.width + 20)
        case .scrollUp:
            animationOffset = -animationProgress * CGFloat(currentDisplayMode.height + 10)
        case .scrollDown:
            animationOffset = animationProgress * CGFloat(currentDisplayMode.height + 10)
        default:
            animationOffset = 0
        }
    }
    
    // MARK: - Text Formatting
    
    private func formatTextToLines(_ text: String, settings: TextFormattingSettings) -> [String] {
        let processedText = settings.forceCaps ? text.uppercased() : text
        
        switch settings.lineBreakMode {
        case 0: // No line breaks
            return [processedText]
            
        case 1: // Break after words
            let words = processedText.components(separatedBy: " ")
            var lines: [String] = []
            var currentLine: [String] = []
            let wordsPerLine = max(1, Int(settings.charsPerLine) / 5)
            
            for (index, word) in words.enumerated() {
                currentLine.append(word)
                if (index + 1) % wordsPerLine == 0 || index == words.count - 1 {
                    lines.append(currentLine.joined(separator: " "))
                    currentLine = []
                }
            }
            
            return lines
            
        case 2: // Break after characters
            let charLimit = max(1, Int(settings.charsPerLine))
            var lines: [String] = []
            var currentLine = ""
            
            let words = processedText.components(separatedBy: " ")
            for word in words {
                if currentLine.count + word.count + 1 > charLimit && !currentLine.isEmpty {
                    lines.append(currentLine)
                    currentLine = word
                } else if currentLine.isEmpty {
                    currentLine = word
                } else {
                    currentLine += " " + word
                }
            }
            
            if !currentLine.isEmpty {
                lines.append(currentLine)
            }
            
            return lines
            
        default:
            return [processedText]
        }
    }
    
    // MARK: - Preview Generation
    
    private func updatePreview() {
        // This method would update the internal preview state
        // The actual visual preview is handled by the SwiftUI view
    }
    
    // MARK: - Export Functionality
    
    @MainActor
    public func exportPreviewAsImage(size: CGSize) async -> Data? {
        // This would generate an image representation of the current preview
        // For now, we'll return a placeholder
        return await generatePlaceholderImageData(size: size)
    }
    
    public func exportConfiguration() -> [String: Any] {
        return [
            "displayMode": [
                "name": currentDisplayMode.name,
                "width": currentDisplayMode.width,
                "height": currentDisplayMode.height
            ],
            "colorScheme": [
                "name": currentColorScheme.name,
                "backgroundColor": colorToHex(currentColorScheme.backgroundColor),
                "primaryColor": colorToHex(currentColorScheme.primaryColor)
            ],
            "animation": currentAnimation.rawValue,
            "text": previewText,
            "formattedLines": formattedLines
        ]
    }
    
    public func importConfiguration(_ config: [String: Any]) {
        // Implementation for importing preview configuration
        if let displayModeData = config["displayMode"] as? [String: Any],
           let modeName = displayModeData["name"] as? String {
            if let mode = LEDDisplayMode.presets.first(where: { $0.name == modeName }) {
                setDisplayMode(mode)
            }
        }
        
        if let colorSchemeData = config["colorScheme"] as? [String: Any],
           let schemeName = colorSchemeData["name"] as? String {
            if let scheme = LEDColorScheme.presets.first(where: { $0.name == schemeName }) {
                setColorScheme(scheme)
            }
        }
        
        if let animationName = config["animation"] as? String,
           let animation = AnimationStyle(rawValue: animationName) {
            setAnimation(animation)
        }
    }
    
    // MARK: - Helper Methods
    
    @MainActor
    private func generatePlaceholderImageData(size: CGSize) async -> Data? {
        // Generate a placeholder PNG data
        let renderer = ImageRenderer(content: 
            Rectangle()
                .fill(currentColorScheme.backgroundColor)
                .frame(width: size.width, height: size.height)
        )
        
        renderer.scale = 2.0 // Retina quality
        
        // For iPad and Mac Catalyst, use UIImage (UIKit)
        return renderer.uiImage?.pngData()
    }
    
    private func colorToHex(_ color: Color) -> String {
        // Convert SwiftUI Color to hex string
        // This is a simplified implementation
        return "#000000"
    }
}

// MARK: - Text Formatting Settings
public struct TextFormattingSettings {
    public let forceCaps: Bool
    public let lineBreakMode: Int
    public let charsPerLine: Double
    public let autoClearAfter: TimeInterval
    
    public init(forceCaps: Bool, lineBreakMode: Int, charsPerLine: Double, autoClearAfter: TimeInterval) {
        self.forceCaps = forceCaps
        self.lineBreakMode = lineBreakMode
        self.charsPerLine = charsPerLine
        self.autoClearAfter = autoClearAfter
    }
}

// MARK: - Extensions for iPad/Mac Catalyst compatibility
// Mac Catalyst uses UIKit, so no additional extensions needed
