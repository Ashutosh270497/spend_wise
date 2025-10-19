//
//  CalendarRootView.swift
//  spendwise
//
//  Created by Codex on 20/10/2025.
//

import SwiftUI

struct CalendarRootView: View {
    @EnvironmentObject private var store: ExpenseStore
    @State private var selectedMonth: Date = Date()
    @State private var selectedDate: Date? = Date()
    @State private var isEditingBudget = false
    @State private var budgetInput: String = ""

    private var monthComponents: DateComponents {
        Calendar.current.dateComponents([.year, .month], from: selectedMonth)
    }

    private var currentBudget: MonthlyBudget? {
        store.budget(for: monthComponents)
    }

    var body: some View {
        NavigationStack {
            CalendarView(
                selectedMonth: $selectedMonth,
                selectedDate: $selectedDate,
                onEditBudget: openBudgetEditor
            )
            .navigationTitle("Calendar")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        openBudgetEditor()
                    } label: {
                        Label("Budget", systemImage: "pencil.and.ruler")
                    }
                }
            }
            .sheet(isPresented: $isEditingBudget) {
                BudgetEditorSheet(
                    month: selectedMonth,
                    amount: $budgetInput,
                    onSave: saveBudget
                )
            }
            .onAppear {
                if selectedDate == nil {
                    selectedDate = Date()
                }
                syncBudgetInput()
            }
            .onChange(of: selectedMonth) { _ in
                syncBudgetInput()
                if let firstDay = Calendar.current.date(from: monthComponents) {
                    selectedDate = firstDay
                }
            }
        }
    }

    private func openBudgetEditor() {
        syncBudgetInput()
        isEditingBudget = true
    }

    private func syncBudgetInput() {
        if let allocated = currentBudget?.allocated {
            budgetInput = String(format: "%.2f", allocated)
        } else {
            budgetInput = ""
        }
    }

    private func saveBudget() {
        guard let value = Double(budgetInput.replacingOccurrences(of: ",", with: "")) else {
            isEditingBudget = false
            return
        }
        store.addOrUpdateBudget(amount: max(value, 0), month: monthComponents)
        isEditingBudget = false
    }
}

private struct BudgetEditorSheet: View {
    @Environment(\.dismiss) private var dismiss

    let month: Date
    @Binding var amount: String
    var onSave: () -> Void

    private var monthTitle: String {
        month.formatted(.dateTime.year().month(.wide))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Monthly budget for \(monthTitle)")) {
                    TextField("Amount in ₹", text: $amount)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("Edit Budget")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave()
                        dismiss()
                    }
                    .disabled(amount.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
