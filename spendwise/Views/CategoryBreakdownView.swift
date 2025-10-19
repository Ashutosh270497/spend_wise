//
//  CategoryBreakdownView.swift
//  spendwise
//
//  Created by Codex on 20/10/2025.
//

import SwiftUI

struct CategoryBreakdownView: View {
    @EnvironmentObject private var store: ExpenseStore

    var body: some View {
        let monthComponents = Calendar.current.dateComponents([.year, .month], from: Date())

        List {
            ForEach(store.expensesByCategory(for: monthComponents), id: \.category) { entry in
                NavigationLink {
                    CategoryDetailView(category: entry.category)
                } label: {
                    HStack {
                        Label(entry.category.rawValue, systemImage: entry.category.systemImageName)
                        Spacer()
                        Text(entry.amount, format: .currency(code: "INR"))
                            .font(.callout.weight(.semibold))
                    }
                }
            }
        }
        .navigationTitle("Categories")
        .overlay {
            if store.expenses.isEmpty {
                EmptyStateView(
                    systemImage: "chart.pie",
                    title: "No categories yet",
                    message: "Log an expense to see categories and insights."
                )
            }
        }
    }
}

struct CategoryDetailView: View {
    @EnvironmentObject private var store: ExpenseStore

    let category: ExpenseCategory
    @State private var isPresentingAddExpense = false

    private var expenses: [Expense] {
        store.expenses(in: category)
    }

    private var total: Double {
        store.total(for: category)
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(total, format: .currency(code: "INR"))
                        .font(.system(.title2, weight: .bold))

                    Text("\(expenses.count) entr\(expenses.count == 1 ? "y" : "ies")")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section("Activity") {
                if expenses.isEmpty {
                    EmptyStateView(
                        systemImage: "doc.plaintext",
                        title: "No expenses yet",
                        message: "Log an expense in \(category.rawValue) to see it listed here."
                    )
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(expenses) { expense in
                        NavigationLink {
                            ExpenseDetailView(expense: expense)
                        } label: {
                            ExpenseRow(expense: expense)
                        }
                    }
                    .onDelete { offsets in
                        let ids = offsets.map { expenses[$0].id }
                        store.deleteExpenses(withIDs: ids)
                    }
                }
            }
        }
        .navigationTitle(category.rawValue)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isPresentingAddExpense = true
                } label: {
                    Label("Add expense", systemImage: "plus.circle.fill")
                }
            }
        }
        .sheet(isPresented: $isPresentingAddExpense) {
            AddExpenseView(initialCategory: category) { expense in
                store.addExpense(expense)
            }
        }
    }
}

#Preview("Categories") {
    CategoryBreakdownView()
        .environmentObject(ExpenseStore())
}

#Preview("Detail") {
    CategoryDetailView(category: .food)
        .environmentObject(ExpenseStore())
}
