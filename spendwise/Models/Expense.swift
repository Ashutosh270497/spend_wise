//
//  Expense.swift
//  spendwise
//
//  Created by Codex on 20/10/2025.
//

import Foundation

struct Expense: Identifiable, Codable {
    let id: UUID
    var title: String
    var amount: Double
    var category: ExpenseCategory
    var date: Date
    var notes: String?
    var tax: Double?
    var receiptId: UUID?

    init(
        id: UUID = UUID(),
        title: String,
        amount: Double,
        category: ExpenseCategory,
        date: Date = .now,
        notes: String? = nil,
        tax: Double? = nil,
        receiptId: UUID? = nil
    ) {
        self.id = id
        self.title = title
        self.amount = amount
        self.category = category
        self.date = date
        self.notes = notes
        self.tax = tax
        self.receiptId = receiptId
    }
}

enum ExpenseCategory: String, CaseIterable, Codable, Identifiable {
    case food = "Food & Dining"
    case transport = "Transport"
    case entertainment = "Entertainment"
    case shopping = "Shopping"
    case utilities = "Utilities"
    case housing = "Housing"
    case health = "Health"
    case subscriptions = "Subscriptions"
    case other = "Other"

    var id: String { rawValue }

    var systemImageName: String {
        switch self {
        case .food: return "fork.knife"
        case .transport: return "car.fill"
        case .entertainment: return "sparkles.tv"
        case .shopping: return "bag.fill"
        case .utilities: return "lightbulb.fill"
        case .housing: return "house.fill"
        case .health: return "cross.case.fill"
        case .subscriptions: return "arrow.triangle.2.circlepath"
        case .other: return "ellipsis.circle.fill"
        }
    }

    static var sample: [ExpenseCategory] {
        Array(allCases.prefix(4))
    }
}
