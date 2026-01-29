//
//  MockNavigationService.swift
//  macSCPTests
//
//  Mock implementation of NavigationService for testing
//

import Foundation
@testable import macSCP

@MainActor
final class MockNavigationService {
    // MARK: - State
    private var history: [String] = []
    private var currentIndex: Int = -1

    // MARK: - Recorded Calls
    var navigateCalled = false
    var goBackCalled = false
    var goForwardCalled = false
    var resetCalled = false

    // MARK: - Recorded Parameters
    var lastNavigatedPath: String?
    var lastResetPath: String?

    // MARK: - Methods

    func navigate(to path: String) {
        navigateCalled = true
        lastNavigatedPath = path

        if currentIndex < history.count - 1 {
            history = Array(history[0...currentIndex])
        }
        history.append(path)
        currentIndex = history.count - 1
    }

    func goBack() -> String? {
        goBackCalled = true
        guard canGoBack else { return nil }
        currentIndex -= 1
        return history[currentIndex]
    }

    func goForward() -> String? {
        goForwardCalled = true
        guard canGoForward else { return nil }
        currentIndex += 1
        return history[currentIndex]
    }

    func reset() {
        resetCalled = true
        history = []
        currentIndex = -1
    }

    func reset(to path: String) {
        resetCalled = true
        lastResetPath = path
        history = [path]
        currentIndex = 0
    }

    // MARK: - Computed Properties

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

    // MARK: - Reset Mock State
    func resetMock() {
        history = []
        currentIndex = -1
        navigateCalled = false
        goBackCalled = false
        goForwardCalled = false
        resetCalled = false
        lastNavigatedPath = nil
        lastResetPath = nil
    }
}
