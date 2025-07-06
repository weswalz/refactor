//
//  Logging.swift
//  LEDMessenger
//
//  Created on 5/16/25.
//

import Foundation
import OSLog

// Extension on Logger to provide domain-specific loggers
public extension Logger {
    // App subsystem
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.app.ledmessenger"
    
    // App-specific loggers
    static let app = Logger(subsystem: subsystem, category: "App")
    static let network = Logger(subsystem: subsystem, category: "Network")
    static let osc = Logger(subsystem: subsystem, category: "OSC")
    static let sync = Logger(subsystem: subsystem, category: "Sync")
    static let ui = Logger(subsystem: subsystem, category: "UI")
    static let service = Logger(subsystem: subsystem, category: "Service")
    
    // Helper functions for backwards compatibility
    // Making these public as well for consistency, though not directly causing the current errors
    static func debug(_ message: String, category: String = "App", function: String = #function) {
        let logger = Logger(subsystem: subsystem, category: category)
// logger.debug("\(function): \(message)")
    }
    
    static func info(_ message: String, category: String = "App", function: String = #function) {
        let logger = Logger(subsystem: subsystem, category: category)
// logger.info("\(function): \(message)")
    }
    
    static func error(_ message: String, category: String = "App", function: String = #function) {
        let logger = Logger(subsystem: subsystem, category: category)
// logger.error("\(function): \(message)")
    }
    
    static func critical(_ message: String, category: String = "App", function: String = #function) {
        let logger = Logger(subsystem: subsystem, category: category)
// logger.critical("\(function): \(message)")
    }
    
    static func notice(_ message: String, category: String = "App", function: String = #function) {
        let logger = Logger(subsystem: subsystem, category: category)
// logger.notice("\(function): \(message)")
    }
    
    static func warning(_ message: String, category: String = "App", function: String = #function) {
        let logger = Logger(subsystem: subsystem, category: category)
// logger.warning("\(function): \(message)")
    }
}