import SwiftUI

struct DashboardView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @ObservedObject var resultsViewModel: ResultsViewModel
    
    @State private var selectedMode: ScanMode = .quick
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "gearshape.2")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.blue)
            
            Text("System Data Cleaner")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            if let lastScan = viewModel.lastScanDate {
                Text("Last Scan: \(lastScan, formatter: itemFormatter)")
                    .foregroundColor(.secondary)
            } else {
                Text("Never Scanned")
                    .foregroundColor(.secondary)
            }
            
            if case .failed(let errorMsg) = viewModel.scanState {
                Text("Error: \(errorMsg)")
                    .foregroundColor(.red)
                    .padding()
            }
            
            Picker("Scan Mode", selection: $selectedMode) {
                Text("Quick Scan").tag(ScanMode.quick)
                Text("Deep Scan").tag(ScanMode.deep)
            }
            .pickerStyle(SegmentedPickerStyle())
            .frame(maxWidth: 300)
            
            Button(action: {
                viewModel.startScan(mode: selectedMode) { items in
                    resultsViewModel.allItems = items
                }
            }) {
                Text("Scan System Data")
                    .font(.headline)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter
}()
