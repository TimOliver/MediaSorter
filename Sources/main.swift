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
import ArgumentParser

struct PhotoParser2: ParsableCommand {
    @Option var source: String? = nil
    @Option var destination: String? = nil

    public func run() throws {
        
    }
}

PhotoParser2.main()
