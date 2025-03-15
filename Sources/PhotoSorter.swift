//
//  File.swift
//  MediaSorter
//
//  Created by Tim Oliver on 15/3/2025.
//

import Foundation
import ImageIO

struct PhotoSorter: MediaSortable {

    public let url: URL
    private let imageSource: CGImageSource

    init?(url: URL) {
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            return nil
        }
        self.url = url
        self.imageSource = imageSource
    }

    var mediaType: MediaType {
        .photo
    }
}

extension PhotoSorter {

    public var creationDate: Date {
        if let exifDateTaken = getPhotoDateTaken() {
            return exifDateTaken
        } else if let creationDate = getFileCreationDate() {
            return creationDate
        }
        return Date()
    }

    private func getPhotoDateTaken() -> Date? {
        if let metadata = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any],
           let exif = metadata[kCGImagePropertyExifDictionary] as? [CFString: Any],
           let dateString = exif[kCGImagePropertyExifDateTimeOriginal] as? String {

            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
            formatter.timeZone = TimeZone(identifier: "UTC")
            return formatter.date(from: dateString)
        }
        return nil
    }
}

extension PhotoSorter {
    var uuid: String {
        if let livePhotoUUID = getLivePhotoUUID() {
            return livePhotoUUID
        } else if let fileUUID = getFileHashAsUUID() {
            return fileUUID
        }
        return "00000000-0000-0000-0000-000000000000"
    }

    private func getLivePhotoUUID() -> String? {
        guard let metadata = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any],
              let appleMetadata = metadata[kCGImagePropertyMakerAppleDictionary] as? [AnyHashable: Any] else {
            return nil
        }
        return appleMetadata["17"] as? String
    }
}
