//
//  APIUsage.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import Foundation
import SwiftData

// API 用量記錄模型
@Model
class APIUsage {
    @Attribute(.unique) var id: UUID = UUID()
    var date: Date
    var service: String // "gpt-4o", "whisper", "vision"
    var requestCount: Int
    var tokenCount: Int
    var cost: Double
    var userProvidedKey: Bool
    var createdAt: Date
    
    init(
        date: Date,
        service: String,
        requestCount: Int,
        tokenCount: Int,
        cost: Double,
        userProvidedKey: Bool = false
    ) {
        self.date = date
        self.service = service
        self.requestCount = requestCount
        self.tokenCount = tokenCount
        self.cost = cost
        self.userProvidedKey = userProvidedKey
        self.createdAt = Date()
    }
}

// API 用量統計模型
@Model
class APIUsageStats {
    @Attribute(.unique) var id: UUID = UUID()
    var period: String // "daily", "weekly", "monthly"
    var startDate: Date
    var endDate: Date
    var totalRequests: Int
    var totalTokens: Int
    var totalCost: Double
    var userProvidedKeyUsage: Double // 使用自備 Key 的比例
    var createdAt: Date
    var updatedAt: Date
    
    init(
        period: String,
        startDate: Date,
        endDate: Date,
        totalRequests: Int = 0,
        totalTokens: Int = 0,
        totalCost: Double = 0.0,
        userProvidedKeyUsage: Double = 0.0
    ) {
        self.period = period
        self.startDate = startDate
        self.endDate = endDate
        self.totalRequests = totalRequests
        self.totalTokens = totalTokens
        self.totalCost = totalCost
        self.userProvidedKeyUsage = userProvidedKeyUsage
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// API 配額限制模型
@Model
class APIQuotaLimit {
    @Attribute(.unique) var id: UUID = UUID()
    var subscriptionTier: String
    var dailyRequestLimit: Int
    var monthlyRequestLimit: Int
    var dailyTokenLimit: Int
    var monthlyTokenLimit: Int
    var dailyCostLimit: Double
    var monthlyCostLimit: Double
    var createdAt: Date
    var updatedAt: Date
    
    init(
        subscriptionTier: String,
        dailyRequestLimit: Int,
        monthlyRequestLimit: Int,
        dailyTokenLimit: Int,
        monthlyTokenLimit: Int,
        dailyCostLimit: Double,
        monthlyCostLimit: Double
    ) {
        self.subscriptionTier = subscriptionTier
        self.dailyRequestLimit = dailyRequestLimit
        self.monthlyRequestLimit = monthlyRequestLimit
        self.dailyTokenLimit = dailyTokenLimit
        self.monthlyTokenLimit = monthlyTokenLimit
        self.dailyCostLimit = dailyCostLimit
        self.monthlyCostLimit = monthlyCostLimit
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// 用戶自備 API Key 模型
@Model
class UserAPIKey {
    @Attribute(.unique) var id: UUID = UUID()
    var service: String // "openai", "anthropic", "google"
    var keyName: String
    var keyValue: String // 加密存儲
    var isActive: Bool
    var usageCount: Int
    var totalCost: Double
    var createdAt: Date
    var updatedAt: Date
    var lastUsedAt: Date?
    
    init(
        service: String,
        keyName: String,
        keyValue: String,
        isActive: Bool = true,
        usageCount: Int = 0,
        totalCost: Double = 0.0
    ) {
        self.service = service
        self.keyName = keyName
        self.keyValue = keyValue
        self.isActive = isActive
        self.usageCount = usageCount
        self.totalCost = totalCost
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// API 服務枚舉
enum APIService: String, CaseIterable {
    case gpt4o = "gpt-4o"
    case whisper = "whisper"
    case vision = "vision"
    case claude = "claude"
    case gemini = "gemini"
    
    var displayName: String {
        switch self {
        case .gpt4o: return "GPT-4o"
        case .whisper: return "Whisper"
        case .vision: return "GPT-4 Vision"
        case .claude: return "Claude"
        case .gemini: return "Gemini"
        }
    }
    
    var icon: String {
        switch self {
        case .gpt4o: return "brain.head.profile"
        case .whisper: return "mic.fill"
        case .vision: return "eye.fill"
        case .claude: return "person.fill"
        case .gemini: return "sparkles"
        }
    }
}

// API 用量週期枚舉
enum APIUsagePeriod: String, CaseIterable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    case yearly = "yearly"
    
    var displayName: String {
        switch self {
        case .daily: return "每日"
        case .weekly: return "每週"
        case .monthly: return "每月"
        case .yearly: return "每年"
        }
    }
}
