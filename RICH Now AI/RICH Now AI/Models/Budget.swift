//
//  Budget.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import Foundation
import SwiftData

// 預算項目
struct BudgetItem: Codable {
    let category: String
    let budgetedAmount: Double
    let spentAmount: Double
    let remainingAmount: Double
    let percentage: Double // 已使用百分比
}

// 預算類型
enum BudgetType: String, Codable, CaseIterable {
    case monthly = "monthly"
    case yearly = "yearly"
    case weekly = "weekly"
    case custom = "custom"
}

// 預算狀態
enum BudgetStatus: String, Codable {
    case active = "active"
    case completed = "completed"
    case paused = "paused"
    case cancelled = "cancelled"
}

@Model
final class Budget {
    // 基本資訊
    var name: String
    var type: String // BudgetType.rawValue
    var status: String // BudgetStatus.rawValue
    
    // 時間範圍
    var startDate: Date
    var endDate: Date
    
    // 預算項目
    var budgetItems: Data // [BudgetItem] 的 JSON 格式
    
    // 總預算
    var totalBudget: Double
    var totalSpent: Double
    var totalRemaining: Double
    
    // 預算執行率
    var executionRate: Double // 0-1 的執行率
    
    // 警告設定
    var warningThreshold: Double // 警告閾值（百分比）
    var isWarningEnabled: Bool
    
    // 自動調整
    var autoAdjust: Bool // 是否自動調整預算
    var rolloverUnused: Bool // 未使用預算是否滾入下期
    
    // 時間戳記
    var createdAt: Date
    var updatedAt: Date
    var lastCalculatedAt: Date
    
    // 關聯
    @Relationship(deleteRule: .nullify, inverse: \User.budgets) var user: User?
    
    init(name: String, type: BudgetType, startDate: Date, endDate: Date, totalBudget: Double) {
        self.name = name
        self.type = type.rawValue
        self.status = BudgetStatus.active.rawValue
        self.startDate = startDate
        self.endDate = endDate
        self.budgetItems = Data()
        self.totalBudget = totalBudget
        self.totalSpent = 0
        self.totalRemaining = totalBudget
        self.executionRate = 0
        self.warningThreshold = 0.8 // 80% 警告
        self.isWarningEnabled = true
        self.autoAdjust = false
        self.rolloverUnused = false
        self.createdAt = Date()
        self.updatedAt = Date()
        self.lastCalculatedAt = Date()
    }
    
    // 添加預算項目
    func addBudgetItem(category: String, budgetedAmount: Double) {
        var items = getBudgetItems()
        let newItem = BudgetItem(
            category: category,
            budgetedAmount: budgetedAmount,
            spentAmount: 0,
            remainingAmount: budgetedAmount,
            percentage: 0
        )
        items.append(newItem)
        self.budgetItems = (try? JSONEncoder().encode(items)) ?? Data()
        self.updatedAt = Date()
    }
    
    // 更新支出
    func updateSpending(category: String, amount: Double) {
        var items = getBudgetItems()
        if let index = items.firstIndex(where: { $0.category == category }) {
            items[index] = BudgetItem(
                category: items[index].category,
                budgetedAmount: items[index].budgetedAmount,
                spentAmount: items[index].spentAmount + amount,
                remainingAmount: items[index].budgetedAmount - (items[index].spentAmount + amount),
                percentage: (items[index].spentAmount + amount) / items[index].budgetedAmount
            )
            self.budgetItems = (try? JSONEncoder().encode(items)) ?? Data()
            self.updatedAt = Date()
            self.lastCalculatedAt = Date()
        }
    }
    
    // 獲取預算項目
    func getBudgetItems() -> [BudgetItem] {
        do {
            return try JSONDecoder().decode([BudgetItem].self, from: budgetItems)
        } catch {
            return []
        }
    }
    
    // 計算總支出
    func calculateTotalSpent() -> Double {
        let items = getBudgetItems()
        return items.reduce(0) { $0 + $1.spentAmount }
    }
    
    // 計算總剩餘
    func calculateTotalRemaining() -> Double {
        return totalBudget - totalSpent
    }
    
    // 計算執行率
    func calculateExecutionRate() -> Double {
        guard totalBudget > 0 else { return 0 }
        return totalSpent / totalBudget
    }
    
    // 更新預算統計
    func updateBudgetStatistics() {
        self.totalSpent = calculateTotalSpent()
        self.totalRemaining = calculateTotalRemaining()
        self.executionRate = calculateExecutionRate()
        self.lastCalculatedAt = Date()
        self.updatedAt = Date()
    }
    
    // 檢查是否超支
    func isOverBudget() -> Bool {
        return totalSpent > totalBudget
    }
    
    // 檢查是否需要警告
    func shouldWarn() -> Bool {
        return isWarningEnabled && executionRate >= warningThreshold
    }
    
    // 獲取超支項目
    func getOverBudgetItems() -> [BudgetItem] {
        return getBudgetItems().filter { $0.spentAmount > $0.budgetedAmount }
    }
    
    // 獲取接近預算限制的項目
    func getNearLimitItems(threshold: Double = 0.8) -> [BudgetItem] {
        return getBudgetItems().filter { $0.percentage >= threshold && $0.percentage < 1.0 }
    }
    
    // 完成預算
    func completeBudget() {
        self.status = BudgetStatus.completed.rawValue
        self.updatedAt = Date()
    }
    
    // 暫停預算
    func pauseBudget() {
        self.status = BudgetStatus.paused.rawValue
        self.updatedAt = Date()
    }
    
    // 恢復預算
    func resumeBudget() {
        self.status = BudgetStatus.active.rawValue
        self.updatedAt = Date()
    }
    
    // 取消預算
    func cancelBudget() {
        self.status = BudgetStatus.cancelled.rawValue
        self.updatedAt = Date()
    }
    
    // 獲取預算類型枚舉
    func getBudgetType() -> BudgetType? {
        return BudgetType(rawValue: type)
    }
    
    // 獲取預算狀態枚舉
    func getBudgetStatus() -> BudgetStatus? {
        return BudgetStatus(rawValue: status)
    }
    
    // 檢查是否為活躍預算
    var isActive: Bool {
        return status == BudgetStatus.active.rawValue && Date() >= startDate && Date() <= endDate
    }
    
    // 檢查是否已過期
    var isExpired: Bool {
        return Date() > endDate
    }
    
    // 獲取剩餘天數
    var remainingDays: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: endDate)
        return max(0, components.day ?? 0)
    }
    
    // 獲取預算健康度評分（0-100）
    var healthScore: Int {
        if isOverBudget() {
            return max(0, 100 - Int((totalSpent - totalBudget) / totalBudget * 100))
        } else {
            return min(100, Int((1 - executionRate) * 100))
        }
    }
}
