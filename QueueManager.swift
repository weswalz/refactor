//
//  QueueManager.swift
//  LEDMessenger
//
//  Created by Wesley Walz on 5/12/25.
//

import Foundation
import OSLog
import Observation

// Private logger instance
private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.app.ledmessenger", category: "App")

@Observable
@available(iOS 18.0, *)
public final class QueueManager {
    // Using a private actor for thread-safe access to messages
    // The Storage actor now holds a weak reference to its owner QueueManager
    // to notify it of changes.
    private actor Storage {
        var messages: [Message] = []
        private weak var ownerQueueManager: QueueManager?

        // Initializes the Storage actor with initial messages and a reference
        // to the owning QueueManager.
        init(messages: [Message] = [], owner: QueueManager?) {
            self.messages = messages
            self.ownerQueueManager = owner
        }
        
        // Sets the owner after initialization
        func setOwner(_ owner: QueueManager) {
            self.ownerQueueManager = owner
        }
        
        // Retrieves all messages from storage.
        func getMessages() -> [Message] {
            return messages
        }
        
        // Appends a new message to storage and notifies the QueueManager.
        func append(_ message: Message) async {
            messages.append(message)
            await ownerQueueManager?.refreshMessages()
        }
        
        // Removes a message at a specific index and notifies the QueueManager.
        // Returns true if removal was successful, false otherwise.
        func remove(at index: Int) async -> Bool {
            guard messages.indices.contains(index) else {
                return false
            }
            messages.remove(at: index)
            await ownerQueueManager?.refreshMessages()
            return true
        }
        
        // Removes a message by its ID and notifies the QueueManager.
        // Returns true if a message was found and removed, false otherwise.
        func removeById(_ id: UUID) async -> Bool {
            let initialCount = messages.count
            messages.removeAll { $0.id == id }
            let removed = messages.count < initialCount
            if removed {
                await ownerQueueManager?.refreshMessages()
            }
            return removed
        }
        
        // Clears all messages from storage and notifies the QueueManager.
        // Returns the number of messages cleared.
        func clear() async -> Int {
            let count = messages.count
            if count > 0 {
                messages.removeAll()
                await ownerQueueManager?.refreshMessages()
            }
            return count
        }
        
        // Moves messages from specified offsets to a new offset and notifies the QueueManager.
        func move(fromOffsets: IndexSet, toOffset: Int) async {
            messages.move(fromOffsets: fromOffsets, toOffset: toOffset)
            await ownerQueueManager?.refreshMessages()
        }
        
        // Updates the status of a message by its ID and notifies the QueueManager.
        // Returns true if the message was found and updated, false otherwise.
        func updateStatus(id: UUID, status: Message.MessageStatus) async -> Bool {
            guard let index = messages.firstIndex(where: { $0.id == id }) else {
                return false
            }
            messages[index] = messages[index].withStatus(status)
            await ownerQueueManager?.refreshMessages()
            return true
        }
        
        // Updates an entire message by its ID and notifies the QueueManager.
        // Returns true if the message was found and updated, false otherwise.
        func updateMessage(_ message: Message) async -> Bool {
            guard let index = messages.firstIndex(where: { $0.id == message.id }) else {
                return false
            }
            messages[index] = message
            await ownerQueueManager?.refreshMessages()
            return true
        }
        
        // Replaces all messages with new ones and notifies the QueueManager.
        func replaceAll(_ newMessages: [Message]) async {
            messages = newMessages
            await ownerQueueManager?.refreshMessages()
        }
        
        // Removes a message by ID and notifies the QueueManager.
        func removeMessageAsync(_ messageId: UUID) async -> Bool {
            return await removeById(messageId)
        }
        
        // Gets all messages for synchronization purposes.
        func getAllMessages() async -> [Message] {
            return messages
        }
    }
    
    private let storage: Storage
    
    // Published state for UI access, updated reactively.
    public private(set) var messages: [Message] = []
    
    // Private property to be initialized after all stored properties
    @ObservationIgnored private var storageTask: Task<Void, Never>?
    
    // Initializes the QueueManager with initial messages.
    // The polling task has been removed; updates are now reactive.
    public init(initialMessages: [Message] = []) {
        // First initialize the required properties
        self.messages = initialMessages
        // Initialize storage with nil owner temporarily 
        self.storage = Storage(messages: initialMessages, owner: nil)
        
        // Then perform a second phase initialization to set the owner
        storageTask = Task {
            // Access to self is now safe as all stored properties are initialized
            await self.storage.setOwner(self)
            await self.refreshMessages()
        }
    }
    
    // Cleanup tasks when QueueManager is being deallocated
    deinit {
        storageTask?.cancel()
    }

    // MARK: - Synchronous API (creates tasks internally)
    
    // Enqueues a new message. Storage actor will trigger refreshMessages.
    public func enqueue(_ message: Message) {
        Task {
// logger.debug("Enqueuing message: \(message.content)")
            await storage.append(message)
        }
    }

    // Removes a message at a specific index. Storage actor will trigger refreshMessages.
    public func removeMessage(at index: Int) {
        Task {
            let success = await storage.remove(at: index)
            if success {
// logger.debug("Removed message at index \(index)")
            } else {
// logger.warning("Attempted to remove message at invalid index: \(index)")
            }
        }
    }

    /// Remove the message at a specific index.
    /// Convenience wrapper so other callers can use `remove(at:)`.
    public func remove(at index: Int) {
        removeMessage(at: index)
    }

    /// Remove the first message that matches by `id`. Storage actor will trigger refreshMessages.
    public func remove(_ message: Message) {
        Task {
            let success = await storage.removeById(message.id)
            
            if success {
// logger.debug("Removed message with ID: \(message.id)")
            } else {
// logger.warning("Attempted to remove non-existent message with ID: \(message.id)")
            }
        }
    }

    // Clears the message queue. Storage actor will trigger refreshMessages.
    public func clearQueue() {
        Task {
            _ = await storage.clear()
// logger.info("Clearing message queue, removed \(count) messages")
        }
    }

    // Reorders messages. Storage actor will trigger refreshMessages.
    public func reorder(fromOffsets: IndexSet, toOffset: Int) {
        Task {
            await storage.move(fromOffsets: fromOffsets, toOffset: toOffset)
// logger.debug("Reordering messages from offsets \(fromOffsets) to offset \(toOffset)")
        }
    }
    
    // Updates the status of a message. Storage actor will trigger refreshMessages.
    public func updateMessageStatus(id: UUID, status: Message.MessageStatus) {
        Task {
            let success = await storage.updateStatus(id: id, status: status)
            
            if success {
// logger.debug("Updated message status: \(id) to \(status.rawValue)")
            } else {
// logger.warning("Attempted to update status for non-existent message: \(id)")
            }
        }
    }

    // MARK: - Async API (for use in async contexts)
    
    // Enqueues a new message. Storage actor will trigger refreshMessages.
    public func enqueueAsync(_ message: Message) async {
// logger.debug("Enqueuing message: \(message.content)")
        await storage.append(message)
    }

    // Removes a message at a specific index. Storage actor will trigger refreshMessages.
    public func removeMessageAsync(at index: Int) async {
        let success = await storage.remove(at: index)
        if success {
// logger.debug("Removed message at index \(index)")
        } else {
// logger.warning("Attempted to remove message at invalid index: \(index)")
        }
    }

    /// Remove the message at a specific index.
    /// Convenience wrapper so other callers can use `remove(at:)`.
    public func removeAsync(at index: Int) async {
        await removeMessageAsync(at: index)
    }

    /// Remove the first message that matches by `id`. Storage actor will trigger refreshMessages.
    public func removeAsync(_ message: Message) async {
        let success = await storage.removeById(message.id)
        
        if success {
// logger.debug("Removed message with ID: \(message.id)")
        } else {
// logger.warning("Attempted to remove non-existent message with ID: \(message.id)")
        }
    }

    // Clears the message queue. Storage actor will trigger refreshMessages.
    public func clearQueueAsync() async {
        _ = await storage.clear()
// logger.info("Clearing message queue, removed \(count) messages")
    }

    // Reorders messages. Storage actor will trigger refreshMessages.
    public func reorderAsync(fromOffsets: IndexSet, toOffset: Int) async {
        await storage.move(fromOffsets: fromOffsets, toOffset: toOffset)
// logger.debug("Reordering messages from offsets \(fromOffsets) to offset \(toOffset)")
    }
    
    // Updates the status of a message. Storage actor will trigger refreshMessages.
    public func updateMessageStatusAsync(id: UUID, status: Message.MessageStatus) async {
        let success = await storage.updateStatus(id: id, status: status)
        
        if success {
// logger.debug("Updated message status: \(id) to \(status.rawValue)")
        } else {
// logger.warning("Attempted to update status for non-existent message: \(id)")
        }
    }
    
    // Updates an entire message. Storage actor will trigger refreshMessages.
    public func updateMessageAsync(_ message: Message) async {
        let success = await storage.updateMessage(message)
        
        if success {
// logger.debug("Updated message: \(message.id)")
        } else {
// logger.warning("Attempted to update non-existent message: \(message.id)")
        }
    }
    
    // Replaces all messages with new ones. Storage actor will trigger refreshMessages.
    public func replaceAllMessagesAsync(_ newMessages: [Message]) async {
        await storage.replaceAll(newMessages)
// logger.info("Replaced all messages with \(newMessages.count) new messages")
    }
    
    // Removes a message by ID. Storage actor will trigger refreshMessages.
    public func removeMessageAsync(_ messageId: UUID) async {
        let success = await storage.removeMessageAsync(messageId)
        
        if success {
// logger.debug("Removed message: \(messageId)")
        } else {
// logger.warning("Attempted to remove non-existent message: \(messageId)")
        }
    }
    
    // Gets all messages for synchronization purposes.
    public func getAllMessages() async -> [Message] {
        return await storage.getAllMessages()
    }

    // This method is called by the Storage actor to refresh the QueueManager's messages.
    // It ensures that the UI (or any observer of QueueManager.messages) gets updated.
    @MainActor // Ensure UI updates happen on the main thread.
    internal func refreshMessages() async {
        self.messages = await storage.getMessages()
        // logger.trace("QueueManager.messages refreshed from Storage.")
    }
}

// MARK: - Sendable Conformance
extension QueueManager: @unchecked Sendable {}
