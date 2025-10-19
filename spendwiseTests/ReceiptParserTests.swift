import XCTest
@testable import spendwise

final class ReceiptParserTests: XCTestCase {
    private var parser: ReceiptParser!

    override func setUp() {
        super.setUp()
        parser = ReceiptParser()
    }

    func testParsesTotalWithKeyword() {
        let lines = [
            "Starbucks Coffee",
            "Order #452",
            "Total: ₹245.50"
        ]

        let metadata = parser.parse(lines: lines)
        XCTAssertEqual(metadata.total, Decimal(string: "245.50"))
    }

    func testParsesLargestTotalWhenNoKeyword() {
        let lines = [
            "Mini Mart",
            "Items 5",
            "120.00",
            "248.90"
        ]

        let metadata = parser.parse(lines: lines)
        XCTAssertEqual(metadata.total, Decimal(string: "248.90"))
    }

    func testParsesDateWithDashSeparator() {
        let lines = [
            "Cafe Mocha",
            "12-10-2025",
            "Total 120"
        ]

        let metadata = parser.parse(lines: lines)
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy"
        XCTAssertEqual(metadata.date, formatter.date(from: "12-10-2025"))
    }

    func testParsesMerchantAsFirstNonNumericLine() {
        let lines = [
            "  ",
            "12345",
            "Cafe Indigo",
            "Total 100"
        ]

        let metadata = parser.parse(lines: lines)
        XCTAssertEqual(metadata.merchant, "Cafe Indigo")
    }
}
