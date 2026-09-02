import Foundation

enum StorageCategory: String, Codable, CaseIterable {
    case cache = "Cache"
    case logs = "Logs"
    case developerData = "Developer Data"
    case applicationSupport = "Application Support"
    case backup = "Backup"
    case browserData = "Browser Data"
    case temporaryData = "Temporary Data"
    case virtualMachine = "Virtual Machine"
    case containerData = "Container Data"
    case other = "Other"
    case unknown = "Unknown"
    
    var sfSymbol: String {
        switch self {
        case .cache: return "archivebox"
        case .logs: return "doc.text"
        case .developerData: return "hammer"
        case .applicationSupport: return "macwindow"
        case .backup: return "arrow.counterclockwise.icloud"
        case .browserData: return "safari"
        case .temporaryData: return "timer"
        case .virtualMachine: return "desktopcomputer"
        case .containerData: return "shippingbox"
        case .other: return "doc"
        case .unknown: return "questionmark.folder"
        }
    }
}
