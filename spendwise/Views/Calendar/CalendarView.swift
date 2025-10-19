//
//  CalendarView.swift
//  spendwise
//
//  Created by Codex on 20/10/2025.
//

import SwiftUI

struct CalendarView: View {
    @EnvironmentObject private var store: ExpenseStore
        @Binding var selectedMonth: Date
    @Binding var selectedDate: Date?
    var onEditBudget: (() -> Void)?

    private var calendar: Calendar {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Monday
        return calendar
    }

    private var monthMetadata: MonthMetadata {
        MonthMetadata(date: selectedMonth, calendar: calendar)
    }

    private var selectedDayExpenses: [Expense] {
        guard let selectedDate else { return [] }
        return store.expenses(on: selectedDate)
    }

    private var budgetInfo: (allocated: Double?, spent: Double, remaining: Double?) {
        let spent = store.spentAmount(for: monthMetadata.components)
        if let remaining = store.remainingBudget(for: monthMetadata.components),
           let budget = store.budget(for: monthMetadata.components) {
            return (budget.allocated, spent, remaining)
        }
        return (nil, spent, nil)
    }


    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                MonthHeader(selectedMonth: $selectedMonth, calendar: calendar)
                BudgetSummaryView(info: budgetInfo, onEditBudget: onEditBudget)
                CalendarGrid(
                    metadata: monthMetadata,
                    selectedDate: $selectedDate,
                    expenses: store.expensesSortedByDate
                )
                DayDetailView(selectedDate: selectedDate, expenses: selectedDayExpenses)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .background(
            LinearGradient(
                colors: [Color(.systemGroupedBackground), Color(.systemBackground)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }
}

private struct MonthHeader: View {
    @Binding var selectedMonth: Date
    var calendar: Calendar

    var body: some View {
        HStack {
            Button {
                selectedMonth = calendar.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth
            } label: {
                Image(systemName: "chevron.left")
                    .font(.headline)
                    .padding(8)
            }

            Spacer()

            Text(selectedMonth.formatted(.dateTime.year().month(.wide)))
                .font(.title2.weight(.bold))

            Spacer()

            Button {
                selectedMonth = calendar.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth
            } label: {
                Image(systemName: "chevron.right")
                    .font(.headline)
                    .padding(8)
            }
        }
    }
}

private struct BudgetSummaryView: View {
    var info: (allocated: Double?, spent: Double, remaining: Double?)
    var onEditBudget: (() -> Void)?

    private var formattedSpent: String {
        info.spent.formatted(.currency(code: "INR"))
    }

    private var formattedRemaining: String {
        guard let remaining = info.remaining else { return "—" }
        return remaining.formatted(.currency(code: "INR"))
    }

    private var formattedAllocated: String {
        guard let allocated = info.allocated else { return "Not set" }
        return allocated.formatted(.currency(code: "INR"))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Spent this month")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(formattedSpent)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                }

                Spacer()

                if let onEditBudget {
                    Button(action: onEditBudget) {
                        Label("Edit budget", systemImage: "pencil.and.ruler")
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.accentColor.opacity(0.12), in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }

            if let allocated = info.allocated, allocated > 0 {
                ProgressView(value: min(info.spent / allocated, 1))
                    .tint(.accentColor)
                    .progressViewStyle(.linear)
            }

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Budget")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(formattedAllocated)
                        .font(.headline)
                }
                Spacer()
                if info.allocated != nil {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Remaining")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(formattedRemaining)
                            .font(.headline)
                    }
                } else {
                    Text("Set a monthly budget to monitor progress.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Material.ultraThin, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 12)
    }
}

private struct CalendarGrid: View {
    var metadata: MonthMetadata
    @Binding var selectedDate: Date?
    var expenses: [Expense]

    private var calendar: Calendar { metadata.calendar }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                ForEach(metadata.weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 12) {
                ForEach(metadata.days, id: \.self) { day in
                    let hasExpense = day.hasExpenses(expenses: expenses, calendar: calendar)
                    DayCell(
                        day: day,
                        isSelected: calendar.isDate(day.date, inSameDayAs: selectedDate ?? Date()),
                        hasExpense: hasExpense
                    )
                    .onTapGesture {
                        selectedDate = day.date
                    }
                }
            }
        }
    }
}

private struct DayCell: View {
    let day: MonthDay
    let isSelected: Bool
    let hasExpense: Bool

    var body: some View {
        ZStack {
            if isSelected {
                Circle()
                    .fill(Color.accentColor.opacity(0.2))
            } else if hasExpense {
                Circle()
                    .fill(Color.accentColor.opacity(0.08))
            }

            Text(day.number)
                .font(.body.weight(hasExpense ? .semibold : .regular))
                .foregroundStyle(day.isWithinDisplayedMonth ? .primary : .secondary)
        }
        .frame(height: 44)
    }
}

private struct DayDetailView: View {
    let selectedDate: Date?
    let expenses: [Expense]

    private var dayTitle: String {
        guard let selectedDate else { return "Select a day" }
        return selectedDate.formatted(.dateTime.weekday(.wide).day().month(.wide).year())
    }

    private var total: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(dayTitle)
                    .font(.headline)
                Spacer()
                Text(total, format: .currency(code: "INR"))
                    .font(.headline)
            }

            if expenses.isEmpty {
                Text("No expenses recorded for this day.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(expenses) { expense in
                    ExpenseRow(expense: expense, showsChevron: false)
                        .padding(12)
                        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Material.ultraThin, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 12)
    }
}

private struct MonthMetadata {
    let date: Date
    let calendar: Calendar

    var components: DateComponents {
        calendar.dateComponents([.year, .month], from: date)
    }

    var firstDay: Date {
        calendar.date(from: components)!
    }

    var days: [MonthDay] {
        guard let range = calendar.range(of: .day, in: .month, for: firstDay) else { return [] }
        let firstWeekday = calendar.component(.weekday, from: firstDay)
        let leadingBlankDays = (firstWeekday - calendar.firstWeekday + 7) % 7

        let totalCount = range.count + leadingBlankDays
        let dates = (0..<totalCount).compactMap { index -> MonthDay? in
            if index < leadingBlankDays {
                let date = calendar.date(byAdding: .day, value: index - leadingBlankDays, to: firstDay)!
                return MonthDay(date: date, isWithinDisplayedMonth: false)
            }
            let dayOffset = index - leadingBlankDays
            let date = calendar.date(byAdding: .day, value: dayOffset, to: firstDay)!
            return MonthDay(date: date, isWithinDisplayedMonth: true)
        }
        return dates
    }

    var weekdaySymbols: [String] {
        calendar.shortWeekdaySymbols
    }
}

private struct MonthDay: Hashable {
    let date: Date
    let isWithinDisplayedMonth: Bool

    var number: String {
        let day = Calendar.current.component(.day, from: date)
        return "\(day)"
    }

    func hasExpenses(expenses: [Expense], calendar: Calendar) -> Bool {
        expenses.contains { calendar.isDate($0.date, inSameDayAs: date) }
    }
}
