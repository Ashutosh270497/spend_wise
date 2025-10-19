//
//  DocumentScannerView.swift
//  spendwise
//
//  Created by Codex on 20/10/2025.
//

import Foundation

#if canImport(UIKit) && canImport(VisionKit)
import SwiftUI
import VisionKit

@available(iOS 13.0, *)
struct DocumentScannerView: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let onScan: (UIImage) -> Void
    let onCancel: () -> Void
    let onFailure: (Error) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let controller = VNDocumentCameraViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        private let parent: DocumentScannerView

        init(parent: DocumentScannerView) {
            self.parent = parent
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            parent.isPresented = false
            parent.onCancel()
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            parent.isPresented = false
            parent.onFailure(error)
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            parent.isPresented = false
            guard scan.pageCount > 0 else {
                parent.onFailure(ReceiptTextRecognizerError.recognitionFailed)
                return
            }
            let image = scan.imageOfPage(at: 0)
            parent.onScan(image)
        }
    }
}
#endif
