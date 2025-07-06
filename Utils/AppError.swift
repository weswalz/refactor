//
//  AppError.swift
//  LEDMessenger
//
//  Created on 5/16/25.
//

import Foundation

enum AppError: Error, LocalizedError, Identifiable {
    case networkError(String)
    case oscError(String)
    case syncError(String)
    case configurationError(String)
    
    var id: String {
        return localizedDescription
    }
    
    var errorDescription: String? {
        switch self {
        case .networkError(let message):
            return "Network Error: \(message)"
        case .oscError(let message):
            return "OSC Error: \(message)"
        case .syncError(let message):
            return "Sync Error: \(message)"
        case .configurationError(let message):
            return "Configuration Error: \(message)"
        }
    }
}