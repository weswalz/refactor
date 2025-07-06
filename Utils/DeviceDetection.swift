//
//  DeviceDetection.swift
//  LED MESSENGER
//
//  Device detection utility for conditional UI rendering
//  Created: December 15, 2024
//

import SwiftUI
import UIKit

/// Utility for detecting device types and adapting UI accordingly
struct DeviceDetection {
    
    /// Returns true if the current device is an iPhone
    static var isPhone: Bool {
        #if os(iOS)
        return UIDevice.current.userInterfaceIdiom == .phone
        #else
        return false
        #endif
    }
    
    /// Returns true if the current device is an iPad
    static var isPad: Bool {
        #if os(iOS)
        return UIDevice.current.userInterfaceIdiom == .pad
        #else
        return false
        #endif
    }
    
    /// Returns true if running on Mac Catalyst
    static var isMacCatalyst: Bool {
        #if targetEnvironment(macCatalyst)
        return true
        #else
        return false
        #endif
    }
    
    /// Returns true if running on macOS
    static var isMac: Bool {
        #if os(macOS)
        return true
        #else
        return false
        #endif
    }
    
    /// Returns the appropriate settings interface based on device type
    @ViewBuilder
    static func adaptiveSettings() -> some View {
        if isPhone {
            iPhoneSettingsCoordinator()
        } else {
            SettingsWizardView()
        }
    }
}

/// View modifier for device-adaptive layouts
struct AdaptiveLayoutModifier: ViewModifier {
    func body(content: Content) -> some View {
        if DeviceDetection.isPhone {
            content
                .navigationBarTitleDisplayMode(.inline)
        } else {
            content
        }
    }
}

extension View {
    /// Apply device-adaptive layout modifications
    func adaptiveLayout() -> some View {
        modifier(AdaptiveLayoutModifier())
    }
}
