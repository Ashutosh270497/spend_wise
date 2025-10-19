import XCTest
import SwiftUI
@testable import spendwise

#if canImport(UIKit)
import UIKit
#endif

final class ScanReceiptReviewSnapshotTests: XCTestCase {
    func testReviewScreenProducesImage() throws {
        #if canImport(UIKit)
        let fixtureURL = Bundle(for: Self.self).url(forResource: "receipt_sample", withExtension: "png")
        XCTAssertNotNil(fixtureURL, "Fixture image missing")
        let imageData = try Data(contentsOf: XCTUnwrap(fixtureURL))
        let uiImage = try XCTUnwrap(UIImage(data: imageData))

        let draft = ScanReceiptDraft(
            image: uiImage,
            merchant: "Cafe Aroma",
            total: Decimal(string: "245.50"),
            tax: Decimal(string: "12.30"),
            date: Date(timeIntervalSince1970: 1_696_000_000),
            category: .food,
            notes: "Afternoon coffee meeting",
            recognizedText: "Cafe Aroma\nTotal ₹245.50"
        )

        let view = ScanReceiptReviewScreen(
            draft: draft,
            categoryProvider: { _ in .food },
            onRetake: {},
            onSave: { _ in }
        )
        .frame(width: 320, height: 480)

        let renderer = ImageRenderer(content: view)
        renderer.scale = 1
        let renderedImage = try XCTUnwrap(renderer.uiImage)
        let pngData = try XCTUnwrap(renderedImage.pngData())

        XCTAssertTrue(pngData.count > 1024, "Snapshot should not be empty")
        #else
        throw XCTSkip("Snapshot tests require UIKit")
        #endif
    }
}
