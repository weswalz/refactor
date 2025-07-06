//
//  iPhoneSettingsCoordinator.swift
//  LED MESSENGER
//
//  iPhone-optimized settings coordinator with 2025 SwiftUI design trends
//  Created: December 15, 2024
//

import SwiftUI
import Observation

/// Main coordinator for iPhone-optimized settings interface
struct iPhoneSettingsCoordinator: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSettings.self) private var appSettings
    
    @State private var currentStep: iPhoneSettingsStep = .connection
    @State private var isCompleting = false
    
    // Keyboard handling
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case host
        case port
        case customLabel
        case webhook
        case charsPerLine
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Modern header with progress
                headerSection
                
                // Main content with smooth transitions
                mainContentSection
                
                Spacer(minLength: 0)
                
                // Clean bottom navigation
                bottomNavigationSection
            }
            .background(.black)
        }
        .preferredColorScheme(.dark)
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
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Settings")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .font(.headline)
                .foregroundStyle(.blue)
            }
            .padding(.horizontal, 20)
            
            // Step progress indicator
            stepProgressIndicator
        }
        .padding(.vertical, 20)
        .background(.black)
    }
    
    private var stepProgressIndicator: some View {
        HStack(spacing: 12) {
            ForEach(iPhoneSettingsStep.allCases, id: \.self) { step in
                VStack(spacing: 8) {
                    Circle()
                        .fill(currentStep.rawValue >= step.rawValue ? .purple : .gray.opacity(0.3))
                        .frame(width: 12, height: 12)
                        .scaleEffect(currentStep == step ? 1.2 : 1.0)
                        .animation(.spring(response: 0.3), value: currentStep)
                    
                    Text(step.title)
                        .font(.caption2)
                        .foregroundStyle(currentStep == step ? .white : .gray)
                        .lineLimit(1)
                }
                
                if step != iPhoneSettingsStep.allCases.last {
                    Rectangle()
                        .fill(.gray.opacity(0.3))
                        .frame(height: 1)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Main Content Section
    private var mainContentSection: some View {
        TabView(selection: $currentStep) {
            ForEach(iPhoneSettingsStep.allCases, id: \.self) { step in
                Group {
                    switch step {
                    case .connection:
                        iPhoneConnectionView(focusedField: $focusedField)
                    case .clips:
                        iPhoneClipView()
                    case .textFormat:
                        iPhoneTextFormatView()
                    case .labels:
                        iPhoneLabelView()
                    }
                }
                .tag(step)
                .environment(appSettings)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .animation(.easeInOut(duration: 0.3), value: currentStep)
    }
    
    // MARK: - Bottom Navigation
    private var bottomNavigationSection: some View {
        HStack(spacing: 16) {
            // Previous button
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    if let prevStep = currentStep.previous {
                        currentStep = prevStep
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .font(.headline)
                .foregroundStyle(currentStep.previous != nil ? .white : .gray)
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(.gray.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(currentStep.previous == nil)
            
            // Next button
            Button {
                if let nextStep = currentStep.next {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentStep = nextStep
                    }
                } else {
                    completeSettings()
                }
            } label: {
                HStack(spacing: 8) {
                    Text(currentStep.next != nil ? "Next" : "Complete")
                    if currentStep.next != nil {
                        Image(systemName: "chevron.right")
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                    }
                }
                .font(.headline.bold())
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(currentStep.next != nil ? .purple : .green)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(isCompleting)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(.black)
    }
    
    // MARK: - Methods
    private func completeSettings() {
        isCompleting = true
        
        Task {
            // Let the app settings save with its own debouncing
            // This ensures all pending saves complete
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second for any pending saves
            
            await MainActor.run {
                // Post notification that settings are completed
                NotificationCenter.default.post(name: .ledMessengerSettingsCompleted, object: nil as Any?)
                dismiss()
            }
        }
    }
}

// MARK: - Settings Step Enum
enum iPhoneSettingsStep: Int, CaseIterable {
    case connection = 0
    case clips = 1
    case textFormat = 2
    case labels = 3
    
    var title: String {
        switch self {
        case .connection: return "Network"
        case .clips: return "Clips"
        case .textFormat: return "Text"
        case .labels: return "Labels"
        }
    }
    
    var fullTitle: String {
        switch self {
        case .connection: return "Network Setup"
        case .clips: return "Clip Configuration" 
        case .textFormat: return "Text Formatting"
        case .labels: return "Label Settings"
        }
    }
    
    var next: iPhoneSettingsStep? {
        guard let nextIndex = iPhoneSettingsStep.allCases.firstIndex(where: { $0.rawValue == self.rawValue + 1 })
        else { return nil }
        return iPhoneSettingsStep.allCases[nextIndex]
    }
    
    var previous: iPhoneSettingsStep? {
        guard self.rawValue > 0 else { return nil }
        return iPhoneSettingsStep(rawValue: self.rawValue - 1)
    }
}

#Preview {
    iPhoneSettingsCoordinator()
        .environment(AppSettings())
}
