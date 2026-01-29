//
//  Logger.swift
//  macSCP
//
//  Centralized logging using OSLog
//

import Foundation
import os.log

enum LogCategory: String {
    case app = "App"
    case sftp = "SFTP"
    case keychain = "Keychain"
    case database = "Database"
    case ui = "UI"
    case network = "Network"
}

enum LogLevel {
    case debug
    case info
    case warning
    case error

    var osLogType: OSLogType {
        switch self {
        case .debug: return .debug
        case .info: return .info
        case .warning: return .default
        case .error: return .error
        }
    }

    var prefix: String {
        switch self {
        case .debug: return "🔍"
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .error: return "❌"
        }
    }
}

final class Logger {
    static let shared = Logger()

    private let subsystem = Bundle.main.bundleIdentifier ?? AppConstants.bundleIdentifier
    private var loggers: [LogCategory: os.Logger] = [:]

    private init() {
        for category in [LogCategory.app, .sftp, .keychain, .database, .ui, .network] {
            loggers[category] = os.Logger(subsystem: subsystem, category: category.rawValue)
        }
    }

    func log(
        _ message: String,
        level: LogLevel = .info,
        category: LogCategory = .app,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let logger = loggers[category] ?? os.Logger(subsystem: subsystem, category: category.rawValue)
        let fileName = (file as NSString).lastPathComponent
        let logMessage = "\(level.prefix) [\(fileName):\(line)] \(function) - \(message)"

        logger.log(level: level.osLogType, "\(logMessage)")

        #if DEBUG
        print(logMessage)
        #endif
    }

    func debug(_ message: String, category: LogCategory = .app, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .debug, category: category, file: file, function: function, line: line)
    }

    func info(_ message: String, category: LogCategory = .app, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .info, category: category, file: file, function: function, line: line)
    }

    func warning(_ message: String, category: LogCategory = .app, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .warning, category: category, file: file, function: function, line: line)
    }

    func error(_ message: String, category: LogCategory = .app, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .error, category: category, file: file, function: function, line: line)
    }
}

// MARK: - Convenience Functions
func logDebug(_ message: String, category: LogCategory = .app, file: String = #file, function: String = #function, line: Int = #line) {
    Logger.shared.debug(message, category: category, file: file, function: function, line: line)
}

func logInfo(_ message: String, category: LogCategory = .app, file: String = #file, function: String = #function, line: Int = #line) {
    Logger.shared.info(message, category: category, file: file, function: function, line: line)
}

func logWarning(_ message: String, category: LogCategory = .app, file: String = #file, function: String = #function, line: Int = #line) {
    Logger.shared.warning(message, category: category, file: file, function: function, line: line)
}

func logError(_ message: String, category: LogCategory = .app, file: String = #file, function: String = #function, line: Int = #line) {
    Logger.shared.error(message, category: category, file: file, function: function, line: line)
}
