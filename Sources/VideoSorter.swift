//
// VideoSorter.swift
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
import AVFoundation

/// A struct representing a single video file on disk, powered by the AVFoundation framework.
/// Supports AVFoundation's supported formats (mov, mp4 etc)
struct VideoSorter: MediaSortable {

    // The file URL pointing to this file
    public let url: URL

    // Use the file creation date
    public var useFileCreationDate: Bool = false

    // The AVAsset object backing this file
    private let asset: AVURLAsset

    /// Create a new instance of `VideoSorter` with the provided URL.
    /// Returns nil if the provided file's media format isn't supported.
    /// - Parameter url: The file URL to an image on disk.
    init?(url: URL, useFileCreationDate: Bool = false) {
        let asset = AVURLAsset(url: url)
        guard !asset.tracks.isEmpty else { return nil }

        self.url = url
        self.asset = asset
        self.useFileCreationDate = useFileCreationDate
    }

    /// Identify this media as a video file
    var mediaType: MediaType {
        .video
    }
}

// MARK: - Creation Date

extension VideoSorter {

    /// Determine the time this video was recorded
    public var creationDate: DateComponents? {
        if let exifDateTaken = getVideoDateTaken() {
            return exifDateTaken
        } else if useFileCreationDate, let creationDate = fileCreationDate() {
            return creationDate
        }
        return nil
    }

    /// Fetch the creation date of this video from its QuickTime metadata
    /// - Returns: The creation date as date components if found, nil otherwise
    private func getVideoDateTaken() -> DateComponents? {
        let metadata = asset.metadata(forFormat: .quickTimeMetadata)
        var creationDateString: String?
        for item in metadata {
            if let commonKey = item.commonKey {
                switch commonKey {
                case .commonKeyCreationDate:
                    if let creationDate = item.value as? String {
                        creationDateString = creationDate
                    }
                    break
                default:
                    continue
                }
            }
        }
        guard let creationDateString else { return nil }

        if #available(macOS 13.0, *) {
            return dateComponents(from: creationDateString)
        }

        return nil
    }
}

// MARK: - File UUID

extension VideoSorter {

    /// Fetch the Live Photos UUID first, and if that fails,
    /// generate a UUID based off a SHA256 hash of the file.
    var uuid: String {
        if let livePhotoUUID = getLivePhotoUUID() {
            return livePhotoUUID
        } else if let fileUUID = fileHashAsUUID() {
            return fileUUID
        }
        return "00000000-0000-0000-0000-000000000000"
    }

    /// Fetch the Live Photos UUID from the movie file
    /// - Returns: The UUID string if found, nil otherwise
    private func getLivePhotoUUID() -> String? {
        let metadata = asset.metadata(forFormat: .quickTimeMetadata)
        let livePhotoItem = metadata.first { item in
            guard let key = item.key as? String else { return false }
            return key == "com.apple.quicktime.content.identifier"
        }
        if let livePhotoItem {
            return livePhotoItem.value as? String
        }
        return nil
    }
}
