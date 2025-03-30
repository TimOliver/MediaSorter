//
// MediaSortable.swift
// By Tim Oliver
//
// This is free and unencumbered software released into the public domain.
//
// Anyone is free to copy, modify, publish, use, compile, sell, or
// distribute this software, either in source code form or as a compiled
// binary, for any purpose, commercial or non-commercial, and by any
// means.
//
// For more information, see <https://unlicense.org/>.

import Foundation
import CryptoKit

public enum MediaType {
    case photo
    case video
}

/// Shared implementation details between photos and videos
public protocol MediaSortable: Any {
    /// The URL of the file
    var url: URL { get }

    /// Whether to use the file creation date or not
    var useFileCreationDate: Bool { get }

    /// The date this media was created (ie, when a photo was taken)
    var creationDate: DateComponents? { get }

    /// A unique ID for this media. If the media has a Live Photos ID embedded
    /// in it, this should be used. Specify nil to generate a hash off the file instead.
    var uuid: String { get }

    /// The type of media this is (So that it may be counted in the end)
    var mediaType: MediaType { get }
}

/// Common logic shared between photos and videos
extension MediaSortable {

    /// Get the file's creation date as date components
    func fileCreationDate() -> DateComponents? {
        let fileManager = FileManager.default

        // Get file attributes
        let attributes = try? fileManager.attributesOfItem(atPath: url.path)

        // Extract creation date
        guard let attributes, let creationDate = attributes[.creationDate] as? Date else {
            return nil
        }

        // Convert Date to DateComponents
        let calendar = Calendar.current
        return calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: creationDate)
    }

    /// Generate a SHA256 hash of this file, which is then returned as a standard UUID string
    /// - Returns: The UUID string of the
    func fileHashAsUUID() -> String? {
        guard let fileStream = InputStream(url: url) else {
            print("Failed to open file")
            return nil
        }

        var hasher = SHA256()
        let bufferSize = 1024 * 512 // 512 KB buffer
        var buffer = [UInt8](repeating: 0, count: bufferSize)

        fileStream.open()
        while fileStream.hasBytesAvailable {
            let bytesRead = fileStream.read(&buffer, maxLength: bufferSize)
            if bytesRead > 0 {
                hasher.update(data: Data(buffer[..<bytesRead]))
            } else {
                break
            }
        }
        fileStream.close()

        // Get the final hash
        let digest = hasher.finalize()

        // Convert the first 16 bytes to a UUID
        let uuid = digest.withUnsafeBytes { UUID(uuid: $0.load(as: uuid_t.self)) }
        return uuid.uuidString
    }

    /// Takes a date string from a file's metadata, parses it and returns it as a DateComponents object
    /// - Parameter dateString: The datestring in ISO 8601 (eg yyyy-mm-ddThh:mm:ss)
    /// - Returns: Date components object representing the passed string
    @available(macOS 13.0, *)
    func dateComponents(from dateString: String) -> DateComponents? {
        let datePattern = /([0-9]+)[-:]([0-9]+)[-:]([0-9]+)[T\s]([0-9]+)[-:]([0-9]+)[-:]([0-9]+)/
        guard let match = dateString.firstMatch(of: datePattern) else {
            return nil
        }

        var components = DateComponents()
        components.year = Int(match.1)
        components.month = Int(match.2)
        components.day = Int(match.3)
        components.hour = Int(match.4)
        components.minute = Int(match.5)
        components.second = Int(match.6)
        return components
    }
}
