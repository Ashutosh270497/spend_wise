//
//  ReceiptPreviewView.swift
//  spendwise
//
//  Created by Codex on 20/10/2025.
//

import SwiftUI
#if canImport(UIKit)
import UIKit

struct ReceiptPreviewView: View {
    @Environment(\.dismiss) private var dismiss
    let image: UIImage

    var body: some View {
        NavigationStack {
            ScrollView([.vertical, .horizontal]) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding()
            }
            .background(Color.black.opacity(0.9))
            .ignoresSafeArea()
            .navigationTitle("Receipt")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundStyle(.primary)
                }
            }
        }
    }
}
#endif
