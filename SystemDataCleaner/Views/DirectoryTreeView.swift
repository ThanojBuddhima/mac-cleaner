import SwiftUI

struct DirectoryTreeView: View {
    let items: [StorageItem]
    
    var body: some View {
        List(items, children: \.children) { item in
            HStack {
                Image(systemName: item.isDirectory ? "folder" : "doc")
                    .foregroundColor(item.isDirectory ? .blue : .secondary)
                
                Text(item.name)
                
                Spacer()
                
                Text(formatBytes(item.effectiveSize))
                    .foregroundColor(.secondary)
            }
        }
    }
}
