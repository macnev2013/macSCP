//
//  NavigationServiceTests.swift
//  macSCPTests
//
//  Unit tests for NavigationService
//

import XCTest
@testable import macSCP

@MainActor
final class NavigationServiceTests: XCTestCase {
    var sut: NavigationService!

    override func setUp() async throws {
        try await super.setUp()
        sut = NavigationService()
    }

    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Navigation Tests

    func testNavigate_AddsToHistory() {
        // When
        sut.navigate(to: "/home")

        // Then
        XCTAssertEqual(sut.currentPath, "/home")
        XCTAssertFalse(sut.canGoBack)
        XCTAssertFalse(sut.canGoForward)
    }

    func testNavigate_MultiplePaths() {
        // When
        sut.navigate(to: "/home")
        sut.navigate(to: "/home/user")
        sut.navigate(to: "/home/user/documents")

        // Then
        XCTAssertEqual(sut.currentPath, "/home/user/documents")
        XCTAssertTrue(sut.canGoBack)
        XCTAssertFalse(sut.canGoForward)
    }

    // MARK: - Go Back Tests

    func testGoBack_Success() {
        // Given
        sut.navigate(to: "/home")
        sut.navigate(to: "/home/user")

        // When
        let result = sut.goBack()

        // Then
        XCTAssertEqual(result, "/home")
        XCTAssertEqual(sut.currentPath, "/home")
        XCTAssertTrue(sut.canGoForward)
    }

    func testGoBack_AtBeginning() {
        // Given
        sut.navigate(to: "/home")

        // When
        let result = sut.goBack()

        // Then
        XCTAssertNil(result)
        XCTAssertEqual(sut.currentPath, "/home")
    }

    // MARK: - Go Forward Tests

    func testGoForward_Success() {
        // Given
        sut.navigate(to: "/home")
        sut.navigate(to: "/home/user")
        _ = sut.goBack()

        // When
        let result = sut.goForward()

        // Then
        XCTAssertEqual(result, "/home/user")
        XCTAssertEqual(sut.currentPath, "/home/user")
        XCTAssertFalse(sut.canGoForward)
    }

    func testGoForward_AtEnd() {
        // Given
        sut.navigate(to: "/home")

        // When
        let result = sut.goForward()

        // Then
        XCTAssertNil(result)
    }

    // MARK: - Forward History Cleared on Navigation

    func testNavigate_ClearsForwardHistory() {
        // Given
        sut.navigate(to: "/home")
        sut.navigate(to: "/home/user")
        sut.navigate(to: "/home/user/documents")
        _ = sut.goBack()
        _ = sut.goBack()
        XCTAssertTrue(sut.canGoForward)

        // When
        sut.navigate(to: "/var")

        // Then
        XCTAssertFalse(sut.canGoForward)
        XCTAssertEqual(sut.currentPath, "/var")
    }

    // MARK: - Reset Tests

    func testReset() {
        // Given
        sut.navigate(to: "/home")
        sut.navigate(to: "/home/user")

        // When
        sut.reset()

        // Then
        XCTAssertNil(sut.currentPath)
        XCTAssertFalse(sut.canGoBack)
        XCTAssertFalse(sut.canGoForward)
    }

    func testReset_ToPath() {
        // Given
        sut.navigate(to: "/home")
        sut.navigate(to: "/home/user")

        // When
        sut.reset(to: "/var")

        // Then
        XCTAssertEqual(sut.currentPath, "/var")
        XCTAssertFalse(sut.canGoBack)
        XCTAssertFalse(sut.canGoForward)
    }

    // MARK: - Back/Forward Path Tests

    func testBackPath() {
        // Given
        sut.navigate(to: "/home")
        sut.navigate(to: "/home/user")

        // Then
        XCTAssertEqual(sut.backPath, "/home")
    }

    func testForwardPath() {
        // Given
        sut.navigate(to: "/home")
        sut.navigate(to: "/home/user")
        _ = sut.goBack()

        // Then
        XCTAssertEqual(sut.forwardPath, "/home/user")
    }
}
