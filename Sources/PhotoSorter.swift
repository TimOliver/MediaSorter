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

    public var creationDate: DateComponents? {
        if let exifDateTaken = getPhotoDateTaken() {
            return exifDateTaken
        }
        return nil
    }

    private func getPhotoDateTaken() -> DateComponents? {
        if let metadata = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any],
           let exif = metadata[kCGImagePropertyExifDictionary] as? [CFString: Any],
           let dateString = exif[kCGImagePropertyExifDateTimeOriginal] as? String {

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
