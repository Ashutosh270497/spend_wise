//
//  ReceiptTextRecognizer.swift
//  spendwise
//
//  Created by Codex on 20/10/2025.
//

import Foundation

#if canImport(UIKit)
import UIKit
#endif
#if canImport(Vision)
import Vision
#endif

enum ReceiptTextRecognizerError: Error {
    case cgImageUnavailable
    case recognitionFailed
}

struct ReceiptTextRecognition {
    let lines: [String]

    var combinedText: String {
        lines.joined(separator: "\n")
    }
}

struct ReceiptTextRecognizer {
    #if canImport(Vision) && canImport(UIKit)
    func recognizeText(in image: UIImage) async throws -> ReceiptTextRecognition {
        guard let cgImage = image.cgImage else {
            throw ReceiptTextRecognizerError.cgImageUnavailable
        }

        return try await recognizeText(in: cgImage)
    }

    func recognizeText(in cgImage: CGImage) async throws -> ReceiptTextRecognition {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.customWords = ["GST", "INR"]
        request.revision = VNRecognizeTextRequestRevision2

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        try handler.perform([request])

        let lines: [String] = request.results?
            .flatMap { observation in
                observation.topCandidates(1).map(\.string)
            } ?? []

        return ReceiptTextRecognition(lines: lines)
    }
    #elseif canImport(UIKit)
    func recognizeText(in image: UIImage) async throws -> ReceiptTextRecognition {
        throw ReceiptTextRecognizerError.recognitionFailed
    }
    func recognizeText(in cgImage: CGImage) async throws -> ReceiptTextRecognition {
        throw ReceiptTextRecognizerError.recognitionFailed
    }
    #else
    func recognizeText(in image: Any) async throws -> ReceiptTextRecognition {
        throw ReceiptTextRecognizerError.recognitionFailed
    }
    func recognizeText(in cgImage: CGImage) async throws -> ReceiptTextRecognition {
        throw ReceiptTextRecognizerError.recognitionFailed
    }
    #endif
}
