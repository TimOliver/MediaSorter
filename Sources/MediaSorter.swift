//
// MediaSorter.swift
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

/// General error handler for any errors that occur before sorting starts
enum MediaSorterError: Error {
    case runtimeError(String)
}

/// The main class that sorts through all of the files in a source
/// folder, and sorts each one into a shared destination folder.
/// Makes use of every physical core of the host machine for maximum efficiency.
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

    /// Moves all of the compatible videos and photos in the source folder into the destination
    /// folder, sorted by year and month based on the media's embedded metadata.
    /// The files are named in a reproducible way, using the embedded Live Photos ID if available.
    /// - Parameters:
    ///   - sourcePath: The file path to the source folder, containing photo and video media files.
    ///   - destinationPath: The file path to the destination folder. Will be created if it doesn't exist yet.
    /// - Returns: The number of photos and videos sucessfully processed.
    func sort(from sourcePath: String, to destinationPath: String) throws -> (photoCount: Int, videoCount: Int) {
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

        return (photoCount: numberOfPhotos, videoCount: numberOfVideos)
    }

    /// Sorts a single piece of media from the source folder into the destination folder
    /// - Parameters:
    ///   - sourceURL: The url of the file on disk.
    ///   - destionationURL: The destination folder to save to.
    private func sortMedia(at sourceURL: URL, to destionationURL: URL) {
        let fileName = sourceURL.lastPathComponent
        let sorter: MediaSortable? = {
            if let videoSorter = VideoSorter(url: sourceURL) {
                return videoSorter
            } else if let photoSorter = PhotoSorter(url: sourceURL) {
                return photoSorter
            }
            return nil
        }()
        guard let sorter else {
            print("\(fileName): Not a supported media file. Skipping.")
            return
        }

        let creationDate = sorter.creationDate
        let creationDatePathComponents = dateComponentsPathfor(creationDate)
        let finalDestionationURL = destionationURL.appendingPathComponent(creationDatePathComponents)
        createDateComponentsDirectoriesIfNeeded(url: finalDestionationURL)

        let uuid = sorter.uuid
        let finalFileName = finalFileName(for: sourceURL, creationDate: creationDate, uuid: uuid)
        let previewURLString = creationDatePathComponents + "/" + finalFileName

        var success = false
        do {
            try fileManager.moveItem(at: sourceURL, to: finalDestionationURL.appendingPathComponent(finalFileName))
            success = true
            print("\(fileName):\tMoved to \(previewURLString)")
        } catch (let error) {
            if (error as NSError).code == NSFileWriteFileExistsError {
                print("\(fileName):\tMove failed. File already exists: \(previewURLString)")
            } else {
                print("\(fileName):\tMove failed. \(error.localizedDescription)")
            }
        }

        if success {
            os_unfair_lock_lock(&mediaCountLock)
            if sorter.mediaType == .photo {
                numberOfPhotos += 1
            } else {
                numberOfVideos += 1
            }
            os_unfair_lock_unlock(&mediaCountLock)
        }
    }

    /// Generates the sub folder route where the next file should be saved, based off its date components
    /// - Parameter components: The date components of when a media file was created
    /// - Returns: The folder path based off those components (eg, 2025/03). 'Unsorted' if there was no date provided.
    private func dateComponentsPathfor(_ components: DateComponents?) -> String {
        guard let components else {
            return "Unsorted"
        }
        return String(format: "%04d", components.year ?? 0) + "/" +
                String(format: "%02d", components.month ?? 0)
    }

    /// Generates the new, unique file name of the current file, based off its creation date and a unique UUID.
    /// - Parameters:
    ///   - url: File URL to the target media file.
    ///   - creationDate: Date components object representing the date and time this file was created.
    ///   - uuid: A uniquie UUID for this file. Either its embedded Live Photos UUID, or a hash from its contents
    /// - Returns: The finalized name (eg, YY-mm-dd-hh-mm-ss-uuid), or it's original name if the creation date is nil
    private func finalFileName(for url: URL, creationDate: DateComponents?, uuid: String) -> String {
        let fileExtension = url.pathExtension.lowercased()
        guard let components = creationDate else {
            return url.lastPathComponent
        }
        return String(format: "%04d", components.year ?? 0) + "-" +
        String(format: "%02d", components.month ?? 0) + "-" +
        String(format: "%02d", components.day ?? 0) + "-" +
        String(format: "%02d", components.hour ?? 0) + "-" +
        String(format: "%02d", components.minute ?? 0) + "-" +
        String(format: "%02d", components.second ?? 0) + "-" +
        uuid + ".\(fileExtension)"

    }

    /// Creates all the intermediate folders for the provided URL, if they don't already exist.
    /// This function is thread-safe, to avoid multiple threads potentially trying to create the same folders at the same time.
    /// - Parameter url: The on-disk file URL where all of the directories should be made.
    private func createDateComponentsDirectoriesIfNeeded(url: URL) {
        guard !fileManager.fileExists(atPath: url.path) else { return }
        os_unfair_lock_lock(&folderLock)
        try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        os_unfair_lock_unlock(&folderLock)
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

    /// Verifies if the provided URL points to a valid directory on disk.
    /// It can optionally create the directory if it doesn't exist.
    /// - Parameters:
    ///   - url: The file path to a target directory.
    ///   - createIfNecessary: Whether to create that directory (and any intermediate directories) if not
    /// - Returns: true if a directory was found (or made), false otherwise
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
