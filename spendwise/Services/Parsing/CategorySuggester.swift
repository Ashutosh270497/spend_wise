//
//  CategorySuggester.swift
//  spendwise
//
//  Created by Codex on 20/10/2025.
//

import Foundation

struct CategorySuggester {
    func suggestedCategory(for merchant: String?, store: ExpenseStore) -> ExpenseCategory {
        guard let merchant, !merchant.isEmpty else {
            return .other
        }

        if let stored = store.defaultCategory(for: merchant) {
            return stored
        }

        let lowercased = merchant.lowercased()

        for rule in heuristics {
            if rule.keywords.contains(where: { lowercased.contains($0) }) {
                return rule.category
            }
        }

        return .other
    }

    private var heuristics: [(keywords: [String], category: ExpenseCategory)] {
        [
            (["coffee", "cafe", "café", "starbucks", "tea", "grocery", "groceries", "supermarket", "mart"], .food),
            (["restaurant", "diner", "food", "pizza", "burger", "kitchen"], .food),
            (["uber", "ola", "ride", "cab", "taxi", "metro", "bus", "petrol", "fuel", "diesel", "gas station"], .transport),
            (["movie", "cinema", "theatre", "theater", "entertainment"], .entertainment),
            (["amazon", "flipkart", "store", "mall", "shop"], .shopping),
            (["electric", "water", "gas", "utility", "utilities", "power"], .utilities),
            (["rent", "apartment", "housing", "property"], .housing),
            (["clinic", "doctor", "medical", "pharmacy", "hospital"], .health),
            (["netflix", "spotify", "prime", "subscription"], .subscriptions)
        ]
    }
}
