//
//  SubscriptionHistory.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import Foundation
import SwiftData

// 訂閱歷史記錄模型
@Model
class SubscriptionHistory {
    @Attribute(.unique) var id: UUID = UUID()
    var productId: String
    var plan: String
    var status: String
    var purchaseDate: Date
    var expiryDate: Date?
    var isTrial: Bool
    var isAutoRenew: Bool
    var originalTransactionId: String?
    var webOrderLineItemId: String?
    var price: Double
    var currency: String
    var storeCountry: String
    var environment: String // sandbox, production
    var createdAt: Date
    var updatedAt: Date
    
    init(
        productId: String,
        plan: String,
        status: String,
        purchaseDate: Date,
        expiryDate: Date? = nil,
        isTrial: Bool = false,
        isAutoRenew: Bool = false,
        originalTransactionId: String? = nil,
        webOrderLineItemId: String? = nil,
        price: Double,
        currency: String,
        storeCountry: String,
        environment: String
    ) {
        self.productId = productId
        self.plan = plan
        self.status = status
        self.purchaseDate = purchaseDate
        self.expiryDate = expiryDate
        self.isTrial = isTrial
        self.isAutoRenew = isAutoRenew
        self.originalTransactionId = originalTransactionId
        self.webOrderLineItemId = webOrderLineItemId
        self.price = price
        self.currency = currency
        self.storeCountry = storeCountry
        self.environment = environment
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// 訂閱分析數據模型
@Model
class SubscriptionAnalytics {
    @Attribute(.unique) var id: UUID = UUID()
    var totalRevenue: Double
    var totalTransactions: Int
    var averageRevenuePerUser: Double
    var churnRate: Double
    var retentionRate: Double
    var trialConversionRate: Double
    var mostPopularPlan: String
    var leastPopularPlan: String
    var monthlyActiveSubscribers: Int
    var yearlyActiveSubscribers: Int
    var createdAt: Date
    var updatedAt: Date
    
    init(
        totalRevenue: Double = 0,
        totalTransactions: Int = 0,
        averageRevenuePerUser: Double = 0,
        churnRate: Double = 0,
        retentionRate: Double = 0,
        trialConversionRate: Double = 0,
        mostPopularPlan: String = "",
        leastPopularPlan: String = "",
        monthlyActiveSubscribers: Int = 0,
        yearlyActiveSubscribers: Int = 0
    ) {
        self.totalRevenue = totalRevenue
        self.totalTransactions = totalTransactions
        self.averageRevenuePerUser = averageRevenuePerUser
        self.churnRate = churnRate
        self.retentionRate = retentionRate
        self.trialConversionRate = trialConversionRate
        self.mostPopularPlan = mostPopularPlan
        self.leastPopularPlan = leastPopularPlan
        self.monthlyActiveSubscribers = monthlyActiveSubscribers
        self.yearlyActiveSubscribers = yearlyActiveSubscribers
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// 訂閱升級/降級記錄
@Model
class SubscriptionChange {
    @Attribute(.unique) var id: UUID = UUID()
    var fromPlan: String
    var toPlan: String
    var changeType: String // upgrade, downgrade, cancel, renew
    var changeDate: Date
    var reason: String?
    var priceDifference: Double
    var proratedAmount: Double
    var effectiveDate: Date
    var createdAt: Date
    
    init(
        fromPlan: String,
        toPlan: String,
        changeType: String,
        changeDate: Date,
        reason: String? = nil,
        priceDifference: Double = 0,
        proratedAmount: Double = 0,
        effectiveDate: Date
    ) {
        self.fromPlan = fromPlan
        self.toPlan = toPlan
        self.changeType = changeType
        self.changeDate = changeDate
        self.reason = reason
        self.priceDifference = priceDifference
        self.proratedAmount = proratedAmount
        self.effectiveDate = effectiveDate
        self.createdAt = Date()
    }
}
