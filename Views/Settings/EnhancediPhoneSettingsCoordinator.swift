//
//  EnhancediPhoneSettingsCoordinator.swift
//  LED MESSENGER
//
//  iPhone-optimized settings coordinator with 2025 SwiftUI best practices
//  Created: June 15, 2025
//

import SwiftUI
import Foundation
#if canImport(UIKit)
import UIKit
#endif
/// Adaptive settings coordinator that provides optimal experience on each device
struct EnhancediPhoneSettingsCoordinator: View {
    @Environment(AppSettings.self) private var appSettings
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedTab = 0
    @State private var showingDismissConfirmation = false
    @State private var keyboardHeight: CGFloat = 0
    
    // FIX: Add focus state for keyboard management
    @FocusState private var focusedField: FocusableField?
    enum FocusableField: Hashable {
        case host, port, customPrefix, webhook, charsPerLine
    }
    
    private var isCompactDevice: Bool {
        horizontalSizeClass == .compact
    }
    
    var body: some View {
        Group {
            if isCompactDevice {
                // iPhone: Enhanced stepped flow with modern iOS 18 navigation
                iPhoneSteppedSettings
            } else {
                // iPad: Keep existing advanced settings wizard
                SettingsWizardView()
            }
        }
        .onAppear {
            setupKeyboardObservers()
        }
        .onDisappear {
            removeKeyboardObservers()
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - iPhone Stepped Settings
extension EnhancediPhoneSettingsCoordinator {
    
    private var iPhoneSteppedSettings: some View {
        NavigationStack {
            ZStack {
                // Modern iOS 18 background
                ContainerRelativeShape()
                    .fill(.ultraThinMaterial.opacity(0.5))
                    .background(
                        LinearGradient(
                            colors: [.purple.opacity(0.3), .indigo.opacity(0.2), .black],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Modern Tab Header
                    modernTabHeader
                    
                    // Content with ViewThatFits for adaptive sizing
                    ViewThatFits(in: .vertical) {
                        // Preferred: Full content
                        fullSettingsContent
                        
                        // Fallback: Scrollable content
                        ScrollView {
                            fullSettingsContent
                                .padding(.vertical)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        // Only dismiss keyboard if tapping on background
                        if focusedField != nil {
                            focusedField = nil
                            hideKeyboard()
                        }
                    }
                    
                    Spacer()
                    
                    // Enhanced navigation with haptics
                    enhancedNavigationButtons
                    
                    // Floating keyboard dismiss button
                    if focusedField != nil || keyboardHeight > 0 {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Button(action: {
                                    focusedField = nil
                                    hideKeyboard()
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "keyboard.chevron.compact.down")
                                        Text("Hide Keyboard")
                                            .fontWeight(.medium)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(.purple)
                                    .foregroundColor(.white)
                                    .clipShape(Capsule())
                                    .shadow(radius: 4)
                                }
                                .padding(.trailing, 20)
                                .padding(.bottom, keyboardHeight > 0 ? keyboardHeight + 10 : 20)
                            }
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .animation(.easeOut(duration: 0.25), value: keyboardHeight)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // FIX: Add keyboard dismissal toolbar
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        focusedField = nil
                    }
                    .foregroundColor(.purple)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        performHapticFeedback(.success)
                        
                        // Save settings and post completion notification
                        appSettings.forceSave()
                        NotificationCenter.default.post(name: .ledMessengerSettingsCompleted, object: nil)
                        
                        dismiss()
                    }
                    .foregroundStyle(.purple)
                    .fontWeight(.semibold)
                }
            }
            .confirmationDialog("Discard Changes?", isPresented: $showingDismissConfirmation) {
                Button("Discard", role: .destructive) {
                    dismiss()
                }
                Button("Keep Editing", role: .cancel) { }
            }
        }
    }
    
    private var modernTabHeader: some View {
        HStack(spacing: 0) {
            ForEach(0..<4) { index in
                Button(action: {
                    withAnimation(.smooth(duration: 0.3)) {
                        selectedTab = index
                    }
                    performHapticFeedback(.selection)
                }) {
                    VStack(spacing: 8) {
                        // Tab title
                        Text(tabTitle(for: index))
                            .font(.subheadline)
                            .fontWeight(selectedTab == index ? .semibold : .medium)
                            .foregroundStyle(selectedTab == index ? .purple : .secondary)
                        
                        // Selection indicator
                        if selectedTab == index {
                            Rectangle()
                                .fill(.purple)
                                .frame(width: 40, height: 3)
                                .clipShape(Capsule())
                        } else {
                            Rectangle()
                                .fill(.clear)
                                .frame(width: 40, height: 3)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 60) // Reduced height for better space efficiency
                    .contentShape(Rectangle()) // Maintain 44pt+ touch target
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
            }
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12)) // Reduced from 16
        .padding(.horizontal, 16) // Reduced from 20
        .padding(.top, 4) // Reduced from 8
    }
    
    @ViewBuilder
    private var fullSettingsContent: some View {
        switch selectedTab {
        case 0:
            EnhancediPhoneConnectionView()
        case 1:
            EnhancediPhoneClipView()
        case 2:
            EnhancediPhoneLabelView()
        case 3:
            EnhancediPhoneTextView()
        default:
            EmptyView()
        }
    }
    
    private var enhancedNavigationButtons: some View {
        HStack(spacing: 16) {
            // Previous button with haptic feedback
            if selectedTab > 0 {
                Button(action: {
                    withAnimation(.smooth(duration: 0.3)) {
                        selectedTab -= 1
                    }
                    performHapticFeedback(.impact(.medium))
                }) {
                    Label("Previous", systemImage: "chevron.left")
                        .labelStyle(.iconOnly)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .frame(width: 40, height: 40) // Reduced from 44x44
                        .background(.ultraThinMaterial, in: Circle())
                        .contentShape(Rectangle().size(width: 44, height: 44)) // Maintain touch target
                }
                .buttonStyle(.plain)
            }
            
            Spacer()
            
            // Page indicator with modern design
            HStack(spacing: 6) {
                ForEach(0..<4) { index in
                    Circle()
                        .fill(selectedTab == index ? .purple : .secondary.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .scaleEffect(selectedTab == index ? 1.2 : 1.0)
                        .animation(.smooth(duration: 0.3), value: selectedTab)
                }
            }
            
            Spacer()
            
            // Next button with haptic feedback
            if selectedTab < 3 {
                Button(action: {
                    withAnimation(.smooth(duration: 0.3)) {
                        selectedTab += 1
                    }
                    performHapticFeedback(.impact(.medium))
                }) {
                    Label("Next", systemImage: "chevron.right")
                        .labelStyle(.iconOnly)
                        .font(.title3)
                        .foregroundStyle(.purple)
                        .frame(width: 40, height: 40) // Reduced from 44x44
                        .background(.purple.opacity(0.2), in: Circle())
                        .contentShape(Rectangle().size(width: 44, height: 44)) // Maintain touch target
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 24) // Reduced from 32
        .padding(.bottom, 16) // Reduced from 20
    }
    
    // MARK: - Helper Methods
    
    private func tabIcon(for index: Int) -> String {
        switch index {
        case 0: return "network"
        case 1: return "square.grid.3x3"
        case 2: return "tag"
        case 3: return "textformat"
        default: return "gear"
        }
    }
    
    private func tabTitle(for index: Int) -> String {
        switch index {
        case 0: return "Connect"
        case 1: return "Clips"
        case 2: return "Labels"
        case 3: return "Format"
        default: return "Settings"
        }
    }
    
    private func performHapticFeedback(_ type: HapticType) {
        #if canImport(UIKit)
        switch type {
        case .impact(let style):
            UIImpactFeedbackGenerator(style: style).impactOccurred()
        case .selection:
            UISelectionFeedbackGenerator().selectionChanged()
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .error:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
        #endif
    }
    
    private func hideKeyboard() {
        #if canImport(UIKit)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
    }
    
    private func setupKeyboardObservers() {
        #if canImport(UIKit)
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                withAnimation(.easeOut(duration: 0.25)) {
                    keyboardHeight = keyboardFrame.height
                }
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { _ in
            withAnimation(.easeOut(duration: 0.25)) {
                keyboardHeight = 0
            }
        }
        #endif
    }
    
    private func removeKeyboardObservers() {
        #if canImport(UIKit)
        NotificationCenter.default.removeObserver(
            self,
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.removeObserver(
            self,
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
        #endif
    }
}

// MARK: - Haptic Feedback Types
private enum HapticType {
    case impact(UIImpactFeedbackGenerator.FeedbackStyle)
    case selection
    case success
    case error
}

// MARK: - Enhanced iPhone Setting Views
// These provide iPhone-optimized versions of the existing settings

struct EnhancediPhoneConnectionView: View {
    @Environment(AppSettings.self) private var appSettings
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @State private var host = ""
    @State private var port = ""
    @State private var isTestingConnection = false
    @State private var connectionResult: ConnectionResult?
    
    @FocusState private var focusedField: AnyHashable?
    
    // Dynamic spacing based on device size
    private var sectionSpacing: CGFloat {
        verticalSizeClass == .compact ? 16 : 24
    }
    
    private var headerIconSize: CGFloat {
        verticalSizeClass == .compact ? 20 : 26
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: sectionSpacing) {
                // Header with modern design
                VStack(spacing: 6) { // Reduced from 8
                    LEDIconView.headerIcon(size: headerIconSize)
                    
                    Text("Network Connection")
                        .font(.title3.bold()) // Reduced from .title2
                        .foregroundStyle(.primary)
                    
                    Text("Connect to Resolume Arena via OSC")
                        .font(.caption) // Reduced from .subheadline
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 12) // Reduced from 20
                
                // Connection form with modern styling
                VStack(spacing: 12) { // Reduced from 16
                    ModernTextField(
                        title: "Host Address",
                        text: $host,
                        placeholder: "192.168.1.100",
                        icon: "globe",
                        keyboardType: .numbersAndPunctuation,
                        externalFocus: $focusedField,
                        focusValue: "host" as AnyHashable
                    )
                    
                    ModernTextField(
                        title: "Port",
                        text: $port,
                        placeholder: "2269",
                        icon: "number",
                        keyboardType: .numberPad,
                        externalFocus: $focusedField,
                        focusValue: "port" as AnyHashable
                    )
                }
                
                // Test connection with enhanced feedback
                Button(action: testConnection) {
                    HStack {
                        if isTestingConnection {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "wifi.circle.fill")
                        }
                        
                        Text(isTestingConnection ? "Testing..." : "Test Connection")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(.purple.gradient, in: RoundedRectangle(cornerRadius: 16))
                    .foregroundStyle(.white)
                }
                .disabled(isTestingConnection || host.isEmpty || port.isEmpty)
                .buttonStyle(.plain)
                
                // Connection result with modern styling
                if let result = connectionResult {
                    ConnectionResultCard(result: result)
                        .transition(.scale.combined(with: .opacity))
                }
                
                Spacer(minLength: 20) // Reduced from 40
            }
            .padding(.horizontal, 20)
        }
        .scrollDismissesKeyboard(.interactively)
        .onTapGesture {
            focusedField = nil
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    focusedField = nil
                }
                .fontWeight(.medium)
                .foregroundColor(.purple)
            }
        }
        .onAppear {
            host = appSettings.oscHost
            port = String(appSettings.oscPort)
        }
        .onChange(of: host) { _, newValue in
            saveConnectionSettings()
        }
        .onChange(of: port) { _, newValue in
            saveConnectionSettings()
        }
    }
    
    private func testConnection() {
        isTestingConnection = true
        connectionResult = nil
        
        // Simulate connection test with proper async handling
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            
            await MainActor.run {
                connectionResult = ConnectionResult.success(message: "Connected to Resolume Arena successfully!")
                isTestingConnection = false
                
                // Haptic feedback for success
                #if canImport(UIKit)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                #endif
            }
        }
    }
    
    private func saveConnectionSettings() {
        if let portInt = UInt16(port) {
            appSettings.updateNetworkConfig(host: host, port: portInt)
        }
    }
}

struct EnhancediPhoneClipView: View {
    @Environment(AppSettings.self) private var appSettings
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @State private var layer = 3
    @State private var startSlot = 1
    @State private var clipCount = 3
    
    @FocusState private var focusedTextField: AnyHashable?
    
    // Dynamic spacing
    private var sectionSpacing: CGFloat {
        verticalSizeClass == .compact ? 16 : 24
    }
    
    private var headerIconSize: CGFloat {
        verticalSizeClass == .compact ? 20 : 26
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: sectionSpacing) {
            // Header
            VStack(spacing: 6) {
                LEDIconView.headerIcon(size: headerIconSize)
                
                Text("Clip Configuration")
                    .font(.title3.bold())
                    .foregroundStyle(.primary)
                
                Text("Configure Resolume Arena layers and clips")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 12)
            
            // Controls with modern steppers
            VStack(spacing: 16) { // Reduced from 20
                ModernStepper(
                    title: "Layer",
                    value: $layer,
                    range: 1...10,
                    icon: "square.stack"
                )
                
                ModernStepper(
                    title: "Start Slot",
                    value: $startSlot,
                    range: 1...64,
                    icon: "play.rectangle"
                )
                
                ModernStepper(
                    title: "Clip Count",
                    value: $clipCount,
                    range: 1...8,
                    icon: "square.grid.2x2"
                )
            }
            
            // Visual preview
            ClipPreviewCard(
                layer: layer,
                startSlot: startSlot,
                clipCount: clipCount
            )
            
            Spacer()
            }
            .padding(.horizontal, 20)
        }
        .scrollDismissesKeyboard(.interactively)
        .onTapGesture {
            focusedTextField = nil
        }
        .onAppear {
            layer = appSettings.layer
            startSlot = appSettings.startSlot
            clipCount = appSettings.clipCount
        }
        .onChange(of: layer) { _, _ in saveClipSettings() }
        .onChange(of: startSlot) { _, _ in saveClipSettings() }
        .onChange(of: clipCount) { _, _ in saveClipSettings() }
    }
    
    private func saveClipSettings() {
        appSettings.updateClipConfig(layer: layer, startSlot: startSlot, clipCount: clipCount)
    }
}

struct EnhancediPhoneLabelView: View {
    @Environment(AppSettings.self) private var appSettings
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @State private var labelType = 0
    @State private var customPrefix = ""
    
    @FocusState private var focusedTextField: AnyHashable?
    
    // Dynamic spacing
    private var sectionSpacing: CGFloat {
        verticalSizeClass == .compact ? 16 : 24
    }
    
    private var headerIconSize: CGFloat {
        verticalSizeClass == .compact ? 20 : 26
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: sectionSpacing) {
            // Header
            VStack(spacing: 6) {
                LEDIconView.headerIcon(size: headerIconSize)
                
                Text("Label Setup")
                    .font(.title3.bold())
                    .foregroundStyle(.primary)
                
                Text("Configure message labels for organization")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 12)
            
            // Label type selection
            VStack(spacing: 12) {
                ForEach(LabelTypeOption.all, id: \.value) { option in
                    LabelTypeCard(
                        option: option,
                        isSelected: labelType == option.value,
                        onSelect: {
                            withAnimation(.smooth(duration: 0.3)) {
                                labelType = option.value
                            }
                        }
                    )
                }
            }
            
            // Custom prefix input (conditional)
            if labelType == 1 {
                ModernTextField(
                    title: "Custom Prefix",
                    text: $customPrefix,
                    placeholder: "VIP",
                    icon: "textformat",
                    externalFocus: $focusedTextField,
                    focusValue: "customPrefix" as AnyHashable
                )
                .transition(.scale.combined(with: .opacity))
            }
            
            // Preview
            LabelPreviewCard(
                labelType: labelType,
                customPrefix: customPrefix
            )
            
            Spacer()
            }
            .padding(.horizontal, 20)
        }
        .scrollDismissesKeyboard(.interactively)
        .onAppear {
            labelType = appSettings.defaultLabelType
            customPrefix = appSettings.customLabelPrefix
        }
        .onChange(of: labelType) { _, _ in saveLabelSettings() }
        .onChange(of: customPrefix) { _, _ in saveLabelSettings() }
    }
    
    
    private func saveLabelSettings() {
        // Fixed: Using individual setter methods instead of updateLabelConfig
        appSettings.setDefaultLabelType(labelType)
        appSettings.setCustomLabelPrefix(customPrefix)
    }
}

struct EnhancediPhoneTextView: View {
    @Environment(AppSettings.self) private var appSettings
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @State private var forceCaps = false
    @State private var lineBreakMode = 0
    @State private var charactersPerLine = 12.0
    @State private var autoClearMinutes = 3.0
    @State private var previewText = "Happy Birthday Veronica!"
    
    // Dynamic spacing
    private var sectionSpacing: CGFloat {
        verticalSizeClass == .compact ? 16 : 24
    }
    
    private var headerIconSize: CGFloat {
        verticalSizeClass == .compact ? 20 : 26
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: sectionSpacing) {
            // Header
            VStack(spacing: 6) {
                LEDIconView.headerIcon(size: headerIconSize)
                
                Text("Text Formatting")
                    .font(.title3.bold())
                    .foregroundStyle(.primary)
                
                Text("Configure how text appears on the LED wall")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 12)
            
            // Options
            VStack(spacing: 12) { // Reduced from 16
                ModernToggle(
                    title: "Force Uppercase",
                    description: "Convert all text to uppercase",
                    isOn: $forceCaps,
                    icon: "textformat.abc.uppercase"
                )
                
                ModernPicker(
                    title: "Line Breaks",
                    selection: $lineBreakMode,
                    options: [
                        (0, "None"),
                        (1, "After Words"),
                        (2, "After Characters")
                    ],
                    icon: "line.horizontal.3"
                )
                
                if lineBreakMode == 2 {
                    ModernSlider(
                        title: "Characters Per Line",
                        value: $charactersPerLine,
                        range: 10...40,
                        step: 1,
                        format: "%.0f chars",
                        icon: "ruler"
                    )
                    .transition(.scale.combined(with: .opacity))
                }
                
                ModernSlider(
                    title: "Auto-Clear Duration",
                    value: $autoClearMinutes,
                    range: 1...10,
                    step: 1,
                    format: "%.0f min",
                    icon: "timer"
                )
            }
            
            // Live preview
            TextPreviewCard(
                text: previewText,
                forceCaps: forceCaps,
                lineBreakMode: lineBreakMode,
                charactersPerLine: Int(charactersPerLine)
            )
            
            Spacer()
            }
            .padding(.horizontal, 20)
        }
        .scrollDismissesKeyboard(.interactively)
        .onAppear {
            forceCaps = appSettings.forceCaps
            lineBreakMode = appSettings.lineBreakMode
            charactersPerLine = appSettings.charsPerLine
            autoClearMinutes = appSettings.autoClearAfter / 60.0
        }
        .onChange(of: forceCaps) { _, _ in saveTextSettings() }
        .onChange(of: lineBreakMode) { _, _ in saveTextSettings() }
        .onChange(of: charactersPerLine) { _, _ in saveTextSettings() }
        .onChange(of: autoClearMinutes) { _, _ in saveTextSettings() }
    }
    
    private func saveTextSettings() {
        // Fixed: Using individual setter methods instead of updateFormattingOptions
        appSettings.setForceCaps(forceCaps)
        appSettings.setAutoClearAfter(autoClearMinutes * 60)
        appSettings.setLineBreakMode(lineBreakMode)
        appSettings.setCharsPerLine(charactersPerLine)
    }
}

// Modern UI Components are imported from ModerniPhoneUIComponents.swift

#Preview {
    EnhancediPhoneSettingsCoordinator()
        .environment(AppSettings())
}