//
//  PairingService.swift
//  LED MESSENGER
//
//  Created for automatic device pairing on same WiFi network
//  macOS = Host, iPad = Client
//

import Foundation
import Network
import Observation

@Observable
public final class PairingService {
    // MARK: - Published Properties
    var isAdvertising = false
    var isDiscovering = false
    var discoveredDevices: [PairedDevice] = []
    var currentConnection: PairedDevice?
    var connectionState: ConnectionState = .disconnected
    
    // MARK: - Private Properties
    private var listener: NWListener?
    private var browser: NWBrowser?
    private var connection: NWConnection?
    private let serviceType = "_ledmessenger._tcp"
    private let serviceName = "LED-Messenger"
    
    // MARK: - Types
    public enum ConnectionState: Equatable {
        case disconnected
        case connecting
        case connected
        case failed(Error)
        
        public static func == (lhs: ConnectionState, rhs: ConnectionState) -> Bool {
            switch (lhs, rhs) {
            case (.disconnected, .disconnected), (.connecting, .connecting), (.connected, .connected):
                return true
            case (.failed, .failed):
                return true  // Consider all failed states equal for simplicity
            default:
                return false
            }
        }
    }
    
    public struct PairedDevice: Identifiable, Hashable {
        public let id = UUID()
        public let name: String
        public let endpoint: NWEndpoint
        public let isHost: Bool
        
        public init(name: String, endpoint: NWEndpoint, isHost: Bool) {
            self.name = name
            self.endpoint = endpoint
            self.isHost = isHost
        }
    }
    
    // MARK: - Initialization
    
    public init() {}
    
    // MARK: - Host Methods (macOS)
    
    public func startHostAdvertising() async throws {
        guard !isAdvertising else { return }
        
        let parameters = NWParameters.tcp
        parameters.includePeerToPeer = true
        
        let listener = try NWListener(using: parameters, on: 12345)
        self.listener = listener
        
        let txtRecord = NWTXTRecord(["role": "host", "version": "1.0"])
        listener.service = NWListener.Service(
            name: serviceName,
            type: serviceType,
            txtRecord: txtRecord
        )
        
        listener.newConnectionHandler = { [weak self] connection in
            Task { @MainActor in
                await self?.handleNewConnection(connection)
            }
        }
        
        listener.stateUpdateHandler = { [weak self] state in
            Task { @MainActor in
                switch state {
                case .ready:
                    self?.isAdvertising = true
                    print("Host advertising started")
                case .failed(let error):
                    self?.isAdvertising = false
                    self?.connectionState = .failed(error)
                    print("Host advertising failed: \(error)")
                default:
                    break
                }
            }
        }
        
        listener.start(queue: .main)
    }
    
    public func stopHostAdvertising() {
        listener?.cancel()
        listener = nil
        isAdvertising = false
    }
    
    // MARK: - Client Methods (iPad)
    
    public func startClientDiscovery() async throws {
        guard !isDiscovering else { return }
        
        let parameters = NWParameters()
        parameters.includePeerToPeer = true
        
        let browser = NWBrowser(for: .bonjourWithTXTRecord(type: serviceType, domain: nil), using: parameters)
        self.browser = browser
        
        browser.browseResultsChangedHandler = { [weak self] results, changes in
            Task { @MainActor in
                await self?.handleBrowseResults(results, changes: changes)
            }
        }
        
        browser.stateUpdateHandler = { [weak self] state in
            Task { @MainActor in
                switch state {
                case .ready:
                    self?.isDiscovering = true
                    print("Client discovery started")
                case .failed(let error):
                    self?.isDiscovering = false
                    self?.connectionState = .failed(error)
                    print("Client discovery failed: \(error)")
                default:
                    break
                }
            }
        }
        
        browser.start(queue: .main)
    }
    
    public func stopClientDiscovery() {
        browser?.cancel()
        browser = nil
        isDiscovering = false
        discoveredDevices.removeAll()
    }
    
    public func connectToHost(_ device: PairedDevice) async throws {
        guard connectionState != .connecting else { return }
        
        connectionState = .connecting
        
        let parameters = NWParameters.tcp
        parameters.includePeerToPeer = true
        
        let connection = NWConnection(to: device.endpoint, using: parameters)
        self.connection = connection
        
        connection.stateUpdateHandler = { [weak self] state in
            Task { @MainActor in
                switch state {
                case .ready:
                    self?.connectionState = .connected
                    self?.currentConnection = device
                    print("Connected to host: \(device.name)")
                case .failed(let error):
                    self?.connectionState = .failed(error)
                    self?.currentConnection = nil
                    print("Connection failed: \(error)")
                case .cancelled:
                    self?.connectionState = .disconnected
                    self?.currentConnection = nil
                    print("Connection cancelled")
                default:
                    break
                }
            }
        }
        
        connection.start(queue: .main)
    }
    
    // MARK: - Shared Methods
    
    public func disconnect() {
        connection?.cancel()
        connection = nil
        currentConnection = nil
        connectionState = .disconnected
        
        stopHostAdvertising()
        stopClientDiscovery()
    }
    
    public func sendMessage(_ message: Data) async throws {
        guard let connection = connection,
              connectionState == .connected else {
            throw PairingError.notConnected
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            connection.send(content: message, completion: .contentProcessed { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            })
        }
    }
    
    // MARK: - Private Methods
    
    private func handleNewConnection(_ connection: NWConnection) async {
        self.connection = connection
        connectionState = .connected
        
        // Start receiving messages
        receiveMessages(on: connection)
        
        connection.stateUpdateHandler = { [weak self] state in
            Task { @MainActor in
                switch state {
                case .cancelled:
                    self?.connectionState = .disconnected
                    self?.currentConnection = nil
                default:
                    break
                }
            }
        }
        
        connection.start(queue: .main)
    }
    
    private func handleBrowseResults(_ results: Set<NWBrowser.Result>, changes: Set<NWBrowser.Result.Change>) async {
        for change in changes {
            switch change {
            case .added(let result):
                if case .service(let name, _, _, _) = result.endpoint {
                    // For now, assume all discovered devices are hosts
                    // TODO: Parse TXT record properly when needed
                    let device = PairedDevice(
                        name: name,
                        endpoint: result.endpoint,
                        isHost: true
                    )
                    if !discoveredDevices.contains(device) {
                        discoveredDevices.append(device)
                    }
                }
            case .removed(let result):
                discoveredDevices.removeAll { device in
                    device.endpoint == result.endpoint
                }
            default:
                break
            }
        }
    }
    
    private func receiveMessages(on connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            if let data = data, !data.isEmpty {
                Task { @MainActor in
                    await self?.handleReceivedMessage(data)
                }
            }
            
            if let error = error {
                print("Receive error: \(error)")
                return
            }
            
            if !isComplete {
                self?.receiveMessages(on: connection)
            }
        }
    }
    
    private func handleReceivedMessage(_ data: Data) async {
        // Delegate message handling to SyncManager
        NotificationCenter.default.post(
            name: .pairingServiceReceivedMessage,
            object: nil,
            userInfo: ["data": data]
        )
    }
}

// MARK: - Error Types

enum PairingError: LocalizedError {
    case notConnected
    case invalidMessage
    case encodingFailed
    case decodingFailed
    
    var errorDescription: String? {
        switch self {
        case .notConnected:
            return "Device not connected"
        case .invalidMessage:
            return "Invalid message format"
        case .encodingFailed:
            return "Failed to encode message"
        case .decodingFailed:
            return "Failed to decode message"
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let pairingServiceReceivedMessage = Notification.Name("PairingServiceReceivedMessage")
}