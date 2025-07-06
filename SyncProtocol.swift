//
//  SyncProtocol.swift
//  LED MESSENGER
//
//  Protocol for synchronizing data between paired devices
//  Host (macOS) settings always override Client (iPad) settings
//

import Foundation

// MARK: - Sync Message Types

enum SyncMessage: Codable, Sendable {
    case handshake(HandshakeMessage)
    case settingsSync(SettingsSyncMessage)
    case queueOperation(QueueOperationMessage)
    case acknowledgment(AckMessage)
    
    enum CodingKeys: String, CodingKey {
        case type, data
    }
    
    enum MessageType: String, Codable {
        case handshake, settingsSync, queueOperation, acknowledgment
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(MessageType.self, forKey: .type)
        
        switch type {
        case .handshake:
            let data = try container.decode(HandshakeMessage.self, forKey: .data)
            self = .handshake(data)
        case .settingsSync:
            let data = try container.decode(SettingsSyncMessage.self, forKey: .data)
            self = .settingsSync(data)
        case .queueOperation:
            let data = try container.decode(QueueOperationMessage.self, forKey: .data)
            self = .queueOperation(data)
        case .acknowledgment:
            let data = try container.decode(AckMessage.self, forKey: .data)
            self = .acknowledgment(data)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .handshake(let data):
            try container.encode(MessageType.handshake, forKey: .type)
            try container.encode(data, forKey: .data)
        case .settingsSync(let data):
            try container.encode(MessageType.settingsSync, forKey: .type)
            try container.encode(data, forKey: .data)
        case .queueOperation(let data):
            try container.encode(MessageType.queueOperation, forKey: .type)
            try container.encode(data, forKey: .data)
        case .acknowledgment(let data):
            try container.encode(MessageType.acknowledgment, forKey: .type)
            try container.encode(data, forKey: .data)
        }
    }
}

// MARK: - Message Structures

struct HandshakeMessage: Codable, Sendable {
    let deviceName: String
    let deviceType: DeviceType
    let protocolVersion: String
    let timestamp: Date
    
    init(deviceName: String, deviceType: DeviceType, timestamp: Date) {
        self.deviceName = deviceName
        self.deviceType = deviceType
        self.protocolVersion = "1.0"
        self.timestamp = timestamp
    }
    
    enum DeviceType: String, Codable {
        case host = "host"      // macOS
        case client = "client"  // iPad
    }
}

struct SettingsSyncMessage: Codable, Sendable {
    let oscHost: String
    let oscPort: UInt16
    let layer: Int
    let startSlot: Int
    let clipCount: Int
    let charsPerLine: Double
    let forceCaps: Bool
    let lineBreakMode: Int
    let autoClearAfter: TimeInterval
    let timestamp: Date
}

struct QueueOperationMessage: Codable, Sendable {
    let operation: Operation
    let messageData: MessageData?
    let messageId: UUID?
    let timestamp: Date
    
    enum Operation: String, Codable {
        case add = "add"
        case update = "update"
        case delete = "delete"
        case clear = "clear"
        case send = "send"
        case fullSync = "fullSync"
    }
    
    struct MessageData: Codable, Sendable {
        let id: UUID
        let content: String
        let label: String?
        let timestamp: Date
    }
}

struct AckMessage: Codable, Sendable {
    let originalMessageId: UUID
    let success: Bool
    let error: String?
    let timestamp: Date
}

// MARK: - Sync Manager

@Observable
public final class SyncManager {
    // MARK: - Properties
    var isHost: Bool = false
    var isConnected: Bool = false
    var lastSyncTimestamp: Date?
    
    private let pairingService: PairingService
    private let appSettings: AppSettings
    private let queueManager: QueueManager
    
    // MARK: - Initialization
    
    public init(pairingService: PairingService, appSettings: AppSettings, queueManager: QueueManager) {
        self.pairingService = pairingService
        self.appSettings = appSettings
        self.queueManager = queueManager
    }
    
    // MARK: - Connection Management
    
    func startSync(asHost: Bool) async throws {
        isHost = asHost
        
        if asHost {
            try await pairingService.startHostAdvertising()
        } else {
            try await pairingService.startClientDiscovery()
        }
        
        // Monitor connection state
        Task { @MainActor in
            if pairingService.connectionState == .connected {
                isConnected = true
                try await sendHandshake()
                
                if isHost {
                    // Host immediately sends settings to override client
                    try await sendSettingsSync()
                }
            }
        }
    }
    
    func stopSync() {
        pairingService.disconnect()
        isConnected = false
        lastSyncTimestamp = nil
    }
    
    // MARK: - Message Sending
    
    func sendHandshake() async throws {
        let handshake = HandshakeMessage(
            deviceName: isHost ? "LED Messenger Host" : "LED Messenger Client",
            deviceType: isHost ? .host : .client,
            timestamp: Date()
        )
        
        try await sendMessage(.handshake(handshake))
    }
    
    func sendSettingsSync() async throws {
        guard isHost else { return } // Only host can send settings
        
        let settings = await SettingsSyncMessage(
            oscHost: appSettings.oscHost,
            oscPort: appSettings.oscPort,
            layer: appSettings.layer,
            startSlot: appSettings.startSlot,
            clipCount: appSettings.clipCount,
            charsPerLine: appSettings.charsPerLine,
            forceCaps: appSettings.forceCaps,
            lineBreakMode: appSettings.lineBreakMode,
            autoClearAfter: appSettings.autoClearAfter,
            timestamp: Date()
        )
        
        try await sendMessage(.settingsSync(settings))
    }
    
    func sendQueueOperation(_ operation: QueueOperationMessage.Operation, messageData: QueueOperationMessage.MessageData? = nil, messageId: UUID? = nil) async throws {
        let queueOp = QueueOperationMessage(
            operation: operation,
            messageData: messageData,
            messageId: messageId,
            timestamp: Date()
        )
        
        try await sendMessage(.queueOperation(queueOp))
    }
    
    // MARK: - Queue Synchronization
    
    func syncAddMessage(_ message: Message) async throws {
        let messageData = QueueOperationMessage.MessageData(
            id: message.id,
            content: message.content,
            label: message.label?.text,
            timestamp: message.timestamp
        )
        
        try await sendQueueOperation(.add, messageData: messageData)
    }
    
    func syncUpdateMessage(_ message: Message) async throws {
        let messageData = QueueOperationMessage.MessageData(
            id: message.id,
            content: message.content,
            label: message.label?.text,
            timestamp: message.timestamp
        )
        
        try await sendQueueOperation(.update, messageData: messageData)
    }
    
    func syncDeleteMessage(_ messageId: UUID) async throws {
        try await sendQueueOperation(.delete, messageId: messageId)
    }
    
    func syncClearQueue() async throws {
        try await sendQueueOperation(.clear)
    }
    
    func syncSendMessage(_ messageId: UUID) async throws {
        try await sendQueueOperation(.send, messageId: messageId)
    }
    
    func syncFullQueue() async throws {
        let messages = await queueManager.getAllMessages()
        for message in messages {
            let messageData = QueueOperationMessage.MessageData(
                id: message.id,
                content: message.content,
                label: message.label?.text,
                timestamp: message.timestamp
            )
            
            try await sendQueueOperation(.add, messageData: messageData)
        }
    }
    
    // MARK: - Message Handling
    
    private func sendMessage(_ message: SyncMessage) async throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(message)
        
        try await pairingService.sendMessage(data)
    }
    
    func handleReceivedMessage(_ data: Data) async throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let message = try decoder.decode(SyncMessage.self, from: data)
        
        switch message {
        case .handshake(let handshake):
            await handleHandshake(handshake)
            
        case .settingsSync(let settings):
            await handleSettingsSync(settings)
            
        case .queueOperation(let operation):
            await handleQueueOperation(operation)
            
        case .acknowledgment(let ack):
            await handleAcknowledgment(ack)
        }
        
        lastSyncTimestamp = Date()
    }
    
    private func handleHandshake(_ handshake: HandshakeMessage) async {
        print("Received handshake from \(handshake.deviceName) (\(handshake.deviceType))")
        
        // Send acknowledgment
        let ack = AckMessage(
            originalMessageId: UUID(), // TODO: Track message IDs
            success: true,
            error: nil,
            timestamp: Date()
        )
        
        do {
            try await sendMessage(.acknowledgment(ack))
        } catch {
            print("Failed to send handshake acknowledgment: \(error)")
        }
    }
    
    private func handleSettingsSync(_ settings: SettingsSyncMessage) async {
        guard !isHost else { return } // Only clients accept settings sync
        
        // Apply host settings to override local settings
        await appSettings.setOscHost(settings.oscHost)
        await appSettings.setOscPort(settings.oscPort)
        await appSettings.setLayer(settings.layer)
        await appSettings.setStartSlot(settings.startSlot)
        await appSettings.setClipCount(settings.clipCount)
        await appSettings.setCharsPerLine(settings.charsPerLine)
        await appSettings.setForceCaps(settings.forceCaps)
        await appSettings.setLineBreakMode(settings.lineBreakMode)
        await appSettings.setAutoClearAfter(settings.autoClearAfter)
        
        print("Applied settings sync from host")
    }
    
    private func handleQueueOperation(_ operation: QueueOperationMessage) async {
        switch operation.operation {
        case .add:
            if let messageData = operation.messageData {
                let label = messageData.label.map { Message.Label(type: .customLabel, text: $0) }
                let message = Message(
                    id: messageData.id,
                    content: messageData.content,
                    timestamp: messageData.timestamp,
                    label: label
                )
                await queueManager.enqueueAsync(message)
            }
            
        case .update:
            if let messageData = operation.messageData {
                let label = messageData.label.map { Message.Label(type: .customLabel, text: $0) }
                let message = Message(
                    id: messageData.id,
                    content: messageData.content,
                    timestamp: messageData.timestamp,
                    label: label
                )
                await queueManager.updateMessageAsync(message)
            }
            
        case .delete:
            if let messageId = operation.messageId {
                await queueManager.removeMessageAsync(messageId)
            }
            
        case .clear:
            await queueManager.clearQueueAsync()
            
        case .send:
            // Both devices can send, so this is just a notification
            print("Message sent from paired device")
            
        case .fullSync:
            // Handle full queue synchronization
            await queueManager.clearQueueAsync()
            // Individual messages will follow
        }
    }
    
    private func handleAcknowledgment(_ ack: AckMessage) async {
        if ack.success {
            print("Message acknowledged successfully")
        } else {
            print("Message failed: \(ack.error ?? "Unknown error")")
        }
    }
}