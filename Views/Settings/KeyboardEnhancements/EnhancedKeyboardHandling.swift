//
//  EnhancedKeyboardHandling.swift
//  LED MESSENGER
//
//  Enhanced keyboard handling for immediate response and easy dismissal
//  Created: January 2025
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Keyboard Responsive View Modifier
struct KeyboardResponsive: ViewModifier {
    @State private var keyboardHeight: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .padding(.bottom, keyboardHeight)
            .animation(.easeOut(duration: 0.25), value: keyboardHeight)
            .onAppear {
                NotificationCenter.default.addObserver(
                    forName: UIResponder.keyboardWillShowNotification,
                    object: nil,
                    queue: .main
                ) { notification in
                    if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                        keyboardHeight = keyboardFrame.height
                    }
                }
                
                NotificationCenter.default.addObserver(
                    forName: UIResponder.keyboardWillHideNotification,
                    object: nil,
                    queue: .main
                ) { _ in
                    keyboardHeight = 0
                }
            }
    }
}

// MARK: - Tap To Dismiss Keyboard Modifier
struct TapToDismissKeyboard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onTapGesture {
                #if canImport(UIKit)
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                #endif
            }
    }
}

// MARK: - Enhanced Text Field with Immediate Response
struct EnhancedTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let icon: String
    var keyboardType: UIKeyboardType = .default
    var submitLabel: SubmitLabel = .done
    var onSubmit: (() -> Void)? = nil
    
    @FocusState private var isFocused: Bool
    @State private var showClearButton = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title with icon
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(.primary)
            
            // Text field container
            HStack(spacing: 12) {
                TextField(placeholder, text: $text)
                    .focused($isFocused)
                    .textFieldStyle(.plain)
                    .font(.body)
                    .keyboardType(keyboardType)
                    .submitLabel(submitLabel)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .onSubmit {
                        onSubmit?()
                        isFocused = false
                    }
                    // Ensure immediate response
                    .onTapGesture {
                        isFocused = true
                    }
                
                // Clear button
                if !text.isEmpty && isFocused {
                    Button(action: {
                        text = ""
                        // Keep focus after clearing
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isFocused = true
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .imageScale(.medium)
                    }
                    .buttonStyle(.plain)
                    .transition(.scale.combined(with: .opacity))
                }
                
                // Done button (always visible when focused)
                if isFocused {
                    Button("Done") {
                        isFocused = false
                        onSubmit?()
                    }
                    .font(.subheadline.bold())
                    .foregroundStyle(.purple)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Material.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isFocused ? .purple : .clear, lineWidth: 2)
            )
            .animation(.smooth(duration: 0.2), value: isFocused)
            .animation(.smooth(duration: 0.2), value: !text.isEmpty)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if !isFocused {
                isFocused = true
            }
        }
    }
}

// MARK: - Keyboard Toolbar Modifier
struct KeyboardToolbar: ViewModifier {
    let onDone: () -> Void
    
    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    
                    Button("Done") {
                        onDone()
                        #if canImport(UIKit)
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        #endif
                    }
                    .font(.body.bold())
                    .foregroundColor(.purple)
                }
            }
    }
}

// MARK: - Floating Keyboard Dismiss Button
struct FloatingKeyboardDismissButton: View {
    @Binding var isVisible: Bool
    let onDismiss: () -> Void
    
    var body: some View {
        if isVisible {
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    
                    Button(action: onDismiss) {
                        HStack(spacing: 8) {
                            Image(systemName: "keyboard.chevron.compact.down")
                            Text("Hide")
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.purple)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                    .transition(.scale.combined(with: .opacity))
                    .animation(.bouncy, value: isVisible)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 10)
            }
        }
    }
}

// MARK: - Enhanced Modern Text Field (Drop-in Replacement)
struct ImprovedModernTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let icon: String
    var keyboardType: UIKeyboardType = .default
    
    // Support both internal and external focus management
    @FocusState private var internalFocus: Bool
    var externalFocus: FocusState<AnyHashable?>.Binding? = nil
    var focusValue: AnyHashable? = nil
    
    @State private var showClearButton = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(.primary)
            
            HStack(spacing: 12) {
                Group {
                    if let externalFocus = externalFocus, let focusValue = focusValue {
                        TextField(placeholder, text: $text)
                            .focused(externalFocus, equals: focusValue)
                            .textFieldStyle(.plain)
                            .font(.body)
                            .keyboardType(keyboardType)
                            .submitLabel(.done)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                            .onSubmit {
                                externalFocus.wrappedValue = nil
                            }
                            // Ensure immediate tap response
                            .simultaneousGesture(
                                TapGesture().onEnded {
                                    externalFocus.wrappedValue = focusValue
                                }
                            )
                    } else {
                        TextField(placeholder, text: $text)
                            .focused($internalFocus)
                            .textFieldStyle(.plain)
                            .font(.body)
                            .keyboardType(keyboardType)
                            .submitLabel(.done)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                            .onSubmit {
                                internalFocus = false
                            }
                            // Ensure immediate tap response
                            .simultaneousGesture(
                                TapGesture().onEnded {
                                    internalFocus = true
                                }
                            )
                    }
                }
                
                // Clear button
                if !text.isEmpty && (internalFocus || (externalFocus?.wrappedValue == focusValue)) {
                    Button(action: {
                        withAnimation(.smooth(duration: 0.15)) {
                            text = ""
                        }
                        // Maintain focus
                        if let externalFocus = externalFocus, let focusValue = focusValue {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                externalFocus.wrappedValue = focusValue
                            }
                        } else {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                internalFocus = true
                            }
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .imageScale(.medium)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .transition(.scale.combined(with: .opacity))
                }
                
                // Inline done button
                if internalFocus || (externalFocus?.wrappedValue == focusValue) {
                    Button("Done") {
                        withAnimation(.smooth(duration: 0.2)) {
                            if let externalFocus = externalFocus {
                                externalFocus.wrappedValue = nil
                            } else {
                                internalFocus = false
                            }
                        }
                        #if canImport(UIKit)
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        #endif
                    }
                    .font(.subheadline.bold())
                    .foregroundStyle(.purple)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Material.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        (internalFocus || (externalFocus?.wrappedValue == focusValue)) ? .purple : .clear,
                        lineWidth: 2
                    )
            )
            .animation(.smooth(duration: 0.2), value: internalFocus)
            .animation(.smooth(duration: 0.2), value: externalFocus?.wrappedValue == focusValue)
            .animation(.smooth(duration: 0.2), value: !text.isEmpty)
        }
        // Make entire component tappable
        .contentShape(Rectangle())
        .onTapGesture {
            if let externalFocus = externalFocus, let focusValue = focusValue {
                if externalFocus.wrappedValue != focusValue {
                    externalFocus.wrappedValue = focusValue
                }
            } else if !internalFocus {
                internalFocus = true
            }
        }
    }
}

// MARK: - View Extensions
extension View {
    func keyboardResponsive() -> some View {
        modifier(KeyboardResponsive())
    }
    
    func tapToDismissKeyboard() -> some View {
        modifier(TapToDismissKeyboard())
    }
    
    func keyboardToolbar(onDone: @escaping () -> Void) -> some View {
        modifier(KeyboardToolbar(onDone: onDone))
    }
    
    // Enhanced dismiss keyboard with completion
    func dismissKeyboard() {
        #if canImport(UIKit)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
    }
}

// MARK: - Keyboard Height Observer
class KeyboardHeightObserver: ObservableObject {
    @Published var height: CGFloat = 0
    @Published var isVisible: Bool = false
    
    init() {
        #if canImport(UIKit)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
        #endif
    }
    
    @objc private func keyboardWillShow(notification: Notification) {
        #if canImport(UIKit)
        if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            height = keyboardFrame.height
            isVisible = true
        }
        #endif
    }
    
    @objc private func keyboardWillHide(notification: Notification) {
        height = 0
        isVisible = false
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Usage Example
struct KeyboardHandlingExample: View {
    @State private var text1 = ""
    @State private var text2 = ""
    @State private var text3 = ""
    @FocusState private var focusedField: Field?
    @StateObject private var keyboard = KeyboardHeightObserver()
    
    enum Field: Hashable {
        case field1, field2, field3
    }
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 20) {
                    ImprovedModernTextField(
                        title: "Host Address",
                        text: $text1,
                        placeholder: "192.168.1.100",
                        icon: "globe",
                        keyboardType: .numbersAndPunctuation,
                        externalFocus: $focusedField,
                        focusValue: Field.field1
                    )
                    
                    ImprovedModernTextField(
                        title: "Port",
                        text: $text2,
                        placeholder: "2269",
                        icon: "number",
                        keyboardType: .numberPad,
                        externalFocus: $focusedField,
                        focusValue: Field.field2
                    )
                    
                    ImprovedModernTextField(
                        title: "Custom Label",
                        text: $text3,
                        placeholder: "Enter label",
                        icon: "tag",
                        externalFocus: $focusedField,
                        focusValue: Field.field3
                    )
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)
            .tapToDismissKeyboard()
            
            // Floating dismiss button
            FloatingKeyboardDismissButton(
                isVisible: $keyboard.isVisible,
                onDismiss: {
                    focusedField = nil
                }
            )
        }
        .keyboardToolbar {
            focusedField = nil
        }
    }
}