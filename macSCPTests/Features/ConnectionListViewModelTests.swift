//
//  ConnectionListViewModelTests.swift
//  macSCPTests
//
//  Unit tests for ConnectionListViewModel
//

import XCTest
@testable import macSCP

@MainActor
final class ConnectionListViewModelTests: XCTestCase {
    var sut: ConnectionListViewModel!
    var mockConnectionRepository: MockConnectionRepository!
    var mockFolderRepository: MockFolderRepository!
    var mockKeychainService: MockKeychainService!
    var mockWindowManager: WindowManager!

    override func setUp() async throws {
        try await super.setUp()
        mockConnectionRepository = MockConnectionRepository()
        mockFolderRepository = MockFolderRepository()
        mockKeychainService = MockKeychainService()
        mockWindowManager = WindowManager.shared

        sut = ConnectionListViewModel(
            connectionRepository: mockConnectionRepository,
            folderRepository: mockFolderRepository,
            keychainService: mockKeychainService,
            windowManager: mockWindowManager
        )
    }

    override func tearDown() async throws {
        sut = nil
        mockConnectionRepository = nil
        mockFolderRepository = nil
        mockKeychainService = nil
        mockWindowManager = nil
        try await super.tearDown()
    }

    // MARK: - Load Data Tests

    func testLoadData_Success() async {
        // Given
        let connection = Connection(name: "Test", host: "test.com", username: "user")
        let folder = Folder(name: "Test Folder")
        mockConnectionRepository.mockConnections = [connection]
        mockFolderRepository.mockFolders = [folder]

        // When
        await sut.loadData()

        // Then
        XCTAssertEqual(sut.connections.count, 1)
        XCTAssertEqual(sut.folders.count, 1)
        XCTAssertTrue(mockConnectionRepository.fetchAllCalled)
        XCTAssertTrue(mockFolderRepository.fetchAllCalled)
        XCTAssertTrue(sut.state.isSuccess)
    }

    func testLoadData_Error() async {
        // Given
        mockConnectionRepository.mockError = AppError.fetchFailed("test")

        // When
        await sut.loadData()

        // Then
        XCTAssertTrue(sut.state.isError)
    }

    // MARK: - Connection Tests

    func testSaveConnection_Success() async {
        // Given
        let connection = Connection(name: "Test", host: "test.com", username: "user", savePassword: true)

        // When
        await sut.saveConnection(connection, password: "secret")

        // Then
        XCTAssertTrue(mockConnectionRepository.saveCalled)
        XCTAssertTrue(mockKeychainService.savePasswordCalled)
        XCTAssertEqual(mockKeychainService.lastSavedPassword, "secret")
    }

    func testDeleteConnection_Success() async {
        // Given
        let connection = Connection(name: "Test", host: "test.com", username: "user")
        mockConnectionRepository.mockConnections = [connection]

        // When
        await sut.deleteConnection(connection)

        // Then
        XCTAssertTrue(mockConnectionRepository.deleteCalled)
        XCTAssertEqual(mockConnectionRepository.lastDeletedId, connection.id)
    }

    // MARK: - Folder Tests

    func testCreateFolder_Success() async {
        // Given
        let folderName = "New Folder"

        // When
        await sut.createFolder(name: folderName)

        // Then
        XCTAssertTrue(mockFolderRepository.saveCalled)
        XCTAssertEqual(mockFolderRepository.lastSavedFolder?.name, folderName)
    }

    func testDeleteFolder_Success() async {
        // Given
        let folder = Folder(name: "Test Folder")
        mockFolderRepository.mockFolders = [folder]
        sut.selectedSidebarItem = .folder(folder.id)

        // When
        await sut.deleteFolder(folder)

        // Then
        XCTAssertTrue(mockFolderRepository.deleteCalled)
        XCTAssertEqual(mockFolderRepository.lastDeletedId, folder.id)
        XCTAssertEqual(sut.selectedSidebarItem, .allConnections)
    }

    // MARK: - Filter Tests

    func testFilteredConnections_SearchText() async {
        // Given
        let connection1 = Connection(name: "Production", host: "prod.com", username: "admin")
        let connection2 = Connection(name: "Development", host: "dev.com", username: "dev")
        mockConnectionRepository.mockConnections = [connection1, connection2]
        await sut.loadData()

        // When
        sut.searchText = "prod"

        // Then
        XCTAssertEqual(sut.filteredConnections.count, 1)
        XCTAssertEqual(sut.filteredConnections.first?.name, "Production")
    }

    func testFilteredConnections_ByFolder() async {
        // Given
        let folder = Folder(name: "Test Folder")
        let connection1 = Connection(name: "In Folder", host: "test.com", username: "user", folderId: folder.id)
        let connection2 = Connection(name: "No Folder", host: "test.com", username: "user")
        mockConnectionRepository.mockConnections = [connection1, connection2]
        mockFolderRepository.mockFolders = [folder]
        await sut.loadData()

        // When
        sut.selectedSidebarItem = .folder(folder.id)

        // Then
        XCTAssertEqual(sut.filteredConnections.count, 1)
        XCTAssertEqual(sut.filteredConnections.first?.name, "In Folder")
    }

    // MARK: - Connection Count Tests

    func testConnectionCount_ForFolder() async {
        // Given
        let folder = Folder(name: "Test Folder")
        let connection1 = Connection(name: "Test 1", host: "test.com", username: "user", folderId: folder.id)
        let connection2 = Connection(name: "Test 2", host: "test.com", username: "user", folderId: folder.id)
        let connection3 = Connection(name: "Test 3", host: "test.com", username: "user")
        mockConnectionRepository.mockConnections = [connection1, connection2, connection3]
        mockFolderRepository.mockFolders = [folder]
        await sut.loadData()

        // Then
        XCTAssertEqual(sut.connectionCount(for: folder.id), 2)
        XCTAssertEqual(sut.totalConnectionCount, 3)
    }
}
