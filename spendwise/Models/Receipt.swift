//
//  Receipt.swift
//  spendwise
//
//  Created by Codex on 20/10/2025.
//

import Foundation

struct Receipt: Identifiable, Codable {
    let id: UUID
    var imagePath: String
    var thumbnailPath: String
    var ocrText: String
    var parsedTotal: Double?
    var parsedDate: Date?
    var parsedMerchant: String?
    var taxAmount: Double?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        imagePath: String,
        thumbnailPath: String,
        ocrText: String,
        parsedTotal: Double?,
        parsedDate: Date?,
        parsedMerchant: String?,
        taxAmount: Double? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.imagePath = imagePath
        self.thumbnailPath = thumbnailPath
        self.ocrText = ocrText
        self.parsedTotal = parsedTotal
        self.parsedDate = parsedDate
        self.parsedMerchant = parsedMerchant
        self.taxAmount = taxAmount
        self.createdAt = createdAt
    }
}

extension Receipt {
    func imageURL(relativeTo baseURL: URL) -> URL {
        baseURL.appendingPathComponent(imagePath)
    }

    func thumbnailURL(relativeTo baseURL: URL) -> URL {
        baseURL.appendingPathComponent(thumbnailPath)
    }
}
