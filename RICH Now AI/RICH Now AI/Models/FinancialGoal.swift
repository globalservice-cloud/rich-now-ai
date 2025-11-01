//
//  FinancialGoal.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import Foundation
import SwiftData

// 目標類型
enum GoalType: String, Codable, CaseIterable {
    case emergency_fund = "emergency_fund"     // 緊急預備金
    case debt_payoff = "debt_payoff"          // 債務清償
    case home_purchase = "home_purchase"      // 購屋
    case car_purchase = "car_purchase"        // 購車
    case education = "education"              // 教育基金
    case retirement = "retirement"            // 退休規劃
    case investment = "investment"            // 投資理財
    case travel = "travel"                   // 旅行基金
    case wedding = "wedding"                 // 婚禮基金
    case business = "business"                // 創業基金
    case donation = "donation"                // 奉獻目標
    case other = "other"                     // 其他
}

// 目標狀態
enum GoalStatus: String, Codable {
    case active = "active"           // 進行中
    case completed = "completed"     // 已完成
    case paused = "paused"          // 暫停
    case cancelled = "cancelled"    // 已取消
}

// 目標優先級
enum GoalPriority: String, Codable, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case urgent = "urgent"
}

@Model
final class FinancialGoal {
    // 唯一識別碼
    @Attribute(.unique) var id: UUID = UUID()
    
    // 基本資訊
    var title: String
    var goalDescription: String
    var type: String // GoalType.rawValue
    var priority: String // GoalPriority.rawValue
    var status: String // GoalStatus.rawValue
    
    // 金額與進度
    var targetAmount: Double
    var currentAmount: Double
    var progress: Double // 0-1 的進度百分比
    
    // 時間規劃
    var startDate: Date
    var targetDate: Date
    var completedDate: Date?
    
    // 儲蓄計劃
    var monthlyContribution: Double
    var contributionFrequency: String // monthly, weekly, yearly
    
    // 目標設定
    var isFlexible: Bool // 目標日期是否可調整
    var autoAdjust: Bool // 是否自動調整儲蓄金額
    
    // 里程碑
    var milestones: Data // [String] 的 JSON 格式，里程碑描述
    var completedMilestones: Data // [String] 的 JSON 格式
    
    // 激勵與提醒
    var motivation: String? // 動機描述
    var reminderFrequency: String? // 提醒頻率
    var lastReminderDate: Date?
    
    // 關聯目標
    var relatedGoalIds: [String] // 相關目標 ID 列表
    
    // 時間戳記
    var createdAt: Date
    var updatedAt: Date
    
    // 關聯
    @Relationship(deleteRule: .nullify, inverse: \User.goals) var user: User?
    
    init(title: String, description: String, type: GoalType, targetAmount: Double, targetDate: Date, monthlyContribution: Double) {
        self.title = title
        self.goalDescription = description
        self.type = type.rawValue
        self.priority = GoalPriority.medium.rawValue
        self.status = GoalStatus.active.rawValue
        self.targetAmount = targetAmount
        self.currentAmount = 0
        self.progress = 0
        self.startDate = Date()
        self.targetDate = targetDate
        self.monthlyContribution = monthlyContribution
        self.contributionFrequency = "monthly"
        self.isFlexible = true
        self.autoAdjust = false
        self.milestones = Data()
        self.completedMilestones = Data()
        self.relatedGoalIds = []
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // 更新進度
    func updateProgress(_ newAmount: Double) {
        self.currentAmount = newAmount
        self.progress = min(1.0, newAmount / targetAmount)
        self.updatedAt = Date()
        
        // 檢查是否完成
        if progress >= 1.0 && status == GoalStatus.active.rawValue {
            completeGoal()
        }
    }
    
    // 添加進度
    func addProgress(_ amount: Double) {
        updateProgress(currentAmount + amount)
    }
    
    // 完成目標
    func completeGoal() {
        self.status = GoalStatus.completed.rawValue
        self.completedDate = Date()
        self.progress = 1.0
        self.updatedAt = Date()
    }
    
    // 暫停目標
    func pauseGoal() {
        self.status = GoalStatus.paused.rawValue
        self.updatedAt = Date()
    }
    
    // 恢復目標
    func resumeGoal() {
        self.status = GoalStatus.active.rawValue
        self.updatedAt = Date()
    }
    
    // 取消目標
    func cancelGoal() {
        self.status = GoalStatus.cancelled.rawValue
        self.updatedAt = Date()
    }
    
    // 添加里程碑
    func addMilestone(_ milestone: String) {
        var milestones = getMilestones()
        milestones.append(milestone)
        self.milestones = (try? JSONEncoder().encode(milestones)) ?? Data()
        self.updatedAt = Date()
    }
    
    // 完成里程碑
    func completeMilestone(_ milestone: String) {
        var completed = getCompletedMilestones()
        if !completed.contains(milestone) {
            completed.append(milestone)
            self.completedMilestones = (try? JSONEncoder().encode(completed)) ?? Data()
            self.updatedAt = Date()
        }
    }
    
    // 獲取里程碑
    func getMilestones() -> [String] {
        do {
            return try JSONDecoder().decode([String].self, from: milestones)
        } catch {
            return []
        }
    }
    
    // 獲取已完成的里程碑
    func getCompletedMilestones() -> [String] {
        do {
            return try JSONDecoder().decode([String].self, from: completedMilestones)
        } catch {
            return []
        }
    }
    
    // 計算剩餘金額
    var remainingAmount: Double {
        return max(0, targetAmount - currentAmount)
    }
    
    // 計算剩餘時間（月）
    var remainingMonths: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month], from: Date(), to: targetDate)
        return max(0, components.month ?? 0)
    }
    
    // 計算建議的月度儲蓄金額
    var suggestedMonthlyContribution: Double {
        let remaining = remainingAmount
        let months = remainingMonths
        return months > 0 ? remaining / Double(months) : 0
    }
    
    // 檢查是否逾期
    var isOverdue: Bool {
        return status == GoalStatus.active.rawValue && Date() > targetDate
    }
    
    // 獲取目標類型枚舉
    func getGoalType() -> GoalType? {
        return GoalType(rawValue: type)
    }
    
    // 獲取目標狀態枚舉
    func getGoalStatus() -> GoalStatus? {
        return GoalStatus(rawValue: status)
    }
    
    // 獲取目標優先級枚舉
    func getGoalPriority() -> GoalPriority? {
        return GoalPriority(rawValue: priority)
    }
    
    // 更新優先級
    func updatePriority(_ newPriority: GoalPriority) {
        self.priority = newPriority.rawValue
        self.updatedAt = Date()
    }
    
    // 更新目標日期
    func updateTargetDate(_ newDate: Date) {
        self.targetDate = newDate
        self.updatedAt = Date()
    }
    
    // 更新月度儲蓄金額
    func updateMonthlyContribution(_ newAmount: Double) {
        self.monthlyContribution = newAmount
        self.updatedAt = Date()
    }
    
    // 自動調整儲蓄金額
    func autoAdjustContribution() {
        if autoAdjust && remainingMonths > 0 {
            let suggested = suggestedMonthlyContribution
            if suggested > 0 && suggested != monthlyContribution {
                self.monthlyContribution = suggested
                self.updatedAt = Date()
            }
        }
    }
}
