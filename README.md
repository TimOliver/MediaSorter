# MediaSorter

While I use iCloud Photos as sort of intermediate buffer, I archive all of the photos I take on my Synology NAS (which is then backed up to Backblaze).

Unfortunately, when exporting photos from Apple's ecosystem, whether it be by dumping from an iPhone, or exporting the originals from Apple Photos, the photos are usually grouped together in a single folder, with completely arbitrary files. This is especially true of Apple Photos that internally renames image files to a UUID string.

In order to organize these potentially large buckets of photos into a better folder layout for my NAS, I've written this small utility in Swift. It loops through a single folder full of photos and videos, extracts the date they were taken from their EXIF data, and sorts them into folders split up by months and years. The files are given reliable, reproducible file names, so if the same photo exists in separate buckets, they're very easy to find.

Photos and videos that were captured together as Live Photos are also kept together, by having the file name include the Live Photo's UUID.

# Usage

1. Clone or download this repo to your Mac.
2. From the command line, navigate to the downloaded folder.
3. Run `swift run MediaSorter -s /path/to/unsorted/photos/folder -d /path/to/sorted/photos/folder`

# License

This code is in the public domain. Feel free to use 
