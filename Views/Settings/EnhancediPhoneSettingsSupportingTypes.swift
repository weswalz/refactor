//
//  EnhancediPhoneSettingsSupportingTypes.swift
//  LED MESSENGER
//
//  Supporting types for iPhone settings coordinator
//  Created: July 2025
//

import SwiftUI
import Foundation

// MARK: - Connection Result
enum ConnectionResult {
    case success(message: String)
    case failure(message: String)
    
    var isSuccess: Bool {
        switch self {
        case .success: return true
        case .failure: return false
        }
    }
    
    var message: String {
        switch self {
        case .success(let msg), .failure(let msg):
            return msg
        }
    }
}

// MARK: - Label Type Option
struct LabelTypeOption {
    let value: Int
    let title: String
    let description: String
    let icon: String
    
    static let all: [LabelTypeOption] = [
        LabelTypeOption(
            value: 0,
            title: "Table Numbers",
            description: "Automatically add table numbers",
            icon: "tablecells"
        ),
        LabelTypeOption(
            value: 1,
            title: "Custom Prefix",
            description: "Add your own custom prefix",
            icon: "textformat"
        ),
        LabelTypeOption(
            value: 2,
            title: "No Labels",
            description: "Display messages without labels",
            icon: "xmark.circle"
        )
    ]
}

// MARK: - Notification Names
extension Notification.Name {
    static let ledMessengerSettingsCompleted = Notification.Name("ledMessengerSettingsCompleted")
}

// MARK: - AppSettings Extension
extension AppSettings {
    /// Update network configuration
    func updateNetworkConfig(host: String, port: UInt16) {
        self.oscHost = host
        self.oscPort = port
    }
    
    /// Update clip configuration
    func updateClipConfig(layer: Int, startSlot: Int, clipCount: Int) {
        self.layer = layer
        self.startSlot = startSlot
        self.clipCount = clipCount
    }
    
    /// Convenience methods for individual settings
    func setDefaultLabelType(_ type: Int) {
        self.defaultLabelType = type
    }
    
    func setCustomLabelPrefix(_ prefix: String) {
        self.customLabelPrefix = prefix
    }
    
    func setForceCaps(_ enabled: Bool) {
        self.forceCaps = enabled
    }
    
    func setAutoClearAfter(_ seconds: TimeInterval) {
        self.autoClearAfter = seconds
    }
    
    func setLineBreakMode(_ mode: Int) {
        self.lineBreakMode = mode
    }
    
    func setCharsPerLine(_ chars: Double) {
        self.charsPerLine = chars
    }
}