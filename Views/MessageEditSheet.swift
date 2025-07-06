//
//  MessageEditSheet.swift
//  LED MESSENGER
//
//  Shared component for editing messages
//

import SwiftUI

struct MessageEditSheet: View {
    @Binding var message: Message?
    @Binding var showEditModal: Bool
    @Environment(AppSettings.self) private var appSettings
    @Environment(QueueViewModel.self) var queueVM
    @AppStorage("launchMode") private var launchMode: String = ""
    
    @State private var editedText: String = ""
    @State private var editedTableNumber: String = ""
    
    private var isDualMode: Bool {
        launchMode.starts(with: "dual")
    }
    
    var body: some View {
        if let msg = message {
            NavigationStack {
                VStack(spacing: 24) {
                    Text("EDIT MESSAGE")
                        .font(.title2.weight(.bold))
                        .foregroundColor(.white)
                    
                    // Editing form
                    VStack(alignment: .leading, spacing: 12) {
                        if let label = msg.label {
                            Text(label.type.rawValue.uppercased())
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                            
                            TextField("Enter \(label.type.rawValue.lowercased())", text: $editedTableNumber)
                                .padding()
                                .background(Color.black.opacity(0.2))
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.purple, lineWidth: 1))
                                .foregroundColor(Color.white)
                                .onAppear {
                                    editedTableNumber = label.text
                                }
                        }
                        
                        Text("MESSAGE")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                        
                        TextField("Enter message", text: $editedText)
                            .padding()
                            .background(Color.black.opacity(0.2))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.purple, lineWidth: 1))
                            .foregroundColor(Color.white)
                            .onAppear {
                                editedText = appSettings.forceCaps ? msg.content.uppercased() : msg.content
                            }
                    }
                    
                    // Buttons
                    HStack(spacing: 16) {
                        Button("CANCEL") {
                            message = nil
                            showEditModal = false
                        }
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(colors: [Color.pink, Color.purple], startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(12)
                        .foregroundColor(.white)
                        
                        Button("SAVE CHANGES") {
                            saveChanges(for: msg)
                        }
                        .disabled(editedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(colors: [Color.purple, Color.blue], startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(12)
                        .foregroundColor(.white)
                    }
                }
                .padding()
                .frame(maxWidth: 500)
                .background(Color(red: 0.08, green: 0.02, blue: 0.15))
                .cornerRadius(24)
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.ignoresSafeArea())
            }
        }
    }
    
    private func saveChanges(for msg: Message) {
        let label: Message.Label? = msg.label != nil ? 
            .init(type: msg.label!.type, text: editedTableNumber) : nil
        
        let finalText = appSettings.forceCaps ? editedText.uppercased() : editedText
        
        let updatedMessage = Message(
            id: msg.id,
            content: finalText,
            timestamp: msg.timestamp,
            status: msg.status,
            priority: msg.priority,
            label: label
        )
        
        // Update the message in the queue (solo mode only for now)
        if !isDualMode {
            queueVM.updateMessage(updatedMessage)
            
            // If the message was already sent, resend it to update the LED wall
            if msg.status == .sent || msg.status == .delivered {
                queueVM.sendMessage(updatedMessage)
            }
        }
        
        // Close the modal
        message = nil
        showEditModal = false
    }
}