//
//  InvoiceFormatValidator.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/12/19.
//

import Foundation
import UIKit
import Vision
import NaturalLanguage
import Combine
import os.log

/// 發票格式驗證器 - 專門用於識別和驗證台灣發票格式
@MainActor
class InvoiceFormatValidator: ObservableObject {
    static let shared = InvoiceFormatValidator()
    
    @Published var isProcessing = false
    @Published var validationResult: InvoiceValidationResult?
    @Published var processingError: String?
    
    private let naturalLanguageProcessor = NaturalLanguageProcessor.shared
    private let logger = Logger(subsystem: "com.richnowai", category: "InvoiceFormatValidator")
    
    private init() {}
    
    // MARK: - 發票格式驗證
    
    /// 驗證發票格式並提取詳細資訊
    func validateInvoiceFormat(_ image: UIImage) async throws -> InvoiceValidationResult {
        isProcessing = true
        processingError = nil
        
        defer {
            isProcessing = false
        }
        
        do {
            // 1. 使用 Vision 提取文字
            let extractedText = try await extractTextFromImage(image)
            
            // 2. 識別發票類型
            let invoiceType = identifyInvoiceType(from: extractedText)
            
            // 3. 驗證發票格式
            let formatValidation = validateInvoiceFormat(text: extractedText, type: invoiceType)
            
            // 4. 提取發票詳細資訊
            let invoiceDetails = try await extractInvoiceDetails(from: extractedText, type: invoiceType)
            
            // 5. 驗證發票完整性
            let completenessCheck = validateInvoiceCompleteness(details: invoiceDetails, type: invoiceType)
            
            let result = InvoiceValidationResult(
                isValid: formatValidation.isValid && completenessCheck.isValid,
                invoiceType: invoiceType,
                formatValidation: formatValidation,
                completenessCheck: completenessCheck,
                extractedDetails: invoiceDetails,
                confidence: calculateOverallConfidence(formatValidation, completenessCheck),
                suggestions: generateSuggestions(formatValidation, completenessCheck),
                extractedAt: Date()
            )
            
            validationResult = result
            return result
            
        } catch {
            processingError = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - 文字提取
    
    private func extractTextFromImage(_ image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw InvoiceValidationError.invalidImage
        }
        
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["zh-Hant", "zh-Hans", "en"]
        request.usesLanguageCorrection = true
        request.customWords = [
            "統一發票", "電子發票", "收據", "INVOICE", "RECEIPT",
            "統一編號", "統編", "發票號碼", "發票日期",
            "總計", "合計", "小計", "稅額", "未稅金額",
            "7-11", "全家", "OK", "萊爾富", "統一超商",
            "家樂福", "全聯", "屈臣氏", "康是美"
        ]
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        try handler.perform([request])
        
        guard let observations = request.results else {
            throw InvoiceValidationError.textRecognitionFailed
        }
        
        var extractedText = ""
        for observation in observations {
            if let topCandidate = observation.topCandidates(1).first {
                let text = topCandidate.string
                let confidence = topCandidate.confidence
                
                if confidence > 0.5 {
                    if !extractedText.isEmpty {
                        extractedText += "\n"
                    }
                    extractedText += text
                }
            }
        }
        
        guard !extractedText.isEmpty else {
            throw InvoiceValidationError.textRecognitionFailed
        }
        
        return extractedText
    }
    
    // MARK: - 發票類型識別
    
    private func identifyInvoiceType(from text: String) -> InvoiceType {
        let lowercasedText = text.lowercased()
        
        // 檢查是否為台灣統一發票
        if lowercasedText.contains("統一發票") || lowercasedText.contains("電子發票") {
            // 檢查是否為電子發票
            if lowercasedText.contains("電子發票") || lowercasedText.contains("載具") {
                return .electronicInvoice
            } else {
                return .traditionalInvoice
            }
        }
        
        // 檢查是否為一般收據
        if lowercasedText.contains("收據") || lowercasedText.contains("receipt") {
            return .receipt
        }
        
        // 檢查是否為國外發票
        if lowercasedText.contains("invoice") || lowercasedText.contains("tax") {
            return .internationalInvoice
        }
        
        // 預設為一般收據
        return .receipt
    }
    
    // MARK: - 格式驗證
    
    private func validateInvoiceFormat(text: String, type: InvoiceType) -> FormatValidation {
        var isValid = true
        var issues: [String] = []
        var confidence: Double = 1.0
        
        switch type {
        case .electronicInvoice:
            let validation = validateElectronicInvoiceFormat(text)
            isValid = validation.isValid
            issues = validation.issues
            confidence = validation.confidence
            
        case .traditionalInvoice:
            let validation = validateTraditionalInvoiceFormat(text)
            isValid = validation.isValid
            issues = validation.issues
            confidence = validation.confidence
            
        case .receipt:
            let validation = validateReceiptFormat(text)
            isValid = validation.isValid
            issues = validation.issues
            confidence = validation.confidence
            
        case .internationalInvoice:
            let validation = validateInternationalInvoiceFormat(text)
            isValid = validation.isValid
            issues = validation.issues
            confidence = validation.confidence
        }
        
        return FormatValidation(
            isValid: isValid,
            issues: issues,
            confidence: confidence
        )
    }
    
    private func validateElectronicInvoiceFormat(_ text: String) -> FormatValidation {
        var issues: [String] = []
        var confidence: Double = 1.0
        
        // 檢查必要欄位
        let requiredFields = [
            ("發票號碼", #"\d{2}[A-Z]\d{8}"#),
            ("發票日期", #"\d{4}[-/]\d{2}[-/]\d{2}"#),
            ("統一編號", #"\d{8}"#),
            ("總計", #"總計|合計|Total"#)
        ]
        
        for (fieldName, pattern) in requiredFields {
            if text.range(of: pattern, options: .regularExpression) == nil {
                issues.append("缺少\(fieldName)")
                confidence -= 0.2
            }
        }
        
        // 檢查金額格式
        let amountPattern = #"\d+(?:\.\d{2})?"#
        if text.range(of: amountPattern, options: .regularExpression) == nil {
            issues.append("未找到金額資訊")
            confidence -= 0.3
        }
        
        return FormatValidation(
            isValid: issues.isEmpty,
            issues: issues,
            confidence: max(0.0, confidence)
        )
    }
    
    private func validateTraditionalInvoiceFormat(_ text: String) -> FormatValidation {
        var issues: [String] = []
        var confidence: Double = 1.0
        
        // 檢查傳統發票必要欄位
        let requiredFields = [
            ("發票號碼", #"\d{2}[A-Z]\d{8}"#),
            ("發票日期", #"\d{4}[-/]\d{2}[-/]\d{2}"#),
            ("統一編號", #"\d{8}"#)
        ]
        
        for (fieldName, pattern) in requiredFields {
            if text.range(of: pattern, options: .regularExpression) == nil {
                issues.append("缺少\(fieldName)")
                confidence -= 0.25
            }
        }
        
        return FormatValidation(
            isValid: issues.isEmpty,
            issues: issues,
            confidence: max(0.0, confidence)
        )
    }
    
    private func validateReceiptFormat(_ text: String) -> FormatValidation {
        var issues: [String] = []
        var confidence: Double = 1.0
        
        // 檢查收據基本欄位
        let hasAmount = text.range(of: #"\d+(?:\.\d{2})?"#, options: .regularExpression) != nil
        let hasDate = text.range(of: #"\d{4}[-/]\d{2}[-/]\d{2}"#, options: .regularExpression) != nil
        
        if !hasAmount {
            issues.append("未找到金額資訊")
            confidence -= 0.4
        }
        
        if !hasDate {
            issues.append("未找到日期資訊")
            confidence -= 0.2
        }
        
        return FormatValidation(
            isValid: issues.isEmpty,
            issues: issues,
            confidence: max(0.0, confidence)
        )
    }
    
    private func validateInternationalInvoiceFormat(_ text: String) -> FormatValidation {
        var issues: [String] = []
        var confidence: Double = 1.0
        
        // 檢查國際發票欄位
        let hasAmount = text.range(of: #"\d+(?:\.\d{2})?"#, options: .regularExpression) != nil
        let hasDate = text.range(of: #"\d{4}[-/]\d{2}[-/]\d{2}"#, options: .regularExpression) != nil
        
        if !hasAmount {
            issues.append("未找到金額資訊")
            confidence -= 0.4
        }
        
        return FormatValidation(
            isValid: issues.isEmpty,
            issues: issues,
            confidence: max(0.0, confidence)
        )
    }
    
    // MARK: - 發票詳細資訊提取
    
    private func extractInvoiceDetails(from text: String, type: InvoiceType) async throws -> InvoiceDetails {
        let lines = text.components(separatedBy: .newlines)
        
        // 提取基本資訊
        let merchantName = extractMerchantName(from: text, lines: lines)
        let invoiceNumber = extractInvoiceNumber(from: text, type: type)
        let invoiceDate = extractInvoiceDate(from: text)
        let totalAmount = extractTotalAmount(from: text)
        let taxAmount = extractTaxAmount(from: text)
        let items = extractInvoiceItems(from: text, lines: lines)
        let sellerInfo = extractSellerInfo(from: text)
        let paymentMethod = extractPaymentMethod(from: text)
        
        return InvoiceDetails(
            merchantName: merchantName,
            invoiceNumber: invoiceNumber,
            invoiceDate: invoiceDate,
            totalAmount: totalAmount,
            taxAmount: taxAmount,
            items: items,
            sellerInfo: sellerInfo,
            paymentMethod: paymentMethod,
            rawText: text
        )
    }
    
    private func extractMerchantName(from text: String, lines: [String]) -> String {
        // 優先從前幾行提取商家名稱
        for (index, line) in lines.prefix(5).enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // 跳過明顯不是商家名稱的行
            if trimmed.isEmpty ||
               trimmed.contains("發票") ||
               trimmed.contains("統一編號") ||
               trimmed.contains("統編") ||
               trimmed.contains("日期") ||
               trimmed.contains("Date") ||
               trimmed.contains("INVOICE") ||
               trimmed.contains("#") ||
               trimmed.range(of: #"^\d+$"#, options: .regularExpression) != nil {
                continue
            }
            
            // 商家名稱通常不會太長，且不包含金額符號
            if trimmed.count >= 2 && trimmed.count <= 50 &&
               !trimmed.contains("$") && !trimmed.contains("NT$") &&
               !trimmed.contains("元") && !trimmed.contains("總計") {
                return trimmed
            }
        }
        
        return "未知商家"
    }
    
    private func extractInvoiceNumber(from text: String, type: InvoiceType) -> String? {
        let patterns: [String]
        
        switch type {
        case .electronicInvoice, .traditionalInvoice:
            patterns = [
                #"發票號碼[：:]\s*(\d{2}[A-Z]\d{8})"#,
                #"發票號[：:]\s*(\d{2}[A-Z]\d{8})"#,
                #"(\d{2}[A-Z]\d{8})"#
            ]
        case .receipt, .internationalInvoice:
            patterns = [
                #"發票號碼[：:]\s*([A-Z0-9]+)"#,
                #"發票號[：:]\s*([A-Z0-9]+)"#,
                #"Invoice\s*#?\s*([A-Z0-9]+)"#
            ]
        }
        
        for pattern in patterns {
            if let range = text.range(of: pattern, options: .regularExpression) {
                let match = String(text[range])
                if let numberRange = match.range(of: #"(\d{2}[A-Z]\d{8}|[A-Z0-9]+)"#, options: .regularExpression) {
                    return String(match[numberRange])
                }
            }
        }
        
        return nil
    }
    
    private func extractInvoiceDate(from text: String) -> Date? {
        let datePatterns = [
            #"(\d{4})[-/](\d{2})[-/](\d{2})"#,
            #"(\d{2})[-/](\d{2})[-/](\d{4})"#,
            #"(\d{4})年(\d{1,2})月(\d{1,2})日"#
        ]
        
        for pattern in datePatterns {
            if let range = text.range(of: pattern, options: .regularExpression) {
                let dateString = String(text[range])
                
                // 嘗試解析日期
                let formatters = [
                    "yyyy-MM-dd",
                    "yyyy/MM/dd",
                    "MM/dd/yyyy",
                    "MM-dd-yyyy",
                    "yyyy年MM月dd日"
                ]
                
                for format in formatters {
                    let formatter = DateFormatter()
                    formatter.dateFormat = format
                    formatter.locale = Locale(identifier: "zh_TW")
                    
                    if let date = formatter.date(from: dateString) {
                        return date
                    }
                }
            }
        }
        
        return nil
    }
    
    private func extractTotalAmount(from text: String) -> Double? {
        let amountPatterns = [
            #"總計[：:]\s*[NT$]?(\d+(?:\.\d{2})?)"#,
            #"合計[：:]\s*[NT$]?(\d+(?:\.\d{2})?)"#,
            #"Total[：:]\s*[NT$]?(\d+(?:\.\d{2})?)"#,
            #"小計[：:]\s*[NT$]?(\d+(?:\.\d{2})?)"#
        ]
        
        for pattern in amountPatterns {
            if let range = text.range(of: pattern, options: .regularExpression) {
                let match = String(text[range])
                if let amountRange = match.range(of: #"(\d+(?:\.\d{2})?)"#, options: .regularExpression) {
                    let amountString = String(match[amountRange])
                    return Double(amountString)
                }
            }
        }
        
        return nil
    }
    
    private func extractTaxAmount(from text: String) -> Double? {
        let taxPatterns = [
            #"稅額[：:]\s*[NT$]?(\d+(?:\.\d{2})?)"#,
            #"稅[：:]\s*[NT$]?(\d+(?:\.\d{2})?)"#,
            #"Tax[：:]\s*[NT$]?(\d+(?:\.\d{2})?)"#
        ]
        
        for pattern in taxPatterns {
            if let range = text.range(of: pattern, options: .regularExpression) {
                let match = String(text[range])
                if let amountRange = match.range(of: #"(\d+(?:\.\d{2})?)"#, options: .regularExpression) {
                    let amountString = String(match[amountRange])
                    return Double(amountString)
                }
            }
        }
        
        return nil
    }
    
    private func extractInvoiceItems(from text: String, lines: [String]) -> [InvoiceItem] {
        var items: [InvoiceItem] = []
        let skipKeywords = ["總計", "合計", "小計", "稅", "發票", "統一編號", "統編", "日期", "SUB TOTAL", "TOTAL", "TAX", "INVOICE", "DATE"]
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if trimmed.isEmpty {
                continue
            }
            
            var shouldSkip = false
            for keyword in skipKeywords {
                if trimmed.contains(keyword) {
                    shouldSkip = true
                    break
                }
            }
            
            if shouldSkip {
                continue
            }
            
            // 檢查是否包含金額（通常商品項目會包含價格）
            let amountPattern = #"\d+(?:\.\d{2})?"#
            let hasAmount = trimmed.range(of: amountPattern, options: .regularExpression) != nil
            
            // 商品項目通常長度在 3-50 字符之間
            if trimmed.count >= 3 && trimmed.count <= 50 && hasAmount {
                // 嘗試提取商品名稱和價格
                if let item = parseItemLine(trimmed) {
                    items.append(item)
                }
            }
        }
        
        return items
    }
    
    private func parseItemLine(_ line: String) -> InvoiceItem? {
        // 嘗試不同的解析模式
        let patterns = [
            #"(.+?)\s+(\d+)\s+[NT$]?(\d+(?:\.\d{2})?)"#,  // 商品名稱 數量 價格
            #"(.+?)\s+[NT$]?(\d+(?:\.\d{2})?)"#,          // 商品名稱 價格
            #"(.+?)\s+x\s*(\d+)\s+[NT$]?(\d+(?:\.\d{2})?)"# // 商品名稱 x 數量 價格
        ]
        
        for pattern in patterns {
            if let range = line.range(of: pattern, options: .regularExpression) {
                let match = String(line[range])
                let components = match.components(separatedBy: .whitespaces)
                
                if components.count >= 2 {
                    let name = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
                    let quantity = components.count >= 3 ? Double(components[1]) ?? 1.0 : 1.0
                    let priceIndex = components.count >= 3 ? 2 : 1
                    let price = Double(components[priceIndex]) ?? 0.0
                    
                    if !name.isEmpty && price > 0 {
                        return InvoiceItem(
                            name: name,
                            quantity: quantity,
                            unit: nil,
                            unitPrice: price,
                            amount: price * quantity,
                            taxRate: nil
                        )
                    }
                }
            }
        }
        
        return nil
    }
    
    private func extractSellerInfo(from text: String) -> SellerInfo? {
        // 提取統一編號
        let taxIdPattern = #"統一編號[：:]\s*(\d{8})"#
        var taxId: String?
        
        if let range = text.range(of: taxIdPattern, options: .regularExpression) {
            let match = String(text[range])
            if let idRange = match.range(of: #"(\d{8})"#, options: .regularExpression) {
                taxId = String(match[idRange])
            }
        }
        
        // 提取地址
        let addressPattern = #"地址[：:]\s*([^\n]+)"#
        var address: String?
        
        if let range = text.range(of: addressPattern, options: .regularExpression) {
            address = String(text[range]).replacingOccurrences(of: "地址：", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        if taxId != nil || address != nil {
            return SellerInfo(taxId: taxId, address: address)
        }
        
        return nil
    }
    
    private func extractPaymentMethod(from text: String) -> String? {
        let paymentKeywords = ["現金", "信用卡", "悠遊卡", "一卡通", "LINE Pay", "街口支付", "Apple Pay", "Google Pay", "現金", "Cash", "Credit Card"]
        
        for keyword in paymentKeywords {
            if text.contains(keyword) {
                return keyword
            }
        }
        
        return nil
    }
    
    // MARK: - 完整性檢查
    
    private func validateInvoiceCompleteness(details: InvoiceDetails, type: InvoiceType) -> CompletenessCheck {
        var missingFields: [String] = []
        var confidence: Double = 1.0
        
        // 檢查必要欄位
        if details.merchantName.isEmpty || details.merchantName == "未知商家" {
            missingFields.append("商家名稱")
            confidence -= 0.3
        }
        
        if details.totalAmount == nil {
            missingFields.append("總金額")
            confidence -= 0.4
        }
        
        if details.invoiceDate == nil {
            missingFields.append("發票日期")
            confidence -= 0.2
        }
        
        if details.items.isEmpty {
            missingFields.append("商品明細")
            confidence -= 0.2
        }
        
        // 根據發票類型檢查特定欄位
        switch type {
        case .electronicInvoice, .traditionalInvoice:
            if details.invoiceNumber == nil {
                missingFields.append("發票號碼")
                confidence -= 0.3
            }
        case .receipt, .internationalInvoice:
            // 收據和國際發票對發票號碼要求較低
            break
        }
        
        return CompletenessCheck(
            isValid: missingFields.isEmpty,
            missingFields: missingFields,
            confidence: max(0.0, confidence)
        )
    }
    
    // MARK: - 輔助方法
    
    private func calculateOverallConfidence(_ formatValidation: FormatValidation, _ completenessCheck: CompletenessCheck) -> Double {
        return (formatValidation.confidence + completenessCheck.confidence) / 2.0
    }
    
    private func generateSuggestions(_ formatValidation: FormatValidation, _ completenessCheck: CompletenessCheck) -> [String] {
        var suggestions: [String] = []
        
        if !formatValidation.isValid {
            suggestions.append("發票格式可能不正確，請確保圖片清晰且包含完整的發票資訊")
        }
        
        if !completenessCheck.isValid {
            suggestions.append("發票資訊不完整，建議重新拍攝或手動補充缺失資訊")
        }
        
        if formatValidation.confidence < 0.7 {
            suggestions.append("發票識別信心度較低，建議在光線充足的地方重新拍攝")
        }
        
        return suggestions
    }
}

// MARK: - 資料結構

/// 發票類型
enum InvoiceType: String, Codable, CaseIterable {
    case electronicInvoice = "electronic_invoice"    // 電子發票
    case traditionalInvoice = "traditional_invoice"  // 傳統發票
    case receipt = "receipt"                         // 一般收據
    case internationalInvoice = "international_invoice" // 國際發票
    
    var displayName: String {
        switch self {
        case .electronicInvoice: return "電子發票"
        case .traditionalInvoice: return "統一發票"
        case .receipt: return "收據"
        case .internationalInvoice: return "國際發票"
        }
    }
}

/// 發票驗證結果
struct InvoiceValidationResult: Codable, Identifiable {
    let id: UUID
    let isValid: Bool
    let invoiceType: InvoiceType
    let formatValidation: FormatValidation
    let completenessCheck: CompletenessCheck
    let extractedDetails: InvoiceDetails
    let confidence: Double
    let suggestions: [String]
    let extractedAt: Date
    
    init(isValid: Bool, invoiceType: InvoiceType, formatValidation: FormatValidation, completenessCheck: CompletenessCheck, extractedDetails: InvoiceDetails, confidence: Double, suggestions: [String], extractedAt: Date) {
        self.id = UUID()
        self.isValid = isValid
        self.invoiceType = invoiceType
        self.formatValidation = formatValidation
        self.completenessCheck = completenessCheck
        self.extractedDetails = extractedDetails
        self.confidence = confidence
        self.suggestions = suggestions
        self.extractedAt = extractedAt
    }
}

/// 格式驗證結果
struct FormatValidation: Codable {
    let isValid: Bool
    let issues: [String]
    let confidence: Double
}

/// 完整性檢查結果
struct CompletenessCheck: Codable {
    let isValid: Bool
    let missingFields: [String]
    let confidence: Double
}

/// 發票詳細資訊
struct InvoiceDetails: Codable {
    let merchantName: String
    let invoiceNumber: String?
    let invoiceDate: Date?
    let totalAmount: Double?
    let taxAmount: Double?
    let items: [InvoiceItem]
    let sellerInfo: SellerInfo?
    let paymentMethod: String?
    let rawText: String
}

/// 賣方資訊
struct SellerInfo: Codable {
    let taxId: String?
    let address: String?
}

/// 發票驗證錯誤
enum InvoiceValidationError: LocalizedError {
    case invalidImage
    case textRecognitionFailed
    case formatValidationFailed
    case incompleteData
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "無效的圖片格式"
        case .textRecognitionFailed:
            return "文字識別失敗"
        case .formatValidationFailed:
            return "發票格式驗證失敗"
        case .incompleteData:
            return "發票資料不完整"
        }
    }
}
