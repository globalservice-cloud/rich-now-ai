//
//  SubscriptionAnalyticsService.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import Foundation
import SwiftData
import Combine

@MainActor
class SubscriptionAnalyticsService: ObservableObject {
    static let shared = SubscriptionAnalyticsService()
    
    @Published var analytics: SubscriptionAnalytics?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var modelContext: ModelContext?
    
    init() {
        // 初始化時載入分析數據
        loadAnalytics()
    }
    
    // MARK: - 分析數據管理
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadAnalytics()
    }
    
    func loadAnalytics() {
        guard let context = modelContext else { return }
        
        isLoading = true
        
        do {
            let descriptor = FetchDescriptor<SubscriptionAnalytics>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            let analyticsList = try context.fetch(descriptor)
            
            if let latestAnalytics = analyticsList.first {
                self.analytics = latestAnalytics
            } else {
                // 創建新的分析數據
                let newAnalytics = SubscriptionAnalytics()
                context.insert(newAnalytics)
                try context.save()
                self.analytics = newAnalytics
            }
            
            isLoading = false
        } catch {
            errorMessage = "Failed to load analytics: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    // MARK: - 訂閱歷史分析
    
    func analyzeSubscriptionHistory() async {
        guard let context = modelContext else { return }
        
        do {
            let descriptor = FetchDescriptor<SubscriptionHistory>(
                sortBy: [SortDescriptor(\.purchaseDate, order: .reverse)]
            )
            let history = try context.fetch(descriptor)
            
            let analysis = calculateAnalytics(from: history)
            
            if var currentAnalytics = analytics {
                updateAnalytics(&currentAnalytics, with: analysis)
                try context.save()
            } else {
                var newAnalytics = SubscriptionAnalytics()
                updateAnalytics(&newAnalytics, with: analysis)
                context.insert(newAnalytics)
                try context.save()
                self.analytics = newAnalytics
            }
        } catch {
            errorMessage = "Failed to analyze subscription history: \(error.localizedDescription)"
        }
    }
    
    private func calculateAnalytics(from history: [SubscriptionHistory]) -> SubscriptionAnalytics {
        let totalRevenue = history.reduce(0) { $0 + $1.price }
        let totalTransactions = history.count
        let averageRevenuePerUser = totalTransactions > 0 ? totalRevenue / Double(totalTransactions) : 0
        
        // 計算流失率
        let cancelledSubscriptions = history.filter { $0.status == "cancelled" }.count
        let churnRate = totalTransactions > 0 ? Double(cancelledSubscriptions) / Double(totalTransactions) : 0
        
        // 計算留存率
        let retentionRate = 1.0 - churnRate
        
        // 計算試用轉換率
        let trialSubscriptions = history.filter { $0.isTrial }.count
        let convertedTrials = history.filter { $0.isTrial && $0.status == "active" }.count
        let trialConversionRate = trialSubscriptions > 0 ? Double(convertedTrials) / Double(trialSubscriptions) : 0
        
        // 找出最受歡迎和最不受歡迎的方案
        let planCounts = Dictionary(grouping: history, by: { $0.plan })
            .mapValues { $0.count }
        let mostPopularPlan = planCounts.max(by: { $0.value < $1.value })?.key ?? ""
        let leastPopularPlan = planCounts.min(by: { $0.value < $1.value })?.key ?? ""
        
        // 計算活躍訂閱者
        let activeSubscriptions = history.filter { $0.status == "active" }
        let monthlyActiveSubscribers = activeSubscriptions.count
        let yearlyActiveSubscribers = activeSubscriptions.filter { 
            Calendar.current.dateInterval(of: .year, for: $0.purchaseDate)?.contains(Date()) ?? false 
        }.count
        
        return SubscriptionAnalytics(
            totalRevenue: totalRevenue,
            totalTransactions: totalTransactions,
            averageRevenuePerUser: averageRevenuePerUser,
            churnRate: churnRate,
            retentionRate: retentionRate,
            trialConversionRate: trialConversionRate,
            mostPopularPlan: mostPopularPlan,
            leastPopularPlan: leastPopularPlan,
            monthlyActiveSubscribers: monthlyActiveSubscribers,
            yearlyActiveSubscribers: yearlyActiveSubscribers
        )
    }
    
    private func updateAnalytics(_ analytics: inout SubscriptionAnalytics, with analysis: SubscriptionAnalytics) {
        analytics.totalRevenue = analysis.totalRevenue
        analytics.totalTransactions = analysis.totalTransactions
        analytics.averageRevenuePerUser = analysis.averageRevenuePerUser
        analytics.churnRate = analysis.churnRate
        analytics.retentionRate = analysis.retentionRate
        analytics.trialConversionRate = analysis.trialConversionRate
        analytics.mostPopularPlan = analysis.mostPopularPlan
        analytics.leastPopularPlan = analysis.leastPopularPlan
        analytics.monthlyActiveSubscribers = analysis.monthlyActiveSubscribers
        analytics.yearlyActiveSubscribers = analysis.yearlyActiveSubscribers
        analytics.updatedAt = Date()
    }
    
    // MARK: - 訂閱升級/降級
    
    func upgradeSubscription(from currentPlan: String, to newPlan: String, reason: String? = nil) async -> Bool {
        guard let context = modelContext else { return false }
        
        do {
            let change = SubscriptionChange(
                fromPlan: currentPlan,
                toPlan: newPlan,
                changeType: "upgrade",
                changeDate: Date(),
                reason: reason,
                priceDifference: calculatePriceDifference(from: currentPlan, to: newPlan),
                proratedAmount: calculateProratedAmount(from: currentPlan, to: newPlan),
                effectiveDate: Date()
            )
            
            context.insert(change)
            try context.save()
            
            // 更新分析數據
            await analyzeSubscriptionHistory()
            
            return true
        } catch {
            errorMessage = "Failed to upgrade subscription: \(error.localizedDescription)"
            return false
        }
    }
    
    func downgradeSubscription(from currentPlan: String, to newPlan: String, reason: String? = nil) async -> Bool {
        guard let context = modelContext else { return false }
        
        do {
            let change = SubscriptionChange(
                fromPlan: currentPlan,
                toPlan: newPlan,
                changeType: "downgrade",
                changeDate: Date(),
                reason: reason,
                priceDifference: calculatePriceDifference(from: currentPlan, to: newPlan),
                proratedAmount: calculateProratedAmount(from: currentPlan, to: newPlan),
                effectiveDate: Date()
            )
            
            context.insert(change)
            try context.save()
            
            // 更新分析數據
            await analyzeSubscriptionHistory()
            
            return true
        } catch {
            errorMessage = "Failed to downgrade subscription: \(error.localizedDescription)"
            return false
        }
    }
    
    private func calculatePriceDifference(from currentPlan: String, to newPlan: String) -> Double {
        let currentPrice = getPlanPrice(currentPlan)
        let newPrice = getPlanPrice(newPlan)
        return newPrice - currentPrice
    }
    
    private func calculateProratedAmount(from currentPlan: String, to newPlan: String) -> Double {
        // 簡化計算，實際應用中需要考慮剩餘時間
        return calculatePriceDifference(from: currentPlan, to: newPlan) * 0.5
    }
    
    private func getPlanPrice(_ plan: String) -> Double {
        switch plan {
        case "free": return 0
        case "basic": return 4.99
        case "premium": return 9.99
        case "pro": return 19.99
        default: return 0
        }
    }
    
    // MARK: - 獲取分析報告
    
    func getAnalyticsReport() -> String {
        guard let analytics = analytics else { return "No analytics data available" }
        
        return """
        📊 訂閱分析報告
        
        💰 總收入: $\(String(format: "%.2f", analytics.totalRevenue))
        📈 總交易數: \(analytics.totalTransactions)
        💵 平均每用戶收入: $\(String(format: "%.2f", analytics.averageRevenuePerUser))
        
        📉 流失率: \(String(format: "%.1f", analytics.churnRate * 100))%
        📈 留存率: \(String(format: "%.1f", analytics.retentionRate * 100))%
        🎯 試用轉換率: \(String(format: "%.1f", analytics.trialConversionRate * 100))%
        
        🏆 最受歡迎方案: \(analytics.mostPopularPlan)
        📉 最不受歡迎方案: \(analytics.leastPopularPlan)
        
        👥 月活躍訂閱者: \(analytics.monthlyActiveSubscribers)
        👥 年活躍訂閱者: \(analytics.yearlyActiveSubscribers)
        """
    }
}
