//
//  SafeLayoutExtensions.swift
//  LED MESSENGER
//
//  Centralized safe layout system for preventing "Invalid frame dimension" errors
//  Created: June 22, 2025
//

import SwiftUI
import Foundation

// MARK: - Safe Layout Extensions

extension CGFloat {
    /// Returns a safe value for layout calculations
    /// Converts NaN, infinity, and negative values to safe defaults
    func safe() -> CGFloat {
        guard !self.isNaN && !self.isInfinite && self >= 0 else { return 0 }
        return self
    }
    
    /// Returns a safe value with minimum constraint
    func safeMinimum(_ minimum: CGFloat = 0) -> CGFloat {
        let validated = self.safe()
        return Swift.max(validated, minimum)
    }
    
    /// Returns a safe value with maximum constraint  
    func safeMaximum(_ maximum: CGFloat) -> CGFloat {
        let validated = self.safe()
        return Swift.min(validated, maximum)
    }
    
    /// Returns a safe value within specified bounds
    func safeClamped(to range: ClosedRange<CGFloat>) -> CGFloat {
        let validated = self.safe()
        return Swift.min(Swift.max(validated, range.lowerBound), range.upperBound)
    }
}

extension View {
    /// Safe frame modifier that prevents invalid frame dimensions
    func safeFrame(
        width: CGFloat? = nil,
        height: CGFloat? = nil,
        maxWidth: CGFloat? = nil,
        maxHeight: CGFloat? = nil,
        alignment: Alignment = .center
    ) -> some View {
        let safeWidth = width?.safe()
        let safeHeight = height?.safe()
        let safeMaxWidth = maxWidth?.safe() ?? .infinity
        let safeMaxHeight = maxHeight?.safe() ?? .infinity
        
        return self.frame(
            minWidth: nil,
            idealWidth: safeWidth,
            maxWidth: safeMaxWidth,
            minHeight: nil,
            idealHeight: safeHeight,
            maxHeight: safeMaxHeight,
            alignment: alignment
        )
    }
    
    /// Safe padding modifier
    func safePadding(_ edges: Edge.Set = .all, _ length: CGFloat? = nil) -> some View {
        let safeLength = length?.safe()
        return self.padding(edges, safeLength)
    }
    
    /// Safe shadow modifier
    func safeShadow(
        color: Color = .black,
        radius: CGFloat,
        x: CGFloat = 0,
        y: CGFloat = 0
    ) -> some View {
        self.shadow(
            color: color,
            radius: radius.safe(),
            x: x.safe(),
            y: y.safe()
        )
    }
}

// MARK: - Device-Aware Safe Constraints

struct DeviceSafeConstraints {
    /// Gets safe frame constraints based on current device
    static func frameConstraints() -> (minWidth: CGFloat, maxWidth: CGFloat, minHeight: CGFloat, maxHeight: CGFloat) {
        #if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .phone {
            return (320, 430, 568, 932) // iPhone constraints
        } else {
            return (768, 1366, 1024, 1366) // iPad constraints
        }
        #else
        return (430, 1200, 932, 800) // Mac constraints
        #endif
    }
    
    /// Safe radius calculation for gradients based on screen size
    static func safeRadius(preferred: CGFloat) -> CGFloat {
        #if os(iOS)
        let screenSize = UIScreen.main.bounds
        let maxDimension = max(screenSize.width, screenSize.height)
        return min(preferred, maxDimension).safe()
        #else
        return preferred.safe()
        #endif
    }
}

// MARK: - Debug Extensions (DEBUG only)

#if DEBUG
extension View {
    /// Debug overlay that shows frame dimensions
    func debugFrame(_ label: String = "") -> some View {
        self.overlay(
            GeometryReader { geometry in
                VStack {
                    Text(label)
                        .font(.caption2)
                        .foregroundColor(.red)
                    Text("W: \(geometry.size.width, specifier: "%.1f")")
                        .font(.caption2)
                        .foregroundColor(.red)
                    Text("H: \(geometry.size.height, specifier: "%.1f")")
                        .font(.caption2)
                        .foregroundColor(.red)
                }
                .padding(4)
                .background(Color.white.opacity(0.8))
                .cornerRadius(4)
            }
            .allowsHitTesting(false)
        )
    }
}
#endif
