//
//  ReceiptParsingModels.swift
//  spendwise
//
//  Created by Codex on 20/10/2025.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

struct ParsedReceiptMetadata {
    var merchant: String?
    var total: Decimal?
    var tax: Decimal?
    var date: Date?
    var lines: [String]

    var combinedText: String {
        lines.joined(separator: "\n")
    }
}

#if canImport(UIKit)
struct ScanReceiptDraft {
    let image: UIImage
    var merchant: String
    var total: Decimal?
    var tax: Decimal?
    var date: Date?
    var category: ExpenseCategory
    var notes: String
    var recognizedText: String

    init(
        image: UIImage,
        merchant: String,
        total: Decimal?,
        tax: Decimal?,
        date: Date?,
        category: ExpenseCategory,
        notes: String = "",
        recognizedText: String
    ) {
        self.image = image
        self.merchant = merchant
        self.total = total
        self.tax = tax
        self.date = date
        self.category = category
        self.notes = notes
        self.recognizedText = recognizedText
    }
}
#endif
