//
//  ClipRotationTestView.swift
//  LED MESSENGER
//
//  Temporary debug view for testing clip rotation fix
//  Created: June 1, 2025
//

import SwiftUI

struct ClipRotationTestView: View {
    @Environment(QueueViewModel.self) var queueVM
    @Environment(AppSettings.self) var appSettings
    
    @State private var testMessages = [
        "TEST 1",
        "TEST 2", 
        "TEST 3",
        "TEST 4",
        "TEST 5",
        "TEST 6",
        "TEST 7"
    ]
    
    @State private var sentClips: [Int] = []
    @State private var testScenario = 0
    
    let testScenarios = [
        (name: "Default", layer: 3, start: 1, count: 3),
        (name: "Bug Repro", layer: 5, start: 4, count: 5),
        (name: "High Start", layer: 1, start: 8, count: 3),
        (name: "Single Clip", layer: 2, start: 5, count: 1)
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("🧪 Clip Rotation Test")
                .font(.largeTitle)
                .bold()
            
            // Current Settings Display
            GroupBox("Current Settings") {
                HStack(spacing: 30) {
                    VStack(alignment: .leading) {
                        Text("Layer: \(appSettings.layer)")
                        Text("Start Slot: \(appSettings.startSlot)")
                        Text("Clip Count: \(appSettings.clipCount)")
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Current Clip: \(queueVM.currentSlot)")
                        Text("Range: \(appSettings.startSlot)-\(appSettings.startSlot + appSettings.clipCount - 1)")
                        Text("Sending: \(queueVM.isSending ? "YES" : "NO")")
                            .foregroundColor(queueVM.isSending ? .red : .green)
                    }
                }
                .font(.system(.body, design: .monospaced))
            }
            
            // Test Scenario Picker
            GroupBox("Test Scenarios") {
                Picker("Scenario", selection: $testScenario) {
                    ForEach(0..<testScenarios.count, id: \.self) { index in
                        Text(testScenarios[index].name)
                            .tag(index)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: testScenario) { _, newValue in
                    applyTestScenario(newValue)
                }
                
                Button("Apply Scenario") {
                    applyTestScenario(testScenario)
                }
                .buttonStyle(.borderedProminent)
            }
            
            // Send Test Messages
            GroupBox("Send Test Messages") {
                HStack {
                    Button("Send Next") {
                        sendNextTestMessage()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(queueVM.isSending)
                    
                    Button("Send All 7") {
                        sendAllTestMessages()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Clear History") {
                        sentClips.removeAll()
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                }
            }
            
            // Sent Clips History
            GroupBox("Sent Clips History") {
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(Array(sentClips.enumerated()), id: \.offset) { index, clip in
                            VStack {
                                Text("Msg \(index + 1)")
                                    .font(.caption)
                                Text("\(clip)")
                                    .font(.title2)
                                    .bold()
                            }
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(isClipInRange(clip) ? Color.green.opacity(0.3) : Color.red.opacity(0.3))
                            )
                        }
                    }
                }
                .frame(height: 80)
                
                // Expected vs Actual
                if !sentClips.isEmpty {
                    let expected = expectedClipSequence()
                    let actual = sentClips
                    let matches = expected.prefix(actual.count) == actual.prefix(expected.count)
                    
                    VStack(alignment: .leading) {
                        Text("Expected: \(expected.map(String.init).joined(separator: "→"))")
                        Text("Actual: \(actual.map(String.init).joined(separator: "→"))")
                        Text(matches ? "✅ PASS" : "❌ FAIL")
                            .font(.title3)
                            .bold()
                            .foregroundColor(matches ? .green : .red)
                    }
                    .font(.system(.body, design: .monospaced))
                }
            }
            
            Spacer()
        }
        .padding()
        .onAppear {
            // Record initial clip
            recordCurrentClip()
        }
    }
    
    private func applyTestScenario(_ index: Int) {
        let scenario = testScenarios[index]
        appSettings.updateClipConfig(
            layer: scenario.layer,
            startSlot: scenario.start,
            clipCount: scenario.count
        )
        
        // Clear history when changing scenarios
        sentClips.removeAll()
        
        // Give settings time to update
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            recordCurrentClip()
        }
    }
    
    private func sendNextTestMessage() {
        let messageIndex = sentClips.count % testMessages.count
        let message = Message(
            content: testMessages[messageIndex],
            label: Message.Label(text: "TEST", type: .tableNumber)
        )
        
        // Record the clip before sending
        recordCurrentClip()
        
        // Send the message
        queueVM.sendMessage(message)
    }
    
    private func sendAllTestMessages() {
        Task {
            for i in 0..<7 {
                sendNextTestMessage()
                try? await Task.sleep(for: .milliseconds(500))
            }
        }
    }
    
    private func recordCurrentClip() {
        let currentClip = queueVM.currentSlot
        if sentClips.isEmpty || sentClips.last != currentClip {
            sentClips.append(currentClip)
        }
    }
    
    private func isClipInRange(_ clip: Int) -> Bool {
        let minClip = appSettings.startSlot
        let maxClip = appSettings.startSlot + appSettings.clipCount - 1
        return clip >= minClip && clip <= maxClip
    }
    
    private func expectedClipSequence() -> [Int] {
        var sequence: [Int] = []
        let start = appSettings.startSlot
        let count = appSettings.clipCount
        
        for i in 0..<min(7, sentClips.count) {
            let clipIndex = start + (i % count)
            sequence.append(clipIndex)
        }
        
        return sequence
    }
}

// Preview
#Preview {
    let appSettings = AppSettings()
    let oscService = OSCService()
    let queueManager = QueueManager()
    let queueViewModel = QueueViewModel(
        queueManager: queueManager,
        oscService: oscService,
        appSettings: appSettings
    )
    
    return ClipRotationTestView()
        .environment(queueViewModel)
        .environment(appSettings)
}