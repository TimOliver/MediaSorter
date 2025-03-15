//
// PhotoSorter2
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
import Prism
import ArgumentParser

/// A small command-line utility to take a folder containing completely unsorted
/// and arbitrarily name photos and videos (eg, from the Photos app) and to sort
/// them into a new folder structure based on the date taken.
/// The new naming scheme aims to be reliably reproducible, so if this command is
/// run on two folders containing identical files, these can be detected and merged.
struct MainCommand: ParsableCommand {

    /// The source folder of unsorted photos/videos
    @Option(name: .shortAndLong, help: "The path to the source folder containing unsorted photos/videos.")
    var source: String? = nil

    /// The destination folder. Will be created if it doesn't exist
    @Option(name: .shortAndLong, help: "The path to the destination folder where the sorted photos/videos will be moved.")
    var destination: String? = nil

    /// The current version of this package.
    public var version = "1.0.0"

    /// Main app entrypoint
    public func run() throws {
        // Print header strings
        printTitle()
        printSubtitle()

        // Verify source and destination paths were provided
        guard let source, let destination else {
            print(MainCommand.helpMessage())
            return
        }

        // Begin sorting all of the media files
        var numberOfFilesSorted: Int = 0
        do {
            let mediaSorter = MediaSorter()
            numberOfFilesSorted = try mediaSorter.sort(from: source, to: destination)
        } catch MediaSorterError.runtimeError(let message) {
            printError(message)
            return
        }

        // Print success message if no errors were thrown
        printSuccess(numberOfFilesCopied: numberOfFilesSorted)
    }
}

// MARK: - String Formatting

extension MainCommand {
    private func printTitle() {
        let title = Prism {
            ForegroundColor(.green, "MediaSorter")
            "-"
            version
        }
        print(title)
    }

    private func printSubtitle() {
        print("A lightweight tool for relibaly sorting a folder of unsorted folders into a new folder sorted by date.\n")
    }

    private func printError(_ message: String) {
        let errorMessage = Prism {
            ForegroundColor(.red, "ERROR:")
            message
        }
        print(errorMessage)
    }

    private func printSuccess(numberOfFilesCopied: Int) {
        let successMessage = Prism {
            ForegroundColor(.green, "SUCCESS:")
            "\(numberOfFilesCopied) files successfully copied."
        }
        print(successMessage)
    }
}

// Run the utility
MainCommand.main()
