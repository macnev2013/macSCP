//
//  FileEditorViewModelTests.swift
//  macSCPTests
//
//  Unit tests for FileEditorViewModel
//

import XCTest
@testable import macSCP

@MainActor
final class FileEditorViewModelTests: XCTestCase {
    var sut: FileEditorViewModel!
    var mockFileRepository: MockFileRepository!

    let testContent = "Hello, World!\nThis is a test file.\nLine 3."

    override func setUp() async throws {
        try await super.setUp()
        mockFileRepository = MockFileRepository()

        sut = FileEditorViewModel(
            filePath: "/test/file.txt",
            fileName: "file.txt",
            initialContent: testContent,
            fileRepository: mockFileRepository
        )
    }

    override func tearDown() async throws {
        sut = nil
        mockFileRepository = nil
        try await super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState() {
        XCTAssertEqual(sut.content, testContent)
        XCTAssertEqual(sut.filePath, "/test/file.txt")
        XCTAssertEqual(sut.fileName, "file.txt")
        XCTAssertFalse(sut.hasChanges)
    }

    // MARK: - Content Statistics Tests

    func testLineCount() {
        XCTAssertEqual(sut.lineCount, 3)
    }

    func testWordCount() {
        // "Hello, World! This is a test file. Line 3." = 9 words
        XCTAssertEqual(sut.wordCount, 9)
    }

    func testCharacterCount() {
        XCTAssertEqual(sut.characterCount, testContent.count)
    }

    // MARK: - Change Detection Tests

    func testHasChanges_WhenContentModified() {
        // When
        sut.content = "Modified content"

        // Then
        XCTAssertTrue(sut.hasChanges)
    }

    func testHasChanges_WhenContentReverted() {
        // Given
        sut.content = "Modified content"

        // When
        sut.revertChanges()

        // Then
        XCTAssertFalse(sut.hasChanges)
        XCTAssertEqual(sut.content, testContent)
    }

    // MARK: - Save Tests

    func testSave_Success() async {
        // Given
        sut.content = "New content"

        // When
        await sut.save()

        // Then
        XCTAssertTrue(mockFileRepository.writeFileContentCalled)
        XCTAssertEqual(mockFileRepository.lastWriteContent, "New content")
        XCTAssertEqual(mockFileRepository.lastWritePath, "/test/file.txt")
    }

    func testSave_Error() async {
        // Given
        mockFileRepository.mockError = AppError.fileWriteFailed

        // When
        await sut.save()

        // Then
        XCTAssertNotNil(sut.error)
    }

    // MARK: - Reload Tests

    func testReload_Success() async {
        // Given
        mockFileRepository.mockFileContent = "Reloaded content"

        // When
        await sut.reload()

        // Then
        XCTAssertTrue(mockFileRepository.readFileContentCalled)
        XCTAssertEqual(sut.content, "Reloaded content")
    }

    // MARK: - Search Tests

    func testSearch_FindsMatches() {
        // When
        sut.searchText = "test"
        sut.search()

        // Then
        XCTAssertEqual(sut.searchResults.count, 1)
    }

    func testSearch_CaseSensitive() {
        // Given
        sut.isCaseSensitive = true

        // When
        sut.searchText = "Test"
        sut.search()

        // Then
        XCTAssertEqual(sut.searchResults.count, 0)
    }

    func testSearch_CaseInsensitive() {
        // Given
        sut.isCaseSensitive = false

        // When
        sut.searchText = "HELLO"
        sut.search()

        // Then
        XCTAssertEqual(sut.searchResults.count, 1)
    }

    func testSearch_EmptyText() {
        // When
        sut.searchText = ""
        sut.search()

        // Then
        XCTAssertTrue(sut.searchResults.isEmpty)
    }

    func testSearchStatusText_NoResults() {
        // When
        sut.searchText = "notfound"
        sut.search()

        // Then
        XCTAssertEqual(sut.searchStatusText, "No results")
    }

    func testSearchStatusText_WithResults() {
        // When
        sut.searchText = "test"
        sut.search()

        // Then
        XCTAssertEqual(sut.searchStatusText, "1 of 1")
    }

    // MARK: - Navigation Tests

    func testFindNext() {
        // Given - use content with multiple occurrences
        sut.content = "test test test"
        sut.searchText = "test"
        sut.search()
        XCTAssertEqual(sut.searchResults.count, 3)
        XCTAssertEqual(sut.currentSearchIndex, 0)

        // When
        sut.findNext()

        // Then
        XCTAssertEqual(sut.currentSearchIndex, 1)
    }

    func testFindPrevious() {
        // Given - use content with multiple occurrences
        sut.content = "test test test"
        sut.searchText = "test"
        sut.search()
        sut.findNext() // Move to index 1

        // When
        sut.findPrevious()

        // Then
        XCTAssertEqual(sut.currentSearchIndex, 0)
    }

    // MARK: - Replace Tests

    func testReplaceCurrent() {
        // Given
        sut.searchText = "World"
        sut.replaceText = "Universe"
        sut.search()

        // When
        sut.replaceCurrent()

        // Then
        XCTAssertTrue(sut.content.contains("Universe"))
        XCTAssertFalse(sut.content.contains("World"))
    }

    func testReplaceAll() {
        // Given - use content with multiple occurrences
        sut.content = "hello hello hello"
        sut.searchText = "hello"
        sut.replaceText = "hi"
        sut.search()

        // When
        sut.replaceAll()

        // Then
        XCTAssertEqual(sut.content, "hi hi hi")
    }

    // MARK: - Toggle Search Tests

    func testToggleSearch_ShowsSearch() {
        // When
        sut.toggleSearch()

        // Then
        XCTAssertTrue(sut.isShowingSearch)
    }

    func testToggleSearch_HidesAndClearsSearch() {
        // Given
        sut.isShowingSearch = true
        sut.searchText = "test"
        sut.search()

        // When
        sut.toggleSearch()

        // Then
        XCTAssertFalse(sut.isShowingSearch)
        XCTAssertTrue(sut.searchText.isEmpty)
        XCTAssertTrue(sut.searchResults.isEmpty)
    }
}
