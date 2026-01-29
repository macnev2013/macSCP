//
//  RemoteFile.swift
//  macSCP
//
//  Domain model for remote files and directories
//

import Foundation

struct RemoteFile: Identifiable, Hashable, Sendable, Codable {
    let id: UUID
    let name: String
    let path: String
    let isDirectory: Bool
    let size: Int64
    let permissions: String
    let modificationDate: Date?
    let owner: String?
    let group: String?

    init(
        id: UUID = UUID(),
        name: String,
        path: String,
        isDirectory: Bool,
        size: Int64,
        permissions: String,
        modificationDate: Date? = nil,
        owner: String? = nil,
        group: String? = nil
    ) {
        self.id = id
        self.name = name
        self.path = path
        self.isDirectory = isDirectory
        self.size = size
        self.permissions = permissions
        self.modificationDate = modificationDate
        self.owner = owner
        self.group = group
    }

    // MARK: - Computed Properties
    var isFile: Bool {
        !isDirectory
    }

    var displaySize: String {
        if isDirectory {
            return "--"
        }
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    var fileExtension: String {
        name.fileExtension.lowercased()
    }

    var parentPath: String {
        path.parentPath
    }

    var isHidden: Bool {
        name.hasPrefix(".")
    }

    var isSymlink: Bool {
        permissions.hasPrefix("l")
    }

    var isExecutable: Bool {
        permissions.contains("x")
    }

    // MARK: - File Type
    var fileType: FileType {
        if isDirectory {
            return .directory
        }
        return FileType.from(extension: fileExtension)
    }
}

// MARK: - File Type
enum FileType: String, Sendable {
    case directory
    case text
    case code
    case image
    case video
    case audio
    case archive
    case document
    case spreadsheet
    case presentation
    case pdf
    case executable
    case configuration
    case unknown

    var iconName: String {
        switch self {
        case .directory: return "folder.fill"
        case .text: return "doc.text.fill"
        case .code: return "chevron.left.forwardslash.chevron.right"
        case .image: return "photo.fill"
        case .video: return "video.fill"
        case .audio: return "music.note"
        case .archive: return "doc.zipper"
        case .document: return "doc.fill"
        case .spreadsheet: return "tablecells.fill"
        case .presentation: return "play.rectangle.fill"
        case .pdf: return "doc.richtext.fill"
        case .executable: return "terminal.fill"
        case .configuration: return "gearshape.fill"
        case .unknown: return "doc.fill"
        }
    }

    var isEditable: Bool {
        switch self {
        case .text, .code, .configuration:
            return true
        default:
            return false
        }
    }

    static func from(extension ext: String) -> FileType {
        switch ext {
        // Text
        case "txt", "md", "markdown", "rtf", "log":
            return .text

        // Code
        case "swift", "js", "ts", "jsx", "tsx", "py", "rb", "go", "rs", "java",
             "kt", "c", "cpp", "h", "hpp", "m", "mm", "cs", "php", "html",
             "htm", "css", "scss", "sass", "less", "sql", "sh", "bash", "zsh",
             "fish", "ps1", "bat", "cmd":
            return .code

        // Configuration
        case "json", "yaml", "yml", "xml", "plist", "ini", "conf", "config",
             "env", "gitignore", "dockerfile", "makefile", "toml":
            return .configuration

        // Image
        case "jpg", "jpeg", "png", "gif", "bmp", "svg", "webp", "ico", "tiff",
             "tif", "heic", "heif", "raw":
            return .image

        // Video
        case "mp4", "mov", "avi", "mkv", "wmv", "flv", "webm", "m4v":
            return .video

        // Audio
        case "mp3", "wav", "aac", "flac", "ogg", "m4a", "wma":
            return .audio

        // Archive
        case "zip", "tar", "gz", "bz2", "7z", "rar", "xz", "tgz":
            return .archive

        // Document
        case "doc", "docx", "odt":
            return .document

        // Spreadsheet
        case "xls", "xlsx", "csv", "ods":
            return .spreadsheet

        // Presentation
        case "ppt", "pptx", "odp", "key":
            return .presentation

        // PDF
        case "pdf":
            return .pdf

        // Executable
        case "exe", "app", "dmg", "pkg", "deb", "rpm", "apk", "ipa":
            return .executable

        default:
            return .unknown
        }
    }
}

// MARK: - Sorting
extension RemoteFile {
    static func sortedFiles(_ files: [RemoteFile], by criteria: SortCriteria, ascending: Bool = true) -> [RemoteFile] {
        files.sorted { file1, file2 in
            // Directories always come first
            if file1.isDirectory != file2.isDirectory {
                return file1.isDirectory
            }

            let result: Bool
            switch criteria {
            case .name:
                result = file1.name.localizedCaseInsensitiveCompare(file2.name) == .orderedAscending
            case .size:
                result = file1.size < file2.size
            case .date:
                let date1 = file1.modificationDate ?? .distantPast
                let date2 = file2.modificationDate ?? .distantPast
                result = date1 < date2
            case .type:
                result = file1.fileExtension < file2.fileExtension
            }

            return ascending ? result : !result
        }
    }

    enum SortCriteria: String, CaseIterable, Sendable {
        case name = "Name"
        case size = "Size"
        case date = "Date Modified"
        case type = "Type"
    }
}
