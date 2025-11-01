//
//  FinancialHealthManager.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import Foundation
import SwiftData
import Combine

// 財務健康管理器
@MainActor
class FinancialHealthManager: ObservableObject {
    static let shared = FinancialHealthManager()
    
    @Published var currentScore: FinancialHealthScore = FinancialHealthScore(overall: 0, dimensions: [:])
    @Published var currentMetrics: FinancialHealthMetrics = FinancialHealthMetrics(
        monthlyIncome: 0,
        incomeStability: 0,
        incomeGrowth: 0,
        monthlyExpenses: 0,
        expenseRatio: 0,
        expenseGrowth: 0,
        monthlySavings: 0,
        savingsRate: 0,
        emergencyFund: 0,
        totalDebt: 0,
        debtToIncomeRatio: 0,
        debtServiceRatio: 0,
        totalInvestments: 0,
        investmentReturn: 0,
        portfolioDiversification: 0,
        insuranceCoverage: 0,
        riskProtection: 0,
        estatePlanning: 0
    )
    @Published var historicalScores: [FinancialHealthScore] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var modelContext: ModelContext?
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // ModelContext 將從外部注入
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        Task {
            await loadHealthData()
        }
    }
    
    // MARK: - 資料載入
    
    func loadHealthData() async {
        guard let modelContext = modelContext else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // 載入用戶資料
            let userDescriptor = FetchDescriptor<User>()
            let users = try modelContext.fetch(userDescriptor)
            
            guard let user = users.first else {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = "No user found"
                }
                return
            }
            
            // 計算財務指標
            let metrics = await calculateFinancialMetrics(for: user)
            
            // 計算健康評分
            var score = FinancialHealthCalculator.calculateOverallScore(from: metrics)
            
            // 應用手動覆蓋的分數
            score = applyScoreOverrides(to: score)
            
            // 載入歷史評分
            let historicalScores = await loadHistoricalScores(for: user)
            
            await MainActor.run {
                self.currentMetrics = metrics
                self.currentScore = score
                self.historicalScores = historicalScores
                self.isLoading = false
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load health data: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    func refreshHealthScore() async {
        await loadHealthData()
    }
    
    // MARK: - 財務指標計算
    
    private func calculateFinancialMetrics(for user: User) async -> FinancialHealthMetrics {
        guard let modelContext = modelContext else { 
            return FinancialHealthMetrics(
                monthlyIncome: 0, incomeStability: 0, incomeGrowth: 0,
                monthlyExpenses: 0, expenseRatio: 0, expenseGrowth: 0,
                monthlySavings: 0, savingsRate: 0, emergencyFund: 0,
                totalDebt: 0, debtToIncomeRatio: 0, debtServiceRatio: 0,
                totalInvestments: 0, investmentReturn: 0, portfolioDiversification: 0,
                insuranceCoverage: 0, riskProtection: 0, estatePlanning: 0
            )
        }
        
        // 載入交易資料
        let transactionDescriptor = FetchDescriptor<Transaction>()
        let allTransactions = (try? modelContext.fetch(transactionDescriptor)) ?? []
        let transactions = allTransactions.filter { $0.user?.id == user.id }
        
        // 載入投資資料
        let investmentDescriptor = FetchDescriptor<Investment>()
        let allInvestments = (try? modelContext.fetch(investmentDescriptor)) ?? []
        let investments = allInvestments.filter { $0.user?.id == user.id }
        
        // 載入財務目標
        let goalDescriptor = FetchDescriptor<FinancialGoal>()
        let allGoals = (try? modelContext.fetch(goalDescriptor)) ?? []
        let goals = allGoals.filter { $0.user?.id == user.id }
        
        // 計算各項指標
        let metrics = calculateMetricsFromData(
            transactions: transactions,
            investments: investments,
            goals: goals,
            user: user
        )
        
        return metrics
    }
    
    private func calculateMetricsFromData(
        transactions: [Transaction],
        investments: [Investment],
        goals: [FinancialGoal],
        user: User
    ) -> FinancialHealthMetrics {
        
        // 計算收入指標
        let incomeTransactions = transactions.filter { $0.type == "income" }
        let monthlyIncome = calculateMonthlyIncome(from: incomeTransactions)
        let incomeStability = calculateIncomeStability(from: incomeTransactions)
        let incomeGrowth = calculateIncomeGrowth(from: incomeTransactions)
        
        // 計算支出指標
        let expenseTransactions = transactions.filter { $0.type == "expense" }
        let monthlyExpenses = calculateMonthlyExpenses(from: expenseTransactions)
        let expenseRatio = monthlyIncome > 0 ? monthlyExpenses / monthlyIncome : 0
        let expenseGrowth = calculateExpenseGrowth(from: expenseTransactions)
        
        // 計算儲蓄指標
        let monthlySavings = monthlyIncome - monthlyExpenses
        let savingsRate = monthlyIncome > 0 ? monthlySavings / monthlyIncome : 0
        let emergencyFund = calculateEmergencyFund(from: transactions)
        
        // 計算債務指標
        let debtTransactions = transactions.filter { $0.category == "debt" }
        let totalDebt = calculateTotalDebt(from: debtTransactions)
        let debtToIncomeRatio = monthlyIncome > 0 ? totalDebt / (monthlyIncome * 12) : 0
        let debtServiceRatio = calculateDebtServiceRatio(from: debtTransactions, monthlyIncome: monthlyIncome)
        
        // 計算投資指標
        let totalInvestments = calculateTotalInvestments(from: investments)
        let investmentReturn = calculateInvestmentReturn(from: investments)
        let portfolioDiversification = calculatePortfolioDiversification(from: investments)
        
        // 計算保護指標
        let insuranceCoverage = calculateInsuranceCoverage(from: user)
        let riskProtection = calculateRiskProtection(from: user, totalAssets: totalInvestments)
        let estatePlanning = calculateEstatePlanning(from: user)
        
        return FinancialHealthMetrics(
            monthlyIncome: monthlyIncome,
            incomeStability: incomeStability,
            incomeGrowth: incomeGrowth,
            monthlyExpenses: monthlyExpenses,
            expenseRatio: expenseRatio,
            expenseGrowth: expenseGrowth,
            monthlySavings: monthlySavings,
            savingsRate: savingsRate,
            emergencyFund: emergencyFund,
            totalDebt: totalDebt,
            debtToIncomeRatio: debtToIncomeRatio,
            debtServiceRatio: debtServiceRatio,
            totalInvestments: totalInvestments,
            investmentReturn: investmentReturn,
            portfolioDiversification: portfolioDiversification,
            insuranceCoverage: insuranceCoverage,
            riskProtection: riskProtection,
            estatePlanning: estatePlanning
        )
    }
    
    // MARK: - 具體計算方法
    
    private func calculateMonthlyIncome(from transactions: [Transaction]) -> Double {
        let lastMonth = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        let incomeTransactions = transactions.filter { 
            $0.type == "income" && $0.date >= lastMonth 
        }
        return incomeTransactions.reduce(0) { $0 + $1.amount }
    }
    
    func calculateIncomeStability(from transactions: [Transaction]) -> Double {
        // 計算過去12個月的收入穩定性
        let last12Months = Calendar.current.date(byAdding: .month, value: -12, to: Date()) ?? Date()
        let incomeTransactions = transactions.filter { 
            ($0.type == TransactionType.income.rawValue || $0.type == "income") && $0.date >= last12Months 
        }
        
        guard !incomeTransactions.isEmpty else {
            print("⚠️ 沒有收入交易記錄，無法計算穩定性")
            return 0
        }
        
        let monthlyIncomes = Dictionary(grouping: incomeTransactions) { transaction in
            Calendar.current.dateInterval(of: .month, for: transaction.date)?.start ?? transaction.date
        }.mapValues { $0.reduce(0) { $0 + $1.amount } }
        
        guard !monthlyIncomes.isEmpty else {
            print("⚠️ 無法分組收入記錄，可能日期有問題")
            return 0
        }
        
        let values = Array(monthlyIncomes.values)
        let mean = values.reduce(0, +) / Double(values.count)
        
        guard mean > 0 else {
            print("⚠️ 平均收入為 0，無法計算穩定性")
            return 0
        }
        
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count)
        let standardDeviation = sqrt(variance)
        
        // 穩定性 = 1 - (標準差 / 平均值)
        let stability = max(0, min(1, 1 - (standardDeviation / mean)))
        print("📊 收入穩定性計算: 交易數=\(incomeTransactions.count), 月數=\(monthlyIncomes.count), 平均=\(mean), 穩定性=\(stability)")
        return stability
    }
    
    private func calculateIncomeGrowth(from transactions: [Transaction]) -> Double {
        let last6Months = Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date()
        let last12Months = Calendar.current.date(byAdding: .month, value: -12, to: Date()) ?? Date()
        
        let recentIncome = transactions.filter { 
            $0.type == "income" && $0.date >= last6Months 
        }.reduce(0) { $0 + $1.amount }
        
        let previousIncome = transactions.filter { 
            $0.type == "income" && $0.date >= last12Months && $0.date < last6Months 
        }.reduce(0) { $0 + $1.amount }
        
        return previousIncome > 0 ? (recentIncome - previousIncome) / previousIncome : 0
    }
    
    private func calculateMonthlyExpenses(from transactions: [Transaction]) -> Double {
        let lastMonth = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        let expenseTransactions = transactions.filter { 
            $0.type == "expense" && $0.date >= lastMonth 
        }
        return expenseTransactions.reduce(0) { $0 + $1.amount }
    }
    
    private func calculateExpenseGrowth(from transactions: [Transaction]) -> Double {
        let last6Months = Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date()
        let last12Months = Calendar.current.date(byAdding: .month, value: -12, to: Date()) ?? Date()
        
        let recentExpenses = transactions.filter { 
            $0.type == "expense" && $0.date >= last6Months 
        }.reduce(0) { $0 + $1.amount }
        
        let previousExpenses = transactions.filter { 
            $0.type == "expense" && $0.date >= last12Months && $0.date < last6Months 
        }.reduce(0) { $0 + $1.amount }
        
        return previousExpenses > 0 ? (recentExpenses - previousExpenses) / previousExpenses : 0
    }
    
    private func calculateEmergencyFund(from transactions: [Transaction]) -> Double {
        // 計算儲蓄帳戶餘額
        let savingsTransactions = transactions.filter { $0.category == "savings" }
        return savingsTransactions.reduce(0) { $0 + $1.amount }
    }
    
    private func calculateTotalDebt(from transactions: [Transaction]) -> Double {
        let debtTransactions = transactions.filter { $0.category == "debt" }
        return debtTransactions.reduce(0) { $0 + $1.amount }
    }
    
    private func calculateDebtServiceRatio(from transactions: [Transaction], monthlyIncome: Double) -> Double {
        let debtPayments = transactions.filter { $0.category == "debt_payment" }
        let monthlyDebtPayments = debtPayments.reduce(0) { $0 + $1.amount }
        return monthlyIncome > 0 ? monthlyDebtPayments / monthlyIncome : 0
    }
    
    private func calculateTotalInvestments(from investments: [Investment]) -> Double {
        return investments.reduce(0) { $0 + $1.currentValue }
    }
    
    private func calculateInvestmentReturn(from investments: [Investment]) -> Double {
        guard !investments.isEmpty else { return 0 }
        
        let totalReturn = investments.reduce(0) { $0 + ($1.currentValue - $1.totalCost) }
        let totalInitial = investments.reduce(0) { $0 + $1.totalCost }
        
        return totalInitial > 0 ? totalReturn / totalInitial : 0
    }
    
    private func calculatePortfolioDiversification(from investments: [Investment]) -> Double {
        guard !investments.isEmpty else { return 0 }
        
        let categories = Set(investments.map { $0.type })
        let diversificationScore = Double(categories.count) / 5.0 // 假設有5個投資類別
        
        return min(1.0, diversificationScore)
    }
    
    private func calculateInsuranceCoverage(from user: User) -> Double {
        // 這裡需要根據用戶的保險資料計算
        // 暫時返回一個預設值
        return 0.5
    }
    
    private func calculateRiskProtection(from user: User, totalAssets: Double) -> Double {
        // 根據用戶的年齡、收入、資產等計算風險保護度
        return 0.6
    }
    
    private func calculateEstatePlanning(from user: User) -> Double {
        // 根據用戶的遺產規劃完成度計算
        return 0.3
    }
    
    // MARK: - 歷史資料
    
    private func loadHistoricalScores(for user: User) async -> [FinancialHealthScore] {
        guard let modelContext = modelContext else { return [] }
        
        let reportDescriptor = FetchDescriptor<FinancialHealthReport>()
        
        do {
            let reports = try modelContext.fetch(reportDescriptor)
            return reports.map { $0.score }.sorted { $0.lastUpdated > $1.lastUpdated }
        } catch {
            return []
        }
    }
    
    // MARK: - 資料保存
    
    func saveHealthReport() async {
        guard let modelContext = modelContext else { return }
        
        do {
            let report = FinancialHealthReport(
                userId: UUID(), // 這裡需要從當前用戶獲取
                score: currentScore,
                metrics: currentMetrics,
                recommendations: []
            )
            
            modelContext.insert(report)
            try modelContext.save()
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to save health report: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - 手動分數覆蓋
    
    /// 應用手動覆蓋的分數
    private func applyScoreOverrides(to score: FinancialHealthScore) -> FinancialHealthScore {
        var modifiedDimensions = score.dimensions
        
        // 從 UserDefaults 讀取覆蓋分數
        for dimension in FinancialHealthDimension.allCases {
            let key = "scoreOverride_\(dimension.rawValue)"
            if let overrideValue = UserDefaults.standard.object(forKey: key) as? Int {
                modifiedDimensions[dimension] = overrideValue
            }
        }
        
        // 如果沒有任何覆蓋，返回原分數
        if modifiedDimensions == score.dimensions {
            return score
        }
        
        // 重新計算總體評分
        let overallScore = modifiedDimensions.values.reduce(0, +) / modifiedDimensions.count
        
        return FinancialHealthScore(
            overall: overallScore,
            dimensions: modifiedDimensions,
            recommendations: score.recommendations,
            lastUpdated: score.lastUpdated,
            gabrielInsight: score.gabrielInsight
        )
    }
}
