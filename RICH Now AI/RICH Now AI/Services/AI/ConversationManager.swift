//
//  ConversationManager.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import Foundation
import Combine
import SwiftData
import NaturalLanguage
import os.log

// 對話上下文
struct ConversationContext: Codable {
    let currentTopic: String
    let userGoals: [String]
    let recentTransactions: [String]
    let financialHealth: String
    let vglaType: String
    let tkiMode: String?
    let hasIntegratedAnalysis: Bool
    let lastAdvice: String?
}

// 對話建議
struct ConversationSuggestion: Codable {
    let title: String
    let content: String
    let action: String
}

@MainActor
class ConversationManager: ObservableObject {
    static let shared = ConversationManager()
    
    private let openAIService = OpenAIService.shared
    private let vglaAnalyzer = VGLAAnalyzer.shared
    private let gabrielAI = GabrielAIService.shared
    private let aiProcessingRouter = AIProcessingRouter.shared
    private let naturalLanguageProcessor = NaturalLanguageProcessor.shared
    private let settingsManager = SettingsManager.shared
    private let performanceMonitor = AIPerformanceMonitor.shared
    private let logger = Logger(subsystem: "com.richnowai", category: "ConversationManager")
    
    @Published var currentConversation: Conversation?
    @Published var suggestions: [ConversationSuggestion] = []
    @Published var isTyping: Bool = false
    @Published var currentProcessingMethod: String = "未知"
    @Published var isOfflineMode: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupNetworkMonitoring()
    }
    
    // MARK: - 網路監控
    
    private func setupNetworkMonitoring() {
        NetworkMonitor.shared.$isConnected
            .sink { [weak self] isConnected in
                self?.isOfflineMode = !isConnected
            }
            .store(in: &cancellables)
    }
    
    // MARK: - 智能對話處理
    
    func processConversationWithIntelligentRouting(
        userMessage: String,
        context: ConversationContext
    ) async throws -> String {
        currentProcessingMethod = "處理中..."
        
        // 使用智能 AI 處理路由器
        let result = try await processConversationWithRouting(
            userMessage: userMessage,
            context: context
        )
        
        currentProcessingMethod = result.source == .native ? "原生 AI" : "OpenAI"
        
        logger.info("對話處理完成: 方法=\(String(describing: result.source)), 信心度=\(result.confidence), 時間=\(result.processingTime)")
        
        return result.data
    }
    
    private func processConversationWithRouting(
        userMessage: String,
        context: ConversationContext
    ) async throws -> AIProcessingRouter.ProcessingResult<String> {
        // 直接使用 AIProcessingRouter 的當前策略，確保一致性
        let strategy = aiProcessingRouter.currentStrategy
        
        logger.info("對話處理路由策略: \(strategy.displayName)")
        
        switch strategy {
        case .nativeOnly:
            return try await processConversationWithNativeOnly(userMessage: userMessage, context: context)
        case .nativeFirst:
            return try await processConversationWithNativeFirst(userMessage: userMessage, context: context)
        case .openAIFirst:
            return try await processConversationWithOpenAIFirst(userMessage: userMessage, context: context)
        case .hybrid:
            return try await processConversationWithHybrid(userMessage: userMessage, context: context)
        case .auto:
            return try await processConversationWithAuto(userMessage: userMessage, context: context)
        }
    }
    
    // MARK: - 原生 AI 對話處理
    
    private func processConversationWithNativeOnly(
        userMessage: String,
        context: ConversationContext
    ) async throws -> AIProcessingRouter.ProcessingResult<String> {
        let startTime = Date()
        
        let response = try await generateNativeConversationResponse(
            userMessage: userMessage,
            context: context
        )
        let processingTime = Date().timeIntervalSince(startTime)
        
        performanceMonitor.recordNativeAIProcessing(
            success: true,
            processingTime: processingTime,
            confidence: 0.8
        )
        
        return AIProcessingRouter.ProcessingResult(
            data: response,
            source: .native,
            confidence: 0.8,
            processingTime: processingTime,
            fallbackUsed: false
        )
    }
    
    private func processConversationWithNativeFirst(
        userMessage: String,
        context: ConversationContext
    ) async throws -> AIProcessingRouter.ProcessingResult<String> {
        do {
            let nativeResult = try await processConversationWithNativeOnly(
                userMessage: userMessage,
                context: context
            )
            // 降低信心度閾值，讓原生 AI 更容易被接受（從 0.85 降到 0.6）
            let confidenceThreshold = settingsManager.currentSettings?.nativeAIConfidenceThreshold ?? 0.6
            
            if nativeResult.confidence >= confidenceThreshold {
                logger.info("原生 AI 處理成功，信心度: \(String(format: "%.2f", nativeResult.confidence))")
                return nativeResult
            } else {
                logger.info("原生 AI 信心度不足 (\(String(format: "%.2f", nativeResult.confidence)))，降級到 OpenAI")
                throw AIProcessingError.insufficientConfidence
            }
        } catch {
            logger.info("原生 AI 失敗，降級到 OpenAI: \(error.localizedDescription)")
            return try await processConversationWithOpenAI(userMessage: userMessage, context: context)
        }
    }
    
    private func processConversationWithOpenAIFirst(
        userMessage: String,
        context: ConversationContext
    ) async throws -> AIProcessingRouter.ProcessingResult<String> {
        do {
            return try await processConversationWithOpenAI(userMessage: userMessage, context: context)
        } catch {
            logger.info("OpenAI 失敗，降級到原生 AI: \(error.localizedDescription)")
            return try await processConversationWithNativeOnly(userMessage: userMessage, context: context)
        }
    }
    
    private func processConversationWithHybrid(
        userMessage: String,
        context: ConversationContext
    ) async throws -> AIProcessingRouter.ProcessingResult<String> {
        async let nativeTask = try? processConversationWithNativeOnly(userMessage: userMessage, context: context)
        async let openAITask = try? processConversationWithOpenAI(userMessage: userMessage, context: context)
        
        let (nativeResult, openAIResult) = await (nativeTask, openAITask)
        
        if let native = nativeResult, let openai = openAIResult {
            // 比較結果，選擇更可靠的
            if native.confidence >= openai.confidence {
                logger.info("混合模式選擇原生 AI 結果")
                return native
            } else {
                logger.info("混合模式選擇 OpenAI 結果")
                return openai
            }
        } else if let native = nativeResult {
            logger.info("混合模式僅原生 AI 成功")
            return native
        } else if let openai = openAIResult {
            logger.info("混合模式僅 OpenAI 成功")
            return openai
        } else {
            throw AIProcessingError.textProcessingFailed
        }
    }
    
    private func processConversationWithAuto(
        userMessage: String,
        context: ConversationContext
    ) async throws -> AIProcessingRouter.ProcessingResult<String> {
        let messageComplexity = assessMessageComplexity(userMessage)
        let deviceCapability = getDeviceCapability()
        
        if deviceCapability >= 0.7 && messageComplexity < 0.6 {
            // 設備能力強，訊息不複雜，優先使用原生 AI
            return try await processConversationWithNativeFirst(userMessage: userMessage, context: context)
        } else {
            // 設備能力一般或訊息複雜，使用混合策略
            return try await processConversationWithHybrid(userMessage: userMessage, context: context)
        }
    }
    
    // MARK: - 原生 AI 對話實現
    
    private func generateNativeConversationResponse(
        userMessage: String,
        context: ConversationContext
    ) async throws -> String {
        // 確保訊息不為空
        let trimmedMessage = userMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty else {
            logger.warning("嘗試處理空訊息")
            return "您好！我是您的財務顧問 Gabriel。請告訴我您需要什麼幫助？"
        }
        
        do {
            // 使用 Natural Language Framework 分析用戶訊息
            let analysis = await analyzeMessageWithNativeAI(userMessage: trimmedMessage, context: context)
            
            // 檢查是否完成 VGLA 測驗
            // 如果 vglaType 是 "VG"、"未知"、空字串，或長度不是2，表示沒有完成測驗
            let hasVGLA = !context.vglaType.isEmpty && 
                         context.vglaType != "VG" && 
                         context.vglaType != "未知" && 
                         context.vglaType.count == 2
            
            // 基於分析結果生成回應（根據是否有 VGLA 結果調整回應品質）
            let response = generateResponseBasedOnAnalysis(
                analysis: analysis, 
                context: context,
                hasVGLA: hasVGLA
            )
            
            // 確保回應不為空
            guard !response.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                logger.warning("生成的回應為空，使用回退回應")
                return generateFallbackResponse(userMessage: trimmedMessage, context: context)
            }
            
            logger.info("原生 AI 回應生成成功，意圖: \(String(describing: analysis.intent)), 信心度: \(String(format: "%.2f", analysis.confidence)), 有VGLA: \(hasVGLA)")
            
            // 如果沒有 VGLA 結果，在回應末尾添加建議測驗的提示
            if !hasVGLA && analysis.intent != .general {
                return response + "\n\n💡 提示：完成 VGLA 測驗後，我可以為您提供更個性化和準確的財務建議。"
            }
            
            return response
        } catch {
            logger.error("生成原生 AI 回應時發生錯誤: \(error.localizedDescription)")
            // 回退到基本回應
            return generateFallbackResponse(userMessage: trimmedMessage, context: context)
        }
    }
    
    // 回退回應（當主要邏輯失敗時）
    private func generateFallbackResponse(userMessage: String, context: ConversationContext) -> String {
        // 即使分析失敗，也提供一個基本的友好回應
        let lowercased = userMessage.lowercased()
        
        if lowercased.contains("你好") || lowercased.contains("hello") || lowercased.contains("hi") {
            return "您好！我是您的財務顧問 Gabriel。很高興為您服務！"
        } else if lowercased.contains("幫助") || lowercased.contains("help") {
            return "我很樂意幫助您！我可以協助您：\n• 記帳和財務管理\n• 投資建議\n• 財務分析\n• 制定理財目標\n\n請告訴我您需要什麼幫助？"
        } else {
            return "我收到了您的訊息。作為您的財務顧問，我會盡力為您提供幫助。基於您的 VGLA 類型 \(context.vglaType)，我了解您的思考方式。請詳細告訴我您的需求，我會為您提供最適合的建議。"
        }
    }
    
    private func analyzeMessageWithNativeAI(
        userMessage: String,
        context: ConversationContext
    ) async -> MessageAnalysisResult {
        // 使用 Natural Language Framework 分析訊息
        // 確保用戶訊息不為空
        guard !userMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            logger.warning("收到空訊息")
            return MessageAnalysisResult(
                sentiment: 0.5,
                language: .traditionalChinese,
                intent: .general,
                confidence: 0.5
            )
        }
        
        // 語言識別
        var detectedLanguage: NLLanguage = .traditionalChinese
        let languageResult = await naturalLanguageProcessor.detectLanguage(userMessage)
        let languageCode = languageResult.language
        
        // 嘗試轉換語言代碼到 NLLanguage
        let lang = NLLanguage(rawValue: languageCode)
        if lang != .undetermined && !languageCode.isEmpty {
            detectedLanguage = lang
        } else {
            // 如果無法直接轉換，根據常見語言代碼嘗試
            if languageCode.contains("zh") || languageCode.contains("Chinese") {
                detectedLanguage = .traditionalChinese
            } else if languageCode.contains("en") || languageCode.contains("English") {
                detectedLanguage = .english
            } else if let dominantLang = NLLanguageRecognizer.dominantLanguage(for: userMessage) {
                detectedLanguage = dominantLang
            } else {
                detectedLanguage = .traditionalChinese // 默認使用繁體中文
            }
            logger.debug("語言代碼轉換: \(languageCode) → \(detectedLanguage.rawValue)")
        }
        
        // 真實的情感分析
        let sentimentAnalysis = await naturalLanguageProcessor.analyzeSentiment(userMessage)
        let sentimentScore = sentimentAnalysis.score
        
        // 分析訊息意圖
        let intent = analyzeMessageIntent(userMessage: userMessage, context: context)
        
        // 計算信心度（基於訊息長度和意圖匹配度）
        let confidence = calculateConfidence(userMessage: userMessage, intent: intent)
        
        logger.debug("訊息分析完成: 語言=\(detectedLanguage.rawValue), 意圖=\(String(describing: intent)), 情感=\(String(format: "%.2f", sentimentScore)), 信心度=\(String(format: "%.2f", confidence))")
        
        return MessageAnalysisResult(
            sentiment: sentimentScore, // 使用真實的情感分析結果
            language: detectedLanguage,
            intent: intent,
            confidence: confidence
        )
    }
    
    // 計算處理信心度
    private func calculateConfidence(userMessage: String, intent: MessageIntent) -> Double {
        var confidence: Double = 0.7 // 基礎信心度
        
        // 如果訊息足夠長且有明確意圖，提高信心度
        if userMessage.count > 10 {
            confidence += 0.1
        }
        
        // 如果意圖不是 general，提高信心度
        if intent != .general {
            confidence += 0.1
        }
        
        // 如果訊息包含問號或感嘆號，可能表示明確的問題或請求
        if userMessage.contains("?") || userMessage.contains("？") || 
           userMessage.contains("!") || userMessage.contains("！") {
            confidence += 0.05
        }
        
        return min(confidence, 0.95) // 限制最高信心度
    }
    
    private func analyzeMessageIntent(
        userMessage: String,
        context: ConversationContext
    ) -> MessageIntent {
        let lowercasedMessage = userMessage.lowercased()
        
        // 優先檢查具體操作意圖（更具體的先檢查）
        
        // 拍照記帳相關
        let photoAccountingKeywords = ["拍照記帳", "拍攝記帳", "拍發票", "掃描發票", "拍照記錄", "掃描收據", "拍單據", "photo accounting", "scan receipt", "take photo", "camera"]
        if photoAccountingKeywords.contains(where: lowercasedMessage.contains) {
            return .photoAccounting
        }
        
        // 查詢交易歷史相關
        let queryKeywords = ["查詢", "查看", "顯示", "列出", "歷史", "記錄", "交易歷史", "記帳記錄", "查交易", "看交易", "歷史記錄", "query", "history", "transactions", "list", "show"]
        if queryKeywords.contains(where: lowercasedMessage.contains) {
            // 檢查是否包含交易相關關鍵詞
            let transactionKeywords = ["交易", "記帳", "支出", "收入", "transaction", "accounting"]
            if transactionKeywords.contains(where: lowercasedMessage.contains) {
                return .queryTransactions
            }
        }
        
        // 打開相機相關
        let cameraKeywords = ["打開相機", "開啟相機", "相機", "拍照", "open camera", "camera"]
        if cameraKeywords.contains(where: lowercasedMessage.contains) && !photoAccountingKeywords.contains(where: lowercasedMessage.contains) {
            return .openCamera
        }
        
        // 文字記帳相關（需要檢查是否包含具體交易描述）
        let textAccountingKeywords = ["記帳", "記錄", "記", "輸入", "添加", "account", "record", "add"]
        let hasTransactionDescription = lowercasedMessage.contains("花了") || 
                                       lowercasedMessage.contains("買了") || 
                                       lowercasedMessage.contains("收入") || 
                                       lowercasedMessage.contains("支出") ||
                                       lowercasedMessage.contains("元") ||
                                       lowercasedMessage.contains("塊") ||
                                       lowercasedMessage.contains("spent") ||
                                       lowercasedMessage.contains("bought") ||
                                       lowercasedMessage.contains("income") ||
                                       lowercasedMessage.contains("expense") ||
                                       lowercasedMessage.contains("$")
        
        if textAccountingKeywords.contains(where: lowercasedMessage.contains) && hasTransactionDescription {
            return .textAccounting
        }
        
        // 投資相關
        let investmentKeywords = ["投資", "股票", "基金", "證券", "投資組合", "理財", "投資建議", "投資策略", "portfolio", "investment", "stock", "fund"]
        if investmentKeywords.contains(where: lowercasedMessage.contains) {
            return .investment
        }
        
        // 記帳相關（一般性）
        let accountingKeywords = ["記帳", "支出", "收入", "花費", "消費", "支付", "花錢", "賺錢", "交易", "帳單", "發票", "accounting", "expense", "income", "spend", "pay"]
        if accountingKeywords.contains(where: lowercasedMessage.contains) {
            return .accounting
        }
        
        // 建議相關
        let adviceKeywords = ["建議", "幫助", "怎麼辦", "如何", "應該", "推薦", "advice", "help", "how", "should", "recommend"]
        if adviceKeywords.contains(where: lowercasedMessage.contains) {
            return .advice
        }
        
        // 分析相關
        let analysisKeywords = ["分析", "報告", "統計", "查看", "了解", "檢視", "analysis", "report", "statistics", "view", "check"]
        if analysisKeywords.contains(where: lowercasedMessage.contains) {
            return .analysis
        }
        
        // 默認返回一般意圖
        return .general
    }
    
    private func generateResponseBasedOnAnalysis(
        analysis: MessageAnalysisResult,
        context: ConversationContext,
        hasVGLA: Bool = true
    ) -> String {
        let baseResponse: String
        switch analysis.intent {
        case .investment:
            baseResponse = generateInvestmentResponse(context: context, hasVGLA: hasVGLA, sentiment: analysis.sentiment)
        case .accounting:
            baseResponse = generateAccountingResponse(context: context, hasVGLA: hasVGLA, sentiment: analysis.sentiment)
        case .advice:
            baseResponse = generateAdviceResponse(context: context, hasVGLA: hasVGLA, sentiment: analysis.sentiment)
        case .analysis:
            baseResponse = generateAnalysisResponse(context: context, hasVGLA: hasVGLA, sentiment: analysis.sentiment)
        case .textAccounting:
            baseResponse = generateTextAccountingResponse(context: context, sentiment: analysis.sentiment)
        case .photoAccounting:
            baseResponse = generatePhotoAccountingResponse(context: context, sentiment: analysis.sentiment)
        case .queryTransactions:
            baseResponse = generateQueryTransactionsResponse(context: context, sentiment: analysis.sentiment)
        case .openCamera:
            baseResponse = generateOpenCameraResponse(context: context, sentiment: analysis.sentiment)
        case .general:
            baseResponse = generateGeneralResponse(context: context, hasVGLA: hasVGLA, sentiment: analysis.sentiment)
        }
        
        // 根據情感調整回應的語氣和風格
        let emotionalResponse = adjustResponseWithEmotion(baseResponse, sentiment: analysis.sentiment)
        
        // 添加互動性：在回應末尾添加引導性問題
        let followUpQuestion = generateFollowUpQuestion(intent: analysis.intent, context: context, sentiment: analysis.sentiment)
        return emotionalResponse + "\n\n" + followUpQuestion
    }
    
    /// 根據用戶情感調整回應的語氣和風格
    private func adjustResponseWithEmotion(_ response: String, sentiment: Double) -> String {
        // 情感分數範圍：-1.0 (非常負面) 到 1.0 (非常正面)
        if sentiment < -0.3 {
            // 用戶情緒較負面，使用更溫暖、關心的語氣
            return addEmpatheticTone(response)
        } else if sentiment < 0.0 {
            // 用戶情緒稍微負面，使用鼓勵和支持的語氣
            return addEncouragingTone(response)
        } else if sentiment > 0.3 {
            // 用戶情緒正面，使用積極、共鳴的語氣
            return addPositiveTone(response)
        } else {
            // 中性情緒，保持專業友好的語氣
            return response
        }
    }
    
    /// 添加同理心語氣（針對負面情緒）
    private func addEmpatheticTone(_ response: String) -> String {
        let empatheticPhrases = [
            "我理解您的感受",
            "我知道這可能不容易",
            "我明白您的擔憂",
            "我能感受到您的壓力",
            "這確實是個挑戰"
        ]
        
        if let phrase = empatheticPhrases.randomElement() {
            return "\(phrase)，讓我來幫助您。\n\n\(response)"
        }
        return response
    }
    
    /// 添加鼓勵語氣（針對稍微負面情緒）
    private func addEncouragingTone(_ response: String) -> String {
        let encouragingPhrases = [
            "沒關係，我們一步一步來",
            "別擔心，我會陪伴您一起解決",
            "讓我們一起面對這個挑戰",
            "我相信您可以做到的",
            "每一個小步驟都是進步"
        ]
        
        if let phrase = encouragingPhrases.randomElement() {
            return "\(phrase)！\n\n\(response)"
        }
        return response
    }
    
    /// 添加積極語氣（針對正面情緒）
    private func addPositiveTone(_ response: String) -> String {
        let positivePhrases = [
            "太好了！",
            "很棒的想法！",
            "我為您感到高興！",
            "讓我們繼續保持這個積極的態度！",
            "這是很棒的開始！"
        ]
        
        if let phrase = positivePhrases.randomElement() {
            return "\(phrase)\n\n\(response)"
        }
        return response
    }
    
    /// 生成後續引導問題，增強互動性
    private func generateFollowUpQuestion(intent: MessageIntent, context: ConversationContext, sentiment: Double) -> String {
        let localizationManager = LocalizationManager.shared
        let isChinese = localizationManager.currentLanguage != .english
        
        // 根據情感調整問題的語氣
        let emotionalPrefix: String
        if sentiment < -0.3 {
            emotionalPrefix = isChinese ? "💝 別擔心，" : "💝 Don't worry, "
        } else if sentiment < 0.0 {
            emotionalPrefix = isChinese ? "🤝 讓我們一起，" : "🤝 Let's work together, "
        } else if sentiment > 0.3 {
            emotionalPrefix = isChinese ? "✨ 太好了！" : "✨ Great! "
        } else {
            emotionalPrefix = ""
        }
        
        switch intent {
        case .investment:
            if isChinese {
                let base = "💬 您還想了解：\n• 如何開始投資？\n• 適合我的投資組合？\n• 投資風險管理？\n\n告訴我您想先討論哪一個！"
                return emotionalPrefix.isEmpty ? base : "\(emotionalPrefix)\n\n\(base)"
            } else {
                let base = "💬 Would you like to know:\n• How to start investing?\n• Investment portfolio for me?\n• Investment risk management?\n\nTell me which one you'd like to discuss!"
                return emotionalPrefix.isEmpty ? base : "\(emotionalPrefix)\n\n\(base)"
            }
        case .accounting:
            if isChinese {
                let base = "💬 我可以幫您：\n• 記錄今天的收支\n• 分析這個月的支出\n• 設定預算目標\n\n告訴我您想先做什麼！"
                return emotionalPrefix.isEmpty ? base : "\(emotionalPrefix)\n\n\(base)"
            } else {
                let base = "💬 I can help you:\n• Record today's transactions\n• Analyze this month's expenses\n• Set budget goals\n\nTell me what you'd like to do first!"
                return emotionalPrefix.isEmpty ? base : "\(emotionalPrefix)\n\n\(base)"
            }
        case .advice:
            if isChinese {
                let base = "💬 您還想知道：\n• 如何提升財務健康？\n• 債務管理建議？\n• 儲蓄計劃？\n\n告訴我您的優先需求！"
                return emotionalPrefix.isEmpty ? base : "\(emotionalPrefix)\n\n\(base)"
            } else {
                let base = "💬 Would you like to know:\n• How to improve financial health?\n• Debt management advice?\n• Savings plan?\n\nTell me your priority!"
                return emotionalPrefix.isEmpty ? base : "\(emotionalPrefix)\n\n\(base)"
            }
        case .analysis:
            if isChinese {
                let base = "💬 我可以為您：\n• 分析財務趨勢\n• 生成財務報告\n• 查看詳細統計\n\n告訴我您想看什麼！"
                return emotionalPrefix.isEmpty ? base : "\(emotionalPrefix)\n\n\(base)"
            } else {
                let base = "💬 I can provide:\n• Financial trend analysis\n• Financial reports\n• Detailed statistics\n\nTell me what you'd like to see!"
                return emotionalPrefix.isEmpty ? base : "\(emotionalPrefix)\n\n\(base)"
            }
        case .textAccounting:
            if isChinese {
                let base = "💬 請直接告訴我您的交易內容，我會立即為您記錄！\n\n例如：「午餐花了 150 元」或「收到薪水 50000 元」"
                return emotionalPrefix.isEmpty ? base : "\(emotionalPrefix)\n\n\(base)"
            } else {
                let base = "💬 Please tell me your transaction directly, and I'll record it immediately!\n\nFor example: \"Lunch cost 150 dollars\" or \"Received salary 50000 dollars\""
                return emotionalPrefix.isEmpty ? base : "\(emotionalPrefix)\n\n\(base)"
            }
        case .photoAccounting:
            if isChinese {
                let base = "💬 準備好了嗎？讓我為您開啟相機進行拍照記帳！"
                return emotionalPrefix.isEmpty ? base : "\(emotionalPrefix)\n\n\(base)"
            } else {
                let base = "💬 Ready? Let me open the camera for photo accounting!"
                return emotionalPrefix.isEmpty ? base : "\(emotionalPrefix)\n\n\(base)"
            }
        case .queryTransactions:
            if isChinese {
                let base = "💬 我可以為您顯示：\n• 今天的交易記錄\n• 本週的交易記錄\n• 本月的交易記錄\n• 所有交易記錄\n\n告訴我您想查看哪個時期的記錄？"
                return emotionalPrefix.isEmpty ? base : "\(emotionalPrefix)\n\n\(base)"
            } else {
                let base = "💬 I can show you:\n• Today's transactions\n• This week's transactions\n• This month's transactions\n• All transactions\n\nTell me which period you'd like to see?"
                return emotionalPrefix.isEmpty ? base : "\(emotionalPrefix)\n\n\(base)"
            }
        case .openCamera:
            if isChinese {
                let base = "💬 好的！讓我為您開啟相機。您可以用它來拍攝發票或收據進行記帳。"
                return emotionalPrefix.isEmpty ? base : "\(emotionalPrefix)\n\n\(base)"
            } else {
                let base = "💬 Great! Let me open the camera for you. You can use it to take photos of receipts for accounting."
                return emotionalPrefix.isEmpty ? base : "\(emotionalPrefix)\n\n\(base)"
            }
        case .general:
            if isChinese {
                let base = "💬 我可以幫助您：\n• 📊 記錄和管理財務\n• 💰 提供投資建議\n• 📈 分析財務狀況\n• 🎯 設定財務目標\n\n告訴我您想要什麼幫助！"
                return emotionalPrefix.isEmpty ? base : "\(emotionalPrefix)\n\n\(base)"
            } else {
                let base = "💬 I can help you:\n• 📊 Record and manage finances\n• 💰 Provide investment advice\n• 📈 Analyze financial situation\n• 🎯 Set financial goals\n\nTell me what you'd like help with!"
                return emotionalPrefix.isEmpty ? base : "\(emotionalPrefix)\n\n\(base)"
            }
        }
    }
    
    private func generateInvestmentResponse(context: ConversationContext, hasVGLA: Bool, sentiment: Double) -> String {
        if hasVGLA && context.vglaType.count == 2 {
            // 有 VGLA 結果，提供個性化建議
            let vglaAdvice = getVGLAInvestmentAdvice(vglaType: context.vglaType)
            return """
            我了解您對投資的關注。🌟
            
            基於您的 VGLA 類型 **\(context.vglaType)**，我為您提供以下個性化投資建議：
            
            \(vglaAdvice)
            
            '不要為明天憂慮，因為明天自有明天的憂慮。'讓我們一起規劃適合您的投資組合。
            """
        } else {
            // 沒有 VGLA 結果，提供一般性建議
            return """
            我了解您對投資的關注。💰
            
            作為一個財務顧問，我建議您：
            • 建立緊急預備金（3-6個月生活費）
            • 分散投資風險
            • 長期持有優質資產
            • 定期檢視投資組合
            
            💡 **想要更個性化的投資建議嗎？**
            完成 VGLA 測驗後，我可以根據您的思考模式提供更精準的投資策略！
            
            '不要為明天憂慮，因為明天自有明天的憂慮。'讓我們一起規劃您的投資組合。
            """
        }
    }
    
    private func generateAccountingResponse(context: ConversationContext, hasVGLA: Bool, sentiment: Double) -> String {
        if hasVGLA && context.vglaType.count == 2 {
            return """
            記帳是理財的基礎。📝
            
            基於您的 VGLA 類型 **\(context.vglaType)**，我建議您採用以下記帳方式：
            \(getVGLAAccountingAdvice(vglaType: context.vglaType))
            
            '凡有的，還要加給他，叫他多餘。'讓我們善用每一分錢。
            """
        } else {
            return """
            記帳是理財的基礎。📝
            
            我建議您：
            • 每日記錄所有收支
            • 使用分類標籤
            • 定期檢視和分析
            • 設定預算目標
            
            💡 完成 VGLA 測驗後，我可以為您提供更符合您思考習慣的記帳建議！
            
            '凡有的，還要加給他，叫他多餘。'讓我們善用每一分錢。
            """
        }
    }
    
    private func generateAdviceResponse(context: ConversationContext, hasVGLA: Bool, sentiment: Double) -> String {
        if hasVGLA && context.vglaType.count == 2 {
            return """
            我很樂意為您提供財務建議。💡
            
            基於您的 VGLA 類型 **\(context.vglaType)** 和財務健康狀況 **\(context.financialHealth)**，我建議您：
            \(getVGLAAdvice(vglaType: context.vglaType, financialHealth: context.financialHealth))
            
            '智慧人積存知識，愚妄人的口速致敗壞。'讓我們一起學習理財智慧。
            """
        } else {
            return """
            我很樂意為您提供財務建議。💡
            
            基於您的財務健康狀況 **\(context.financialHealth)**，我建議您：
            • 建立緊急預備金（3-6個月生活費）
            • 優先償還高利率債務
            • 開始長期投資計劃
            • 定期檢視財務目標
            
            💡 **想要更精準的建議嗎？**
            完成 VGLA 測驗後，我可以根據您的思考模式提供更個性化的財務建議！
            
            '智慧人積存知識，愚妄人的口速致敗壞。'讓我們一起學習理財智慧。
            """
        }
    }
    
    private func generateAnalysisResponse(context: ConversationContext, hasVGLA: Bool, sentiment: Double) -> String {
        if hasVGLA && context.vglaType.count == 2 {
            return """
            讓我為您分析財務數據。📊
            
            基於您的 VGLA 類型 **\(context.vglaType)**，我發現：
            \(getVGLAnalysis(vglaType: context.vglaType))
            
            '你要詳細知道你羊群的景況，留心料理你的牛群。'讓我們深入了解您的財務狀況。
            """
        } else {
            return """
            讓我為您分析財務數據。📊
            
            基於您最近的交易和投資組合，我建議您：
            • 定期檢視支出趨勢
            • 分析收入來源
            • 評估投資表現
            • 調整理財策略
            
            💡 完成 VGLA 測驗後，我可以為您提供更符合您決策風格的財務分析！
            
            '你要詳細知道你羊群的景況，留心料理你的牛群。'讓我們深入了解您的財務狀況。
            """
        }
    }
    
    /// 生成對話建議，用於快速互動
    func generateConversationSuggestions(context: ConversationContext) -> [ConversationSuggestion] {
        let localizationManager = LocalizationManager.shared
        let isChinese = localizationManager.currentLanguage != .english
        
        var suggestions: [ConversationSuggestion] = []
        
        if isChinese {
            suggestions = [
                ConversationSuggestion(
                    title: "📊 查看財務狀況",
                    content: "幫我分析一下我的財務狀況",
                    action: "查看財務狀況"
                ),
                ConversationSuggestion(
                    title: "💰 投資建議",
                    content: "給我一些投資建議",
                    action: "投資建議"
                ),
                ConversationSuggestion(
                    title: "📝 記帳幫助",
                    content: "教我怎么記帳比較好",
                    action: "記帳幫助"
                ),
                ConversationSuggestion(
                    title: "🎯 設定目標",
                    content: "幫我設定財務目標",
                    action: "設定目標"
                )
            ]
        } else {
            suggestions = [
                ConversationSuggestion(
                    title: "📊 View Financial Status",
                    content: "Help me analyze my financial situation",
                    action: "View Financial Status"
                ),
                ConversationSuggestion(
                    title: "💰 Investment Advice",
                    content: "Give me some investment advice",
                    action: "Investment Advice"
                ),
                ConversationSuggestion(
                    title: "📝 Accounting Help",
                    content: "Teach me how to do accounting better",
                    action: "Accounting Help"
                ),
                ConversationSuggestion(
                    title: "🎯 Set Goals",
                    content: "Help me set financial goals",
                    action: "Set Goals"
                )
            ]
        }
        
        return suggestions
    }
    
    private func generateGeneralResponse(context: ConversationContext, hasVGLA: Bool, sentiment: Double) -> String {
        let vglaSection = hasVGLA && context.vglaType.count == 2 ? 
            "基於您的 VGLA 類型 **\(context.vglaType)**，我了解您的思考方式。\n\n" : 
            "💡 **完成 VGLA 測驗**後，我可以根據您的思考模式提供更個性化的建議。\n\n"
        
        return """
        您好！我是您的財務顧問 Gabriel。🌟
        
        \(vglaSection)我很樂意為您提供以下服務：
        
        💰 **記帳與財務管理**
        • 記錄日常收支
        • 分類和標籤管理
        • 預算規劃
        
        📈 **投資與理財**
        • 投資組合分析
        • 風險評估
        • 投資建議
        
        📊 **財務分析**
        • 財務健康評分
        • 趨勢分析
        • 報表生成
        
        📋 **VGLA 測驗**
        • 了解您的思考模式
        • 獲得個性化建議
        
        請告訴我您想要做什麼，我會為您提供專業的幫助！
        
        '敬畏耶和華是智慧的開端。' 讓我們一起在理財路上尋求智慧。
        """
    }
    
    // MARK: - VGLA 個性化建議生成
    
    private func getVGLAInvestmentAdvice(vglaType: String) -> String {
        switch vglaType.uppercased() {
        case "VG", "GV":
            return """
            • **視覺型 + 恩典型**：您傾向於視覺化投資和長期持有
            • 建議關注圖表分析和趨勢
            • 適合穩健型基金和長期投資
            """
        case "VL", "LV":
            return """
            • **視覺型 + 邏輯型**：您注重數據分析和邏輯判斷
            • 建議深入研究財務報表和市場數據
            • 適合價值投資和量化策略
            """
        case "VA", "AV":
            return """
            • **視覺型 + 行動型**：您是行動派，喜歡快速決策
            • 建議設定明確的止損和止盈點
            • 適合波段操作和技術分析
            """
        case "GL", "LG":
            return """
            • **恩典型 + 邏輯型**：您平衡人際關係和理性分析
            • 建議考慮 ESG 投資和長期價值
            • 適合平衡型基金和多元化配置
            """
        case "GA", "AG":
            return """
            • **恩典型 + 行動型**：您注重人際關係且行動果斷
            • 建議關注團隊管理和合作投資
            • 適合共同基金和信託產品
            """
        case "LA", "AL":
            return """
            • **邏輯型 + 行動型**：您理性分析且執行力強
            • 建議建立系統化的投資流程
            • 適合主動投資和策略交易
            """
        default:
            return """
            • 基於您的 VGLA 類型，建議採用多元化投資策略
            • 平衡風險與收益
            • 定期檢視和調整
            """
        }
    }
    
    private func getVGLAAccountingAdvice(vglaType: String) -> String {
        switch vglaType.uppercased().prefix(1) {
        case "V":
            return """
            • 使用視覺化圖表和圖標分類
            • 建議使用顏色標籤區分
            • 每月檢視視覺化報表
            """
        case "G":
            return """
            • 重視人際關係相關的支出記錄
            • 建議記錄社交和人情支出
            • 定期與家人討論財務狀況
            """
        case "L":
            return """
            • 建立系統化的分類和標籤
            • 建議使用詳細的子分類
            • 定期進行數據分析
            """
        case "A":
            return """
            • 簡化記帳流程，快速記錄
            • 建議使用自動分類功能
            • 每天固定時間快速記帳
            """
        default:
            return "• 根據您的習慣選擇記帳方式\n• 保持持續記錄\n• 定期檢視分析"
        }
    }
    
    private func getVGLAAdvice(vglaType: String, financialHealth: String) -> String {
        let primaryType = String(vglaType.uppercased().prefix(1))
        switch primaryType {
        case "V":
            return "• 建立視覺化的財務目標圖表\n• 使用顏色標示不同優先級\n• 定期檢視視覺化進度"
        case "G":
            return "• 與信任的理財顧問討論\n• 考慮家庭財務規劃\n• 注重人際關係中的財務影響"
        case "L":
            return "• 制定詳細的財務計劃\n• 分析各種方案的優劣\n• 建立系統化的評估機制"
        case "A":
            return "• 立即行動，設定具體目標\n• 簡化決策流程\n• 快速執行和調整"
        default:
            return "• 建立緊急預備金\n• 長期投資計劃\n• 定期檢視財務狀況"
        }
    }
    
    private func getVGLAnalysis(vglaType: String) -> String {
        let primaryType = String(vglaType.uppercased().prefix(1))
        switch primaryType {
        case "V":
            return "• 您適合視覺化的財務報表\n• 建議關注圖表趨勢和模式\n• 重視長期的視覺化目標"
        case "G":
            return "• 您重視人際關係的財務影響\n• 建議平衡個人和家庭財務\n• 注重團隊協作的財務決策"
        case "L":
            return "• 您擅長邏輯分析財務數據\n• 建議深入分析各項指標\n• 重視系統化的財務規劃"
        case "A":
            return "• 您傾向快速決策和行動\n• 建議設定明確的執行步驟\n• 重視即時調整和優化"
        default:
            return "• 定期檢視財務狀況\n• 分析收支趨勢\n• 優化理財策略"
        }
    }
    
    // MARK: - OpenAI 對話處理
    
    private func processConversationWithOpenAI(
        userMessage: String,
        context: ConversationContext
    ) async throws -> AIProcessingRouter.ProcessingResult<String> {
        let startTime = Date()
        
        let response = try await generateOpenAIConversationResponse(
            userMessage: userMessage,
            context: context
        )
        let processingTime = Date().timeIntervalSince(startTime)
        let cost = 0.0 // 成本計算由 APIUsageTracker 處理
        
        performanceMonitor.recordOpenAIProcessing(
            success: true,
            processingTime: processingTime,
            confidence: 1.0,
            cost: cost
        )
        
        return AIProcessingRouter.ProcessingResult(
            data: response,
            source: .openAI,
            confidence: 1.0,
            processingTime: processingTime,
            fallbackUsed: false
        )
    }
    
    private func generateOpenAIConversationResponse(
        userMessage: String,
        context: ConversationContext
    ) async throws -> String {
        // 先分析用戶訊息的情感
        let sentimentAnalysis = await naturalLanguageProcessor.analyzeSentiment(userMessage)
        
        // 在上下文中添加情感資訊
        var enhancedContext = context
        let enhancedMessages = buildOpenAIMessages(
            userMessage: userMessage,
            context: enhancedContext,
            sentiment: sentimentAnalysis.score
        )
        
        let response = try await openAIService.chat(messages: enhancedMessages)
        
        // 根據情感調整回應
        return adjustResponseWithEmotion(response, sentiment: sentimentAnalysis.score)
    }
    
    // MARK: - 輔助方法
    
    private func assessMessageComplexity(_ message: String) -> Double {
        let wordCount = message.components(separatedBy: .whitespacesAndNewlines).count
        let sentenceCount = message.components(separatedBy: CharacterSet(charactersIn: ".!?")).count - 1
        let hasNumbers = message.rangeOfCharacter(from: CharacterSet.decimalDigits) != nil
        let hasSpecialChars = message.rangeOfCharacter(from: CharacterSet.punctuationCharacters) != nil
        
        var complexity: Double = 0.0
        
        if wordCount > 50 { complexity += 0.4 }
        else if wordCount > 20 { complexity += 0.2 }
        
        if sentenceCount > 3 { complexity += 0.3 }
        
        if hasNumbers { complexity += 0.1 }
        if hasSpecialChars { complexity += 0.1 }
        
        return min(complexity, 1.0)
    }
    
    private func getDeviceCapability() -> Double {
        return 0.8 // 假設為中高端設備
    }
    
    private func estimateTokensForMessage(userMessage: String, context: ConversationContext) -> Int {
        let messageTokens = userMessage.count / 4 // 粗略估算
        let contextTokens = 200 // 上下文固定 token 數
        return messageTokens + contextTokens
    }
    
    // MARK: - 對話管理
    
    func buildOpenAIMessages(userMessage: String, context: ConversationContext) -> [OpenAIMessage] {
        var messages: [OpenAIMessage] = []
        
        // 將 ConversationContext 轉換為描述性字符串
        let contextString = """
        當前話題: \(context.currentTopic)
        用戶目標: \(context.userGoals.joined(separator: ", "))
        VGLA 類型: \(context.vglaType)
        財務健康: \(context.financialHealth)
        """
        
        // 添加系統提示
        if let user = currentConversation?.user {
            let systemPrompt = buildSystemPrompt(for: user, context: contextString)
            messages.append(OpenAIMessage(role: "system", content: systemPrompt))
        }
        
        // 添加對話歷史
        if let conversation = currentConversation {
            for msg in conversation.getLastMessages(count: 10) { // 最近 10 條訊息
                let role = msg.type.rawValue
                messages.append(OpenAIMessage(role: role, content: msg.content))
            }
        }
        
        // 添加當前用戶訊息
        messages.append(OpenAIMessage(role: "user", content: userMessage))
        
        return messages
    }
    
    func startNewConversation(user: User, title: String = "與加百列對話") -> Conversation {
        let conversation = Conversation(title: title, vglaType: user.vglaPrimaryType)
        conversation.user = user
        currentConversation = conversation
        
        // 添加歡迎訊息
        let welcomeMessage = createWelcomeMessage(for: user)
        conversation.addMessage(welcomeMessage)
        
        return conversation
    }
    
    func continueConversation(_ conversation: Conversation) {
        currentConversation = conversation
    }
    
    func endCurrentConversation() {
        currentConversation?.endConversation()
        currentConversation = nil
        suggestions = []
    }
    
    // MARK: - 訊息處理
    
    func addMessage(_ message: Message) {
        currentConversation?.addMessage(message)
    }
    
    func sendUserMessage(_ content: String, contentType: MessageContentType = .text) {
        let userMessage = Message(
            type: .user,
            contentType: contentType,
            content: content
        )
        addMessage(userMessage)
        
        // 處理使用者訊息並生成回應
        Task {
            await processUserMessage(content, contentType: contentType)
        }
    }
    
    func sendUserVoiceMessage(_ audioData: Data) {
        Task {
            do {
                // 轉錄語音
                let transcribedText = try await openAIService.transcribeAudio(audioData: audioData)
                
                // 添加轉錄訊息
                let voiceMessage = Message(
                    type: .user,
                    contentType: .voice,
                    content: transcribedText,
                    metadata: ["audio_data": "voice_file_path"]
                )
                addMessage(voiceMessage)
                
                // 處理轉錄文字
                await processUserMessage(transcribedText, contentType: .voice)
                
            } catch {
                // 處理錯誤
                let errorMessage = Message(
                    type: .assistant,
                    contentType: .text,
                    content: "抱歉，我無法理解您的語音訊息。請再試一次，或改用文字輸入。"
                )
                addMessage(errorMessage)
            }
        }
    }
    
    func sendUserImageMessage(_ imageData: Data, description: String) {
        Task {
            do {
                // 分析圖片
                let analysisResult = try await openAIService.analyzeReceipt(imageData: imageData)
                
                // 添加圖片訊息
                let imageMessage = Message(
                    type: .user,
                    contentType: .image,
                    content: description,
                    metadata: ["image_data": "image_file_path", "analysis": "\(analysisResult)"]
                )
                addMessage(imageMessage)
                
                // 處理分析結果
                await processImageAnalysis(analysisResult)
                
            } catch {
                // 處理錯誤
                let errorMessage = Message(
                    type: .assistant,
                    contentType: .text,
                    content: "抱歉，我無法分析這張圖片。請確保圖片清晰，或改用文字描述。"
                )
                addMessage(errorMessage)
            }
        }
    }
    
    // MARK: - AI 回應生成
    
    private func processUserMessage(_ content: String, contentType: MessageContentType) async {
        isTyping = true
        
        do {
            guard let conversation = currentConversation,
                  let user = conversation.user else {
                isTyping = false
                return
            }
            
            // 建立對話上下文，正確檢測 VGLA 完成狀態
            let vglaType: String
            if user.vglaCompleted, let combinationType = user.vglaCombinationType, !combinationType.isEmpty {
                // 有完整的組合類型
                vglaType = combinationType
            } else if let primaryType = user.vglaPrimaryType, !primaryType.isEmpty {
                // 只有主要類型，未完成測驗
                vglaType = "未知"
            } else {
                // 未完成測驗
                vglaType = "未知"
            }
            
            // 獲取財務健康評分
            let financialHealth: String
            let score = user.financialHealthScore
            if score >= 80 {
                financialHealth = "優秀"
            } else if score >= 60 {
                financialHealth = "良好"
            } else if score >= 40 {
                financialHealth = "一般"
            } else {
                financialHealth = "需要改善"
            }
            
            let context = ConversationContext(
                currentTopic: conversation.title.isEmpty ? "general_chat" : conversation.title,
                userGoals: user.goals.map { $0.title },
                recentTransactions: [],
                financialHealth: financialHealth,
                vglaType: vglaType,
                tkiMode: user.tkiPrimaryMode,
                hasIntegratedAnalysis: user.hasIntegratedAnalysis,
                lastAdvice: nil
            )
            
            // 優先使用原生 AI 智能路由處理對話
            let aiResponse = try await processConversationWithIntelligentRouting(
                userMessage: content,
                context: context
            )
            
            // 添加 AI 回應
            let assistantMessage = Message(
                type: .assistant,
                contentType: .text,
                content: aiResponse
            )
            addMessage(assistantMessage)
            
            // 更新建議
            await updateSuggestions(content: content, response: aiResponse)
            
        } catch {
            // 處理錯誤
            let errorMessage = Message(
                type: .assistant,
                contentType: .text,
                content: "抱歉，我現在無法回應。請稍後再試，或檢查您的網路連線。"
            )
            addMessage(errorMessage)
        }
        
        isTyping = false
    }
    
    private func processImageAnalysis(_ result: TransactionParseResult) async {
        isTyping = true
        
        let analysisMessage = Message(
            type: .assistant,
            contentType: .text,
            content: createImageAnalysisResponse(result)
        )
        addMessage(analysisMessage)
        
        isTyping = false
    }
    
    // MARK: - 上下文建立
    
    private func buildConversationContext(user: User, conversation: Conversation) -> ConversationContext {
        return ConversationContext(
            currentTopic: conversation.context ?? "一般對話",
            userGoals: user.goals.map { $0.title },
            recentTransactions: [], // 從最近的交易中獲取
            financialHealth: "\(user.financialHealthScore)/100",
            vglaType: user.vglaPrimaryType ?? "未知",
            tkiMode: user.tkiPrimaryMode,
            hasIntegratedAnalysis: user.hasIntegratedAnalysis,
            lastAdvice: nil // 從對話歷史中獲取
        )
    }
    
    private func buildMessageHistory(conversation: Conversation) -> [OpenAIMessage] {
        let messages = conversation.getLastMessages(count: 10)
        return messages.map { message in
            OpenAIMessage(
                role: message.type.rawValue,
                content: message.content
            )
        }
    }
    
    private func determineContext(_ content: String) -> String {
        let lowercased = content.lowercased()
        
        if lowercased.contains("記帳") || lowercased.contains("花費") || lowercased.contains("支出") {
            return "transaction_analysis"
        } else if lowercased.contains("目標") || lowercased.contains("夢想") || lowercased.contains("計劃") {
            return "goal_setting"
        } else if lowercased.contains("投資") || lowercased.contains("理財") || lowercased.contains("建議") {
            return "financial_advice"
        } else {
            return "general"
        }
    }
    
    // MARK: - 建議更新
    
    private func updateSuggestions(content: String, response: String) async {
        // 根據對話內容和回應生成建議
        let newSuggestions = generateSuggestions(content: content, response: response)
        
        await MainActor.run {
            self.suggestions = newSuggestions
        }
    }
    
    private func generateSuggestions(content: String, response: String) -> [ConversationSuggestion] {
        var suggestions: [ConversationSuggestion] = []
        
        // 根據內容類型生成建議
        if content.contains("記帳") {
            suggestions.append(ConversationSuggestion(
                title: "快速記帳",
                content: "記錄今天的支出",
                action: "quick_entry"
            ))
        }
        
        if content.contains("目標") {
            suggestions.append(ConversationSuggestion(
                title: "設定目標",
                content: "建立新的財務目標",
                action: "set_goal"
            ))
        }
        
        if content.contains("報表") {
            suggestions.append(ConversationSuggestion(
                title: "生成報表",
                content: "查看財務報表",
                action: "generate_report"
            ))
        }
        
        // 預設建議
        if suggestions.isEmpty {
            suggestions.append(ConversationSuggestion(
                title: "記一筆帳",
                content: "記錄收支",
                action: "add_transaction"
            ))
            suggestions.append(ConversationSuggestion(
                title: "查看目標",
                content: "檢視財務目標",
                action: "view_goals"
            ))
            suggestions.append(ConversationSuggestion(
                title: "財務建議",
                content: "獲取理財建議",
                action: "get_advice"
            ))
        }
        
        return suggestions
    }
    
    // MARK: - 歡迎訊息
    
    private func createWelcomeMessage(for user: User) -> Message {
        let vglaType = user.vglaPrimaryType ?? "V"
        let tkiMode = user.tkiPrimaryMode
        let hasIntegratedAnalysis = user.hasIntegratedAnalysis
        let welcomeText = getWelcomeText(for: vglaType, tkiMode: tkiMode, hasIntegratedAnalysis: hasIntegratedAnalysis)
        
        return Message(
            type: .assistant,
            contentType: .text,
            content: welcomeText
        )
    }
    
    private func getWelcomeText(for vglaType: String, tkiMode: String?, hasIntegratedAnalysis: Bool) -> String {
        // 基礎歡迎訊息
        let baseWelcome = getBaseWelcomeMessage(for: vglaType)
        
        // 如果有整合分析，添加 TKI 相關內容
        if hasIntegratedAnalysis, let tkiMode = tkiMode {
            let tkiInsight = getTKIInsight(for: tkiMode)
            return baseWelcome + "\n\n" + tkiInsight
        }
        
        return baseWelcome
    }
    
    private func getBaseWelcomeMessage(for vglaType: String) -> String {
        switch vglaType {
        case "V":
            return """
            你好！我是加百列，你的 AI CFO 財務顧問。🌟
            
            我看到你是一個重視願景和意義的人。讓我們一起規劃你的財務未來，讓每一分錢都能幫助你實現人生夢想！
            
            今天有什麼財務問題需要我協助嗎？或者想聊聊你的財務目標？
            """
        case "G":
            return """
            你好！我是加百列，你的 AI CFO 財務顧問。💝
            
            我感受到你對家人和關係的重視。讓我們一起建立穩固的財務基礎，保護你所愛的人，創造美好的家庭回憶！
            
            有什麼財務規劃想為家人做的嗎？
            """
        case "L":
            return """
            你好！我是加百列，你的 AI CFO 財務顧問。📊
            
            我了解你喜歡用數據和邏輯來做決策。讓我們一起分析你的財務狀況，制定科學的理財策略！
            
            想先看看你目前的財務數據嗎？
            """
        case "A":
            return """
            你好！我是加百列，你的 AI CFO 財務顧問。⚡
            
            我知道你喜歡立即行動！讓我們快速檢視你的財務狀況，制定可執行的改善計劃！
            
            最想先解決哪個財務問題？
            """
        default:
            return """
            你好！我是加百列，你的 AI CFO 財務顧問。✨
            
            我很高興能陪伴你的理財旅程。讓我們一起建立正確的金錢觀念，讓財務成為祝福而非負擔！
            
            有什麼財務問題需要我協助嗎？
            """
        }
    }
    
    private func getTKIInsight(for tkiMode: String) -> String {
        switch tkiMode {
        case "competing":
            return """
            💪 根據你的決策風格分析，你是一個果斷的決策者！
            
            在財務決策上，你傾向於快速行動並追求最佳結果。這讓你能抓住投資機會，但也需要留意風險控制。
            
            我會為你提供更精準的投資建議和風險評估，幫助你在快速決策中保持理性。
            """
        case "collaborating":
            return """
            🤝 根據你的決策風格分析，你是一個善於協作的規劃者！
            
            你喜歡在財務決策中尋求多方意見，這讓你能做出更全面的規劃。特別適合家庭財務規劃和長期投資。
            
            我會協助你建立完整的財務規劃框架，並提供適合與家人討論的理財建議。
            """
        case "compromising":
            return """
            ⚖️ 根據你的決策風格分析，你是一個平衡的決策者！
            
            你善於在財務決策中尋找平衡點，這讓你能快速達成共識。特別適合日常財務管理和短期目標設定。
            
            我會為你提供實用的日常理財工具和快速可執行的財務改善方案。
            """
        case "avoiding":
            return """
            🤔 根據你的決策風格分析，你是一個謹慎的思考者！
            
            你傾向於在財務決策前充分思考，這能避免衝動決策，但也可能錯過機會。需要適度的行動力。
            
            我會為你提供詳細的財務分析，並適時提醒你把握投資時機，幫助你在謹慎中保持行動力。
            """
        case "accommodating":
            return """
            💝 根據你的決策風格分析，你是一個體貼的決策者！
            
            你總是優先考慮他人的財務需求，這展現了你的愛心，但也需要照顧好自己的財務健康。
            
            我會協助你建立健康的財務界線，在照顧他人的同時，也為自己建立穩固的財務基礎。
            """
        default:
            return """
            根據你的綜合分析，我將為你提供更個人化的財務建議！
            
            我會結合你的思考模式和決策風格，為你量身定制最適合的理財策略。
            """
        }
    }
    
    // MARK: - 圖片分析回應
    
    private func createImageAnalysisResponse(_ result: TransactionParseResult) -> String {
        var response = "我分析了你的發票/收據：\n\n"
        
        if let amount = result.amount {
            response += "💰 金額：NT$ \(String(format: "%.0f", amount))\n"
        }
        
        if let category = result.category {
            response += "📂 分類：\(category)\n"
        }
        
        if let description = result.description {
            response += "📝 描述：\(description)\n"
        }
        
        if let date = result.date {
            response += "📅 日期：\(date)\n"
        }
        
        response += "\n信心度：\(Int(result.confidence * 100))%\n"
        
        if !result.suggestions.isEmpty {
            response += "\n💡 建議：\n"
            for suggestion in result.suggestions {
                response += "• \(suggestion)\n"
            }
        }
        
        response += "\n要將這筆交易加入記帳嗎？"
        
        return response
    }
    
    // 為 ChatView 生成回應
    func generateResponse(userMessage: String, context: String, modelContext: ModelContext) async throws -> String {
        // 獲取用戶資料
        guard let user = try? modelContext.fetch(FetchDescriptor<User>()).first else {
            return "抱歉，我無法找到你的資料。請先完成設定。"
        }
        
        // 建立系統提示
        let systemPrompt = buildSystemPrompt(for: user, context: context)
        
        // 建立對話歷史
        let conversationHistory = buildConversationHistory()
        
        // 建立訊息
        let messages = [
            OpenAIMessage(role: "system", content: systemPrompt),
            OpenAIMessage(role: "user", content: "對話上下文：\(context)"),
            OpenAIMessage(role: "user", content: "使用者訊息：\(userMessage)")
        ] + conversationHistory
        
        // 生成回應
        let response = try await openAIService.chat(messages: messages)
        
        return response
    }
    
    private func buildSystemPrompt(for user: User, context: String) -> String {
        // 使用加百列 AI 服務生成個性化系統提示
        gabrielAI.adaptPersonality(for: user)
        
        var prompt = "你是加百列，一位友善、溫暖、有同理心的 AI CFO。你的使命是幫助用戶建立健康的財務習慣，並基於聖經原則提供建議。\n\n"
        
        // 強調情感和同理心
        prompt += "**重要原則**：\n"
        prompt += "1. **情感感知**：仔細聆聽用戶的情緒，如果用戶表達擔憂、焦慮或負面情緒，請用溫暖、同理心的語氣回應，表達理解和關心。\n"
        prompt += "2. **積極鼓勵**：如果用戶表達正面情緒或成就感，請與他們一起慶祝，使用積極、鼓勵的語氣。\n"
        prompt += "3. **溫暖關懷**：始終以愛心和耐心對待用戶，記住他們不僅僅是數據，而是需要關懷的人。\n"
        prompt += "4. **真誠溝通**：用真誠、自然的語氣對話，避免機械化的回應。\n\n"
        
        // 添加加百列的人格特徵
        prompt += "你的當前人格：\(gabrielAI.currentPersonality.displayName)\n"
        prompt += "你的情緒狀態：\(gabrielAI.currentMood.displayName)\n"
        prompt += "你的對話風格：\(gabrielAI.conversationStyle.displayName)\n\n"
        
        // 添加用戶 VGLA 資訊
        if let vglaType = user.vglaPrimaryType {
            prompt += "用戶的 VGLA 類型：\(vglaType)\n"
        }
        
        // 添加 TKI 資訊（如果有）
        if let tkiMode = user.tkiPrimaryMode {
            prompt += "用戶的 TKI 決策風格：\(tkiMode)\n"
        }
        
        // 添加整合分析資訊
        if user.hasIntegratedAnalysis {
            prompt += "用戶已完成 VGLA + TKI 整合分析，請結合兩種測驗結果提供更精準的建議。\n"
        }
        
        // 添加財務健康資訊
        prompt += "用戶財務健康分數：\(user.financialHealthScore)\n"
        
        // 添加上下文特定提示
        switch context {
        case "general_chat":
            prompt += "請以友善、溫暖、有同理心的語氣回應用戶的問題，仔細感知他們的情緒，並提供實用的財務建議。如果用戶表達擔憂，請先安慰他們，再提供建議。"
        case "transaction_analysis":
            prompt += "請分析用戶的交易記錄，提供洞察和建議。如果發現用戶有財務壓力，請用溫暖的語氣給予鼓勵和支持。"
        case "goal_setting":
            prompt += "請幫助用戶設定和追蹤財務目標。用積極、鼓勵的語氣，幫助他們建立信心。"
        default:
            prompt += "請根據用戶的需求和情緒，提供適當且有同理心的財務建議。"
        }
        
        // 添加個性化建議
        if user.hasIntegratedAnalysis {
            prompt += "\n\n請根據用戶的 VGLA 和 TKI 結果，提供更個人化的財務建議："
            if let vglaType = user.vglaPrimaryType, let tkiMode = user.tkiPrimaryMode {
                prompt += "\n- VGLA 類型：\(vglaType) - 請根據其思考模式調整建議風格"
                prompt += "\n- TKI 風格：\(tkiMode) - 請根據其決策風格提供相應的建議"
            }
        }
        
        // 添加聖經原則
        prompt += "\n\n記住：金錢是神的恩賜，我們是管家。尋求智慧，善用資源，榮耀神。最重要的是，用愛心對待每一個人，因為「愛是永不止息」。"
        
        // 整合聖經原則
        prompt = gabrielAI.integrateBiblicalPrinciples(prompt)
        
        return prompt
    }
    
    private func buildConversationHistory() -> [OpenAIMessage] {
        // 這裡可以添加最近的對話歷史
        // 目前返回空陣列，未來可以實作對話歷史管理
        return []
    }
}

// MARK: - 訊息分析結果

struct MessageAnalysisResult {
    let sentiment: Double
    let language: NLLanguage?
    let intent: MessageIntent
    let confidence: Double
}

// MARK: - 訊息意圖枚舉

enum MessageIntent {
    case investment
    case accounting
    case advice
    case analysis
    case general
    case textAccounting      // 文字記帳
    case photoAccounting      // 拍攝記帳
    case queryTransactions    // 查詢交易歷史
    case openCamera           // 打開相機
}

// MARK: - 錯誤定義

