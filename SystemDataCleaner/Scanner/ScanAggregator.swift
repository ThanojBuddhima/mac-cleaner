import Foundation

class ScanAggregator {
    // Intermediate representation for fast accumulation
    class Node {
        let url: URL
        let name: String
        var isDirectory: Bool
        var size: Int64
        var physicalSize: Int64?
        var modifiedDate: Date?
        var children: [String: Node] = [:]
        var fileCount: Int = 0
        
        init(url: URL, isDirectory: Bool) {
            self.url = url
            self.name = url.lastPathComponent
            self.isDirectory = isDirectory
            self.size = 0
        }
        
        func addChild(_ pathComponents: [String], metadata: FileMetadata, fullURL: URL) {
            guard let first = pathComponents.first else {
                // We reached the node, update its metadata
                self.size += metadata.size
                if let phys = metadata.physicalSize {
                    self.physicalSize = (self.physicalSize ?? 0) + phys
                }
                self.modifiedDate = metadata.modifiedDate
                self.isDirectory = metadata.isDirectory
                if !metadata.isDirectory {
                    self.fileCount += 1
                }
                return
            }
            
            let childNode: Node
            if let existing = children[first] {
                childNode = existing
            } else {
                let childURL = url.appendingPathComponent(first)
                // Assume directory until we hit the leaf
                childNode = Node(url: childURL, isDirectory: true)
                children[first] = childNode
            }
            
            childNode.addChild(Array(pathComponents.dropFirst()), metadata: metadata, fullURL: fullURL)
            
            // Accumulate size upward
            self.size += metadata.size
            if let phys = metadata.physicalSize {
                self.physicalSize = (self.physicalSize ?? 0) + phys
            }
            if !metadata.isDirectory {
                self.fileCount += 1
            }
        }
    }
    
    let rootNode: Node
    
    init(rootURL: URL) {
        self.rootNode = Node(url: rootURL, isDirectory: true)
    }
    
    func add(file: URL, metadata: FileMetadata) {
        let relativePath = file.path.replacingOccurrences(of: rootNode.url.path + "/", with: "")
        if relativePath == file.path { return } // Should not happen if file is under root
        let components = relativePath.components(separatedBy: "/")
        rootNode.addChild(components, metadata: metadata, fullURL: file)
    }
}
