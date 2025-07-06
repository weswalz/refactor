//
//  DashboardContainer.swift
//  LED MESSENGER
//
//  Container view that routes between Solo and Dual dashboard modes
//  Updated: June 16, 2025
//

import SwiftUI

struct DashboardContainer: View {
    @Environment(AppSettings.self) var appSettings
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    // User preference for iPhone UI style
    @AppStorage("useEnhancediPhoneUI") private var useEnhancediPhoneUI = false
    
    private var isCompactDevice: Bool {
        horizontalSizeClass == .compact
    }
    
    var body: some View {
        Group {
            if isCompactDevice {
                // iPhone: Use the clean, working dashboard
                iPhoneDashboardView()
            } else {
                // iPad: Keep original interface (NO CHANGES)
                SoloDashboardView()
            }
        }
        .onShake {
            // Hidden feature: Triple-tap to switch iPhone UI styles (disabled for now)
            // useEnhancediPhoneUI.toggle()
        }
    }
}

#Preview("Dashboard") {
    let appSettings = AppSettings()
    let oscService = OSCService()
    let queueManager = QueueManager()
    let queueViewModel = QueueViewModel(queueManager: queueManager, oscService: oscService, appSettings: appSettings)
    
    return DashboardContainer()
        .environment(queueViewModel)
        .environment(DashboardViewModel())
        .environment(appSettings)
}

// MARK: - Shake Gesture Extension
extension View {
    func onShake(perform action: @escaping () -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: UIDevice.deviceDidShakeNotification)) { _ in
            action()
        }
    }
}

extension UIDevice {
    static let deviceDidShakeNotification = Notification.Name(rawValue: "deviceDidShakeNotification")
}

#if canImport(UIKit)
extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            NotificationCenter.default.post(name: UIDevice.deviceDidShakeNotification, object: nil)
        }
    }
}
#endif