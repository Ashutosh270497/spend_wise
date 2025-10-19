//
//  AddExpenseView.swift
//  spendwise
//
//  Created by Codex on 20/10/2025.
//

import SwiftUI

struct AddExpenseView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var amount: String = ""
    @State private var category: ExpenseCategory
    @State private var date: Date = .now
    @State private var notes: String = ""
    @State private var tax: String = ""

    var onSave: (Expense) -> Void

    init(
        initialCategory: ExpenseCategory = .food,
        onSave: @escaping (Expense) -> Void
    ) {
        _category = State(initialValue: initialCategory)
        self.onSave = onSave
    }

    private var parsedAmount: Double? {
        Double(amount.replacingOccurrences(of: ",", with: "."))
    }

    private var parsedTax: Double? {
        guard !tax.isEmpty else { return nil }
        return Double(tax.replacingOccurrences(of: ",", with: "."))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Title", text: $title)
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                    TextField("Tax (optional)", text: $tax)
                        .keyboardType(.decimalPad)
                    Picker("Category", selection: $category) {
                        ForEach(ExpenseCategory.allCases) { category in
                            Label(category.rawValue, systemImage: category.systemImageName)
                                .tag(category)
                        }
                    }
                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                }

                Section("Notes (optional)") {
                    TextField("Add a short note", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Add Expense")
            .scrollContentBackground(.hidden)
            .background(Color(.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let expense = Expense(
                            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                            amount: parsedAmount ?? 0,
                            category: category,
                            date: date,
                            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : notes,
                            tax: parsedTax
                        )
                        onSave(expense)
                        dismiss()
                    }
                    .disabled(!isValidInput)
                }
            }
        }
    }

    private var isValidInput: Bool {
        guard let parsedAmount, parsedAmount > 0 else { return false }
        return !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

#Preview {
    AddExpenseView { _ in }
}
