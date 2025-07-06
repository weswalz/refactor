//
//  SettingsWizardView.swift
//  LEDMessenger
//
//  Advanced settings wizard with beautiful UI and preview screens
//  Updated: June 07, 2025 - Fixed Mac Catalyst dismissal and completion flow
//

import SwiftUI
import Observation
import Foundation

struct SettingsWizardView: View {
    // MARK: - Environment & State
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSettings.self) private var appSettings
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    // Keyboard handling
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case host
        case port
        case customLabel
        case webhook
    }
    
    // Device detection
    private var isCompactDevice: Bool {
        horizontalSizeClass == .compact
    }
    
    // FIXED: Completion callback - now properly handled for Mac Catalyst
    var onComplete: (() -> Void)?
    
    @State private var activeStep: Int = 0
    @State private var isFinishing: Bool = false
    @State private var hasUnsavedChanges: Bool = false
    @State private var isDismissing: Bool = false
    
    // Step configuration
    private let steps = [
        ("CONNECTION", "Configure OSC connections"),
        ("CLIP SETUP", "Layer/slot configuration"),
        ("LABEL SETUP", "Configure message labels"),
        ("TEXT FORMAT", "Configure text formatting and preview")
    ]
    
    // MARK: - View Body
    var body: some View {
        ZStack {
            // IMMEDIATE BLACK BACKGROUND - PREVENTS SILVER FLASH
            Color.black
                .ignoresSafeArea()
            
            // Background gradient that fills entire screen
            RadialGradient(
                gradient: Gradient(colors: [Color.purple.opacity(0.3), Color.black]),
                center: .center,
                startRadius: 100,
                endRadius: 600
            )
            .ignoresSafeArea()
            .ignoresSafeArea(.keyboard) // Let keyboard push content up
            
            // Main content
            VStack(spacing: 0) {
                // Header with title and close button
                headerSection
                
                // Step navigation tabs
                stepNavigationTabs
                
                // Main content area - ensure it takes all available space
                mainContentArea
                    .frame(maxWidth: CGFloat.infinity, maxHeight: CGFloat.infinity)
                
                // Bottom navigation
                bottomNavigation
            }
            .frame(maxWidth: CGFloat.infinity, maxHeight: CGFloat.infinity)
        }
        .background(Color.black) // Immediate background
        .frame(maxWidth: CGFloat.infinity, maxHeight: CGFloat.infinity) // Ensure full screen
        .preferredColorScheme(.dark)
        .presentationBackground(Color.black) // BLACK PRESENTATION BACKGROUND - NO SILVER!
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    focusedField = nil
                }
                .foregroundColor(.purple)
            }
        }
    }
    
    // MARK: - UI Components
    
    var headerSection: some View {
        HStack {
            Text("Settings Wizard")
                .font(.headline.bold())
                .foregroundColor(.white)
            
            Spacer()
            
            Button(action: { 
                // FIXED: Proper dismissal for Mac Catalyst
                handleDismissal()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.gray)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.purple.opacity(0.3))
    }
    
    var stepNavigationTabs: some View {
        HStack(spacing: 0) {
            ForEach(Array(steps.enumerated()), id: \.0) { index, step in
                stepTab(index: index, title: step.0, description: step.1)
            }
        }
        .background(Color.black.opacity(0.8))
    }
    
    func stepTab(index: Int, title: String, description: String) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                activeStep = index
            }
        }) {
            VStack(spacing: 8) {
                // Step indicator and title
                HStack(spacing: 8) {
                    // Step number circle
                    Circle()
                        .fill(activeStep == index ? Color.purple : Color.gray.opacity(0.5))
                        .frame(width: 24, height: 24)
                        .overlay(
                            Text("\(index + 1)")
                                .font(.caption.bold())
                                .foregroundColor(.white)
                        )
                    
                    Text(title)
                        .font(.subheadline.bold())
                        .foregroundColor(activeStep == index ? .white : .gray)
                }
                
                // Step description
                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                // Active indicator bar
                Rectangle()
                    .fill(activeStep == index ? Color.purple : Color.clear)
                    .frame(height: 3)
                    .animation(.easeInOut(duration: 0.3), value: activeStep)
            }
            .frame(maxWidth: CGFloat.infinity)
            .padding(.horizontal, 12)
            .padding(.vertical, 16)
        }
        .buttonStyle(.plain)
    }
    
    var mainContentArea: some View {
        TabView(selection: $activeStep) {
            // Step 1: Connection Setup - Use the actual sophisticated ConnectionSetupView
            ConnectionSetupView(focusedField: $focusedField)
                .environment(appSettings)
                .tag(0)
                .frame(maxWidth: CGFloat.infinity, maxHeight: CGFloat.infinity)
                .background(Color.black)
            
            // Step 2: Clip Configuration - Use the actual sophisticated ClipConfigurationView  
            ClipConfigurationView()
                .environment(appSettings)
                .tag(1)
                .frame(maxWidth: CGFloat.infinity, maxHeight: CGFloat.infinity)
                .background(Color.black)
            
            // Step 3: Label Setup - Configure message labels
            LabelSettingsView(focusedField: $focusedField)
                .environment(appSettings)
                .tag(2)
                .frame(maxWidth: CGFloat.infinity, maxHeight: CGFloat.infinity)
                .background(Color.black)
            
            // Step 4: Text Formatting - Use the actual TextFormattingView
            TextFormattingView()
                .environment(appSettings)
                .tag(3)
                .frame(maxWidth: CGFloat.infinity, maxHeight: CGFloat.infinity)
                .background(Color.black)
        }
        .background(Color.black) // BLACK BACKGROUND FOR TABVIEW
#if os(iOS)
        .tabViewStyle(.page(indexDisplayMode: .never))
        .indexViewStyle(.page(backgroundDisplayMode: .never))
#else
        .tabViewStyle(.automatic)
#endif
        .frame(maxWidth: CGFloat.infinity, maxHeight: CGFloat.infinity)
        .animation(.easeInOut(duration: 0.3), value: activeStep)
    }
    
    var bottomNavigation: some View {
        HStack {
            // Back button
            Button(action: goToPreviousStep) {
                Label("Back", systemImage: "chevron.left")
                    .font(.subheadline.bold())
                    .frame(width: 100, height: 44)
            }
            .buttonStyle(.bordered)
            .tint(.pink)
            .disabled(activeStep == 0)
            .opacity(activeStep == 0 ? 0.5 : 1.0)
            
            Spacer()
            
            // Progress indicator
            VStack(spacing: 4) {
                Text("Step \(activeStep + 1) of \(steps.count)")
                    .font(.caption.bold())
                    .foregroundColor(.white)
                
                // Progress bar
                HStack(spacing: 4) {
                    ForEach(0..<steps.count, id: \.self) { index in
                        Circle()
                            .fill(index <= activeStep ? Color.purple : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
            }
            
            Spacer()
            
            // Next/Finish button
            Button(action: goToNextStep) {
                Label(
                    activeStep < steps.count - 1 ? "Next" : (isFinishing ? "Finishing..." : "Finish"),
                    systemImage: activeStep < steps.count - 1 ? "chevron.right" : "checkmark"
                )
                .font(.subheadline.bold())
                .frame(width: 100, height: 44)
            }
            .buttonStyle(.borderedProminent)
            .tint(activeStep < steps.count - 1 ? .purple : .green)
            .disabled(isFinishing)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .background(
            LinearGradient(
                colors: [Color.purple.opacity(0.3), Color.purple.opacity(0.15)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
    }
    
    // MARK: - Navigation Methods
    
    private func goToPreviousStep() {
        guard activeStep > 0 else { return }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            activeStep -= 1
        }
    }
    
    private func goToNextStep() {
        if activeStep < steps.count - 1 {
            // Move to next step
            withAnimation(.easeInOut(duration: 0.3)) {
                activeStep += 1
            }
        } else {
            // Finish wizard
            finishWizard()
        }
    }
    
    private func handleDismissal() {
        guard !isDismissing else { return }
        isDismissing = true
        
        #if targetEnvironment(macCatalyst)
        DispatchQueue.main.async { [weak self] in
            self?.dismiss()
        }
        #else
        dismiss()
        #endif
    }
    
    private func finishWizard() {
        guard !isDismissing && !isFinishing else { return }
        
        isFinishing = true
        
        Task {
            // Let the app settings save with its own debouncing
            // This ensures all pending saves complete
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
            
            // No test sequence - it's handled by dashboard onAppear
            
            await MainActor.run {
                isFinishing = false
                isDismissing = true
                activeStep = 0
                
                #if targetEnvironment(macCatalyst)
                DispatchQueue.main.async { [weak self] in
                    self?.onComplete?()
                    self?.dismiss()
                }
                #else
                onComplete?()
                dismiss()
                #endif
            }
        }
    }
}

// MARK: - Preview
#Preview {
    SettingsWizardView()
        .environment(AppSettings())
        .preferredColorScheme(.dark)
}
