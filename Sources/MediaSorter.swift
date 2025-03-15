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
public struct MediaSorter {

    // Share state for tracking the number of files processed
    let state = MediaSorterState()

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

        return 0
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
