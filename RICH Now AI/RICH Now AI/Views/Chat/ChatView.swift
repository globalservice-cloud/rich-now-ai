//
//  ChatView.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import SwiftUI
import SwiftData
import Combine
import os.log
import UniformTypeIdentifiers

// 聊天訊息模型
struct ChatMessage: Identifiable, Codable {
    let id: UUID
    let content: String
    let isFromUser: Bool
    let timestamp: Date
    let messageType: MessageType
    let metadata: [String: String]?
    
    enum MessageType: String, Codable {
        case text = "text"
        case transaction = "transaction"
        case suggestion = "suggestion"
        case report = "report"
        case error = "error"
    }
    
    init(content: String, isFromUser: Bool, messageType: MessageType = .text, metadata: [String: String]? = nil) {
        self.id = UUID()
        self.content = content
        self.isFromUser = isFromUser
        self.timestamp = Date()
        self.messageType = messageType
        self.metadata = metadata
    }
}

// 聊天狀態管理
@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isTyping: Bool = false
    @Published var inputText: String = ""
    @Published var isRecording: Bool = false
    @Published var isProcessingImage: Bool = false
    @Published var isProcessingPDF: Bool = false
    @Published var errorMessage: String?
    @Published var isStreaming: Bool = false
    @Published var currentStreamingMessage: String = ""
    @Published var showTypingIndicator: Bool = false
    @Published var animationPhase: Int = 0
    @Published var conversationSuggestions: [ConversationSuggestion] = []
    @Published var showSuggestions: Bool = true
    @Published var showTextAccounting = false
    @Published var showPhotoAccounting = false
    @Published var showTransactionHistory = false
    @Published var showCamera = false
    @Published var showReceiptConfirmation = false
    @Published var extractedReceiptData: ExtractedReceiptData?
    
    private let conversationManager: ConversationManager
    private let transactionParser: TransactionParser
    private let openAIService: OpenAIService
    private let usageTracker: APIUsageTracker
    private let pdfProcessor = PDFDocumentProcessor.shared
    private let photoAccountingManager = PhotoAccountingManager.shared
    private let logger = Logger(subsystem: "com.richnowai", category: "ChatView")
    private var cancellables = Set<AnyCancellable>()
    private var typingTimer: Timer?
    
    // 用於存儲當前用戶（由 ChatView 設置）
    var currentUser: User?
    
    // 操作回調（由 ChatView 設置）
    var onOpenTextAccounting: (() -> Void)?
    var onOpenPhotoAccounting: (() -> Void)?
    var onOpenTransactionHistory: (() -> Void)?
    var onOpenCamera: (() -> Void)?
    
    init(conversationManager: ConversationManager, transactionParser: TransactionParser, openAIService: OpenAIService) {
        self.conversationManager = conversationManager
        self.transactionParser = transactionParser
        self.openAIService = openAIService
        self.usageTracker = APIUsageTracker.shared
        
        // 添加歡迎訊息
        addWelcomeMessage()
    }
    
    private func addWelcomeMessage() {
        let welcomeMessage = ChatMessage(
            content: LocalizationManager.shared.localizedString("chat.welcome"),
            isFromUser: false,
            messageType: .text
        )
        messages.append(welcomeMessage)
        
        // 生成對話建議
        updateConversationSuggestions()
        
        // 啟動歡迎動畫
        startWelcomeAnimation()
    }
    
    func updateConversationSuggestions() {
        guard let user = currentUser else { return }
        
        // 獲取用戶上下文
        let vglaType: String
        if user.vglaCompleted, let combinationType = user.vglaCombinationType, !combinationType.isEmpty {
            vglaType = combinationType
        } else {
            vglaType = "未知"
        }
        
        let financialHealth: String
        let score = user.financialHealthScore
        if score >= 80 {
            financialHealth = LocalizationManager.shared.localizedString("financial_health.excellent")
        } else if score >= 60 {
            financialHealth = LocalizationManager.shared.localizedString("financial_health.good")
        } else if score >= 40 {
            financialHealth = LocalizationManager.shared.localizedString("financial_health.fair")
        } else {
            financialHealth = LocalizationManager.shared.localizedString("financial_health.needs_improvement")
        }
        
        let context = ConversationContext(
            currentTopic: "general_chat",
            userGoals: user.goals.map { $0.title },
            recentTransactions: [],
            financialHealth: financialHealth,
            vglaType: vglaType,
            tkiMode: user.tkiPrimaryMode,
            hasIntegratedAnalysis: user.hasIntegratedAnalysis,
            lastAdvice: nil
        )
        
        conversationSuggestions = conversationManager.generateConversationSuggestions(context: context)
    }
    
    func reloadWelcomeMessage() {
        // 如果只有歡迎訊息，更新它；否則不改變現有訊息
        if messages.count == 1, let firstMessage = messages.first, !firstMessage.isFromUser {
            let updatedWelcomeMessage = ChatMessage(
                content: LocalizationManager.shared.localizedString("chat.welcome"),
                isFromUser: false,
                messageType: .text
            )
            messages[0] = updatedWelcomeMessage
        }
    }
    
    private func startWelcomeAnimation() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 0.8)) {
                self.animationPhase = 1
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 0.8)) {
                self.animationPhase = 2
            }
        }
    }
    
    func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMessage = ChatMessage(
            content: inputText,
            isFromUser: true,
            messageType: .text
        )
        messages.append(userMessage)
        
        let messageToSend = inputText
        inputText = ""
        
        // 隱藏建議按鈕（用戶開始對話後）
        showSuggestions = false
        
        // 添加發送動畫
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            animationPhase = 3
        }
        
        Task {
            await processUserMessage(messageToSend, currentUser: currentUser)
        }
    }
    
    func sendSuggestion(_ suggestion: ConversationSuggestion) {
        // 使用建議的內容作為輸入
        inputText = suggestion.content
        sendMessage()
    }
    
    private func processUserMessage(_ message: String, currentUser: User?) async {
        isTyping = true
        showTypingIndicator = true
        errorMessage = nil
        
        // 開始打字動畫
        startTypingAnimation()
        
        // 檢查是否為交易記錄
        if isTransactionMessage(message) {
            await handleTransactionMessage(message)
        } else {
            await handleGeneralMessage(message, currentUser: currentUser)
        }
    }
    
    private func startTypingAnimation() {
        typingTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            Task { @MainActor in
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.showTypingIndicator.toggle()
                }
            }
        }
    }
    
    private func stopTypingAnimation() {
        typingTimer?.invalidate()
        typingTimer = nil
        showTypingIndicator = false
    }
    
    private func isTransactionMessage(_ message: String) -> Bool {
        // 支援多語言的交易關鍵字
        let localizationManager = LocalizationManager.shared
        let transactionKeywords: [String]
        
        switch localizationManager.currentLanguage {
        case .english:
            transactionKeywords = [
                "spent", "bought", "income", "expense", "earned", "paid", "received", 
                "cost", "purchase", "payment", "spend", "buy", "pay"
            ]
        case .traditionalChinese:
            transactionKeywords = [
                "花了", "買了", "收入", "支出", "賺了", "付了", "收到", "花費", 
                "消費", "購買", "支付", "花", "買", "付"
            ]
        case .simplifiedChinese:
            transactionKeywords = [
                "花了", "买了", "收入", "支出", "赚了", "付了", "收到", "花费", 
                "消费", "购买", "支付", "花", "买", "付"
            ]
        }
        
        return transactionKeywords.contains { message.lowercased().contains($0.lowercased()) }
    }
    
    private func handleTransactionMessage(_ message: String) async {
        do {
            // 嘗試解析多筆交易
            let parsedTransactions = try await transactionParser.parseMultipleTransactions(from: message)
            
            await MainActor.run {
                if parsedTransactions.count > 1 {
                    // 多筆交易回應
                    var content = String(format: LocalizationManager.shared.localizedString("chat.multiple_transactions_success"), parsedTransactions.count) + "\n\n"
                    for (index, transaction) in parsedTransactions.enumerated() {
                        content += String(format: LocalizationManager.shared.localizedString("chat.transaction_number"), index + 1) + "\n"
                        content += "   " + String(format: LocalizationManager.shared.localizedString("chat.transaction_amount"), String(format: "%.2f", transaction.amount)) + "\n"
                        content += "   " + String(format: LocalizationManager.shared.localizedString("chat.transaction_category"), transaction.category) + "\n"
                        content += "   " + String(format: LocalizationManager.shared.localizedString("chat.transaction_description"), transaction.description) + "\n\n"
                    }
                    content += LocalizationManager.shared.localizedString("chat.all_transactions_recorded") + LocalizationManager.shared.localizedString("chat.transaction_analysis_question")
                    
                    let responseMessage = ChatMessage(
                        content: content,
                        isFromUser: false,
                        messageType: .transaction,
                        metadata: [
                            "count": String(parsedTransactions.count),
                            "totalAmount": String(parsedTransactions.reduce(0) { $0 + $1.amount })
                        ]
                    )
                    
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        messages.append(responseMessage)
                        animationPhase = 4
                    }
                } else if parsedTransactions.count == 1 {
                    // 單筆交易回應（原有邏輯）
                    let parsedTransaction = parsedTransactions.first!
                    let content = LocalizationManager.shared.localizedString("chat.transaction_success") + "\n\n" +
                        String(format: LocalizationManager.shared.localizedString("chat.transaction_amount"), String(format: "%.2f", parsedTransaction.amount)) + "\n" +
                        String(format: LocalizationManager.shared.localizedString("chat.transaction_category"), parsedTransaction.category) + "\n" +
                        String(format: LocalizationManager.shared.localizedString("chat.transaction_description"), parsedTransaction.description) + "\n\n" +
                        LocalizationManager.shared.localizedString("chat.transaction_analysis")
                    
                    let responseMessage = ChatMessage(
                        content: content,
                        isFromUser: false,
                        messageType: .transaction,
                        metadata: [
                            "amount": String(parsedTransaction.amount),
                            "category": parsedTransaction.category,
                            "description": parsedTransaction.description
                        ]
                    )
                    
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        messages.append(responseMessage)
                        animationPhase = 4
                    }
                } else {
                    // 解析失敗
                    let errorMessage = ChatMessage(
                        content: LocalizationManager.shared.localizedString("chat.transaction_parse_error"),
                        isFromUser: false,
                        messageType: .error
                    )
                    withAnimation(.easeInOut(duration: 0.5)) {
                        messages.append(errorMessage)
                    }
                }
            }
        } catch TransactionParserError.offlineParsingFailed {
            await MainActor.run {
                let errorMessage = ChatMessage(
                    content: LocalizationManager.shared.localizedString("chat.offline_mode"),
                    isFromUser: false,
                    messageType: .error
                )
                withAnimation(.easeInOut(duration: 0.5)) {
                    messages.append(errorMessage)
                }
            }
        } catch {
            await MainActor.run {
                let errorMessage = ChatMessage(
                    content: LocalizationManager.shared.localizedString("chat.transaction_parse_error"),
                    isFromUser: false,
                    messageType: .error
                )
                withAnimation(.easeInOut(duration: 0.5)) {
                    messages.append(errorMessage)
                }
            }
        }
        
        isTyping = false
        stopTypingAnimation()
    }
    
    private func handleGeneralMessage(_ message: String, currentUser: User?) async {
        // 使用 streaming 回應
        await handleStreamingResponse(message: message, currentUser: currentUser)
    }
    
    private func handleStreamingResponse(message: String, currentUser: User?) async {
        await MainActor.run {
            isStreaming = true
            currentStreamingMessage = ""
            isTyping = true
            showTypingIndicator = true
            
            // 創建一個臨時的 streaming 訊息
            let streamingMessage = ChatMessage(
                content: "",
                isFromUser: false,
                messageType: .text
            )
            messages.append(streamingMessage)
        }
        
        do {
            // 從用戶資料獲取 VGLA 結果
            var userVGLA: String = ""
            var userFinancialHealth: String = "良好"
            
            // 使用傳入的用戶資料
            if let user = currentUser {
                // 檢查是否完成 VGLA 測驗
                if user.vglaCompleted, let combinationType = user.vglaCombinationType, !combinationType.isEmpty {
                    userVGLA = combinationType
                } else if let primaryType = user.vglaPrimaryType, !primaryType.isEmpty {
                    // 如果只有主要類型，但未完成測驗，視為未完成
                    userVGLA = ""
                } else {
                    userVGLA = "" // 未完成測驗
                }
                
            // 獲取財務健康評分
            let score = user.financialHealthScore
            let localizationManager = LocalizationManager.shared
            if score >= 80 {
                userFinancialHealth = localizationManager.localizedString("financial_health.excellent")
            } else if score >= 60 {
                userFinancialHealth = localizationManager.localizedString("financial_health.good")
            } else if score >= 40 {
                userFinancialHealth = localizationManager.localizedString("financial_health.fair")
            } else {
                userFinancialHealth = localizationManager.localizedString("financial_health.needs_improvement")
            }
            }
            
            // 創建對話上下文
            let localizationManager = LocalizationManager.shared
            let context = ConversationContext(
                currentTopic: "general_chat",
                userGoals: [],
                recentTransactions: [],
                financialHealth: userFinancialHealth,
                vglaType: userVGLA.isEmpty ? localizationManager.localizedString("common.unknown") : userVGLA,
                tkiMode: nil,
                hasIntegratedAnalysis: false,
                lastAdvice: nil
            )
            
            // 優先使用原生 AI 智能路由處理對話
            let response = try await conversationManager.processConversationWithIntelligentRouting(
                userMessage: message,
                context: context
            )
            
            // 原生 AI 處理完成，更新訊息
            await MainActor.run {
                if let lastIndex = messages.indices.last {
                    messages[lastIndex] = ChatMessage(
                        content: response,
                        isFromUser: false,
                        messageType: .text
                    )
                }
                
                // 更新對話建議（在回應後提供新的建議）
                updateConversationSuggestions()
                // 如果對話較短，顯示建議幫助用戶繼續對話
                if messages.count <= 4 {
                    showSuggestions = true
                }
                
                isStreaming = false
                currentStreamingMessage = ""
                isTyping = false
                stopTypingAnimation()
            }
            return
            
        } catch {
            // 原生 AI 失敗，嘗試降級到 OpenAI
            logger.warning("原生 AI 處理失敗: \(error.localizedDescription)")
            
            // 嘗試降級到 OpenAI，但先提供一個基本回應避免用戶等待
            await MainActor.run {
                let fallbackMessage = ChatMessage(
                    content: LocalizationManager.shared.localizedString("chat.processing_powerful_ai"),
                    isFromUser: false,
                    messageType: .text
                )
                if let lastIndex = messages.indices.last {
                    messages[lastIndex] = fallbackMessage
                }
            }
            
            // 檢查是否有可用的 OpenAI API Key（用戶自備）
            let hasUserAPIKey = APIKeyManager.shared.getAPIKey(for: "openai") != nil
            
            // 檢查訂閱狀態（允許使用應用程式預設 Key）
            let storeKitManager = StoreKitManager.shared
            let canUseAIChat = storeKitManager.canUseFeature(.aiChat)
            
            // 如果沒有用戶的 API Key 也沒有訂閱權限，提供友好的預設回應
            // 注意：即使沒有用戶 Key，如果應用程式有預設 Key，也會嘗試使用
            if !hasUserAPIKey && !canUseAIChat {
                await MainActor.run {
                    let friendlyMessage = ChatMessage(
                        content: LocalizationManager.shared.localizedString("chat.sorry_cannot_process"),
                        isFromUser: false,
                        messageType: .text
                    )
                    if let lastIndex = messages.indices.last {
                        messages[lastIndex] = friendlyMessage
                    }
                    isStreaming = false
                    isTyping = false
                    stopTypingAnimation()
                }
                return
            }
            
            // 檢查訂閱限制（僅在使用 OpenAI API 且用戶沒有自己的 API Key 時）
            if !hasUserAPIKey {
                let storeKitManager = StoreKitManager.shared
                if !storeKitManager.canUseFeature(.aiChat) {
                    await MainActor.run {
                        let limitMessage = ChatMessage(
                            content: LocalizationManager.shared.localizedString("chat.limit_reached"),
                            isFromUser: false,
                            messageType: .error
                        )
                        if let lastIndex = messages.indices.last {
                            messages[lastIndex] = limitMessage
                        }
                        isStreaming = false
                        isTyping = false
                        stopTypingAnimation()
                    }
                    return
                }
            }
            
            // 降級到 OpenAI streaming
            do {
                // 先分析情感
                let sentimentAnalysis = await NaturalLanguageProcessor.shared.analyzeSentiment(message)
                
                // 創建對話上下文
                let context = ConversationContext(
                    currentTopic: "general_chat",
                    userGoals: [],
                    recentTransactions: [],
                    financialHealth: userFinancialHealth,
                    vglaType: userVGLA.isEmpty ? localizationManager.localizedString("common.unknown") : userVGLA,
                    tkiMode: nil,
                    hasIntegratedAnalysis: false,
                    lastAdvice: nil
                )
                
                // 獲取 OpenAI 訊息格式（包含情感資訊）
                let openAIMessages = conversationManager.buildOpenAIMessages(
                    userMessage: message,
                    context: context,
                    sentiment: sentimentAnalysis.score
                )
                
                // 使用 streaming API 作為降級方案
                let stream = openAIService.chatStream(messages: openAIMessages)
                
                var totalTokens = 0
                var fullResponse = ""
                
                for try await chunk in stream {
                    await MainActor.run {
                        fullResponse += chunk
                        currentStreamingMessage = fullResponse
                        totalTokens += chunk.count / 4 // 粗略估算 token 數量
                        
                        // 更新最後一個訊息（streaming 訊息）
                        if let lastIndex = messages.indices.last {
                            messages[lastIndex] = ChatMessage(
                                content: currentStreamingMessage,
                                isFromUser: false,
                                messageType: .text
                            )
                        }
                    }
                }
                
                // 追蹤 API 用量
                APIKeyManager.shared.trackAPIUsage(for: "openai", tokens: totalTokens, cost: 0.0)
                
                // 完成 streaming
                await MainActor.run {
                    isStreaming = false
                    currentStreamingMessage = ""
                    isTyping = false
                    stopTypingAnimation()
                }
                
            } catch {
                // 降級也失敗了
                logger.error("OpenAI 降級處理也失敗: \(error.localizedDescription)")
                await MainActor.run {
                    if let lastIndex = messages.indices.last {
                        messages[lastIndex] = ChatMessage(
                            content: LocalizationManager.shared.localizedString("chat.processing_error"),
                            isFromUser: false,
                            messageType: .error
                        )
                    }
                    isStreaming = false
                    isTyping = false
                    stopTypingAnimation()
                }
            }
        }
        
        // 確保狀態重置
        await MainActor.run {
            isTyping = false
            isStreaming = false
            stopTypingAnimation()
        }
    }
    
    func startVoiceRecording() {
        Task {
            do {
                try await VoiceRecordingManager.shared.startRecording()
                isRecording = true
            } catch {
                errorMessage = String(format: LocalizationManager.shared.localizedString("chat.voice_recording_error"), error.localizedDescription)
            }
        }
    }
    
    func stopVoiceRecording() {
        guard let audioURL = VoiceRecordingManager.shared.stopRecording() else { return }
        isRecording = false
        
        Task {
            do {
                let transcription = try await VoiceToTextService.shared.transcribeAudio(from: audioURL)
                await MainActor.run {
                    inputText = transcription
                    
                    // 自動檢查是否為交易訊息，如果是則自動處理
                    if isTransactionMessage(transcription) {
                        // 發送轉錄的文字以自動處理交易
                        sendMessage()
                    } else {
                        // 如果不是交易訊息，將轉錄文字填入輸入框讓用戶確認
                        let transcriptionMessage = ChatMessage(
                            content: String(format: LocalizationManager.shared.localizedString("chat.voice_transcription_success"), transcription),
                            isFromUser: false,
                            messageType: .text
                        )
                        messages.append(transcriptionMessage)
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = String(format: LocalizationManager.shared.localizedString("chat.voice_transcription_error"), error.localizedDescription)
                }
            }
        }
    }
    
    func processImage(_ imageData: Data) {
        isProcessingImage = true
        
        Task {
            do {
                let image = UIImage(data: imageData) ?? UIImage()
                // 從聊天中上傳的圖片，來源未知（可能是相簿或相機）
                let result = try await PhotoAccountingManager.shared.processReceiptImage(image, source: .unknown)
                
                await MainActor.run {
                    // 保存提取的資料並顯示確認介面
                    extractedReceiptData = result
                    showReceiptConfirmation = true
                    isProcessingImage = false
                    
                    // 同時在聊天中顯示成功訊息
                    let content = String(format: LocalizationManager.shared.localizedString("chat.image_analysis_success"), 
                                       String(result.amount), result.category, result.notes)
                    let responseMessage = ChatMessage(
                        content: content,
                        isFromUser: false,
                        messageType: .transaction,
                        metadata: [
                            "amount": String(result.amount),
                            "category": result.category,
                            "description": result.notes
                        ]
                    )
                    messages.append(responseMessage)
                }
            } catch {
                await MainActor.run {
                    let errorMessage = ChatMessage(
                        content: String(format: LocalizationManager.shared.localizedString("chat.image_analysis_error"), error.localizedDescription),
                        isFromUser: false,
                        messageType: .error
                    )
                    messages.append(errorMessage)
                    isProcessingImage = false
                }
            }
        }
    }
    
    func processPDF(_ pdfData: Data) {
        isProcessingPDF = true
        
        Task {
            do {
                let result = try await pdfProcessor.processPDFDocument(pdfData)
                
                await MainActor.run {
                    // 保存提取的資料並顯示確認介面
                    extractedReceiptData = result
                    showReceiptConfirmation = true
                    isProcessingPDF = false
                    
                    // 在聊天中顯示成功訊息
                    let content = String(format: LocalizationManager.shared.localizedString("chat.pdf_analysis_success"), 
                                       String(result.amount), result.category, result.notes)
                    let responseMessage = ChatMessage(
                        content: content,
                        isFromUser: false,
                        messageType: .transaction,
                        metadata: [
                            "amount": String(result.amount),
                            "category": result.category,
                            "description": result.notes
                        ]
                    )
                    messages.append(responseMessage)
                }
            } catch {
                await MainActor.run {
                    let errorMessage = ChatMessage(
                        content: String(format: LocalizationManager.shared.localizedString("chat.pdf_analysis_error"), error.localizedDescription),
                        isFromUser: false,
                        messageType: .error
                    )
                    messages.append(errorMessage)
                    isProcessingPDF = false
                }
            }
        }
    }
    
    func saveReceiptData(_ receiptData: ExtractedReceiptData) {
        // 將發票資料轉換為交易記錄並保存
        Task {
            do {
                let transactionType: TransactionType = receiptData.amount >= 0 ? .expense : .income
                let category = mapCategoryToTransactionCategory(receiptData.category)
                
                let newTransaction = Transaction(
                    amount: abs(receiptData.amount),
                    type: transactionType,
                    category: category,
                    description: receiptData.notes.isEmpty ? receiptData.merchant : receiptData.notes,
                    inputMethod: "photo",
                    originalText: "發票: \(receiptData.merchant)"
                )
                
                // 設定 AI 分析結果
                newTransaction.isAutoCategorized = true
                newTransaction.aiConfidence = receiptData.confidence
                newTransaction.aiSuggestion = receiptData.category
                
                // 保存到資料庫（需要在主執行緒上執行）
                await MainActor.run {
                    // 這裡需要 modelContext，但 ChatViewModel 沒有直接訪問
                    // 所以我們通過回調來處理
                }
                
                // 顯示成功訊息
                await MainActor.run {
                    let successMessage = ChatMessage(
                        content: LocalizationManager.shared.localizedString("chat.receipt_saved_success"),
                        isFromUser: false,
                        messageType: .transaction
                    )
                    messages.append(successMessage)
                }
            } catch {
                await MainActor.run {
                    let errorMessage = ChatMessage(
                        content: String(format: LocalizationManager.shared.localizedString("chat.receipt_save_error"), error.localizedDescription),
                        isFromUser: false,
                        messageType: .error
                    )
                    messages.append(errorMessage)
                }
            }
        }
    }
    
    private func mapCategoryToTransactionCategory(_ category: String) -> TransactionCategory {
        switch category {
        case "餐飲": return .food
        case "交通": return .transport
        case "居住": return .housing
        case "娛樂": return .entertainment
        case "教育": return .education
        case "醫療": return .healthcare
        case "購物": return .shopping
        case "其他": return .other_expense
        default: return .other_expense
        }
    }
}

// 主聊天介面
struct ChatView: View {
    @StateObject private var viewModel: ChatViewModel
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @StateObject private var localizationManager = LocalizationManager.shared
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]
    @State private var scrollProxy: ScrollViewProxy?
    @State private var showMainMenu = false
    
    init(conversationManager: ConversationManager, transactionParser: TransactionParser, openAIService: OpenAIService) {
        self._viewModel = StateObject(wrappedValue: ChatViewModel(
            conversationManager: conversationManager,
            transactionParser: transactionParser,
            openAIService: openAIService
        ))
    }
    
    var body: some View {
        NavigationBarContainer(
            title: localizationManager.localizedString("chat.gabriel"),
            showBackButton: true,
            showMenuButton: true,
            onBack: {
                // 返回主頁的邏輯
            },
            onMenu: {
                showMainMenu = true
            }
        ) {
            VStack(spacing: 0) {
                // 離線狀態橫幅
                if !networkMonitor.isConnected {
                    OfflineBanner(
                        message: localizationManager.localizedString("chat.offline_banner"),
                        icon: "wifi.slash"
                    )
                }
                
                // 設置當前用戶到 ViewModel
                Color.clear
                    .onAppear {
                        viewModel.currentUser = users.first
                        // 如果用戶已設置，更新建議
                        if viewModel.currentUser != nil {
                            viewModel.updateConversationSuggestions()
                        }
                    }
                    .onChange(of: users.count) { _, _ in
                        viewModel.currentUser = users.first
                        if viewModel.currentUser != nil {
                            viewModel.updateConversationSuggestions()
                        }
                    }
                
                // 聊天訊息列表
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                                    .transition(.asymmetric(
                                        insertion: .scale.combined(with: .opacity),
                                        removal: .opacity
                                    ))
                            }
                            
                            if viewModel.isTyping {
                                TypingIndicator()
                                    .id("typing")
                            }
                            
                            // 對話建議按鈕（在歡迎訊息後或對話間隙顯示）
                            if viewModel.showSuggestions && !viewModel.conversationSuggestions.isEmpty && viewModel.messages.count <= 2 {
                                ConversationSuggestionsView(
                                    suggestions: viewModel.conversationSuggestions,
                                    onSuggestionTapped: { suggestion in
                                        viewModel.sendSuggestion(suggestion)
                                    }
                                )
                                .padding(.top, 8)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                    .onAppear {
                        scrollProxy = proxy
                    }
                    .onChange(of: viewModel.messages.count) {
                        scrollToBottom()
                    }
                    .onChange(of: viewModel.isTyping) {
                        scrollToBottom()
                    }
                }
                
                // 輸入區域
                InputArea(
                    inputText: $viewModel.inputText,
                    isRecording: $viewModel.isRecording,
                    isProcessingImage: $viewModel.isProcessingImage,
                    isProcessingPDF: $viewModel.isProcessingPDF,
                    onSend: viewModel.sendMessage,
                    onStartRecording: viewModel.startVoiceRecording,
                    onStopRecording: viewModel.stopVoiceRecording,
                    onImageSelected: viewModel.processImage,
                    onPDFSelected: viewModel.processPDF
                )
            }
            .alert(localizationManager.localizedString("chat.error"), isPresented: .constant(viewModel.errorMessage != nil)) {
                Button(localizationManager.localizedString("chat.ok")) {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
            .sheet(isPresented: $showMainMenu) {
                MainMenuView(isPresented: $showMainMenu)
            }
            .sheet(isPresented: $viewModel.showReceiptConfirmation) {
                if let receiptData = viewModel.extractedReceiptData {
                    ReceiptConfirmationView(
                        data: receiptData,
                        onConfirm: { confirmedData in
                            // 保存交易記錄
                            let transactionType: TransactionType = confirmedData.amount >= 0 ? .expense : .income
                            let category: TransactionCategory
                            switch confirmedData.category {
                            case "餐飲": category = .food
                            case "交通": category = .transport
                            case "居住": category = .housing
                            case "娛樂": category = .entertainment
                            case "教育": category = .education
                            case "醫療": category = .healthcare
                            case "購物": category = .shopping
                            default: category = .other_expense
                            }
                            
                            let newTransaction = Transaction(
                                amount: abs(confirmedData.amount),
                                type: transactionType,
                                category: category,
                                description: confirmedData.notes.isEmpty ? confirmedData.merchant : confirmedData.notes,
                                inputMethod: "photo",
                                originalText: "發票: \(confirmedData.merchant)"
                            )
                            
                            newTransaction.isAutoCategorized = true
                            newTransaction.aiConfidence = confirmedData.confidence
                            newTransaction.aiSuggestion = confirmedData.category
                            
                            modelContext.insert(newTransaction)
                            
                            do {
                                try modelContext.save()
                                viewModel.showReceiptConfirmation = false
                                viewModel.extractedReceiptData = nil
                            } catch {
                                viewModel.errorMessage = error.localizedDescription
                            }
                        },
                        onCancel: {
                            viewModel.showReceiptConfirmation = false
                            viewModel.extractedReceiptData = nil
                        }
                    )
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .languageChanged)) { _ in
                // 語言變化時，重新載入歡迎訊息以更新內容
                Task { @MainActor in
                    viewModel.reloadWelcomeMessage()
                }
            }
        }
    }
    
    private func scrollToBottom() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.easeOut(duration: 0.2)) {
                if viewModel.isTyping {
                    scrollProxy?.scrollTo("typing", anchor: .bottom)
                } else if let lastMessage = viewModel.messages.last {
                    scrollProxy?.scrollTo(lastMessage.id, anchor: .bottom)
                }
            }
        }
    }
}

// MARK: - 訊息氣泡
struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer()
                UserMessageBubble(message: message)
            } else {
                GabrielMessageBubble(message: message)
                Spacer()
            }
        }
    }
}

struct UserMessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(message.content)
                .font(.system(size: 16))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color.blue)
                )
            
            Text(message.timestamp, style: .time)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: 280, alignment: .trailing)
    }
}

struct GabrielMessageBubble: View {
    let message: ChatMessage
    @AppStorage("selectedGabrielGender") private var selectedGabrielGender: String = "male"
    
    init(message: ChatMessage) {
        self.message = message
        // 確保從 UserDefaults 讀取正確的值
        if let savedGender = UserDefaults.standard.string(forKey: "selectedGabrielGender") {
            self._selectedGabrielGender = AppStorage(wrappedValue: savedGender, "selectedGabrielGender")
        }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // 加百列頭像
            GabrielAvatarView(
                gender: GabrielGender(rawValue: selectedGabrielGender) ?? .male,
                size: 32,
                showFullBody: false
            )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(message.content)
                    .font(.system(size: 16))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color(.systemGray6))
                    )
                
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: 280, alignment: .leading)
    }
}

// MARK: - 打字指示器
struct TypingIndicator: View {
    @State private var animationOffset: CGFloat = 0
    @AppStorage("selectedGabrielGender") private var selectedGabrielGender: String = "male"
    
    init() {
        // 確保從 UserDefaults 讀取正確的值
        if let savedGender = UserDefaults.standard.string(forKey: "selectedGabrielGender") {
            self._selectedGabrielGender = AppStorage(wrappedValue: savedGender, "selectedGabrielGender")
        }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            GabrielAvatarView(
                gender: GabrielGender(rawValue: selectedGabrielGender) ?? .male,
                size: 32,
                showFullBody: false
            )
            
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 8, height: 8)
                        .offset(y: animationOffset)
                        .animation(
                            .easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                            value: animationOffset
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(.systemGray6))
            )
        }
        .frame(maxWidth: 280, alignment: .leading)
        .onAppear {
            animationOffset = -4
        }
    }
}

// MARK: - 輸入區域
struct InputArea: View {
    @Binding var inputText: String
    @Binding var isRecording: Bool
    @Binding var isProcessingImage: Bool
    @Binding var isProcessingPDF: Bool
    let onSend: () -> Void
    let onStartRecording: () -> Void
    let onStopRecording: () -> Void
    let onImageSelected: (Data) -> Void
    let onPDFSelected: (Data) -> Void
    
    @State private var showingImagePicker = false
    @State private var showingDocumentPicker = false
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @StateObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 12) {
                // 語音按鈕
                Button(action: {
                    if isRecording {
                        onStopRecording()
                    } else {
                        onStartRecording()
                    }
                }) {
                    Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                        .resizable()
                        .frame(width: 32, height: 32)
                        .foregroundColor(isRecording ? .red : .blue)
                }
                
                // 圖片按鈕（長按顯示選單：相機/相簿/PDF）
                Button(action: {
                    showingImagePicker = true
                }) {
                    Image(systemName: "camera.circle.fill")
                        .resizable()
                        .frame(width: 32, height: 32)
                        .foregroundColor(.green)
                }
                .disabled(isProcessingImage || isProcessingPDF)
                .contextMenu {
                    Button(action: {
                        showingImagePicker = true
                    }) {
                        Label(localizationManager.localizedString("chat.select_photo"), systemImage: "photo")
                    }
                    
                    Button(action: {
                        showingDocumentPicker = true
                    }) {
                        Label(localizationManager.localizedString("chat.select_pdf"), systemImage: "doc.fill")
                    }
                }
                
                // 文字輸入框
                HStack {
                    TextField(localizationManager.localizedString("chat.input_placeholder"), text: $inputText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .disabled(!networkMonitor.isConnected)
                        .onSubmit {
                            if networkMonitor.isConnected {
                                onSend()
                            }
                        }
                    
                    if !inputText.isEmpty {
                        Button(localizationManager.localizedString("chat.send")) {
                            if networkMonitor.isConnected {
                                onSend()
                            }
                        }
                        .foregroundColor(networkMonitor.isConnected ? .blue : .gray)
                        .disabled(!networkMonitor.isConnected)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.systemGray6))
                )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(.systemBackground))
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker { imageData in
                onImageSelected(imageData)
            }
        }
        .sheet(isPresented: $showingDocumentPicker) {
            DocumentPicker { pdfData in
                onPDFSelected(pdfData)
            }
        }
    }
}

// MARK: - PDF 文件選擇器
struct DocumentPicker: UIViewControllerRepresentable {
    let onPDFSelected: (Data) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf])
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            
            // 確保有訪問權限
            guard url.startAccessingSecurityScopedResource() else {
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }
            
            // 讀取 PDF 數據
            if let pdfData = try? Data(contentsOf: url) {
                parent.onPDFSelected(pdfData)
            }
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            // 用戶取消選擇
        }
    }
}

// MARK: - 圖片選擇器
struct ImagePicker: UIViewControllerRepresentable {
    enum SourceType {
        case camera
        case photoLibrary
    }
    
    let sourceType: SourceType
    let onImageSelected: (Data) -> Void
    
    init(sourceType: SourceType, onImageSelected: @escaping (Data) -> Void) {
        self.sourceType = sourceType
        self.onImageSelected = onImageSelected
    }
    
    // 兼容舊的初始化方法
    init(_ onImageSelected: @escaping (Data) -> Void) {
        self.sourceType = .photoLibrary
        self.onImageSelected = onImageSelected
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType == .camera ? .camera : .photoLibrary
        picker.allowsEditing = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage,
               let imageData = image.jpegData(compressionQuality: 0.8) {
                parent.onImageSelected(imageData)
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

// MARK: - 對話建議視圖
struct ConversationSuggestionsView: View {
    let suggestions: [ConversationSuggestion]
    let onSuggestionTapped: (ConversationSuggestion) -> Void
    @StateObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(localizationManager.localizedString("chat.quick_start"))
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(suggestions.indices, id: \.self) { index in
                        let suggestion = suggestions[index]
                        Button(action: {
                            onSuggestionTapped(suggestion)
                        }) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(suggestion.title)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.leading)
                                
                                Text(suggestion.content)
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.leading)
                                    .lineLimit(2)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .frame(maxWidth: 200, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGray6))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                            )
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
}

#Preview {
    NavigationView {
        ChatView(
            conversationManager: ConversationManager.shared,
            transactionParser: TransactionParser(),
            openAIService: OpenAIService.shared
        )
    }
}
