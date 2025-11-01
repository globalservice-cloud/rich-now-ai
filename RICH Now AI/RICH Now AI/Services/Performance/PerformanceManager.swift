//
//  PerformanceManager.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/27.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class PerformanceManager: ObservableObject {
    static let shared = PerformanceManager()
    
    @Published var isLowPowerMode = false
    @Published var memoryUsage: Double = 0.0
    @Published var cpuUsage: Double = 0.0
    @Published var shouldReduceAnimations = false
    @Published var shouldUseLazyLoading = true
    
    private var timer: Timer?
    private let memoryWarningThreshold: Double = 0.8 // 80%
    private let cpuWarningThreshold: Double = 0.7 // 70%
    
    // 整合記憶體優化器
    private let memoryOptimizer = MemoryOptimizer.shared
    private let dataCleanupManager = DataCleanupManager.shared
    
    private init() {
        setupPerformanceMonitoring()
        checkLowPowerMode()
    }
    
    // MARK: - 性能監控
    
    private func setupPerformanceMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.updatePerformanceMetrics()
            }
        }
    }
    
    private func updatePerformanceMetrics() async {
        // 更新記憶體使用量
        memoryUsage = await getMemoryUsage()
        
        // 更新 CPU 使用量
        cpuUsage = await getCPUUsage()
        
        // 根據性能調整設定
        adjustPerformanceSettings()
        
        // 整合記憶體優化器
        await memoryOptimizer.updateMemoryUsage()
    }
    
    private func getMemoryUsage() async -> Double {
        // 使用 MemoryOptimizer 獲取真實的記憶體使用量
        await memoryOptimizer.updateMemoryUsage()
        let usage = memoryOptimizer.memoryUsage
        return usage.usagePercentage
    }
    
    private func getCPUUsage() async -> Double {
        // 改進的 CPU 使用量計算
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
            // 使用任務基本資訊來估算 CPU 使用
            // 這是一個簡化的實現，實際 CPU 監控需要更多複雜的計算
            // 返回一個基於記憶體使用的估算值
            let memoryFactor = await getMemoryUsage()
            return min(1.0, memoryFactor * 0.8) // CPU 通常與記憶體使用相關
        }
        
        return 0.2 // 默認值
    }
    
    private func adjustPerformanceSettings() {
        // 根據記憶體使用量調整設定
        if memoryUsage > memoryWarningThreshold {
            shouldReduceAnimations = true
            shouldUseLazyLoading = true
        } else if memoryUsage < memoryWarningThreshold * 0.6 {
            shouldReduceAnimations = false
        }
        
        // 根據 CPU 使用量調整設定
        if cpuUsage > cpuWarningThreshold {
            shouldReduceAnimations = true
        }
    }
    
    private func checkLowPowerMode() {
        isLowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled
        if isLowPowerMode {
            shouldReduceAnimations = true
            shouldUseLazyLoading = true
        }
    }
    
    // MARK: - 性能優化建議
    
    func getPerformanceRecommendations() -> [String] {
        var recommendations: [String] = []
        
        if memoryUsage > memoryWarningThreshold {
            recommendations.append("記憶體使用量較高，建議關閉不必要的功能")
        }
        
        if cpuUsage > cpuWarningThreshold {
            recommendations.append("CPU 使用量較高，建議減少動畫效果")
        }
        
        if isLowPowerMode {
            recommendations.append("低電量模式已啟用，已自動優化性能")
        }
        
        return recommendations
    }
    
    // MARK: - 動畫優化
    
    func getOptimizedAnimationDuration(_ baseDuration: Double) -> Double {
        if shouldReduceAnimations {
            return baseDuration * 0.5 // 減少動畫時間
        }
        return baseDuration
    }
    
    func getOptimizedAnimationDelay(_ baseDelay: Double) -> Double {
        if shouldReduceAnimations {
            return baseDelay * 0.3 // 減少動畫延遲
        }
        return baseDelay
    }
    
    // MARK: - 清理資源
    
    func cleanup() {
        timer?.invalidate()
        timer = nil
        
        // 整合記憶體優化器清理
        Task {
            await memoryOptimizer.forceCleanup()
        }
    }
    
    deinit {
        // 簡化清理，避免複雜的異步操作
        timer?.invalidate()
    }
}

// MARK: - 性能優化擴展

extension View {
    @ViewBuilder
    func performanceOptimized() -> some View {
        if PerformanceManager.shared.shouldUseLazyLoading {
            self.lazy()
        } else {
            self
        }
    }
    
    @ViewBuilder
    func conditionalAnimation<Value: Equatable>(
        _ value: Value,
        animation: Animation? = nil
    ) -> some View {
        if PerformanceManager.shared.shouldReduceAnimations {
            self
        } else {
            self.animation(animation, value: value)
        }
    }
}

// MARK: - 延遲載入擴展

extension View {
    @ViewBuilder
    func lazy() -> some View {
        LazyView { self }
    }
}
