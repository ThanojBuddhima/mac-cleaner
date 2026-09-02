import SwiftUI

struct CleanupProgressView: View {
    let progress: Double
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Cleaning...")
                .font(.title)
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle())
                .padding()
            
            Text("\(Int(progress * 100))%")
                .font(.headline)
            
            // In a real app we'd have a cancel button here
            // But since cleanup happens fast, we omit for MVP
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
