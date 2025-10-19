//
//  ExpenseDetailView.swift
//  spendwise
//
//  Created by Codex on 20/10/2025.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct ExpenseDetailView: View {
    @EnvironmentObject private var store: ExpenseStore
    @Environment(\.dismiss) private var dismiss

    let expense: Expense
    @State private var isShowingDeleteConfirmation = false
#if canImport(UIKit)
    @State private var isShowingReceiptPreview = false
    @State private var receiptToPreview: Receipt?
#endif

    private var formattedAmount: String {
        expense.amount.formatted(.currency(code: "INR"))
    }

    private var formattedDate: String {
        expense.date.formatted(.dateTime.weekday(.wide).day().month(.wide).year().hour().minute())
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(formattedAmount)
                        .font(.system(.largeTitle, weight: .bold))

                    Label(expense.category.rawValue, systemImage: expense.category.systemImageName)
                        .font(.headline)

                    Text(formattedDate)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if let tax = expense.tax {
                        Text("Tax: \(tax, format: .currency(code: "INR"))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            if let notes = expense.notes {
                Section("Notes") {
                    Text(notes)
                        .font(.body)
                        .foregroundStyle(.primary)
                }
            }

#if canImport(UIKit)
            if let receiptId = expense.receiptId, let receipt = store.receipt(for: receiptId) {
                Section("Receipt") {
                    if let thumbnail = receiptThumbnail(for: receipt) {
                        Button {
                            receiptToPreview = receipt
                            isShowingReceiptPreview = true
                        } label: {
                            HStack(spacing: 16) {
                                Image(uiImage: thumbnail)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 88, height: 88)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.secondary.opacity(0.15))
                                    }
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("View receipt")
                                        .font(.headline)
                                    Text("Tap to open full image")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .buttonStyle(.plain)
                    } else {
                        Text("Receipt image unavailable.")
                    }
                }
            }
#endif

            Section("Actions") {
                Button(role: .destructive) {
                    isShowingDeleteConfirmation = true
                } label: {
                    Label("Delete expense", systemImage: "trash")
                }
            }
        }
        .navigationTitle(expense.title)
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "Delete this expense?",
            isPresented: $isShowingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                store.deleteExpenses(withIDs: [expense.id])
                dismiss()
            }
        } message: {
            Text("This action cannot be undone.")
        }
#if canImport(UIKit)
        .sheet(isPresented: $isShowingReceiptPreview) {
            if
                let receipt = receiptToPreview,
                let image = fullReceiptImage(for: receipt)
            {
                ReceiptPreviewView(image: image)
            } else {
                Text("Receipt unavailable")
                    .padding()
            }
        }
#endif
    }
}

#Preview {
    NavigationStack {
        ExpenseDetailView(expense: Expense.samples().first!)
            .environmentObject(ExpenseStore())
    }
}

#if canImport(UIKit)
private extension ExpenseDetailView {
    func receiptThumbnail(for receipt: Receipt) -> UIImage? {
        UIImage(contentsOfFile: store.documentsURL(for: receipt.thumbnailPath).path)
    }

    func fullReceiptImage(for receipt: Receipt) -> UIImage? {
        UIImage(contentsOfFile: store.documentsURL(for: receipt.imagePath).path)
    }
}
#endif
