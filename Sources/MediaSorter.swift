//
//  File.swift
//  PhotoSorter2
//
//  Created by Tim Oliver on 15/3/2025.
//

import Foundation

/// General error handler for any errors that occur before sorting starts
enum MediaSorterError: Error {
    case runtimeError(String)
}

/// The main class that sorts through all of the files in a source
/// folder, and sorts each one into a shared destination folder
public class MediaSorter: @unchecked Sendable {

    // Track the number of medias processed
    private var mediaCountLock = os_unfair_lock()
    private var numberOfPhotos = 0
    private var numberOfVideos = 0

    // Track making new folders
    private var folderLock = os_unfair_lock()

    // An operation queue to process each media concurrently
    private var operationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = ProcessInfo.processInfo.activeProcessorCount
        return queue
    }()

    // Shared reference to the system file manager
    let fileManager = FileManager.default

    func sort(from sourcePath: String, to destinationPath: String) throws -> Int {
        // Validate the source folder URL
        let sourceURL = URL(fileURLWithPath: absolutePath(sourcePath))
        guard isValidFolderURL(sourceURL) else {
            throw MediaSorterError.runtimeError("Source file path must point to a valid folder on disk.")
        }

        // Validate the destination folder URL
        let destinationURL = URL(fileURLWithPath: absolutePath(destinationPath))
        guard isValidFolderURL(destinationURL, createIfNecessary: true) else {
            throw MediaSorterError.runtimeError("Destination file path must point to a valid folder on disk.")
        }

        // Sort through every file in this folder
        for fileURL in try fileManager.contentsOfDirectory(at: sourceURL, includingPropertiesForKeys: nil, options: []) {
            //Skip hidden files
            guard !fileURL.lastPathComponent.hasPrefix(".") else { continue }
            operationQueue.addOperation { [weak self] in
                self?.sortMedia(at: fileURL, to: destinationURL)
            }
        }
        operationQueue.waitUntilAllOperationsAreFinished()

        return 0
    }

    private func sortMedia(at sourceURL: URL, to destionationURL: URL) {
        let fileName = sourceURL.lastPathComponent
        let sorter: MediaSortable? = {
            if let photoSorter = PhotoSorter(url: sourceURL) {
                return photoSorter
            }
            return nil
        }()
        guard let sorter else {
            print("\(fileName): Not a valid media format")
            return
        }

        let creationDate = sorter.creationDate
        print("\(fileName): \(creationDate)")
        print(dateComponentsURLfor(creationDate))
    }

    private func dateComponentsURLfor(_ date: Date) -> String {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d", components.year ?? 0) + "/" +
                String(format: "%02d", components.month ?? 0) + "/" +
                String(format: "%02d", components.day ?? 0)
    }
}

// MARK: - Convenience Helpers

extension MediaSorter {

    /// Converts a relative file path into its absolute equivalent
    /// - Parameter relativePath: A relative file path
    /// - Returns: If the file path was relative, the absolute version.
    public func absolutePath(_ relativePath: String) -> String {
        if relativePath.hasPrefix("/") {
            return relativePath
        }
        return fileManager.currentDirectoryPath + "/" + relativePath
    }

    public func isValidFolderURL(_ url: URL, createIfNecessary: Bool = false) -> Bool {
        // Sanity check the URL is valid
        guard url.isFileURL else {
            return false
        }

        // Check if the provided URL is a valid folder on disk already
        var isFolder: ObjCBool = false
        if fileManager.fileExists(atPath: url.path, isDirectory: &isFolder), isFolder.boolValue {
            return true
        }

        // If a file exists already, short-circuit to avoid changing it
        if !createIfNecessary || fileManager.fileExists(atPath: url.path) {
            return false
        }

        // Create the folder
        do {
            try fileManager.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
            return true
        } catch {}

        return false
    }
}
