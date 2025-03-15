//
//  File.swift
//  MediaSorter
//
//  Created by Tim Oliver on 15/3/2025.
//

import Foundation
import AVFoundation

struct VideoSorter: MediaSortable {

    public let url: URL
    private let asset: AVURLAsset

    init?(url: URL) {
        let asset = AVURLAsset(url: url)
        guard !asset.tracks.isEmpty else { return nil }

        self.url = url
        self.asset = asset
    }

    var mediaType: MediaType {
        .video
    }
}

extension VideoSorter {

    public var creationDate: Date? {
        if let exifDateTaken = getVideoDateTaken() {
            return exifDateTaken
        }
        return nil
    }

    private func getVideoDateTaken() -> Date? {
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

        let datePattern = /([0-9]+)[-:]([0-9]+)[-:]([0-9]+)/
        guard let match = creationDateString.firstMatch(of: datePattern) else {
            return nil
        }

        var components = DateComponents()
        components.year = Int(match.1)
        components.month = Int(match.2)
        components.day = Int(match.3)
        return Calendar.current.date(from: components)
    }
}

extension VideoSorter {
    var uuid: String {
        if let livePhotoUUID = getLivePhotoUUID() {
            return livePhotoUUID
        } else if let fileUUID = getFileHashAsUUID() {
            return fileUUID
        }
        return "00000000-0000-0000-0000-000000000000"
    }

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
