//
//  ReceiptParser.swift
//  spendwise
//
//  Created by Codex on 20/10/2025.
//

import Foundation

struct ReceiptParser {
    private let totalKeywords: [String] = [
        "total", "grand total", "amount", "balance due", "amount due", "subtotal"
    ]

    private let mrpKeywords: [String] = [
        "mrp", "m.r.p", "maximum retail price"
    ]

    private let taxKeywords: [String] = [
        "tax", "gst", "vat", "service tax"
    ]

    private let dateFormats: [String] = [
        "dd/MM/yyyy",
        "dd-MM-yyyy",
        "yyyy-MM-dd",
        "dd/MM/yy",
        "dd-MM-yy",
        "MM/dd/yyyy",
        "MM-dd-yyyy"
    ]

    private let currencyRegex: NSRegularExpression
    private let dateRegex: NSRegularExpression

    init() {
        currencyRegex = try! NSRegularExpression(
            pattern: #"₹?\s*[0-9]+(?:[,\s][0-9]{2,3})*(?:\.[0-9]{1,2})?"#,
            options: [.caseInsensitive]
        )
        dateRegex = try! NSRegularExpression(
            pattern: #"\b(\d{1,2}[/-]\d{1,2}[/-]\d{2,4}|\d{4}[/-]\d{1,2}[/-]\d{1,2})\b"#,
            options: []
        )
    }

    func parse(lines rawLines: [String]) -> ParsedReceiptMetadata {
        let sanitizedLines = rawLines
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let total = parseTotal(from: sanitizedLines)
        let tax = parseTax(from: sanitizedLines)
        let date = parseDate(from: sanitizedLines)
        let merchant = parseMerchant(from: sanitizedLines)

        return ParsedReceiptMetadata(
            merchant: merchant,
            total: total,
            tax: tax,
            date: date,
            lines: sanitizedLines
        )
    }

    private func parseTotal(from lines: [String]) -> Decimal? {
        if let mrp = parseMRP(from: lines) {
            return mrp
        }

        var candidates: [(value: Decimal, weight: Int, index: Int)] = []

        for (index, line) in lines.enumerated() {
            let matches = currencyMatches(in: line)

            guard !matches.isEmpty else { continue }

            let keywordMatches = totalKeywords.contains { keyword in
                line.localizedCaseInsensitiveContains(keyword)
            }

            for match in matches {
                guard let value = decimalValue(from: match) else {
                    continue
                }

                let weight = (keywordMatches ? 5 : 1) + (index == lines.count - 1 ? 1 : 0)
                candidates.append((value, weight, index))
            }
        }

        guard let best = candidates.sorted(by: totalCandidateSort).first else {
            return candidates.map(\.value).max()
        }

        return best.value
    }

    private func totalCandidateSort(lhs: (Decimal, Int, Int), rhs: (Decimal, Int, Int)) -> Bool {
        if lhs.1 != rhs.1 {
            return lhs.1 > rhs.1
        }
        if lhs.0 != rhs.0 {
            return lhs.0 > rhs.0
        }
        return lhs.2 > rhs.2
    }

    private func parseMRP(from lines: [String]) -> Decimal? {
        for (index, line) in lines.enumerated() {
            let lowercased = line.lowercased()
            guard mrpKeywords.contains(where: { lowercased.contains($0) }) else { continue }

            if let value = firstCurrencyValue(in: line) {
                return value
            }

            if index + 1 < lines.count, let value = firstCurrencyValue(in: lines[index + 1]) {
                return value
            }
        }
        return nil
    }

    private func parseTax(from lines: [String]) -> Decimal? {
        for line in lines {
            guard taxKeywords.contains(where: { line.localizedCaseInsensitiveContains($0) }) else { continue }
            if let value = firstCurrencyValue(in: line) {
                return value
            }
        }
        return nil
    }

    private func parseDate(from lines: [String]) -> Date? {
        for line in lines {
            let range = NSRange(location: 0, length: line.utf16.count)
            guard let match = dateRegex.firstMatch(in: line, options: [], range: range) else { continue }
            let candidate = (line as NSString).substring(with: match.range)
            if let date = dateFromString(candidate) {
                return date
            }
        }
        return nil
    }

    private func parseMerchant(from lines: [String]) -> String? {
        for line in lines {
            guard !line.isEmpty else { continue }
            if containsCurrency(line) { continue }
            if containsDate(line) { continue }
            if totalKeywords.contains(where: { line.localizedCaseInsensitiveContains($0) }) { continue }
            if taxKeywords.contains(where: { line.localizedCaseInsensitiveContains($0) }) { continue }

            return line
        }
        return lines.first
    }

    private func currencyMatches(in line: String) -> [String] {
        let range = NSRange(location: 0, length: line.utf16.count)
        let matches = currencyRegex.matches(in: line, range: range)
        return matches.map { (line as NSString).substring(with: $0.range) }
    }

    private func firstCurrencyValue(in line: String) -> Decimal? {
        guard let raw = currencyMatches(in: line).first else { return nil }
        return decimalValue(from: raw)
    }

    private func decimalValue(from string: String) -> Decimal? {
        let sanitized = string
            .replacingOccurrences(of: "₹", with: "")
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: CharacterSet(charactersIn: " :;-"))
            .replacingOccurrences(of: " ", with: "")

        return Decimal(string: sanitized)
    }

    private func containsCurrency(_ line: String) -> Bool {
        let range = NSRange(location: 0, length: line.utf16.count)
        return currencyRegex.firstMatch(in: line, options: [], range: range) != nil
    }

    private func containsDate(_ line: String) -> Bool {
        let range = NSRange(location: 0, length: line.utf16.count)
        return dateRegex.firstMatch(in: line, options: [], range: range) != nil
    }

    private func dateFromString(_ string: String) -> Date? {
        for format in dateFormats {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_IN")
            formatter.dateFormat = format
            if let date = formatter.date(from: string) {
                return date
            }
        }
        return nil
    }
}
