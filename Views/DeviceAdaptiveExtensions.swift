//
//  DeviceAdaptiveExtensions.swift
//  LED MESSENGER
//
//  Created on June 17, 2025
//  Device-adaptive view modifiers and extensions
//

import SwiftUI

// MARK: - Device Appropriate Modal

extension View {
    /// Present a modal in a device-appropriate way
    func deviceAppropriateModal<Content: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        self.modifier(DeviceAppropriateModalModifier(isPresented: isPresented, content: content))
    }
}

struct DeviceAppropriateModalModifier<ModalContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    @ViewBuilder let content: () -> ModalContent
    @Environment(\.deviceEnvironment) private var deviceEnvironment
    
    @MainActor
    func body(content: Content) -> some View {
        switch deviceEnvironment.deviceType {
        case .iPhone:
            // iPhone: Use full screen cover
            content
                .fullScreenCover(isPresented: $isPresented) {
                    self.content()
                }
            
        case .iPad:
            // iPad: Use sheet with form presentation
            content
                .sheet(isPresented: $isPresented) {
                    self.content()
                        .presentationDetents([.large])
                        .presentationDragIndicator(.visible)
                }
            
        case .macCatalyst, .mac:
            // Mac: Use sheet with fixed size
            content
                .sheet(isPresented: $isPresented) {
                    self.content()
                        .frame(minWidth: 600, minHeight: 400)
                }
        }
    }
}

// MARK: - Device Environment Extensions
// Note: networkConfig is already defined in DeviceEnvironment.swift

// MARK: - Adaptive Button Styles

struct DeviceAdaptiveButtonStyle: ButtonStyle {
    @Environment(\.deviceEnvironment) private var deviceEnvironment
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(backgroundColor(for: configuration))
            .foregroundColor(.white)
            .cornerRadius(cornerRadius)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
    
    @MainActor
    private var horizontalPadding: CGFloat {
        switch deviceEnvironment.deviceType {
        case .iPhone: return 16
        case .iPad: return 24
        case .macCatalyst, .mac: return 20
        }
    }
    
    @MainActor
    private var verticalPadding: CGFloat {
        switch deviceEnvironment.deviceType {
        case .iPhone: return 12
        case .iPad: return 16
        case .macCatalyst, .mac: return 14
        }
    }
    
    @MainActor
    private var cornerRadius: CGFloat {
        switch deviceEnvironment.deviceType {
        case .iPhone: return 8
        case .iPad: return 12
        case .macCatalyst, .mac: return 10
        }
    }
    
    private func backgroundColor(for configuration: Configuration) -> Color {
        if configuration.isPressed {
            return Color.purple.opacity(0.8)
        } else {
            return Color.purple
        }
    }
}

// MARK: - Adaptive Text Styles

extension Text {
    /// Apply device-appropriate text styling
    func deviceAdaptiveStyle(_ style: DeviceTextStyle) -> some View {
        self.modifier(DeviceAdaptiveTextModifier(style: style))
    }
}

enum DeviceTextStyle {
    case title
    case headline
    case body
    case caption
}

struct DeviceAdaptiveTextModifier: ViewModifier {
    let style: DeviceTextStyle
    @Environment(\.deviceEnvironment) private var deviceEnvironment
    
    func body(content: Content) -> some View {
        content
            .font(font(for: style))
    }
    
    @MainActor
    private func font(for style: DeviceTextStyle) -> Font {
        let deviceType = deviceEnvironment.deviceType
        switch (style, deviceType) {
        case (.title, .iPhone):
            return .title2
        case (.title, .iPad):
            return .largeTitle
        case (.title, .macCatalyst), (.title, .mac):
            return .title
            
        case (.headline, .iPhone):
            return .headline
        case (.headline, .iPad):
            return .title3
        case (.headline, .macCatalyst), (.headline, .mac):
            return .title2
            
        case (.body, .iPhone):
            return .body
        case (.body, .iPad):
            return .title3
        case (.body, .macCatalyst), (.body, .mac):
            return .title3
            
        case (.caption, _):
            return .caption
        }
    }
}

// MARK: - Adaptive Spacing

struct DeviceAdaptiveSpacing {
    @Environment(\.deviceEnvironment) private var deviceEnvironment
    
    @MainActor
    var small: CGFloat {
        switch deviceEnvironment.deviceType {
        case .iPhone: return 8
        case .iPad: return 12
        case .macCatalyst, .mac: return 10
        }
    }
    
    @MainActor
    var medium: CGFloat {
        switch deviceEnvironment.deviceType {
        case .iPhone: return 16
        case .iPad: return 24
        case .macCatalyst, .mac: return 20
        }
    }
    
    @MainActor
    var large: CGFloat {
        switch deviceEnvironment.deviceType {
        case .iPhone: return 24
        case .iPad: return 32
        case .macCatalyst, .mac: return 28
        }
    }
}

// MARK: - Safe Area Helpers

extension View {
    /// Apply device-appropriate safe area handling
    func deviceSafeArea() -> some View {
        self.modifier(DeviceSafeAreaModifier())
    }
}

struct DeviceSafeAreaModifier: ViewModifier {
    @Environment(\.deviceEnvironment) private var deviceEnvironment
    
    @MainActor
    func body(content: Content) -> some View {
        switch deviceEnvironment.deviceType {
        case .iPhone:
            // iPhone: Respect all safe areas
            content
                .padding(.horizontal)
                
        case .iPad:
            // iPad: Add readable content guides
            content
                .padding(.horizontal, 20)
                
        case .macCatalyst, .mac:
            // Mac: Window-appropriate margins
            content
                .padding(.horizontal, 16)
        }
    }
}
