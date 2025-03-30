//
// PhotoSorter.swift
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
import ImageIO

/// A struct representing a single photo file on disk, powered by the ImageIO framework.
/// Supports all of ImageIO's media formats (jpeg, gif, png, heic etc)
struct PhotoSorter: MediaSortable {

    // The file URL pointing to this file
    public let url: URL

    // Use the file creation date
    public var useFileCreationDate: Bool = false

    // The ImageIO source reference pointing to this image
    private let imageSource: CGImageSource

    /// Create a new instance of `PhotoSorter` with the provided URL.
    /// Returns nil if the provided file's image format isn't supported.
    /// - Parameter url: The file URL to an image on disk.
    init?(url: URL, useFileCreationDate: Bool = false) {
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            return nil
        }
        self.url = url
        self.imageSource = imageSource
        self.useFileCreationDate = useFileCreationDate
    }

    /// Identify this media as an image file
    var mediaType: MediaType {
        .photo
    }
}

// MARK: - Creation Date

extension PhotoSorter {

    /// Determine the time this photo was taken from its metadata
    public var creationDate: DateComponents? {
        if let exifDateTaken = getPhotoDateTaken() {
            return exifDateTaken
        } else if useFileCreationDate, let creationDate = fileCreationDate() {
            return creationDate
        }
        return nil
    }

    /// Fetch the creation date of this photo from the EXIF metadata
    /// - Returns: The creation date as date components if found, nil otherwise
    private func getPhotoDateTaken() -> DateComponents? {
        guard let metadata = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any],
           let exif = metadata[kCGImagePropertyExifDictionary] as? [CFString: Any],
              let dateString = exif[kCGImagePropertyExifDateTimeOriginal] as? String else {
            return nil
        }

        if #available(macOS 13.0, *) {
            return dateComponents(from: dateString)
        }

        return nil
    }
}

// MARK: - File UUID

extension PhotoSorter {

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

    /// Fetch the Live Photos UUID from the image file
    /// - Returns: The UUID string if found, nil otherwise
    private func getLivePhotoUUID() -> String? {
        guard let metadata = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any],
              let appleMetadata = metadata[kCGImagePropertyMakerAppleDictionary] as? [AnyHashable: Any] else {
            return nil
        }
        return appleMetadata["17"] as? String
    }
}
