//
//  AIProcessingRouter.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/28.
//

import Foundation
import UIKit
import NaturalLanguage
import Vision
import Speech
import CoreML
import Combine
import os.log

@MainActor
class AIProcessingRouter: ObservableObject {
    static let shared = AIProcessingRouter()
    
    @Published var currentStrategy: AIProcessingStrategy = .nativeFirst
    @Published var isOfflineMode: Bool = false
    @Published var nativeAIConfidence: Double = 0.85
    @Published var performanceMetrics: AIPerformanceMetrics = AIPerformanceMetrics()
    @Published var offlineCapabilities: OfflineCapabilities = OfflineCapabilities()
    
    private let nativeAIOptimizer = AppleNativeAIOptimizer.shared
    private let openAIService = OpenAIService.shared
    private let performanceMonitor = AIPerformanceMonitor.shared
    private let naturalLanguageProcessor = NaturalLanguageProcessor.shared
    private let networkMonitor = NetworkMonitor.shared
    private var cancellables = Set<AnyCancellable>()
    private let logger = Logger(subsystem: "com.richnowai", category: "AIProcessingRouter")
    
    private init() {
        loadUserPreferences()
        setupPerformanceMonitoring()
        checkOfflineCapabilities()
        setupNetworkMonitoring()
    }
    
    // MARK: - AI 處理策略枚舉
    
    enum AIProcessingStrategy: String, CaseIterable, Codable {
        case nativeOnly = "nativeOnly"           // 僅使用原生 AI
        case nativeFirst = "nativeFirst"         // 原生優先，失敗時降級到 OpenAI
        case openAIFirst = "openAIFirst"         // OpenAI 優先
        case hybrid = "hybrid"                   // 雙重驗證
        case auto = "auto"                       // 根據設備能力自動選擇
        
        var displayName: String {
            switch self {
            case .nativeOnly: return "僅使用原生 AI"
            case .nativeFirst: return "原生 AI 優先"
            case .openAIFirst: return "OpenAI 優先"
            case .hybrid: return "混合驗證"
            case .auto: return "自動選擇"
            }
        }
        
        var description: String {
            switch self {
            case .nativeOnly: return "完全使用 iPhone 原生 AI，無需網路"
            case .nativeFirst: return "優先使用原生 AI，失敗時使用 OpenAI"
            case .openAIFirst: return "優先使用 OpenAI，備用原生 AI"
            case .hybrid: return "同時使用兩種 AI 進行驗證"
            case .auto: return "根據設備性能和任務自動選擇"
            }
        }
    }
    
    // MARK: - 處理結果
    
    struct ProcessingResult<T> {
        let data: T
        let source: AISource
        let confidence: Double
        let processingTime: TimeInterval
        let fallbackUsed: Bool
        
        enum AISource {
            case native
            case openAI
            case hybrid
        }
    }
    
    // MARK: - 用戶偏好管理
    
    private func loadUserPreferences() {
        // 從 UserDefaults 載入用戶偏好
        // 如果沒有設置過，強制使用原生 AI 優先策略
        if let strategyString = UserDefaults.standard.string(forKey: "aiProcessingStrategy"),
           let strategy = AIProcessingStrategy(rawValue: strategyString) {
            currentStrategy = strategy
            logger.info("從 UserDefaults 載入 AI 策略: \(strategy.displayName)")
        } else {
            // 首次使用，強制設置為原生 AI 優先
            currentStrategy = .nativeFirst
            UserDefaults.standard.set("nativeFirst", forKey: "aiProcessingStrategy")
            logger.info("首次初始化，設置為原生 AI 優先策略")
        }
        
        // 檢查網路狀態
        checkNetworkStatus()
        
        // 如果是離線模式，強制切換到原生 AI
        if isOfflineMode && currentStrategy != .nativeOnly {
            logger.info("離線模式，強制切換到原生 AI 模式")
            currentStrategy = .nativeOnly
        }
    }
    
    func updateStrategy(_ strategy: AIProcessingStrategy) {
        let oldStrategy = currentStrategy
        currentStrategy = strategy
        UserDefaults.standard.set(strategy.rawValue, forKey: "aiProcessingStrategy")
        
        logger.info("AI 處理策略已更新: \(oldStrategy.displayName) → \(strategy.displayName)")
        
        // 根據策略調整設置
        adjustSettingsForStrategy(strategy)
    }
    
    private func adjustSettingsForStrategy(_ strategy: AIProcessingStrategy) {
        switch strategy {
        case .nativeOnly:
            isOfflineMode = true
        case .nativeFirst, .hybrid, .auto:
            isOfflineMode = false
        case .openAIFirst:
            isOfflineMode = false
        }
    }
    
    // MARK: - 網路狀態檢查
    
    private func checkNetworkStatus() {
        // 使用 NetworkMonitor 進行精確的網路狀態檢查
        isOfflineMode = !networkMonitor.isConnected
        
        if isOfflineMode {
            logger.info("檢測到離線模式，將優先使用原生 AI")
        } else {
            let networkQuality = networkMonitor.getNetworkQuality()
            let connectionTypeString: String
            if let type = networkMonitor.connectionType {
                connectionTypeString = type == .wifi ? "WiFi" : (type == .cellular ? "行動網路" : "其他")
            } else {
                connectionTypeString = "未知"
            }
            logger.debug("網路狀態: \(networkQuality.displayName), 類型: \(connectionTypeString)")
        }
    }
    
    private func isNetworkAvailable() -> Bool {
        return networkMonitor.isConnected
    }
    
    // MARK: - 智能路由邏輯
    
    func processTransaction(_ text: String) async throws -> ProcessingResult<ParsedTransaction> {
        let startTime = Date()
        
        logger.debug("開始處理交易文字，策略: \(self.currentStrategy.displayName), 文字長度: \(text.count)字符")
        
        let result: ProcessingResult<ParsedTransaction>
        switch self.currentStrategy {
        case .nativeOnly:
            result = try await processWithNativeOnly(text: text, startTime: startTime)
        case .nativeFirst:
            result = try await processWithNativeFirst(text: text, startTime: startTime)
        case .openAIFirst:
            result = try await processWithOpenAIFirst(text: text, startTime: startTime)
        case .hybrid:
            result = try await processWithHybrid(text: text, startTime: startTime)
        case .auto:
            result = try await processWithAuto(text: text, startTime: startTime)
        }
        
        // 計算並記錄最終信心度
        let finalConfidence = calculateConfidenceScore(for: result)
        logger.info("交易處理完成: 來源=\(String(describing: result.source)), 信心度=\(String(format: "%.2f", finalConfidence)), 時間=\(String(format: "%.2f", result.processingTime))秒")
        
        return result
    }
    
    func processImage(_ image: UIImage) async throws -> ProcessingResult<ExtractedReceiptData> {
        let startTime = Date()
        let imageSize = image.size
        
        logger.debug("開始處理圖像，策略: \(self.currentStrategy.displayName), 圖像尺寸: \(imageSize.width)x\(imageSize.height)")
        
        let result: ProcessingResult<ExtractedReceiptData>
        switch self.currentStrategy {
        case .nativeOnly:
            result = try await processImageWithNativeOnly(image: image, startTime: startTime)
        case .nativeFirst:
            result = try await processImageWithNativeFirst(image: image, startTime: startTime)
        case .openAIFirst:
            result = try await processImageWithOpenAIFirst(image: image, startTime: startTime)
        case .hybrid:
            result = try await processImageWithHybrid(image: image, startTime: startTime)
        case .auto:
            result = try await processImageWithAuto(image: image, startTime: startTime)
        }
        
        let finalConfidence = calculateConfidenceScore(for: result)
        logger.info("圖像處理完成: 來源=\(String(describing: result.source)), 信心度=\(String(format: "%.2f", finalConfidence)), 時間=\(String(format: "%.2f", result.processingTime))秒")
        
        return result
    }
    
    func processVoice(_ audioData: Data) async throws -> ProcessingResult<String> {
        let startTime = Date()
        let audioSizeKB = Double(audioData.count) / 1024.0
        
        logger.debug("開始處理語音，策略: \(self.currentStrategy.displayName), 音頻大小: \(String(format: "%.1f", audioSizeKB))KB")
        
        let result: ProcessingResult<String>
        switch self.currentStrategy {
        case .nativeOnly:
            result = try await processVoiceWithNativeOnly(audioData: audioData, startTime: startTime)
        case .nativeFirst:
            result = try await processVoiceWithNativeFirst(audioData: audioData, startTime: startTime)
        case .openAIFirst:
            result = try await processVoiceWithOpenAIFirst(audioData: audioData, startTime: startTime)
        case .hybrid:
            result = try await processVoiceWithHybrid(audioData: audioData, startTime: startTime)
        case .auto:
            result = try await processVoiceWithAuto(audioData: audioData, startTime: startTime)
        }
        
        let finalConfidence = calculateConfidenceScore(for: result)
        logger.info("語音處理完成: 來源=\(String(describing: result.source)), 信心度=\(String(format: "%.2f", finalConfidence)), 時間=\(String(format: "%.2f", result.processingTime))秒, 轉錄長度=\(result.data.count)字符")
        
        return result
    }
    
    // MARK: - 原生 AI 處理
    
    private func processWithNativeOnly(text: String, startTime: Date) async throws -> ProcessingResult<ParsedTransaction> {
        logger.debug("開始原生 AI 文字處理: \(text.prefix(50))...")
        
        do {
            let result = try await nativeAIOptimizer.parseTransactionWithNaturalLanguage(text)
            let processingTime = Date().timeIntervalSince(startTime)
            
            logger.debug("原生 AI 文字處理成功，處理時間: \(String(format: "%.2f", processingTime))秒")
            
            return ProcessingResult(
                data: result,
                source: .native,
                confidence: 0.8, // 原生 AI 的預設信心度
                processingTime: processingTime,
                fallbackUsed: false
            )
        } catch {
            logger.error("原生 AI 文字處理失敗: \(error.localizedDescription)")
            throw error
        }
    }
    
    private func processImageWithNativeOnly(image: UIImage, startTime: Date) async throws -> ProcessingResult<ExtractedReceiptData> {
        let imageSize = image.size
        logger.debug("開始原生 AI 圖像處理，圖像尺寸: \(imageSize.width)x\(imageSize.height)")
        
        do {
            let result = try await nativeAIOptimizer.extractReceiptDataWithVision(image)
            let processingTime = Date().timeIntervalSince(startTime)
            
            logger.debug("原生 AI 圖像處理成功，處理時間: \(String(format: "%.2f", processingTime))秒，信心度: \(String(format: "%.2f", result.confidence))")
            
            return ProcessingResult(
                data: result,
                source: .native,
                confidence: result.confidence,
                processingTime: processingTime,
                fallbackUsed: false
            )
        } catch {
            logger.error("原生 AI 圖像處理失敗: \(error.localizedDescription)")
            throw error
        }
    }
    
    private func processVoiceWithNativeOnly(audioData: Data, startTime: Date) async throws -> ProcessingResult<String> {
        let audioSizeKB = Double(audioData.count) / 1024.0
        logger.debug("開始原生 AI 語音處理，音頻大小: \(String(format: "%.1f", audioSizeKB))KB")
        
        do {
            let result = try await nativeAIOptimizer.transcribeAudioWithSpeech(audioData)
            let processingTime = Date().timeIntervalSince(startTime)
            
            logger.debug("原生 AI 語音處理成功，處理時間: \(String(format: "%.2f", processingTime))秒，轉錄長度: \(result.count)字符")
            
            return ProcessingResult(
                data: result,
                source: .native,
                confidence: 0.9, // 語音識別通常有較高的信心度
                processingTime: processingTime,
                fallbackUsed: false
            )
        } catch {
            logger.error("原生 AI 語音處理失敗: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - 原生優先處理
    
    private func processWithNativeFirst(text: String, startTime: Date) async throws -> ProcessingResult<ParsedTransaction> {
        do {
            // 先嘗試原生 AI
            let result = try await processWithNativeOnly(text: text, startTime: startTime)
            
            // 檢查信心度是否足夠
            if result.confidence >= nativeAIConfidence {
                logger.debug("原生 AI 處理成功，信心度: \(String(format: "%.2f", result.confidence))")
                return result
            } else {
                // 信心度不足，降級到 OpenAI
                logger.info("原生 AI 信心度不足 (\(String(format: "%.2f", result.confidence)))，降級到 OpenAI")
                return try await processWithOpenAIFallback(text: text, startTime: startTime)
            }
        } catch {
            // 原生 AI 失敗，降級到 OpenAI
            logger.warning("原生 AI 處理失敗: \(error.localizedDescription)，降級到 OpenAI")
            return try await processWithOpenAIFallback(text: text, startTime: startTime)
        }
    }
    
    private func processImageWithNativeFirst(image: UIImage, startTime: Date) async throws -> ProcessingResult<ExtractedReceiptData> {
        do {
            let result = try await processImageWithNativeOnly(image: image, startTime: startTime)
            
            if result.confidence >= nativeAIConfidence {
                logger.debug("原生 AI 圖像處理成功，信心度: \(String(format: "%.2f", result.confidence))")
                return result
            } else {
                logger.info("原生 AI 圖像處理信心度不足 (\(String(format: "%.2f", result.confidence)))，降級到 OpenAI")
                return try await processImageWithOpenAIFallback(image: image, startTime: startTime)
            }
        } catch {
            logger.warning("原生 AI 圖像處理失敗: \(error.localizedDescription)，降級到 OpenAI")
            return try await processImageWithOpenAIFallback(image: image, startTime: startTime)
        }
    }
    
    private func processVoiceWithNativeFirst(audioData: Data, startTime: Date) async throws -> ProcessingResult<String> {
        do {
            let result = try await processVoiceWithNativeOnly(audioData: audioData, startTime: startTime)
            
            if result.confidence >= nativeAIConfidence {
                logger.debug("原生 AI 語音處理成功，信心度: \(String(format: "%.2f", result.confidence))")
                return result
            } else {
                logger.info("原生 AI 語音處理信心度不足 (\(String(format: "%.2f", result.confidence)))，降級到 OpenAI")
                return try await processVoiceWithOpenAIFallback(audioData: audioData, startTime: startTime)
            }
        } catch {
            logger.warning("原生 AI 語音處理失敗: \(error.localizedDescription)，降級到 OpenAI")
            return try await processVoiceWithOpenAIFallback(audioData: audioData, startTime: startTime)
        }
    }
    
    // MARK: - OpenAI 優先處理
    
    private func processWithOpenAIFirst(text: String, startTime: Date) async throws -> ProcessingResult<ParsedTransaction> {
        do {
            // 先嘗試 OpenAI
            let result = try await processWithOpenAI(text: text, startTime: startTime)
            logger.debug("OpenAI 優先模式處理成功")
            return result
        } catch {
            // OpenAI 失敗，降級到原生 AI
            logger.warning("OpenAI 優先模式失敗: \(error.localizedDescription)，降級到原生 AI")
            return try await processWithNativeOnly(text: text, startTime: startTime)
        }
    }
    
    private func processImageWithOpenAIFirst(image: UIImage, startTime: Date) async throws -> ProcessingResult<ExtractedReceiptData> {
        do {
            let result = try await processImageWithOpenAI(image: image, startTime: startTime)
            logger.debug("OpenAI 優先模式（圖像）處理成功")
            return result
        } catch {
            logger.warning("OpenAI 優先模式（圖像）失敗: \(error.localizedDescription)，降級到原生 AI")
            return try await processImageWithNativeOnly(image: image, startTime: startTime)
        }
    }
    
    private func processVoiceWithOpenAIFirst(audioData: Data, startTime: Date) async throws -> ProcessingResult<String> {
        do {
            let result = try await processVoiceWithOpenAI(audioData: audioData, startTime: startTime)
            logger.debug("OpenAI 優先模式（語音）處理成功")
            return result
        } catch {
            logger.warning("OpenAI 優先模式（語音）失敗: \(error.localizedDescription)，降級到原生 AI")
            return try await processVoiceWithNativeOnly(audioData: audioData, startTime: startTime)
        }
    }
    
    // MARK: - 混合處理
    
    private func processWithHybrid(text: String, startTime: Date) async throws -> ProcessingResult<ParsedTransaction> {
        // 同時使用兩種 AI 進行處理（如果網路可用）
        if !isNetworkAvailable() {
            // 網路不可用，只使用原生 AI
            logger.warning("混合模式：網路不可用，僅使用原生 AI")
            return try await processWithNativeOnly(text: text, startTime: startTime)
        }
        
        // 並行處理，但允許單個失敗
        async let nativeTask = Task {
            try? await processWithNativeOnly(text: text, startTime: startTime)
        }
        async let openAITask = Task {
            try? await processWithOpenAI(text: text, startTime: startTime)
        }
        
        let nativeResult = await nativeTask.value
        let openAIResult = await openAITask.value
        
        // 比較結果並選擇最佳
        if let native = nativeResult, let openAI = openAIResult {
            // 兩個都成功，選擇信心度更高的
            let selected = native.confidence >= openAI.confidence ? native : openAI
            logger.debug("混合模式：兩者成功，選擇信心度更高的 (\(String(format: "%.2f", selected.confidence)))")
            
            return ProcessingResult(
                data: selected.data,
                source: .hybrid,
                confidence: max(native.confidence, openAI.confidence) * 1.1, // 混合模式增加 10% 信心度
                processingTime: max(native.processingTime, openAI.processingTime),
                fallbackUsed: false
            )
        } else if let native = nativeResult {
            // 只有原生 AI 成功
            logger.info("混合模式：僅原生 AI 成功")
            return native
        } else if let openAI = openAIResult {
            // 只有 OpenAI 成功
            logger.info("混合模式：僅 OpenAI 成功")
            return openAI
        } else {
            // 兩者都失敗
            logger.error("混合模式：兩種 AI 處理都失敗")
            throw AIProcessingError.textProcessingFailed
        }
    }
    
    private func processImageWithHybrid(image: UIImage, startTime: Date) async throws -> ProcessingResult<ExtractedReceiptData> {
        if !isNetworkAvailable() {
            logger.warning("混合模式（圖像）：網路不可用，僅使用原生 AI")
            return try await processImageWithNativeOnly(image: image, startTime: startTime)
        }
        
        // 並行處理，允許單個失敗
        async let nativeTask = Task {
            try? await processImageWithNativeOnly(image: image, startTime: startTime)
        }
        async let openAITask = Task {
            try? await processImageWithOpenAI(image: image, startTime: startTime)
        }
        
        let nativeResult = await nativeTask.value
        let openAIResult = await openAITask.value
        
        if let native = nativeResult, let openAI = openAIResult {
            let selected = native.confidence >= openAI.confidence ? native : openAI
            logger.debug("混合模式（圖像）：兩者成功，選擇信心度更高的 (\(String(format: "%.2f", selected.confidence)))")
            
            return ProcessingResult(
                data: selected.data,
                source: .hybrid,
                confidence: max(native.confidence, openAI.confidence) * 1.1,
                processingTime: max(native.processingTime, openAI.processingTime),
                fallbackUsed: false
            )
        } else if let native = nativeResult {
            logger.info("混合模式（圖像）：僅原生 AI 成功")
            return native
        } else if let openAI = openAIResult {
            logger.info("混合模式（圖像）：僅 OpenAI 成功")
            return openAI
        } else {
            logger.error("混合模式（圖像）：兩種 AI 處理都失敗")
            throw AIProcessingError.imageProcessingFailed
        }
    }
    
    private func processVoiceWithHybrid(audioData: Data, startTime: Date) async throws -> ProcessingResult<String> {
        if !isNetworkAvailable() {
            logger.warning("混合模式（語音）：網路不可用，僅使用原生 AI")
            return try await processVoiceWithNativeOnly(audioData: audioData, startTime: startTime)
        }
        
        // 並行處理，允許單個失敗
        async let nativeTask = Task {
            try? await processVoiceWithNativeOnly(audioData: audioData, startTime: startTime)
        }
        async let openAITask = Task {
            try? await processVoiceWithOpenAI(audioData: audioData, startTime: startTime)
        }
        
        let nativeResult = await nativeTask.value
        let openAIResult = await openAITask.value
        
        if let native = nativeResult, let openAI = openAIResult {
            let selected = native.confidence >= openAI.confidence ? native : openAI
            logger.debug("混合模式（語音）：兩者成功，選擇信心度更高的 (\(String(format: "%.2f", selected.confidence)))")
            
            return ProcessingResult(
                data: selected.data,
                source: .hybrid,
                confidence: max(native.confidence, openAI.confidence) * 1.1,
                processingTime: max(native.processingTime, openAI.processingTime),
                fallbackUsed: false
            )
        } else if let native = nativeResult {
            logger.info("混合模式（語音）：僅原生 AI 成功")
            return native
        } else if let openAI = openAIResult {
            logger.info("混合模式（語音）：僅 OpenAI 成功")
            return openAI
        } else {
            logger.error("混合模式（語音）：兩種 AI 處理都失敗")
            throw AIProcessingError.audioProcessingFailed
        }
    }
    
    // MARK: - 自動選擇處理
    
    private func processWithAuto(text: String, startTime: Date) async throws -> ProcessingResult<ParsedTransaction> {
        // 根據設備性能、任務複雜度和網路狀況自動選擇
        let deviceCapability = getDeviceCapability()
        let taskComplexity = assessTaskComplexity(text: text)
        let isNetworkGood = isNetworkAvailable() && !networkMonitor.isLowBandwidth()
        
        // 決策矩陣
        if !isNetworkAvailable() {
            // 離線時強制使用原生 AI
            logger.debug("自動模式：離線，使用原生 AI")
            return try await processWithNativeOnly(text: text, startTime: startTime)
        } else if deviceCapability >= 0.8 && taskComplexity <= 0.5 && isNetworkGood {
            // 高性能設備 + 簡單任務 + 良好網路 = 使用原生 AI
            logger.debug("自動模式：高性能+簡單任務+良好網路，使用原生 AI")
            return try await processWithNativeOnly(text: text, startTime: startTime)
        } else if deviceCapability >= 0.7 && taskComplexity <= 0.7 {
            // 較高性能設備 + 中等任務 = 原生優先
            logger.debug("自動模式：中等性能+中等任務，原生優先")
            return try await processWithNativeFirst(text: text, startTime: startTime)
        } else if taskComplexity > 0.8 || deviceCapability < 0.5 {
            // 複雜任務或低性能設備 = OpenAI 優先
            logger.debug("自動模式：複雜任務或低性能設備，OpenAI 優先")
            return try await processWithOpenAIFirst(text: text, startTime: startTime)
        } else {
            // 其他情況使用混合模式
            logger.debug("自動模式：預設使用混合模式")
            return try await processWithHybrid(text: text, startTime: startTime)
        }
    }
    
    private func processImageWithAuto(image: UIImage, startTime: Date) async throws -> ProcessingResult<ExtractedReceiptData> {
        let deviceCapability = getDeviceCapability()
        let taskComplexity = assessImageComplexity(image: image)
        let isNetworkGood = isNetworkAvailable() && !networkMonitor.isLowBandwidth()
        
        if !isNetworkAvailable() {
            logger.debug("自動模式（圖像）：離線，使用原生 AI")
            return try await processImageWithNativeOnly(image: image, startTime: startTime)
        } else if deviceCapability >= 0.8 && taskComplexity <= 0.5 && isNetworkGood {
            logger.debug("自動模式（圖像）：高性能+簡單任務+良好網路，使用原生 AI")
            return try await processImageWithNativeOnly(image: image, startTime: startTime)
        } else if deviceCapability >= 0.7 && taskComplexity <= 0.7 {
            logger.debug("自動模式（圖像）：中等性能+中等任務，原生優先")
            return try await processImageWithNativeFirst(image: image, startTime: startTime)
        } else if taskComplexity > 0.8 || deviceCapability < 0.5 {
            logger.debug("自動模式（圖像）：複雜任務或低性能設備，OpenAI 優先")
            return try await processImageWithOpenAIFirst(image: image, startTime: startTime)
        } else {
            logger.debug("自動模式（圖像）：預設使用混合模式")
            return try await processImageWithHybrid(image: image, startTime: startTime)
        }
    }
    
    private func processVoiceWithAuto(audioData: Data, startTime: Date) async throws -> ProcessingResult<String> {
        let deviceCapability = getDeviceCapability()
        let audioComplexity = assessAudioComplexity(audioData: audioData)
        let isNetworkGood = isNetworkAvailable() && !networkMonitor.isLowBandwidth()
        
        if !isNetworkAvailable() {
            logger.debug("自動模式（語音）：離線，使用原生 AI")
            return try await processVoiceWithNativeOnly(audioData: audioData, startTime: startTime)
        } else if deviceCapability >= 0.8 && audioComplexity <= 0.5 && isNetworkGood {
            logger.debug("自動模式（語音）：高性能+簡單音頻+良好網路，使用原生 AI")
            return try await processVoiceWithNativeOnly(audioData: audioData, startTime: startTime)
        } else if deviceCapability >= 0.7 && audioComplexity <= 0.7 {
            logger.debug("自動模式（語音）：中等性能+中等音頻，原生優先")
            return try await processVoiceWithNativeFirst(audioData: audioData, startTime: startTime)
        } else {
            logger.debug("自動模式（語音）：複雜或低性能，OpenAI 優先")
            return try await processVoiceWithOpenAIFirst(audioData: audioData, startTime: startTime)
        }
    }
    
    // MARK: - OpenAI 處理方法
    
    private func processWithOpenAI(text: String, startTime: Date) async throws -> ProcessingResult<ParsedTransaction> {
        // 檢查網路可用性
        guard isNetworkAvailable() else {
            logger.error("OpenAI 處理時發現網路不可用")
            throw AIProcessingError.networkUnavailable
        }
        
        let result = try await openAIService.parseTransactionFromText(text)
        let processingTime = Date().timeIntervalSince(startTime)
        
        // 轉換 TransactionParseResult 為 ParsedTransaction
        let parsedTransaction = ParsedTransaction(
            amount: result.amount ?? 0.0,
            category: result.category ?? "其他",
            description: result.description ?? "",
            date: Date(), // 使用當前日期
            type: .expense // 預設為支出
        )
        
        logger.debug("OpenAI 文字處理成功，處理時間: \(String(format: "%.2f", processingTime))秒")
        
        return ProcessingResult(
            data: parsedTransaction,
            source: .openAI,
            confidence: 0.9, // OpenAI 通常有較高的信心度
            processingTime: processingTime,
            fallbackUsed: false
        )
    }
    
    private func processImageWithOpenAI(image: UIImage, startTime: Date) async throws -> ProcessingResult<ExtractedReceiptData> {
        guard isNetworkAvailable() else {
            logger.error("OpenAI 圖像處理時發現網路不可用")
            throw AIProcessingError.networkUnavailable
        }
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            logger.error("無法將圖片轉換為 JPEG 數據")
            throw AIProcessingError.imageProcessingFailed
        }
        
        let result = try await openAIService.analyzeReceipt(imageData: imageData)
        let processingTime = Date().timeIntervalSince(startTime)
        
        // 轉換 TransactionParseResult 為 ExtractedReceiptData
        let extractedData = ExtractedReceiptData(
            merchant: "未知商家",
            amount: result.amount ?? 0.0,
            currency: "USD",
            date: result.date ?? Date().formatted(date: .abbreviated, time: .omitted),
            items: [],
            tax: 0.0,
            total: result.amount ?? 0.0,
            paymentMethod: "未知",
            category: result.category ?? "其他",
            confidence: result.confidence,
            notes: result.description ?? "",
            extractedAt: Date()
        )
        
        logger.debug("OpenAI 圖像處理成功，處理時間: \(String(format: "%.2f", processingTime))秒")
        
        return ProcessingResult(
            data: extractedData,
            source: .openAI,
            confidence: 0.9,
            processingTime: processingTime,
            fallbackUsed: false
        )
    }
    
    private func processVoiceWithOpenAI(audioData: Data, startTime: Date) async throws -> ProcessingResult<String> {
        guard isNetworkAvailable() else {
            logger.error("OpenAI 語音處理時發現網路不可用")
            throw AIProcessingError.networkUnavailable
        }
        
        let result = try await openAIService.transcribeAudio(audioData: audioData)
        let processingTime = Date().timeIntervalSince(startTime)
        
        logger.debug("OpenAI 語音處理成功，處理時間: \(String(format: "%.2f", processingTime))秒，轉錄長度: \(result.count)字符")
        
        return ProcessingResult(
            data: result,
            source: .openAI,
            confidence: 0.9,
            processingTime: processingTime,
            fallbackUsed: false
        )
    }
    
    // MARK: - 降級處理方法
    
    private func processWithOpenAIFallback(text: String, startTime: Date) async throws -> ProcessingResult<ParsedTransaction> {
        // 檢查網路可用性
        guard isNetworkAvailable() else {
            logger.error("降級到 OpenAI 時發現網路不可用")
            throw AIProcessingError.networkUnavailable
        }
        
        let result = try await processWithOpenAI(text: text, startTime: startTime)
        logger.info("OpenAI 降級處理成功，信心度: \(String(format: "%.2f", result.confidence))")
        
        return ProcessingResult(
            data: result.data,
            source: result.source,
            confidence: result.confidence,
            processingTime: result.processingTime,
            fallbackUsed: true
        )
    }
    
    private func processImageWithOpenAIFallback(image: UIImage, startTime: Date) async throws -> ProcessingResult<ExtractedReceiptData> {
        guard isNetworkAvailable() else {
            logger.error("降級到 OpenAI 圖像處理時發現網路不可用")
            throw AIProcessingError.networkUnavailable
        }
        
        let result = try await processImageWithOpenAI(image: image, startTime: startTime)
        logger.info("OpenAI 圖像降級處理成功，信心度: \(String(format: "%.2f", result.confidence))")
        
        return ProcessingResult(
            data: result.data,
            source: result.source,
            confidence: result.confidence,
            processingTime: result.processingTime,
            fallbackUsed: true
        )
    }
    
    private func processVoiceWithOpenAIFallback(audioData: Data, startTime: Date) async throws -> ProcessingResult<String> {
        guard isNetworkAvailable() else {
            logger.error("降級到 OpenAI 語音處理時發現網路不可用")
            throw AIProcessingError.networkUnavailable
        }
        
        let result = try await processVoiceWithOpenAI(audioData: audioData, startTime: startTime)
        logger.info("OpenAI 語音降級處理成功，信心度: \(String(format: "%.2f", result.confidence))")
        
        return ProcessingResult(
            data: result.data,
            source: result.source,
            confidence: result.confidence,
            processingTime: result.processingTime,
            fallbackUsed: true
        )
    }
    
    // MARK: - 設備能力評估
    
    private func getDeviceCapability() -> Double {
        // 更精確的設備能力評估
        let processInfo = ProcessInfo.processInfo
        let processorCount = processInfo.processorCount
        let memorySize = processInfo.physicalMemory
        let isLowPowerModeEnabled = processInfo.isLowPowerModeEnabled
        
        var capability: Double = 0.5 // 基礎分數
        
        // 處理器核心數評估（更細緻的評分）
        switch processorCount {
        case 8...:
            capability += 0.35
        case 6..<8:
            capability += 0.25
        case 4..<6:
            capability += 0.15
        case 2..<4:
            capability += 0.05
        default:
            break
        }
        
        // 記憶體評估（更精確的範圍）
        let memoryGB = Double(memorySize) / (1024.0 * 1024.0 * 1024.0)
        switch memoryGB {
        case 8...:
            capability += 0.25
        case 6..<8:
            capability += 0.20
        case 4..<6:
            capability += 0.15
        case 3..<4:
            capability += 0.10
        case 2..<3:
            capability += 0.05
        default:
            break
        }
        
        // 低電量模式會降低能力評估
        if isLowPowerModeEnabled {
            capability *= 0.7
            logger.debug("設備處於低電量模式，能力評估降低 30%")
        }
        
        let finalCapability = min(capability, 1.0)
        logger.debug("設備能力評估: \(String(format: "%.2f", finalCapability)) (CPU: \(processorCount)核, 記憶體: \(String(format: "%.1f", memoryGB))GB)")
        
        return finalCapability
    }
    
    private func assessTaskComplexity(text: String) -> Double {
        // 評估任務複雜度
        let length = text.count
        let wordCount = text.components(separatedBy: .whitespaces).count
        
        var complexity: Double = 0.0
        
        // 文字長度評估
        if length > 200 {
            complexity += 0.3
        } else if length > 100 {
            complexity += 0.2
        } else if length > 50 {
            complexity += 0.1
        }
        
        // 詞彙數量評估
        if wordCount > 30 {
            complexity += 0.3
        } else if wordCount > 15 {
            complexity += 0.2
        } else if wordCount > 5 {
            complexity += 0.1
        }
        
        // 特殊字符評估
        let specialCharCount = text.filter { !$0.isLetter && !$0.isNumber && !$0.isWhitespace }.count
        if specialCharCount > 10 {
            complexity += 0.2
        } else if specialCharCount > 5 {
            complexity += 0.1
        }
        
        return min(complexity, 1.0)
    }
    
    private func assessImageComplexity(image: UIImage) -> Double {
        // 評估圖像複雜度
        let size = image.size
        let area = size.width * size.height
        
        var complexity: Double = 0.0
        
        // 圖像大小評估
        if area > 2000000 { // 2MP
            complexity += 0.4
        } else if area > 1000000 { // 1MP
            complexity += 0.2
        }
        
        // 圖像比例評估
        let aspectRatio = size.width / size.height
        if aspectRatio > 3 || aspectRatio < 0.33 {
            complexity += 0.2 // 極端比例增加複雜度
        }
        
        return min(complexity, 1.0)
    }
    
    private func assessAudioComplexity(audioData: Data) -> Double {
        // 評估音頻複雜度
        let duration = Double(audioData.count) / 16000.0 // 假設 16kHz 採樣率
        let size = audioData.count
        
        var complexity: Double = 0.0
        
        // 音頻長度評估
        if duration > 30 {
            complexity += 0.4
        } else if duration > 10 {
            complexity += 0.2
        } else if duration > 5 {
            complexity += 0.1
        }
        
        // 文件大小評估
        if size > 1000000 { // 1MB
            complexity += 0.3
        } else if size > 500000 { // 500KB
            complexity += 0.2
        } else if size > 100000 { // 100KB
            complexity += 0.1
        }
        
        return min(complexity, 1.0)
    }
    
    // MARK: - 性能監控設置
    
    private func setupPerformanceMonitoring() {
        // 監聽性能指標變化
        performanceMonitor.$metrics
            .sink { [weak self] (metrics: AIPerformanceMetrics) in
                self?.performanceMetrics = metrics
            }
            .store(in: &cancellables)
    }
}

// MARK: - 錯誤定義

enum AIProcessingError: Error, LocalizedError {
    case imageProcessingFailed
    case audioProcessingFailed
    case textProcessingFailed
    case networkUnavailable
    case insufficientConfidence
    case processingTimeout
    
    var errorDescription: String? {
        switch self {
        case .imageProcessingFailed:
            return "圖像處理失敗"
        case .audioProcessingFailed:
            return "音頻處理失敗"
        case .textProcessingFailed:
            return "文字處理失敗"
        case .networkUnavailable:
            return "網路不可用"
        case .insufficientConfidence:
            return "處理信心度不足"
        case .processingTimeout:
            return "處理超時"
        }
    }
}

// MARK: - 離線能力結構

struct OfflineCapabilities {
    var textProcessing: Bool = true
    var imageProcessing: Bool = true
    var voiceProcessing: Bool = true
    var languageDetection: Bool = true
    var sentimentAnalysis: Bool = true
    var entityRecognition: Bool = true
    
    var overallScore: Double {
        let capabilities = [textProcessing, imageProcessing, voiceProcessing, languageDetection, sentimentAnalysis, entityRecognition]
        let availableCount = capabilities.filter { $0 }.count
        return Double(availableCount) / Double(capabilities.count)
    }
}

// MARK: - 離線模式支持

extension AIProcessingRouter {
    
    private func checkOfflineCapabilities() {
        // 檢查設備的原生 AI 能力
        offlineCapabilities.textProcessing = true // Natural Language Framework 通常可用
        offlineCapabilities.imageProcessing = true // Vision Framework 通常可用
        offlineCapabilities.voiceProcessing = true // Speech Framework 通常可用（iOS 10+）
        offlineCapabilities.languageDetection = true // NLLanguageRecognizer 通常可用
        offlineCapabilities.sentimentAnalysis = true // NLTagger 支持情感分析
        offlineCapabilities.entityRecognition = true // NLTagger 支持實體識別
        
        // 根據離線能力調整策略
        if offlineCapabilities.overallScore >= 0.8 {
            currentStrategy = .nativeFirst
        } else if offlineCapabilities.overallScore >= 0.5 {
            currentStrategy = .hybrid
        } else {
            currentStrategy = .openAIFirst
        }
    }
    
    private func setupNetworkMonitoring() {
        // 監聽網路狀態變化
        networkMonitor.$isConnected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isConnected in
                guard let self = self else { return }
                
                let wasOffline = self.isOfflineMode
                self.isOfflineMode = !isConnected
                
                if !isConnected {
                    // 離線時強制使用原生 AI
                    let oldStrategy = self.currentStrategy
                    self.currentStrategy = .nativeOnly
                    
                    if oldStrategy != .nativeOnly {
                        self.logger.info("網路離線，自動切換到原生 AI 模式")
                    }
                } else if wasOffline && self.currentStrategy == .nativeOnly {
                    // 恢復連線後，恢復原策略（除非用戶明確選擇 nativeOnly）
                    self.logger.info("網路恢復連線，恢復原策略")
                    self.loadUserPreferences()
                }
                
                // 根據網路品質調整策略
                self.adjustStrategyForNetworkQuality()
            }
            .store(in: &cancellables)
        
        // 監聽網路品質變化
        networkMonitor.objectWillChange
            .sink { [weak self] _ in
                self?.adjustStrategyForNetworkQuality()
            }
            .store(in: &cancellables)
    }
    
    private func adjustStrategyForNetworkQuality() {
        // 如果網路品質很差，傾向使用原生 AI
        if networkMonitor.isLowBandwidth() && currentStrategy == .openAIFirst {
            logger.info("網路品質差，建議使用原生 AI")
            // 不自動切換，只是記錄日誌
        }
    }
    
    // MARK: - 離線模式處理
    
    func processOfflineTransaction(_ text: String) async throws -> ProcessingResult<ParsedTransaction> {
        guard isOfflineMode else {
            logger.warning("嘗試使用離線處理但網路可用")
            throw AIProcessingError.networkUnavailable
        }
        
        logger.info("開始離線模式交易處理")
        let startTime = Date()
        
        let analysis = await naturalLanguageProcessor.analyzeTransactionText(text)
        let processingTime = Date().timeIntervalSince(startTime)
        
        let parsedTransaction = ParsedTransaction(
            amount: analysis.amounts.first?.value ?? 0.0,
            category: analysis.category,
            description: analysis.originalText,
            date: Date(),
            type: analysis.transactionType == TransactionType.income ? TransactionType.income : TransactionType.expense
        )
        
        logger.info("離線交易處理成功，金額: \(parsedTransaction.amount), 分類: \(parsedTransaction.category)")
        
        return ProcessingResult(
            data: parsedTransaction,
            source: .native,
            confidence: analysis.confidence,
            processingTime: processingTime,
            fallbackUsed: false
        )
    }
    
    func processOfflineImage(_ image: UIImage) async throws -> ProcessingResult<ExtractedReceiptData> {
        guard isOfflineMode else {
            logger.warning("嘗試使用離線圖像處理但網路可用")
            throw AIProcessingError.networkUnavailable
        }
        
        logger.info("開始離線模式圖像處理")
        let startTime = Date()
        
        do {
            let extractedData = try await nativeAIOptimizer.extractReceiptDataWithVision(image)
            let processingTime = Date().timeIntervalSince(startTime)
            
            logger.info("離線圖像處理成功，商家: \(extractedData.merchant), 金額: \(extractedData.amount)")
            
            return ProcessingResult(
                data: extractedData,
                source: .native,
                confidence: extractedData.confidence,
                processingTime: processingTime,
                fallbackUsed: false
            )
        } catch {
            logger.error("離線圖像處理失敗: \(error.localizedDescription)")
            throw AIProcessingError.imageProcessingFailed
        }
    }
    
    func processOfflineVoice(_ audioData: Data) async throws -> ProcessingResult<String> {
        guard isOfflineMode else {
            logger.warning("嘗試使用離線語音處理但網路可用")
            throw AIProcessingError.networkUnavailable
        }
        
        logger.info("開始離線模式語音處理")
        let startTime = Date()
        
        do {
            let transcription = try await nativeAIOptimizer.transcribeAudioWithSpeech(audioData)
            let processingTime = Date().timeIntervalSince(startTime)
            
            logger.info("離線語音處理成功，轉錄: \(transcription.prefix(50))...")
            
            return ProcessingResult(
                data: transcription,
                source: .native,
                confidence: 0.8, // 語音識別默認信心度
                processingTime: processingTime,
                fallbackUsed: false
            )
        } catch {
            logger.error("離線語音處理失敗: \(error.localizedDescription)")
            throw AIProcessingError.audioProcessingFailed
        }
    }
    
    // MARK: - 信心度評分機制
    
    func calculateConfidenceScore<T>(for result: ProcessingResult<T>) -> Double {
        var baseConfidence = result.confidence
        
        // 根據處理時間調整信心度（更平滑的曲線）
        if result.processingTime < 0.5 {
            baseConfidence += 0.15 // 極快處理大幅增加信心度
        } else if result.processingTime < 1.0 {
            baseConfidence += 0.1 // 快速處理增加信心度
        } else if result.processingTime < 2.0 {
            baseConfidence += 0.05 // 正常處理略微增加
        } else if result.processingTime > 5.0 {
            baseConfidence -= 0.15 // 慢速處理顯著降低信心度
        } else if result.processingTime > 3.0 {
            baseConfidence -= 0.1 // 較慢處理降低信心度
        }
        
        // 根據處理源調整信心度
        switch result.source {
        case .native:
            // 原生 AI 更穩定且離線可用
            baseConfidence += 0.05
        case .openAI:
            // OpenAI 通常更準確但依賴網路
            baseConfidence += 0.1
            // 如果網路品質差，降低信心度
            if networkMonitor.isLowBandwidth() {
                baseConfidence -= 0.05
            }
        case .hybrid:
            // 混合模式最可靠，因為經過雙重驗證
            baseConfidence += 0.15
        }
        
        // 根據離線模式和網路品質調整
        if isOfflineMode {
            baseConfidence -= 0.03 // 離線模式略微降低
        } else {
            let networkQuality = networkMonitor.getNetworkQuality()
            switch networkQuality {
            case .excellent:
                baseConfidence += 0.05
            case .good:
                baseConfidence += 0.02
            case .poor:
                baseConfidence -= 0.05
            case .offline, .unknown:
                baseConfidence -= 0.03
            }
        }
        
        // 根據是否使用降級處理調整
        if result.fallbackUsed {
            baseConfidence -= 0.05 // 降級處理可能略低
        }
        
        let finalConfidence = min(max(baseConfidence, 0.0), 1.0)
        logger.debug("信心度計算: 基礎=\(String(format: "%.2f", result.confidence)), 最終=\(String(format: "%.2f", finalConfidence))")
        
        return finalConfidence
    }
    
    func shouldUseFallback(for confidence: Double) -> Bool {
        let threshold = nativeAIConfidence
        return confidence < threshold
    }
}

// MARK: - 性能指標 (定義在 AppleNativeAIOptimizer.swift 中)
