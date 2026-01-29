//
//  ClipboardServiceTests.swift
//  macSCPTests
//
//  Unit tests for ClipboardService
//

import XCTest
@testable import macSCP

@MainActor
final class ClipboardServiceTests: XCTestCase {
    var sut: ClipboardService!
    let testConnectionId = UUID()

    override func setUp() async throws {
        try await super.setUp()
        sut = ClipboardService.shared
        sut.clear()
    }

    override func tearDown() async throws {
        sut.clear()
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Copy Tests

    func testCopy_SingleFile() {
        // Given
        let file = RemoteFile(name: "test.txt", path: "/test.txt", isDirectory: false, size: 100, permissions: "-rw-r--r--")

        // When
        sut.copy(files: [file], from: "/", connectionId: testConnectionId)

        // Then
        XCTAssertTrue(sut.isCopy)
        XCTAssertFalse(sut.isCut)
        XCTAssertEqual(sut.fileCount, 1)
        XCTAssertEqual(sut.items.first?.file.name, "test.txt")
    }

    func testCopy_MultipleFiles() {
        // Given
        let files = [
            RemoteFile(name: "file1.txt", path: "/file1.txt", isDirectory: false, size: 100, permissions: "-rw-r--r--"),
            RemoteFile(name: "file2.txt", path: "/file2.txt", isDirectory: false, size: 100, permissions: "-rw-r--r--")
        ]

        // When
        sut.copy(files: files, from: "/", connectionId: testConnectionId)

        // Then
        XCTAssertEqual(sut.fileCount, 2)
    }

    // MARK: - Cut Tests

    func testCut_SingleFile() {
        // Given
        let file = RemoteFile(name: "test.txt", path: "/test.txt", isDirectory: false, size: 100, permissions: "-rw-r--r--")

        // When
        sut.cut(files: [file], from: "/", connectionId: testConnectionId)

        // Then
        XCTAssertTrue(sut.isCut)
        XCTAssertFalse(sut.isCopy)
        XCTAssertEqual(sut.fileCount, 1)
    }

    // MARK: - Clear Tests

    func testClear() {
        // Given
        let file = RemoteFile(name: "test.txt", path: "/test.txt", isDirectory: false, size: 100, permissions: "-rw-r--r--")
        sut.copy(files: [file], from: "/", connectionId: testConnectionId)

        // When
        sut.clear()

        // Then
        XCTAssertTrue(sut.isEmpty)
        XCTAssertEqual(sut.fileCount, 0)
    }

    // MARK: - Display Text Tests

    func testDisplayText_Empty() {
        XCTAssertEqual(sut.displayText, "Clipboard empty")
    }

    func testDisplayText_SingleCopiedFile() {
        // Given
        let file = RemoteFile(name: "test.txt", path: "/test.txt", isDirectory: false, size: 100, permissions: "-rw-r--r--")

        // When
        sut.copy(files: [file], from: "/", connectionId: testConnectionId)

        // Then
        XCTAssertEqual(sut.displayText, "Copied: test.txt")
    }

    func testDisplayText_MultipleCutFiles() {
        // Given
        let files = [
            RemoteFile(name: "file1.txt", path: "/file1.txt", isDirectory: false, size: 100, permissions: "-rw-r--r--"),
            RemoteFile(name: "file2.txt", path: "/file2.txt", isDirectory: false, size: 100, permissions: "-rw-r--r--")
        ]

        // When
        sut.cut(files: files, from: "/", connectionId: testConnectionId)

        // Then
        XCTAssertEqual(sut.displayText, "Cut: 2 items")
    }

    // MARK: - Can Paste Tests

    func testCanPaste_SameConnection() {
        // Given
        let file = RemoteFile(name: "test.txt", path: "/test.txt", isDirectory: false, size: 100, permissions: "-rw-r--r--")
        sut.copy(files: [file], from: "/", connectionId: testConnectionId)

        // Then
        XCTAssertTrue(sut.canPaste(to: testConnectionId))
    }

    func testCanPaste_DifferentConnection() {
        // Given
        let file = RemoteFile(name: "test.txt", path: "/test.txt", isDirectory: false, size: 100, permissions: "-rw-r--r--")
        sut.copy(files: [file], from: "/", connectionId: testConnectionId)
        let differentConnectionId = UUID()

        // Then
        XCTAssertFalse(sut.canPaste(to: differentConnectionId))
    }

    func testCanPaste_EmptyClipboard() {
        XCTAssertFalse(sut.canPaste(to: testConnectionId))
    }

    // MARK: - Connection ID Tests

    func testConnectionIds() {
        // Given
        let file = RemoteFile(name: "test.txt", path: "/test.txt", isDirectory: false, size: 100, permissions: "-rw-r--r--")

        // When
        sut.copy(files: [file], from: "/", connectionId: testConnectionId)

        // Then
        XCTAssertEqual(sut.connectionId, testConnectionId)
    }
}
