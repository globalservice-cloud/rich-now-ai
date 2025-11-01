//
//  APIUsageTracker.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import Foundation
import SwiftData
import Combine

@MainActor
class APIUsageTracker: ObservableObject {
    static let shared = APIUsageTracker()
    
    @Published var dailyUsage: APIUsageStats?
    @Published var monthlyUsage: APIUsageStats?
    @Published var isNearLimit: Bool = false
    @Published var limitWarning: String?
    @Published var currentQuota: APIQuotaLimit?
    @Published var nativeAIUsage: NativeAIUsageStats?
    @Published var hybridUsage: HybridUsageStats?
    
    private var modelContext: ModelContext?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupQuotaLimits()
    }
    
    // MARK: - 設定管理
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadUsageStats()
    }
    
    // MARK: - 用量記錄
    
    func recordUsage(
        service: String,
        requestCount: Int = 1,
        tokenCount: Int,
        cost: Double,
        userProvidedKey: Bool = false
    ) {
        guard let context = modelContext else { return }
        
        let usage = APIUsage(
            date: Date(),
            service: service,
            requestCount: requestCount,
            tokenCount: tokenCount,
            cost: cost,
            userProvidedKey: userProvidedKey
        )
        
        context.insert(usage)
        
        do {
            try context.save()
            updateUsageStats()
            checkQuotaLimits()
        } catch {
            print("Failed to save API usage: \(error)")
        }
    }
    
    // MARK: - 用量統計
    
    func loadUsageStats() {
        guard let context = modelContext else { return }
        
        // 載入今日用量
        loadDailyUsage(context: context)
        
        // 載入本月用量
        loadMonthlyUsage(context: context)
        
        // 檢查配額限制
        checkQuotaLimits()
    }
    
    private func loadDailyUsage(context: ModelContext) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        do {
            let descriptor = FetchDescriptor<APIUsage>(
                predicate: #Predicate<APIUsage> { usage in
                    usage.date >= today && usage.date < tomorrow
                }
            )
            let usages = try context.fetch(descriptor)
            
            let stats = calculateStats(from: usages, period: "daily", startDate: today, endDate: tomorrow)
            self.dailyUsage = stats
        } catch {
            print("Failed to load daily usage: \(error)")
        }
    }
    
    private func loadMonthlyUsage(context: ModelContext) {
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: Date())?.start ?? Date()
        let endOfMonth = calendar.dateInterval(of: .month, for: Date())?.end ?? Date()
        
        do {
            let descriptor = FetchDescriptor<APIUsage>(
                predicate: #Predicate<APIUsage> { usage in
                    usage.date >= startOfMonth && usage.date < endOfMonth
                }
            )
            let usages = try context.fetch(descriptor)
            
            let stats = calculateStats(from: usages, period: "monthly", startDate: startOfMonth, endDate: endOfMonth)
            self.monthlyUsage = stats
        } catch {
            print("Failed to load monthly usage: \(error)")
        }
    }
    
    private func calculateStats(from usages: [APIUsage], period: String, startDate: Date, endDate: Date) -> APIUsageStats {
        let totalRequests = usages.reduce(0) { $0 + $1.requestCount }
        let totalTokens = usages.reduce(0) { $0 + $1.tokenCount }
        let totalCost = usages.reduce(0.0) { $0 + $1.cost }
        let userProvidedKeyUsage = usages.filter { $0.userProvidedKey }.reduce(0.0) { $0 + $1.cost }
        let userProvidedKeyRatio = totalCost > 0 ? userProvidedKeyUsage / totalCost : 0.0
        
        return APIUsageStats(
            period: period,
            startDate: startDate,
            endDate: endDate,
            totalRequests: totalRequests,
            totalTokens: totalTokens,
            totalCost: totalCost,
            userProvidedKeyUsage: userProvidedKeyRatio
        )
    }
    
    // MARK: - 配額管理
    
    private func setupQuotaLimits() {
        // 根據訂閱方案設定配額限制
        let freeQuota = APIQuotaLimit(
            subscriptionTier: "free",
            dailyRequestLimit: 50,  // 增加到50次
            monthlyRequestLimit: 500,  // 增加到500次
            dailyTokenLimit: 50000,  // 增加到50,000個
            monthlyTokenLimit: 500000,  // 增加到500,000個
            dailyCostLimit: 5.0,  // 增加到$5.0
            monthlyCostLimit: 50.0  // 增加到$50.0
        )
        
        let basicQuota = APIQuotaLimit(
            subscriptionTier: "basic",
            dailyRequestLimit: 50,
            monthlyRequestLimit: 1000,
            dailyTokenLimit: 50000,
            monthlyTokenLimit: 1000000,
            dailyCostLimit: 5.0,
            monthlyCostLimit: 50.0
        )
        
        let premiumQuota = APIQuotaLimit(
            subscriptionTier: "premium",
            dailyRequestLimit: 200,
            monthlyRequestLimit: 5000,
            dailyTokenLimit: 200000,
            monthlyTokenLimit: 5000000,
            dailyCostLimit: 20.0,
            monthlyCostLimit: 200.0
        )
        
        let proQuota = APIQuotaLimit(
            subscriptionTier: "pro",
            dailyRequestLimit: 1000,
            monthlyRequestLimit: 25000,
            dailyTokenLimit: 1000000,
            monthlyTokenLimit: 25000000,
            dailyCostLimit: 100.0,
            monthlyCostLimit: 1000.0
        )
        
        // 保存配額限制到 SwiftData
        if let context = modelContext {
            context.insert(freeQuota)
            context.insert(basicQuota)
            context.insert(premiumQuota)
            context.insert(proQuota)
            
            do {
                try context.save()
            } catch {
                print("Failed to save quota limits: \(error)")
            }
        }
    }
    
    func updateQuotaForSubscription(_ subscriptionTier: String) {
        guard let context = modelContext else { return }
        
        do {
            let descriptor = FetchDescriptor<APIQuotaLimit>(
                predicate: #Predicate<APIQuotaLimit> { quota in
                    quota.subscriptionTier == subscriptionTier
                }
            )
            let quotas = try context.fetch(descriptor)
            self.currentQuota = quotas.first
        } catch {
            print("Failed to load quota for subscription: \(error)")
        }
    }
    
    // MARK: - 限制檢查
    
    private func checkQuotaLimits() {
        guard let quota = currentQuota else { 
            print("⚠️ No quota limit found for current subscription")
            return 
        }
        guard let dailyUsage = dailyUsage else { 
            print("⚠️ No daily usage data available")
            return 
        }
        
        // 調試信息
        print("🔍 API Usage Check:")
        print("   Subscription Tier: \(quota.subscriptionTier)")
        print("   Daily Requests: \(dailyUsage.totalRequests)/\(quota.dailyRequestLimit)")
        print("   Daily Tokens: \(dailyUsage.totalTokens)/\(quota.dailyTokenLimit)")
        print("   Daily Cost: $\(String(format: "%.2f", dailyUsage.totalCost))/$\(String(format: "%.2f", quota.dailyCostLimit))")
        
        var warnings: [String] = []
        
        // 檢查每日限制
        if dailyUsage.totalRequests >= quota.dailyRequestLimit {
            warnings.append("已達到每日請求限制")
        }
        
        if dailyUsage.totalTokens >= quota.dailyTokenLimit {
            warnings.append("已達到每日 Token 限制")
        }
        
        if dailyUsage.totalCost >= quota.dailyCostLimit {
            warnings.append("已達到每日成本限制")
        }
        
        // 檢查每月限制
        if let monthlyUsage = monthlyUsage {
            if monthlyUsage.totalRequests >= quota.monthlyRequestLimit {
                warnings.append("已達到每月請求限制")
            }
            
            if monthlyUsage.totalTokens >= quota.monthlyTokenLimit {
                warnings.append("已達到每月 Token 限制")
            }
            
            if monthlyUsage.totalCost >= quota.monthlyCostLimit {
                warnings.append("已達到每月成本限制")
            }
        }
        
        // 檢查是否接近限制
        let dailyRequestRatio = Double(dailyUsage.totalRequests) / Double(quota.dailyRequestLimit)
        let dailyTokenRatio = Double(dailyUsage.totalTokens) / Double(quota.dailyTokenLimit)
        let dailyCostRatio = dailyUsage.totalCost / quota.dailyCostLimit
        
        isNearLimit = dailyRequestRatio >= 0.8 || dailyTokenRatio >= 0.8 || dailyCostRatio >= 0.8
        
        if isNearLimit && warnings.isEmpty {
            warnings.append("用量接近限制，請注意")
        }
        
        limitWarning = warnings.isEmpty ? nil : warnings.joined(separator: "；")
    }
    
    // MARK: - 用量統計更新
    
    private func updateUsageStats() {
        guard let context = modelContext else { return }
        
        // 更新每日統計
        loadDailyUsage(context: context)
        
        // 更新每月統計
        loadMonthlyUsage(context: context)
    }
    
    // MARK: - 重置用量限制
    
    func resetUsageLimits() {
        guard modelContext != nil else { return }
        
        // 重置每日用量統計
        dailyUsage = nil
        
        // 重置每月用量統計
        monthlyUsage = nil
        
        // 清除限制警告
        isNearLimit = false
        limitWarning = nil
        
        // 重新載入用量統計
        loadUsageStats()
        
        print("API usage limits have been reset")
    }
    
    func forceResetQuota() {
        // 強制重置配額限制
        setupQuotaLimits()
        loadUsageStats()
    }
    
    // MARK: - 獲取用量報告
    
    func getUsageReport(period: APIUsagePeriod) -> String {
        let stats = period == .daily ? dailyUsage : monthlyUsage
        guard let usageStats = stats else { return "無用量數據" }
        
        let periodName = period.displayName
        let requestCount = usageStats.totalRequests
        let tokenCount = usageStats.totalTokens
        let cost = usageStats.totalCost
        let userProvidedKeyRatio = usageStats.userProvidedKeyUsage * 100
        
        return """
        📊 \(periodName) API 用量報告
        
        🔢 請求次數: \(requestCount)
        🎯 Token 使用: \(tokenCount)
        💰 總成本: $\(String(format: "%.2f", cost))
        🔑 自備 Key 使用: \(String(format: "%.1f", userProvidedKeyRatio))%
        
        📈 使用趨勢: \(getUsageTrend(period: period))
        ⚠️ 限制狀態: \(isNearLimit ? "接近限制" : "正常")
        """
    }
    
    private func getUsageTrend(period: APIUsagePeriod) -> String {
        // 簡化的趨勢分析
        guard let stats = period == .daily ? dailyUsage : monthlyUsage else { return "無數據" }
        
        if stats.totalRequests == 0 {
            return "無使用"
        } else if stats.totalRequests < 10 {
            return "輕度使用"
        } else if stats.totalRequests < 50 {
            return "中度使用"
        } else {
            return "重度使用"
        }
    }
    
    // MARK: - 用量重置
    
    func resetMonthlyUsage() {
        monthlyUsage = nil
        // 重置相關的統計數據
        isNearLimit = false
        limitWarning = nil
    }
    
    // MARK: - 用量分析
    
    func getUsageAnalysis() -> [String: Any] {
        var analysis: [String: Any] = [:]
        
        if let daily = dailyUsage {
            analysis["daily"] = [
                "requests": daily.totalRequests,
                "tokens": daily.totalTokens,
                "cost": daily.totalCost,
                "userProvidedKeyRatio": daily.userProvidedKeyUsage
            ]
        }
        
        if let monthly = monthlyUsage {
            analysis["monthly"] = [
                "requests": monthly.totalRequests,
                "tokens": monthly.totalTokens,
                "cost": monthly.totalCost,
                "userProvidedKeyRatio": monthly.userProvidedKeyUsage
            ]
        }
        
        analysis["isNearLimit"] = isNearLimit
        analysis["limitWarning"] = limitWarning
        
        return analysis
    }
    
    // MARK: - 原生 AI 使用統計
    
    func recordNativeAIUsage(
        taskType: String,
        processingTime: Double,
        success: Bool,
        confidence: Double
    ) {
        guard let context = modelContext else { return }
        
        let usage = NativeAIUsage(
            date: Date(),
            taskType: taskType,
            processingTime: processingTime,
            success: success,
            confidence: confidence
        )
        
        context.insert(usage)
        
        do {
            try context.save()
            loadNativeAIUsageStats()
        } catch {
            print("Failed to save native AI usage: \(error)")
        }
    }
    
    func recordHybridUsage(
        taskType: String,
        nativeProcessingTime: Double,
        openAIProcessingTime: Double,
        nativeSuccess: Bool,
        openAISuccess: Bool,
        finalSource: String,
        costSavings: Double
    ) {
        guard let context = modelContext else { return }
        
        let usage = HybridUsage(
            date: Date(),
            taskType: taskType,
            nativeProcessingTime: nativeProcessingTime,
            openAIProcessingTime: openAIProcessingTime,
            nativeSuccess: nativeSuccess,
            openAISuccess: openAISuccess,
            finalSource: finalSource,
            costSavings: costSavings
        )
        
        context.insert(usage)
        
        do {
            try context.save()
            loadHybridUsageStats()
        } catch {
            print("Failed to save hybrid usage: \(error)")
        }
    }
    
    private func loadNativeAIUsageStats() {
        guard let context = modelContext else { return }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let predicate = #Predicate<NativeAIUsage> { usage in
            usage.date >= today
        }
        
        let descriptor = FetchDescriptor<NativeAIUsage>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        do {
            let usages = try context.fetch(descriptor)
            nativeAIUsage = calculateNativeAIStats(from: usages)
        } catch {
            print("Failed to load native AI usage stats: \(error)")
        }
    }
    
    private func loadHybridUsageStats() {
        guard let context = modelContext else { return }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let predicate = #Predicate<HybridUsage> { usage in
            usage.date >= today
        }
        
        let descriptor = FetchDescriptor<HybridUsage>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        do {
            let usages = try context.fetch(descriptor)
            hybridUsage = calculateHybridStats(from: usages)
        } catch {
            print("Failed to load hybrid usage stats: \(error)")
        }
    }
    
    private func calculateNativeAIStats(from usages: [NativeAIUsage]) -> NativeAIUsageStats {
        let totalTasks = usages.count
        let successfulTasks = usages.filter { $0.success }.count
        let successRate = totalTasks > 0 ? Double(successfulTasks) / Double(totalTasks) : 0.0
        
        let totalProcessingTime = usages.reduce(0) { $0 + $1.processingTime }
        let averageProcessingTime = totalTasks > 0 ? totalProcessingTime / Double(totalTasks) : 0.0
        
        let totalConfidence = usages.reduce(0) { $0 + $1.confidence }
        let averageConfidence = totalTasks > 0 ? totalConfidence / Double(totalTasks) : 0.0
        
        let taskTypeBreakdown = Dictionary(grouping: usages, by: { $0.taskType })
            .mapValues { $0.count }
        
        return NativeAIUsageStats(
            totalTasks: totalTasks,
            successfulTasks: successfulTasks,
            successRate: successRate,
            totalProcessingTime: totalProcessingTime,
            averageProcessingTime: averageProcessingTime,
            averageConfidence: averageConfidence,
            taskTypeBreakdown: taskTypeBreakdown
        )
    }
    
    private func calculateHybridStats(from usages: [HybridUsage]) -> HybridUsageStats {
        let totalTasks = usages.count
        let nativeSuccessful = usages.filter { $0.nativeSuccess }.count
        let openAISuccessful = usages.filter { $0.openAISuccess }.count
        let finalNativeUsed = usages.filter { $0.finalSource == "native" }.count
        
        let totalCostSavings = usages.reduce(0) { $0 + $1.costSavings }
        let averageCostSavings = totalTasks > 0 ? totalCostSavings / Double(totalTasks) : 0.0
        
        let totalNativeTime = usages.reduce(0) { $0 + $1.nativeProcessingTime }
        let totalOpenAITime = usages.reduce(0) { $0 + $1.openAIProcessingTime }
        
        return HybridUsageStats(
            totalTasks: totalTasks,
            nativeSuccessful: nativeSuccessful,
            openAISuccessful: openAISuccessful,
            finalNativeUsed: finalNativeUsed,
            totalCostSavings: totalCostSavings,
            averageCostSavings: averageCostSavings,
            totalNativeTime: totalNativeTime,
            totalOpenAITime: totalOpenAITime
        )
    }
}

// MARK: - 原生 AI 使用統計結構

struct NativeAIUsageStats {
    let totalTasks: Int
    let successfulTasks: Int
    let successRate: Double
    let totalProcessingTime: Double
    let averageProcessingTime: Double
    let averageConfidence: Double
    let taskTypeBreakdown: [String: Int]
}

struct HybridUsageStats {
    let totalTasks: Int
    let nativeSuccessful: Int
    let openAISuccessful: Int
    let finalNativeUsed: Int
    let totalCostSavings: Double
    let averageCostSavings: Double
    let totalNativeTime: Double
    let totalOpenAITime: Double
}

// MARK: - 原生 AI 使用記錄模型

@Model
class NativeAIUsage {
    var date: Date
    var taskType: String
    var processingTime: Double
    var success: Bool
    var confidence: Double
    
    init(date: Date, taskType: String, processingTime: Double, success: Bool, confidence: Double) {
        self.date = date
        self.taskType = taskType
        self.processingTime = processingTime
        self.success = success
        self.confidence = confidence
    }
}

@Model
class HybridUsage {
    var date: Date
    var taskType: String
    var nativeProcessingTime: Double
    var openAIProcessingTime: Double
    var nativeSuccess: Bool
    var openAISuccess: Bool
    var finalSource: String
    var costSavings: Double
    
    init(date: Date, taskType: String, nativeProcessingTime: Double, openAIProcessingTime: Double, nativeSuccess: Bool, openAISuccess: Bool, finalSource: String, costSavings: Double) {
        self.date = date
        self.taskType = taskType
        self.nativeProcessingTime = nativeProcessingTime
        self.openAIProcessingTime = openAIProcessingTime
        self.nativeSuccess = nativeSuccess
        self.openAISuccess = openAISuccess
        self.finalSource = finalSource
        self.costSavings = costSavings
    }
}