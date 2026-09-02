import SwiftUI

struct MainView: View {
    @StateObject private var dashboardViewModel = DashboardViewModel()
    @StateObject private var resultsViewModel = ResultsViewModel()
    @StateObject private var cleanupViewModel = CleanupViewModel()
    
    var body: some View {
        NavigationSplitView {
            List {
                NavigationLink(destination: dashboardOrScanView) {
                    Label("Dashboard", systemImage: "chart.pie")
                }
                
                if dashboardViewModel.scanState == .completed {
                    NavigationLink(destination: ResultsView(viewModel: resultsViewModel, cleanupViewModel: cleanupViewModel)) {
                        Label("Scan Results", systemImage: "list.dash")
                    }
                    
                    NavigationLink(destination: LargeFilesView(viewModel: resultsViewModel)) {
                        Label("Large Files", systemImage: "arrow.up.bin")
                    }
                }
            }
            .navigationTitle("System Data Cleaner")
            .listStyle(SidebarListStyle())
        } detail: {
            dashboardOrScanView
        }
        .onChange(of: dashboardViewModel.scanState) { newState in
            if case .completed = newState {
                // When scan completes, we normally would pass the items to results.
                // For now, handled in the dashboard onComplete callback.
            }
        }
    }
    
    @ViewBuilder
    var dashboardOrScanView: some View {
        switch dashboardViewModel.scanState {
        case .idle, .cancelled, .completed, .failed:
            DashboardView(viewModel: dashboardViewModel, resultsViewModel: resultsViewModel)
        case .preparing, .scanning:
            ScanView(viewModel: dashboardViewModel)
        case .permissionRequired:
            PermissionGuidanceView(viewModel: dashboardViewModel)
        }
    }
}
