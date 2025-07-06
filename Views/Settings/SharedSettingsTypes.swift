//
//  SharedSettingsTypes.swift
//  LED MESSENGER
//
//  Created by Wesley Walz on 7/1/25.
//

import Foundation

// Extension for NSNotification.Name
extension NSNotification.Name {
    static let ledMessengerSettingsCompleted = NSNotification.Name("ledMessengerSettingsCompleted")
}

/// Connection test result for iPhone settings
enum ConnectionResult {
    case success(message: String)
    case failure(message: String)
    
    var isSuccess: Bool {
        switch self {
        case .success: return true
        case .failure: return false
        }
    }
    
    var message: String {
        switch self {
        case .success(let message), .failure(let message):
            return message
        }
    }
}

/// Label type options for iPhone settings
struct LabelTypeOption {
    let value: Int
    let title: String
    let description: String
    let icon: String
    
    static let all: [LabelTypeOption] = [
        LabelTypeOption(
            value: 0,
            title: "Table Numbers",
            description: "Use numeric table identifiers",
            icon: "number.circle"
        ),
        LabelTypeOption(
            value: 1,
            title: "Custom Labels",
            description: "Use custom text labels with prefix",
            icon: "tag.circle"
        ),
        LabelTypeOption(
            value: 2,
            title: "No Labels",
            description: "Messages without labels",
            icon: "minus.circle"
        )
    ]
}
