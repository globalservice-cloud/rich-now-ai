//
//  FamilyAccountManager.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/12/19.
//

import Foundation
import SwiftData
import Combine
import os.log

/// 家庭記帳管理器
@MainActor
class FamilyAccountManager: ObservableObject {
    static let shared = FamilyAccountManager()
    
    @Published var currentFamilyGroup: FamilyGroup?
    @Published var familyMembers: [FamilyMember] = []
    @Published var familyBudgets: [FamilyBudget] = []
    @Published var familyTransactions: [Transaction] = []
    @Published var familyStats: FamilyAccountingStats?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var modelContext: ModelContext?
    private var cancellables = Set<AnyCancellable>()
    private let logger = Logger(subsystem: "com.richnowai", category: "FamilyAccountManager")
    
    private init() {}
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadFamilyData()
    }
    
    // MARK: - 家庭群組管理
    
    func createFamilyGroup(name: String, ownerId: UUID) -> FamilyGroup? {
        guard let modelContext = modelContext else {
            errorMessage = "ModelContext 未初始化"
            return nil
        }
        
        let familyGroup = FamilyGroup(name: name, createdBy: ownerId)
        modelContext.insert(familyGroup)
        
        do {
            try modelContext.save()
            currentFamilyGroup = familyGroup
            logger.info("創建家庭群組: \(name)")
            return familyGroup
        } catch {
            errorMessage = "創建家庭群組失敗: \(error.localizedDescription)"
            logger.error("創建家庭群組失敗: \(error.localizedDescription)")
            return nil
        }
    }
    
    func loadFamilyData() {
        guard let modelContext = modelContext else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // 載入家庭群組
            var descriptor = FetchDescriptor<FamilyGroup>()
            descriptor.sortBy = [SortDescriptor(\.createdAt, order: .reverse)]
            let groups = try modelContext.fetch(descriptor)
            currentFamilyGroup = groups.first
            
            if let group = currentFamilyGroup {
                // 載入家庭成員
                familyMembers = group.members.filter { $0.isActive }
                
                // 載入家庭預算
                familyBudgets = group.budgets.filter { $0.isActive }
                
                // 載入家庭交易
                familyTransactions = group.transactions.sorted { $0.date > $1.date }
                
                // 計算統計數據
                calculateFamilyStats()
            }
            
            isLoading = false
        } catch {
            errorMessage = "載入家庭數據失敗: \(error.localizedDescription)"
            logger.error("載入家庭數據失敗: \(error.localizedDescription)")
            isLoading = false
        }
    }
    
    // MARK: - 家庭成員管理
    
    func addFamilyMember(
        name: String,
        role: String,
        age: Int? = nil,
        canManageBudget: Bool = false,
        canViewAllTransactions: Bool = true,
        monthlyAllowance: Double? = nil
    ) -> Bool {
        guard let modelContext = modelContext,
              let familyGroup = currentFamilyGroup else {
            errorMessage = "請先創建家庭群組"
            return false
        }
        
        // 檢查是否已存在同名成員
        let existing = familyMembers.first { $0.name == name && $0.role == role }
        if existing != nil {
            errorMessage = "此成員已存在"
            return false
        }
        
        let member = FamilyMember(
            name: name,
            role: role,
            age: age,
            canManageBudget: canManageBudget,
            canViewAllTransactions: canViewAllTransactions,
            monthlyAllowance: monthlyAllowance
        )
        member.familyGroup = familyGroup
        
        modelContext.insert(member)
        
        do {
            try modelContext.save()
            familyMembers.append(member)
            familyGroup.updatedAt = Date()
            logger.info("添加家庭成員: \(name) (\(role))")
            return true
        } catch {
            errorMessage = "添加成員失敗: \(error.localizedDescription)"
            logger.error("添加成員失敗: \(error.localizedDescription)")
            return false
        }
    }
    
    func updateFamilyMember(
        _ member: FamilyMember,
        name: String? = nil,
        role: String? = nil,
        age: Int? = nil,
        canManageBudget: Bool? = nil,
        canViewAllTransactions: Bool? = nil,
        monthlyAllowance: Double? = nil
    ) {
        guard let modelContext = modelContext else { return }
        
        if let name = name {
            member.name = name
        }
        if let role = role {
            member.role = role
        }
        if let age = age {
            member.age = age
        }
        if let canManage = canManageBudget {
            member.canManageBudget = canManage
        }
        if let canView = canViewAllTransactions {
            member.canViewAllTransactions = canView
        }
        if let allowance = monthlyAllowance {
            member.monthlyAllowance = allowance
        }
        
        member.updatedAt = Date()
        
        do {
            try modelContext.save()
            logger.info("更新家庭成員: \(member.name)")
        } catch {
            errorMessage = "更新成員失敗: \(error.localizedDescription)"
            logger.error("更新成員失敗: \(error.localizedDescription)")
        }
    }
    
    func removeFamilyMember(_ member: FamilyMember) {
        guard let modelContext = modelContext else { return }
        
        member.isActive = false
        member.updatedAt = Date()
        
        do {
            try modelContext.save()
            familyMembers.removeAll { $0.id == member.id }
            logger.info("移除家庭成員: \(member.name)")
        } catch {
            errorMessage = "移除成員失敗: \(error.localizedDescription)"
            logger.error("移除成員失敗: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 家庭預算管理
    
    func createFamilyBudget(
        name: String,
        category: String,
        budgetedAmount: Double,
        period: String,
        startDate: Date,
        endDate: Date,
        warningThreshold: Double = 0.8
    ) -> FamilyBudget? {
        guard let modelContext = modelContext,
              let familyGroup = currentFamilyGroup else {
            errorMessage = "請先創建家庭群組"
            return nil
        }
        
        let budget = FamilyBudget(
            name: name,
            category: category,
            budgetedAmount: budgetedAmount,
            period: period,
            startDate: startDate,
            endDate: endDate,
            warningThreshold: warningThreshold
        )
        budget.familyGroup = familyGroup
        
        modelContext.insert(budget)
        
        do {
            try modelContext.save()
            familyBudgets.append(budget)
            familyGroup.updatedAt = Date()
            logger.info("創建家庭預算: \(name)")
            return budget
        } catch {
            errorMessage = "創建預算失敗: \(error.localizedDescription)"
            logger.error("創建預算失敗: \(error.localizedDescription)")
            return nil
        }
    }
    
    func updateBudgetSpending(_ budget: FamilyBudget, amount: Double) {
        guard let modelContext = modelContext else { return }
        
        budget.updateSpending(amount)
        
        do {
            try modelContext.save()
            calculateFamilyStats()
        } catch {
            errorMessage = "更新預算失敗: \(error.localizedDescription)"
            logger.error("更新預算失敗: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 家庭交易管理
    
    func addFamilyTransaction(
        amount: Double,
        type: TransactionType,
        category: TransactionCategory,
        description: String,
        memberId: UUID?,
        date: Date = Date()
    ) -> Transaction? {
        guard let modelContext = modelContext,
              let familyGroup = currentFamilyGroup else {
            errorMessage = "請先創建家庭群組"
            return nil
        }
        
        let transaction = Transaction(
            amount: amount,
            type: type,
            category: category,
            description: description,
            date: date
        )
        
        // 關聯到家庭群組
        transaction.familyGroup = familyGroup
        
        // 關聯到成員（如果需要）
        if let memberId = memberId,
           let member = familyMembers.first(where: { $0.id == memberId }) {
            transaction.notes = (transaction.notes ?? "") + "\n成員: \(member.name)"
            // 添加標籤
            transaction.addTag("家庭記帳")
            transaction.addTag("成員:\(member.name)")
        } else {
            // 如果沒有 memberId 或找不到成員，仍然添加家庭記帳標籤
            transaction.addTag("家庭記帳")
        }
        
        modelContext.insert(transaction)
        
        // 更新相關預算
        if type == .expense, let budget = familyBudgets.first(where: { $0.category == category.rawValue && $0.isActive }) {
            updateBudgetSpending(budget, amount: amount)
        }
        
        do {
            try modelContext.save()
            familyTransactions.append(transaction)
            familyGroup.updatedAt = Date()
            calculateFamilyStats()
            logger.info("添加家庭交易: \(description)")
            return transaction
        } catch {
            errorMessage = "添加交易失敗: \(error.localizedDescription)"
            logger.error("添加交易失敗: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - 統計計算
    
    func calculateFamilyStats() {
        guard let familyGroup = currentFamilyGroup else { return }
        
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
        let endOfMonth = calendar.dateInterval(of: .month, for: now)?.end ?? now
        
        // 篩選本月交易
        let monthlyTransactions = familyTransactions.filter { transaction in
            transaction.date >= startOfMonth && transaction.date < endOfMonth
        }
        
        // 計算總收入
        let totalIncome = monthlyTransactions
            .filter { $0.getTransactionType() == .income }
            .reduce(0.0) { $0 + $1.amount }
        
        // 計算總支出
        let totalExpenses = monthlyTransactions
            .filter { $0.getTransactionType() == .expense }
            .reduce(0.0) { $0 + $1.amount }
        
        // 計算淨收入
        let netIncome = totalIncome - totalExpenses
        
        // 按成員統計
        var memberStatsDict: [UUID: MemberStats] = [:]
        for member in familyMembers {
            let memberTransactions = monthlyTransactions.filter { transaction in
                // 根據標籤或備註來識別成員的交易
                if let notes = transaction.notes, notes.contains("成員:\(member.name)") {
                    return true
                }
                if transaction.tags.contains("成員:\(member.name)") {
                    return true
                }
                return false
            }
            
            let memberIncome = memberTransactions
                .filter { $0.getTransactionType() == .income }
                .reduce(0.0) { $0 + $1.amount }
            
            let memberExpenses = memberTransactions
                .filter { $0.getTransactionType() == .expense }
                .reduce(0.0) { $0 + $1.amount }
            
            memberStatsDict[member.id] = MemberStats(
                memberId: member.id,
                memberName: member.name,
                income: memberIncome,
                expenses: memberExpenses,
                transactionCount: memberTransactions.count
            )
        }
        
        // 按分類統計
        var categoryStatsDict: [String: (amount: Double, count: Int)] = [:]
        for transaction in monthlyTransactions {
            let category = transaction.getTransactionCategory()?.rawValue ?? "other"
            let amount = transaction.amount
            
            if let existing = categoryStatsDict[category] {
                categoryStatsDict[category] = (
                    amount: existing.amount + amount,
                    count: existing.count + 1
                )
            } else {
                categoryStatsDict[category] = (amount: amount, count: 1)
            }
        }
        
        let totalForPercentage = totalIncome + totalExpenses
        let categoryBreakdown = categoryStatsDict.map { (category, data) in
            CategoryStats(
                category: category,
                amount: data.amount,
                percentage: totalForPercentage > 0 ? (data.amount / totalForPercentage) * 100 : 0,
                transactionCount: data.count
            )
        }.sorted { $0.amount > $1.amount }
        
        familyStats = FamilyAccountingStats(
            totalIncome: totalIncome,
            totalExpenses: totalExpenses,
            netIncome: netIncome,
            memberBreakdown: Array(memberStatsDict.values).sorted { $0.memberName < $1.memberName },
            categoryBreakdown: categoryBreakdown,
            periodStart: startOfMonth,
            periodEnd: endOfMonth
        )
        
        // 更新家庭群組統計
        familyGroup.totalMonthlyIncome = totalIncome
        familyGroup.totalMonthlyExpenses = totalExpenses
        familyGroup.updatedAt = Date()
        
        // 保存更新
        if let modelContext = modelContext {
            try? modelContext.save()
        }
    }
    
    // MARK: - 預算警告檢查
    
    func checkBudgetWarnings() -> [FamilyBudget] {
        return familyBudgets.filter { $0.isOverWarningThreshold && $0.isActive }
    }
}

