import XCTest
@testable import SystemDataCleaner

final class SafetyAnalyzerTests: XCTestCase {
    
    func testProtectedPathIsDangerous() {
        let url = URL(fileURLWithPath: "/System/Library/CoreServices")
        let (level, _) = SafetyAnalyzer.evaluate(url: url, category: .unknown)
        XCTAssertEqual(level, .dangerous)
    }
    
    func testCacheIsSafe() {
        let url = URL(fileURLWithPath: "/Users/test/Library/Caches/com.apple.Safari")
        let (level, _) = SafetyAnalyzer.evaluate(url: url, category: .cache)
        XCTAssertEqual(level, .safe)
    }
    
    func testUnknownIsUnknown() {
        let url = URL(fileURLWithPath: "/Users/test/Documents/Resume.pdf")
        let (level, _) = SafetyAnalyzer.evaluate(url: url, category: .unknown)
        XCTAssertEqual(level, .unknown) // Unknown is never treated as safe
    }
}
