//
//  ReceiptReviewSubmission.swift
//  spendwise
//
//  Created by Codex on 20/10/2025.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

#if canImport(UIKit)
struct ReceiptReviewSubmission {
    let image: UIImage
    let merchant: String
    let amount: Decimal
    let date: Date
    let category: ExpenseCategory
    let tax: Decimal?
    let notes: String
    let recognizedText: String
}
#endif
