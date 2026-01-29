//
//  NavigationService.swift
//  macSCP
//
//  Service for managing browser navigation history
//

import Foundation

@MainActor
@Observable
final class NavigationService {
    private var history: [String] = []
    private var currentIndex: Int = -1
    private let maxHistorySize = 50

    init() {}

    // MARK: - Navigation

    /// Navigates to a new path and adds it to history
    func navigate(to path: String) {
        // Remove any forward history
        if currentIndex < history.count - 1 {
            history = Array(history[0...currentIndex])
        }

        // Add new path
        history.append(path)

        // Trim history if too large
        if history.count > maxHistorySize {
            history.removeFirst(history.count - maxHistorySize)
        }

        currentIndex = history.count - 1
        logDebug("Navigated to: \(path), history index: \(currentIndex)", category: .ui)
    }

    /// Goes back in history
    func goBack() -> String? {
        guard canGoBack else { return nil }
        currentIndex -= 1
        logDebug("Went back to index: \(currentIndex)", category: .ui)
        return history[currentIndex]
    }

    /// Goes forward in history
    func goForward() -> String? {
        guard canGoForward else { return nil }
        currentIndex += 1
        logDebug("Went forward to index: \(currentIndex)", category: .ui)
        return history[currentIndex]
    }

    // MARK: - State

    var canGoBack: Bool {
        currentIndex > 0
    }

    var canGoForward: Bool {
        currentIndex < history.count - 1
    }

    var currentPath: String? {
        guard currentIndex >= 0 && currentIndex < history.count else { return nil }
        return history[currentIndex]
    }

    var backPath: String? {
        guard canGoBack else { return nil }
        return history[currentIndex - 1]
    }

    var forwardPath: String? {
        guard canGoForward else { return nil }
        return history[currentIndex + 1]
    }

    // MARK: - Reset

    func reset() {
        history = []
        currentIndex = -1
        logDebug("Navigation history reset", category: .ui)
    }

    /// Resets history and navigates to the given path
    func reset(to path: String) {
        history = [path]
        currentIndex = 0
        logDebug("Navigation history reset to: \(path)", category: .ui)
    }
}
