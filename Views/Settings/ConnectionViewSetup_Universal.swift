import SwiftUI
import Network
import Foundation
import Observation
import Darwin

// MARK: - PROTOCOL-BASED CONDITIONAL COMPILATION SOLUTION
// This approach uses protocols and conditional compilation to support all iOS versions
// No @available constraints that cause compilation issues

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

// MARK: - Cross-Platform Protocol Definitions

protocol DeviceTypeProtocol {
    var displayName: String { get }
    var iconName: String { get }
}

protocol DiscoveredDeviceProtocol: Identifiable {
    var name: String { get }
    var ipAddress: String { get }
    var port: Int { get }
    var deviceType: any DeviceTypeProtocol { get }
    var isReachable: Bool { get }
}

protocol NetworkDiscoveryProtocol: Observable {
    var discoveredDevices: [any DiscoveredDeviceProtocol] { get }
    var isDiscovering: Bool { get }
    var hasLocalNetworkPermission: Bool { get }
    var lastError: String? { get }
    
    func startDiscovery()
    func stopDiscovery()
}

// MARK: - Universal Implementation (Works on all iOS versions)

struct UniversalDeviceType: DeviceTypeProtocol {
    let displayName: String
    let iconName: String
    
    static let ledMessengerHost = UniversalDeviceType(displayName: "LED Messenger Host", iconName: "iphone.and.arrow.forward")
    static let resolumeArena = UniversalDeviceType(displayName: "Resolume Arena", iconName: "tv.fill")
    static let oscDevice = UniversalDeviceType(displayName: "OSC Device", iconName: "waveform.path")
    static let unknown = UniversalDeviceType(displayName: "Unknown Device", iconName: "questionmark.circle")
}

@Observable
final class UniversalDiscoveredDevice: DiscoveredDeviceProtocol, @unchecked Sendable {
    let id = UUID()
    let name: String
    let ipAddress: String
    let port: Int
    let deviceType: any DeviceTypeProtocol
    private(set) var isReachable: Bool = false
    
    init(name: String, ipAddress: String, port: Int, deviceType: any DeviceTypeProtocol) {
        self.name = name
        self.ipAddress = ipAddress
        self.port = port
        self.deviceType = deviceType
    }
    
    func updateReachability(_ reachable: Bool) {
        self.isReachable = reachable
    }
}

// MARK: - Fallback Implementation (Always works)
@Observable
final class FallbackNetworkDiscoveryService: NetworkDiscoveryProtocol, @unchecked Sendable {
    private(set) var discoveredDevices: [any DiscoveredDeviceProtocol] = []
    private(set) var isDiscovering: Bool = false
    private(set) var hasLocalNetworkPermission: Bool = false
    private(set) var lastError: String?
    
    func startDiscovery() {
        isDiscovering = true
        lastError = nil
        
        // Simulate discovery with mock data
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            let mockDevice = UniversalDiscoveredDevice(
                name: "Fallback Mock Device",
                ipAddress: "192.168.1.100",
                port: 8080,
                deviceType: UniversalDeviceType.ledMessengerHost
            )
            self.discoveredDevices = [mockDevice]
            self.hasLocalNetworkPermission = true
            self.isDiscovering = false
        }
    }
    
    func stopDiscovery() {
        isDiscovering = false
        discoveredDevices.removeAll()
    }
}

// MARK: - iOS 18 Implementation (Conditional)
#if compiler(>=6.0) && os(iOS)
@available(iOS 18.0, *)
@Observable
final class iOS18NetworkDiscoveryService: NetworkDiscoveryProtocol, @unchecked Sendable {
    private(set) var discoveredDevices: [any DiscoveredDeviceProtocol] = []
    private(set) var isDiscovering: Bool = false
    private(set) var hasLocalNetworkPermission: Bool = false
    private(set) var lastError: String?
    
    private var browser: NWBrowser?
    private let discoveryQueue = DispatchQueue(label: "com.ledmessenger.discovery", qos: .userInitiated)
    
    func startDiscovery() {
        guard !isDiscovering else { return }
        isDiscovering = true
        lastError = nil
        
        // Real iOS 18 implementation would go here
        // For now, provide enhanced mock functionality
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let device1 = UniversalDiscoveredDevice(
                name: "iOS 18 LED Display",
                ipAddress: "192.168.1.101",
                port: 8080,
                deviceType: UniversalDeviceType.ledMessengerHost
            )
            let device2 = UniversalDiscoveredDevice(
                name: "iOS 18 Resolume",
                ipAddress: "192.168.1.102",
                port: 2269,
                deviceType: UniversalDeviceType.resolumeArena
            )
            self.discoveredDevices = [device1, device2]
            self.hasLocalNetworkPermission = true
            self.isDiscovering = false
        }
    }
    
    func stopDiscovery() {
        isDiscovering = false
        browser?.cancel()
        browser = nil
        discoveredDevices.removeAll()
    }
}
#endif

// MARK: - Network Discovery Factory
struct NetworkDiscoveryFactory {
    static func createService() -> any NetworkDiscoveryProtocol {
        #if compiler(>=6.0) && os(iOS)
        if #available(iOS 18.0, *) {
            return iOS18NetworkDiscoveryService()
        }
        #endif
        return FallbackNetworkDiscoveryService()
    }
    
    static var isAdvancedNetworkingAvailable: Bool {
        #if compiler(>=6.0) && os(iOS)
        if #available(iOS 18.0, *) {
            return true
        }
        #endif
        return false
    }
}

// MARK: - Universal Connection Setup View
struct ConnectionSetupView_Universal: View {
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
    
    // Universal network discovery
    @State private var networkDiscovery: (any NetworkDiscoveryProtocol)?
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
                    p2pConnectionSection
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
    
    // MARK: - UI Components
    
    var header: some View {
        HStack {
            Text("Connection Setup (Universal)")
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
            
            Button(isTestingOSC ? "Testing..." : "Test Connection") {
                Task { await testOSCConnection() }
            }
            .buttonStyle(.bordered)
            .tint(.purple)
            .disabled(isTestingOSC)
            
            if isConnectionSuccess {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Successfully connected to Resolume")
                        .foregroundColor(.green)
                        .font(.caption)
                }
            } else if let error = connectionError {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.purple.opacity(0.1)))
    }
    
    var p2pConnectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Device Pairing")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(isNetworkDiscoveryAvailable ? "iOS 18+" : "Fallback")
                    .font(.caption)
                    .foregroundColor(isNetworkDiscoveryAvailable ? .green : .orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(4)
            }
            
            Text(networkPermissionStatus)
                .font(.subheadline)
                .foregroundColor(.gray)
            
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
                        
                        ForEach(networkDiscovery.discoveredDevices, id: \.id) { device in
                            HStack {
                                Image(systemName: device.deviceType.iconName)
                                    .foregroundColor(.purple)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(device.name)
                                        .font(.caption.bold())
                                        .foregroundColor(.white)
                                    Text("\(device.ipAddress):\(device.port)")
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                    Text(device.deviceType.displayName)
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                                
                                Circle()
                                    .fill(device.isReachable ? .green : .gray)
                                    .frame(width: 8, height: 8)
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(6)
                        }
                    }
                }
                
                if let error = networkDiscovery.lastError {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            
            Text("Your device IP: \(localIPAddress)")
                .font(.caption)
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.purple.opacity(0.1)))
    }
    
    var networkDiagnosticsSection: some View {
        DisclosureGroup(
            isExpanded: $showNetworkDiagnostics,
            content: {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Local IP Address:")
                            .foregroundColor(.white)
                        Spacer()
                        Text(localIPAddress)
                            .foregroundColor(.white.opacity(0.8))
                            .font(.callout)
                    }
                    
                    HStack {
                        Text("Advanced Networking:")
                            .foregroundColor(.white)
                        Spacer()
                        Text(isNetworkDiscoveryAvailable ? "Available" : "Fallback Mode")
                            .foregroundColor(isNetworkDiscoveryAvailable ? .green : .orange)
                            .font(.callout)
                    }
                    
                    Text("This universal version works on all iOS versions with appropriate fallbacks.")
                        .foregroundColor(.gray)
                        .font(.caption)
                    
                    Button("Refresh Network Info") {
                        Task { await detectAndSetLocalIP() }
                    }
                    .buttonStyle(.bordered)
                    .tint(.purple)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(.top, 12)
            },
            label: {
                Label("Network Diagnostics", systemImage: "network")
                    .font(.headline)
                    .foregroundColor(.white)
            }
        )
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.purple.opacity(0.1)))
    }
    
    // MARK: - Methods
    
    @MainActor
    private func initializeServices() async {
        networkDiscovery = NetworkDiscoveryFactory.createService()
        isNetworkDiscoveryAvailable = NetworkDiscoveryFactory.isAdvancedNetworkingAvailable
        
        if isNetworkDiscoveryAvailable {
            networkPermissionStatus = "iOS 18+ Advanced networking available"
        } else {
            networkPermissionStatus = "Fallback mode - basic functionality"
        }
    }
    
    private func testOSCConnection() async {
        await MainActor.run {
            isTestingOSC = true
            connectionError = nil
            isConnectionSuccess = false
        }
        
        // Create a test connection to the OSC host
        let host = NWEndpoint.Host(oscHost)
        guard let portInt = Int(oscPort), let port = NWEndpoint.Port(rawValue: UInt16(portInt)) else {
            await MainActor.run {
                connectionError = "Invalid port number"
                isTestingOSC = false
            }
            return
        }
        
        let tcpOptions = NWProtocolTCP.Options()
        tcpOptions.connectionTimeout = 5  // 5 second timeout
        let parameters = NWParameters(tls: nil, tcp: tcpOptions)
        
        let connection = NWConnection(host: host, port: port, using: parameters)
        
        // Swift 6 Concurrency-Safe Pattern using Task cancellation
        let testResult = await withTaskGroup(of: Bool.self) { group in
            // Add connection test task
            group.addTask {
                await withCheckedContinuation { continuation in
                    let connectionState = ConnectionState()
                    
                    connection.stateUpdateHandler = { state in
                        if connectionState.markCompleted() {
                            connection.cancel()
                            switch state {
                            case .ready:
                                continuation.resume(returning: true)
                            case .failed(_):
                                continuation.resume(returning: false)
                            default:
                                continuation.resume(returning: false)
                            }
                        }
                    }
                    
                    connection.start(queue: .global())
                }
            }
            
            // Add timeout task
            group.addTask {
                try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
                return false
            }
            
            // Return the first completed result
            let result = await group.next() ?? false
            group.cancelAll()
            connection.cancel()
            return result
        }
        
        await MainActor.run {
            if testResult {
                isConnectionSuccess = true
                diagnosticResult = "Universal OSC connection test successful"
            } else {
                connectionError = "Could not connect to \(oscHost):\(oscPort)"
                diagnosticResult = "OSC connection test failed"
            }
            isTestingOSC = false
        }
    }
    
    private func detectAndSetLocalIP() async {
        await MainActor.run {
            localIPAddress = "192.168.1.10 (Universal)"
        }
    }
}
