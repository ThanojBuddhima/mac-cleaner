import SwiftUI

struct LargeFilesView: View {
    @ObservedObject var viewModel: ResultsViewModel
    
    var largeFiles: [StorageItem] {
        var allFiles: [StorageItem] = []
        
        func extractFiles(from items: [StorageItem]) {
            for item in items {
                if !item.isDirectory {
                    allFiles.append(item)
                } else if let children = item.children {
                    extractFiles(from: children)
                }
            }
        }
        
        extractFiles(from: viewModel.allItems)
        
        return Array(allFiles.sorted { $0.effectiveSize > $1.effectiveSize }.prefix(100))
    }
    
    var body: some View {
        VStack {
            Text("Largest Files")
                .font(.title2)
                .padding()
            
            List(largeFiles) { file in
                HStack {
                    Image(systemName: "doc")
                    VStack(alignment: .leading) {
                        Text(file.name)
                            .font(.headline)
                        Text(file.path.path)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    Spacer()
                    Text(formatBytes(file.effectiveSize))
                        .font(.body)
                        .fontWeight(.bold)
                    
                    Menu {
                        Button("Reveal in Finder") {
                            NSWorkspace.shared.activateFileViewerSelecting([file.path])
                        }
                        Button("Move to Trash", role: .destructive) {
                            Task {
                                do {
                                    _ = try await TrashManager.moveToTrash(url: file.path)
                                    await MainActor.run {
                                        viewModel.removeItem(with: file.id)
                                    }
                                } catch {
                                    print("Failed to delete: \(error)")
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .menuStyle(BorderlessButtonMenuStyle())
                    .frame(width: 30)
                }
                .padding(.vertical, 4)
            }
        }
    }
}
