//
//  PhotoAccountingManager.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import Foundation
import UIKit
import Vision
import Combine
import NaturalLanguage

// 照片記帳管理器
@MainActor
class PhotoAccountingManager: ObservableObject {
    static let shared = PhotoAccountingManager()
    
    @Published var isProcessing = false
    @Published var extractedData: ExtractedReceiptData?
    @Published var processingError: String?
    @Published var isSupported = true
    
    private let openAIService = OpenAIService.shared
    private let aiOptimizer = AppleNativeAIOptimizer.shared
    private let aiProcessingRouter = AIProcessingRouter.shared
    private let naturalLanguageProcessor = NaturalLanguageProcessor.shared
    private let settingsManager = SettingsManager.shared
    private let qrCodeScanner = QRCodeScanner.shared
    private let invoiceQRCodeParser = InvoiceQRCodeParser.shared
    private let invoiceFormatValidator = InvoiceFormatValidator.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        checkVisionSupport()
    }
    
    // MARK: - 照片處理
    
    /// 處理發票圖片（優先掃描 QR Code）
    func processReceiptImage(_ image: UIImage, source: ImageSource = .unknown) async throws -> ExtractedReceiptData {
        isProcessing = true
        processingError = nil
        extractedData = nil
        
        // 步驟 1: 優先掃描 QR Code
        if let qrCodeData = await tryScanQRCode(from: image) {
            // QR Code 掃描成功，使用 QR Code 資料
            let receiptData = createReceiptDataFromQRCode(qrCodeData)
            
            // 可選：使用國稅局 API 驗證和獲取詳細明細
            if let verifiedData = await tryVerifyWithTaxBureau(qrCodeData) {
                self.extractedData = verifiedData
                self.isProcessing = false
                return verifiedData
            }
            
            self.extractedData = receiptData
            self.isProcessing = false
            return receiptData
        }
        
        // 步驟 2: QR Code 掃描失敗，降級到 OCR + AI 分析
        let originalStrategy = aiProcessingRouter.currentStrategy
        let shouldRestoreStrategy = source == .camera
        
        if shouldRestoreStrategy {
            aiProcessingRouter.updateStrategy(.nativeFirst)
        }
        
        defer {
            if shouldRestoreStrategy {
                aiProcessingRouter.updateStrategy(originalStrategy)
            }
        }
        
        do {
            // 使用智能 AI 處理路由器（OCR + AI 分析）
            let result = try await aiProcessingRouter.processImage(image)
            
            // 確保 OCR 結果設置正確的 dataSource
            var ocrData = result.data
            if ocrData.dataSource == .ocr || ocrData.invoiceNumber == nil {
                // 如果是純 OCR 結果，確保 dataSource 正確
                // 注意：這裡假設 processImage 返回的數據可能沒有設置 dataSource
                // 創建一個新的 ExtractedReceiptData 以確保所有欄位都正確
                let correctedData = ExtractedReceiptData(
                    merchant: ocrData.merchant,
                    amount: ocrData.amount,
                    currency: ocrData.currency,
                    date: ocrData.date,
                    items: ocrData.items,
                    tax: ocrData.tax,
                    total: ocrData.total,
                    paymentMethod: ocrData.paymentMethod,
                    category: ocrData.category,
                    confidence: ocrData.confidence,
                    notes: ocrData.notes,
                    extractedAt: ocrData.extractedAt,
                    invoiceNumber: ocrData.invoiceNumber,
                    randomCode: ocrData.randomCode,
                    sellerTaxId: ocrData.sellerTaxId,
                    invoiceDate: ocrData.invoiceDate,
                    dataSource: .ocr,
                    verificationStatus: .notVerified
                )
                ocrData = correctedData
            }
            
            // 更新狀態
            self.extractedData = ocrData
            isProcessing = false
            
            return ocrData
            
        } catch {
            isProcessing = false
            processingError = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - QR Code 處理
    
    /// 嘗試掃描 QR Code
    private func tryScanQRCode(from image: UIImage) async -> InvoiceQRCodeData? {
        do {
            let scanResults = try await qrCodeScanner.scanQRCodes(from: image)
            
            // 嘗試解析每個 QR Code
            for result in scanResults {
                if let qrCodeData = invoiceQRCodeParser.tryParse(result.content) {
                    return qrCodeData
                }
            }
            
            return nil
        } catch {
            // QR Code 掃描失敗，返回 nil 以觸發 OCR 流程
            return nil
        }
    }
    
    /// 從 QR Code 資料創建 ExtractedReceiptData
    private func createReceiptDataFromQRCode(_ qrCodeData: InvoiceQRCodeData) -> ExtractedReceiptData {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd"
        dateFormatter.locale = Locale(identifier: "zh_TW")
        
        let dateString = dateFormatter.string(from: qrCodeData.date)
        
        // 嘗試從統編查找店家名稱（如果需要）
        let merchantName = qrCodeData.sellerTaxId != nil ? "店家（統編: \(qrCodeData.sellerTaxId!)）" : "未知店家"
        
        // 創建基本的商品項目（從 QR Code 無法獲取詳細明細，需要在確認介面中手動添加）
        let items: [ReceiptItem] = []
        
        return ExtractedReceiptData(
            merchant: merchantName,
            amount: qrCodeData.amount,
            currency: "TWD",
            date: dateString,
            items: items,
            tax: qrCodeData.taxAmount ?? qrCodeData.calculatedTaxAmount,
            total: qrCodeData.amount,
            paymentMethod: "未知",
            category: "其他",
            confidence: 0.95, // QR Code 資料通常很準確
            notes: "從 QR Code 掃描取得",
            invoiceNumber: qrCodeData.invoiceNumber,
            randomCode: qrCodeData.randomCode,
            sellerTaxId: qrCodeData.sellerTaxId,
            invoiceDate: qrCodeData.date,
            dataSource: .qrCode,
            verificationStatus: .notVerified
        )
    }
    
    /// 嘗試使用國稅局 API 驗證和獲取詳細資訊
    private func tryVerifyWithTaxBureau(_ qrCodeData: InvoiceQRCodeData) async -> ExtractedReceiptData? {
        // 檢查是否啟用國稅局 API
        let taxBureauService = TaxBureauService.shared
        
        // 檢查是否有 API Key
        guard taxBureauService.hasAPIKey() else {
            return nil
        }
        
        // 檢查發票號碼和隨機碼是否存在
        guard let invoiceNumber = qrCodeData.invoiceNumber,
              let randomCode = qrCodeData.randomCode else {
            return nil
        }
        
        do {
            // 使用國稅局 API 查詢發票資訊
            let invoiceInfo = try await taxBureauService.queryInvoiceDetail(
                invoiceNumber: invoiceNumber,
                randomCode: randomCode
            )
            
            // 將國稅局 API 的資料轉換為 ExtractedReceiptData
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy/MM/dd"
            dateFormatter.locale = Locale(identifier: "zh_TW")
            let dateString = dateFormatter.string(from: invoiceInfo.invoiceDate)
            
            // 轉換商品項目
            let items = invoiceInfo.items.map { item in
                ReceiptItem(
                    name: item.name,
                    price: item.amount,
                    quantity: Int(item.quantity)
                )
            }
            
            return ExtractedReceiptData(
                merchant: invoiceInfo.sellerName,
                amount: invoiceInfo.amount,
                currency: "TWD",
                date: dateString,
                items: items,
                tax: invoiceInfo.taxAmount,
                total: invoiceInfo.amount,
                paymentMethod: invoiceInfo.paymentMethod ?? "未知",
                category: categorizeByMerchant(invoiceInfo.sellerName),
                confidence: 1.0, // 國稅局 API 資料最準確
                notes: "從國稅局 API 驗證取得",
                invoiceNumber: invoiceInfo.invoiceNumber,
                randomCode: qrCodeData.randomCode,
                sellerTaxId: invoiceInfo.sellerTaxId,
                invoiceDate: invoiceInfo.invoiceDate,
                dataSource: .taxBureau,
                verificationStatus: .verified
            )
            
        } catch {
            // API 查詢失敗，返回 nil（使用 QR Code 資料）
            return nil
        }
    }
    
    /// 根據店家名稱推斷類別
    private func categorizeByMerchant(_ merchantName: String) -> String {
        let lowercased = merchantName.lowercased()
        
        if lowercased.contains("超商") || lowercased.contains("7-11") || lowercased.contains("全家") || lowercased.contains("萊爾富") || lowercased.contains("ok") {
            return "購物"
        } else if lowercased.contains("餐廳") || lowercased.contains("餐廳") || lowercased.contains("咖啡") || lowercased.contains("tea") {
            return "餐飲"
        } else if lowercased.contains("加油站") || lowercased.contains("gas") {
            return "交通"
        } else if lowercased.contains("藥局") || lowercased.contains("醫院") || lowercased.contains("診所") {
            return "醫療"
        } else {
            return "其他"
        }
    }
    
    // 圖片來源類型
    enum ImageSource {
        case camera      // 相機拍攝
        case photoLibrary // 相簿選擇
        case unknown     // 未知來源
    }
    
    // 智能照片處理方法 - 使用混合 AI 策略
    func processReceiptImageWithIntelligentRouting(_ image: UIImage) async throws -> ExtractedReceiptData {
        // 獲取用戶的 AI 偏好設定
        let settings = settingsManager.currentSettings
        let strategy = settings?.aiProcessingStrategy ?? "nativeFirst"
        
        switch strategy {
        case "nativeOnly":
            return try await processWithNativeAIOnly(image)
        case "nativeFirst":
            return try await processWithNativeFirst(image)
        case "openAIFirst":
            return try await processWithOpenAIFirst(image)
        case "hybrid":
            return try await processWithHybridVerification(image)
        case "auto":
            return try await processWithAutoSelection(image)
        default:
            return try await processWithNativeFirst(image)
        }
    }
    
    // 僅使用原生 AI 處理
    private func processWithNativeAIOnly(_ image: UIImage) async throws -> ExtractedReceiptData {
        // 直接使用優化後的原生 AI 提取方法（已經包含完整的數據提取邏輯）
        return try await aiOptimizer.extractReceiptDataWithVision(image)
    }
    
    // 原生 AI 優先處理
    private func processWithNativeFirst(_ image: UIImage) async throws -> ExtractedReceiptData {
        do {
            // 先嘗試原生 AI
            let result = try await processWithNativeAIOnly(image)
            
            // 如果信心度足夠高，直接使用原生 AI 結果
            if result.confidence >= 0.8 {
                return result
            }
        } catch {
            // 原生 AI 失敗，繼續使用 OpenAI
            print("Native AI failed: \(error)")
        }
        
        // 降級到 OpenAI
        return try await processWithOpenAI(image)
    }
    
    // OpenAI 優先處理
    private func processWithOpenAIFirst(_ image: UIImage) async throws -> ExtractedReceiptData {
        do {
            return try await processWithOpenAI(image)
        } catch {
            // OpenAI 失敗，降級到原生 AI
            return try await processWithNativeAIOnly(image)
        }
    }
    
    // 混合驗證處理
    private func processWithHybridVerification(_ image: UIImage) async throws -> ExtractedReceiptData {
        // 同時使用兩種方法
        let nativeResult = try? await processWithNativeAIOnly(image)
        let openAIResult = try? await processWithOpenAI(image)
        
        // 比較結果，選擇更可靠的
        if let nativeResult = nativeResult, let openAIResult = openAIResult {
            // 如果金額差異不大，使用原生 AI 結果（更快）
            if abs(nativeResult.total - openAIResult.total) < 0.01 {
                return nativeResult
            }
        }
        
        // 否則使用 OpenAI 結果
        return try await processWithOpenAI(image)
    }
    
    // 自動選擇處理策略
    private func processWithAutoSelection(_ image: UIImage) async throws -> ExtractedReceiptData {
        // 根據圖片複雜度自動選擇策略
        let complexity = assessImageComplexity(image)
        
        if complexity < 0.5 {
            // 簡單圖片，使用原生 AI
            return try await processWithNativeAIOnly(image)
        } else {
            // 複雜圖片，使用混合策略
            return try await processWithHybridVerification(image)
        }
    }
    
    // 評估圖片複雜度
    private func assessImageComplexity(_ image: UIImage) -> Double {
        let imageSize = image.size.width * image.size.height
        let hasMultipleTextBlocks = true // 簡化實現，實際需要更複雜的檢測
        let hasTables = true // 簡化實現
        
        var complexity: Double = 0.0
        
        // 基於圖片大小
        if imageSize > 2000000 { complexity += 0.3 }
        else if imageSize > 1000000 { complexity += 0.2 }
        else { complexity += 0.1 }
        
        // 基於文字塊數量
        if hasMultipleTextBlocks { complexity += 0.3 }
        
        // 基於表格存在
        if hasTables { complexity += 0.4 }
        
        return min(complexity, 1.0)
    }
    
    // 使用 OpenAI 處理（原有邏輯）
    private func processWithOpenAI(_ image: UIImage) async throws -> ExtractedReceiptData {
        // 1. 預處理圖片
        let processedImage = try preprocessImage(image)
        
        // 2. 使用 Vision Framework 進行文字識別
        let textContent = try await extractTextFromImage(processedImage)
        
        // 3. 使用 GPT-4 Vision 進行智能分析
        return try await analyzeReceiptWithAI(processedImage, textContent: textContent)
    }
    
    // MARK: - 圖片預處理
    
    private func preprocessImage(_ image: UIImage) throws -> UIImage {
        // 調整圖片大小（如果太大）
        let maxSize: CGFloat = 2048
        let resizedImage = image.resized(to: CGSize(width: maxSize, height: maxSize))
        
        // 增強對比度和清晰度
        let enhancedImage = resizedImage.enhancedForOCR()
        
        return enhancedImage
    }
    
    // MARK: - Vision Framework 文字識別
    
    private func extractTextFromImage(_ image: UIImage) async throws -> String {
        // 使用優化後的文字識別
        return try await aiOptimizer.optimizedTextRecognition(for: image)
    }
    
    // MARK: - 原生 AI 輔助方法
    
    // 提取商家名稱
    private func extractMerchantName(from text: String) -> String {
        let lines = text.components(separatedBy: .newlines)
        
        // 尋找可能的商家名稱（通常是第一行或包含特定關鍵詞的行）
        for line in lines.prefix(5) {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedLine.isEmpty && !trimmedLine.contains("$") && !trimmedLine.contains("總計") {
                return trimmedLine
            }
        }
        
        return "未知商家"
    }
    
    // 提取商品項目
    private func extractItems(from text: String) -> [String] {
        let lines = text.components(separatedBy: .newlines)
        var items: [String] = []
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            // 簡單的項目檢測邏輯
            if !trimmedLine.isEmpty && 
               !trimmedLine.contains("總計") && 
               !trimmedLine.contains("稅") && 
               !trimmedLine.contains("小計") &&
               trimmedLine.count > 3 {
                items.append(trimmedLine)
            }
        }
        
        return Array(items.prefix(10)) // 限制最多10個項目
    }
    
    // MARK: - GPT-4 Vision 分析
    
    private func analyzeReceiptWithAI(_ image: UIImage, textContent: String) async throws -> ExtractedReceiptData {
        guard let apiKey = APIKeyManager.shared.getAPIKey(for: "openai") else {
            throw PhotoAccountingError.invalidAPIKey
        }
        
        // 檢查是否可以發送請求
        guard APIKeyManager.shared.canMakeRequest(for: "openai") else {
            throw PhotoAccountingError.rateLimitExceeded
        }
        
        // 將圖片轉換為 base64
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw PhotoAccountingError.imageConversionFailed
        }
        
        let base64Image = imageData.base64EncodedString()
        
        // 構建 GPT-4 Vision 請求
        let _ = VisionAnalysisRequest(
            model: "gpt-4o",
            messages: [
                VisionMessage(
                    role: "user",
                    content: [
                        VisionContent(
                            type: "text",
                            text: buildAnalysisPrompt(textContent: textContent),
                            imageUrl: nil
                        ),
                        VisionContent(
                            type: "image_url",
                            text: nil,
                            imageUrl: VisionImageUrl(url: "data:image/jpeg;base64,\(base64Image)")
                        )
                    ]
                )
            ],
            maxTokens: 1000,
            temperature: 0.1
        )
        
        let response = try await openAIService.analyzeReceipt(
            imageData: imageData,
            apiKey: apiKey
        )
        
        // 解析 AI 回應
        let extractedData = try parseAIResponse(response.description ?? "")
        
        // 追蹤 API 使用量
        let estimatedTokens = estimateTokensForVision(image: image, textLength: textContent.count)
        APIKeyManager.shared.trackAPIUsage(for: "openai", tokens: estimatedTokens, cost: calculateVisionCost(tokens: estimatedTokens))
        
        return extractedData
    }
    
    private func buildAnalysisPrompt(textContent: String) -> String {
        return """
        Please analyze this receipt/invoice image and extract the following financial information:
        
        Extracted text: "\(textContent)"
        
        Please provide a JSON response with the following structure:
        {
            "merchant": "Store/Company name",
            "amount": 123.45,
            "currency": "USD",
            "date": "2024-01-01",
            "items": [
                {
                    "name": "Item name",
                    "price": 12.34,
                    "quantity": 1
                }
            ],
            "tax": 10.00,
            "total": 123.45,
            "paymentMethod": "Credit Card",
            "category": "Food & Dining",
            "confidence": 0.95,
            "notes": "Additional observations"
        }
        
        Rules:
        1. Extract all numerical values accurately
        2. Identify the merchant name clearly
        3. Parse the date in YYYY-MM-DD format
        4. Categorize the transaction appropriately
        5. Provide confidence score (0-1)
        6. If any information is unclear, mark as null
        7. Focus on financial transaction data only
        """
    }
    
    private func parseAIResponse(_ response: String) throws -> ExtractedReceiptData {
        // 嘗試解析 JSON 回應
        guard let data = response.data(using: .utf8) else {
            throw PhotoAccountingError.invalidResponse
        }
        
        do {
            let extractedData = try JSONDecoder().decode(ExtractedReceiptData.self, from: data)
            return extractedData
        } catch {
            // 如果 JSON 解析失敗，嘗試從文字中提取信息
            return try extractDataFromText(response)
        }
    }
    
    private func extractDataFromText(_ text: String) throws -> ExtractedReceiptData {
        // 使用正則表達式從文字中提取信息
        let merchantPattern = #"merchant["\s]*:[\s]*["']([^"']+)["']"#
        let amountPattern = #"amount["\s]*:[\s]*(\d+\.?\d*)"#
        let datePattern = #"date["\s]*:[\s]*["'](\d{4}-\d{2}-\d{2})["']"#
        
        let merchant = extractValue(from: text, pattern: merchantPattern) ?? "Unknown Merchant"
        let amountString = extractValue(from: text, pattern: amountPattern) ?? "0"
        let amount = Double(amountString) ?? 0.0
        let dateString = extractValue(from: text, pattern: datePattern) ?? Date().formatted(.iso8601.day().month().year())
        
        return ExtractedReceiptData(
            merchant: merchant,
            amount: amount,
            currency: "USD",
            date: dateString,
            items: [],
            tax: 0.0,
            total: amount,
            paymentMethod: "Unknown",
            category: "Other",
            confidence: 0.7,
            notes: "Extracted from text analysis"
        )
    }
    
    private func extractValue(from text: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return nil
        }
        
        let range = NSRange(location: 0, length: text.utf16.count)
        guard let match = regex.firstMatch(in: text, options: [], range: range) else {
            return nil
        }
        
        guard let range = Range(match.range(at: 1), in: text) else {
            return nil
        }
        
        return String(text[range])
    }
    
    // MARK: - 支援檢查
    
    private func checkVisionSupport() {
        // 檢查是否有 API Key
        guard APIKeyManager.shared.getAPIKey(for: "openai") != nil else {
            isSupported = false
            return
        }
        
        // 檢查訂閱等級是否支援視覺功能
        let subscriptionTier = StoreKitManager.shared.currentSubscription
        isSupported = subscriptionTier != .free
    }
    
    // MARK: - 成本計算
    
    private func estimateTokensForVision(image: UIImage, textLength: Int) -> Int {
        // GPT-4 Vision 的 token 估算
        let imageTokens = estimateImageTokens(image: image)
        let textTokens = textLength / 4 // 大約每4個字符1個token
        return imageTokens + textTokens + 100 // 加上提示詞的token
    }
    
    private func estimateImageTokens(image: UIImage) -> Int {
        // 基於圖片大小估算token
        let imageSize = image.size
        let pixelCount = imageSize.width * imageSize.height
        
        if pixelCount <= 1024 * 1024 {
            return 85 // 小圖片
        } else if pixelCount <= 2048 * 2048 {
            return 170 // 中等圖片
        } else {
            return 255 // 大圖片
        }
    }
    
    private func calculateVisionCost(tokens: Int) -> Double {
        // GPT-4 Vision 定價：$0.01 per 1K tokens
        return Double(tokens) / 1000.0 * 0.01
    }
    
    // MARK: - 批次處理
    
    func processMultipleImages(_ images: [UIImage]) async throws -> [ExtractedReceiptData] {
        var results: [ExtractedReceiptData] = []
        
        for image in images {
            let extractedData = try await processReceiptImage(image)
            results.append(extractedData)
        }
        
        return results
    }
    
    // MARK: - 歷史記錄
    
    func saveExtractionHistory(_ data: ExtractedReceiptData) {
        var history = getExtractionHistory()
        history.append(data)
        
        // 只保留最近50條記錄
        if history.count > 50 {
            history = Array(history.suffix(50))
        }
        
        if let encoded = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(encoded, forKey: "extraction_history")
        }
    }
    
    func getExtractionHistory() -> [ExtractedReceiptData] {
        guard let data = UserDefaults.standard.data(forKey: "extraction_history"),
              let history = try? JSONDecoder().decode([ExtractedReceiptData].self, from: data) else {
            return []
        }
        return history
    }
    
    func clearExtractionHistory() {
        UserDefaults.standard.removeObject(forKey: "extraction_history")
    }
}

// MARK: - 資料結構

/// 資料來源類型
enum DataSource: String, Codable {
    case qrCode = "qrCode"
    case ocr = "ocr"
    case hybrid = "hybrid"
    case taxBureau = "taxBureau"
}

/// 驗證狀態
enum VerificationStatus: String, Codable {
    case notVerified = "notVerified"
    case verified = "verified"
    case verifying = "verifying"
    case verificationFailed = "verificationFailed"
}

struct ExtractedReceiptData: Codable, Identifiable {
    let id: UUID
    let merchant: String
    let amount: Double
    let currency: String
    let date: String
    let items: [ReceiptItem]
    let tax: Double
    let total: Double
    let paymentMethod: String
    let category: String
    let confidence: Double
    let notes: String
    let extractedAt: Date
    
    // 新增欄位
    let invoiceNumber: String?           // 發票號碼
    let randomCode: String?             // 隨機碼
    let sellerTaxId: String?            // 店家統編
    let invoiceDate: Date?               // 發票日期（Date 類型）
    let dataSource: DataSource          // 資料來源
    let verificationStatus: VerificationStatus  // 驗證狀態
    
    init(merchant: String, amount: Double, currency: String, date: String, items: [ReceiptItem], tax: Double, total: Double, paymentMethod: String, category: String, confidence: Double, notes: String, extractedAt: Date = Date(), invoiceNumber: String? = nil, randomCode: String? = nil, sellerTaxId: String? = nil, invoiceDate: Date? = nil, dataSource: DataSource = .ocr, verificationStatus: VerificationStatus = .notVerified) {
        self.id = UUID()
        self.merchant = merchant
        self.amount = amount
        self.currency = currency
        self.date = date
        self.items = items
        self.tax = tax
        self.total = total
        self.paymentMethod = paymentMethod
        self.category = category
        self.confidence = confidence
        self.notes = notes
        self.extractedAt = extractedAt
        self.invoiceNumber = invoiceNumber
        self.randomCode = randomCode
        self.sellerTaxId = sellerTaxId
        self.invoiceDate = invoiceDate
        self.dataSource = dataSource
        self.verificationStatus = verificationStatus
    }
}

struct ReceiptItem: Codable {
    let name: String
    let price: Double
    let quantity: Int
}

// Vision API 資料結構
struct VisionAnalysisRequest: Codable {
    let model: String
    let messages: [VisionMessage]
    let maxTokens: Int?
    let temperature: Double?
}

// VisionMessage 和 VisionContent 已移至 OpenAIService.swift

// VisionImageUrl 已移至 OpenAIService.swift

struct VisionAnalysisResponse: Codable {
    let choices: [VisionChoice]
}

// VisionChoice 和 VisionResponseMessage 已移至 OpenAIService.swift

// MARK: - 錯誤定義

enum PhotoAccountingError: LocalizedError {
    case invalidImage
    case textRecognitionFailed
    case invalidAPIKey
    case rateLimitExceeded
    case imageConversionFailed
    case invalidResponse
    case unsupportedImageFormat
    case processingTimeout
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "無效的圖片格式"
        case .textRecognitionFailed:
            return "文字識別失敗"
        case .invalidAPIKey:
            return "無效的 API 金鑰"
        case .rateLimitExceeded:
            return "API 使用量超限"
        case .imageConversionFailed:
            return "圖片轉換失敗"
        case .invalidResponse:
            return "無效的回應"
        case .unsupportedImageFormat:
            return "不支援的圖片格式"
        case .processingTimeout:
            return "處理超時"
        }
    }
}
