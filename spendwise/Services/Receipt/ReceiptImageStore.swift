//
//  ReceiptImageStore.swift
//  spendwise
//
//  Created by Codex on 20/10/2025.
//

import Foundation

#if canImport(UIKit)
import UIKit

enum ReceiptImageStoreError: Error {
    case unableToGenerateImageData
    case unableToGenerateThumbnailData
}

struct ReceiptImageStore {
    private let fileManager = FileManager.default
    private let receiptsDirectoryName = "Receipts"
    let baseURL: URL

    func store(image: UIImage, for receiptID: UUID) throws -> (imagePath: String, thumbnailPath: String) {
        let directoryURL = receiptsDirectoryURL()
        if !fileManager.fileExists(atPath: directoryURL.path) {
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        }

        let imageFileName = "\(receiptID.uuidString).jpg"
        let thumbnailFileName = "\(receiptID.uuidString)_thumb.jpg"

        guard let imageData = image.jpegData(compressionQuality: 0.85) else {
            throw ReceiptImageStoreError.unableToGenerateImageData
        }

        let thumbnailImage = makeThumbnail(from: image)
        guard let thumbnailData = thumbnailImage.jpegData(compressionQuality: 0.7) else {
            throw ReceiptImageStoreError.unableToGenerateThumbnailData
        }

        let imageURL = directoryURL.appendingPathComponent(imageFileName)
        let thumbnailURL = directoryURL.appendingPathComponent(thumbnailFileName)

        try imageData.write(to: imageURL, options: [.atomic])
        try thumbnailData.write(to: thumbnailURL, options: [.atomic])

        return (
            imagePath: "\(receiptsDirectoryName)/\(imageFileName)",
            thumbnailPath: "\(receiptsDirectoryName)/\(thumbnailFileName)"
        )
    }

    func removeFiles(at relativePaths: [String]) {
        for path in relativePaths {
            let url = baseURL.appendingPathComponent(path)
            try? fileManager.removeItem(at: url)
        }
    }

    func loadImage(at relativePath: String) -> UIImage? {
        let url = baseURL.appendingPathComponent(relativePath)
        return UIImage(contentsOfFile: url.path)
    }

    private func receiptsDirectoryURL() -> URL {
        baseURL.appendingPathComponent(receiptsDirectoryName, isDirectory: true)
    }

    private func makeThumbnail(from image: UIImage) -> UIImage {
        let maxDimension: CGFloat = 320
        let aspectRatio = image.size.width / image.size.height

        let targetSize: CGSize
        if aspectRatio > 1 {
            targetSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
        } else {
            targetSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
        }

        if let thumbnail = image.preparingThumbnail(of: targetSize) {
            return thumbnail
        }

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}
#endif
