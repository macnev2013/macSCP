//
//  ViewState.swift
//  macSCP
//
//  Generic view state for managing loading, success, and error states
//

import Foundation

enum ViewState<T: Sendable>: Sendable {
    case idle
    case loading
    case success(T)
    case error(AppError)

    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    var isIdle: Bool {
        if case .idle = self { return true }
        return false
    }

    var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }

    var isError: Bool {
        if case .error = self { return true }
        return false
    }

    var data: T? {
        if case .success(let data) = self { return data }
        return nil
    }

    var error: AppError? {
        if case .error(let error) = self { return error }
        return nil
    }
}

// MARK: - Equatable conformance when T is Equatable
extension ViewState: Equatable where T: Equatable {
    static func == (lhs: ViewState<T>, rhs: ViewState<T>) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle):
            return true
        case (.loading, .loading):
            return true
        case (.success(let lhsData), .success(let rhsData)):
            return lhsData == rhsData
        case (.error(let lhsError), .error(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}
