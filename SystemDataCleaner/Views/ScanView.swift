import SwiftUI

struct ScanView: View {
    @ObservedObject var viewModel: DashboardViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            if case .scanning(let progress) = viewModel.scanState {
                Text("Scanning System Data...")
                    .font(.title2)
                
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5)
                    .padding()
                
                Text(progress.location)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(maxWidth: 400)
                
                HStack(spacing: 40) {
                    VStack {
                        Text("Files Analyzed")
                            .font(.caption)
                        Text("\(progress.filesAnalyzed)")
                            .font(.headline)
                    }
                    
                    VStack {
                        Text("Storage Analyzed")
                            .font(.caption)
                        Text(formatBytes(progress.storageAnalyzed))
                            .font(.headline)
                    }
                }
                .padding()
                
                Button("Cancel") {
                    viewModel.cancelScan()
                }
                .keyboardShortcut(.cancelAction)
            } else if case .preparing = viewModel.scanState {
                Text("Preparing Scan...")
                ProgressView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB, .useKB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
