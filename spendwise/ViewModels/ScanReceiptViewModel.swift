//
//  ScanReceiptViewModel.swift
//  spendwise
//
//  Created by Codex on 20/10/2025.
//

import Combine
import Foundation

#if canImport(UIKit)
import UIKit

@MainActor
final class ScanReceiptViewModel: ObservableObject {
    enum Phase {
        case idle
        case processing(UIImage)
        case review(ScanReceiptDraft)
        case error(String)
    }

    @Published private(set) var phase: Phase = .idle

    private let recognizer: ReceiptTextRecognizer
    private let parser: ReceiptParser
    private unowned let store: ExpenseStore
    private let categorySuggester = CategorySuggester()

    init(
        store: ExpenseStore,
        recognizer: ReceiptTextRecognizer = ReceiptTextRecognizer(),
        parser: ReceiptParser = ReceiptParser()
    ) {
        self.store = store
        self.recognizer = recognizer
        self.parser = parser
    }

    func reset() {
        phase = .idle
    }

    func retake() {
        phase = .idle
    }

    func handleFailure(_ message: String) {
        phase = .error(message)
    }

    func categorySuggestion(for merchant: String?) -> ExpenseCategory {
        categorySuggester.suggestedCategory(for: merchant, store: store)
    }

    func startProcessing(image: UIImage) {
        phase = .processing(image)

        Task {
            do {
                let recognition = try await recognizer.recognizeText(in: image)
                let metadata = parser.parse(lines: recognition.lines)
                let category = categorySuggestion(for: metadata.merchant)

                let draft = ScanReceiptDraft(
                    image: image,
                    merchant: metadata.merchant ?? "",
                    total: metadata.total,
                    tax: metadata.tax,
                    date: metadata.date,
                    category: category,
                    notes: "",
                    recognizedText: metadata.combinedText
                )

                await MainActor.run {
                    self.phase = .review(draft)
                }
            } catch {
                await MainActor.run {
                    self.phase = .error("We couldn't read the receipt. \(error.localizedDescription)")
                }
            }
        }
    }
}
#endif
