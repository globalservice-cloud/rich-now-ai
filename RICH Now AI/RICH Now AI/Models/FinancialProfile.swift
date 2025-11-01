//
//  FinancialProfile.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import Foundation
import SwiftData

// 收入來源
struct IncomeSource: Codable {
    let name: String
    let amount: Double
    let frequency: String // monthly, weekly, yearly
    let isActive: Bool
}

// 支出項目
struct ExpenseItem: Codable {
    let category: String
    let amount: Double
    let frequency: String
    let isFixed: Bool // 固定支出或變動支出
}

// 資產項目
struct AssetItem: Codable {
    let name: String
    let type: String // cash, investment, property, vehicle, etc.
    let value: Double
    let lastUpdated: Date
}

// 負債項目
struct LiabilityItem: Codable {
    let name: String
    let type: String // mortgage, car_loan, credit_card, personal_loan, etc.
    let balance: Double
    let monthlyPayment: Double
    let interestRate: Double
    let dueDate: Date?
}

// 保險項目
struct InsuranceItem: Codable {
    let type: String // life, health, auto, property, etc.
    let provider: String
    let premium: Double
    let coverage: Double
    let nextPayment: Date
}

@Model
final class FinancialProfile {
    // 基本財務資訊
    var monthlyIncome: Double
    var monthlyExpenses: Double
    var netWorth: Double
    var emergencyFund: Double
    var emergencyFundTarget: Double // 目標緊急預備金
    
    // 收入來源
    var incomeSources: Data // [IncomeSource] 的 JSON 格式
    
    // 支出項目
    var expenseItems: Data // [ExpenseItem] 的 JSON 格式
    
    // 資產
    var assets: Data // [AssetItem] 的 JSON 格式
    
    // 負債
    var liabilities: Data // [LiabilityItem] 的 JSON 格式
    
    // 保險
    var insurance: Data // [InsuranceItem] 的 JSON 格式
    
    // 風險承受度
    var riskTolerance: String // conservative, moderate, aggressive
    
    // 投資經驗
    var investmentExperience: String // beginner, intermediate, advanced
    
    // 財務目標優先順序
    var goalPriorities: [String] // 目標優先順序列表
    
    // 時間戳記
    var createdAt: Date
    var updatedAt: Date
    var lastCalculatedAt: Date
    
    // 關聯
    @Relationship(deleteRule: .nullify, inverse: \User.financialProfile) var user: User?
    
    init() {
        self.monthlyIncome = 0
        self.monthlyExpenses = 0
        self.netWorth = 0
        self.emergencyFund = 0
        self.emergencyFundTarget = 0
        self.incomeSources = Data()
        self.expenseItems = Data()
        self.assets = Data()
        self.liabilities = Data()
        self.insurance = Data()
        self.riskTolerance = "moderate"
        self.investmentExperience = "beginner"
        self.goalPriorities = []
        self.createdAt = Date()
        self.updatedAt = Date()
        self.lastCalculatedAt = Date()
    }
    
    // 添加收入來源
    func addIncomeSource(_ source: IncomeSource) {
        var sources = getIncomeSources()
        sources.append(source)
        self.incomeSources = (try? JSONEncoder().encode(sources)) ?? Data()
        self.updatedAt = Date()
    }
    
    // 添加支出項目
    func addExpenseItem(_ item: ExpenseItem) {
        var items = getExpenseItems()
        items.append(item)
        self.expenseItems = (try? JSONEncoder().encode(items)) ?? Data()
        self.updatedAt = Date()
    }
    
    // 添加資產
    func addAsset(_ asset: AssetItem) {
        var assets = getAssets()
        assets.append(asset)
        self.assets = (try? JSONEncoder().encode(assets)) ?? Data()
        self.updatedAt = Date()
    }
    
    // 添加負債
    func addLiability(_ liability: LiabilityItem) {
        var liabilities = getLiabilities()
        liabilities.append(liability)
        self.liabilities = (try? JSONEncoder().encode(liabilities)) ?? Data()
        self.updatedAt = Date()
    }
    
    // 添加保險
    func addInsurance(_ insurance: InsuranceItem) {
        var insuranceList = getInsurance()
        insuranceList.append(insurance)
        self.insurance = (try? JSONEncoder().encode(insuranceList)) ?? Data()
        self.updatedAt = Date()
    }
    
    // 獲取收入來源
    func getIncomeSources() -> [IncomeSource] {
        do {
            return try JSONDecoder().decode([IncomeSource].self, from: incomeSources)
        } catch {
            return []
        }
    }
    
    // 獲取支出項目
    func getExpenseItems() -> [ExpenseItem] {
        do {
            return try JSONDecoder().decode([ExpenseItem].self, from: expenseItems)
        } catch {
            return []
        }
    }
    
    // 獲取資產
    func getAssets() -> [AssetItem] {
        do {
            return try JSONDecoder().decode([AssetItem].self, from: assets)
        } catch {
            return []
        }
    }
    
    // 獲取負債
    func getLiabilities() -> [LiabilityItem] {
        do {
            return try JSONDecoder().decode([LiabilityItem].self, from: liabilities)
        } catch {
            return []
        }
    }
    
    // 獲取保險
    func getInsurance() -> [InsuranceItem] {
        do {
            return try JSONDecoder().decode([InsuranceItem].self, from: insurance)
        } catch {
            return []
        }
    }
    
    // 計算淨資產
    func calculateNetWorth() -> Double {
        let totalAssets = getAssets().reduce(0) { $0 + $1.value }
        let totalLiabilities = getLiabilities().reduce(0) { $0 + $1.balance }
        self.netWorth = totalAssets - totalLiabilities
        self.lastCalculatedAt = Date()
        return netWorth
    }
    
    // 計算月度現金流
    func calculateMonthlyCashFlow() -> Double {
        return monthlyIncome - monthlyExpenses
    }
    
    // 檢查緊急預備金是否充足
    func isEmergencyFundAdequate() -> Bool {
        return emergencyFund >= emergencyFundTarget
    }
    
    // 獲取緊急預備金完成度
    func getEmergencyFundProgress() -> Double {
        guard emergencyFundTarget > 0 else { return 0 }
        return min(1.0, emergencyFund / emergencyFundTarget)
    }
    
    // 更新財務概況
    func updateFinancialSummary() {
        // 計算總收入
        let totalIncome = getIncomeSources().reduce(0) { total, source in
            switch source.frequency {
            case "monthly":
                return total + source.amount
            case "weekly":
                return total + (source.amount * 4.33) // 平均每月週數
            case "yearly":
                return total + (source.amount / 12)
            default:
                return total + source.amount
            }
        }
        self.monthlyIncome = totalIncome
        
        // 計算總支出
        let totalExpenses = getExpenseItems().reduce(0) { total, item in
            switch item.frequency {
            case "monthly":
                return total + item.amount
            case "weekly":
                return total + (item.amount * 4.33)
            case "yearly":
                return total + (item.amount / 12)
            default:
                return total + item.amount
            }
        }
        self.monthlyExpenses = totalExpenses
        
        // 重新計算淨資產
        _ = calculateNetWorth()
        
        self.updatedAt = Date()
    }
}
