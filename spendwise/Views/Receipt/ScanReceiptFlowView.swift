//
//  ScanReceiptFlowView.swift
//  spendwise
//
//  Created by Codex on 20/10/2025.
//

import SwiftUI
import PhotosUI
import Combine

#if canImport(UIKit)
#if canImport(VisionKit)
import VisionKit
#endif
struct ScanReceiptFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var preferences: AppearanceSettings
    @ObservedObject var viewModel: ScanReceiptViewModel
    let onSave: (ReceiptReviewSubmission) -> Void

    @State private var isShowingDocumentScanner = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isShowingPhotoPicker = false
    @State private var hasAutoSubmitted = false

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Scan Receipt")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") { dismiss() }
                    }
                }
        }
        .sheet(isPresented: $isShowingDocumentScanner) {
            #if canImport(VisionKit)
            if #available(iOS 13.0, *) {
                DocumentScannerView(
                    isPresented: $isShowingDocumentScanner,
                    onScan: { image in
                        viewModel.startProcessing(image: image)
                    },
                    onCancel: {
                        if case .idle = viewModel.phase {
                            dismiss()
                        }
                    },
                    onFailure: { error in
                        viewModel.handleFailure(error.localizedDescription)
                    }
                )
            } else {
                Text("Document scanning requires iOS 13 or later.")
            }
            #else
            Text("Document scanning is not available on this device.")
            #endif
        }
        .photosPicker(isPresented: $isShowingPhotoPicker, selection: $selectedPhotoItem, matching: .images)
        .onChange(of: selectedPhotoItem) { newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                    await MainActor.run {
                        viewModel.startProcessing(image: image)
                    }
                }
            }
        }
        .onAppear {
            if case .idle = viewModel.phase {
                // Automatically present the scanner if available.
                #if canImport(VisionKit)
                if VNDocumentCameraViewController.isSupported {
                    isShowingDocumentScanner = true
                }
                #endif
            }
        }
        .onReceive(viewModel.$phase) { phase in
            if case .idle = phase {
                hasAutoSubmitted = false
            }
            #if canImport(VisionKit)
            if case .idle = phase, VNDocumentCameraViewController.isSupported {
                isShowingDocumentScanner = true
            }
            #endif

            #if canImport(UIKit)
            if case let .review(draft) = phase {
                autoSubmitIfPossible(for: draft)
            }
            #endif
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.phase {
        case .idle:
            CaptureOptionsView(
                showDocumentScanner: showDocumentScanner,
                showPhotoPicker: showPhotoPicker
            )
        case let .processing(image):
            ProcessingView(image: image) {
                selectedPhotoItem = nil
                viewModel.retake()
            }
        case let .review(draft):
            if shouldShowManualReview(for: draft) {
                ScanReceiptReviewScreen(
                    draft: draft,
                    categoryProvider: viewModel.categorySuggestion,
                    onRetake: {
                        selectedPhotoItem = nil
                        viewModel.retake()
                    },
                    onSave: { submission in
                        onSave(submission)
                        dismiss()
                    }
                )
            } else {
                AutoSavingView()
            }
        case let .error(message):
            ErrorStateView(
                message: message,
                onRetry: {
                    selectedPhotoItem = nil
                    viewModel.reset()
                },
                onDismiss: { dismiss() }
            )
        }
    }

    private func showDocumentScanner() {
        #if canImport(VisionKit)
        if VNDocumentCameraViewController.isSupported {
            isShowingDocumentScanner = true
        } else {
            isShowingPhotoPicker = true
        }
        #else
        isShowingPhotoPicker = true
        #endif
    }

    private func showPhotoPicker() {
        isShowingPhotoPicker = true
    }

    private func shouldShowManualReview(for draft: ScanReceiptDraft) -> Bool {
        draft.total == nil || !preferences.autoSaveScans
    }

    private func autoSubmitIfPossible(for draft: ScanReceiptDraft) {
        guard preferences.autoSaveScans else { return }
        guard !hasAutoSubmitted else { return }
        guard let total = draft.total else { return }

        hasAutoSubmitted = true

        let trimmedMerchant = draft.merchant.trimmingCharacters(in: .whitespacesAndNewlines)
        let merchant = trimmedMerchant.isEmpty ? "Receipt" : trimmedMerchant

        let note = draft.notes.isEmpty ? summaryNote(from: draft.recognizedText) : draft.notes

        let submission = ReceiptReviewSubmission(
            image: draft.image,
            merchant: merchant,
            amount: total,
            date: draft.date ?? Date(),
            category: draft.category,
            tax: draft.tax,
            notes: note,
            recognizedText: draft.recognizedText
        )

        onSave(submission)
        dismiss()
    }

    private func summaryNote(from text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        if let firstLine = trimmed.split(whereSeparator: { $0.isNewline }).first {
            let line = String(firstLine).trimmingCharacters(in: .whitespacesAndNewlines)
            return String(line.prefix(120))
        }
        return String(trimmed.prefix(120))
    }
}

private struct CaptureOptionsView: View {
    var showDocumentScanner: () -> Void
    var showPhotoPicker: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "doc.text.viewfinder")
                .font(.system(size: 64))
                .foregroundStyle(.tint)

            VStack(spacing: 8) {
                Text("Scan a receipt")
                    .font(.title2.weight(.semibold))
                Text("Use your camera or pick a photo to automatically turn a receipt into an expense.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                Button {
                    showDocumentScanner()
                } label: {
                    Label("Scan with Camera", systemImage: "camera.viewfinder")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    showPhotoPicker()
                } label: {
                    Label("Choose from Photos", systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal)
        }
        .padding()
    }
}

private struct ProcessingView: View {
    let image: UIImage
    var onCancel: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.secondary.opacity(0.1))
                    .frame(width: 220, height: 220)
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 200, maxHeight: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            ProgressView("Reading receipt…")
                .progressViewStyle(.circular)

            Button("Cancel") {
                onCancel()
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}

private struct ErrorStateView: View {
    let message: String
    var onRetry: () -> Void
    var onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 44))
                .foregroundStyle(.orange)
            Text("We couldn’t read that receipt")
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Try Again") {
                onRetry()
            }
            .buttonStyle(.borderedProminent)
            Button("Close") {
                onDismiss()
            }
        }
        .padding()
    }
}

private struct AutoSavingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView("Saving expense…")
                .progressViewStyle(.circular)
            Text("We’re turning this receipt into an expense.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

struct ScanReceiptReviewScreen: View {
    @State private var merchant: String
    @State private var amount: String
    @State private var tax: String
    @State private var date: Date
    @State private var category: ExpenseCategory
    @State private var notes: String

    let draft: ScanReceiptDraft
    let categoryProvider: (String?) -> ExpenseCategory
    let onRetake: () -> Void
    let onSave: (ReceiptReviewSubmission) -> Void

    init(
        draft: ScanReceiptDraft,
        categoryProvider: @escaping (String?) -> ExpenseCategory,
        onRetake: @escaping () -> Void,
        onSave: @escaping (ReceiptReviewSubmission) -> Void
    ) {
        self.draft = draft
        self.categoryProvider = categoryProvider
        self.onRetake = onRetake
        self.onSave = onSave

        _merchant = State(initialValue: draft.merchant)
        _amount = State(initialValue: draft.total?.decimalString ?? "")
        _tax = State(initialValue: draft.tax?.decimalString ?? "")
        _date = State(initialValue: draft.date ?? Date())
        _category = State(initialValue: draft.category)
        _notes = State(initialValue: draft.notes)
    }

    var body: some View {
        Form {
            Section("Receipt") {
                HStack(spacing: 16) {
                    Image(uiImage: draft.image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 84, height: 84)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.secondary.opacity(0.2))
                        }
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Preview")
                            .font(.headline)
                        Button("Retake") {
                            onRetake()
                        }
                        .buttonStyle(.borderless)
                    }
                }
            }

            Section("Details") {
                TextField("Merchant", text: $merchant)
                    .onChange(of: merchant) { newValue in
                        let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                        if trimmed.isEmpty { return }
                        category = categoryProvider(trimmed)
                    }

                TextField("Total amount", text: $amount)
                    .keyboardType(.decimalPad)

                TextField("Tax (optional)", text: $tax)
                    .keyboardType(.decimalPad)

                DatePicker("Date", selection: $date, displayedComponents: [.date])

                Picker("Category", selection: $category) {
                    ForEach(ExpenseCategory.allCases) { category in
                        Text(category.rawValue).tag(category)
                    }
                }
            }

            Section("Notes") {
                TextField("Add notes", text: $notes, axis: .vertical)
                    .lineLimit(3...6)
            }
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    if let submission = makeSubmission() {
                        onSave(submission)
                    }
                }
                .disabled(!isValid)
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Retake") {
                    onRetake()
                }
            }
        }
    }

    private var isValid: Bool {
        !merchant.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && makeDecimal(from: amount) != nil
    }

    private func makeSubmission() -> ReceiptReviewSubmission? {
        guard let amountDecimal = makeDecimal(from: amount) else { return nil }

        let taxDecimal = makeDecimal(from: tax)

        return ReceiptReviewSubmission(
            image: draft.image,
            merchant: merchant.trimmingCharacters(in: .whitespacesAndNewlines),
            amount: amountDecimal,
            date: date,
            category: category,
            tax: taxDecimal,
            notes: notes,
            recognizedText: draft.recognizedText
        )
    }

    private func makeDecimal(from string: String) -> Decimal? {
        guard !string.isEmpty else { return nil }
        let sanitized = string
            .replacingOccurrences(of: "₹", with: "")
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return Decimal(string: sanitized)
    }
}

extension Decimal {
    var decimalString: String {
        NSDecimalNumber(decimal: self).stringValue
    }
}
#endif
