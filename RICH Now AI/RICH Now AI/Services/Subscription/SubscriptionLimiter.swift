//
//  SubscriptionLimiter.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import Foundation
import Combine

@MainActor
class SubscriptionLimiter: ObservableObject {
    static let shared = SubscriptionLimiter()
    
    @Published var usageStats: [SubscriptionFeature: Int] = [:]
    @Published var showUpgradePrompt = false
    @Published var upgradePromptMessage = ""
    
    private let storeKitManager = StoreKitManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupUsageTracking()
    }
    
    // MARK: - 功能使用檢查
    
    func canUseFeature(_ feature: SubscriptionFeature) -> Bool {
        return storeKitManager.canUseFeature(feature)
    }
    
    func getRemainingUsage(_ feature: SubscriptionFeature) -> Int {
        return storeKitManager.getRemainingUsage(feature)
    }
    
    func recordUsage(_ feature: SubscriptionFeature) {
        let currentUsage = usageStats[feature] ?? 0
        usageStats[feature] = currentUsage + 1
        
        // 檢查是否接近限制
        checkUsageLimits(feature)
    }
    
    func recordVoiceUsage(minutes: Int) {
        let currentUsage = usageStats[.voiceInput] ?? 0
        usageStats[.voiceInput] = currentUsage + minutes
        
        checkUsageLimits(.voiceInput)
    }
    
    func recordImageAnalysis() {
        recordUsage(.imageAnalysis)
    }
    
    func recordAIChat() {
        recordUsage(.aiChat)
    }
    
    // MARK: - 限制檢查
    
    private func checkUsageLimits(_ feature: SubscriptionFeature) {
        let remaining = getRemainingUsage(feature)
        let limits = storeKitManager.currentSubscription.limits
        
        // 檢查是否達到限制
        if !canUseFeature(feature) {
            showUpgradePrompt = true
            upgradePromptMessage = generateUpgradeMessage(feature)
            return
        }
        
        // 檢查是否接近限制（80% 使用率）
        if remaining > 0 {
            let totalLimit = getTotalLimit(feature, limits: limits)
            let usagePercentage = Double(usageStats[feature] ?? 0) / Double(totalLimit)
            
            if usagePercentage >= 0.8 {
                showUpgradePrompt = true
                upgradePromptMessage = generateWarningMessage(feature, remaining: remaining)
            }
        }
    }
    
    private func getTotalLimit(_ feature: SubscriptionFeature, limits: SubscriptionLimits) -> Int {
        switch feature {
        case .aiChat:
            return limits.aiChatMessages
        case .voiceInput:
            return limits.voiceMinutes
        case .imageAnalysis:
            return limits.imageAnalysis
        default:
            return 0
        }
    }
    
    // MARK: - 升級提示訊息
    
    private func generateUpgradeMessage(_ feature: SubscriptionFeature) -> String {
        let featureName = feature.displayName
        let currentPlan = storeKitManager.currentSubscription.displayName
        
        return LocalizationManager.shared.localizedString("subscription.limit.reached")
            .replacingOccurrences(of: "%@", with: featureName)
            .replacingOccurrences(of: "%1", with: currentPlan)
    }
    
    private func generateWarningMessage(_ feature: SubscriptionFeature, remaining: Int) -> String {
        let featureName = feature.displayName
        
        return LocalizationManager.shared.localizedString("subscription.limit.warning")
            .replacingOccurrences(of: "%@", with: featureName)
            .replacingOccurrences(of: "%1", with: "\(remaining)")
    }
    
    // MARK: - 使用量追蹤設置
    
    private func setupUsageTracking() {
        // 監聽訂閱狀態變化
        storeKitManager.$currentSubscription
            .sink { [weak self] _ in
                self?.resetUsageStats()
            }
            .store(in: &cancellables)
    }
    
    private func resetUsageStats() {
        // 每月重置使用統計
        usageStats.removeAll()
    }
    
    // MARK: - 功能限制檢查器
    
    func checkAIChatLimit() -> Bool {
        if canUseFeature(.aiChat) {
            recordAIChat()
            return true
        } else {
            showUpgradePrompt = true
            upgradePromptMessage = generateUpgradeMessage(.aiChat)
            return false
        }
    }
    
    func checkVoiceInputLimit() -> Bool {
        if canUseFeature(.voiceInput) {
            return true
        } else {
            showUpgradePrompt = true
            upgradePromptMessage = generateUpgradeMessage(.voiceInput)
            return false
        }
    }
    
    func checkImageAnalysisLimit() -> Bool {
        if canUseFeature(.imageAnalysis) {
            recordImageAnalysis()
            return true
        } else {
            showUpgradePrompt = true
            upgradePromptMessage = generateUpgradeMessage(.imageAnalysis)
            return false
        }
    }
    
    func checkAdvancedReportsLimit() -> Bool {
        if canUseFeature(.advancedReports) {
            return true
        } else {
            showUpgradePrompt = true
            upgradePromptMessage = generateUpgradeMessage(.advancedReports)
            return false
        }
    }
    
    func checkCustomThemesLimit() -> Bool {
        if canUseFeature(.customThemes) {
            return true
        } else {
            showUpgradePrompt = true
            upgradePromptMessage = generateUpgradeMessage(.customThemes)
            return false
        }
    }
    
    func checkPrioritySupportLimit() -> Bool {
        if canUseFeature(.prioritySupport) {
            return true
        } else {
            showUpgradePrompt = true
            upgradePromptMessage = generateUpgradeMessage(.prioritySupport)
            return false
        }
    }
    
    func checkAPIKeySupportLimit() -> Bool {
        if canUseFeature(.apiKeySupport) {
            return true
        } else {
            showUpgradePrompt = true
            upgradePromptMessage = generateUpgradeMessage(.apiKeySupport)
            return false
        }
    }
}

// MARK: - 使用統計管理器

class UsageStatsManager: ObservableObject {
    static let shared = UsageStatsManager()
    
    @Published var monthlyStats: MonthlyUsageStats = MonthlyUsageStats()
    
    private let limiter = SubscriptionLimiter.shared
    
    func recordFeatureUsage(_ feature: SubscriptionFeature, amount: Int = 1) {
        limiter.recordUsage(feature)
        updateMonthlyStats(feature, amount: amount)
    }
    
    func recordVoiceUsage(minutes: Int) {
        limiter.recordVoiceUsage(minutes: minutes)
        updateMonthlyStats(.voiceInput, amount: minutes)
    }
    
    private func updateMonthlyStats(_ feature: SubscriptionFeature, amount: Int) {
        switch feature {
        case .aiChat:
            monthlyStats.aiChatMessages += amount
        case .voiceInput:
            monthlyStats.voiceMinutes += amount
        case .imageAnalysis:
            monthlyStats.imageAnalysis += amount
        default:
            break
        }
    }
    
    func resetMonthlyStats() {
        monthlyStats = MonthlyUsageStats()
    }
}

// MARK: - 月度使用統計

struct MonthlyUsageStats: Codable {
    var aiChatMessages: Int = 0
    var voiceMinutes: Int = 0
    var imageAnalysis: Int = 0
    var advancedReports: Int = 0
    var customThemes: Int = 0
    var prioritySupport: Int = 0
    var apiKeySupport: Int = 0
    
    var totalUsage: Int {
        return aiChatMessages + voiceMinutes + imageAnalysis + advancedReports + customThemes + prioritySupport + apiKeySupport
    }
}
