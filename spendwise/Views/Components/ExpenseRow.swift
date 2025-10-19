//
//  ExpenseRow.swift
//  spendwise
//
//  Created by Codex on 20/10/2025.
//

import SwiftUI

struct ExpenseRow: View {
    let expense: Expense
    var showsChevron: Bool = true

    private var formattedDate: String {
        expense.date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated).year(.defaultDigits))
    }

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.accentColor.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: expense.category.systemImageName)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.tint)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(expense.title)
                    .font(.headline)
                Text(formattedDate)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(expense.amount, format: .currency(code: "INR"))
                .font(.headline)

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    VStack {
        ExpenseRow(expense: Expense.samples().first!)
        ExpenseRow(expense: Expense.samples()[1])
    }
    .padding()
}
