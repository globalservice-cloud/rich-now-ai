//
//  SubscriptionPlan.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import Foundation
import StoreKit

// 訂閱方案枚舉
enum SubscriptionPlan: String, CaseIterable, Codable {
    case free = "free"                    // 免費方案
    case basic = "com.richnowai.basic"    // 基礎方案
    case premium = "com.richnowai.premium" // 進階方案
    case pro = "com.richnowai.pro"        // 專業方案
    
    var displayName: String {
        switch self {
        case .free:
            return LocalizationManager.shared.localizedString("subscription.free.name")
        case .basic:
            return LocalizationManager.shared.localizedString("subscription.basic.name")
        case .premium:
            return LocalizationManager.shared.localizedString("subscription.premium.name")
        case .pro:
            return LocalizationManager.shared.localizedString("subscription.pro.name")
        }
    }
    
    var description: String {
        switch self {
        case .free:
            return LocalizationManager.shared.localizedString("subscription.free.description")
        case .basic:
            return LocalizationManager.shared.localizedString("subscription.basic.description")
        case .premium:
            return LocalizationManager.shared.localizedString("subscription.premium.description")
        case .pro:
            return LocalizationManager.shared.localizedString("subscription.pro.description")
        }
    }
    
    var price: String {
        switch self {
        case .free:
            return LocalizationManager.shared.localizedString("subscription.free.price")
        case .basic:
            return "$4.99/month"
        case .premium:
            return "$9.99/month"
        case .pro:
            return "$19.99/month"
        }
    }
    
    var features: [String] {
        switch self {
        case .free:
            return [
                LocalizationManager.shared.localizedString("subscription.free.feature1"),
                LocalizationManager.shared.localizedString("subscription.free.feature2"),
                LocalizationManager.shared.localizedString("subscription.free.feature3")
            ]
        case .basic:
            return [
                LocalizationManager.shared.localizedString("subscription.basic.feature1"),
                LocalizationManager.shared.localizedString("subscription.basic.feature2"),
                LocalizationManager.shared.localizedString("subscription.basic.feature3"),
                LocalizationManager.shared.localizedString("subscription.basic.feature4")
            ]
        case .premium:
            return [
                LocalizationManager.shared.localizedString("subscription.premium.feature1"),
                LocalizationManager.shared.localizedString("subscription.premium.feature2"),
                LocalizationManager.shared.localizedString("subscription.premium.feature3"),
                LocalizationManager.shared.localizedString("subscription.premium.feature4"),
                LocalizationManager.shared.localizedString("subscription.premium.feature5")
            ]
        case .pro:
            return [
                LocalizationManager.shared.localizedString("subscription.pro.feature1"),
                LocalizationManager.shared.localizedString("subscription.pro.feature2"),
                LocalizationManager.shared.localizedString("subscription.pro.feature3"),
                LocalizationManager.shared.localizedString("subscription.pro.feature4"),
                LocalizationManager.shared.localizedString("subscription.pro.feature5"),
                LocalizationManager.shared.localizedString("subscription.pro.feature6")
            ]
        }
    }
    
    var color: String {
        switch self {
        case .free:
            return "#8E8E93"
        case .basic:
            return "#007AFF"
        case .premium:
            return "#FF9500"
        case .pro:
            return "#FF3B30"
        }
    }
    
    var icon: String {
        switch self {
        case .free:
            return "star"
        case .basic:
            return "star.fill"
        case .premium:
            return "crown.fill"
        case .pro:
            return "diamond.fill"
        }
    }
    
    // 功能限制
    var limits: SubscriptionLimits {
        switch self {
        case .free:
            return SubscriptionLimits(
                monthlyTransactions: 50,
                aiChatMessages: 20,
                voiceMinutes: 0,
                imageAnalysis: 0,
                advancedReports: false,
                customThemes: false,
                prioritySupport: false,
                apiKeySupport: false
            )
        case .basic:
            return SubscriptionLimits(
                monthlyTransactions: 200,
                aiChatMessages: 100,
                voiceMinutes: 30,
                imageAnalysis: 10,
                advancedReports: false,
                customThemes: false,
                prioritySupport: false,
                apiKeySupport: false
            )
        case .premium:
            return SubscriptionLimits(
                monthlyTransactions: 1000,
                aiChatMessages: 500,
                voiceMinutes: 120,
                imageAnalysis: 50,
                advancedReports: true,
                customThemes: true,
                prioritySupport: false,
                apiKeySupport: false
            )
        case .pro:
            return SubscriptionLimits(
                monthlyTransactions: -1, // 無限制
                aiChatMessages: -1, // 無限制
                voiceMinutes: -1, // 無限制
                imageAnalysis: -1, // 無限制
                advancedReports: true,
                customThemes: true,
                prioritySupport: true,
                apiKeySupport: true
            )
        }
    }
}

// 訂閱限制結構
struct SubscriptionLimits {
    let monthlyTransactions: Int      // 每月交易數量限制 (-1 表示無限制)
    let aiChatMessages: Int           // AI 對話訊息限制
    let voiceMinutes: Int             // 語音記帳分鐘數限制
    let imageAnalysis: Int            // 圖片分析次數限制
    let advancedReports: Bool         // 進階報告功能
    let customThemes: Bool            // 自訂主題功能
    let prioritySupport: Bool         // 優先客服支援
    let apiKeySupport: Bool           // 自備 API Key 功能
}

// 訂閱狀態
enum SubscriptionStatus: String, Codable {
    case none = "none"                // 未訂閱
    case active = "active"            // 有效訂閱
    case expired = "expired"          // 已過期
    case cancelled = "cancelled"      // 已取消
    case pending = "pending"          // 待處理
    case gracePeriod = "grace_period" // 寬限期
}

// 訂閱產品資訊
struct SubscriptionProduct {
    let plan: SubscriptionPlan
    let product: Product
    let isPopular: Bool
    let discount: String?
    
    init(plan: SubscriptionPlan, product: Product, isPopular: Bool = false, discount: String? = nil) {
        self.plan = plan
        self.product = product
        self.isPopular = isPopular
        self.discount = discount
    }
}

// 訂閱交易記錄
struct SubscriptionTransaction {
    let id: String
    let plan: SubscriptionPlan
    let status: SubscriptionStatus
    let purchaseDate: Date
    let expiryDate: Date?
    let isTrial: Bool
    let isAutoRenew: Bool
    let originalTransactionId: String?
    let webOrderLineItemId: String?
}
