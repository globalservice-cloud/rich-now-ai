//
//  AIPerformanceMonitor.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/28.
//

import Foundation
import Combine
import os.log

@MainActor
class AIPerformanceMonitor: ObservableObject {
    static let shared = AIPerformanceMonitor()
    
    @Published var metrics: AIPerformanceMetrics = AIPerformanceMetrics()
    @Published var isMonitoring: Bool = false
    @Published var performanceReport: PerformanceReport?
    
    private let logger = Logger(subsystem: "com.richnowai", category: "AIPerformanceMonitor")
    private var cancellables = Set<AnyCancellable>()
    private var monitoringTimer: Timer?
    
    // 性能數據收集
    private var nativeAIAttempts: Int = 0
    private var nativeAISuccesses: Int = 0
    private var openAIAttempts: Int = 0
    private var openAISuccesses: Int = 0
    private var totalProcessingTime: TimeInterval = 0
    private var totalConfidence: Double = 0
    private var confidenceCount: Int = 0
    private var costSavings: Double = 0
    
    // 性能歷史記錄
    private var performanceHistory: [PerformanceSnapshot] = []
    private let maxHistorySize = 100
    
    private init() {
        startMonitoring()
    }
    
    deinit {
        // 在 deinit 中不能調用 async 方法，所以只清理同步資源
        monitoringTimer?.invalidate()
        monitoringTimer = nil
    }
    
    // MARK: - 監控控制
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        logger.info("AI Performance monitoring started")
        
        // 每分鐘更新一次性能指標
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.updateMetrics()
            }
        }
    }
    
    func stopMonitoring() {
        isMonitoring = false
        monitoringTimer?.invalidate()
        monitoringTimer = nil
        logger.info("AI Performance monitoring stopped")
    }
    
    // MARK: - 性能記錄
    
    func recordNativeAIProcessing(
        success: Bool,
        processingTime: TimeInterval,
        confidence: Double? = nil
    ) {
        nativeAIAttempts += 1
        if success {
            nativeAISuccesses += 1
        }
        
        totalProcessingTime += processingTime
        
        if let confidence = confidence {
            totalConfidence += confidence
            confidenceCount += 1
        }
        
        // 記錄性能快照
        let snapshot = PerformanceSnapshot(
            timestamp: Date(),
            source: .native,
            success: success,
            processingTime: processingTime,
            confidence: confidence ?? 0.0
        )
        addPerformanceSnapshot(snapshot)
        
        logger.debug("Native AI processing recorded: success=\(success), time=\(processingTime)s, confidence=\(confidence ?? 0)")
    }
    
    func recordOpenAIProcessing(
        success: Bool,
        processingTime: TimeInterval,
        confidence: Double? = nil,
        cost: Double = 0.0
    ) {
        openAIAttempts += 1
        if success {
            openAISuccesses += 1
        }
        
        totalProcessingTime += processingTime
        
        if let confidence = confidence {
            totalConfidence += confidence
            confidenceCount += 1
        }
        
        // 計算成本節省（如果使用原生 AI 成功）
        if success {
            costSavings += cost
        }
        
        // 記錄性能快照
        let snapshot = PerformanceSnapshot(
            timestamp: Date(),
            source: .openAI,
            success: success,
            processingTime: processingTime,
            confidence: confidence ?? 0.0
        )
        addPerformanceSnapshot(snapshot)
        
        logger.debug("OpenAI processing recorded: success=\(success), time=\(processingTime)s, confidence=\(confidence ?? 0), cost=\(cost)")
    }
    
    func recordHybridProcessing(
        nativeSuccess: Bool,
        openAISuccess: Bool,
        nativeTime: TimeInterval,
        openAITime: TimeInterval,
        nativeConfidence: Double? = nil,
        openAIConfidence: Double? = nil,
        cost: Double = 0.0
    ) {
        // 記錄原生 AI 部分
        recordNativeAIProcessing(
            success: nativeSuccess,
            processingTime: nativeTime,
            confidence: nativeConfidence
        )
        
        // 記錄 OpenAI 部分
        recordOpenAIProcessing(
            success: openAISuccess,
            processingTime: openAITime,
            confidence: openAIConfidence,
            cost: cost
        )
    }
    
    // MARK: - 性能快照管理
    
    private func addPerformanceSnapshot(_ snapshot: PerformanceSnapshot) {
        performanceHistory.append(snapshot)
        
        // 保持歷史記錄大小限制
        if performanceHistory.count > maxHistorySize {
            performanceHistory.removeFirst(performanceHistory.count - maxHistorySize)
        }
    }
    
    // MARK: - 指標更新
    
    private func updateMetrics() {
        let _ = Date()
        
        // 計算成功率
        let nativeSuccessRate = nativeAIAttempts > 0 ? Double(nativeAISuccesses) / Double(nativeAIAttempts) : 0.0
        let openAISuccessRate = openAIAttempts > 0 ? Double(openAISuccesses) / Double(openAIAttempts) : 0.0
        
        // 計算平均處理時間
        let totalAttempts = nativeAIAttempts + openAIAttempts
        let averageProcessingTime = totalAttempts > 0 ? totalProcessingTime / Double(totalAttempts) : 0.0
        
        // 計算平均信心度
        let averageConfidence = confidenceCount > 0 ? totalConfidence / Double(confidenceCount) : 0.0
        
        // 更新指標
        metrics = AIPerformanceMetrics(
            visionProcessingTime: getAverageProcessingTime(for: .vision),
            speechProcessingTime: getAverageProcessingTime(for: .speech),
            mlProcessingTime: getAverageProcessingTime(for: .ml),
            memoryUsage: getCurrentMemoryUsage(),
            cpuUsage: getCurrentCPUUsage(),
            nativeAISuccessRate: nativeSuccessRate,
            openAISuccessRate: openAISuccessRate,
            averageConfidence: averageConfidence,
            costSavings: costSavings
        )
        
        // 生成性能報告
        generatePerformanceReport()
        
        logger.debug("Performance metrics updated: native=\(nativeSuccessRate), openAI=\(openAISuccessRate), avgTime=\(averageProcessingTime)s")
    }
    
    private func getAverageProcessingTime(for type: ProcessingType) -> Double {
        let recentSnapshots = performanceHistory.filter { snapshot in
            snapshot.timestamp.timeIntervalSinceNow > -3600 // 最近一小時
        }
        
        let typeSnapshots = recentSnapshots.filter { snapshot in
            snapshot.processingType == type
        }
        
        guard !typeSnapshots.isEmpty else { return 0.0 }
        
        let totalTime = typeSnapshots.reduce(0.0) { $0 + $1.processingTime }
        return totalTime / Double(typeSnapshots.count)
    }
    
    private func getCurrentMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            let usedMemory = Double(info.resident_size) / (1024 * 1024) // MB
            return usedMemory
        }
        
        return 0.0
    }
    
    private func getCurrentCPUUsage() -> Double {
        // 簡化的 CPU 使用率計算
        // 實際應用中應該使用更精確的方法
        return 0.0
    }
    
    // MARK: - 性能報告生成
    
    private func generatePerformanceReport() {
        let report = PerformanceReport(
            generatedAt: Date(),
            totalNativeAttempts: nativeAIAttempts,
            totalOpenAIAttempts: openAIAttempts,
            nativeSuccessRate: metrics.nativeAISuccessRate,
            openAISuccessRate: metrics.openAISuccessRate,
            averageProcessingTime: getAverageProcessingTime(for: .all),
            averageConfidence: metrics.averageConfidence,
            costSavings: metrics.costSavings,
            recommendations: generateRecommendations()
        )
        
        performanceReport = report
    }
    
    private func generateRecommendations() -> [String] {
        var recommendations: [String] = []
        
        // 基於成功率給出建議
        if metrics.nativeAISuccessRate < 0.7 && metrics.openAISuccessRate > 0.9 {
            recommendations.append("建議增加 OpenAI 使用比例，原生 AI 成功率較低")
        } else if metrics.nativeAISuccessRate > 0.9 && metrics.costSavings > 0 {
            recommendations.append("原生 AI 表現優秀，可考慮增加使用比例以節省成本")
        }
        
        // 基於處理時間給出建議
        if metrics.visionProcessingTime > 5.0 {
            recommendations.append("圖像處理時間較長，建議優化圖片大小或質量")
        }
        
        if metrics.speechProcessingTime > 3.0 {
            recommendations.append("語音處理時間較長，建議縮短音頻長度")
        }
        
        // 基於信心度給出建議
        if metrics.averageConfidence < 0.8 {
            recommendations.append("平均信心度較低，建議啟用混合驗證模式")
        }
        
        return recommendations
    }
    
    // MARK: - 重置統計
    
    func resetStatistics() {
        nativeAIAttempts = 0
        nativeAISuccesses = 0
        openAIAttempts = 0
        openAISuccesses = 0
        totalProcessingTime = 0
        totalConfidence = 0
        confidenceCount = 0
        costSavings = 0
        performanceHistory.removeAll()
        
        metrics = AIPerformanceMetrics()
        performanceReport = nil
        
        logger.info("Performance statistics reset")
    }
    
    // MARK: - 獲取歷史數據
    
    func getPerformanceHistory(for source: AISource? = nil, hours: Int = 24) -> [PerformanceSnapshot] {
        let cutoffTime = Date().addingTimeInterval(-TimeInterval(hours * 3600))
        
        let filteredHistory = performanceHistory.filter { snapshot in
            snapshot.timestamp >= cutoffTime
        }
        
        if let source = source {
            return filteredHistory.filter { $0.source == source }
        }
        
        return filteredHistory
    }
    
    func getPerformanceTrend(for source: AISource, hours: Int = 24) -> [Double] {
        let history = getPerformanceHistory(for: source, hours: hours)
        
        // 按小時分組計算成功率
        var hourlySuccessRates: [Double] = []
        
        for hour in 0..<hours {
            let hourStart = Date().addingTimeInterval(-TimeInterval((hour + 1) * 3600))
            let hourEnd = Date().addingTimeInterval(-TimeInterval(hour * 3600))
            
            let hourSnapshots = history.filter { snapshot in
                snapshot.timestamp >= hourStart && snapshot.timestamp < hourEnd
            }
            
            if !hourSnapshots.isEmpty {
                let successCount = hourSnapshots.filter { $0.success }.count
                let successRate = Double(successCount) / Double(hourSnapshots.count)
                hourlySuccessRates.append(successRate)
            } else {
                hourlySuccessRates.append(0.0)
            }
        }
        
        return hourlySuccessRates.reversed() // 從舊到新
    }
}

// MARK: - 數據模型

struct PerformanceSnapshot {
    let timestamp: Date
    let source: AISource
    let success: Bool
    let processingTime: TimeInterval
    let confidence: Double
    
    var processingType: ProcessingType {
        // 根據處理時間推斷處理類型
        if processingTime < 1.0 {
            return .ml
        } else if processingTime < 3.0 {
            return .speech
        } else {
            return .vision
        }
    }
}

enum AISource {
    case native
    case openAI
    case hybrid
}

enum ProcessingType {
    case vision
    case speech
    case ml
    case all
}

struct PerformanceReport {
    let generatedAt: Date
    let totalNativeAttempts: Int
    let totalOpenAIAttempts: Int
    let nativeSuccessRate: Double
    let openAISuccessRate: Double
    let averageProcessingTime: Double
    let averageConfidence: Double
    let costSavings: Double
    let recommendations: [String]
    
    var summary: String {
        return """
        性能報告 (\(generatedAt.formatted(date: .abbreviated, time: .shortened)))
        
        原生 AI: \(totalNativeAttempts) 次嘗試, \(String(format: "%.1f", nativeSuccessRate * 100))% 成功率
        OpenAI: \(totalOpenAIAttempts) 次嘗試, \(String(format: "%.1f", openAISuccessRate * 100))% 成功率
        
        平均處理時間: \(String(format: "%.2f", averageProcessingTime)) 秒
        平均信心度: \(String(format: "%.2f", averageConfidence))
        成本節省: $\(String(format: "%.2f", costSavings))
        
        建議:
        \(recommendations.joined(separator: "\n• "))
        """
    }
}
