//
//  File.swift
//  MediaSorter
//
//  Created by Tim Oliver on 15/3/2025.
//

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

    /// The date this media was created (ie, when a photo was taken)
    var creationDate: DateComponents? { get }

    /// A unique ID for this media. If the media has a Live Photos ID embedded
    /// in it, this should be used. Specify nil to generate a hash off the file instead.
    var uuid: String { get }

    /// The type of media this is (So that it may be counted in the end)
    var mediaType: MediaType { get }
}

extension MediaSortable {

    func getFileHashAsUUID() -> String? {
        guard let fileStream = InputStream(url: url) else {
            print("Failed to open file")
            return nil
        }

        fileStream.open()

        var hasher = SHA256()
        let bufferSize = 1024 * 512 // 512 KB buffer
        var buffer = [UInt8](repeating: 0, count: bufferSize)

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
}
