//
//  ResourceMonitor.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/12/19.
//

import Foundation
import SwiftUI
import Combine
import os.log
import Network

/// 統一資源監控器 - 整合記憶體、CPU、網路、快取等所有資源監控
@MainActor
class ResourceMonitor: ObservableObject {
    static let shared = ResourceMonitor()
    
    @Published var systemHealth: SystemHealth = SystemHealth()
    @Published var resourceUsage: ResourceUsage = ResourceUsage()
    @Published var activeOptimizations: [Optimization] = []
    @Published var recommendations: [Recommendation] = []
    
    private let memoryOptimizer = MemoryOptimizer.shared
    private let performanceManager = PerformanceManager.shared
    private let imageCacheManager = ImageCacheManager.shared
    private let networkMonitor = NetworkMonitor.shared
    private var cancellables = Set<AnyCancellable>()
    private var monitoringTimer: Timer?
    private let logger = Logger(subsystem: "com.richnowai", category: "ResourceMonitor")
    
    private init() {
        setupMonitoring()
        observeComponents()
    }
    
    deinit {
        monitoringTimer?.invalidate()
    }
    
    // MARK: - 監控設置
    
    private func setupMonitoring() {
        // 每 3 秒更新一次資源使用情況
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.updateResourceMetrics()
            }
        }
        
        // 立即執行一次
        Task { @MainActor in
            await updateResourceMetrics()
        }
    }
    
    private func observeComponents() {
        // 觀察記憶體優化器
        memoryOptimizer.$memoryPressure
            .sink { [weak self] pressure in
                Task { @MainActor in
                    await self?.updateSystemHealth()
                }
            }
            .store(in: &cancellables)
        
        // 觀察性能管理器
        performanceManager.$memoryUsage
            .combineLatest(performanceManager.$cpuUsage)
            .sink { [weak self] _, _ in
                Task { @MainActor in
                    await self?.updateResourceMetrics()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - 資源指標更新
    
    private func updateResourceMetrics() async {
        // 更新記憶體使用
        await memoryOptimizer.updateMemoryUsage()
        let memoryUsage = memoryOptimizer.memoryUsage
        
        // 更新 CPU 使用（PerformanceManager 會自動更新）
        let cpuUsage = performanceManager.cpuUsage
        
        // 更新網路狀態
        let networkQuality = networkMonitor.getNetworkQuality().displayName
        
        // 更新快取統計
        let cacheStats = imageCacheManager.getCacheStats()
        
        // 獲取連接類型字符串
        let connectionTypeString: String?
        if let type = networkMonitor.connectionType {
            connectionTypeString = type == .wifi ? "WiFi" : (type == .cellular ? "Cellular" : "Other")
        } else {
            connectionTypeString = nil
        }
        
        // 更新資源使用情況
        resourceUsage = ResourceUsage(
            memory: MemoryMetrics(
                usedBytes: memoryUsage.usedBytes,
                totalBytes: memoryUsage.totalBytes,
                percentage: memoryUsage.usagePercentage,
                pressure: memoryOptimizer.memoryPressure
            ),
            cpu: CPUMetrics(
                percentage: cpuUsage,
                isLowPowerMode: performanceManager.isLowPowerMode
            ),
            network: NetworkMetrics(
                isConnected: networkMonitor.isConnected,
                quality: networkQuality,
                connectionType: connectionTypeString
            ),
            cache: CacheMetrics(
                memoryUsage: cacheStats.memoryUsagePercentage,
                diskSize: cacheStats.diskCacheSizeMB,
                itemCount: cacheStats.currentMemoryCount
            ),
            timestamp: Date()
        )
        
        // 更新系統健康狀態
        await updateSystemHealth()
        
        // 生成建議
        generateRecommendations()
    }
    
    private func updateSystemHealth() async {
        let memoryHealth: HealthStatus
        switch memoryOptimizer.memoryPressure {
        case .normal:
            memoryHealth = .good
        case .warning:
            memoryHealth = .warning
        case .critical:
            memoryHealth = .critical
        }
        
        let cpuHealth: HealthStatus
        if performanceManager.cpuUsage > 0.8 {
            cpuHealth = .critical
        } else if performanceManager.cpuUsage > 0.6 {
            cpuHealth = .warning
        } else {
            cpuHealth = .good
        }
        
        let networkHealth: HealthStatus
        if networkMonitor.isConnected {
            let quality = networkMonitor.getNetworkQuality()
            let qualityString = quality.displayName.lowercased()
            networkHealth = (qualityString == "excellent" || qualityString == "good") ? .good : .warning
        } else {
            networkHealth = .critical
        }
        
        systemHealth = SystemHealth(
            memory: memoryHealth,
            cpu: cpuHealth,
            network: networkHealth,
            overall: overallHealth(memory: memoryHealth, cpu: cpuHealth, network: networkHealth),
            timestamp: Date()
        )
        
        // 根據健康狀態應用優化
        await applyOptimizations()
    }
    
    private func overallHealth(memory: HealthStatus, cpu: HealthStatus, network: HealthStatus) -> HealthStatus {
        let statuses = [memory, cpu, network]
        if statuses.contains(.critical) {
            return .critical
        } else if statuses.contains(.warning) {
            return .warning
        } else {
            return .good
        }
    }
    
    // MARK: - 優化應用
    
    private func applyOptimizations() async {
        var newOptimizations: [Optimization] = []
        
        // 根據系統健康狀態應用優化
        switch systemHealth.memory {
        case .warning:
            if !activeOptimizations.contains(.reduceMemoryUsage) {
                ImageCacheManager.shared.clearCache()
                newOptimizations.append(.reduceMemoryUsage)
            }
        case .critical:
            await memoryOptimizer.forceCleanup()
            ImageCacheManager.shared.clearCache()
            newOptimizations.append(.reduceMemoryUsage)
            newOptimizations.append(.aggressiveCleanup)
        default:
            break
        }
        
        if systemHealth.cpu == .critical || systemHealth.cpu == .warning {
            if !performanceManager.shouldReduceAnimations {
                performanceManager.shouldReduceAnimations = true
                newOptimizations.append(.reduceAnimations)
            }
        }
        
        activeOptimizations = newOptimizations
    }
    
    // MARK: - 建議生成
    
    private func generateRecommendations() {
        var newRecommendations: [Recommendation] = []
        
        if resourceUsage.memory.percentage > 0.8 {
            newRecommendations.append(Recommendation(
                type: .memory,
                priority: .high,
                title: "記憶體使用率過高",
                message: "建議清理快取或關閉不必要的功能",
                action: { [weak self] in
                    Task { @MainActor in
                        await self?.memoryOptimizer.forceCleanup()
                    }
                }
            ))
        }
        
        if resourceUsage.cpu.percentage > 0.7 {
            newRecommendations.append(Recommendation(
                type: .performance,
                priority: .medium,
                title: "CPU 使用率較高",
                message: "已自動減少動畫效果以改善性能",
                action: nil
            ))
        }
        
        if !resourceUsage.network.isConnected {
            newRecommendations.append(Recommendation(
                type: .network,
                priority: .high,
                title: "網路連線已斷開",
                message: "部分功能可能無法使用，將使用離線模式",
                action: nil
            ))
        }
        
        if resourceUsage.cache.memoryUsage > 0.8 {
            newRecommendations.append(Recommendation(
                type: .cache,
                priority: .low,
                title: "圖片快取過多",
                message: "建議清理快取以釋放空間",
                action: { [weak self] in
                    self?.imageCacheManager.clearCache()
                }
            ))
        }
        
        recommendations = newRecommendations
    }
    
    // MARK: - 公共方法
    
    func getResourceReport() -> ResourceReport {
        return ResourceReport(
            health: systemHealth,
            usage: resourceUsage,
            activeOptimizations: activeOptimizations,
            recommendations: recommendations,
            generatedAt: Date()
        )
    }
    
    func forceOptimization() async {
        logger.info("Forcing resource optimization")
        await memoryOptimizer.forceCleanup()
        imageCacheManager.clearCache()
        await updateResourceMetrics()
    }
}

// MARK: - 支援類型

struct SystemHealth {
    var memory: HealthStatus = .good
    var cpu: HealthStatus = .good
    var network: HealthStatus = .good
    var overall: HealthStatus = .good
    var timestamp: Date = Date()
}

enum HealthStatus: String, CaseIterable {
    case good = "good"
    case warning = "warning"
    case critical = "critical"
    
    var displayName: String {
        switch self {
        case .good: return "良好"
        case .warning: return "警告"
        case .critical: return "嚴重"
        }
    }
    
    var color: Color {
        switch self {
        case .good: return .green
        case .warning: return .orange
        case .critical: return .red
        }
    }
}

struct ResourceUsage {
    var memory: MemoryMetrics = MemoryMetrics()
    var cpu: CPUMetrics = CPUMetrics()
    var network: NetworkMetrics = NetworkMetrics()
    var cache: CacheMetrics = CacheMetrics()
    var timestamp: Date = Date()
}

struct MemoryMetrics {
    var usedBytes: Double = 0
    var totalBytes: Double = 0
    var percentage: Double = 0
    var pressure: MemoryPressureLevel = .normal
}

struct CPUMetrics {
    var percentage: Double = 0
    var isLowPowerMode: Bool = false
}

struct NetworkMetrics {
    var isConnected: Bool = true
    var quality: String = "excellent"
    var connectionType: String? = nil
}

struct CacheMetrics {
    var memoryUsage: Double = 0
    var diskSize: Double = 0
    var itemCount: Int = 0
}

enum Optimization: String, CaseIterable {
    case reduceMemoryUsage = "reduce_memory_usage"
    case reduceAnimations = "reduce_animations"
    case aggressiveCleanup = "aggressive_cleanup"
    case enableLazyLoading = "enable_lazy_loading"
    
    var displayName: String {
        switch self {
        case .reduceMemoryUsage: return "減少記憶體使用"
        case .reduceAnimations: return "減少動畫"
        case .aggressiveCleanup: return "積極清理"
        case .enableLazyLoading: return "啟用延遲載入"
        }
    }
}

struct Recommendation: Identifiable {
    let id = UUID()
    let type: RecommendationType
    let priority: RecommendationPriority
    let title: String
    let message: String
    let action: (() -> Void)?
}

enum RecommendationType: String, CaseIterable {
    case memory = "memory"
    case performance = "performance"
    case network = "network"
    case cache = "cache"
    
    var icon: String {
        switch self {
        case .memory: return "memorychip"
        case .performance: return "speedometer"
        case .network: return "network"
        case .cache: return "externaldrive"
        }
    }
}

enum RecommendationPriority: String, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    
    var color: Color {
        switch self {
        case .low: return .blue
        case .medium: return .orange
        case .high: return .red
        }
    }
}

struct ResourceReport {
    let health: SystemHealth
    let usage: ResourceUsage
    let activeOptimizations: [Optimization]
    let recommendations: [Recommendation]
    let generatedAt: Date
}


