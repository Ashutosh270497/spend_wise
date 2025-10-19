import CoreGraphics
//
//  DashboardView.swift
//  spendwise
//
//  Created by Codex on 20/10/2025.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct DashboardView: View {
    @EnvironmentObject private var store: ExpenseStore
    @Binding var isPresentingAddExpense: Bool
#if canImport(UIKit)
    @State private var isPresentingScanReceipt = false
    @State private var scanViewModel: ScanReceiptViewModel?
    @State private var scanErrorMessage: String?
#endif

    private var monthComponents: DateComponents {
        Calendar.current.dateComponents([.year, .month], from: Date())
    }

    private var topCategories: [(category: ExpenseCategory, amount: Double)] {
        Array(store.expensesByCategory(for: monthComponents).prefix(6))
    }

    private var recentExpenses: [Expense] {
        Array(store.expensesSortedByDate.prefix(5))
    }

    private var currentBudget: MonthlyBudget? {
        store.budget(for: monthComponents)
    }

    private var spentThisMonth: Double {
        store.spentAmount(for: monthComponents)
    }

    private var remainingBudget: Double? {
        store.remainingBudget(for: monthComponents)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if store.expenses.isEmpty {
                        EmptyStateCard {
                            isPresentingAddExpense = true
                        }
                    } else {
                        summaryCard
                        categoriesCard
                        recentActivityCard
                    }
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
            .navigationTitle("Overview")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            isPresentingAddExpense = true
                        } label: {
                            Label("Add Expense", systemImage: "square.and.pencil")
                        }

                        #if canImport(UIKit)
                        Button {
                            startScanReceipt()
                        } label: {
                            Label("Scan Receipt", systemImage: "doc.text.viewfinder")
                        }
                        #endif
                    } label: {
                        Label("Add", systemImage: "plus.circle.fill")
                    }
                    .accessibilityIdentifier("add-expense-button")
                }
            }
#if canImport(UIKit)
            .sheet(isPresented: $isPresentingScanReceipt, onDismiss: {
                scanViewModel = nil
            }) {
                ScanReceiptFlowView(
                    viewModel: scanViewModel ?? ScanReceiptViewModel(store: store)
                ) { submission in
                    handleScanSubmission(submission)
                }
            }
            .alert("Could not save receipt", isPresented: Binding(
                get: { scanErrorMessage != nil },
                set: { value in
                    if !value { scanErrorMessage = nil }
                }
            ), actions: {
                Button("OK", role: .cancel) { scanErrorMessage = nil }
            }, message: {
                Text(scanErrorMessage ?? "Something went wrong.")
            })
#endif
        }
    }

    private var summaryCard: some View {
        dashboardCard {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Label("This month", systemImage: "indianrupeesign.circle")
                        .font(.subheadline.weight(.medium))
                        .labelStyle(.titleAndIcon)
                        .foregroundStyle(.secondary)

                    Text(spentThisMonth, format: .currency(code: "INR"))
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .contentTransition(.numericText())
                }

                if let budget = currentBudget, budget.allocated > 0 {
                    VStack(alignment: .leading, spacing: 8) {
                        ProgressView(value: min(spentThisMonth / budget.allocated, 1))
                            .tint(.accentColor)
                        HStack {
                            SummaryChip(
                                title: "Budget",
                                value: budget.allocated.formatted(.currency(code: "INR")),
                                systemImage: "wallet.pass"
                            )
                            SummaryChip(
                                title: "Remaining",
                                value: (remainingBudget ?? 0).formatted(.currency(code: "INR")),
                                systemImage: "indianrupeesign.arrow.circlepath"
                            )
                        }
                    }
                } else {
                    Text("Set a monthly budget from the Calendar tab to track your spending allowance.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 16) {
                    SummaryChip(
                        title: "Top category",
                        value: topCategories.first?.category.rawValue ?? "N/A",
                        systemImage: topCategories.first?.category.systemImageName ?? "chart.pie"
                    )
                    SummaryChip(
                        title: "Entries",
                        value: "\(store.expenses.count)",
                        systemImage: "list.number"
                    )
                }
            }
        }
    }

    private var categoriesCard: some View {
        dashboardCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Where your money goes", systemImage: "chart.pie")
                        .font(.headline)
                    Spacer()
                    NavigationLink {
                        CategoryBreakdownView()
                    } label: {
                        Text("See all")
                            .font(.subheadline.weight(.semibold))
                    }
                }

                if topCategories.isEmpty {
                    Text("Add a few expenses to unlock insights.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    CategoryPieChart(entries: topCategories)
                }
            }
        }
    }

    private var recentActivityCard: some View {
        dashboardCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Recent activity", systemImage: "clock.arrow.circlepath")
                        .font(.headline)
                    Spacer()
                    NavigationLink {
                        ExpensesListView(
                            isPresentingAddExpense: $isPresentingAddExpense,
                            embeddedInNavigationStack: false
                        )
                    } label: {
                        Text("View all")
                            .font(.subheadline.weight(.semibold))
                    }
                }

                if recentExpenses.isEmpty {
                    Text("Tap the add button to start tracking your spending.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    VStack(spacing: 12) {
                        ForEach(recentExpenses) { expense in
                            NavigationLink {
                                ExpenseDetailView(expense: expense)
                            } label: {
                                ExpenseRow(expense: expense, showsChevron: true)
                                    .padding(12)
                                    .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                                    .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private func dashboardCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            content()
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Material.ultraThin, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 12)
    }

    #if canImport(UIKit)
    private func startScanReceipt() {
        scanViewModel = ScanReceiptViewModel(store: store)
        isPresentingScanReceipt = true
    }

    private func handleScanSubmission(_ submission: ReceiptReviewSubmission) {
        let receiptID = UUID()
        let imageStore = ReceiptImageStore(baseURL: store.documentsRoot())

        do {
            let paths = try imageStore.store(image: submission.image, for: receiptID)

            let receipt = Receipt(
                id: receiptID,
                imagePath: paths.imagePath,
                thumbnailPath: paths.thumbnailPath,
                ocrText: submission.recognizedText,
                parsedTotal: submission.amount.doubleValue,
                parsedDate: submission.date,
                parsedMerchant: submission.merchant,
                taxAmount: submission.tax?.doubleValue,
                createdAt: Date()
            )

            store.addReceipt(receipt)

            let expense = Expense(
                title: submission.merchant,
                amount: submission.amount.doubleValue,
                category: submission.category,
                date: submission.date,
                notes: submission.notes.isEmpty ? nil : submission.notes,
                tax: submission.tax?.doubleValue,
                receiptId: receiptID
            )

            store.addExpense(expense)
        } catch {
            scanErrorMessage = error.localizedDescription
        }
    }
    #endif
}

private struct SummaryChip: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .frame(width: 26, height: 26)
                .background(Color.accentColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .foregroundStyle(.tint)

            VStack(alignment: .leading, spacing: 2) {
                Text(title.uppercased())
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#if canImport(UIKit)
private extension Decimal {
    var doubleValue: Double {
        NSDecimalNumber(decimal: self).doubleValue
    }
}
#endif

private struct CategoryBreakdownRow: View {
    let category: ExpenseCategory
    let amount: Double
    let total: Double
    var showAccessory: Bool = false

    private var progress: Double {
        guard total > 0 else { return 0 }
        return min(amount / total, 1)
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Label(category.rawValue, systemImage: category.systemImageName)
                        .labelStyle(.titleAndIcon)
                    Spacer(minLength: 8)
                    Text(amount, format: .currency(code: "INR"))
                        .font(.callout.weight(.semibold))
                }
                ProgressView(value: progress)
                    .tint(.accentColor)
            }

            if showAccessory {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct EmptyStateCard: View {
    var action: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 52, weight: .semibold))
                .foregroundStyle(.tint)
            Text("Track your spending")
                .font(.title2.weight(.semibold))
            Text("Add your first expense to unlock personalised insights and analytics.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Button(action: action) {
                Label("Add expense", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.accentColor.opacity(0.15), in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .background(Material.ultraThin, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 12)
    }
}

private struct CategoryPieChart: View {
    let entries: [(category: ExpenseCategory, amount: Double)]

    private var total: Double {
        entries.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            GeometryReader { geometry in
                let radius = min(geometry.size.width, geometry.size.height) / 2
                let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                let slices = makeSlices()

                ZStack {
                    ForEach(slices) { slice in
                        PieSlice(startAngle: slice.startAngle, endAngle: slice.endAngle)
                            .fill(slice.color.opacity(0.92))
                            .shadow(color: slice.color.opacity(0.25), radius: 6, x: 0, y: 3)

                        if slice.percentage > 0.04 {
                            let midAngle = (slice.startAngle + slice.endAngle) / 2
                            let labelPoint = CGPoint(
                                       x: center.x + CGFloat(cos(midAngle.radians)) * radius * 0.65,
                                y: center.y + CGFloat(sin(midAngle.radians)) * radius * 0.65
                            )

                            VStack(spacing: 2) {
                                Text(slice.label)
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(.primary)
                                Text(slice.amount.formatted(.currency(code: "INR")))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .position(labelPoint)
                        }
                    }

                    VStack(spacing: 6) {
                        Text(total, format: .currency(code: "INR"))
                            .font(.title3.weight(.bold))
                        Text("Total spend")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(height: 240)

            LazyVStack(alignment: .leading, spacing: 10) {
                ForEach(entries, id: \.category) { entry in
                    HStack(spacing: 12) {
                        Capsule()
                            .fill(color(for: entry.category))
                            .frame(width: 18, height: 8)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.category.rawValue)
                                .font(.subheadline.weight(.semibold))
                            Text(entry.amount.formatted(.currency(code: "INR")))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(percentage(for: entry).formatted(.percent.precision(.fractionLength(1))))
                            .font(.subheadline.weight(.semibold))
                    }
                }
            }
        }
    }

    private func color(for category: ExpenseCategory) -> Color {
        switch category {
        case .food: return .orange
        case .transport: return .blue
        case .entertainment: return .purple
        case .shopping: return .pink
        case .utilities: return .teal
        case .housing: return .mint
        case .health: return .red
        case .subscriptions: return .indigo
        case .other: return .gray
        }
    }

    private func percentage(for entry: (category: ExpenseCategory, amount: Double)) -> Double {
        guard total > 0 else { return 0 }
        return entry.amount / total
    }

    private func makeSlices() -> [Slice] {
        var startAngle = Angle.degrees(-90)
        return entries.map { entry in
            let percent = percentage(for: entry)
            let endAngle = startAngle + Angle.degrees(360 * percent)
            defer { startAngle = endAngle }
            return Slice(
                id: UUID(),
                category: entry.category,
                amount: entry.amount,
                startAngle: startAngle,
                endAngle: endAngle,
                percentage: percent,
                label: entry.category.rawValue,
                color: color(for: entry.category)
            )
        }
    }

    private struct Slice: Identifiable {
        let id: UUID
        let category: ExpenseCategory
        let amount: Double
        let startAngle: Angle
        let endAngle: Angle
        let percentage: Double
        let label: String
        let color: Color
    }
}

private struct PieSlice: Shape {
    var startAngle: Angle
    var endAngle: Angle

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        path.move(to: center)
        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        path.closeSubpath()
        return path
    }
}

#Preview("Populated") {
    let store = ExpenseStore()
    store.addExpense(Expense(title: "Lunch", amount: 14, category: .food))

    return DashboardView(isPresentingAddExpense: .constant(false))
        .environmentObject(store)
}

#Preview("Empty") {
    DashboardView(isPresentingAddExpense: .constant(false))
        .environmentObject(ExpenseStore(fileName: "preview-empty"))
}
