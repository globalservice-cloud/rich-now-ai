//
//  InvoiceQRCodeParser.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/12/19.
//

import Foundation
import os.log

/// 台灣電子發票 QR Code 解析結果
struct InvoiceQRCodeData: Codable {
    let invoiceNumber: String          // 發票號碼 (例如: AB12345678)
    let randomCode: String            // 隨機碼 (4碼)
    let date: Date                    // 發票日期
    let amount: Double                 // 總金額 (新台幣元)
    let sellerTaxId: String?          // 店家統編 (8碼)
    let carrierNumber: String?        // 載具條碼
    let buyerTaxId: String?           // 買方統編
    let salesAmount: Double?           // 銷售金額
    let taxAmount: Double?             // 稅額
    let donateCode: String?           // 捐贈碼
    
    /// 計算稅額（如果有銷售金額）
    var calculatedTaxAmount: Double {
        if let salesAmount = salesAmount {
            return amount - salesAmount
        }
        // 預設 5% 稅率
        return amount / 1.05 * 0.05
    }
    
    /// 計算未稅金額
    var calculatedSalesAmount: Double {
        if let salesAmount = salesAmount {
            return salesAmount
        }
        // 預設 5% 稅率
        return amount / 1.05
    }
}

/// 台灣電子發票 QR Code 解析器
class InvoiceQRCodeParser {
    static let shared = InvoiceQRCodeParser()
    
    private let logger = Logger(subsystem: "com.richnowai", category: "InvoiceQRCodeParser")
    private let dateFormatter: DateFormatter
    
    private init() {
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        dateFormatter.locale = Locale(identifier: "zh_TW")
        dateFormatter.timeZone = TimeZone(identifier: "Asia/Taipei")
    }
    
    // MARK: - 解析 QR Code
    
    /// 解析台灣電子發票 QR Code 字串
    func parse(_ qrCodeString: String) throws -> InvoiceQRCodeData {
        logger.info("開始解析 QR Code: \(qrCodeString.prefix(50))...")
        
        // 台灣電子發票 QR Code 格式有多種：
        // 格式1 (標準格式): [發票號碼]||[隨機碼]||[日期]||[金額]||[統編]||[載具]||[其他]
        // 格式2 (簡化格式): [發票號碼]||[隨機碼]||[日期]||[金額]
        // 格式3 (含稅額): [發票號碼]||[隨機碼]||[日期]||[銷售金額]||[稅額]||[總額]||[統編]||[載具]||[其他]
        
        let components = qrCodeString.components(separatedBy: "||")
        
        guard components.count >= 4 else {
            throw InvoiceQRCodeParseError.invalidFormat("QR Code 格式錯誤，至少需要 4 個欄位")
        }
        
        // 提取基本資訊
        let invoiceNumber = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
        let randomCode = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
        let dateString = components[2].trimmingCharacters(in: .whitespacesAndNewlines)
        let amountString = components[3].trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 驗證發票號碼格式 (例如: AB12345678)
        guard isValidInvoiceNumber(invoiceNumber) else {
            throw InvoiceQRCodeParseError.invalidInvoiceNumber(invoiceNumber)
        }
        
        // 驗證隨機碼格式 (4碼數字或字母)
        guard isValidRandomCode(randomCode) else {
            throw InvoiceQRCodeParseError.invalidRandomCode(randomCode)
        }
        
        // 解析日期 (格式: YYYYMMDD)
        guard let date = parseDate(dateString) else {
            throw InvoiceQRCodeParseError.invalidDate(dateString)
        }
        
        // 解析金額 (新台幣分，需要轉換為元)
        guard let amountInCents = Int64(amountString), amountInCents > 0 else {
            throw InvoiceQRCodeParseError.invalidAmount(amountString)
        }
        let amount = Double(amountInCents) / 100.0 // 轉換為元
        
        // 提取可選欄位
        var sellerTaxId: String? = nil
        var carrierNumber: String? = nil
        var buyerTaxId: String? = nil
        var salesAmount: Double? = nil
        var taxAmount: Double? = nil
        var donateCode: String? = nil
        
        // 判斷格式類型
        if components.count >= 6 {
            // 標準格式或含稅額格式
            if components.count >= 7 {
                // 可能是含稅額格式
                if let salesAmountInCents = Int64(components[3]),
                   let taxAmountInCents = Int64(components[4]),
                   let totalAmountInCents = Int64(components[5]) {
                    // 確認這是含稅額格式
                    if salesAmountInCents + taxAmountInCents == totalAmountInCents {
                        salesAmount = Double(salesAmountInCents) / 100.0
                        taxAmount = Double(taxAmountInCents) / 100.0
                        
                        if components.count > 6 {
                            sellerTaxId = parseOptionalTaxId(components[6])
                        }
                        if components.count > 7 {
                            carrierNumber = parseOptionalCarrier(components[7])
                        }
                        if components.count > 8 {
                            donateCode = parseOptionalDonateCode(components[8])
                        }
                    } else {
                        // 標準格式
                        sellerTaxId = parseOptionalTaxId(components[4])
                        carrierNumber = parseOptionalCarrier(components[5])
                        if components.count > 6 {
                            donateCode = parseOptionalDonateCode(components[6])
                        }
                    }
                } else {
                    // 標準格式
                    sellerTaxId = parseOptionalTaxId(components[4])
                    carrierNumber = parseOptionalCarrier(components[5])
                    if components.count > 6 {
                        donateCode = parseOptionalDonateCode(components[6])
                    }
                }
            } else {
                // 簡化標準格式
                sellerTaxId = parseOptionalTaxId(components[4])
                carrierNumber = parseOptionalCarrier(components[5])
            }
        }
        
        let data = InvoiceQRCodeData(
            invoiceNumber: invoiceNumber,
            randomCode: randomCode,
            date: date,
            amount: amount,
            sellerTaxId: sellerTaxId,
            carrierNumber: carrierNumber,
            buyerTaxId: buyerTaxId,
            salesAmount: salesAmount,
            taxAmount: taxAmount,
            donateCode: donateCode
        )
        
        logger.info("QR Code 解析成功: 發票號碼=\(invoiceNumber), 金額=\(amount)")
        
        return data
    }
    
    /// 驗證發票號碼格式
    private func isValidInvoiceNumber(_ number: String) -> Bool {
        // 格式: 2位數字 + 1位大寫字母 + 8位數字 (例如: 12A12345678)
        let pattern = #"^\d{2}[A-Z]\d{8}$"#
        return number.range(of: pattern, options: .regularExpression) != nil
    }
    
    /// 驗證隨機碼格式
    private func isValidRandomCode(_ code: String) -> Bool {
        // 4碼數字或字母數字組合
        return code.count == 4 && code.allSatisfy { $0.isLetter || $0.isNumber }
    }
    
    /// 解析日期字串
    private func parseDate(_ dateString: String) -> Date? {
        // 格式: YYYYMMDD
        dateFormatter.dateFormat = "yyyyMMdd"
        if let date = dateFormatter.date(from: dateString) {
            return date
        }
        
        // 嘗試其他格式
        dateFormatter.dateFormat = "yyyy-MM-dd"
        if let date = dateFormatter.date(from: dateString) {
            return date
        }
        
        dateFormatter.dateFormat = "yyyy/MM/dd"
        if let date = dateFormatter.date(from: dateString) {
            return date
        }
        
        return nil
    }
    
    /// 解析可選的統編
    private func parseOptionalTaxId(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || trimmed == "0" {
            return nil
        }
        // 統編應該是 8 位數字
        if trimmed.count == 8 && trimmed.allSatisfy({ $0.isNumber }) {
            return trimmed
        }
        return nil
    }
    
    /// 解析可選的載具號碼
    private func parseOptionalCarrier(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || trimmed == "0" {
            return nil
        }
        return trimmed
    }
    
    /// 解析可選的捐贈碼
    private func parseOptionalDonateCode(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || trimmed == "0" {
            return nil
        }
        return trimmed
    }
    
    /// 嘗試解析多種格式的 QR Code（容錯處理）
    func tryParse(_ qrCodeString: String) -> InvoiceQRCodeData? {
        do {
            return try parse(qrCodeString)
        } catch {
            logger.warning("標準解析失敗，嘗試其他格式: \(error.localizedDescription)")
            
            // 嘗試其他可能的格式變體
            // 例如：有些 QR Code 可能使用不同的分隔符或格式
            
            // 處理包含特殊字符的情況
            let cleaned = qrCodeString.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // 嘗試用單個 | 分隔
            if cleaned.contains("|") && !cleaned.contains("||") {
                let modified = cleaned.replacingOccurrences(of: "|", with: "||")
                if let result = try? parse(modified) {
                    return result
                }
            }
            
            return nil
        }
    }
}

// MARK: - 錯誤定義

enum InvoiceQRCodeParseError: LocalizedError {
    case invalidFormat(String)
    case invalidInvoiceNumber(String)
    case invalidRandomCode(String)
    case invalidDate(String)
    case invalidAmount(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidFormat(let message):
            return "QR Code 格式錯誤: \(message)"
        case .invalidInvoiceNumber(let number):
            return "無效的發票號碼格式: \(number)"
        case .invalidRandomCode(let code):
            return "無效的隨機碼格式: \(code)"
        case .invalidDate(let dateString):
            return "無效的日期格式: \(dateString)"
        case .invalidAmount(let amountString):
            return "無效的金額格式: \(amountString)"
        }
    }
}


