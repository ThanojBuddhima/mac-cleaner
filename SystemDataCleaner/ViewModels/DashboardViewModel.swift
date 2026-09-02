import Foundation
import SwiftUI

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var scanState: ScanState = .idle
    @Published var lastScanDate: Date? = nil
    
    private let scanner = StorageScanner()
    
    func startScan(mode: ScanMode, onComplete: @escaping ([StorageItem]) -> Void) {
        scanState = .preparing
        
        scanner.scan(mode: mode) { progress in
            Task { @MainActor in
                self.scanState = .scanning(progress)
            }
        } onComplete: { items in
            Task { @MainActor in
                self.scanState = .completed
                self.lastScanDate = Date()
                onComplete(items)
            }
        } onError: { error in
            Task { @MainActor in
                self.scanState = .failed(error.localizedDescription)
            }
        }
    }
    
    func cancelScan() {
        scanner.cancel()
        scanState = .cancelled
    }
}
