//
//  DeviceEnvironment.swift
//  LED MESSENGER
//
//  Created on June 17, 2025
//  Device detection and adaptive configuration for iOS 18
//

import Foundation
import SwiftUI
import Observation
import Network

// MARK: - Device Type

/// Represents the type of device the app is running on
public enum DeviceType: String, CaseIterable, Codable, Sendable {
    case iPhone = "iPhone"
    case iPad = "iPad"
    case macCatalyst = "macCatalyst"
    case mac = "mac"
    
    /// Human-readable description for UI display
    var displayName: String {
        switch self {
        case .iPhone: return "iPhone"
        case .iPad: return "iPad"
        case .macCatalyst: return "Mac (Catalyst)"
        case .mac: return "Mac"
        }
    }
    
    /// Device-specific icon for UI
    var systemImage: String {
        switch self {
        case .iPhone: return "iphone"
        case .iPad: return "ipad"
        case .macCatalyst: return "laptopcomputer"
        case .mac: return "desktopcomputer"
        }
    }
}

// MARK: - Connection Type

/// Preferred network connection type for device
public enum ConnectionType: String, CaseIterable, Codable, Sendable {
    case adaptive = "adaptive"     // Automatically choose best connection
    case wifi = "wifi"            // Prefer WiFi
    case ethernet = "ethernet"    // Prefer wired connection
    case cellular = "cellular"    // Mobile data (fallback)
    
    var displayName: String {
        switch self {
        case .adaptive: return "Adaptive"
        case .wifi: return "Wi-Fi"
        case .ethernet: return "Ethernet"
        case .cellular: return "Cellular"
        }
    }
}

// MARK: - Networking Settings

/// Device-specific networking configuration
public struct NetworkingSettings: Codable, Sendable {
    public var preferredConnectionType: ConnectionType
    public var oscKeepAliveInterval: TimeInterval
    public var oscTimeout: TimeInterval
    public var p2pDiscoveryTimeout: TimeInterval
    public var backgroundNetworkingAllowed: Bool
    public var maxConnectionAttempts: Int
    public var connectionRetryDelay: TimeInterval
    
    /// Default settings based on device type
    static func defaults(for deviceType: DeviceType) -> NetworkingSettings {
        switch deviceType {
        case .iPhone:
            return NetworkingSettings(
                preferredConnectionType: .adaptive,
                oscKeepAliveInterval: 30,      // More frequent keep-alive for mobile
                oscTimeout: 5,                  // Shorter timeout for mobile networks
                p2pDiscoveryTimeout: 10,        // Quick discovery for mobile
                backgroundNetworkingAllowed: false,
                maxConnectionAttempts: 5,       // Fewer retries on mobile
                connectionRetryDelay: 3.0       // Quick retry for mobile
            )
        case .iPad:
            return NetworkingSettings(
                preferredConnectionType: .wifi,
                oscKeepAliveInterval: 60,      // Standard keep-alive
                oscTimeout: 10,                 // Standard timeout
                p2pDiscoveryTimeout: 15,        // Standard discovery
                backgroundNetworkingAllowed: true,
                maxConnectionAttempts: 10,      // Standard retries
                connectionRetryDelay: 5.0       // Standard retry delay
            )
        case .macCatalyst, .mac:
            return NetworkingSettings(
                preferredConnectionType: .ethernet,
                oscKeepAliveInterval: 120,     // Less frequent for stable connections
                oscTimeout: 30,                 // Longer timeout for stable networks
                p2pDiscoveryTimeout: 30,        // Extended discovery time
                backgroundNetworkingAllowed: true,
                maxConnectionAttempts: 20,      // More retries for desktop
                connectionRetryDelay: 10.0      // Longer retry delay
            )
        }
    }
}

// MARK: - Device Environment

/// Manages device detection and adaptive configuration for LED MESSENGER
@Observable
public final class DeviceEnvironment: @unchecked Sendable {
    
    // MARK: - Published Properties
    
    /// Current device type
    public private(set) var deviceType: DeviceType
    
    /// Current networking settings
    public private(set) var networkingSettings: NetworkingSettings
    
    /// Device-specific UI adaptations
    public private(set) var compactLayout: Bool = false
    public private(set) var supportsSplitView: Bool = false
    public private(set) var supportsMultipleWindows: Bool = false
    
    /// Network connectivity status
    public private(set) var isConnectedToNetwork: Bool = false
    public private(set) var connectionTypeActive: ConnectionType = .adaptive
    
    /// Device capabilities summary
    public var capabilities: String {
        var caps = [String]()
        
        if compactLayout {
            caps.append("Compact")
        } else {
            caps.append("Regular")
        }
        
        if supportsSplitView {
            caps.append("SplitView")
        }
        
        if supportsMultipleWindows {
            caps.append("MultiWindow")
        }
        
        if networkingSettings.backgroundNetworkingAllowed {
            caps.append("Background")
        }
        
        return caps.joined(separator: ", ")
    }
    
    /// Network configuration summary for debug display
    public var networkConfig: String {
        let settings = networkingSettings
        return "\(settings.preferredConnectionType.displayName), Timeout: \(Int(settings.oscTimeout))s, Background: \(settings.backgroundNetworkingAllowed ? "Yes" : "No")"
    }
    
    // MARK: - Private Properties
    
    private let pathMonitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "com.ledmessenger.networkmonitor")
    
    // MARK: - Initialization
    
    nonisolated public init() {
        // Calculate device type first (before accessing self)
        let detectedDeviceType = Self.detectDeviceType()
        
        // Initialize all stored properties before calling methods
        self.deviceType = detectedDeviceType
        self.networkingSettings = NetworkingSettings.defaults(for: detectedDeviceType)
        self.compactLayout = false
        self.supportsSplitView = false
        self.supportsMultipleWindows = false
        self.isConnectedToNetwork = false
        self.connectionTypeActive = .adaptive
        
        print("🔧 DeviceEnvironment initialized")
        print("📱 Device Type: \(detectedDeviceType.displayName)")
        print("🌐 Network Settings: \(self.networkingSettings.preferredConnectionType.displayName)")
        
        // Now it's safe to call methods that access self
        self.configureUIAdaptations()
        self.startNetworkMonitoring()
    }
    
    deinit {
        pathMonitor.cancel()
    }
    
    // MARK: - Device Detection
    
    /// Detects the current device type
    private static func detectDeviceType() -> DeviceType {
        #if targetEnvironment(macCatalyst)
        return .macCatalyst
        #elseif os(macOS)
        return .mac
        #else
        // iOS device detection
        switch UIDevice.current.userInterfaceIdiom {
        case .phone:
            return .iPhone
        case .pad:
            return .iPad
        default:
            // Check if running on Mac ("Designed for iPad")
            if ProcessInfo.processInfo.isiOSAppOnMac {
                return .macCatalyst  // Changed from .mac to .macCatalyst for consistency
            }
            return .iPad // Default fallback
        }
        #endif
    }
    
    // MARK: - UI Adaptations
    
    /// Configure device-specific UI features
    private func configureUIAdaptations() {
        switch deviceType {
        case .iPhone:
            compactLayout = true
            supportsSplitView = false
            supportsMultipleWindows = false
            
        case .iPad:
            compactLayout = false
            supportsSplitView = true
            supportsMultipleWindows = true
            
        case .macCatalyst, .mac:
            compactLayout = false
            supportsSplitView = true
            supportsMultipleWindows = true
        }
    }
    
    // MARK: - Network Monitoring
    
    /// Start monitoring network connectivity
    private func startNetworkMonitoring() {
        pathMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                guard let self = self else { return }
                
                await MainActor.run {
                    self.isConnectedToNetwork = (path.status == .satisfied)
                
                // Determine active connection type
                if path.usesInterfaceType(.wiredEthernet) {
                    self.connectionTypeActive = .ethernet
                } else if path.usesInterfaceType(.wifi) {
                        self.connectionTypeActive = .wifi
                    } else if path.usesInterfaceType(.cellular) {
                        self.connectionTypeActive = .cellular
                    } else {
                        self.connectionTypeActive = .adaptive
                    }
                    
                    print("🌐 Network status: \(self.isConnectedToNetwork ? "Connected" : "Disconnected") via \(self.connectionTypeActive.displayName)")
                }
            }
        }
        
        pathMonitor.start(queue: monitorQueue)
    }
    
    // MARK: - Public Methods
    
    /// Get current networking settings
    public func getNetworkingSettings() -> NetworkingSettings {
        return networkingSettings
    }
    
    /// Update networking settings
    @MainActor
    public func updateNetworkingSettings(_ settings: NetworkingSettings) {
        self.networkingSettings = settings
        print("🔧 Updated networking settings for \(deviceType.displayName)")
    }
    
    /// Get recommended OSC host based on device and network
    public func recommendedOSCHost() -> String {
        switch (deviceType, connectionTypeActive) {
        case (.iPhone, _):
            return "192.168.1.250"  // Typical LAN IP for mobile
        case (.iPad, .ethernet), (.iPad, .wifi):
            return "192.168.1.100"  // Stable WiFi/Ethernet for iPad
        case (.macCatalyst, _), (.mac, _):
            return "127.0.0.1"      // Localhost for desktop testing
        default:
            return "192.168.1.100"  // Default LAN IP
        }
    }
    
    /// Get recommended timeout values based on current connection
    public func recommendedTimeouts() -> (connection: TimeInterval, discovery: TimeInterval) {
        switch connectionTypeActive {
        case .ethernet:
            return (30, 30)  // Stable connection, longer timeouts
        case .wifi:
            return (10, 15)  // Standard timeouts
        case .cellular:
            return (5, 10)   // Quick timeouts for mobile data
        case .adaptive:
            return (networkingSettings.oscTimeout, networkingSettings.p2pDiscoveryTimeout)
        }
    }
}

// MARK: - Environment Key (FIXED)

private struct DeviceEnvironmentKey: EnvironmentKey {
    static let defaultValue = DeviceEnvironment() // Never nil
}

extension EnvironmentValues {
    public var deviceEnvironment: DeviceEnvironment {
        get { self[DeviceEnvironmentKey.self] }
        set { self[DeviceEnvironmentKey.self] = newValue }
    }
}

// MARK: - View Extensions

extension View {
    /// Apply device-specific adaptations to a view
    public func adaptForDevice() -> some View {
        self.modifier(DeviceAdaptiveModifier())
    }
}

/// ViewModifier that applies device-specific adaptations
struct DeviceAdaptiveModifier: ViewModifier {
    @Environment(\.deviceEnvironment) private var deviceEnvironment
    
    func body(content: Content) -> some View {
        content
            .navigationBarTitleDisplayMode(deviceEnvironment.compactLayout ? .inline : .large)
            .frame(
                maxWidth: (deviceEnvironment.deviceType == .iPhone) ? .infinity : 1200,
                maxHeight: .infinity
            )
    }
}
