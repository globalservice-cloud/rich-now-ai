//
//  VoiceToTextService.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import Foundation
import Combine
import AVFoundation
import Speech
import NaturalLanguage
import os.log

// 語音轉文字服務
@MainActor
class VoiceToTextService: ObservableObject {
    static let shared = VoiceToTextService()
    
    @Published var isProcessing = false
    @Published var transcriptionText = ""
    @Published var confidence: Float = 0.0
    @Published var processingError: String?
    @Published var isSupported = true
    @Published var isNativeAIAvailable = false
    @Published var currentProcessingMethod: String = "未知"
    @Published var hasSpeechPermission = false
    
    private let openAIService = OpenAIService.shared
    private let aiProcessingRouter = AIProcessingRouter.shared
    private let naturalLanguageProcessor = NaturalLanguageProcessor.shared
    private let settingsManager = SettingsManager.shared
    private let performanceMonitor = AIPerformanceMonitor.shared
    private var cancellables = Set<AnyCancellable>()
    private let logger = Logger(subsystem: "com.richnowai", category: "VoiceToTextService")
    
    // 原生語音識別器（支持多語言）
    private var speechRecognizers: [Locale: SFSpeechRecognizer] = [:]
    private var primaryRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var currentConfidence: Float = 0.0
    
    // 支持的語言列表（優先順序）
    private let supportedLocales: [Locale] = [
        Locale(identifier: "zh-TW"),  // 繁體中文（台灣）
        Locale(identifier: "zh-CN"),  // 簡體中文（中國）
        Locale(identifier: "en-US"),  // 英文（美國）
        Locale(identifier: "ja-JP"),  // 日文
        Locale(identifier: "ko-KR")   // 韓文
    ]
    
    private init() {
        initializeSpeechRecognizers()
        checkSpeechPermission()
        checkNativeAISupport()
        checkWhisperSupport()
        setupPerformanceMonitoring()
    }
    
    // MARK: - 初始化語音識別器
    
    private func initializeSpeechRecognizers() {
        // 初始化所有支持的語言識別器
        for locale in supportedLocales {
            if let recognizer = SFSpeechRecognizer(locale: locale), recognizer.isAvailable {
                speechRecognizers[locale] = recognizer
                // 設置主要識別器（優先使用系統語言或繁體中文）
                if primaryRecognizer == nil {
                    let systemLocale = Locale.current
                    let localeLangCode = locale.language.languageCode?.identifier ?? ""
                    let systemLangCode = systemLocale.language.languageCode?.identifier ?? ""
                    if localeLangCode == systemLangCode || locale.identifier == "zh-TW" {
                        primaryRecognizer = recognizer
                    }
                }
            }
        }
        
        // 如果沒有找到主要識別器，使用第一個可用的
        if primaryRecognizer == nil {
            primaryRecognizer = speechRecognizers.values.first
        }
        
        logger.info("初始化語音識別器: 可用語言數量=\(self.speechRecognizers.count), 主要語言=\(self.primaryRecognizer?.locale.identifier ?? "無")")
    }
    
    // 獲取適合的語音識別器
    private func getSpeechRecognizer(for locale: Locale? = nil) -> SFSpeechRecognizer? {
        if let locale = locale,
           let recognizer = speechRecognizers[locale],
           recognizer.isAvailable {
            return recognizer
        }
        return primaryRecognizer
    }
    
    // 自動檢測語言並獲取識別器
    private func detectSpeechLanguage(from url: URL) -> Locale? {
        // 這裡可以根據音頻文件或其他信息推測語言
        // 暫時返回系統語言或主要識別器語言
        return primaryRecognizer?.locale ?? Locale.current
    }
    
    // MARK: - 語音識別權限管理
    
    func checkSpeechPermission() {
        let status = SFSpeechRecognizer.authorizationStatus()
        hasSpeechPermission = (status == .authorized)
        
        if status == .authorized {
            logger.info("語音識別權限已授予")
        } else {
            logger.warning("語音識別權限狀態: \(status.rawValue)")
        }
    }
    
    func requestSpeechPermission() async -> Bool {
        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                Task { @MainActor in
                    let authorized = (status == .authorized)
                    self.hasSpeechPermission = authorized
                    self.logger.info("語音識別權限請求結果: \(status == .authorized ? "已授予" : "被拒絕")")
                    continuation.resume(returning: authorized)
                }
            }
        }
    }
    
    // MARK: - 語音轉文字
    
    func transcribeAudio(from url: URL) async throws -> String {
        isProcessing = true
        processingError = nil
        transcriptionText = ""
        confidence = 0.0
        currentProcessingMethod = "處理中..."
        
        do {
            // 檢查文件是否存在
            guard FileManager.default.fileExists(atPath: url.path) else {
                logger.error("音頻文件不存在: \(url.path)")
                throw VoiceToTextError.fileNotFound
            }
            
            // 檢查文件大小
            let fileSize = try FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64 ?? 0
            let maxSize: Int64 = 25 * 1024 * 1024 // 25MB Whisper API 限制
            
            guard fileSize <= maxSize else {
                logger.error("文件太大: \(fileSize) bytes，最大允許: \(maxSize) bytes")
                throw VoiceToTextError.fileTooLarge
            }
            
            // 檢查語音識別權限（如果需要使用原生 AI）
            checkSpeechPermission()
            if !hasSpeechPermission {
                logger.warning("語音識別權限未授予，嘗試請求權限")
                let granted = await requestSpeechPermission()
                if !granted {
                    logger.warning("語音識別權限被拒絕，將使用 OpenAI 作為替代方案")
                    // 權限被拒絕時，強制使用 OpenAI
                    let result = try await transcribeWithOpenAI(from: url)
                    transcriptionText = result.data
                    confidence = Float(result.confidence)
                    currentProcessingMethod = "OpenAI"
                    isProcessing = false
                    return result.data
                }
            }
            
            // 使用智能 AI 處理路由器
            let result = try await transcribeWithIntelligentRouting(from: url)
            
            // 更新狀態
            transcriptionText = result.data
            confidence = Float(result.confidence)
            currentProcessingMethod = result.source == .native ? "原生 AI" : "OpenAI"
            isProcessing = false
            
            logger.info("語音轉文字完成: 方法=\(String(describing: result.source)), 信心度=\(String(format: "%.2f", result.confidence)), 時間=\(String(format: "%.2f", result.processingTime))秒")
            
            return result.data
            
        } catch {
            isProcessing = false
            processingError = error.localizedDescription
            currentProcessingMethod = "錯誤"
            logger.error("語音轉文字失敗: \(error.localizedDescription)")
            
            // 如果是權限錯誤，提供更友好的錯誤訊息
            if let speechError = error as? VoiceToTextError,
               speechError == .speechRecognizerNotAvailable {
                throw VoiceToTextError.speechRecognizerNotAvailable
            }
            
            throw error
        }
    }
    
    // MARK: - 智能路由語音轉文字
    
    private func transcribeWithIntelligentRouting(from url: URL) async throws -> AIProcessingRouter.ProcessingResult<String> {
        let settings = settingsManager.currentSettings
        let strategy = settings?.aiProcessingStrategy ?? "nativeFirst"
        
        switch strategy {
        case "nativeOnly":
            return try await transcribeWithNativeOnly(from: url)
        case "nativeFirst":
            return try await transcribeWithNativeFirst(from: url)
        case "openAIFirst":
            return try await transcribeWithOpenAIFirst(from: url)
        case "hybrid":
            return try await transcribeWithHybrid(from: url)
        case "auto":
            return try await transcribeWithAuto(from: url)
        default:
            return try await transcribeWithNativeFirst(from: url)
        }
    }
    
    // MARK: - 原生 AI 語音轉文字
    
    private func transcribeWithNativeOnly(from url: URL) async throws -> AIProcessingRouter.ProcessingResult<String> {
        let startTime = Date()
        
        // 檢查文件是否存在
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw VoiceToTextError.fileNotFound
        }
        
        guard let recognizer = primaryRecognizer, recognizer.isAvailable else {
            logger.warning("原生語音識別不可用")
            throw VoiceToTextError.speechRecognizerNotAvailable
        }
        
        // 再次檢查權限
        guard SFSpeechRecognizer.authorizationStatus() == .authorized else {
            logger.warning("語音識別權限未授予")
            throw VoiceToTextError.speechRecognizerNotAvailable
        }
        
        // 檢查是否需要網路（如果不支援離線識別）
        if !recognizer.supportsOnDeviceRecognition && !NetworkMonitor.shared.isConnected {
            logger.warning("需要網路連線進行語音識別")
            throw VoiceToTextError.networkError
        }
        
        // 直接使用 URL 進行識別（更高效）
        let transcription = try await transcribeAudioFile(url: url, recognizer: recognizer)
        let processingTime = Date().timeIntervalSince(startTime)
        
        let finalConfidence = max(currentConfidence, 0.7) // 確保最低信心度
        
        performanceMonitor.recordNativeAIProcessing(
            success: true,
            processingTime: processingTime,
            confidence: Double(finalConfidence)
        )
        
        return AIProcessingRouter.ProcessingResult(
            data: transcription,
            source: .native,
            confidence: Double(finalConfidence),
            processingTime: processingTime,
            fallbackUsed: false
        )
    }
    
    private func transcribeWithNativeFirst(from url: URL) async throws -> AIProcessingRouter.ProcessingResult<String> {
        do {
            let nativeResult = try await transcribeWithNativeOnly(from: url)
            let confidenceThreshold = settingsManager.currentSettings?.nativeAIConfidenceThreshold ?? 0.85
            
            if nativeResult.confidence >= confidenceThreshold {
                return nativeResult
            } else {
                logger.info("原生 AI 信心度不足 (\(nativeResult.confidence))，降級到 OpenAI")
                throw VoiceToTextError.lowConfidence
            }
        } catch {
            logger.info("原生 AI 失敗，降級到 OpenAI: \(error.localizedDescription)")
            return try await transcribeWithOpenAI(from: url)
        }
    }
    
    private func transcribeWithOpenAIFirst(from url: URL) async throws -> AIProcessingRouter.ProcessingResult<String> {
        do {
            return try await transcribeWithOpenAI(from: url)
        } catch {
            logger.info("OpenAI 失敗，降級到原生 AI: \(error.localizedDescription)")
            return try await transcribeWithNativeOnly(from: url)
        }
    }
    
    private func transcribeWithHybrid(from url: URL) async throws -> AIProcessingRouter.ProcessingResult<String> {
        async let nativeTask = try? transcribeWithNativeOnly(from: url)
        async let openAITask = try? transcribeWithOpenAI(from: url)
        
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
            throw VoiceToTextError.transcriptionFailed
        }
    }
    
    private func transcribeWithAuto(from url: URL) async throws -> AIProcessingRouter.ProcessingResult<String> {
        let audioComplexity = assessAudioComplexity(url: url)
        let deviceCapability = getDeviceCapability()
        
        if deviceCapability >= 0.7 && audioComplexity < 0.6 {
            // 設備能力強，音頻不複雜，優先使用原生 AI
            return try await transcribeWithNativeFirst(from: url)
        } else {
            // 設備能力一般或音頻複雜，使用混合策略
            return try await transcribeWithHybrid(from: url)
        }
    }
    
    // MARK: - 原生語音識別實現
    
    private func transcribeWithNativeSpeech(audioData: Data) async throws -> String {
        guard let recognizer = primaryRecognizer, recognizer.isAvailable else {
            logger.warning("語音識別器不可用，降級到 OpenAI")
            throw VoiceToTextError.speechRecognizerNotAvailable
        }
        
        // 再次檢查權限
        guard SFSpeechRecognizer.authorizationStatus() == .authorized else {
            logger.warning("語音識別權限未授予")
            throw VoiceToTextError.speechRecognizerNotAvailable
        }
        
        // 創建臨時音頻文件
        let tempDir = FileManager.default.temporaryDirectory
        let tempURL = tempDir.appendingPathComponent("voice_transcription_\(UUID().uuidString).m4a")
        
        do {
            // 將音頻數據寫入臨時文件
            try audioData.write(to: tempURL)
            defer {
                // 清理臨時文件
                try? FileManager.default.removeItem(at: tempURL)
            }
            
            // 使用 AVAudioFile 讀取音頻
            return try await transcribeAudioFile(url: tempURL, recognizer: recognizer)
            
        } catch {
            logger.error("處理音頻文件失敗: \(error.localizedDescription)")
            throw VoiceToTextError.audioProcessingFailed
        }
    }
    
    private func transcribeAudioFile(url: URL, recognizer: SFSpeechRecognizer? = nil) async throws -> String {
        // 再次檢查權限
        guard SFSpeechRecognizer.authorizationStatus() == .authorized else {
            logger.error("語音識別權限未授予")
            throw VoiceToTextError.speechRecognizerNotAvailable
        }
        
        // 使用提供的識別器或主要識別器
        let finalRecognizer: SFSpeechRecognizer
        if let recognizer = recognizer, recognizer.isAvailable {
            finalRecognizer = recognizer
        } else if let primary = primaryRecognizer, primary.isAvailable {
            finalRecognizer = primary
        } else {
            logger.error("沒有可用的語音識別器")
            throw VoiceToTextError.speechRecognizerNotAvailable
        }
        
        logger.info("使用語音識別器: \(finalRecognizer.locale.identifier), 離線支持: \(finalRecognizer.supportsOnDeviceRecognition)")
        
        // 使用 SFSpeechURLRecognitionRequest 直接處理音頻文件
        // 這比使用 AudioBuffer 更簡單可靠
        return try await withCheckedThrowingContinuation { continuation in
            let request = SFSpeechURLRecognitionRequest(url: url)
            request.shouldReportPartialResults = false
            request.taskHint = .dictation
            
            // 設置超時處理（避免長時間等待）
            var hasResumed = false
            let timeout: TimeInterval = 60.0 // 60秒超時
            let timeoutTask = Task {
                try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                if !hasResumed {
                    self.logger.warning("語音識別超時")
                    self.recognitionTask?.cancel()
                    self.recognitionTask = nil
                    continuation.resume(throwing: VoiceToTextError.transcriptionFailed)
                    hasResumed = true
                }
            }
            
            recognitionTask = finalRecognizer.recognitionTask(with: request) { [weak self] result, error in
                guard let self = self else {
                    timeoutTask.cancel()
                    return
                }
                
                if let error = error {
                    timeoutTask.cancel()
                    let nsError = error as NSError
                    let errorCode = nsError.code
                    
                    // 檢查是否是權限錯誤
                    if errorCode == 1700 || errorCode == 203 { // Speech recognition authorization errors
                        self.logger.error("語音識別權限錯誤: \(error.localizedDescription)")
                        if !hasResumed {
                            continuation.resume(throwing: VoiceToTextError.speechRecognizerNotAvailable)
                            hasResumed = true
                        }
                    } else {
                        self.logger.error("語音識別錯誤 (code: \(errorCode)): \(error.localizedDescription)")
                        if !hasResumed {
                            continuation.resume(throwing: VoiceToTextError.transcriptionFailed)
                            hasResumed = true
                        }
                    }
                    
                    self.recognitionTask?.cancel()
                    self.recognitionTask = nil
                    return
                }
                
                guard let result = result else {
                    return
                }
                
                if result.isFinal {
                    timeoutTask.cancel()
                    
                    let transcription = result.bestTranscription.formattedString
                    self.recognitionTask?.cancel()
                    self.recognitionTask = nil
                    
                    // 更新信心度
                    let transcriptions = result.transcriptions
                    if let bestTranscription = transcriptions.first {
                        let segmentConfidences = bestTranscription.segments.map { Float($0.confidence) }
                        let avgConfidence = segmentConfidences.isEmpty ? 0.8 : segmentConfidences.reduce(0, +) / Float(segmentConfidences.count)
                        self.currentConfidence = avgConfidence
                        self.confidence = avgConfidence
                    } else {
                        // 如果沒有段落信心度，使用預設值
                        self.currentConfidence = 0.8
                        self.confidence = 0.8
                    }
                    
                    if transcription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        if !hasResumed {
                            self.logger.warning("語音識別結果為空")
                            continuation.resume(throwing: VoiceToTextError.transcriptionFailed)
                            hasResumed = true
                        }
                    } else {
                        if !hasResumed {
                            let preview = transcription.count > 50 ? String(transcription.prefix(50)) + "..." : transcription
                            self.logger.info("原生語音識別成功: \(preview)")
                            continuation.resume(returning: transcription)
                            hasResumed = true
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - OpenAI 語音轉文字
    
    private func transcribeWithOpenAI(from url: URL) async throws -> AIProcessingRouter.ProcessingResult<String> {
        let startTime = Date()
        
        let transcription = try await openAIService.transcribeAudio(url: url)
        let processingTime = Date().timeIntervalSince(startTime)
        let cost = 0.0 // 成本計算由 APIUsageTracker 處理
        
        performanceMonitor.recordOpenAIProcessing(
            success: true,
            processingTime: processingTime,
            confidence: 0.9,
            cost: cost
        )
        
        return AIProcessingRouter.ProcessingResult(
            data: transcription,
            source: .openAI,
            confidence: 1.0,
            processingTime: processingTime,
            fallbackUsed: false
        )
    }
    
    // MARK: - 支援檢查
    
    private func checkNativeAISupport() {
        // 檢查權限
        let authStatus = SFSpeechRecognizer.authorizationStatus()
        let hasPermission = (authStatus == .authorized)
        
        // 檢查是否有可用的識別器
        let hasAvailableRecognizer = primaryRecognizer != nil && (primaryRecognizer?.isAvailable ?? false)
        
        // 只有當有權限且有可用識別器時，才標記為可用
        isNativeAIAvailable = hasPermission && hasAvailableRecognizer
        
        if isNativeAIAvailable {
            let availableLocales = speechRecognizers.keys.map { $0.identifier }.joined(separator: ", ")
            let supportsOnDevice = primaryRecognizer?.supportsOnDeviceRecognition ?? false
            logger.info("原生語音識別可用（支持語言: \(availableLocales), 離線支持: \(supportsOnDevice)）")
        } else {
            var reasons: [String] = []
            if !hasPermission {
                reasons.append("權限未授予（狀態: \(authStatus.rawValue)）")
            }
            if !hasAvailableRecognizer {
                reasons.append("無可用識別器")
            }
            logger.warning("原生語音識別不可用（原因: \(reasons.joined(separator: ", "))）")
        }
        
        // 更新權限狀態
        hasSpeechPermission = hasPermission
    }
    
    private func checkWhisperSupport() {
        // 檢查是否有 API Key
        guard APIKeyManager.shared.getAPIKey(for: "openai") != nil else {
            isSupported = false
            return
        }
        
        // 檢查訂閱等級是否支援語音功能
        let subscriptionTier = StoreKitManager.shared.currentSubscription
        isSupported = subscriptionTier != .free
    }
    
    private func setupPerformanceMonitoring() {
        performanceMonitor.$metrics
            .sink { [weak self] metrics in
                // 更新性能指標
                self?.logger.debug("語音轉文字性能更新: 原生成功率=\(metrics.nativeAISuccessRate), OpenAI成功率=\(metrics.openAISuccessRate)")
            }
            .store(in: &cancellables)
    }
    
    // MARK: - 文字處理
    
    func processTranscription(_ text: String) -> ProcessedTranscription {
        let cleanedText = cleanTranscriptionText(text)
        let confidence = calculateConfidence(text)
        let language = detectLanguage(text)
        
        return ProcessedTranscription(
            originalText: text,
            cleanedText: cleanedText,
            confidence: confidence,
            language: language,
            wordCount: cleanedText.split(separator: " ").count,
            duration: estimateDuration(for: cleanedText)
        )
    }
    
    private func cleanTranscriptionText(_ text: String) -> String {
        // 移除多餘的空白
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        
        // 移除常見的語音轉文字錯誤
        let commonErrors = [
            "um": "",
            "uh": "",
            "ah": "",
            "er": "",
            "嗯": "",
            "呃": "",
            "啊": ""
        ]
        
        var result = cleaned
        for (error, replacement) in commonErrors {
            result = result.replacingOccurrences(of: error, with: replacement)
        }
        
        return result
    }
    
    private func calculateConfidence(_ text: String) -> Float {
        // 基於文字長度和複雜度的簡單信心度計算
        let wordCount = text.split(separator: " ").count
        let hasNumbers = text.rangeOfCharacter(from: .decimalDigits) != nil
        let hasPunctuation = text.rangeOfCharacter(from: .punctuationCharacters) != nil
        
        var confidence: Float = 0.8 // 基礎信心度
        
        if wordCount > 5 {
            confidence += 0.1
        }
        
        if hasNumbers {
            confidence += 0.05
        }
        
        if hasPunctuation {
            confidence += 0.05
        }
        
        return min(1.0, confidence)
    }
    
    private func detectLanguage(_ text: String) -> String {
        // 簡單的語言檢測
        let chineseCharacters = text.rangeOfCharacter(from: CharacterSet(charactersIn: "\u{4e00}"..."\u{9fff}"))
        let englishCharacters = text.rangeOfCharacter(from: CharacterSet.letters)
        
        if chineseCharacters != nil {
            return "zh"
        } else if englishCharacters != nil {
            return "en"
        } else {
            return "unknown"
        }
    }
    
    // MARK: - 輔助方法
    
    private func assessAudioComplexity(url: URL) -> Double {
        do {
            let fileSize = try FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64 ?? 0
            let duration = estimateAudioDuration(url: url)
            
            var complexity: Double = 0.0
            
            // 基於文件大小
            if fileSize > 10 * 1024 * 1024 { // 10MB
                complexity += 0.4
            } else if fileSize > 5 * 1024 * 1024 { // 5MB
                complexity += 0.2
            }
            
            // 基於音頻時長
            if duration > 60 { // 60秒
                complexity += 0.4
            } else if duration > 30 { // 30秒
                complexity += 0.2
            }
            
            return min(complexity, 1.0)
        } catch {
            return 0.5 // 默認中等複雜度
        }
    }
    
    private func estimateAudioDuration(url: URL) -> Double {
        // 簡化實現，實際應用中需要更精確的音頻分析
        do {
            let fileSize = try FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64 ?? 0
            // 假設 128kbps 音頻，粗略估算時長
            let estimatedDuration = Double(fileSize) / (128 * 1024 / 8) // 秒
            return estimatedDuration
        } catch {
            return 30.0 // 默認 30 秒
        }
    }
    
    private func getDeviceCapability() -> Double {
        // 簡化實現，實際應根據設備型號、RAM、Neural Engine 等判斷
        // 例如：iPhone 15 Pro Max (A17 Pro) -> 1.0
        // iPhone 12 (A14 Bionic) -> 0.7
        // 舊設備 -> 0.3
        return 0.8 // 假設為中高端設備
    }
    
    private func estimateDuration(for text: String) -> TimeInterval {
        // 基於文字長度估算語音時長
        let wordCount = text.split(separator: " ").count
        let averageWordsPerMinute: Double = 150
        return Double(wordCount) / averageWordsPerMinute * 60
    }
    
    // MARK: - 批次處理
    
    func transcribeMultipleFiles(_ urls: [URL]) async throws -> [String] {
        var transcriptions: [String] = []
        
        for url in urls {
            let transcription = try await transcribeAudio(from: url)
            transcriptions.append(transcription)
        }
        
        return transcriptions
    }
    
    // MARK: - 歷史記錄
    
    func saveTranscriptionHistory(_ transcription: ProcessedTranscription) {
        // 保存轉錄歷史到 UserDefaults
        var history = getTranscriptionHistory()
        history.append(transcription)
        
        // 只保留最近50條記錄
        if history.count > 50 {
            history = Array(history.suffix(50))
        }
        
        if let data = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(data, forKey: "transcription_history")
        }
    }
    
    func getTranscriptionHistory() -> [ProcessedTranscription] {
        guard let data = UserDefaults.standard.data(forKey: "transcription_history"),
              let history = try? JSONDecoder().decode([ProcessedTranscription].self, from: data) else {
            return []
        }
        return history
    }
    
    func clearTranscriptionHistory() {
        UserDefaults.standard.removeObject(forKey: "transcription_history")
    }
}

// MARK: - OpenAI 服務擴展

extension OpenAIService {
    
    @MainActor
    func transcribeAudioWithDetails(url: URL) async throws -> WhisperTranscription {
        let text = try await transcribeAudio(url: url)
        let duration = getAudioDuration(url: url)
        
        let estimatedTokens = estimateTokensForAudio(url: url)
        APIKeyManager.shared.trackAPIUsage(for: "openai", tokens: estimatedTokens, cost: calculateWhisperCost(duration: duration))
        
        let languageCode = Locale.current.language.languageCode?.identifier ?? Locale.current.identifier
        return WhisperTranscription(
            text: text,
            confidence: 0.0,
            language: languageCode,
            duration: duration
        )
    }
    
    private func estimateTokensForAudio(url: URL) -> Int {
        // Whisper API 的 token 估算
        let duration = getAudioDuration(url: url)
        return Int(duration * 0.75) // 大約每秒0.75個token
    }
    
    private func calculateWhisperCost(duration: TimeInterval) -> Double {
        // Whisper API 定價：$0.006 per minute
        return duration / 60.0 * 0.006
    }
    
    private func getAudioDuration(url: URL) -> TimeInterval {
        do {
            let audioFile = try AVAudioFile(forReading: url)
            let frameCount = audioFile.length
            let sampleRate = audioFile.fileFormat.sampleRate
            return Double(frameCount) / sampleRate
        } catch {
            return 0.0
        }
    }
}

// MARK: - 資料結構

// WhisperTranscriptionRequest 和 WhisperTranscriptionResponse 已移至 OpenAIService.swift

struct WhisperTranscription {
    let text: String
    let confidence: Float
    let language: String
    let duration: TimeInterval
}

struct ProcessedTranscription: Codable, Identifiable {
    var id: UUID = UUID()
    let originalText: String
    let cleanedText: String
    let confidence: Float
    let language: String
    let wordCount: Int
    let duration: TimeInterval
    let timestamp: Date
    
    init(originalText: String, cleanedText: String, confidence: Float, language: String, wordCount: Int, duration: TimeInterval) {
        self.originalText = originalText
        self.cleanedText = cleanedText
        self.confidence = confidence
        self.language = language
        self.wordCount = wordCount
        self.duration = duration
        self.timestamp = Date()
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, originalText, cleanedText, confidence, language, wordCount, duration, timestamp
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.originalText = try container.decode(String.self, forKey: .originalText)
        self.cleanedText = try container.decode(String.self, forKey: .cleanedText)
        self.confidence = try container.decode(Float.self, forKey: .confidence)
        self.language = try container.decode(String.self, forKey: .language)
        self.wordCount = try container.decode(Int.self, forKey: .wordCount)
        self.duration = try container.decode(TimeInterval.self, forKey: .duration)
        self.timestamp = try container.decodeIfPresent(Date.self, forKey: .timestamp) ?? Date()
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(originalText, forKey: .originalText)
        try container.encode(cleanedText, forKey: .cleanedText)
        try container.encode(confidence, forKey: .confidence)
        try container.encode(language, forKey: .language)
        try container.encode(wordCount, forKey: .wordCount)
        try container.encode(duration, forKey: .duration)
        try container.encode(timestamp, forKey: .timestamp)
    }
}

// MARK: - 錯誤定義

enum VoiceToTextError: LocalizedError {
    case fileNotFound
    case fileTooLarge
    case transcriptionFailed
    case unsupportedFormat
    case networkError
    case speechRecognizerNotAvailable
    case audioProcessingFailed
    case lowConfidence
    case nativeAIFailed
    case openAIFailed
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "檔案未找到"
        case .fileTooLarge:
            return "檔案過大"
        case .transcriptionFailed:
            return "轉錄失敗"
        case .unsupportedFormat:
            return "不支援的格式"
        case .networkError:
            return "網路錯誤"
        case .speechRecognizerNotAvailable:
            return "語音識別器不可用"
        case .audioProcessingFailed:
            return "音頻處理失敗"
        case .lowConfidence:
            return "信心度不足"
        case .nativeAIFailed:
            return "原生 AI 處理失敗"
        case .openAIFailed:
            return "OpenAI 處理失敗"
        }
    }
}
