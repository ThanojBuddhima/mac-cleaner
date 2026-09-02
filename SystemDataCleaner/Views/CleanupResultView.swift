import SwiftUI

struct CleanupResultView: View {
    let cleanupResult: CleanupResult
    let verificationResult: VerificationResult
    let onDone: () -> Void
    
    var body: some View {
        VStack(spacing: 15) {
            Text("Cleanup Complete")
                .font(.largeTitle)
                .padding()
            
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Processed: \(formatBytes(cleanupResult.processedSize))")
                    Text("Successfully removed: \(formatBytes(cleanupResult.successfullyRemovedSize))")
                        .foregroundColor(.green)
                    Text("Skipped: \(formatBytes(cleanupResult.processedSize - cleanupResult.successfullyRemovedSize))")
                        .foregroundColor(cleanupResult.skippedItems.isEmpty ? .secondary : .orange)
                }
                Spacer()
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(8)
            
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Before: \(formatBytes(verificationResult.beforeAvailableStorage)) available")
                    Text("After: \(formatBytes(verificationResult.afterAvailableStorage)) available")
                    Text("Recovered: \(formatBytes(verificationResult.recoveredSize))")
                        .fontWeight(.bold)
                }
                Spacer()
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(8)
            
            if !cleanupResult.skippedItems.isEmpty {
                VStack(alignment: .leading) {
                    Text("Skipped Items:")
                        .font(.headline)
                    List(cleanupResult.skippedItems, id: \.item.id) { skipped in
                        VStack(alignment: .leading) {
                            Text(skipped.item.name)
                            Text(skipped.reason)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            
            Text("Storage values can change independently because macOS may perform background storage management.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()
            
            Button("Done") {
                onDone()
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
        .padding()
    }
}
