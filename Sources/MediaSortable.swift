//
//  File.swift
//  MediaSorter
//
//  Created by Tim Oliver on 15/3/2025.
//

import Foundation

public enum MediaType {
    case photo
    case video
}

/// Shared implementation details between photos and videos
public protocol MediaSortable: Any {
    /// The URL of the file
    var url: URL { get }

    /// The date this media was created (ie, when a photo was taken)
    var creationDate: Date { get }

    /// A unique ID for this media. If the media has a Live Photos ID embedded
    /// in it, this should be used. Specify nil to generate a hash off the file instead.
    var uuid: String? { get }

    /// The type of media this is (So that it may be counted in the end)
    var mediaType: MediaType { get }
}

extension MediaSortable {
    func getFileCreationDate() -> Date? {
        let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
        return attributes?[.creationDate] as? Date
    }

    
}
