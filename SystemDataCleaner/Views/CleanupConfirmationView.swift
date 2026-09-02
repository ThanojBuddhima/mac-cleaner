import SwiftUI

struct CleanupConfirmationView: View {
    @ObservedObject var cleanupViewModel: CleanupViewModel
    @Binding var isPresented: Bool
    var onComplete: (([StorageItem]) -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            if let plan = cleanupViewModel.plan, case .planning = cleanupViewModel.state {
                Text("Review Cleanup")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding()
                
                Text("You selected:")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                
                List(plan.items) { item in
                    HStack {
                        Text(item.name)
                        Spacer()
                        Text(formatBytes(item.effectiveSize))
                    }
                }
                .frame(height: 200)
                
                HStack {
                    Text("Total:")
                        .font(.headline)
                    Spacer()
                    Text(formatBytes(plan.estimatedSize))
                        .font(.headline)
                }
                .padding()
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Risk:")
                            .fontWeight(.bold)
                        Text(plan.overallSafety.rawValue)
                            .foregroundColor(plan.overallSafety.color)
                            .fontWeight(.bold)
                    }
                    
                    if plan.overallSafety == .dangerous {
                        Text("This cleanup includes dangerous items. Proceed with extreme caution.")
                            .foregroundColor(.red)
                    } else if plan.overallSafety == .review {
                        Text("Review items carefully. Some data may be important.")
                            .foregroundColor(.orange)
                    } else {
                        Text("These files are generally safe to remove.")
                            .foregroundColor(.green)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.secondary.opacity(0.1))
                
                HStack {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .keyboardShortcut(.cancelAction)
                    
                    Spacer()
                    
                    Button("Move to Trash") {
                        cleanupViewModel.executeCleanup()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
                .padding()
                
            } else {
                // Progress or Results
                switch cleanupViewModel.state {
                case .cleaning(let progress):
                    CleanupProgressView(progress: progress)
                case .complete(let cResult, let vResult):
                    CleanupResultView(cleanupResult: cResult, verificationResult: vResult) {
                        onComplete?(cResult.successfulItems)
                        isPresented = false
                    }
                default:
                    EmptyView()
                }
            }
        }
        .frame(width: 500, height: 600)
    }
}
