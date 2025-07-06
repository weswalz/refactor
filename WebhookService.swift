//
//  WebhookService.swift
//  LED MESSENGER
//
//  Simple webhook service for sending HTTP notifications
//  Created: June 07, 2025
//

import Foundation

// MARK: - Webhook Event Types
public enum WebhookEvent: String, CaseIterable {
    case messageAdded = "message_added"
    case messageSent = "message_sent"
    case messageDeleted = "message_deleted"
    case messageCancelled = "message_cancelled"
    case queueCleared = "queue_cleared"
}

// MARK: - Webhook Payload
public struct WebhookPayload: Codable {
    let event: String
    let message: WebhookMessage?
    let timestamp: String
    let app: String
    
    struct WebhookMessage: Codable {
        let id: String
        let content: String
        let status: String
        let label: String?
    }
    
    init(event: String, message: WebhookMessage?, timestamp: String) {
        self.event = event
        self.message = message
        self.timestamp = timestamp
        self.app = "LED MESSENGER"
    }
}

// MARK: - Simple Webhook Service
public final class WebhookService: @unchecked Sendable {
    private let session = URLSession.shared
    
    public init() {}
    
    /// Send webhook notification
    public func sendWebhook(
        to url: String,
        event: WebhookEvent,
        message: Message? = nil
    ) async {
        // Validate URL
        guard !url.isEmpty,
              let webhookURL = URL(string: url),
              webhookURL.scheme?.lowercased() == "https" || webhookURL.scheme?.lowercased() == "http" else {
            print("⚠️ Webhook: Invalid URL provided: \(url)")
            return
        }
        
        // Create payload
        let payload = WebhookPayload(
            event: event.rawValue,
            message: message.map { msg in
                WebhookPayload.WebhookMessage(
                    id: msg.id.uuidString,
                    content: msg.content,
                    status: msg.status.rawValue,
                    label: msg.label?.text  // Extract text from Label struct
                )
            },
            timestamp: ISO8601DateFormatter().string(from: Date())
        )
        
        do {
            // Encode payload
            let jsonData = try JSONEncoder().encode(payload)
            
            // Create request
            var request = URLRequest(url: webhookURL)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("LED MESSENGER/1.0", forHTTPHeaderField: "User-Agent")
            request.httpBody = jsonData
            request.timeoutInterval = 10.0 // 10 second timeout
            
            print("📤 Webhook: Sending \(event.rawValue) to \(url)")
            
            // Send request
            let (data, response) = try await session.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                    print("✅ Webhook: Successfully sent \(event.rawValue) (Status: \(httpResponse.statusCode))")
                } else {
                    print("⚠️ Webhook: Server returned status \(httpResponse.statusCode)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("⚠️ Webhook: Response: \(responseString)")
                    }
                }
            }
            
        } catch {
            print("❌ Webhook: Failed to send \(event.rawValue) - \(error.localizedDescription)")
        }
    }
    
    /// Test webhook URL by sending a test ping
    public func testWebhook(url: String) async -> Bool {
        guard !url.isEmpty,
              let webhookURL = URL(string: url) else {
            return false
        }
        
        let testPayload = WebhookPayload(
            event: "test_ping",
            message: nil,
            timestamp: ISO8601DateFormatter().string(from: Date())
        )
        
        do {
            let jsonData = try JSONEncoder().encode(testPayload)
            
            var request = URLRequest(url: webhookURL)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("LED MESSENGER/1.0", forHTTPHeaderField: "User-Agent")
            request.httpBody = jsonData
            request.timeoutInterval = 5.0 // 5 second timeout for test
            
            let (_, response) = try await session.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                return httpResponse.statusCode >= 200 && httpResponse.statusCode < 300
            }
            
            return false
        } catch {
            print("❌ Webhook Test: \(error.localizedDescription)")
            return false
        }
    }
}
