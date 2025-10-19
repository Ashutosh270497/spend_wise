import Combine
import Foundation

@MainActor
final class ExpenseStore: ObservableObject {
    @Published private(set) var expenses: [Expense] = []
    @Published private(set) var receipts: [Receipt] = []
    @Published private(set) var budgets: [MonthlyBudget] = []
    @Published private(set) var merchantDefaults: [String: ExpenseCategory.RawValue] = [:]

    private let storageURL: URL
    private let documentsDirectory: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(fileName: String = "expenses.json") {
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601

        if let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            documentsDirectory = directory
        } else {
            documentsDirectory = URL(fileURLWithPath: "/tmp")
        }

        storageURL = documentsDirectory.appendingPathComponent(fileName)
        loadSnapshot()
    }

    var totalSpent: Double {
        expenses.reduce(0) { result, expense in
            result + expense.amount
        }
    }

    var expensesSortedByDate: [Expense] {
        expenses.sorted { $0.date > $1.date }
    }

    func expenses(on date: Date) -> [Expense] {
        let calendar = Calendar.current
        return expensesSortedByDate.filter { calendar.isDate($0.date, inSameDayAs: date) }
    }

    func monthlyExpenses(for month: DateComponents) -> [Expense] {
        let calendar = Calendar.current
        return expenses.filter { expense in
            let components = calendar.dateComponents([.year, .month], from: expense.date)
            return components.year == month.year && components.month == month.month
        }
    }

    func expensesByCategory(for month: DateComponents) -> [(category: ExpenseCategory, amount: Double)] {
        let filtered = monthlyExpenses(for: month)
        let grouped = Dictionary(grouping: filtered, by: \.category)
        return grouped
            .map { category, expenses in
                (category, expenses.reduce(0) { $0 + $1.amount })
            }
            .sorted { $0.amount > $1.amount }
    }

    func total(for category: ExpenseCategory) -> Double {
        expenses
            .filter { $0.category == category }
            .reduce(0) { $0 + $1.amount }
    }

    func expenses(in category: ExpenseCategory) -> [Expense] {
        expensesSortedByDate.filter { $0.category == category }
    }

    func receipt(for id: Receipt.ID) -> Receipt? {
        receipts.first { $0.id == id }
    }

    func defaultCategory(for merchant: String) -> ExpenseCategory? {
        guard let stored = merchantDefaults[merchant.normalizedMerchantKey] else {
            return nil
        }
        return ExpenseCategory(rawValue: stored)
    }

    func recordDefaultCategory(_ category: ExpenseCategory, for merchant: String) {
        let key = merchant.normalizedMerchantKey
        guard !key.isEmpty else { return }
        if merchantDefaults[key] == category.rawValue { return }
        merchantDefaults[key] = category.rawValue
        persistSnapshot()
    }

    func budget(for month: DateComponents) -> MonthlyBudget? {
        budgets.first { $0.id == month.budgetIdentifier }
    }

    func addOrUpdateBudget(amount: Double, month: DateComponents) {
        let identifier = month.budgetIdentifier
        if let index = budgets.firstIndex(where: { $0.id == identifier }) {
            budgets[index].allocated = amount
            budgets[index].lastUpdated = .now
        } else {
            let budget = MonthlyBudget(id: identifier, allocated: amount, lastUpdated: .now)
            budgets.append(budget)
        }
        persistSnapshot()
    }

    func spentAmount(for month: DateComponents) -> Double {
        monthlyExpenses(for: month).reduce(0) { $0 + $1.amount }
    }

    func remainingBudget(for month: DateComponents) -> Double? {
        guard let budget = budget(for: month) else { return nil }
        return max(budget.allocated - spentAmount(for: month), 0)
    }

    func addExpense(_ expense: Expense) {
        expenses.append(expense)
        recordDefaultCategory(expense.category, for: expense.title)
        persistSnapshot()
    }

    func upsertExpense(_ expense: Expense) {
        if let index = expenses.firstIndex(where: { $0.id == expense.id }) {
            expenses[index] = expense
        } else {
            expenses.append(expense)
        }
        recordDefaultCategory(expense.category, for: expense.title)
        persistSnapshot()
    }

    func deleteExpenses(at offsets: IndexSet) {
        for index in offsets.sorted(by: >) {
            expenses.remove(at: index)
        }
        cleanupReceipts()
        persistSnapshot()
    }

    func deleteExpenses(withIDs ids: [Expense.ID]) {
        expenses.removeAll { ids.contains($0.id) }
        cleanupReceipts()
        persistSnapshot()
    }

    func replace(_ expense: Expense) {
        guard let index = expenses.firstIndex(where: { $0.id == expense.id }) else { return }
        expenses[index] = expense
        persistSnapshot()
    }

    func addReceipt(_ receipt: Receipt) {
        receipts.append(receipt)
        persistSnapshot()
    }

    func updateReceipt(_ receipt: Receipt) {
        guard let index = receipts.firstIndex(where: { $0.id == receipt.id }) else { return }
        receipts[index] = receipt
        persistSnapshot()
    }

    func deleteReceipt(withID id: Receipt.ID) {
        receipts.removeAll { $0.id == id }
        persistSnapshot()
    }

    func documentsURL(for relativePath: String) -> URL {
        documentsDirectory.appendingPathComponent(relativePath)
    }

    func documentsRoot() -> URL {
        documentsDirectory
    }

    private func cleanupReceipts() {
        let orphaned = receipts.filter { receipt in
            !expenses.contains { $0.receiptId == receipt.id }
        }

        if orphaned.isEmpty { return }

        for receipt in orphaned {
            removeFiles(for: receipt)
        }
        receipts.removeAll { receipt in
            orphaned.contains { $0.id == receipt.id }
        }
    }

    private func removeFiles(for receipt: Receipt) {
        let fileManager = FileManager.default
        let primaryURL = documentsDirectory.appendingPathComponent(receipt.imagePath)
        let thumbnailURL = documentsDirectory.appendingPathComponent(receipt.thumbnailPath)

        try? fileManager.removeItem(at: primaryURL)
        try? fileManager.removeItem(at: thumbnailURL)
    }

    private func loadSnapshot() {
        guard FileManager.default.fileExists(atPath: storageURL.path) else {
            expenses = Expense.samples()
            receipts = []
            merchantDefaults = [:]
            persistSnapshot()
            return
        }

        do {
            let data = try Data(contentsOf: storageURL)
            if let snapshot = try? decoder.decode(ExpenseStoreSnapshot.self, from: data) {
                expenses = snapshot.expenses
                receipts = snapshot.receipts
                budgets = snapshot.budgets
                merchantDefaults = snapshot.merchantDefaults
            } else {
                let decodedExpenses = try decoder.decode([Expense].self, from: data)
                expenses = decodedExpenses
                receipts = []
                budgets = []
                merchantDefaults = [:]
                persistSnapshot()
            }
        } catch {
            expenses = Expense.samples()
            receipts = []
            budgets = []
            merchantDefaults = [:]
        }
    }

    private func persistSnapshot() {
        let snapshot = ExpenseStoreSnapshot(
            expenses: expenses,
            receipts: receipts,
            budgets: budgets,
            merchantDefaults: merchantDefaults
        )
        do {
            let data = try encoder.encode(snapshot)
            try data.write(to: storageURL, options: [.atomic])
        } catch {
            // Intentionally silent: writes fail silently in previews.
        }
    }
}

private struct ExpenseStoreSnapshot: Codable {
    var expenses: [Expense]
    var receipts: [Receipt]
    var budgets: [MonthlyBudget]
    var merchantDefaults: [String: ExpenseCategory.RawValue]
}

extension Expense {
    static func samples() -> [Expense] {
        [
            Expense(title: "Groceries", amount: 54.80, category: .food, date: .now.addingTimeInterval(-86_400)),
            Expense(title: "Ride share", amount: 18.50, category: .transport, date: .now.addingTimeInterval(-43_200)),
            Expense(title: "Streaming", amount: 9.99, category: .subscriptions, date: .now.addingTimeInterval(-604_800)),
            Expense(title: "Coffee with Alex", amount: 7.25, category: .food, date: .now.addingTimeInterval(-21_600)),
            Expense(title: "Gym membership", amount: 39.00, category: .health, date: .now.addingTimeInterval(-259_200))
        ]
    }
}

private extension String {
    var normalizedMerchantKey: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }
}

struct MonthlyBudget: Identifiable, Codable {
    let id: String
    var allocated: Double
    var lastUpdated: Date
}

private extension DateComponents {
    var budgetIdentifier: String {
        let year = self.year ?? Calendar.current.component(.year, from: Date())
        let month = self.month ?? Calendar.current.component(.month, from: Date())
        return "\(year)-\(String(format: "%02d", month))"
    }
}
