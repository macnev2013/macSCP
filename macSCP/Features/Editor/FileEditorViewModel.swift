//
//  FileEditorViewModel.swift
//  macSCP
//
//  ViewModel for the file editor feature
//

import Foundation
import SwiftUI

@MainActor
@Observable
final class FileEditorViewModel {
    // MARK: - State
    private(set) var state: ViewState<Void> = .idle
    var error: AppError?

    var content: String
    private var savedContent: String

    let filePath: String
    let fileName: String

    // Search/Replace state
    var isShowingSearch = false
    var searchText: String = ""
    var replaceText: String = ""
    var searchResults: [Range<String.Index>] = []
    var currentSearchIndex: Int = 0
    var isCaseSensitive: Bool = false
    var isWholeWord: Bool = false

    // MARK: - Dependencies
    private let fileRepository: FileRepositoryProtocol

    // MARK: - Initialization
    init(
        filePath: String,
        fileName: String,
        initialContent: String,
        fileRepository: FileRepositoryProtocol
    ) {
        self.filePath = filePath
        self.fileName = fileName
        self.content = initialContent
        self.savedContent = initialContent
        self.fileRepository = fileRepository
    }

    // MARK: - Computed Properties

    var hasChanges: Bool {
        content != savedContent
    }

    var lineCount: Int {
        content.components(separatedBy: .newlines).count
    }

    var characterCount: Int {
        content.count
    }

    var wordCount: Int {
        content.split { $0.isWhitespace || $0.isNewline }.count
    }

    var currentSearchResult: Range<String.Index>? {
        guard !searchResults.isEmpty, currentSearchIndex < searchResults.count else { return nil }
        return searchResults[currentSearchIndex]
    }

    var searchStatusText: String {
        if searchText.isEmpty {
            return ""
        }
        if searchResults.isEmpty {
            return "No results"
        }
        return "\(currentSearchIndex + 1) of \(searchResults.count)"
    }

    // MARK: - File Operations

    func save() async {
        state = .loading

        do {
            try await fileRepository.writeFileContent(content, to: filePath)
            savedContent = content
            state = .success(())
            logInfo("File saved: \(fileName)", category: .sftp)
        } catch {
            logError("Failed to save file: \(error)", category: .sftp)
            state = .error(AppError.from(error))
            self.error = AppError.from(error)
        }
    }

    func reload() async {
        state = .loading

        do {
            content = try await fileRepository.readFileContent(at: filePath)
            savedContent = content
            state = .success(())
            logInfo("File reloaded: \(fileName)", category: .sftp)
        } catch {
            logError("Failed to reload file: \(error)", category: .sftp)
            state = .error(AppError.from(error))
            self.error = AppError.from(error)
        }
    }

    func revertChanges() {
        content = savedContent
        logInfo("Changes reverted for: \(fileName)", category: .ui)
    }

    // MARK: - Search Operations

    func search() {
        guard !searchText.isEmpty else {
            searchResults = []
            currentSearchIndex = 0
            return
        }

        var options: String.CompareOptions = []
        if !isCaseSensitive {
            options.insert(.caseInsensitive)
        }

        var results: [Range<String.Index>] = []
        var searchRange = content.startIndex..<content.endIndex

        while let range = content.range(of: searchText, options: options, range: searchRange) {
            // Check whole word if enabled
            if isWholeWord {
                let isWordBoundaryBefore = range.lowerBound == content.startIndex ||
                    !content[content.index(before: range.lowerBound)].isLetter
                let isWordBoundaryAfter = range.upperBound == content.endIndex ||
                    !content[range.upperBound].isLetter

                if isWordBoundaryBefore && isWordBoundaryAfter {
                    results.append(range)
                }
            } else {
                results.append(range)
            }

            searchRange = range.upperBound..<content.endIndex
        }

        searchResults = results
        currentSearchIndex = results.isEmpty ? 0 : 0
    }

    func findNext() {
        guard !searchResults.isEmpty else { return }
        currentSearchIndex = (currentSearchIndex + 1) % searchResults.count
    }

    func findPrevious() {
        guard !searchResults.isEmpty else { return }
        currentSearchIndex = (currentSearchIndex - 1 + searchResults.count) % searchResults.count
    }

    func replaceCurrent() {
        guard let range = currentSearchResult else { return }

        content.replaceSubrange(range, with: replaceText)
        search()
    }

    func replaceAll() {
        guard !searchText.isEmpty else { return }

        var options: String.CompareOptions = []
        if !isCaseSensitive {
            options.insert(.caseInsensitive)
        }

        if isWholeWord {
            // Replace manually with word boundary check
            var newContent = ""
            var currentIndex = content.startIndex

            while currentIndex < content.endIndex {
                if let range = content.range(of: searchText, options: options, range: currentIndex..<content.endIndex) {
                    let isWordBoundaryBefore = range.lowerBound == content.startIndex ||
                        !content[content.index(before: range.lowerBound)].isLetter
                    let isWordBoundaryAfter = range.upperBound == content.endIndex ||
                        !content[range.upperBound].isLetter

                    newContent += content[currentIndex..<range.lowerBound]

                    if isWordBoundaryBefore && isWordBoundaryAfter {
                        newContent += replaceText
                    } else {
                        newContent += content[range]
                    }

                    currentIndex = range.upperBound
                } else {
                    newContent += content[currentIndex..<content.endIndex]
                    break
                }
            }

            content = newContent
        } else {
            content = content.replacingOccurrences(of: searchText, with: replaceText, options: options)
        }

        search()
    }

    func toggleSearch() {
        isShowingSearch.toggle()
        if !isShowingSearch {
            searchText = ""
            replaceText = ""
            searchResults = []
            currentSearchIndex = 0
        }
    }

    // MARK: - UI Actions

    func clearError() {
        error = nil
    }
}
