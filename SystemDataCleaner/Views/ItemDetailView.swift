import SwiftUI

struct ItemDetailView: View {
    let item: StorageItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(item.name)
                .font(.title)
                .fontWeight(.bold)
            
            HStack {
                Text(formatBytes(item.effectiveSize))
                    .font(.title2)
                Spacer()
            }
            
            Divider()
            
            Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 10) {
                GridRow {
                    Text("Location:")
                        .fontWeight(.semibold)
                    Text(item.path.path)
                        .lineLimit(2)
                }
                
                GridRow {
                    Text("Category:")
                        .fontWeight(.semibold)
                    Text(item.category.rawValue)
                }
                
                GridRow {
                    Text("Files:")
                        .fontWeight(.semibold)
                    Text("\(item.fileCount)")
                }
                
                GridRow {
                    Text("Safety:")
                        .fontWeight(.semibold)
                    Text(item.safetyLevel.rawValue)
                        .padding(4)
                        .background(item.safetyLevel.color.opacity(0.2))
                        .foregroundColor(item.safetyLevel.color)
                        .cornerRadius(4)
                }
            }
            
            Divider()
            
            if let explanation = item.explanation {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Explanation:")
                        .fontWeight(.bold)
                    Text(explanation)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            
            Spacer()
            
            HStack {
                Button("Reveal in Finder") {
                    NSWorkspace.shared.activateFileViewerSelecting([item.path])
                }
                
                Button("Copy Path") {
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(item.path.path, forType: .string)
                }
                
                Spacer()
                
                Button("Move to Trash") {
                    Task {
                        _ = try? await TrashManager.moveToTrash(url: item.path)
                    }
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .disabled(!item.isDeletable)
            }
        }
        .padding()
        .frame(width: 400, height: 400)
    }
}
