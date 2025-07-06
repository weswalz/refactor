//
//  DashBoardViewModel.swift
//  LEDMessenger
//
//  Created by Wesley Walz on 5/12/25.
//

import Foundation
import Observation

@MainActor
@Observable
final class DashboardViewModel {
    var showNewMessageModal: Bool = false
    var selectedMessageID: UUID?

    func openModal() {
        showNewMessageModal = true
    }

    func closeModal() {
        showNewMessageModal = false
    }

    func selectMessage(_ id: UUID) {
        selectedMessageID = id
    }

    func deselectMessage() {
        selectedMessageID = nil
    }
}
