import SwiftUI
import Network
import Observation

@Observable
class NetworkDiagnosticModel {
    var diagnosticLog = "Starting diagnostics...\n"
    var isRunning = false
    
    @MainActor
    func log(_ message: String) {
        let timestamp = Date().formatted(.dateTime.hour().minute().second())
        diagnosticLog += "\(timestamp): \(message)\n"
    }
    
    @MainActor
    func clearLog() {
        diagnosticLog = ""
    }
    
    @MainActor
    func setRunning(_ running: Bool) {
        isRunning = running
    }
}

struct NetworkDiagnosticView: View {
    @State private var model = NetworkDiagnosticModel()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Network Diagnostics")
                .font(.largeTitle)
                .padding()
            
            ScrollView {
                Text(model.diagnosticLog)
                    .font(.system(.caption, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .frame(maxHeight: 400)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            
            HStack(spacing: 20) {
                Button("Run Diagnostics") {
                    Task {
                        await runDiagnostics()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(model.isRunning)
                
                Button("Test Local Network") {
                    Task {
                        await testLocalNetwork()
                    }
                }
                .buttonStyle(.bordered)
                .disabled(model.isRunning)
                
                Button("Clear") {
                    model.clearLog()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .task {
            await runDiagnostics()
        }
    }
    
    // 2025 SwiftUI: Use async/await patterns
    private func runDiagnostics() async {
        await model.setRunning(true)
        await model.clearLog()
        await model.log("=== NETWORK DIAGNOSTICS ===")
        
        // Check network interfaces
        await model.log("Checking network interfaces...")
        
        let monitor = NWPathMonitor()
        let queue = DispatchQueue(label: "NetworkDiagnostic")
        
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            monitor.pathUpdateHandler = { path in
                Task {
                    await self.model.log("Network Status: \(path.status)")
                    await self.model.log("Available Interfaces:")
                    
                    for interface in path.availableInterfaces {
                        await self.model.log("  - \(interface.name): \(interface.type)")
                    }
                    
                    await self.model.log("WiFi: \(path.usesInterfaceType(.wifi) ? "YES" : "NO")")
                    await self.model.log("Cellular: \(path.usesInterfaceType(.cellular) ? "YES" : "NO")")
                    await self.model.log("Wired: \(path.usesInterfaceType(.wiredEthernet) ? "YES" : "NO")")
                    await self.model.log("Expensive: \(path.isExpensive ? "YES" : "NO")")
                    await self.model.log("Constrained: \(path.isConstrained ? "YES" : "NO")")
                    
                    if path.status == .satisfied {
                        await self.model.log("\n✅ Network is available")
                    } else {
                        await self.model.log("\n❌ Network is NOT available")
                    }
                    
                    monitor.cancel()
                    continuation.resume()
                }
            }
            
            monitor.start(queue: queue)
        }
        
        // Test local network permission
        await testLocalNetworkPermission()
    }
    
    private func testLocalNetworkPermission() async {
        await model.log("\nTesting local network permission...")
        
        // Create a UDP connection to a local address
        // This will trigger the permission dialog if not already granted
        let params = NWParameters.udp
        params.prohibitedInterfaceTypes = [.cellular]
        params.requiredInterfaceType = .wifi
        
        let connection = NWConnection(
            host: "224.0.0.1", // Multicast address - guaranteed local
            port: 12345,
            using: params
        )
        
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            connection.stateUpdateHandler = { state in
                Task {
                    switch state {
                    case .ready:
                        await self.model.log("✅ Local network permission GRANTED")
                        await self.model.log("Connection established to multicast address")
                        connection.cancel()
                    case .failed(let error):
                        await self.model.log("❌ Local network permission DENIED or error")
                        await self.model.log("Error: \(error)")
                        connection.cancel()
                    case .waiting(let error):
                        await self.model.log("⏳ Waiting... \(error)")
                        // This often means permission dialog is showing
                    default:
                        await self.model.log("Connection state: \(state)")
                    }
                    
                    if case .cancelled = state {
                        continuation.resume()
                    }
                }
            }
            
            connection.start(queue: .global())
        }
        
        // Also test with your actual OSC address
        try? await Task.sleep(for: .seconds(2))
        await testActualOSCAddress()
        await model.setRunning(false)
    }
    
    private func testActualOSCAddress() async {
        await model.log("\nTesting actual OSC address (172.17.20.110:2269)...")
        
        let params = NWParameters.udp
        params.prohibitedInterfaceTypes = [.cellular]
        
        let connection = NWConnection(
            host: "172.17.20.110",
            port: 2269,
            using: params
        )
        
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            connection.stateUpdateHandler = { state in
                Task {
                    switch state {
                    case .ready:
                        await self.model.log("✅ Can connect to OSC address!")
                        
                        // Try sending a test packet
                        var packet = Data()
                        packet.append("/test".data(using: .utf8)!)
                        packet.append(0) // null terminator
                        while packet.count % 4 != 0 { packet.append(0) } // OSC padding
                        packet.append(",s".data(using: .utf8)!)
                        packet.append(0)
                        while packet.count % 4 != 0 { packet.append(0) }
                        packet.append("hello".data(using: .utf8)!)
                        packet.append(0)
                        while packet.count % 4 != 0 { packet.append(0) }
                        
                        connection.send(content: packet, completion: .contentProcessed { (error: NWError?) in
                            Task {
                                if let error = error {
                                    await self.model.log("❌ Send error: \(error)")
                                } else {
                                    await self.model.log("✅ Test packet sent successfully!")
                                }
                                connection.cancel()
                            }
                        })
                        
                    case .failed(let error):
                        await self.model.log("❌ Cannot connect to OSC address")
                        await self.model.log("Error: \(error)")
                        connection.cancel()
                    case .cancelled:
                        continuation.resume()
                    default:
                        break
                    }
                }
            }
            
            connection.start(queue: .global())
        }
    }
    
    private func testLocalNetwork() async {
        await model.log("\n=== FORCING LOCAL NETWORK PERMISSION ===")
        
        // Multiple attempts to trigger permission
        let addresses = [
            ("224.0.0.1", 9999),    // Multicast
            ("192.168.1.255", 9999), // Broadcast
            ("172.17.20.110", 2269), // Your OSC
            ("10.0.0.1", 9999)       // Common local
        ]
        
        for (host, port) in addresses {
            await model.log("Attempting connection to \(host):\(port)")
            
            let connection = NWConnection(
                host: NWEndpoint.Host(host),
                port: NWEndpoint.Port(integerLiteral: UInt16(port)),
                using: .udp
            )
            
            connection.start(queue: .global())
            
            // Send a dummy packet
            connection.send(content: Data([0x00]), completion: .contentProcessed { _ in
                connection.cancel()
            })
        }
        
        await model.log("If permission dialog didn't appear, check Settings > Privacy > Local Network")
    }
}

// Add this to your app temporarily to diagnose
struct DiagnosticWrapper: View {
    var body: some View {
        NetworkDiagnosticView()
    }
}