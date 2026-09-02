import Foundation
import SwiftUI

@MainActor
class ScanViewModel: ObservableObject {
    @Published var progress: ScanProgress?
    @Published var error: String?
    @Published var isCancelled = false
    
    private let scanner: StorageScanner
    
    init(scanner: StorageScanner) {
        self.scanner = scanner
    }
    
    func cancel() {
        isCancelled = true
        scanner.cancel()
    }
}
