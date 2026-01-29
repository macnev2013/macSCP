//
//  String+Extensions.swift
//  macSCP
//
//  String utility extensions
//

import Foundation

extension String {
    /// Returns the string with leading and trailing whitespace removed
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Returns true if the string is empty or contains only whitespace
    var isBlank: Bool {
        trimmed.isEmpty
    }

    /// Returns the file name component from a path
    var fileName: String {
        (self as NSString).lastPathComponent
    }

    /// Returns the directory path without the file name
    var directoryPath: String {
        (self as NSString).deletingLastPathComponent
    }

    /// Returns the file extension
    var fileExtension: String {
        (self as NSString).pathExtension
    }

    /// Returns the file name without extension
    var fileNameWithoutExtension: String {
        (self as NSString).deletingPathExtension.fileName
    }

    /// Appends a path component
    func appendingPathComponent(_ component: String) -> String {
        (self as NSString).appendingPathComponent(component)
    }

    /// Returns the parent directory path
    var parentPath: String {
        let components = split(separator: "/")
        if components.count <= 1 {
            return "/"
        }
        return "/" + components.dropLast().joined(separator: "/")
    }

    /// Normalizes a path by resolving . and ..
    var normalizedPath: String {
        var components: [String] = []
        for component in split(separator: "/") {
            let part = String(component)
            if part == "." {
                continue
            } else if part == ".." {
                if !components.isEmpty {
                    components.removeLast()
                }
            } else if !part.isEmpty {
                components.append(part)
            }
        }
        return "/" + components.joined(separator: "/")
    }

    /// Returns true if this path is a child of the given parent path
    func isChildOf(_ parentPath: String) -> Bool {
        let normalizedSelf = self.normalizedPath
        let normalizedParent = parentPath.normalizedPath
        return normalizedSelf.hasPrefix(normalizedParent + "/")
    }

    /// Returns relative path from a base path
    func relativePath(from basePath: String) -> String {
        let normalizedSelf = self.normalizedPath
        let normalizedBase = basePath.normalizedPath

        if normalizedSelf.hasPrefix(normalizedBase) {
            var result = String(normalizedSelf.dropFirst(normalizedBase.count))
            if result.hasPrefix("/") {
                result = String(result.dropFirst())
            }
            return result.isEmpty ? "." : result
        }
        return normalizedSelf
    }
}

// MARK: - Path Building
extension String {
    /// Builds an absolute path from the current directory and a relative or absolute path
    func resolvingPath(_ path: String) -> String {
        if path.hasPrefix("/") {
            return path.normalizedPath
        }

        if path == "~" {
            return self // Will be resolved by SFTP
        }

        return self.appendingPathComponent(path).normalizedPath
    }
}
