import XCTest
@testable import SystemDataCleaner

final class CategoryClassifierTests: XCTestCase {
    
    func testCacheClassification() {
        let url = URL(fileURLWithPath: "/Users/test/Library/Caches/com.apple.Safari")
        let category = CategoryClassifier.classify(url: url)
        XCTAssertEqual(category, .cache)
    }
    
    func testDeveloperClassification() {
        let url = URL(fileURLWithPath: "/Users/test/Library/Developer/Xcode/DerivedData/App-abcde")
        let category = CategoryClassifier.classify(url: url)
        XCTAssertEqual(category, .developerData)
    }
    
    func testUnknownClassification() {
        let url = URL(fileURLWithPath: "/Users/test/Documents/Resume.pdf")
        let category = CategoryClassifier.classify(url: url)
        XCTAssertEqual(category, .unknown)
    }
}
