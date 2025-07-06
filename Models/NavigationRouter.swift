//
//  NavigationRouter.swift
//  LED MESSENGER
//
//  iOS 18 Navigation Router for value-based navigation
//  Created: July 02, 2025
//

import SwiftUI
import Observation

@Observable
@MainActor
final class NavigationRouter {
    var path = NavigationPath()
    
    enum Destination: Hashable {
        case settings
        case messageDetail(Message)
        case profile
        case networkDiagnostics
        case about
    }
    
    func navigate(to destination: Destination) {
        path.append(destination)
    }
    
    func navigateBack() {
        if !path.isEmpty {
            path.removeLast()
        }
    }
    
    func navigateToRoot() {
        path.removeLast(path.count)
    }
}
