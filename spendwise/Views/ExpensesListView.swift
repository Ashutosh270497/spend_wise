//
//  ExpensesListView.swift
//  spendwise
//
//  Created by Codex on 20/10/2025.
//

import SwiftUI

struct ExpensesListView: View {
    @EnvironmentObject private var store: ExpenseStore

    @Binding var isPresentingAddExpense: Bool
    var embeddedInNavigationStack: Bool = true

    @State private var searchText: String = ""
    @State private var selectedCategory: ExpenseCategory?
    @State private var scope: Scope = .all

    private var filteredExpenses: [Expense] {
        store.expensesSortedByDate.filter { expense in
            matchesScope(expense) && matchesCategory(expense) && matchesSearch(expense)
        }
    }

    private var groupedExpenses: [(date: Date, items: [Expense])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredExpenses) { expense in
            calendar.startOfDay(for: expense.date)
        }

        return grouped
            .map { entry in
                (date: entry.key, items: entry.value.sorted { $0.date > $1.date })
            }
            .sorted { $0.date > $1.date }
    }

    var body: some View {
        Group {
            if embeddedInNavigationStack {
                NavigationStack {
                    content
                        .searchable(
                            text: $searchText,
                            placement: .navigationBarDrawer(displayMode: .automatic),
                            prompt: "Search title or notes"
                        )
                        .navigationTitle("Expenses")
                        .toolbar(content: toolbarContent)
                }
            } else {
                content
                    .searchable(
                        text: $searchText,
                        placement: .navigationBarDrawer(displayMode: .automatic),
                        prompt: "Search title or notes"
                    )
                    .navigationTitle("Expenses")
                    .toolbar(content: toolbarContent)
            }
        }
    }

    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {
        ToolbarItemGroup(placement: .topBarLeading) {
            if let selectedCategory {
                Button {
                    self.selectedCategory = nil
                } label: {
                    Label("Clear filter", systemImage: "line.3.horizontal.decrease.circle.fill")
                }
            }
        }

        ToolbarItemGroup(placement: .topBarTrailing) {
            Menu {
                Picker("Category", selection: $selectedCategory) {
                    Text("All categories")
                        .tag(Optional<ExpenseCategory>.none)
                    ForEach(ExpenseCategory.allCases) { category in
                        Text(category.rawValue)
                            .tag(Optional(category))
                    }
                }

                Picker("Scope", selection: $scope) {
                    ForEach(Scope.allCases) { option in
                        Text(option.title)
                            .tag(option)
                    }
                }
            } label: {
                Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
            }

            Button {
                isPresentingAddExpense = true
            } label: {
                Label("Add expense", systemImage: "plus.circle.fill")
            }
            .accessibilityIdentifier("add-expense-button")
        }
    }

    @ViewBuilder
    private var content: some View {
        if groupedExpenses.isEmpty {
            ScrollView {
                VStack(spacing: 24) {
                    Image(systemName: "tray")
                        .font(.system(size: 52, weight: .semibold))
                        .foregroundStyle(.tint)
                    Text("No expenses found")
                        .font(.title2.weight(.semibold))
                    Text(selectedCategory == nil && searchText.isEmpty
                         ? "Start logging purchases to see them listed here."
                         : "Try adjusting your filters or search for something else.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)

                    Button {
                        isPresentingAddExpense = true
                    } label: {
                        Label("Add expense", systemImage: "plus.circle.fill")
                            .font(.headline)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.accentColor.opacity(0.15), in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 120)
                .padding(.horizontal, 24)
            }
        } else {
            List {
                ForEach(groupedExpenses, id: \.date) { section in
                    Section(header: Text(section.date, format: .dateTime.weekday(.wide).day().month(.abbreviated))) {
                        ForEach(section.items) { expense in
                            NavigationLink {
                                ExpenseDetailView(expense: expense)
                            } label: {
                                ExpenseRow(expense: expense, showsChevron: true)
                                    .padding(12)
                                    .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                            }
                            .buttonStyle(.plain)
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    store.deleteExpenses(withIDs: [expense.id])
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                        .onDelete { offsets in
                            let ids = offsets.map { section.items[$0].id }
                            store.deleteExpenses(withIDs: ids)
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                    }
                    .headerProminence(.increased)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(
                LinearGradient(
                    colors: [Color(.systemGroupedBackground), Color(.systemBackground)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }

    private func matchesScope(_ expense: Expense) -> Bool {
        switch scope {
        case .all:
            return true
        case .thisMonth:
            return Calendar.current.isDate(expense.date, equalTo: Date(), toGranularity: .month)
        }
    }

    private func matchesCategory(_ expense: Expense) -> Bool {
        guard let selectedCategory else { return true }
        return expense.category == selectedCategory
    }

    private func matchesSearch(_ expense: Expense) -> Bool {
        guard !searchText.isEmpty else { return true }
        let haystack = [
            expense.title,
            expense.notes ?? "",
            expense.category.rawValue
        ]
        .joined(separator: " ")
        .lowercased()

        return haystack.contains(searchText.lowercased())
    }
}

#Preview {
    ExpensesListView(isPresentingAddExpense: .constant(false))
        .environmentObject(ExpenseStore())
}

private enum Scope: String, CaseIterable, Identifiable {
    case all
    case thisMonth

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "All time"
        case .thisMonth: return "This month"
        }
    }
}
