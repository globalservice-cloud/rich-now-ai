//
//  FamilyMember.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/12/19.
//

import Foundation
import SwiftData

/// 家庭成員模型
@Model
final class FamilyMember {
    @Attribute(.unique) var id: UUID = UUID()
    var name: String                    // 成員名稱
    var role: String                    // 角色（例如：父親、母親、子女）
    var age: Int?                       // 年齡
    var avatar: String?                 // 頭像（可選）
    var isActive: Bool                  // 是否啟用
    var canManageBudget: Bool           // 是否可以管理預算
    var canViewAllTransactions: Bool    // 是否可以查看所有交易
    var monthlyAllowance: Double?       // 每月零用錢（可選）
    var createdAt: Date
    var updatedAt: Date
    
    // 關聯
    @Relationship(deleteRule: .nullify) var familyGroup: FamilyGroup?
    @Relationship(deleteRule: .cascade) var transactions: [Transaction] = []
    
    init(
        name: String,
        role: String,
        age: Int? = nil,
        avatar: String? = nil,
        canManageBudget: Bool = false,
        canViewAllTransactions: Bool = true,
        monthlyAllowance: Double? = nil
    ) {
        self.name = name
        self.role = role
        self.age = age
        self.avatar = avatar
        self.isActive = true
        self.canManageBudget = canManageBudget
        self.canViewAllTransactions = canViewAllTransactions
        self.monthlyAllowance = monthlyAllowance
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

/// 家庭群組模型
@Model
final class FamilyGroup {
    @Attribute(.unique) var id: UUID = UUID()
    var name: String                    // 家庭名稱
    var createdBy: UUID                 // 創建者用戶 ID
    var totalMonthlyIncome: Double      // 家庭總月收入
    var totalMonthlyExpenses: Double    // 家庭總月支出
    var createdAt: Date
    var updatedAt: Date
    
    // 關聯
    @Relationship(deleteRule: .nullify) var owner: User?
    @Relationship(deleteRule: .cascade) var members: [FamilyMember] = []
    @Relationship(deleteRule: .cascade) var budgets: [FamilyBudget] = []
    @Relationship(deleteRule: .cascade) var transactions: [Transaction] = []
    
    init(name: String, createdBy: UUID) {
        self.name = name
        self.createdBy = createdBy
        self.totalMonthlyIncome = 0
        self.totalMonthlyExpenses = 0
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

/// 家庭預算模型
@Model
final class FamilyBudget {
    @Attribute(.unique) var id: UUID = UUID()
    var name: String                    // 預算名稱
    var category: String                // 預算分類
    var budgetedAmount: Double          // 預算金額
    var spentAmount: Double             // 已支出金額
    var period: String                  // 預算週期（monthly, weekly, yearly）
    var startDate: Date
    var endDate: Date
    var isActive: Bool
    var warningThreshold: Double        // 警告閾值（百分比）
    var createdAt: Date
    var updatedAt: Date
    
    // 關聯
    @Relationship(deleteRule: .nullify, inverse: \FamilyGroup.budgets) var familyGroup: FamilyGroup?
    @Relationship(deleteRule: .cascade) var transactions: [Transaction] = []
    
    init(
        name: String,
        category: String,
        budgetedAmount: Double,
        period: String,
        startDate: Date,
        endDate: Date,
        warningThreshold: Double = 0.8
    ) {
        self.name = name
        self.category = category
        self.budgetedAmount = budgetedAmount
        self.spentAmount = 0
        self.period = period
        self.startDate = startDate
        self.endDate = endDate
        self.isActive = true
        self.warningThreshold = warningThreshold
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // 計算剩餘預算
    var remainingAmount: Double {
        return max(0, budgetedAmount - spentAmount)
    }
    
    // 計算使用率
    var usageRate: Double {
        guard budgetedAmount > 0 else { return 0 }
        return min(1.0, spentAmount / budgetedAmount)
    }
    
    // 檢查是否超過警告閾值
    var isOverWarningThreshold: Bool {
        return usageRate >= warningThreshold
    }
    
    // 更新支出金額
    func updateSpending(_ amount: Double) {
        spentAmount += amount
        updatedAt = Date()
    }
}

/// 家庭記帳統計
struct FamilyAccountingStats {
    let totalIncome: Double
    let totalExpenses: Double
    let netIncome: Double
    let memberBreakdown: [MemberStats]
    let categoryBreakdown: [CategoryStats]
    let periodStart: Date
    let periodEnd: Date
}

struct MemberStats {
    let memberId: UUID
    let memberName: String
    let income: Double
    let expenses: Double
    let transactionCount: Int
}

struct CategoryStats {
    let category: String
    let amount: Double
    let percentage: Double
    let transactionCount: Int
}

