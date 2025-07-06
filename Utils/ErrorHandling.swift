//
//  ErrorHandling.swift
//  LEDMessenger
//
//  Created on 5/16/25.
//

import Foundation
import SwiftUI

// Define AlertItem struct conforming to Identifiable
// This struct is used to hold error details for display in an alert.
public struct AlertItem: Identifiable {
    public var id = UUID() // Conforms to Identifiable
    var title: Text
    var message: Text
    var dismissButton: Alert.Button?

    // Initializer for convenience
    public init(title: Text, message: Text, dismissButton: Alert.Button? = .default(Text("OK"))) {
        self.title = title
        self.message = message
        self.dismissButton = dismissButton
    }
}

// ErrorView ViewModifier to present an alert when an error occurs.
// It uses the .alert(item:content:) modifier for a cleaner implementation.
struct ErrorView: ViewModifier {
    @Binding var error: AlertItem? // The AlertItem to display.
    
    func body(content: Content) -> some View {
        content
            .alert(item: $error) { alertItem in // Use the item-based alert
                Alert(
                    title: alertItem.title,
                    message: alertItem.message,
                    dismissButton: alertItem.dismissButton
                )
            }
    }
}

// Extension on View to provide a convenient withErrorHandling modifier.
extension View {
    // Applies the ErrorView modifier to the view.
    // - Parameter error: A binding to an optional AlertItem.
    // - Returns: A view modified to present an alert when the error is non-nil.
    func withErrorHandling(error: Binding<AlertItem?>) -> some View {
        modifier(ErrorView(error: error))
    }
}