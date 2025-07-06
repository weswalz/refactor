//
//  PhoneAdaptiveView.swift
//  LED MESSENGER
//
//  iPhone-optimized view using iOS 18 SwiftUI components
//  Created: June 15, 2025 - Fixed compilation errors
//

import SwiftUI

struct PhoneAdaptiveView: View {
    @Environment(QueueViewModel.self) var queueVM
    @Environment(DashboardViewModel.self) var dashboardVM
    @Environment(AppSettings.self) var appSettings
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    @State private var messageToEdit: Message? = nil
    @State private var showEditModal = false
    
    // Determine if we're on iPhone based on size classes
    private var isCompactDevice: Bool {
        horizontalSizeClass == .compact
    }
    
    var body: some View {
        Group {
            if isCompactDevice {
                // iPhone-optimized interface
                iPhoneDashboardView()
            } else {
                // Keep original iPad interface
                SoloDashboardView()
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showEditModal, onDismiss: {
            messageToEdit = nil
        }) {
            MessageEditSheet(message: $messageToEdit, showEditModal: $showEditModal)
                .environment(appSettings)
                .environment(queueVM)
                .environment(dashboardVM)
        }
    }
}

// MARK: - Preview
#Preview("Phone Adaptive Layout") {
    let appSettings = AppSettings()
    let oscService = OSCService()
    let queueManager = QueueManager()
    let queueViewModel = QueueViewModel(queueManager: queueManager, oscService: oscService, appSettings: appSettings)
    
    return PhoneAdaptiveView()
        .environment(queueViewModel)
        .environment(DashboardViewModel())
        .environment(appSettings)
}
