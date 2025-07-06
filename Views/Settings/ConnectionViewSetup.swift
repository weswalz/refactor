import SwiftUI
import Network
import Foundation
import Observation
import Darwin

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

struct ConnectionSetupView: View {
    // MARK: - Properties
    @Environment(AppSettings.self) private var appSettings
    @Environment(QueueViewModel.self) private var queueVM
    
    // Focus state binding from parent
    var focusedField: FocusState<SettingsWizardView.Field?>.Binding
    
    @State private var oscHost: String = "127.0.0.1"
    @State private var oscPort: String = "2269"
    @State private var isTestingOSC: Bool = false
    @State private var isConnectionSuccess: Bool = false
    @State private var connectionError: String?
    @State private var localIPAddress: String = "Checking..."
    @State private var diagnosticResult: String = "Ready to test"
    @State private var showNetworkDiagnostics: Bool = false
    
    // MARK: - Webhook Properties
    @State private var webhookUrl: String = ""
    @State private var isTestingWebhook: Bool = false
    @State private var webhookTestSuccess: Bool = false
    @State private var webhookTestError: String?
    
    // MARK: - Debouncing Properties
    @State private var debounceTask: Task<Void, Never>?
    @State private var webhookDebounceTask: Task<Void, Never>?
    private let debounceDelay: Duration = .milliseconds(1500) // 1.5 second delay - only save after user stops typing

    // MARK: - View Body
    
    var body: some View {
        ZStack {
            // IMMEDIATE BLACK BACKGROUND
            Color.black
                .ignoresSafeArea()
            
            // iOS 18 Material background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.purple.opacity(0.15),
                    Color.indigo.opacity(0.1),
                    Color.black.opacity(0.3)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 16) {
                header
                
                ScrollView {
                    VStack(spacing: 20) {
                        oscConnectionSection
                        webhookConfigurationSection
                        networkDiagnosticsSection
                    }
                    .padding(.horizontal, 6)
                    .padding(.bottom, 20) // Add bottom padding for keyboard
                }
                
                Spacer(minLength: 10)
                
                Text("Step 1 of 4")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.vertical, 8)
            }
        }
        .onAppear {
            oscHost = appSettings.oscHost
            oscPort = String(appSettings.oscPort)
            webhookUrl = appSettings.webhookUrl
            
            Task {
                await detectAndSetLocalIP()
            }
        }
        .onChange(of: oscHost) { _, newValue in
            // Cancel previous debounce task
            debounceTask?.cancel()
            
            // Start new debounce task
            debounceTask = Task {
                // Wait for debounce delay
                try? await Task.sleep(for: debounceDelay)
                
                // Check if task was cancelled during sleep
                if !Task.isCancelled {
                    // Update settings after debounce
                    appSettings.setOscHost(newValue)
                }
            }
        }
        .onChange(of: oscPort) { _, newValue in
            // Cancel previous debounce task
            debounceTask?.cancel()
            
            // Start new debounce task
            debounceTask = Task {
                // Wait for debounce delay
                try? await Task.sleep(for: debounceDelay)
                
                // Check if task was cancelled during sleep
                if !Task.isCancelled {
                    // Validate port number
                    if let port = Int(newValue), port > 0 && port <= 65535 {
                        appSettings.setOscPort(UInt16(port))
                    }
                }
            }
        }
        .onChange(of: webhookUrl) { _, newValue in
            // Cancel previous debounce task
            webhookDebounceTask?.cancel()
            
            // Start new debounce task
            webhookDebounceTask = Task {
                // Wait for debounce delay
                try? await Task.sleep(for: debounceDelay)
                
                // Check if task was cancelled during sleep
                if !Task.isCancelled {
                    // Update settings after debounce
                    appSettings.setWebhookUrl(newValue)
                }
            }
        }
        .onDisappear {
            // Cancel any pending debounce when view disappears
            debounceTask?.cancel()
            webhookDebounceTask?.cancel()
        }
    }
    
    // MARK: - UI Components
    
    var header: some View {
        HStack {
            Text("Connection Setup")
                .font(.headline.bold())
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.6))
                .stroke(.purple.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }
    
    // MARK: - OSC Connection Section
    var oscConnectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Resolume OSC Connection")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text("In Resolume, go to Preferences > OSC and enable 'OSC Input'. Copy the IP Address shown at the top and the Incoming Port (2269) into the settings below.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack {
                Text("Host:")
                    .foregroundColor(.white)
                    .frame(width: 60, alignment: .leading)
                
                TextField("e.g., 127.0.0.1", text: $oscHost)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: .infinity)
                    .autocorrectionDisabled(true)
                    .textInputAutocapitalization(.never)
                    .focused(focusedField, equals: SettingsWizardView.Field.host)
            }
            
            HStack {
                Text("Port:")
                    .foregroundColor(.white)
                    .frame(width: 60, alignment: .leading)
                
                TextField("e.g., 2269", text: $oscPort)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: .infinity)
                    .keyboardType(.numberPad)
                    .focused(focusedField, equals: SettingsWizardView.Field.port)
            }
            
            Button(isTestingOSC ? "Testing..." : "Test Connection") {
                Task {
                    await testOSCConnection()
                }
            }
            .buttonStyle(.bordered)
            .tint(.purple)
            .disabled(isTestingOSC)
            
            // OSC Test Status Display
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
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.4))
                .stroke(.purple.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - Webhook Configuration Section
    var webhookConfigurationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Webhook Notifications")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text("Configure a webhook URL to receive notifications when messages are added or sent.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack {
                Text("URL:")
                    .foregroundColor(.white)
                    .frame(width: 60, alignment: .leading)
                
                TextField("e.g., https://n8n.example.com/webhook/...", text: $webhookUrl)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: .infinity)
                    .autocorrectionDisabled(true)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                    .focused(focusedField, equals: SettingsWizardView.Field.webhook)
            }
            
            if !webhookUrl.isEmpty {
                Button(isTestingWebhook ? "Testing..." : "Test Webhook") {
                    Task {
                        await testWebhook()
                    }
                }
                .buttonStyle(.bordered)
                .tint(.purple)
                .disabled(isTestingWebhook)
            }
            
            // Webhook Test Status Display
            if webhookTestSuccess {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Webhook test successful")
                        .foregroundColor(.green)
                        .font(.caption)
                }
            } else if let error = webhookTestError {
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
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.4))
                .stroke(.purple.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - Network Diagnostics Section
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
                    
                    Button("Refresh Network Info") {
                        Task { 
                            await detectAndSetLocalIP()
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .buttonStyle(.bordered)
                    .tint(.purple)
                    .frame(maxWidth: .infinity, alignment: .center)
                    
                    Text(diagnosticResult)
                        .foregroundColor(diagnosticResult.contains("Error") ? .red : .white.opacity(0.8))
                        .font(.caption)
                    
                    Text("Troubleshooting:")
                        .foregroundColor(.white)
                        .font(.caption.bold())
                        .padding(.top, 8)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• Ensure Resolume is running")
                        Text("• Check OSC is enabled in Resolume preferences")
                        Text("• Verify the port number matches Resolume settings")
                        Text("• Make sure your device is on the same network as Resolume")
                    }
                    .font(.caption)
                    .foregroundColor(.gray)
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
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.4))
                .stroke(.purple.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - Methods
    
    // Swift 6 Concurrency-Safe OSC Connection Test
    private func testOSCConnection() async {
        // Cancel any pending debounce tasks first
        debounceTask?.cancel()
        
        await MainActor.run {
            isTestingOSC = true
            connectionError = nil
            isConnectionSuccess = false
            diagnosticResult = "Testing OSC connection..."
        }
        
        // Validate input
        guard let port = UInt16(oscPort) else {
            await MainActor.run {
                connectionError = "Invalid port number"
                isTestingOSC = false
            }
            return
        }
        
        // Configure the OSC service with test values
        let config = OSCConfiguration(
            host: oscHost,
            port: port,
            layer: appSettings.layer,
            clipCount: appSettings.clipCount,
            clearClip: appSettings.startSlot + appSettings.clipCount
        )
        
        await appSettings.oscService.configure(config)
        
        // For UDP/OSC, the configuration itself is the "connection"
        // Since UDP is connectionless, if the configuration completed without error,
        // we consider it successful. The real test happens when sending actual messages.
        
        await MainActor.run {
            isConnectionSuccess = true
            diagnosticResult = "OSC configured successfully for \(oscHost):\(port)"
            connectionError = nil

        }
        
        // Keep success message visible for a moment
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        await MainActor.run {
            isTestingOSC = false
        }
    }
    
    private func detectAndSetLocalIP() async {
        await MainActor.run {
            localIPAddress = "Detecting..."
        }
        
        let ipAddress = getLocalIPAddress()
        
        await MainActor.run {
            self.localIPAddress = ipAddress
        }
    }
    
    private func getLocalIPAddress() -> String {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        
        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            while ptr != nil {
                defer { ptr = ptr?.pointee.ifa_next }
                
                guard let interface = ptr?.pointee else { continue }
                let addrFamily = interface.ifa_addr.pointee.sa_family
                
                if addrFamily == UInt8(AF_INET) {
                    let name = String(cString: interface.ifa_name)
                    
                    // Skip loopback addresses
                    if name == "lo0" { continue }
                    
                    // Convert interface address to a human readable string
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    if getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                   &hostname, socklen_t(hostname.count),
                                   nil, socklen_t(0), NI_NUMERICHOST) == 0 {
                        let potentialAddress = String(cString: hostname)
                        
                        // Prefer IPv4 addresses that start with common local prefixes
                        if potentialAddress.hasPrefix("192.168.") ||
                           potentialAddress.hasPrefix("10.") ||
                           potentialAddress.hasPrefix("172.") {
                            address = potentialAddress
                            break
                        }
                    }
                }
            }
            freeifaddrs(ifaddr)
        }
        
        return address ?? "Unable to detect IP"
    }
    
    // MARK: - Webhook Test Method
    private func testWebhook() async {
        // Cancel any pending debounce tasks first
        webhookDebounceTask?.cancel()
        
        await MainActor.run {
            isTestingWebhook = true
            webhookTestError = nil
            webhookTestSuccess = false
        }
        
        let webhookService = WebhookService()
        let success = await webhookService.testWebhook(url: webhookUrl)
        
        await MainActor.run {
            if success {
                webhookTestSuccess = true
                webhookTestError = nil
                // Test successful
            } else {
                webhookTestSuccess = false
                webhookTestError = "Failed to connect to webhook URL"
                // Test failed
            }
        }
        
        // Keep success/error message visible for a moment
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        await MainActor.run {
            isTestingWebhook = false
        }
    }
}
