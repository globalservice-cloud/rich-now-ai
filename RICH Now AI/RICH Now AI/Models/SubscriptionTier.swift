//
//  SubscriptionTier.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/27.
//

import Foundation
import Combine

// 訂閱層級枚舉
enum SubscriptionTier: String, CaseIterable, Codable {
    case free = "free"                    // 免費版
    case basic = "basic"                  // 基礎版
    case pro = "pro"                      // 專業版
    case enterprise = "enterprise"        // 企業版
    case byok = "byok"                    // 自備 API Key
    
    // 顯示名稱
    var displayName: String {
        switch self {
        case .free: return "免費版"
        case .basic: return "基礎版"
        case .pro: return "專業版"
        case .enterprise: return "企業版"
        case .byok: return "自備 API Key"
        }
    }
    
    // 英文名稱
    var englishName: String {
        switch self {
        case .free: return "Free"
        case .basic: return "Basic"
        case .pro: return "Pro"
        case .enterprise: return "Enterprise"
        case .byok: return "BYOK"
        }
    }
    
    // 價格資訊
    var pricing: PricingInfo {
        switch self {
        case .free:
            return PricingInfo(monthly: 0, yearly: 0, setupFee: 0)
        case .basic:
            return PricingInfo(monthly: 2.99, yearly: 29.99, setupFee: 0)
        case .pro:
            return PricingInfo(monthly: 9.99, yearly: 99.99, setupFee: 0)
        case .enterprise:
            return PricingInfo(monthly: 19.99, yearly: 199.99, setupFee: 0)
        case .byok:
            return PricingInfo(monthly: 0, yearly: 0, setupFee: 4.99)
        }
    }
    
    // 功能限制
    var limits: FeatureLimits {
        switch self {
        case .free:
            return FeatureLimits(
                aiChatsPerMonth: 0,
                imageAnalysisPerMonth: 0,
                hasAIConversation: false,
                hasSmartClassification: false,
                hasWhisperOptimization: false,
                hasVisionAnalysis: false,
                hasInvestmentAnalysis: false,
                hasTeamCollaboration: false,
                hasCustomAPI: false,
                hasAdvancedReports: false
            )
        case .basic:
            return FeatureLimits(
                aiChatsPerMonth: 100,
                imageAnalysisPerMonth: 50,
                hasAIConversation: true,
                hasSmartClassification: true,
                hasWhisperOptimization: true,
                hasVisionAnalysis: true,
                hasInvestmentAnalysis: true,
                hasTeamCollaboration: false,
                hasCustomAPI: false,
                hasAdvancedReports: false
            )
        case .pro:
            return FeatureLimits(
                aiChatsPerMonth: 1000,
                imageAnalysisPerMonth: -1, // 無限制
                hasAIConversation: true,
                hasSmartClassification: true,
                hasWhisperOptimization: true,
                hasVisionAnalysis: true,
                hasInvestmentAnalysis: true,
                hasTeamCollaboration: false,
                hasCustomAPI: false,
                hasAdvancedReports: true
            )
        case .enterprise:
            return FeatureLimits(
                aiChatsPerMonth: -1, // 無限制
                imageAnalysisPerMonth: -1, // 無限制
                hasAIConversation: true,
                hasSmartClassification: true,
                hasWhisperOptimization: true,
                hasVisionAnalysis: true,
                hasInvestmentAnalysis: true,
                hasTeamCollaboration: true,
                hasCustomAPI: true,
                hasAdvancedReports: true
            )
        case .byok:
            return FeatureLimits(
                aiChatsPerMonth: -1, // 無限制（使用用戶自己的配額）
                imageAnalysisPerMonth: -1, // 無限制
                hasAIConversation: true,
                hasSmartClassification: true,
                hasWhisperOptimization: true,
                hasVisionAnalysis: true,
                hasInvestmentAnalysis: true,
                hasTeamCollaboration: false,
                hasCustomAPI: false,
                hasAdvancedReports: false
            )
        }
    }
    
    // 圖示
    var icon: String {
        switch self {
        case .free: return "🆓"
        case .basic: return "⭐"
        case .pro: return "💎"
        case .enterprise: return "🏢"
        case .byok: return "🔑"
        }
    }
    
    // 顏色
    var color: String {
        switch self {
        case .free: return "#8B5CF6"
        case .basic: return "#3B82F6"
        case .pro: return "#F59E0B"
        case .enterprise: return "#10B981"
        case .byok: return "#EF4444"
        }
    }
    
    // 描述
    var description: String {
        switch self {
        case .free:
            return "使用 Apple 原生技術的基本記帳功能"
        case .basic:
            return "AI 財務顧問 + 智能分類，每月 100 次對話"
        case .pro:
            return "完整 AI 功能 + 高級投資分析，每月 1000 次對話"
        case .enterprise:
            return "無限制 AI 功能 + 團隊協作 + 自定義整合"
        case .byok:
            return "使用您自己的 OpenAI API Key，無限制使用"
        }
    }
}

// 價格資訊結構
struct PricingInfo: Codable {
    let monthly: Double
    let yearly: Double
    let setupFee: Double
    
    // 年付折扣百分比
    var yearlyDiscount: Double {
        guard monthly > 0 else { return 0 }
        let monthlyYearly = monthly * 12
        return ((monthlyYearly - yearly) / monthlyYearly) * 100
    }
}

// 功能限制結構
struct FeatureLimits: Codable {
    let aiChatsPerMonth: Int        // -1 表示無限制
    let imageAnalysisPerMonth: Int  // -1 表示無限制
    let hasAIConversation: Bool
    let hasSmartClassification: Bool
    let hasWhisperOptimization: Bool
    let hasVisionAnalysis: Bool
    let hasInvestmentAnalysis: Bool
    let hasTeamCollaboration: Bool
    let hasCustomAPI: Bool
    let hasAdvancedReports: Bool
    
    // 檢查是否有 AI 對話功能
    var canUseAIChat: Bool {
        return hasAIConversation && aiChatsPerMonth != 0
    }
    
    // 檢查是否有圖片分析功能
    var canUseImageAnalysis: Bool {
        return hasVisionAnalysis && imageAnalysisPerMonth != 0
    }
    
    // 檢查是否無限制
    var isUnlimited: Bool {
        return aiChatsPerMonth == -1 && imageAnalysisPerMonth == -1
    }
}

// 用戶訂閱狀態
class UserSubscriptionManager: ObservableObject {
    static let shared = UserSubscriptionManager()
    
    @Published var currentTier: SubscriptionTier = .free
    @Published var hasAPIKey: Bool = false
    @Published var monthlyUsage: MonthlyUsage = MonthlyUsage()
    
    private init() {
        loadSubscriptionStatus()
    }
    
    // 載入訂閱狀態
    private func loadSubscriptionStatus() {
        // 從 UserDefaults 載入
        if let tierString = UserDefaults.standard.string(forKey: "subscription_tier"),
           let tier = SubscriptionTier(rawValue: tierString) {
            currentTier = tier
        }
        
        // 檢查是否有 API Key
        hasAPIKey = APIKeyManager.shared.getAPIKey(for: "openai") != nil
        
        // 如果用戶有 API Key，自動設為 BYOK
        if hasAPIKey && currentTier == .free {
            currentTier = .byok
        }
    }
    
    // 更新訂閱層級
    func updateTier(_ tier: SubscriptionTier) {
        currentTier = tier
        UserDefaults.standard.set(tier.rawValue, forKey: "subscription_tier")
    }
    
    // 檢查功能是否可用
    func canUseFeature(_ feature: FeatureType) -> Bool {
        let limits = currentTier.limits
        
        switch feature {
        case .aiConversation:
            return limits.canUseAIChat
        case .imageAnalysis:
            return limits.canUseImageAnalysis
        case .smartClassification:
            return limits.hasSmartClassification
        case .whisperOptimization:
            return limits.hasWhisperOptimization
        case .investmentAnalysis:
            return limits.hasInvestmentAnalysis
        case .teamCollaboration:
            return limits.hasTeamCollaboration
        case .customAPI:
            return limits.hasCustomAPI
        case .advancedReports:
            return limits.hasAdvancedReports
        }
    }
    
    // 檢查使用量是否超限
    func isWithinLimits(for feature: FeatureType) -> Bool {
        let limits = currentTier.limits
        
        switch feature {
        case .aiConversation:
            if limits.aiChatsPerMonth == -1 { return true }
            return monthlyUsage.aiChats < limits.aiChatsPerMonth
        case .imageAnalysis:
            if limits.imageAnalysisPerMonth == -1 { return true }
            return monthlyUsage.imageAnalysis < limits.imageAnalysisPerMonth
        default:
            return canUseFeature(feature)
        }
    }
    
    // 增加使用量
    func incrementUsage(for feature: FeatureType) {
        switch feature {
        case .aiConversation:
            monthlyUsage.aiChats += 1
        case .imageAnalysis:
            monthlyUsage.imageAnalysis += 1
        default:
            break
        }
        
        // 保存使用量
        saveUsage()
    }
    
    // 保存使用量
    private func saveUsage() {
        if let data = try? JSONEncoder().encode(monthlyUsage) {
            UserDefaults.standard.set(data, forKey: "monthly_usage")
        }
    }
}

// 功能類型枚舉
enum FeatureType: String, CaseIterable {
    case aiConversation = "ai_conversation"
    case imageAnalysis = "image_analysis"
    case smartClassification = "smart_classification"
    case whisperOptimization = "whisper_optimization"
    case investmentAnalysis = "investment_analysis"
    case teamCollaboration = "team_collaboration"
    case customAPI = "custom_api"
    case advancedReports = "advanced_reports"
    
    var displayName: String {
        switch self {
        case .aiConversation: return "AI 對話"
        case .imageAnalysis: return "圖片分析"
        case .smartClassification: return "智能分類"
        case .whisperOptimization: return "語音優化"
        case .investmentAnalysis: return "投資分析"
        case .teamCollaboration: return "團隊協作"
        case .customAPI: return "自定義 API"
        case .advancedReports: return "高級報表"
        }
    }
}

// 月度使用量
struct MonthlyUsage: Codable {
    var aiChats: Int = 0
    var imageAnalysis: Int = 0
    var lastResetDate: Date = Date()
    
    // 檢查是否需要重置（每月重置）
    var needsReset: Bool {
        let calendar = Calendar.current
        let now = Date()
        return !calendar.isDate(lastResetDate, equalTo: now, toGranularity: .month)
    }
    
    // 重置使用量
    mutating func resetIfNeeded() {
        if needsReset {
            aiChats = 0
            imageAnalysis = 0
            lastResetDate = Date()
        }
    }
}