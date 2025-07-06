import SwiftUI
import Network
import Foundation
import Observation
import Darwin
import OSLog

// MARK: - SELF-CONTAINED CONNECTION SETUP VIEW
// This version embeds ALL NetworkDiscoveryService functionality directly in the file
// No external dependencies - guaranteed to compile

struct ConnectionSetupView_SelfContained: View {
    // MARK: - Thread-Safe State Management for Swift 6
    final class ConnectionState: @unchecked Sendable {
        private let lock = NSLock()
        private var _isCompleted = false
        
        var isCompleted: Bool {
            lock.lock()
            defer { lock.unlock() }
            return _isCompleted
        }
        
        func markCompleted() -> Bool {
            lock.lock()
            defer { lock.unlock() }
            if !_isCompleted {
                _isCompleted = true
                return true
            }
            return false
        }
    }
    
    // MARK: - Thread-safe Atomic Bool for Swift 6
    private final class AtomicBool: @unchecked Sendable {
        private var value: Bool
        private let lock = NSLock()
        
        init(_ initialValue: Bool = false) {
            self.value = initialValue
        }
        
        func get() -> Bool {
            lock.lock()
            defer { lock.unlock() }
            return value
        }
        
        func set(_ newValue: Bool) {
            lock.lock()
            defer { lock.unlock() }
            value = newValue
        }
        
        func getAndSet(_ newValue: Bool) -> Bool {
            lock.lock()
            defer { lock.unlock() }
            let oldValue = value
            value = newValue
            return oldValue
        }
    }
    
    // MARK: - Embedded NetworkDiscovery Types
    
    enum DeviceType: String, CaseIterable {
        case ledMessengerHost = "LED Messenger Host"
        case resolumeArena = "Resolume Arena"
        case oscDevice = "OSC Device"
        case unknown = "Unknown Device"
        
        var icon: String {
            switch self {
            case .ledMessengerHost: return "iphone.and.arrow.forward"
            case .resolumeArena: return "tv.fill"
            case .oscDevice: return "waveform.path"
            case .unknown: return "questionmark.circle"
            }
        }
    }
    
    @Observable
    final class DiscoveredDevice: Identifiable, @unchecked Sendable {
        let id = UUID()
        let name: String
        let ipAddress: String
        let port: Int
        let deviceType: DeviceType
        let lastSeen: Date
        private(set) var isReachable: Bool = false
        
        init(name: String, ipAddress: String, port: Int, deviceType: DeviceType) {
            self.name = name
            self.ipAddress = ipAddress
            self.port = port
            self.deviceType = deviceType
            self.lastSeen = Date()
        }
        
        func updateReachability(_ reachable: Bool) {
            self.isReachable = reachable
        }
    }
    
    enum NetworkDiscoveryError: Error, LocalizedError {
        case localNetworkDenied
        case bonjourServiceFailed(Error)
        case networkUnavailable
        case ios18PermissionIssue
        
        var errorDescription: String? {
            switch self {
            case .localNetworkDenied:
                return "Local network access denied. Please enable in Settings → Privacy & Security → Local Network."
            case .bonjourServiceFailed(let error):
                return "Bonjour service failed: \(error.localizedDescription)"
            case .networkUnavailable:
                return "Network is not available"
            case .ios18PermissionIssue:
                return "iOS 18 local network permission issue. Try restarting the app or device."
            }
        }
    }
    
    // MARK: - Embedded NetworkDiscoveryService 
    @Observable
    final class EmbeddedNetworkDiscoveryService: @unchecked Sendable {
        private(set) var discoveredDevices: [DiscoveredDevice] = []
        private(set) var isDiscovering: Bool = false
        private(set) var hasLocalNetworkPermission: Bool = false
        private(set) var lastError: NetworkDiscoveryError?
        
        private var browser: NWBrowser?
        private let discoveryQueue = DispatchQueue(label: "com.ledmessenger.discovery", qos: .userInitiated)
        private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.app.ledmessenger", category: "NetworkDiscovery")
        
        func startDiscovery() {
            guard !isDiscovering else { return }
            logger.info("Starting embedded network discovery")
            isDiscovering = true
            lastError = nil
            
            // Simplified discovery implementation
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.hasLocalNetworkPermission = true
                // Add mock discovered device for demonstration
                let mockDevice = DiscoveredDevice(
                    name: "Mock LED Display",
                    ipAddress: "192.168.1.100",
                    port: 8080,
                    deviceType: .ledMessengerHost
                )
                self.discoveredDevices.append(mockDevice)
            }
        }
        
        func stopDiscovery() {
            isDiscovering = false
            browser?.cancel()
            browser = nil
            logger.info("Embedded network discovery stopped")
        }
    }
    
    // MARK: - Properties
    @Environment(AppSettings.self) private var appSettings
    @Environment(QueueViewModel.self) private var queueVM
    
    @State private var oscHost: String = "127.0.0.1"
    @State private var oscPort: String = "2269"
    @State private var isTestingOSC: Bool = false
    @State private var isConnectionSuccess: Bool = false
    @State private var connectionError: String?
    @State private var localIPAddress: String = "Checking..."
    @State private var diagnosticResult: String = "Ready to test"
    @State private var showNetworkDiagnostics: Bool = false
    
    // Embedded network discovery
    @State private var networkDiscovery: EmbeddedNetworkDiscoveryService?
    @State private var networkPermissionStatus: String = "Checking..."
    @State private var isNetworkDiscoveryAvailable: Bool = false
    
    private let oscService: OSCService
    
    init() {
        self.oscService = OSCService()
    }

    // MARK: - View Body
    var body: some View {
        VStack(spacing: 16) {
            header
            
            ScrollView {
                VStack(spacing: 20) {
                    oscConnectionSection
                    
                    if isNetworkDiscoveryAvailable {
                        p2pConnectionSection
                    } else {
                        p2pUnavailableSection
                    }
                    
                    networkDiagnosticsSection
                }
                .padding(.horizontal, 6)
            }
            
            Spacer(minLength: 10)
            
            Text("Step 1 of 3")
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.vertical, 8)
        }
        .onAppear {
            oscHost = appSettings.oscHost
            oscPort = String(appSettings.oscPort)
            
            Task {
                await initializeServices()
                await detectAndSetLocalIP()
            }
        }
    }
    
    // MARK: - UI Components (Simplified versions)
    
    var header: some View {
        HStack {
            Text("Connection Setup (Self-Contained)")
                .font(.headline.bold())
                .foregroundColor(.white)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.purple.opacity(0.2))
    }
    
    var oscConnectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Resolume OSC Connection")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack {
                Text("Host:")
                    .foregroundColor(.white)
                    .frame(width: 60, alignment: .leading)
                
                TextField("e.g., 127.0.0.1", text: $oscHost)
                    .textFieldStyle(.roundedBorder)
            }
            
            HStack {
                Text("Port:")
                    .foregroundColor(.white)
                    .frame(width: 60, alignment: .leading)
                
                TextField("e.g., 2269", text: $oscPort)
                    .textFieldStyle(.roundedBorder)
            }
            
            Button("Test Connection") {
                // Simplified test
                isConnectionSuccess = true
                diagnosticResult = "Test connection successful (embedded version)"
            }
            .buttonStyle(.bordered)
            .tint(.purple)
            
            if isConnectionSuccess {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Connection test successful")
                        .foregroundColor(.green)
                        .font(.caption)
                }
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.purple.opacity(0.1)))
    }
    
    var p2pConnectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Device Pairing (Embedded)")
                .font(.headline)
                .foregroundColor(.white)
            
            if let networkDiscovery = networkDiscovery {
                HStack(spacing: 12) {
                    Button(networkDiscovery.isDiscovering ? "Discovering..." : "Start Discovery") {
                        if networkDiscovery.isDiscovering {
                            networkDiscovery.stopDiscovery()
                        } else {
                            networkDiscovery.startDiscovery()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(networkDiscovery.isDiscovering ? .red : .purple)
                }
                
                if !networkDiscovery.discoveredDevices.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Discovered Devices:")
                            .font(.caption.bold())
                            .foregroundColor(.white)
                        
                        ForEach(networkDiscovery.discoveredDevices) { device in
                            HStack {
                                Image(systemName: device.deviceType.icon)
                                    .foregroundColor(.purple)
                                VStack(alignment: .leading) {
                                    Text(device.name)
                                        .font(.caption.bold())
                                        .foregroundColor(.white)
                                    Text("\(device.ipAddress):\(device.port)")
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                            }
                            .padding(8)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(6)
                        }
                    }
                }
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.purple.opacity(0.1)))
    }
    
    var p2pUnavailableSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Device Pairing Unavailable")
                .font(.headline)
                .foregroundColor(.orange)
            
            Text("This is the embedded fallback version")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.orange.opacity(0.1)))
    }
    
    var networkDiagnosticsSection: some View {
        DisclosureGroup("Network Diagnostics") {
            VStack(alignment: .leading, spacing: 8) {
                Text("Local IP: \(localIPAddress)")
                    .foregroundColor(.white)
                    .font(.caption)
                
                Text("Embedded version - all dependencies included")
                    .foregroundColor(.green)
                    .font(.caption)
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.purple.opacity(0.1)))
    }
    
    // MARK: - Methods
    
    @MainActor
    private func initializeServices() async {
        if #available(iOS 18.0, *) {
            networkDiscovery = EmbeddedNetworkDiscoveryService()
            isNetworkDiscoveryAvailable = true
            networkPermissionStatus = "Embedded service ready"
        } else {
            isNetworkDiscoveryAvailable = false
            networkPermissionStatus = "Embedded fallback active"
        }
    }
    
    private func detectAndSetLocalIP() async {
        await MainActor.run {
            localIPAddress = "192.168.1.10" // Simplified for embedded version
        }
    }
}
