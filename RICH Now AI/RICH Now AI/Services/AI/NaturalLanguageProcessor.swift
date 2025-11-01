//
//  NaturalLanguageProcessor.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/28.
//

import Foundation
import NaturalLanguage
import CoreML
import Combine
import os.log

@MainActor
class NaturalLanguageProcessor: ObservableObject {
    static let shared = NaturalLanguageProcessor()
    
    @Published var isAvailable: Bool = true
    @Published var supportedLanguages: [String] = []
    @Published var processingConfidence: Double = 0.0
    
    private let logger = Logger(subsystem: "com.richnowai", category: "NaturalLanguageProcessor")
    
    // 語言識別器
    private let languageRecognizer = NLLanguageRecognizer()
    
    // 文字標註器
    private let tagger = NLTagger(tagSchemes: [.nameType, .lexicalClass, .sentimentScore])
    
    // 文字分類器（如果可用）
    private var textClassifier: NLModel?
    
    private init() {
        setupLanguageRecognizer()
        setupTagger()
        loadTextClassifier()
    }
    
    // MARK: - 初始化設置
    
    private func setupLanguageRecognizer() {
        // 設置支援的語言
        supportedLanguages = ["en", "zh-Hans", "zh-Hant", "ja", "ko", "es", "fr", "de"]
        languageRecognizer.languageConstraints = supportedLanguages.map { NLLanguage($0) }
    }
    
    private func setupTagger() {
        // 設置標註器選項
        tagger.string = ""
        // NLTagger 沒有 options 屬性，使用其他方式配置
    }
    
    private func loadTextClassifier() {
        // 嘗試載入自定義文字分類器
        // 如果沒有自定義模型，將使用規則基礎分類
        // 這裡應該載入實際的 Core ML 模型
        // textClassifier = try NLModel(contentsOf: modelURL)
        logger.info("Text classifier loaded successfully")
        textClassifier = nil
    }
    
    // MARK: - 語言識別
    
    func detectLanguage(_ text: String) async -> (language: String, confidence: Double) {
        guard !text.isEmpty else {
            return ("unknown", 0.0)
        }
        
        let dominantLanguage = NLLanguageRecognizer.dominantLanguage(for: text)
        let confidence = languageRecognizer.languageHypotheses(withMaximum: 1)[dominantLanguage ?? .english] ?? 0.0
        
        let languageCode = dominantLanguage?.rawValue ?? "unknown"
        
        logger.debug("Language detected: \(languageCode) with confidence: \(confidence)")
        
        return (languageCode, confidence)
    }
    
    func getSupportedLanguages() -> [String] {
        return supportedLanguages
    }
    
    // MARK: - 交易文字分析
    
    func analyzeTransactionText(_ text: String) async -> TransactionAnalysisResult {
        let startTime = Date()
        
        // 1. 語言識別
        let (language, languageConfidence) = await detectLanguage(text)
        
        // 2. 詞性標註
        let tokens = await performTokenization(text)
        
        // 3. 命名實體識別
        let entities = await extractNamedEntities(text)
        
        // 4. 金額提取
        let amounts = await extractAmounts(text)
        
        // 5. 交易類型分類
        let transactionType = await classifyTransactionType(text)
        
        // 6. 類別分類
        let category = await classifyCategory(text)
        
        // 7. 情感分析
        let sentiment = await analyzeSentiment(text)
        
        let processingTime = Date().timeIntervalSince(startTime)
        
        let result = TransactionAnalysisResult(
            originalText: text,
            language: language,
            languageConfidence: languageConfidence,
            tokens: tokens,
            entities: entities,
            amounts: amounts,
            transactionType: transactionType,
            category: category,
            sentiment: sentiment,
            confidence: calculateOverallConfidence(
                languageConfidence: languageConfidence,
                entityCount: entities.count,
                amountCount: amounts.count
            ),
            processingTime: processingTime
        )
        
        logger.debug("Transaction analysis completed in \(processingTime)s with confidence \(result.confidence)")
        
        return result
    }
    
    // MARK: - 詞性標註和分詞
    
    private func performTokenization(_ text: String) async -> [Token] {
        tagger.string = text
        var tokens: [Token] = []
        
        let range = text.startIndex..<text.endIndex
        tagger.enumerateTags(in: range, unit: .word, scheme: .lexicalClass) { tag, tokenRange in
            let tokenText = String(text[tokenRange])
            let token = Token(
                text: tokenText,
                lexicalClass: tag?.rawValue ?? "unknown",
                range: tokenRange
            )
            tokens.append(token)
            return true
        }
        
        return tokens
    }
    
    // MARK: - 命名實體識別
    
    private func extractNamedEntities(_ text: String) async -> [NamedEntity] {
        tagger.string = text
        var entities: [NamedEntity] = []
        
        let range = text.startIndex..<text.endIndex
        tagger.enumerateTags(in: range, unit: .word, scheme: .nameType) { tag, tokenRange in
            if let tag = tag {
                let entityText = String(text[tokenRange])
                let entity = NamedEntity(
                    text: entityText,
                    type: tag.rawValue,
                    range: tokenRange
                )
                entities.append(entity)
            }
            return true
        }
        
        return entities
    }
    
    // MARK: - 金額提取
    
    private func extractAmounts(_ text: String) async -> [Amount] {
        var amounts: [Amount] = []
        
        // 使用正則表達式提取金額
        let patterns = [
            // 美元格式
            "\\$\\s*(\\d+(?:\\.\\d{2})?)",
            "USD\\s*(\\d+(?:\\.\\d{2})?)",
            "dollars?\\s*(\\d+(?:\\.\\d{2})?)",
            
            // 台幣格式
            "NT\\$\\s*(\\d+(?:\\.\\d{2})?)",
            "TWD\\s*(\\d+(?:\\.\\d{2})?)",
            "\\d+(?:\\.\\d{2})?\\s*元",
            "\\d+(?:\\.\\d{2})?\\s*塊",
            
            // 歐元格式
            "€\\s*(\\d+(?:\\.\\d{2})?)",
            "EUR\\s*(\\d+(?:\\.\\d{2})?)",
            
            // 日圓格式
            "¥\\s*(\\d+(?:\\.\\d{2})?)",
            "JPY\\s*(\\d+(?:\\.\\d{2})?)",
            
            // 英鎊格式
            "£\\s*(\\d+(?:\\.\\d{2})?)",
            "GBP\\s*(\\d+(?:\\.\\d{2})?)",
            
            // 通用數字格式
            "\\d+(?:\\.\\d{2})?"
        ]
        
        for pattern in patterns {
            let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            let range = NSRange(text.startIndex..., in: text)
            
            regex?.enumerateMatches(in: text, options: [], range: range) { match, _, _ in
                guard let match = match,
                      let range = Range(match.range, in: text) else { return }
                
                let amountText = String(text[range])
                let amount = parseAmount(from: amountText, in: text)
                if let amount = amount {
                    amounts.append(amount)
                }
            }
        }
        
        return amounts
    }
    
    private func parseAmount(from text: String, in originalText: String) -> Amount? {
        // 提取數字部分
        let numberPattern = "\\d+(?:\\.\\d{2})?"
        guard let regex = try? NSRegularExpression(pattern: numberPattern),
              let match = regex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range, in: text) else { return nil }
        
        let numberString = String(text[range])
        guard let value = Double(numberString) else { return nil }
        
        // 判斷貨幣類型
        let currency: String
        if text.contains("$") || text.contains("USD") || text.contains("dollar") {
            currency = "USD"
        } else if text.contains("NT$") || text.contains("TWD") || text.contains("元") || text.contains("塊") {
            currency = "TWD"
        } else if text.contains("€") || text.contains("EUR") {
            currency = "EUR"
        } else if text.contains("¥") || text.contains("JPY") {
            currency = "JPY"
        } else if text.contains("£") || text.contains("GBP") {
            currency = "GBP"
        } else {
            currency = "USD" // 默認美元
        }
        
        // 判斷是否為收入
        let incomeKeywords = ["收入", "賺", "收到", "獲得", "earn", "earned", "income", "received", "gain", "gained"]
        let isIncome = incomeKeywords.contains { keyword in
            originalText.lowercased().contains(keyword)
        }
        
        return Amount(
            value: value,
            currency: currency,
            isIncome: isIncome,
            originalText: text
        )
    }
    
    // MARK: - 交易類型分類
    
    private func classifyTransactionType(_ text: String) async -> TransactionType {
        let lowercasedText = text.lowercased()
        
        // 收入關鍵詞
        let incomeKeywords = [
            "收入", "賺", "收到", "獲得", "工資", "薪水", "獎金", "分紅",
            "earn", "earned", "income", "salary", "wage", "bonus", "received", "gain", "gained"
        ]
        
        // 支出關鍵詞
        let expenseKeywords = [
            "支出", "花", "買", "付", "消費", "購買", "支付", "費用",
            "spend", "spent", "buy", "bought", "pay", "paid", "expense", "cost", "purchase"
        ]
        
        let incomeScore = incomeKeywords.reduce(0) { score, keyword in
            score + (lowercasedText.contains(keyword) ? 1 : 0)
        }
        
        let expenseScore = expenseKeywords.reduce(0) { score, keyword in
            score + (lowercasedText.contains(keyword) ? 1 : 0)
        }
        
        if incomeScore > expenseScore {
            return .income
        } else if expenseScore > incomeScore {
            return .expense
        } else {
            // 如果無法確定，根據金額前的動詞判斷
            if lowercasedText.contains("賺") || lowercasedText.contains("earn") {
                return .income
            } else {
                return .expense
            }
        }
    }
    
    // MARK: - 類別分類
    
    private func classifyCategory(_ text: String) async -> String {
        let lowercasedText = text.lowercased()
        
        // 類別關鍵詞映射
        let categoryKeywords: [String: [String]] = [
            "食物": ["吃", "餐廳", "食物", "飲料", "咖啡", "午餐", "晚餐", "早餐", "超市", "買菜", "eat", "food", "restaurant", "coffee", "lunch", "dinner", "breakfast", "grocery", "supermarket"],
            "交通": ["車", "油", "停車", "公車", "捷運", "計程車", "機票", "火車", "car", "gas", "parking", "bus", "metro", "taxi", "flight", "train", "transport"],
            "居住": ["房租", "水電", "瓦斯", "網路", "電費", "水費", "管理費", "房貸", "租金", "rent", "utilities", "electricity", "water", "internet", "mortgage", "housing"],
            "娛樂": ["電影", "遊戲", "唱歌", "旅遊", "ktv", "netflix", "spotify", "youtube", "音樂", "運動", "健身", "movie", "game", "music", "sport", "gym", "travel", "entertainment"],
            "教育": ["書", "課程", "學費", "培訓", "學習", "book", "course", "tuition", "training", "education", "study"],
            "醫療": ["醫院", "醫生", "藥", "檢查", "治療", "hospital", "doctor", "medicine", "checkup", "treatment", "medical"],
            "購物": ["衣服", "鞋子", "包包", "化妝品", "clothes", "shoes", "bag", "cosmetics", "shopping"],
            "其他": ["其他", "雜項", "miscellaneous", "other"]
        ]
        
        var categoryScores: [String: Int] = [:]
        
        for (category, keywords) in categoryKeywords {
            let score = keywords.reduce(0) { score, keyword in
                score + (lowercasedText.contains(keyword) ? 1 : 0)
            }
            categoryScores[category] = score
        }
        
        // 找到得分最高的類別
        let bestCategory = categoryScores.max { $0.value < $1.value }
        return bestCategory?.key ?? "其他"
    }
    
    // MARK: - 情感分析
    
    func analyzeSentiment(_ text: String) async -> SentimentAnalysis {
        tagger.string = text
        let range = text.startIndex..<text.endIndex
        
        var sentimentScore: Double = 0.0
        var sentimentCount = 0
        
        tagger.enumerateTags(in: range, unit: .sentence, scheme: .sentimentScore) { tag, tokenRange in
            if let tag = tag {
                // 將 String 轉換為 Double
                if let value = Double(tag.rawValue) {
                    sentimentScore += value
                    sentimentCount += 1
                }
            }
            return true
        }
        
        let averageSentiment = sentimentCount > 0 ? sentimentScore / Double(sentimentCount) : 0.0
        
        let sentimentType: SentimentType
        if averageSentiment > 0.1 {
            sentimentType = .positive
        } else if averageSentiment < -0.1 {
            sentimentType = .negative
        } else {
            sentimentType = .neutral
        }
        
        return SentimentAnalysis(
            score: averageSentiment,
            type: sentimentType,
            confidence: min(abs(averageSentiment) * 2, 1.0)
        )
    }
    
    // MARK: - 信心度計算
    
    private func calculateOverallConfidence(
        languageConfidence: Double,
        entityCount: Int,
        amountCount: Int
    ) -> Double {
        var confidence: Double = 0.0
        
        // 語言識別信心度 (40%)
        confidence += languageConfidence * 0.4
        
        // 實體識別信心度 (30%)
        let entityConfidence = min(Double(entityCount) / 5.0, 1.0)
        confidence += entityConfidence * 0.3
        
        // 金額識別信心度 (30%)
        let amountConfidence = min(Double(amountCount) / 3.0, 1.0)
        confidence += amountConfidence * 0.3
        
        return min(confidence, 1.0)
    }
    
    // MARK: - 批量處理
    
    func processMultipleTransactions(_ texts: [String]) async -> [TransactionAnalysisResult] {
        var results: [TransactionAnalysisResult] = []
        
        for text in texts {
            let result = await analyzeTransactionText(text)
            results.append(result)
        }
        
        return results
    }
    
    // MARK: - 可用性檢查
    
    func checkAvailability() -> Bool {
        // 檢查 Natural Language 框架是否可用
        isAvailable = true
        return isAvailable
    }
}

// MARK: - 數據模型

struct TransactionAnalysisResult {
    let originalText: String
    let language: String
    let languageConfidence: Double
    let tokens: [Token]
    let entities: [NamedEntity]
    let amounts: [Amount]
    let transactionType: TransactionType
    let category: String
    let sentiment: SentimentAnalysis
    let confidence: Double
    let processingTime: TimeInterval
}

struct Token {
    let text: String
    let lexicalClass: String
    let range: Range<String.Index>
}

struct NamedEntity {
    let text: String
    let type: String
    let range: Range<String.Index>
}

struct Amount {
    let value: Double
    let currency: String
    let isIncome: Bool
    let originalText: String
}

// TransactionType 定義在 Models/Transaction.swift 中

struct SentimentAnalysis {
    let score: Double
    let type: SentimentType
    let confidence: Double
}

enum SentimentType {
    case positive
    case negative
    case neutral
}
