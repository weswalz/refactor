//
//  iPhoneConnectionView.swift
//  LED MESSENGER
//
//  iPhone-optimized connection settings with 2025 SwiftUI design
//  Created: December 15, 2024
//

import SwiftUI
import Observation

struct iPhoneConnectionView: View {
    @Environment(AppSettings.self) private var appSettings
    
    // Focus state binding from parent
    var focusedField: FocusState<iPhoneSettingsCoordinator.Field?>.Binding
    
    @State private var hostIP: String = ""
    @State private var port: String = ""
    @State private var isTestingConnection = false
    @State private var connectionResult: ConnectionResult?
    
    var body: some View {
        // FIX: Wrap in ScrollView to prevent keyboard from hiding content
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                connectionSettingsSection
                testSection
                instructionsSection
            }
            .padding(20)
            .padding(.bottom, 20) // Add bottom padding for keyboard
        }
        .scrollDismissesKeyboard(.interactively) // iOS 16+ feature for better keyboard dismissal
        .background(.black)
        .contentShape(Rectangle()) // Ensure tap gesture works on entire area
        .onTapGesture {
            // Only dismiss keyboard if it's currently shown
            if focusedField.wrappedValue != nil {
                focusedField.wrappedValue = nil
            }
        }
        .onAppear {
            loadCurrentSettings()
            // Automatically focus on IP address field
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                focusedField.wrappedValue = .host
            }
        }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("LED MESSENGER")
                .font(.system(size: 19.6, weight: .black, design: .default))
                .tracking(1.75)
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(red: 0.8, green: 0.2, blue: 0.8),  // Pink
                            Color(red: 0.6, green: 0.2, blue: 0.9)   // Purple
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .padding(.bottom, 16)
            
            Text("Network Connection")
                .font(.title2.bold())
                .foregroundStyle(.white)
            
            Text("Connect to Resolume Arena via OSC")
                .font(.subheadline)
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Connection Settings
    private var connectionSettingsSection: some View {
        VStack(spacing: 16) {
            // Host IP Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Host IP Address")
                    .font(.headline)
                    .foregroundStyle(.white)
                
                TextField("192.168.1.100", text: $hostIP)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numbersAndPunctuation)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .submitLabel(.done)
                    .focused(focusedField, equals: iPhoneSettingsCoordinator.Field.host)
                    .onChange(of: hostIP) { _, newValue in
                        saveSettings()
                    }
                    .onSubmit {
                        focusedField.wrappedValue = nil
                    }
                    // FIX: Add keyboard toolbar for easy dismissal
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button("Done") {
                                focusedField.wrappedValue = nil
                            }
                            .foregroundColor(.purple)
                        }
                    }
            }
            .padding(16)
            .background(.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Port Field
            VStack(alignment: .leading, spacing: 8) {
                Text("OSC Port")
                    .font(.headline)
                    .foregroundStyle(.white)
                
                TextField("7000", text: $port)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                    .submitLabel(.done)
                    .focused(focusedField, equals: iPhoneSettingsCoordinator.Field.port)
                    .onChange(of: port) { _, newValue in
                        saveSettings()
                    }
                    .onSubmit {
                        focusedField.wrappedValue = nil
                    }
                    // FIX: Add keyboard toolbar for easy dismissal
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button("Done") {
                                focusedField.wrappedValue = nil
                            }
                            .foregroundColor(.purple)
                        }
                    }
            }
            .padding(16)
            .background(.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Test Section
    private var testSection: some View {
        VStack(spacing: 16) {
            Button {
                testConnection()
            } label: {
                HStack(spacing: 12) {
                    if isTestingConnection {
                        ProgressView()
                            .scaleEffect(0.7)
                            .tint(.white)
                    } else {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.system(size: 16))
                    }
                    
                    Text(isTestingConnection ? "Testing..." : "Test Connection")
                        .font(.headline)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(.purple)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(isTestingConnection || hostIP.isEmpty || port.isEmpty)
            
            // Test Result
            if let result = connectionResult {
                connectionResultView(result)
            }
        }
    }
    
    private func connectionResultView(_ result: ConnectionResult) -> some View {
        ConnectionResultCard(result: result)
            .transition(.opacity.combined(with: .scale))
    }
    
    // MARK: - Instructions
    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Setup Instructions")
                .font(.headline)
                .foregroundStyle(.white)
            
            VStack(alignment: .leading, spacing: 8) {
                instructionRow("1", "Open Resolume on your computer")
                instructionRow("2", "Go to OSC Input settings")
                instructionRow("3", "Enable OSC and set port to 7000")
                instructionRow("4", "Enter your computer's IP address above")
                instructionRow("5", "Test connection to verify setup")
            }
        }
        .padding(16)
        .background(.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func instructionRow(_ number: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 16, height: 16)
                .background(.purple)
                .clipShape(Circle())
            
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.gray)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    // MARK: - Methods
    private func loadCurrentSettings() {
        hostIP = appSettings.oscHost
        port = String(appSettings.oscPort)
    }
    
    private func saveSettings() {
        // Safe conversion to UInt16 with bounds checking (0-65535)
        let portValue = UInt16(clamping: Int(port) ?? 7000)
        appSettings.updateNetworkConfig(host: hostIP, port: portValue)
    }
    
    private func testConnection() {
        guard !isTestingConnection else { return }
        
        isTestingConnection = true
        connectionResult = nil
        
        Task {
            do {
                // Simulate connection test
                try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                
                await MainActor.run {
                    // Simple validation for demo
                    if hostIP.contains(".") && !port.isEmpty {
                        connectionResult = .success(
                            message: "Successfully connected to \(hostIP):\(port)"
                        )
                    } else {
                        connectionResult = .failure(
                            message: "Invalid IP address or port"
                        )
                    }
                    isTestingConnection = false
                }
            } catch {
                await MainActor.run {
                    connectionResult = .failure(
                        message: "Connection failed: \(error.localizedDescription)"
                    )
                    isTestingConnection = false
                }
            }
        }
    }
}



#Preview {
    @FocusState var focusedField: iPhoneSettingsCoordinator.Field?
    return iPhoneConnectionView(focusedField: $focusedField)
        .environment(AppSettings())
}
