//
//  Message.swift
//  LEDMessenger
//
//  Created by Wesley Walz on 5/12/25.
//

import Foundation

/// Represents a single message in the system.
public struct Message: Identifiable, Codable, Sendable, Equatable, Hashable {
    public let id: UUID
    public let content: String
    public let timestamp: Date
    public let status: MessageStatus
    public let priority: MessagePriority
    public let label: Label?

    public init(
        id: UUID = UUID(),
        content: String,
        timestamp: Date = Date(),
        status: MessageStatus = .pending,
        priority: MessagePriority = .normal,
        label: Label? = nil
    ) {
        self.id = id
        self.content = content
        self.timestamp = timestamp
        self.status = status
        self.priority = priority
        self.label = label
    }

    public func withStatus(_ newStatus: MessageStatus) -> Message {
        Message(
            id: id,
            content: content,
            timestamp: timestamp,
            status: newStatus,
            priority: priority,
            label: label
        )
    }

    public func withContent(_ newContent: String) -> Message {
        Message(
            id: id,
            content: newContent,
            timestamp: timestamp,
            status: status,
            priority: priority,
            label: label
        )
    }

    public func withLabel(_ newLabel: Label?) -> Message {
        Message(
            id: id,
            content: content,
            timestamp: timestamp,
            status: status,
            priority: priority,
            label: newLabel
        )
    }

    public enum MessageStatus: String, Codable, Sendable {
        case pending
        case sent
        case delivered
        case read
        case failed
    }

    public enum MessagePriority: String, Codable, Sendable, Comparable {
        case low
        case normal
        case high
        case critical

        public static func < (lhs: MessagePriority, rhs: MessagePriority) -> Bool {
            let order: [MessagePriority] = [.low, .normal, .high, .critical]
            let lhsIndex = order.firstIndex(of: lhs) ?? 0
            let rhsIndex = order.firstIndex(of: rhs) ?? 0
            return lhsIndex < rhsIndex
        }
    }

    public struct Label: Codable, Sendable, Equatable, Hashable {
        public let type: MessageLabelType
        public let text: String

        public init(type: MessageLabelType, text: String) {
            self.type = type
            self.text = text
        }
    }

    public enum MessageLabelType: String, Codable, Sendable, Equatable {
        case tableNumber
        case customLabel
        case noLabel
    }
}