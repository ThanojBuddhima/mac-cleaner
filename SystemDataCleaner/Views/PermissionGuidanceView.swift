import SwiftUI

struct PermissionGuidanceView: View {
    @ObservedObject var viewModel: DashboardViewModel
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "lock.shield")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.orange)
            
            Text("Some locations couldn't be scanned")
                .font(.title)
                .fontWeight(.bold)
            
            Text("macOS denied access to some files. Granting Full Disk Access can allow a more complete storage analysis.")
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)
            
            VStack(spacing: 15) {
                Button("Open Full Disk Access Settings") {
                    PermissionManager.shared.openFullDiskAccessSettings()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                
                Button("Continue Without It") {
                    // Just return to idle, or show whatever was scanned
                    viewModel.scanState = .idle
                }
                .buttonStyle(.borderless)
            }
            .padding(.top, 20)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
