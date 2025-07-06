//
//  DashboardHeaderView.swift
//  LED MESSENGER
//
//  Shared header component for dashboard views
//  Updated: June 07, 2025 - Fixed Mac Catalyst settings wizard dismissal
//

import SwiftUI

// MARK: - Color Extensions
fileprivate extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red:   Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >>  8) & 0xFF) / 255,
            blue:  Double( hex        & 0xFF) / 255,
            opacity: alpha
        )
    }
}

struct DashboardHeaderView: View {
    @State private var showingSettingsWizard = false
    @State private var showingProfile = false
    @AppStorage("hasShownDashboardSettings") private var hasShownDashboardSettings = false
    @Environment(DashboardViewModel.self) var dashboardVM
    @Environment(QueueViewModel.self) var queueVM
    @Environment(AppSettings.self) var appSettings
    @Environment(\.authViewModel) var authViewModel
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    // Device detection for settings presentation
    private var isCompactDevice: Bool {
        horizontalSizeClass == .compact
    }
    
    var body: some View {
        HStack(alignment: .center) {
            // Left side - Logo and status info grouped together
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Image("ledmwide35")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 18)
                }
                
                // Status and connection info grouped together
                HStack(spacing: 6) {
                    StatusChip()
                    
                    // IP info with reduced font size, positioned next to status
                    InfoChip(text: "\(appSettings.oscHost):\(appSettings.oscPort)")
                        .font(.system(size: 10, weight: .medium)) // Reduced from caption2 size
                }
            }
            
            Spacer()
            
            // Right side - Action buttons vertically centered
            HStack(spacing: 12) {
                // Profile button
                Button {
                    showingProfile = true
                } label: {
                    Image(systemName: "person.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Color(hex: 0x8538df))
                }
                
                // Settings button with device-aware presentation
                RotatingGearButton {
                    showingSettingsWizard = true
                }
                .foregroundStyle(Color(hex: 0x8538df))
                
                Button("Clear") {
                    queueVM.clearQueue()
                    queueVM.triggerClearSlot(at: queueVM.startingSlot + appSettings.clipCount)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(hex: 0x7026c6))
                
                AnimatedBorderButton(
                    cornerRadius: 8,
                    lineWidth: 1.5,
                    tintColor: Color(hex: 0xaf34cb),
                    action: {
                        dashboardVM.openModal()
                    }
                ) {
                    Text("New Message")
                }
            }
        }
        .padding(.horizontal)
        // DEVICE-AWARE: Settings presentation optimized for each platform
        // iPhone: Mobile-optimized settings coordinator  
        // iPad/Mac: Full desktop-style settings wizard
        .sheet(isPresented: isCompactDevice ? $showingSettingsWizard : .constant(false)) {
            // iPhone: Use mobile-optimized settings
            EnhancediPhoneSettingsCoordinator()
                .environment(appSettings)
                .environment(queueVM)
                .environment(dashboardVM)
        }
        .fullScreenCover(isPresented: !isCompactDevice ? $showingSettingsWizard : .constant(false)) {
            // iPad/Mac: Use full desktop settings wizard with full screen
            SettingsWizardView(onComplete: {
                DispatchQueue.main.async {
                    showingSettingsWizard = false
                    hasShownDashboardSettings = true
                }
            })
            .environment(appSettings)
            .environment(queueVM)
            .environment(dashboardVM)
            .background(Color.black) // IMMEDIATE BLACK BACKGROUND
            .presentationBackground(Color.black) // NO SILVER PRESENTATION BACKGROUND
        }
        .sheet(isPresented: $showingProfile) {
            ProfileView()
                .environment(\.authViewModel, authViewModel)
                .presentationDetents([.height(650)])
                .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Rotating Gear Button
struct RotatingGearButton: View {
    @State private var rotation: Double = 0
    var action: () -> Void
    
    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.6)) { rotation += 360 }
            action()
        } label: {
            Image(systemName: "gearshape.fill")
                .font(.title3)
        }
        .rotationEffect(.degrees(rotation))
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6)) { rotation += 360 }
        }
    }
}
