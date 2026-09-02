import Foundation

struct FileMetadata {
    let size: Int64
    let physicalSize: Int64?
    let modifiedDate: Date?
    let isDirectory: Bool
    let isSymbolicLink: Bool
}

class FileMetadataReader {
    static let resourceKeys: Set<URLResourceKey> = [
        .fileSizeKey,
        .totalFileAllocatedSizeKey,
        .contentModificationDateKey,
        .isDirectoryKey,
        .isSymbolicLinkKey
    ]
    
    static func metadata(for url: URL) -> FileMetadata? {
        do {
            let values = try url.resourceValues(forKeys: resourceKeys)
            
            let isSymbolicLink = values.isSymbolicLink ?? false
            let isDirectory = values.isDirectory ?? false
            let modifiedDate = values.contentModificationDate
            
            // Directories don't have direct size in URLResourceValues, calculated via children
            var size: Int64 = 0
            var physicalSize: Int64? = nil
            
            if !isDirectory {
                size = Int64(values.fileSize ?? 0)
                if let allocatedSize = values.totalFileAllocatedSize {
                    physicalSize = Int64(allocatedSize)
                }
            }
            
            return FileMetadata(
                size: size,
                physicalSize: physicalSize,
                modifiedDate: modifiedDate,
                isDirectory: isDirectory,
                isSymbolicLink: isSymbolicLink
            )
        } catch {
            return nil
        }
    }
}
