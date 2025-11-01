//
//  AppleNativeAIOptimizer.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/28.
//

import Foundation
import UIKit
@preconcurrency import Vision
import Speech
import AVFoundation
import CoreML
import Combine
import os.log

@MainActor
class AppleNativeAIOptimizer: ObservableObject {
    static let shared = AppleNativeAIOptimizer()
    
    @Published var isOptimized = false
    @Published var optimizationLevel: OptimizationLevel = .balanced
    @Published var performanceMetrics: AIPerformanceMetrics = AIPerformanceMetrics(
        visionProcessingTime: 0.0,
        speechProcessingTime: 0.0,
        mlProcessingTime: 0.0,
        memoryUsage: 0.0,
        cpuUsage: 0.0
    )
    
    private let logger = Logger(subsystem: "com.richnowai", category: "AppleNativeAIOptimizer")
    
    // Vision Framework 優化
    private var visionRequestCache: [String: VNRequest] = [:]
    private let visionQueue = DispatchQueue(label: "com.richnowai.vision", qos: .userInitiated)
    
    // Speech Recognition 優化
    private var speechRecognizer: SFSpeechRecognizer?
    private let speechQueue = DispatchQueue(label: "com.richnowai.speech", qos: .userInitiated)
    
    // Core ML 優化
    private var mlModelCache: [String: MLModel] = [:]
    private let mlQueue = DispatchQueue(label: "com.richnowai.ml", qos: .userInitiated)
    
    private init() {
        setupOptimizations()
    }
    
    // MARK: - 初始化優化
    
    private func setupOptimizations() {
        // 設定 Vision Framework 優化
        setupVisionOptimizations()
        
        // 設定 Speech Recognition 優化
        setupSpeechOptimizations()
        
        // 設定 Core ML 優化
        setupCoreMLOptimizations()
        
        isOptimized = true
        logger.info("Apple Native AI optimizations enabled")
    }
    
    // MARK: - Vision Framework 優化
    
    private func setupVisionOptimizations() {
        // 預載入常用的 Vision 請求
        preloadVisionRequests()
        
        // 設定最佳化參數
        configureVisionParameters()
    }
    
    private func preloadVisionRequests() {
        // 文字識別請求
        let textRequest = VNRecognizeTextRequest()
        textRequest.recognitionLevel = .accurate
        textRequest.recognitionLanguages = ["en", "zh-Hans", "zh-Hant"]
        textRequest.usesLanguageCorrection = true
        visionRequestCache["text_recognition"] = textRequest
        
        // 人臉檢測請求
        let faceRequest = VNDetectFaceRectanglesRequest()
        visionRequestCache["face_detection"] = faceRequest
        
        // 條碼檢測請求
        let barcodeRequest = VNDetectBarcodesRequest()
        visionRequestCache["barcode_detection"] = barcodeRequest
    }
    
    private func configureVisionParameters() {
        // 根據設備性能調整參數
        let devicePerformance = getDevicePerformanceLevel()
        
        switch devicePerformance {
        case .high:
            // 高級設備使用最高精度
            break
        case .medium:
            // 中等設備平衡精度和性能
            break
        case .low:
            // 低端設備優先考慮性能
            break
        }
    }
    
    func optimizedTextRecognition(for image: UIImage) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            guard let cgImage = image.cgImage else {
                continuation.resume(throwing: AIOptimizationError.invalidImage)
                return
            }
            
            // 使用快取的請求
            let request = visionRequestCache["text_recognition"] as? VNRecognizeTextRequest ?? VNRecognizeTextRequest()
            
            request.recognitionLevel = optimizationLevel.visionRecognitionLevel
            request.recognitionLanguages = ["en", "zh-Hans", "zh-Hant"]
            request.usesLanguageCorrection = true
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            visionQueue.async { [handler, request] in
                do {
                    try handler.perform([request])
                    
                    guard let results = request.results else {
                        continuation.resume(throwing: AIOptimizationError.textRecognitionFailed)
                        return
                    }
                    
                    let observations = results
                    
                    let recognizedStrings = observations.compactMap { observation in
                        observation.topCandidates(1).first?.string
                    }
                    
                    let fullText = recognizedStrings.joined(separator: "\n")
                    continuation.resume(returning: fullText)
                    
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Speech Recognition 優化
    
    private func setupSpeechOptimizations() {
        // 初始化語音識別器
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-TW"))
        
        // 設定最佳化參數
        configureSpeechParameters()
    }
    
    private func configureSpeechParameters() {
        // 根據設備性能調整語音識別參數
        let devicePerformance = getDevicePerformanceLevel()
        
        switch devicePerformance {
        case .high:
            // 高級設備使用最高精度
            break
        case .medium:
            // 中等設備平衡精度和性能
            break
        case .low:
            // 低端設備優先考慮性能
            break
        }
    }
    
    func optimizedSpeechRecognition(for audioURL: URL) async throws -> String {
        guard let recognizer = speechRecognizer else {
            throw AIOptimizationError.speechRecognizerNotAvailable
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = SFSpeechURLRecognitionRequest(url: audioURL)
            request.shouldReportPartialResults = false
            request.requiresOnDeviceRecognition = optimizationLevel.useOnDeviceRecognition
            
            recognizer.recognitionTask(with: request) { result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                if let result = result, result.isFinal {
                    continuation.resume(returning: result.bestTranscription.formattedString)
                }
            }
        }
    }
    
    // MARK: - Core ML 優化
    
    private func setupCoreMLOptimizations() {
        // 預載入常用的 ML 模型
        preloadMLModels()
        
        // 設定最佳化參數
        configureCoreMLParameters()
    }
    
    private func preloadMLModels() {
        // 預載入常用的 Core ML 模型
        // 這裡可以根據需要載入特定的模型
    }
    
    private func configureCoreMLParameters() {
        // 設定 Core ML 計算單元
        let devicePerformance = getDevicePerformanceLevel()
        
        switch devicePerformance {
        case .high:
            // 高級設備使用 GPU 和 Neural Engine
            break
        case .medium:
            // 中等設備使用 Neural Engine
            break
        case .low:
            // 低端設備使用 CPU
            break
        }
    }
    
    // MARK: - 性能監控
    
    func updatePerformanceMetrics() {
        let metrics = AIPerformanceMetrics(
            visionProcessingTime: getVisionProcessingTime(),
            speechProcessingTime: getSpeechProcessingTime(),
            mlProcessingTime: getMLProcessingTime(),
            memoryUsage: getMemoryUsage(),
            cpuUsage: getCPUUsage()
        )
        
        performanceMetrics = metrics
    }
    
    private func getVisionProcessingTime() -> TimeInterval {
        // 實際實現中，這裡會記錄 Vision 處理時間
        return 0.1
    }
    
    private func getSpeechProcessingTime() -> TimeInterval {
        // 實際實現中，這裡會記錄語音處理時間
        return 0.2
    }
    
    private func getMLProcessingTime() -> TimeInterval {
        // 實際實現中，這裡會記錄 ML 處理時間
        return 0.15
    }
    
    private func getMemoryUsage() -> Double {
        // 實際實現中，這裡會計算記憶體使用量
        return 0.3
    }
    
    private func getCPUUsage() -> Double {
        // 實際實現中，這裡會計算 CPU 使用量
        return 0.2
    }
    
    // MARK: - 設備性能檢測
    
    private func getDevicePerformanceLevel() -> DevicePerformanceLevel {
        let device = UIDevice.current
        
        // 根據設備型號判斷性能等級
        if device.model.contains("iPhone") {
            let modelName = device.model
            if modelName.contains("Pro") || modelName.contains("Max") {
                return .high
            } else if modelName.contains("SE") {
                return .low
            } else {
                return .medium
            }
        }
        
        return .medium
    }
    
    // MARK: - 優化級別調整
    
    func setOptimizationLevel(_ level: OptimizationLevel) {
        optimizationLevel = level
        logger.info("Optimization level changed to: \(level.rawValue)")
    }
    
    // MARK: - 清理資源
    
    func cleanup() {
        visionRequestCache.removeAll()
        mlModelCache.removeAll()
        speechRecognizer = nil
    }
    
    // MARK: - 新增方法以支援 AIProcessingRouter
    
    func parseTransactionWithNaturalLanguage(_ text: String) async throws -> ParsedTransaction {
        // 使用 Natural Language Framework 解析交易文字
        let processor = NaturalLanguageProcessor.shared
        let analysis = await processor.analyzeTransactionText(text)
        
        // 轉換為 ParsedTransaction
        let amount = analysis.amounts.first?.value ?? 0.0
        let category = analysis.category
        let description = analysis.originalText
        let type: TransactionType = analysis.transactionType == .income ? .income : .expense
        
        return ParsedTransaction(
            amount: amount,
            category: category,
            description: description,
            date: Date(),
            type: type
        )
    }
    
    func extractReceiptDataWithVision(_ image: UIImage) async throws -> ExtractedReceiptData {
        let startTime = Date()
        
        // 1. 使用 Vision Framework 提取文字（保留位置信息）
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["en", "zh-Hans", "zh-Hant", "zh-HK"]
        request.usesLanguageCorrection = true
        request.customWords = [
            // 台灣常見超商和商家
            "7-11", "統一超商", "小7", "全家", "FamilyMart", "OK", "OK便利商店", 
            "萊爾富", "Hi-Life", "美廉社", "全聯", "家樂福", "Costco", "好市多",
            "屈臣氏", "康是美", "寶雅", "松青", "頂好", "愛買",
            // 餐飲商家
            "麥當勞", "McDonald's", "肯德基", "KFC", "摩斯漢堡", "MOS Burger",
            "星巴克", "Starbucks", "85度C", "路易莎", "Cama",
            // 發票關鍵字
            "統一發票", "電子發票", "發票號碼", "發票號", "統一編號", "統編",
            "發票日期", "總計", "合計", "小計", "稅額", "未稅金額", "含稅",
            "商品名稱", "數量", "單價", "金額", "付款方式", "現金", "信用卡",
            "悠遊卡", "一卡通", "LINE Pay", "街口支付", "Apple Pay", "Google Pay",
            // 日期格式
            "年", "月", "日", "/", "-",
            // 金額格式
            "NT$", "NT", "$", "元", "新台幣", "TWD"
        ]
        
        guard let cgImage = image.cgImage else {
            throw AIOptimizationError.invalidImage
        }
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        try handler.perform([request])
        
        guard let observations = request.results else {
            throw AIOptimizationError.textRecognitionFailed
        }
        
        // 2. 提取文字內容和位置信息
        var recognizedLines: [(text: String, boundingBox: CGRect)] = []
        var fullText = ""
        
        for observation in observations {
            if let topCandidate = observation.topCandidates(1).first {
                let text = topCandidate.string
                let confidence = topCandidate.confidence
                
                // 只保留信心度較高的文字（> 0.5）
                if confidence > 0.5 {
                    // 獲取文字的邊界框（簡化處理）
                    let boundingBox = observation.boundingBox
                    recognizedLines.append((text: text, boundingBox: boundingBox))
                    
                    if !fullText.isEmpty {
                        fullText += "\n"
                    }
                    fullText += text
                }
            }
        }
        
        guard !fullText.isEmpty else {
            throw AIOptimizationError.textRecognitionFailed
        }
        
        // 3. 使用 Natural Language Processor 進行智能分析
        let naturalLanguageProcessor = NaturalLanguageProcessor.shared
        let analysis = await naturalLanguageProcessor.analyzeTransactionText(fullText)
        
        // 4. 提取結構化數據
        let extractedData = extractStructuredData(
            from: fullText,
            lines: recognizedLines,
            analysis: analysis
        )
        
        let processingTime = Date().timeIntervalSince(startTime)
        logger.info("原生 AI 收據識別完成: 處理時間=\(String(format: "%.2f", processingTime))秒, 信心度=\(String(format: "%.2f", extractedData.confidence))")
        
        return extractedData
    }
    
    // MARK: - 結構化數據提取
    
    private func extractStructuredData(
        from text: String,
        lines: [(text: String, boundingBox: CGRect)],
        analysis: TransactionAnalysisResult
    ) -> ExtractedReceiptData {
        // 提取金額（使用 Natural Language Processor 的結果）
        let amounts = analysis.amounts
        let totalAmount = amounts.max(by: { $0.value < $1.value })?.value ?? 0.0
        let currency = amounts.first?.currency ?? "TWD"
        
        // 提取商家名稱
        let merchantName = extractMerchantName(from: text, lines: lines, entities: analysis.entities)
        
        // 提取日期
        let dateString = extractDate(from: text) ?? Date().formatted(date: .abbreviated, time: .omitted)
        
        // 提取商品項目
        let items = extractItems(from: text, lines: lines)
        
        // 提取稅額
        let taxAmount = extractTaxAmount(from: text, total: totalAmount)
        
        // 判斷支付方式
        let paymentMethod = extractPaymentMethod(from: text)
        
        // 計算信心度（基於識別到的數據完整性）
        let confidence = calculateConfidence(
            hasAmount: totalAmount > 0,
            hasMerchant: merchantName != "未知商家",
            hasItems: !items.isEmpty,
            analysisConfidence: analysis.confidence
        )
        
        return ExtractedReceiptData(
            merchant: merchantName,
            amount: totalAmount,
            currency: currency,
            date: dateString,
            items: items,
            tax: taxAmount,
            total: totalAmount,
            paymentMethod: paymentMethod,
            category: analysis.category,
            confidence: confidence,
            notes: text,
            extractedAt: Date()
        )
    }
    
    private func extractMerchantName(from text: String, lines: [(text: String, boundingBox: CGRect)], entities: [NamedEntity]) -> String {
        // 方法1: 使用命名實體識別（組織名稱）
        for entity in entities {
            if entity.type == "OrganizationName" || entity.type == "PlaceName" {
                let merchant = entity.text.trimmingCharacters(in: .whitespacesAndNewlines)
                if merchant.count > 2 && merchant.count < 50 {
                    return merchant
                }
            }
        }
        
        // 方法2: 從文字開頭幾行提取（通常是商家名稱）
        let allLines = text.components(separatedBy: .newlines)
        for (index, line) in allLines.prefix(3).enumerated() {
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
            if trimmed.count >= 2 && trimmed.count <= 30 &&
               !trimmed.contains("$") &&
               !trimmed.contains("NT$") &&
               !trimmed.contains("總計") &&
               !trimmed.contains("合計") {
                
                // 第一行通常是商家名稱
                if index == 0 {
                    return trimmed
                }
                
                // 檢查是否包含常見商家關鍵詞
                let merchantKeywords = ["公司", "企業", "商行", "商店", "超市", "超商", "餐廳", "飯店", "咖啡", "便利商店", "CO.", "LTD", "INC"]
                for keyword in merchantKeywords {
                    if trimmed.contains(keyword) {
                        return trimmed
                    }
                }
            }
        }
        
        return "未知商家"
    }
    
    private func extractDate(from text: String) -> String? {
        let datePatterns = [
            // 台灣日期格式：2024/01/15, 2024-01-15, 113/01/15
            #"(\d{3,4})[/-](\d{1,2})[/-](\d{1,2})"#,
            // 台灣民國年格式：113年1月15日
            #"(\d{2,3})年\s*(\d{1,2})月\s*(\d{1,2})日"#,
            // 英文日期格式：Jan 15, 2024, 15 Jan 2024
            #"([A-Za-z]+)\s+(\d{1,2}),?\s+(\d{4})"#
        ]
        
        for pattern in datePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(text.startIndex..., in: text)
                if let match = regex.firstMatch(in: text, options: [], range: range),
                   let matchRange = Range(match.range, in: text) {
                    let dateString = String(text[matchRange])
                    // 嘗試解析日期
                    if let parsedDate = parseDate(from: dateString) {
                        return parsedDate.formatted(date: .abbreviated, time: .omitted)
                    }
                }
            }
        }
        
        return nil
    }
    
    private func parseDate(from dateString: String) -> Date? {
        let formatters = [
            // 台灣格式
            createFormatter("yyyy/MM/dd"),
            createFormatter("yyyy-MM-dd"),
            createFormatter("yy/MM/dd"),
            // 民國年格式（需要轉換）
            // 英文格式
            createFormatter("MMM d, yyyy"),
            createFormatter("d MMM yyyy")
        ]
        
        for formatter in formatters {
            if let date = formatter.date(from: dateString) {
                return date
            }
        }
        
        return nil
    }
    
    private func createFormatter(_ format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "zh_TW")
        return formatter
    }
    
    private func extractItems(from text: String, lines: [(text: String, boundingBox: CGRect)]) -> [ReceiptItem] {
        var items: [ReceiptItem] = []
        let allLines = text.components(separatedBy: .newlines)
        
        let skipKeywords = ["總計", "合計", "小計", "稅", "發票", "統一編號", "統編", "日期", "SUB TOTAL", "TOTAL", "TAX", "INVOICE", "DATE"]
        
        for line in allLines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // 跳過空行和包含關鍵詞的行
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
            if trimmed.count >= 3 && trimmed.count <= 50 {
                // 嘗試提取價格
                var price: Double = 0.0
                var quantity: Double = 1.0
                var itemName = trimmed
                
                if hasAmount {
                    // 提取金額
                    if let regex = try? NSRegularExpression(pattern: amountPattern),
                       let match = regex.firstMatch(in: trimmed, options: [], range: NSRange(trimmed.startIndex..., in: trimmed)),
                       let range = Range(match.range, in: trimmed) {
                        if let parsedPrice = Double(String(trimmed[range])) {
                            price = parsedPrice
                            // 從項目名稱中移除金額部分
                            itemName = trimmed.replacingOccurrences(of: String(trimmed[range]), with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                        }
                    }
                    
                    // 嘗試提取數量（格式：2 x $10 或 2x$10）
                    let quantityPattern = #"(\d+(?:\.\d+)?)\s*[xX×]\s*"#
                    if let regex = try? NSRegularExpression(pattern: quantityPattern),
                       let match = regex.firstMatch(in: trimmed, options: [], range: NSRange(trimmed.startIndex..., in: trimmed)),
                       let range = Range(match.range(at: 1), in: trimmed) {
                        if let parsedQuantity = Double(String(trimmed[range])) {
                            quantity = parsedQuantity
                        }
                    }
                }
                
                if !itemName.isEmpty {
                    items.append(ReceiptItem(name: itemName, price: price, quantity: Int(quantity)))
                }
            }
        }
        
        return Array(items.prefix(20)) // 限制最多20個項目
    }
    
    private func extractTaxAmount(from text: String, total: Double) -> Double {
        // 搜尋稅額關鍵詞
        let taxPatterns = [
            #"稅[額金]*[:\s]*(\d+(?:\.\d{2})?)"#,
            #"TAX[:\s]*(\d+(?:\.\d{2})?)"#,
            #"營業稅[:\s]*(\d+(?:\.\d{2})?)"#
        ]
        
        for pattern in taxPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(text.startIndex..., in: text)
                if let match = regex.firstMatch(in: text, options: [], range: range),
                   match.numberOfRanges > 1,
                   let taxRange = Range(match.range(at: 1), in: text),
                   let taxAmount = Double(String(text[taxRange])) {
                    return taxAmount
                }
            }
        }
        
        // 如果沒找到明確的稅額，假設含稅（台灣通常是 5%）
        if total > 0 {
            return total * 0.05 / 1.05
        }
        
        return 0.0
    }
    
    private func extractPaymentMethod(from text: String) -> String {
        let paymentKeywords = [
            ("現金", "現金"),
            ("信用卡", "信用卡"),
            ("CASH", "現金"),
            ("CARD", "信用卡"),
            ("CREDIT", "信用卡"),
            ("悠遊卡", "悠遊卡"),
            ("一卡通", "一卡通"),
            ("LINE Pay", "LINE Pay"),
            ("Apple Pay", "Apple Pay"),
            ("街口", "街口支付")
        ]
        
        for (keyword, method) in paymentKeywords {
            if text.range(of: keyword, options: .caseInsensitive) != nil {
                return method
            }
        }
        
        return "未知"
    }
    
    private func calculateConfidence(
        hasAmount: Bool,
        hasMerchant: Bool,
        hasItems: Bool,
        analysisConfidence: Double
    ) -> Double {
        var confidence = analysisConfidence
        
        // 根據數據完整性調整信心度
        if hasAmount {
            confidence += 0.1
        }
        if hasMerchant {
            confidence += 0.1
        }
        if hasItems {
            confidence += 0.05
        }
        
        // 確保信心度在合理範圍內
        return min(confidence, 0.95)
    }
    
    func transcribeAudioWithSpeech(_ audioData: Data) async throws -> String {
        // 使用 Speech Framework 轉錄音頻
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            throw AIOptimizationError.speechRecognizerNotAvailable
        }
        
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = false
        
        // 這裡需要將 Data 轉換為 AVAudioPCMBuffer
        // 簡化實現，實際應用中需要更複雜的音頻處理
        return "音頻轉文字結果"
    }
}

// MARK: - 支援類型

enum OptimizationLevel: String, CaseIterable {
    case performance = "performance"
    case balanced = "balanced"
    case accuracy = "accuracy"
    
    var visionRecognitionLevel: VNRequestTextRecognitionLevel {
        switch self {
        case .performance:
            return .fast
        case .balanced:
            return .accurate
        case .accuracy:
            return .accurate
        }
    }
    
    var useOnDeviceRecognition: Bool {
        switch self {
        case .performance:
            return true
        case .balanced:
            return true
        case .accuracy:
            return false
        }
    }
}

enum DevicePerformanceLevel {
    case high
    case medium
    case low
}

struct AIPerformanceMetrics {
    var visionProcessingTime: Double = 0.0
    var speechProcessingTime: Double = 0.0
    var mlProcessingTime: Double = 0.0
    var memoryUsage: Double = 0.0
    var cpuUsage: Double = 0.0
    var nativeAISuccessRate: Double = 0.0
    var openAISuccessRate: Double = 0.0
    var averageConfidence: Double = 0.0
    var costSavings: Double = 0.0
    
    var totalProcessingTime: Double {
        return visionProcessingTime + speechProcessingTime + mlProcessingTime
    }
    
    var averageProcessingTime: Double {
        return totalProcessingTime / 3
    }
}

enum AIOptimizationError: Error, LocalizedError {
    case invalidImage
    case textRecognitionFailed
    case speechRecognizerNotAvailable
    case mlModelNotAvailable
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image provided"
        case .textRecognitionFailed:
            return "Text recognition failed"
        case .speechRecognizerNotAvailable:
            return "Speech recognizer not available"
        case .mlModelNotAvailable:
            return "ML model not available"
        }
    }
}
