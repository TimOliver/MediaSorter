//
//  File.swift
//  MediaSorter
//
//  Created by Tim Oliver on 15/3/2025.
//

import Foundation

/// A shared actor for tracking the number of files processed
public actor MediaSorterState {
    private var numberOfPhotos = 0
    private var numberOfVideos = 0

    func inrementPhotoCount() {
        numberOfPhotos += 1
    }

    func getPhotoCount() -> Int {
        return numberOfPhotos
    }

    func inrementVideoCount() {
        numberOfVideos += 1
    }

    func getVideoCount() -> Int {
        return numberOfVideos
    }
}
