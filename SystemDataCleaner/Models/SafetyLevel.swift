import SwiftUI

enum SafetyLevel: String, Codable, CaseIterable {
    case safe = "Safe"
    case review = "Review"
    case dangerous = "Dangerous"
    case unknown = "Unknown"
    
    var color: Color {
        switch self {
        case .safe: return .green
        case .review: return .orange
        case .dangerous: return .red
        case .unknown: return .gray
        }
    }
}
