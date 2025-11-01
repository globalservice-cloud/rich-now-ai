//
//  TransactionParser.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import Foundation
import Combine
import SwiftData
import NaturalLanguage

// 交易解析錯誤類型
enum TransactionParserError: Error, LocalizedError {
    case offlineParsingFailed
    case invalidInput
    case parsingTimeout
    
    var errorDescription: String? {
        switch self {
        case .offlineParsingFailed:
            return "離線模式下無法解析此交易，請使用更簡單的格式或等待網路恢復"
        case .invalidInput:
            return "無效的輸入格式"
        case .parsingTimeout:
            return "解析超時，請重試"
        }
    }
}

// 解析後的交易資料
struct ParsedTransaction {
    let amount: Double
    let category: String
    let description: String
    let date: Date
    let type: TransactionType
}

// 交易解析器
@MainActor
class TransactionParser: ObservableObject {
    private let openAIService: OpenAIService
    private let aiProcessingRouter: AIProcessingRouter
    private let naturalLanguageProcessor: NaturalLanguageProcessor
    private let settingsManager: SettingsManager
    
    init(openAIService: OpenAIService? = nil) {
        self.openAIService = openAIService ?? OpenAIService.shared
        self.aiProcessingRouter = AIProcessingRouter.shared
        self.naturalLanguageProcessor = NaturalLanguageProcessor.shared
        self.settingsManager = SettingsManager.shared
    }
    
    func parseTransaction(from message: String) async throws -> ParsedTransaction {
        // 使用智能 AI 處理路由器
        let result = try await aiProcessingRouter.processTransaction(message)
        
        // 返回解析結果
        return result.data
    }
    
    // 解析多筆交易（新增功能）
    func parseMultipleTransactions(from message: String) async throws -> [ParsedTransaction] {
        // 首先嘗試使用本地規則解析多筆交易
        let localTransactions = extractMultipleTransactions(from: message)
        if localTransactions.count > 1 {
            return localTransactions
        }
        
        // 如果本地解析失敗或只有一筆，嘗試使用 AI 解析
        // 檢查是否可能包含多筆交易（通過關鍵字和格式判斷）
        if hasMultipleTransactionIndicators(message) {
            // 使用 AI 解析多筆交易
            do {
                let aiResult = try await parseMultipleTransactionsWithAI(message)
                if aiResult.count > 1 {
                    return aiResult
                }
            } catch {
                // AI 解析失敗，回退到本地解析
                if localTransactions.count > 0 {
                    return localTransactions
                }
            }
        }
        
        // 如果沒有多筆交易，返回單筆交易（使用本地解析結果或調用單筆解析）
        if localTransactions.count == 1 {
            return localTransactions
        }
        
        let singleTransaction = try await parseTransaction(from: message)
        return [singleTransaction]
    }
    
    // 檢測是否可能包含多筆交易
    private func hasMultipleTransactionIndicators(_ message: String) -> Bool {
        // 多筆交易常見指示符
        let multipleIndicators = [
            // 分隔符
            "\n", "，", ",", "；", ";", "|", "&",
            // 連接詞
            "和", "以及", "還有", "另外", "此外", "加上", "然後", "還有", "再",
            // 數量詞
            "第一", "第二", "第三", "一", "二", "三",
            // 多筆標記
            "筆", "個", "項", "次"
        ]
        
        // 檢查是否包含多個金額
        let amountPattern = "\\d+(?:\\.\\d+)?\\s*(元|塊|錢|dollars?|\\$|USD|TWD|NT\\$)"
        let range = NSRange(location: 0, length: message.utf16.count)
        let regex = try? NSRegularExpression(pattern: amountPattern, options: .caseInsensitive)
        let amountMatches = regex?.matches(in: message, options: [], range: range).count ?? 0
        
        // 如果有分隔符或連接詞，且金額數量 > 1，很可能有多筆交易
        let hasIndicators = multipleIndicators.contains { message.contains($0) }
        return hasIndicators && amountMatches > 1
    }
    
    // 使用 AI 解析多筆交易（完整實現在下面）
    private func parseMultipleTransactionsWithAI(_ message: String) async throws -> [ParsedTransaction] {
        // 調用下面定義的完整實現
        return try await parseMultipleTransactionsWithAIFull(message)
    }
    
    // 智能解析方法 - 使用 AIProcessingRouter 的智能路由
    // 注意：推薦直接使用 parseTransaction(from:) 方法，它已經使用 AIProcessingRouter
    func parseTransactionWithIntelligentRouting(from message: String) async throws -> ParsedTransaction {
        // 直接使用 AIProcessingRouter，確保與系統策略一致
        return try await parseTransaction(from: message)
    }
    
    // 僅使用原生 AI 解析
    private func parseWithNativeAIOnly(from message: String) async throws -> ParsedTransaction {
        let analysis = await naturalLanguageProcessor.analyzeTransactionText(message)
        
        return ParsedTransaction(
            amount: analysis.amounts.first?.value ?? 0.0,
            category: analysis.category,
            description: analysis.originalText,
            date: Date(),
            type: analysis.transactionType == .income ? .income : .expense
        )
    }
    
    // 原生 AI 優先解析
    private func parseWithNativeFirst(from message: String) async throws -> ParsedTransaction {
        // 先嘗試原生 AI（不拋出錯誤，所以不需要 do-catch）
        let analysis = await naturalLanguageProcessor.analyzeTransactionText(message)
        let confidence = analysis.confidence
        
        // 如果信心度足夠高，直接使用原生 AI 結果
        if confidence >= 0.8 {
            return ParsedTransaction(
                amount: analysis.amounts.first?.value ?? 0.0,
                category: analysis.category,
                description: analysis.originalText,
                date: Date(),
                type: analysis.transactionType == .income ? .income : .expense
            )
        }
        
        // 信心度不足，降級到 OpenAI
        return try await parseWithOpenAI(from: message)
    }
    
    // OpenAI 優先解析
    private func parseWithOpenAIFirst(from message: String) async throws -> ParsedTransaction {
        do {
            return try await parseWithOpenAI(from: message)
        } catch {
            // OpenAI 失敗，降級到原生 AI
            return try await parseWithNativeAIOnly(from: message)
        }
    }
    
    // 混合驗證解析
    private func parseWithHybridVerification(from message: String) async throws -> ParsedTransaction {
        // 同時使用兩種方法
        let nativeResult = await naturalLanguageProcessor.analyzeTransactionText(message)
        let openAIResult = try? await parseWithOpenAI(from: message)
        
        // 比較結果，選擇更可靠的
        if let openAIResult = openAIResult {
            let nativeAmount = nativeResult.amounts.first?.value ?? 0.0
            let openAIAmount = openAIResult.amount
            
            // 如果金額差異不大，使用原生 AI 結果（更快）
            if abs(nativeAmount - openAIAmount) < 0.01 {
                return ParsedTransaction(
                    amount: nativeAmount,
                    category: nativeResult.category,
                    description: nativeResult.originalText,
                    date: Date(),
                    type: nativeResult.transactionType == .income ? .income : .expense
                )
            }
        }
        
        // 否則使用 OpenAI 結果
        return try await parseWithOpenAI(from: message)
    }
    
    // 自動選擇解析策略
    private func parseWithAutoSelection(from message: String) async throws -> ParsedTransaction {
        // 根據輸入複雜度自動選擇策略
        let complexity = assessInputComplexity(message)
        
        if complexity < 0.5 {
            // 簡單輸入，使用原生 AI
            return try await parseWithNativeAIOnly(from: message)
        } else {
            // 複雜輸入，使用混合策略
            return try await parseWithHybridVerification(from: message)
        }
    }
    
    // 評估輸入複雜度
    private func assessInputComplexity(_ message: String) -> Double {
        let wordCount = message.components(separatedBy: .whitespacesAndNewlines).count
        let hasMultipleTransactions = message.contains("和") || message.contains("以及") || message.contains(",")
        let hasSpecialCharacters = message.rangeOfCharacter(from: CharacterSet.punctuationCharacters) != nil
        
        var complexity: Double = 0.0
        
        // 基於字數
        if wordCount > 20 { complexity += 0.3 }
        else if wordCount > 10 { complexity += 0.2 }
        else { complexity += 0.1 }
        
        // 基於多筆交易
        if hasMultipleTransactions { complexity += 0.4 }
        
        // 基於特殊字符
        if hasSpecialCharacters { complexity += 0.2 }
        
        return min(complexity, 1.0)
    }
    
    // 使用 OpenAI 解析（原有邏輯）
    private func parseWithOpenAI(from message: String) async throws -> ParsedTransaction {
        // 先嘗試解析多筆交易（使用新的 async 方法）
        do {
            let multipleTransactions = try await parseMultipleTransactions(from: message)
            if multipleTransactions.count > 1 {
                // 如果有多筆交易，返回第一筆（主要交易）
                return multipleTransactions.first!
            } else if multipleTransactions.count == 1 {
                return multipleTransactions.first!
            }
        } catch {
            // 多筆解析失敗，繼續單筆解析
        }
        
        // 先嘗試簡單的正則表達式解析
        if let simpleTransaction = parseSimpleTransaction(message) {
            return simpleTransaction
        }
        
        // 嘗試智能模式匹配
        if let smartTransaction = parseSmartTransaction(message) {
            return smartTransaction
        }
        
        // 檢查網路狀態，只有在線上時才使用 AI
        if NetworkMonitor.shared.isConnected {
            return try await parseWithAI(message)
        } else {
            // 離線時拋出特定錯誤
            throw TransactionParserError.offlineParsingFailed
        }
    }
    
    // 將 AIProcessingRouter 結果轉換為 ParsedTransaction
    private func convertToParsedTransaction(from result: String) throws -> ParsedTransaction {
        // 這裡需要解析 AIProcessingRouter 返回的結果
        // 簡化實現，實際應用中需要更複雜的解析邏輯
        let lines = result.components(separatedBy: .newlines)
        
        var amount: Double = 0.0
        var category: String = "其他"
        let description: String = result
        var type: TransactionType = .expense
        
        for line in lines {
            if line.contains("金額") || line.contains("amount") {
                if let amountMatch = extractAmount(from: line) {
                    amount = amountMatch
                }
            }
            if line.contains("類別") || line.contains("category") {
                category = extractCategory(from: line) ?? "其他"
            }
            if line.contains("收入") || line.contains("income") {
                type = .income
            }
        }
        
        return ParsedTransaction(
            amount: amount,
            category: category,
            description: description,
            date: Date(),
            type: type
        )
    }
    
    // 提取金額
    private func extractAmount(from text: String) -> Double? {
        let regex = try? NSRegularExpression(pattern: "\\d+(\\.\\d+)?")
        let range = NSRange(location: 0, length: text.utf16.count)
        if let match = regex?.firstMatch(in: text, options: [], range: range) {
            let amountString = (text as NSString).substring(with: match.range)
            return Double(amountString)
        }
        return nil
    }
    
    // 提取類別
    private func extractCategory(from text: String) -> String? {
        let categories = ["食物", "交通", "娛樂", "購物", "醫療", "教育", "住房", "其他"]
        for category in categories {
            if text.contains(category) {
                return category
            }
        }
        return nil
    }
    
    // 已改為 async 方法，見上方定義
    
    // 新增：提取多筆交易
    private func extractMultipleTransactions(from message: String) -> [ParsedTransaction] {
        var transactions: [ParsedTransaction] = []
        
        // 分割符號模式 - 處理多筆交易
        let separators = ["\n", "，", ",", "；", ";", "|", "&", "和", "以及", "還有", "另外", "此外"]
        
        // 嘗試用不同分隔符分割
        var segments: [String] = [message]
        for separator in separators {
            if message.contains(separator) {
                segments = message.components(separatedBy: separator)
                break
            }
        }
        
        // 如果沒有找到分隔符，嘗試智能分割
        if segments.count == 1 {
            segments = intelligentSplit(message)
        }
        
        // 解析每個片段
        for segment in segments {
            let trimmedSegment = segment.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedSegment.isEmpty { continue }
            
            // 嘗試解析單筆交易
            if let transaction = parseSingleTransactionFromSegment(trimmedSegment) {
                transactions.append(transaction)
            }
        }
        
        return transactions
    }
    
    // 新增：智能分割長串交易
    private func intelligentSplit(_ message: String) -> [String] {
        var segments: [String] = []
        var currentSegment = ""
        
        // 金額模式
        let amountPattern = "\\d+(?:\\.\\d+)?\\s*(元|塊|錢|dollars?|\\$|USD|TWD|NT\\$|€|EUR|¥|JPY|£|GBP)"
        
        // 按金額分割
        let components = message.components(separatedBy: .whitespacesAndNewlines)
        
        for component in components {
            currentSegment += component + " "
            
            // 如果遇到金額，檢查是否應該分割
            if component.range(of: amountPattern, options: .regularExpression) != nil {
                // 檢查下一個組件是否也是金額（表示新交易）
                let nextIndex = components.firstIndex(of: component)! + 1
                if nextIndex < components.count {
                    let nextComponent = components[nextIndex]
                    if nextComponent.range(of: amountPattern, options: .regularExpression) != nil {
                        // 找到新交易，保存當前片段
                        segments.append(currentSegment.trimmingCharacters(in: .whitespacesAndNewlines))
                        currentSegment = ""
                    }
                }
            }
        }
        
        // 添加最後一個片段
        if !currentSegment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            segments.append(currentSegment.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        
        return segments.isEmpty ? [message] : segments
    }
    
    // 新增：從片段解析單筆交易
    private func parseSingleTransactionFromSegment(_ segment: String) -> ParsedTransaction? {
        // 先嘗試簡單解析
        if let transaction = parseSimpleTransaction(segment) {
            return transaction
        }
        
        // 再嘗試智能解析
        if let transaction = parseSmartTransaction(segment) {
            return transaction
        }
        
        return nil
    }
    
    // 智能模式匹配 - 處理更複雜的自然語言
    private func parseSmartTransaction(_ message: String) -> ParsedTransaction? {
        let lowercasedMessage = message.lowercased()
        
        // 處理常見的語法模式
        let patterns = [
            // 中文模式 - 時間表達
            "今天.*?(\\d+(?:\\.\\d+)?).*?(元|塊|錢)",
            "昨天.*?(\\d+(?:\\.\\d+)?).*?(元|塊|錢)",
            "前天.*?(\\d+(?:\\.\\d+)?).*?(元|塊|錢)",
            "上週.*?(\\d+(?:\\.\\d+)?).*?(元|塊|錢)",
            "上個月.*?(\\d+(?:\\.\\d+)?).*?(元|塊|錢)",
            "下週.*?(\\d+(?:\\.\\d+)?).*?(元|塊|錢)",
            "下個月.*?(\\d+(?:\\.\\d+)?).*?(元|塊|錢)",
            "這個月.*?(\\d+(?:\\.\\d+)?).*?(元|塊|錢)",
            "這個週.*?(\\d+(?:\\.\\d+)?).*?(元|塊|錢)",
            "剛才.*?(\\d+(?:\\.\\d+)?).*?(元|塊|錢)",
            "剛剛.*?(\\d+(?:\\.\\d+)?).*?(元|塊|錢)",
            "最近.*?(\\d+(?:\\.\\d+)?).*?(元|塊|錢)",
            "之前.*?(\\d+(?:\\.\\d+)?).*?(元|塊|錢)",
            "後來.*?(\\d+(?:\\.\\d+)?).*?(元|塊|錢)",
            
            // 中文模式 - 動詞變化
            "買了.*?(\\d+(?:\\.\\d+)?).*?(元|塊|錢)",
            "買.*?(\\d+(?:\\.\\d+)?).*?(元|塊|錢)",
            "購買.*?(\\d+(?:\\.\\d+)?).*?(元|塊|錢)",
            "購入.*?(\\d+(?:\\.\\d+)?).*?(元|塊|錢)",
            "花了.*?(\\d+(?:\\.\\d+)?).*?(元|塊|錢)",
            "花.*?(\\d+(?:\\.\\d+)?).*?(元|塊|錢)",
            "支出.*?(\\d+(?:\\.\\d+)?).*?(元|塊|錢)",
            "支付.*?(\\d+(?:\\.\\d+)?).*?(元|塊|錢)",
            "付了.*?(\\d+(?:\\.\\d+)?).*?(元|塊|錢)",
            "付.*?(\\d+(?:\\.\\d+)?).*?(元|塊|錢)",
            "繳了.*?(\\d+(?:\\.\\d+)?).*?(元|塊|錢)",
            "繳.*?(\\d+(?:\\.\\d+)?).*?(元|塊|錢)",
            "收到.*?(\\d+(?:\\.\\d+)?).*?(元|塊|錢)",
            "賺了.*?(\\d+(?:\\.\\d+)?).*?(元|塊|錢)",
            "賺.*?(\\d+(?:\\.\\d+)?).*?(元|塊|錢)",
            "收入.*?(\\d+(?:\\.\\d+)?).*?(元|塊|錢)",
            "獲得.*?(\\d+(?:\\.\\d+)?).*?(元|塊|錢)",
            "領到.*?(\\d+(?:\\.\\d+)?).*?(元|塊|錢)",
            "領.*?(\\d+(?:\\.\\d+)?).*?(元|塊|錢)",
            
            // 英文模式 - 時間表達
            "today.*?(\\d+(?:\\.\\d+)?).*?(dollars?|\\$|€|¥|£)",
            "yesterday.*?(\\d+(?:\\.\\d+)?).*?(dollars?|\\$|€|¥|£)",
            "last week.*?(\\d+(?:\\.\\d+)?).*?(dollars?|\\$|€|¥|£)",
            "last month.*?(\\d+(?:\\.\\d+)?).*?(dollars?|\\$|€|¥|£)",
            "next week.*?(\\d+(?:\\.\\d+)?).*?(dollars?|\\$|€|¥|£)",
            "next month.*?(\\d+(?:\\.\\d+)?).*?(dollars?|\\$|€|¥|£)",
            "this week.*?(\\d+(?:\\.\\d+)?).*?(dollars?|\\$|€|¥|£)",
            "this month.*?(\\d+(?:\\.\\d+)?).*?(dollars?|\\$|€|¥|£)",
            "recently.*?(\\d+(?:\\.\\d+)?).*?(dollars?|\\$|€|¥|£)",
            "earlier.*?(\\d+(?:\\.\\d+)?).*?(dollars?|\\$|€|¥|£)",
            "later.*?(\\d+(?:\\.\\d+)?).*?(dollars?|\\$|€|¥|£)",
            "just.*?(\\d+(?:\\.\\d+)?).*?(dollars?|\\$|€|¥|£)",
            "now.*?(\\d+(?:\\.\\d+)?).*?(dollars?|\\$|€|¥|£)",
            
            // 英文模式 - 動詞變化
            "bought.*?(\\d+(?:\\.\\d+)?).*?(dollars?|\\$|€|¥|£)",
            "buy.*?(\\d+(?:\\.\\d+)?).*?(dollars?|\\$|€|¥|£)",
            "purchased.*?(\\d+(?:\\.\\d+)?).*?(dollars?|\\$|€|¥|£)",
            "spent.*?(\\d+(?:\\.\\d+)?).*?(dollars?|\\$|€|¥|£)",
            "spend.*?(\\d+(?:\\.\\d+)?).*?(dollars?|\\$|€|¥|£)",
            "paid.*?(\\d+(?:\\.\\d+)?).*?(dollars?|\\$|€|¥|£)",
            "pay.*?(\\d+(?:\\.\\d+)?).*?(dollars?|\\$|€|¥|£)",
            "received.*?(\\d+(?:\\.\\d+)?).*?(dollars?|\\$|€|¥|£)",
            "earned.*?(\\d+(?:\\.\\d+)?).*?(dollars?|\\$|€|¥|£)",
            "earn.*?(\\d+(?:\\.\\d+)?).*?(dollars?|\\$|€|¥|£)",
            "income.*?(\\d+(?:\\.\\d+)?).*?(dollars?|\\$|€|¥|£)",
            "got.*?(\\d+(?:\\.\\d+)?).*?(dollars?|\\$|€|¥|£)",
            "get.*?(\\d+(?:\\.\\d+)?).*?(dollars?|\\$|€|¥|£)",
            "gained.*?(\\d+(?:\\.\\d+)?).*?(dollars?|\\$|€|¥|£)",
            "gain.*?(\\d+(?:\\.\\d+)?).*?(dollars?|\\$|€|¥|£)",
            
            // 通用模式 - 多貨幣格式
            "\\$\\s*(\\d+(?:\\.\\d+)?)",
            "NT\\$\\s*(\\d+(?:\\.\\d+)?)",
            "USD\\s*(\\d+(?:\\.\\d+)?)",
            "TWD\\s*(\\d+(?:\\.\\d+)?)",
            "€\\s*(\\d+(?:\\.\\d+)?)",
            "EUR\\s*(\\d+(?:\\.\\d+)?)",
            "¥\\s*(\\d+(?:\\.\\d+)?)",
            "JPY\\s*(\\d+(?:\\.\\d+)?)",
            "£\\s*(\\d+(?:\\.\\d+)?)",
            "GBP\\s*(\\d+(?:\\.\\d+)?)",
            "\\d+(?:\\.\\d+)?\\s*元",
            "\\d+(?:\\.\\d+)?\\s*塊",
            "\\d+(?:\\.\\d+)?\\s*dollars?",
            "\\d+(?:\\.\\d+)?\\s*USD",
            "\\d+(?:\\.\\d+)?\\s*TWD",
            "\\d+(?:\\.\\d+)?\\s*€",
            "\\d+(?:\\.\\d+)?\\s*EUR",
            "\\d+(?:\\.\\d+)?\\s*¥",
            "\\d+(?:\\.\\d+)?\\s*JPY",
            "\\d+(?:\\.\\d+)?\\s*£",
            "\\d+(?:\\.\\d+)?\\s*GBP"
        ]
        
        var amount: Double = 0
        var transactionType: TransactionType = .expense
        
        for pattern in patterns {
            if let match = message.range(of: pattern, options: .regularExpression) {
                let matchedText = String(message[match])
                let numberPattern = "\\d+(?:\\.\\d+)?"
                if let numberMatch = matchedText.range(of: numberPattern, options: .regularExpression) {
                    let numberString = String(matchedText[numberMatch])
                    amount = Double(numberString) ?? 0
                    
                    // 判斷交易類型
                    if lowercasedMessage.contains("收入") || lowercasedMessage.contains("賺了") || 
                       lowercasedMessage.contains("收到") || lowercasedMessage.contains("earned") || 
                       lowercasedMessage.contains("received") || lowercasedMessage.contains("income") {
                        transactionType = .income
                    } else {
                        transactionType = .expense
                    }
                    break
                }
            }
        }
        
        guard amount > 0 else { return nil }
        
        // 智能類別解析
        let category = parseSmartCategory(from: message)
        
        // 智能描述解析
        let description = parseSmartDescription(from: message)
        
        return ParsedTransaction(
            amount: amount,
            category: category,
            description: description,
            date: Date(),
            type: transactionType
        )
    }
    
    // 智能類別解析 - 使用上下文和關鍵字組合
    private func parseSmartCategory(from message: String) -> String {
        let lowercasedMessage = message.lowercased()
        
        // 多關鍵字匹配，提高準確性
        let categoryRules: [(keywords: [String], category: String)] = [
            // 餐飲類別
            (["吃", "喝", "餐廳", "咖啡", "食物", "麥當勞", "肯德基", "星巴克", "外送", "便當", "小吃", "夜市", "lunch", "dinner", "breakfast", "food", "restaurant", "coffee", "drink", "meal"], "餐飲"),
            
            // 交通類別
            (["車", "公車", "捷運", "計程車", "油錢", "停車", "機票", "火車", "高鐵", "uber", "taxi", "地鐵", "bus", "train", "flight", "gas", "fuel", "parking", "transport", "commute"], "交通"),
            
            // 居住類別
            (["房租", "水電", "瓦斯", "網路", "電費", "水費", "管理費", "房貸", "租金", "rent", "utilities", "electricity", "water", "internet", "mortgage", "housing"], "居住"),
            
            // 娛樂類別
            (["電影", "遊戲", "唱歌", "旅遊", "ktv", "netflix", "spotify", "youtube", "音樂", "運動", "健身", "游泳", "跑步", "瑜伽", "movie", "game", "music", "sport", "gym", "travel", "vacation", "entertainment"], "娛樂"),
            
            // 教育類別
            (["書", "課程", "學費", "補習", "培訓", "線上課程", "證照", "考試", "學習", "book", "course", "tuition", "education", "training", "certification", "study"], "教育"),
            
            // 醫療類別
            (["醫院", "藥", "看醫生", "診所", "健檢", "牙醫", "眼科", "皮膚科", "心理諮商", "hospital", "medicine", "doctor", "clinic", "medical", "health", "therapy"], "醫療"),
            
            // 購物類別
            (["衣服", "鞋子", "包包", "化妝品", "保養品", "3c", "手機", "電腦", "家電", "家具", "網購", "amazon", "shopee", "momo", "clothes", "shoes", "bag", "cosmetics", "shopping", "online", "electronics"], "購物"),
            
            // 薪資類別
            (["薪水", "獎金", "工資", "津貼", "加班費", "salary", "wage", "bonus", "income", "pay", "earnings", "wages"], "薪資"),
            
            // 投資收益類別
            (["投資", "股息", "分紅", "股票", "基金", "債券", "利息", "理財", "investment", "dividend", "stock", "fund", "bond", "interest"], "投資收益"),
            
            // 禮物類別
            (["禮物", "紅包", "生日", "節日", "慶祝", "gift", "present", "celebration", "birthday"], "禮物"),
            
            // 其他類別
            (["保險", "稅", "手續費", "服務費", "insurance", "tax", "fee", "service"], "其他")
        ]
        
        // 計算每個類別的匹配分數
        var categoryScores: [String: Int] = [:]
        
        for rule in categoryRules {
            var score = 0
            for keyword in rule.keywords {
                if lowercasedMessage.contains(keyword) {
                    score += 1
                }
            }
            if score > 0 {
                categoryScores[rule.category] = score
            }
        }
        
        // 返回分數最高的類別
        if let bestCategory = categoryScores.max(by: { $0.value < $1.value }) {
            return bestCategory.key
        }
        
        return "其他"
    }
    
    // 智能描述解析 - 保留更多上下文信息
    private func parseSmartDescription(from message: String) -> String {
        var description = message
        
        // 移除金額
        description = description.replacingOccurrences(of: "\\d+(?:\\.\\d+)?\\s*(元|塊|錢|dollars?|\\$|USD|TWD|NT\\$)", with: "", options: .regularExpression)
        
        // 移除常見動詞
        let verbsToRemove = ["花了", "買了", "支出", "花費", "支付", "收入", "賺了", "收到", "spent", "bought", "paid", "earned", "received", "income"]
        for verb in verbsToRemove {
            description = description.replacingOccurrences(of: verb, with: "")
        }
        
        // 移除時間詞彙
        let timeWords = ["今天", "昨天", "剛才", "剛剛", "today", "yesterday", "just", "now"]
        for timeWord in timeWords {
            description = description.replacingOccurrences(of: timeWord, with: "")
        }
        
        // 清理空白
        description = description.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return description.isEmpty ? "交易記錄" : description
    }
    
    private func parseSimpleTransaction(_ message: String) -> ParsedTransaction? {
        // 擴展的金額解析模式
        let amountPatterns = [
            // 中文模式
            "花了\\s*(\\d+(?:\\.\\d+)?)\\s*元",
            "買了\\s*(\\d+(?:\\.\\d+)?)\\s*元",
            "支出\\s*(\\d+(?:\\.\\d+)?)\\s*元",
            "花費\\s*(\\d+(?:\\.\\d+)?)\\s*元",
            "支付\\s*(\\d+(?:\\.\\d+)?)\\s*元",
            "收入\\s*(\\d+(?:\\.\\d+)?)\\s*元",
            "賺了\\s*(\\d+(?:\\.\\d+)?)\\s*元",
            "收到\\s*(\\d+(?:\\.\\d+)?)\\s*元",
            "花了\\s*(\\d+(?:\\.\\d+)?)\\s*塊",
            "買了\\s*(\\d+(?:\\.\\d+)?)\\s*塊",
            "花了\\s*(\\d+(?:\\.\\d+)?)\\s*錢",
            "花了\\s*(\\d+(?:\\.\\d+)?)\\s*",
            "買了\\s*(\\d+(?:\\.\\d+)?)\\s*",
            "支出\\s*(\\d+(?:\\.\\d+)?)\\s*",
            "花費\\s*(\\d+(?:\\.\\d+)?)\\s*",
            "支付\\s*(\\d+(?:\\.\\d+)?)\\s*",
            "收入\\s*(\\d+(?:\\.\\d+)?)\\s*",
            "賺了\\s*(\\d+(?:\\.\\d+)?)\\s*",
            "收到\\s*(\\d+(?:\\.\\d+)?)\\s*",
            
            // 英文模式
            "spent\\s*(\\d+(?:\\.\\d+)?)\\s*dollars?",
            "bought\\s*(\\d+(?:\\.\\d+)?)\\s*dollars?",
            "paid\\s*(\\d+(?:\\.\\d+)?)\\s*dollars?",
            "earned\\s*(\\d+(?:\\.\\d+)?)\\s*dollars?",
            "received\\s*(\\d+(?:\\.\\d+)?)\\s*dollars?",
            "spent\\s*\\$\\s*(\\d+(?:\\.\\d+)?)",
            "bought\\s*\\$\\s*(\\d+(?:\\.\\d+)?)",
            "paid\\s*\\$\\s*(\\d+(?:\\.\\d+)?)",
            "earned\\s*\\$\\s*(\\d+(?:\\.\\d+)?)",
            "received\\s*\\$\\s*(\\d+(?:\\.\\d+)?)",
            
            // 通用模式
            "\\$\\s*(\\d+(?:\\.\\d+)?)",
            "NT\\$\\s*(\\d+(?:\\.\\d+)?)",
            "USD\\s*(\\d+(?:\\.\\d+)?)",
            "TWD\\s*(\\d+(?:\\.\\d+)?)",
            "\\d+(?:\\.\\d+)?\\s*元",
            "\\d+(?:\\.\\d+)?\\s*塊",
            "\\d+(?:\\.\\d+)?\\s*dollars?",
            "\\d+(?:\\.\\d+)?\\s*USD",
            "\\d+(?:\\.\\d+)?\\s*TWD"
        ]
        
        var amount: Double = 0
        var transactionType: TransactionType = .expense
        
        for pattern in amountPatterns {
            if let match = message.range(of: pattern, options: .regularExpression) {
                let amountString = String(message[match])
                let numberPattern = "\\d+(?:\\.\\d+)?"
                if let numberMatch = amountString.range(of: numberPattern, options: .regularExpression) {
                    let numberString = String(amountString[numberMatch])
                    amount = Double(numberString) ?? 0
                    
                    // 判斷交易類型
                    if message.contains("收入") || message.contains("賺了") || message.contains("收到") {
                        transactionType = .income
                    } else {
                        transactionType = .expense
                    }
                    break
                }
            }
        }
        
        guard amount > 0 else { return nil }
        
        // 類別解析
        let category = parseCategory(from: message)
        
        // 描述解析
        let description = parseDescription(from: message)
        
        return ParsedTransaction(
            amount: amount,
            category: category,
            description: description,
            date: Date(),
            type: transactionType
        )
    }
    
    private func parseCategory(from message: String) -> String {
        let categoryKeywords: [String: String] = [
            // 餐飲類別
            "午餐": "餐飲", "晚餐": "餐飲", "早餐": "餐飲", "吃飯": "餐飲", "餐廳": "餐飲",
            "食物": "餐飲", "咖啡": "餐飲", "飲料": "餐飲", "茶": "餐飲", "酒": "餐飲",
            "麥當勞": "餐飲", "肯德基": "餐飲", "星巴克": "餐飲", "便利商店": "餐飲",
            "外送": "餐飲", "外賣": "餐飲", "便當": "餐飲", "小吃": "餐飲", "夜市": "餐飲",
            "lunch": "餐飲", "dinner": "餐飲", "breakfast": "餐飲", "food": "餐飲",
            "restaurant": "餐飲", "coffee": "餐飲", "drink": "餐飲", "meal": "餐飲",
            
            // 交通類別
            "公車": "交通", "捷運": "交通", "計程車": "交通", "油錢": "交通", "停車": "交通",
            "機票": "交通", "火車": "交通", "高鐵": "交通", "uber": "交通", "taxi": "交通",
            "grab": "交通", "地鐵": "交通", "subway": "交通",
            "bus": "交通", "train": "交通", "flight": "交通", "gas": "交通", "fuel": "交通",
            "parking": "交通", "transport": "交通", "commute": "交通",
            
            // 居住類別
            "房租": "居住", "水電": "居住", "瓦斯": "居住", "網路": "居住", "電費": "居住",
            "水費": "居住", "管理費": "居住", "房貸": "居住", "租金": "居住",
            "rent": "居住", "utilities": "居住", "electricity": "居住", "water": "居住",
            "internet": "居住", "mortgage": "居住", "housing": "居住",
            
            // 娛樂類別
            "電影": "娛樂", "遊戲": "娛樂", "唱歌": "娛樂", "旅遊": "娛樂", "ktv": "娛樂",
            "netflix": "娛樂", "spotify": "娛樂", "youtube": "娛樂", "音樂": "娛樂",
            "運動": "娛樂", "健身": "娛樂", "游泳": "娛樂", "跑步": "娛樂", "瑜伽": "娛樂",
            "movie": "娛樂", "game": "娛樂", "music": "娛樂", "sport": "娛樂", "gym": "娛樂",
            "travel": "娛樂", "vacation": "娛樂", "entertainment": "娛樂",
            
            // 教育類別
            "書": "教育", "課程": "教育", "學費": "教育", "補習": "教育", "培訓": "教育",
            "線上課程": "教育", "證照": "教育", "考試": "教育", "學習": "教育",
            "book": "教育", "course": "教育", "tuition": "教育", "education": "教育",
            "training": "教育", "certification": "教育", "study": "教育",
            
            // 醫療類別
            "醫院": "醫療", "藥": "醫療", "看醫生": "醫療", "診所": "醫療", "健檢": "醫療",
            "牙醫": "醫療", "眼科": "醫療", "皮膚科": "醫療", "心理諮商": "醫療",
            "hospital": "醫療", "medicine": "醫療", "doctor": "醫療", "clinic": "醫療",
            "medical": "醫療", "health": "醫療", "therapy": "醫療",
            
            // 購物類別
            "衣服": "購物", "鞋子": "購物", "包包": "購物", "化妝品": "購物", "保養品": "購物",
            "3c": "購物", "手機": "購物", "電腦": "購物", "家電": "購物", "家具": "購物",
            "網購": "購物", "amazon": "購物", "shopee": "購物", "momo": "購物",
            "clothes": "購物", "shoes": "購物", "bag": "購物", "cosmetics": "購物",
            "shopping": "購物", "online": "購物", "electronics": "購物",
            
            // 薪資類別
            "薪水": "薪資", "獎金": "薪資", "工資": "薪資", "津貼": "薪資", "加班費": "薪資",
            "salary": "薪資", "wage": "薪資", "bonus": "薪資", "income": "薪資",
            "pay": "薪資", "earnings": "薪資", "wages": "薪資",
            
            // 投資收益類別
            "投資": "投資收益", "股息": "投資收益", "分紅": "投資收益", "股票": "投資收益",
            "基金": "投資收益", "債券": "投資收益", "利息": "投資收益", "理財": "投資收益",
            "investment": "投資收益", "dividend": "投資收益", "stock": "投資收益",
            "fund": "投資收益", "bond": "投資收益", "interest": "投資收益",
            
            // 禮物類別
            "禮物": "禮物", "紅包": "禮物", "生日": "禮物", "節日": "禮物", "慶祝": "禮物",
            "gift": "禮物", "present": "禮物", "celebration": "禮物", "birthday": "禮物",
            
            // 其他類別
            "保險": "其他", "稅": "其他", "手續費": "其他", "服務費": "其他",
            "insurance": "其他", "tax": "其他", "fee": "其他", "service": "其他"
        ]
        
        for (keyword, category) in categoryKeywords {
            if message.contains(keyword) {
                return category
            }
        }
        
        return "其他"
    }
    
    private func parseDescription(from message: String) -> String {
        // 移除金額和常見詞彙，保留描述
        var description = message
        
        // 移除金額
        description = description.replacingOccurrences(of: "\\d+(?:\\.\\d+)?\\s*元", with: "", options: .regularExpression)
        
        // 移除常見動詞
        let verbsToRemove = ["花了", "買了", "支出", "花費", "支付", "收入", "賺了", "收到"]
        for verb in verbsToRemove {
            description = description.replacingOccurrences(of: verb, with: "")
        }
        
        // 清理空白
        description = description.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return description.isEmpty ? "交易記錄" : description
    }
    
    private func parseWithAI(_ message: String) async throws -> ParsedTransaction {
        let prompt = """
        你是一個專業的財務交易解析 AI，請解析以下交易訊息並以 JSON 格式回傳。
        
        交易訊息：\(message)
        
        請回傳格式：
        {
            "amount": 金額（數字）,
            "category": "類別（餐飲、交通、居住、娛樂、教育、醫療、購物、薪資、投資收益、禮物、其他）",
            "description": "描述",
            "type": "income 或 expense"
        }
        
        解析規則：
        1. 金額：提取數字，忽略貨幣符號（$、NT$、USD、TWD、元、塊等）
        2. 類型：包含「收入、賺、收到、薪水、獎金、工資、津貼、加班費、投資收益、股息、分紅」等為 income，其他為 expense
        3. 分類：根據關鍵字和上下文判斷
           - 餐飲：吃、喝、餐廳、咖啡、食物、麥當勞、肯德基、星巴克、外送、便當、小吃、夜市、lunch、dinner、breakfast、food、restaurant、coffee、drink、meal
           - 交通：車、公車、捷運、計程車、油錢、停車、機票、火車、高鐵、uber、taxi、地鐵、bus、train、flight、gas、fuel、parking、transport、commute
           - 居住：房租、水電、瓦斯、網路、電費、水費、管理費、房貸、租金、rent、utilities、electricity、water、internet、mortgage、housing
           - 娛樂：電影、遊戲、唱歌、旅遊、ktv、netflix、spotify、youtube、音樂、運動、健身、游泳、跑步、瑜伽、movie、game、music、sport、gym、travel、vacation、entertainment
           - 教育：書、課程、學費、補習、培訓、線上課程、證照、考試、學習、book、course、tuition、education、training、certification、study
           - 醫療：醫院、藥、看醫生、診所、健檢、牙醫、眼科、皮膚科、心理諮商、hospital、medicine、doctor、clinic、medical、health、therapy
           - 購物：衣服、鞋子、包包、化妝品、保養品、3c、手機、電腦、家電、家具、網購、amazon、shopee、momo、clothes、shoes、bag、cosmetics、shopping、online、electronics
           - 薪資：薪水、獎金、工資、津貼、加班費、salary、wage、bonus、income、pay、earnings、wages
           - 投資收益：投資、股息、分紅、股票、基金、債券、利息、理財、investment、dividend、stock、fund、bond、interest
           - 禮物：禮物、紅包、生日、節日、慶祝、gift、present、celebration、birthday
           - 其他：保險、稅、手續費、服務費、insurance、tax、fee、service
        4. 描述：保留原始描述，移除金額和動詞，保持簡潔
        
        特殊情況處理：
        - 如果訊息包含多個金額，選擇最明顯的主要金額
        - 如果無法確定類別，選擇「其他」
        - 如果無法確定類型，預設為「expense」
        - 如果無法解析，請回傳 null
        
        多筆交易處理：
        - 如果訊息包含多筆交易（用逗號、分號、換行等分隔），請解析第一筆主要交易
        - 優先處理金額最大的交易
        - 如果有多個相同金額，選擇第一個出現的
        
        請確保回傳的 JSON 格式正確且完整。
        """
        
        let messages = [
            OpenAIMessage(role: "user", content: prompt)
        ]
        
        let response = try await openAIService.chat(messages: messages)
        
        // 解析 JSON 回應
        guard let data = response.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let amount = json["amount"] as? Double,
              let category = json["category"] as? String,
              let description = json["description"] as? String,
              let typeString = json["type"] as? String else {
            throw TransactionParsingError.invalidResponse
        }
        
        let transactionType: TransactionType = typeString == "income" ? .income : .expense
        
        return ParsedTransaction(
            amount: amount,
            category: category,
            description: description,
            date: Date(),
            type: transactionType
        )
    }
    
    // AI 解析多筆交易（完整實現）
    private func parseMultipleTransactionsWithAIFull(_ message: String) async throws -> [ParsedTransaction] {
        let prompt = """
        你是一個專業的財務交易解析 AI，請解析以下可能包含多筆交易的訊息並以 JSON 格式回傳。
        
        交易訊息：\(message)
        
        請回傳格式：
        {
            "transactions": [
                {
                    "amount": 金額（數字）,
                    "category": "類別（餐飲、交通、居住、娛樂、教育、醫療、購物、薪資、投資收益、禮物、其他）",
                    "description": "描述",
                    "type": "income 或 expense"
                }
            ]
        }
        
        解析規則：
        1. 金額：提取數字，忽略貨幣符號（$、NT$、USD、TWD、元、塊等）
        2. 類型：包含「收入、賺、收到、薪水、獎金、工資、津貼、加班費、投資收益、股息、分紅」等為 income，其他為 expense
        3. 分類：根據關鍵字和上下文判斷
           - 餐飲：吃、喝、餐廳、咖啡、食物、麥當勞、肯德基、星巴克、外送、便當、小吃、夜市、lunch、dinner、breakfast、food、restaurant、coffee、drink、meal
           - 交通：車、公車、捷運、計程車、油錢、停車、機票、火車、高鐵、uber、taxi、地鐵、bus、train、flight、gas、fuel、parking、transport、commute
           - 居住：房租、水電、瓦斯、網路、電費、水費、管理費、房貸、租金、rent、utilities、electricity、water、internet、mortgage、housing
           - 娛樂：電影、遊戲、唱歌、旅遊、ktv、netflix、spotify、youtube、音樂、運動、健身、游泳、跑步、瑜伽、movie、game、music、sport、gym、travel、vacation、entertainment
           - 教育：書、課程、學費、補習、培訓、線上課程、證照、考試、學習、book、course、tuition、education、training、certification、study
           - 醫療：醫院、藥、看醫生、診所、健檢、牙醫、眼科、皮膚科、心理諮商、hospital、medicine、doctor、clinic、medical、health、therapy
           - 購物：衣服、鞋子、包包、化妝品、保養品、3c、手機、電腦、家電、家具、網購、amazon、shopee、momo、clothes、shoes、bag、cosmetics、shopping、online、electronics
           - 薪資：薪水、獎金、工資、津貼、加班費、salary、wage、bonus、income、pay、earnings、wages
           - 投資收益：投資、股息、分紅、股票、基金、債券、利息、理財、investment、dividend、stock、fund、bond、interest
           - 禮物：禮物、紅包、生日、節日、慶祝、gift、present、celebration、birthday
           - 其他：保險、稅、手續費、服務費、insurance、tax、fee、service
        4. 描述：保留原始描述，移除金額和動詞，保持簡潔
        
        多筆交易處理：
        - 如果訊息包含多筆交易（用逗號、分號、換行、和、以及等分隔），請解析所有交易
        - 每筆交易都應該有獨立的金額、類別、描述和類型
        - 如果無法確定某筆交易的類別，選擇「其他」
        - 如果無法確定某筆交易的類型，預設為「expense」
        - 如果無法解析任何交易，請回傳空的 transactions 陣列
        
        請確保回傳的 JSON 格式正確且完整。
        """
        
        let messages = [
            OpenAIMessage(role: "user", content: prompt)
        ]
        
        let response = try await openAIService.chat(messages: messages)
        
        // 解析 JSON 回應
        guard let data = response.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let transactionsArray = json["transactions"] as? [[String: Any]] else {
            // 如果 AI 解析失敗，回退到本地解析
            return extractMultipleTransactions(from: message)
        }
        
        var parsedTransactions: [ParsedTransaction] = []
        
        for transactionData in transactionsArray {
            guard let amount = transactionData["amount"] as? Double,
                  let category = transactionData["category"] as? String,
                  let description = transactionData["description"] as? String,
                  let typeString = transactionData["type"] as? String else {
                continue
            }
            
            let transactionType: TransactionType = typeString == "income" ? .income : .expense
            
            let transaction = ParsedTransaction(
                amount: amount,
                category: category,
                description: description,
                date: Date(),
                type: transactionType
            )
            
            parsedTransactions.append(transaction)
        }
        
        return parsedTransactions
    }
}

// 交易解析錯誤
enum TransactionParsingError: Error, LocalizedError {
    case invalidResponse
    case unableToParse
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "AI 回應格式無效"
        case .unableToParse:
            return "無法解析交易訊息"
        }
    }
}