//
//  MessageListView.swift
//  LED MESSENGER
//
//  Shared component for displaying message list
//

import SwiftUI

struct MessageListView: View {
    let messages: [Message]
    let onDelete: (Int, Message) -> Void
    let onSend: (Message) -> Void
    let onEdit: (Message) -> Void
    
    @Environment(QueueViewModel.self) var queueVM
    @Environment(AppSettings.self) var appSettings
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                ForEach(messages) { message in
                    messageRowView(for: message)
                }
            }
        }
        .scrollIndicators(.hidden)
    }
    
    @ViewBuilder
    private func messageRowView(for message: Message) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            let tableNumber = formatTableNumber(for: message)
            let isSent = message.status == .sent || message.status == .delivered
            
            MessageRow(
                tableNumber: tableNumber,
                message: message.content,
                startingSlot: appSettings.startSlot,
                clipCount: appSettings.clipCount,
                onDelete: { clearSlotIndex in
                    onDelete(clearSlotIndex, message)
                },
                onSend: {
                    onSend(message)
                },
                onEdit: {
                    onEdit(message)
                },
                isSent: isSent,
                isSending: queueVM.isSending
            )
        }
    }
    
    private func formatTableNumber(for message: Message) -> String {
        guard let label = message.label else { return "—" }
        
        switch label.type {
        case .tableNumber:
            return "TABLE \(label.text)"
        case .customLabel:
            return label.text.uppercased()
        case .noLabel:
            return "—"
        }
    }
}