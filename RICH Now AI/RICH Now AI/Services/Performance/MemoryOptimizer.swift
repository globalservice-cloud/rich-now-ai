//
//  MemoryOptimizer.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/28.
//

import Foundation
import UIKit
import Combine
import os.log

@MainActor
class MemoryOptimizer: ObservableObject {
    static let shared = MemoryOptimizer()
    
    @Published var memoryPressure: MemoryPressureLevel = .normal
    @Published var activeOptimizations: Set<MemoryOptimization> = []
    @Published var memoryUsage: MemoryUsage = MemoryUsage()
    
    private var cancellables = Set<AnyCancellable>()
    private var memoryWarningObserver: NSObjectProtocol?
    private let logger = Logger(subsystem: "com.richnowai", category: "MemoryOptimizer")
    
    // 記憶體監控間隔
    private let monitoringInterval: TimeInterval = 1.0
    private var monitoringTimer: Timer?
    
    // 記憶體壓力閾值
    private let warningThreshold: Double = 0.7  // 70%
    private let criticalThreshold: Double = 0.85 // 85%
    
    private init() {
        setupMemoryMonitoring()
        setupMemoryWarningObserver()
    }
    
    deinit {
        // 在 deinit 中不能調用 async 方法，所以只清理同步資源
        monitoringTimer?.invalidate()
        monitoringTimer = nil
        
        if let observer = memoryWarningObserver {
            NotificationCenter.default.removeObserver(observer)
            memoryWarningObserver = nil
        }
    }
    
    // MARK: - 記憶體監控
    
    private func setupMemoryMonitoring() {
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: monitoringInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.updateMemoryUsage()
            }
        }
    }
    
    private func setupMemoryWarningObserver() {
        memoryWarningObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.handleMemoryWarning()
            }
        }
    }
    
    func updateMemoryUsage() async {
        let usage = await getCurrentMemoryUsage()
        memoryUsage = usage
        
        // 更新記憶體壓力等級
        let pressureLevel = determineMemoryPressure(usage: usage)
        if pressureLevel != memoryPressure {
            memoryPressure = pressureLevel
            await applyMemoryOptimizations(for: pressureLevel)
        }
    }
    
    private func getCurrentMemoryUsage() async -> MemoryUsage {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) { infoPtr in
            infoPtr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { reboundInfoPtr in
                withUnsafeMutablePointer(to: &count) { countPtr in
                    countPtr.withMemoryRebound(to: mach_msg_type_number_t.self, capacity: 1) { reboundCountPtr in
                        task_info(mach_task_self_,
                                 task_flavor_t(MACH_TASK_BASIC_INFO),
                                 reboundInfoPtr,
                                 reboundCountPtr)
                    }
                }
            }
        }
        
        if kerr == KERN_SUCCESS {
            let usedMemory = Double(info.resident_size)
            let totalMemory = Double(ProcessInfo.processInfo.physicalMemory)
            let usagePercentage = usedMemory / totalMemory
            
            return MemoryUsage(
                usedBytes: usedMemory,
                totalBytes: totalMemory,
                usagePercentage: usagePercentage,
                timestamp: Date()
            )
        }
        
        return MemoryUsage()
    }
    
    private func determineMemoryPressure(usage: MemoryUsage) -> MemoryPressureLevel {
        switch usage.usagePercentage {
        case 0..<warningThreshold:
            return .normal
        case warningThreshold..<criticalThreshold:
            return .warning
        default:
            return .critical
        }
    }
    
    // MARK: - 記憶體優化策略
    
    private func applyMemoryOptimizations(for level: MemoryPressureLevel) async {
        let optimizations = getOptimizations(for: level)
        
        for optimization in optimizations {
            if !activeOptimizations.contains(optimization) {
                await applyOptimization(optimization)
                activeOptimizations.insert(optimization)
            }
        }
        
        // 移除不再需要的優化
        let currentOptimizations = getOptimizations(for: level)
        activeOptimizations = activeOptimizations.intersection(currentOptimizations)
    }
    
    private func getOptimizations(for level: MemoryPressureLevel) -> Set<MemoryOptimization> {
        switch level {
        case .normal:
            return []
        case .warning:
            return [.imageCacheCleanup, .reduceAnimations, .lazyLoading]
        case .critical:
            return [.imageCacheCleanup, .reduceAnimations, .lazyLoading, .clearUnusedData, .compressImages]
        }
    }
    
    private func applyOptimization(_ optimization: MemoryOptimization) async {
        logger.info("Applying memory optimization: \(optimization.rawValue)")
        
        switch optimization {
        case .imageCacheCleanup:
            await cleanupImageCache()
        case .reduceAnimations:
            await reduceAnimations()
        case .lazyLoading:
            await enableLazyLoading()
        case .clearUnusedData:
            await clearUnusedData()
        case .compressImages:
            await compressImages()
        }
    }
    
    // MARK: - 具體優化實現
    
    private func cleanupImageCache() async {
        // 清理 UIImage 快取
        URLCache.shared.removeAllCachedResponses()
        
        // 清理自定義圖片快取
        ImageCacheManager.shared.clearCache()
        
        // 強制垃圾回收
        await Task.yield()
    }
    
    private func reduceAnimations() async {
        // 通知 PerformanceManager 減少動畫
        PerformanceManager.shared.shouldReduceAnimations = true
    }
    
    private func enableLazyLoading() async {
        // 啟用延遲載入
        PerformanceManager.shared.shouldUseLazyLoading = true
    }
    
    private func clearUnusedData() async {
        // 清理未使用的 SwiftData 物件
        await DataCleanupManager.shared.cleanupUnusedData()
        
        // 清理臨時文件
        await cleanupTemporaryFiles()
    }
    
    private func compressImages() async {
        // 壓縮記憶體中的圖片
        await ImageCompressionManager.shared.compressImagesInMemory()
    }
    
    private func cleanupTemporaryFiles() async {
        let tempDir = FileManager.default.temporaryDirectory
        
        do {
            let tempFiles = try FileManager.default.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: [.creationDateKey])
            
            let cutoffDate = Date().addingTimeInterval(-3600) // 1小時前
            
            for file in tempFiles {
                let attributes = try FileManager.default.attributesOfItem(atPath: file.path)
                if let creationDate = attributes[.creationDate] as? Date,
                   creationDate < cutoffDate {
                    try FileManager.default.removeItem(at: file)
                }
            }
        } catch {
            logger.error("Failed to cleanup temporary files: \(error.localizedDescription)")
        }
    }
    
    private func handleMemoryWarning() async {
        logger.warning("Received memory warning")
        
        // 立即應用關鍵優化
        await applyOptimization(.imageCacheCleanup)
        await applyOptimization(.clearUnusedData)
        
        // 通知其他組件
        NotificationCenter.default.post(name: .memoryWarningReceived, object: nil)
    }
    
    // MARK: - 公共方法
    
    func forceCleanup() async {
        logger.info("Forcing memory cleanup")
        
        await cleanupImageCache()
        await clearUnusedData()
        await compressImages()
        
        // 強制垃圾回收
        await Task.yield()
    }
    
    func getMemoryReport() -> MemoryReport {
        return MemoryReport(
            currentUsage: memoryUsage,
            pressureLevel: memoryPressure,
            activeOptimizations: Array(activeOptimizations),
            recommendations: getMemoryRecommendations()
        )
    }
    
    private func getMemoryRecommendations() -> [String] {
        var recommendations: [String] = []
        
        switch memoryPressure {
        case .normal:
            recommendations.append("記憶體使用正常")
        case .warning:
            recommendations.append("記憶體使用較高，建議關閉不必要的功能")
            recommendations.append("考慮清理圖片快取")
        case .critical:
            recommendations.append("記憶體使用過高，建議重啟應用")
            recommendations.append("關閉所有非必要功能")
        }
        
        return recommendations
    }
    
    private func cleanup() {
        monitoringTimer?.invalidate()
        monitoringTimer = nil
        
        if let observer = memoryWarningObserver {
            NotificationCenter.default.removeObserver(observer)
            memoryWarningObserver = nil
        }
    }
}

// MARK: - 支援類型

enum MemoryPressureLevel: String, CaseIterable {
    case normal = "normal"
    case warning = "warning"
    case critical = "critical"
}

enum MemoryOptimization: String, CaseIterable, Hashable {
    case imageCacheCleanup = "image_cache_cleanup"
    case reduceAnimations = "reduce_animations"
    case lazyLoading = "lazy_loading"
    case clearUnusedData = "clear_unused_data"
    case compressImages = "compress_images"
}

struct MemoryUsage {
    let usedBytes: Double
    let totalBytes: Double
    let usagePercentage: Double
    let timestamp: Date
    
    init(usedBytes: Double = 0, totalBytes: Double = 0, usagePercentage: Double = 0, timestamp: Date = Date()) {
        self.usedBytes = usedBytes
        self.totalBytes = totalBytes
        self.usagePercentage = usagePercentage
        self.timestamp = timestamp
    }
    
    var usedMB: Double {
        return usedBytes / (1024 * 1024)
    }
    
    var totalMB: Double {
        return totalBytes / (1024 * 1024)
    }
    
    var formattedUsage: String {
        return String(format: "%.1f MB / %.1f MB (%.1f%%)", usedMB, totalMB, usagePercentage * 100)
    }
}

struct MemoryReport {
    let currentUsage: MemoryUsage
    let pressureLevel: MemoryPressureLevel
    let activeOptimizations: [MemoryOptimization]
    let recommendations: [String]
}

// MARK: - 通知擴展

extension Notification.Name {
    static let memoryWarningReceived = Notification.Name("memoryWarningReceived")
}
