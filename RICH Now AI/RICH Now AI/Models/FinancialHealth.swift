//
//  FinancialHealth.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import Foundation
import SwiftData

// 財務健康六大維度
enum FinancialHealthDimension: String, CaseIterable, Codable {
    case income = "income"           // 收入穩定性
    case expenses = "expenses"       // 支出控制
    case savings = "savings"        // 儲蓄能力
    case debt = "debt"              // 債務管理
    case investment = "investment"   // 投資成長
    case protection = "protection"   // 風險保護
    
    var icon: String {
        switch self {
        case .income: return "dollarsign.circle"
        case .expenses: return "chart.line.downtrend.xyaxis"
        case .savings: return "banknote"
        case .debt: return "creditcard"
        case .investment: return "chart.line.uptrend.xyaxis"
        case .protection: return "shield"
        }
    }
}

// 財務健康評分等級
enum FinancialHealthLevel: String, CaseIterable, Codable {
    case excellent = "excellent"     // 優秀 (90-100)
    case good = "good"              // 良好 (80-89)
    case fair = "fair"              // 一般 (70-79)
    case poor = "poor"              // 不佳 (60-69)
    case critical = "critical"      // 危險 (0-59)
    
    var scoreRange: ClosedRange<Int> {
        switch self {
        case .excellent: return 90...100
        case .good: return 80...89
        case .fair: return 70...79
        case .poor: return 60...69
        case .critical: return 0...59
        }
    }
    
    static func level(for score: Int) -> FinancialHealthLevel {
        for level in FinancialHealthLevel.allCases {
            if level.scoreRange.contains(score) {
                return level
            }
        }
        return .critical
    }
}

// 財務健康評分
struct FinancialHealthScore: Codable {
    let overall: Int                    // 總體評分 (0-100)
    let dimensions: [FinancialHealthDimension: Int]  // 各維度評分
    let level: FinancialHealthLevel    // 健康等級
    let lastUpdated: Date              // 最後更新時間
    let recommendations: [String]      // 改善建議
    let gabrielInsight: String        // 加百列洞察
    
    init(overall: Int, dimensions: [FinancialHealthDimension: Int], recommendations: [String] = [], lastUpdated: Date = Date(), gabrielInsight: String = "") {
        self.overall = overall
        self.dimensions = dimensions
        self.level = FinancialHealthLevel.level(for: overall)
        self.lastUpdated = lastUpdated
        self.recommendations = recommendations
        self.gabrielInsight = gabrielInsight
    }
    
    // nonisolated 編碼方法
    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(overall, forKey: .overall)
        try container.encode(dimensions, forKey: .dimensions)
        try container.encode(level, forKey: .level)
        try container.encode(lastUpdated, forKey: .lastUpdated)
        try container.encode(recommendations, forKey: .recommendations)
        try container.encode(gabrielInsight, forKey: .gabrielInsight)
    }
    
    // nonisolated 解碼方法
    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        overall = try container.decode(Int.self, forKey: .overall)
        dimensions = try container.decode([FinancialHealthDimension: Int].self, forKey: .dimensions)
        level = try container.decode(FinancialHealthLevel.self, forKey: .level)
        lastUpdated = try container.decode(Date.self, forKey: .lastUpdated)
        recommendations = try container.decode([String].self, forKey: .recommendations)
        gabrielInsight = try container.decode(String.self, forKey: .gabrielInsight)
    }
    
    private enum CodingKeys: String, CodingKey {
        case overall, dimensions, level, lastUpdated, recommendations, gabrielInsight
    }
}

// 財務健康指標
struct FinancialHealthMetrics: Codable {
    // 收入指標
    let monthlyIncome: Double
    let incomeStability: Double        // 收入穩定性 (0-1)
    let incomeGrowth: Double          // 收入成長率
    
    // 支出指標
    let monthlyExpenses: Double
    let expenseRatio: Double          // 支出收入比
    let expenseGrowth: Double         // 支出成長率
    
    // 儲蓄指標
    let monthlySavings: Double
    let savingsRate: Double           // 儲蓄率
    let emergencyFund: Double         // 緊急基金
    
    // 債務指標
    let totalDebt: Double
    let debtToIncomeRatio: Double     // 債務收入比
    let debtServiceRatio: Double     // 債務償還比率
    
    // 投資指標
    let totalInvestments: Double
    let investmentReturn: Double      // 投資報酬率
    let portfolioDiversification: Double // 投資組合分散度
    
    // 保護指標
    let insuranceCoverage: Double     // 保險覆蓋率
    let riskProtection: Double        // 風險保護度
    let estatePlanning: Double        // 遺產規劃完整度
    
    // 默認初始化器
    init(
        monthlyIncome: Double,
        incomeStability: Double,
        incomeGrowth: Double,
        monthlyExpenses: Double,
        expenseRatio: Double,
        expenseGrowth: Double,
        monthlySavings: Double,
        savingsRate: Double,
        emergencyFund: Double,
        totalDebt: Double,
        debtToIncomeRatio: Double,
        debtServiceRatio: Double,
        totalInvestments: Double,
        investmentReturn: Double,
        portfolioDiversification: Double,
        insuranceCoverage: Double,
        riskProtection: Double,
        estatePlanning: Double
    ) {
        self.monthlyIncome = monthlyIncome
        self.incomeStability = incomeStability
        self.incomeGrowth = incomeGrowth
        self.monthlyExpenses = monthlyExpenses
        self.expenseRatio = expenseRatio
        self.expenseGrowth = expenseGrowth
        self.monthlySavings = monthlySavings
        self.savingsRate = savingsRate
        self.emergencyFund = emergencyFund
        self.totalDebt = totalDebt
        self.debtToIncomeRatio = debtToIncomeRatio
        self.debtServiceRatio = debtServiceRatio
        self.totalInvestments = totalInvestments
        self.investmentReturn = investmentReturn
        self.portfolioDiversification = portfolioDiversification
        self.insuranceCoverage = insuranceCoverage
        self.riskProtection = riskProtection
        self.estatePlanning = estatePlanning
    }
    
    // nonisolated 編碼方法
    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(monthlyIncome, forKey: .monthlyIncome)
        try container.encode(incomeStability, forKey: .incomeStability)
        try container.encode(incomeGrowth, forKey: .incomeGrowth)
        try container.encode(monthlyExpenses, forKey: .monthlyExpenses)
        try container.encode(expenseRatio, forKey: .expenseRatio)
        try container.encode(expenseGrowth, forKey: .expenseGrowth)
        try container.encode(monthlySavings, forKey: .monthlySavings)
        try container.encode(savingsRate, forKey: .savingsRate)
        try container.encode(emergencyFund, forKey: .emergencyFund)
        try container.encode(totalDebt, forKey: .totalDebt)
        try container.encode(debtToIncomeRatio, forKey: .debtToIncomeRatio)
        try container.encode(debtServiceRatio, forKey: .debtServiceRatio)
        try container.encode(totalInvestments, forKey: .totalInvestments)
        try container.encode(investmentReturn, forKey: .investmentReturn)
        try container.encode(portfolioDiversification, forKey: .portfolioDiversification)
        try container.encode(insuranceCoverage, forKey: .insuranceCoverage)
        try container.encode(riskProtection, forKey: .riskProtection)
        try container.encode(estatePlanning, forKey: .estatePlanning)
    }
    
    // nonisolated 解碼方法
    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        monthlyIncome = try container.decode(Double.self, forKey: .monthlyIncome)
        incomeStability = try container.decode(Double.self, forKey: .incomeStability)
        incomeGrowth = try container.decode(Double.self, forKey: .incomeGrowth)
        monthlyExpenses = try container.decode(Double.self, forKey: .monthlyExpenses)
        expenseRatio = try container.decode(Double.self, forKey: .expenseRatio)
        expenseGrowth = try container.decode(Double.self, forKey: .expenseGrowth)
        monthlySavings = try container.decode(Double.self, forKey: .monthlySavings)
        savingsRate = try container.decode(Double.self, forKey: .savingsRate)
        emergencyFund = try container.decode(Double.self, forKey: .emergencyFund)
        totalDebt = try container.decode(Double.self, forKey: .totalDebt)
        debtToIncomeRatio = try container.decode(Double.self, forKey: .debtToIncomeRatio)
        debtServiceRatio = try container.decode(Double.self, forKey: .debtServiceRatio)
        totalInvestments = try container.decode(Double.self, forKey: .totalInvestments)
        investmentReturn = try container.decode(Double.self, forKey: .investmentReturn)
        portfolioDiversification = try container.decode(Double.self, forKey: .portfolioDiversification)
        insuranceCoverage = try container.decode(Double.self, forKey: .insuranceCoverage)
        riskProtection = try container.decode(Double.self, forKey: .riskProtection)
        estatePlanning = try container.decode(Double.self, forKey: .estatePlanning)
    }
    
    private enum CodingKeys: String, CodingKey {
        case monthlyIncome, incomeStability, incomeGrowth
        case monthlyExpenses, expenseRatio, expenseGrowth
        case monthlySavings, savingsRate, emergencyFund
        case totalDebt, debtToIncomeRatio, debtServiceRatio
        case totalInvestments, investmentReturn, portfolioDiversification
        case insuranceCoverage, riskProtection, estatePlanning
    }
}

// 財務健康建議
struct FinancialHealthRecommendation: Codable, Identifiable {
    let id: UUID
    let dimension: FinancialHealthDimension
    let priority: RecommendationPriority
    let title: String
    let description: String
    let actionItems: [String]
    let expectedImpact: String
    let timeline: String
    
    init(dimension: FinancialHealthDimension, priority: RecommendationPriority, title: String, description: String, actionItems: [String], expectedImpact: String, timeline: String) {
        self.id = UUID()
        self.dimension = dimension
        self.priority = priority
        self.title = title
        self.description = description
        self.actionItems = actionItems
        self.expectedImpact = expectedImpact
        self.timeline = timeline
    }
    
    enum RecommendationPriority: String, CaseIterable, Codable {
        case high = "high"
        case medium = "medium"
        case low = "low"
    }
}

// 財務健康報告
@Model
final class FinancialHealthReport {
    @Attribute(.unique) var id: UUID = UUID()
    var userId: UUID
    var score: FinancialHealthScore
    var metrics: FinancialHealthMetrics
    var recommendations: [FinancialHealthRecommendation]
    var createdAt: Date
    var updatedAt: Date
    
    // 關聯
    @Relationship(deleteRule: .nullify, inverse: \User.financialHealthReports) var user: User?
    
    init(userId: UUID, score: FinancialHealthScore, metrics: FinancialHealthMetrics, recommendations: [FinancialHealthRecommendation]) {
        self.userId = userId
        self.score = score
        self.metrics = metrics
        self.recommendations = recommendations
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // nonisolated 方法用於在非隔離上下文中訪問數據
    nonisolated func getScore() -> FinancialHealthScore {
        return score
    }
    
    nonisolated func getMetrics() -> FinancialHealthMetrics {
        return metrics
    }
    
    nonisolated func getRecommendations() -> [FinancialHealthRecommendation] {
        return recommendations
    }
}

// 財務健康計算器
class FinancialHealthCalculator {
    
    // 計算總體財務健康評分
    static func calculateOverallScore(from metrics: FinancialHealthMetrics) -> FinancialHealthScore {
        var dimensionScores: [FinancialHealthDimension: Int] = [:]
        
        // 收入穩定性評分
        dimensionScores[.income] = calculateIncomeScore(metrics)
        
        // 支出控制評分
        dimensionScores[.expenses] = calculateExpenseScore(metrics)
        
        // 儲蓄能力評分
        dimensionScores[.savings] = calculateSavingsScore(metrics)
        
        // 債務管理評分
        dimensionScores[.debt] = calculateDebtScore(metrics)
        
        // 投資成長評分
        dimensionScores[.investment] = calculateInvestmentScore(metrics)
        
        // 風險保護評分
        dimensionScores[.protection] = calculateProtectionScore(metrics)
        
        // 計算總體評分
        let overallScore = dimensionScores.values.reduce(0, +) / dimensionScores.count
        
        // 生成建議
        let recommendations = generateRecommendations(dimensionScores, metrics)
        
        return FinancialHealthScore(
            overall: overallScore,
            dimensions: dimensionScores,
            recommendations: recommendations
        )
    }
    
    // 收入穩定性評分
    private static func calculateIncomeScore(_ metrics: FinancialHealthMetrics) -> Int {
        var score = 50 // 基礎分數
        
        // 收入穩定性 (0-30分)
        score += Int(metrics.incomeStability * 30)
        
        // 收入成長率 (0-20分)
        if metrics.incomeGrowth > 0.05 { // 5%以上成長
            score += 20
        } else if metrics.incomeGrowth > 0 {
            score += 10
        }
        
        return min(100, max(0, score))
    }
    
    // 支出控制評分
    private static func calculateExpenseScore(_ metrics: FinancialHealthMetrics) -> Int {
        var score = 50
        
        // 支出收入比 (0-40分)
        if metrics.expenseRatio <= 0.5 { // 支出不超過收入50%
            score += 40
        } else if metrics.expenseRatio <= 0.7 {
            score += 20
        } else if metrics.expenseRatio <= 0.9 {
            score += 10
        }
        
        // 支出成長控制 (0-10分)
        if metrics.expenseGrowth <= 0.03 { // 支出成長不超過3%
            score += 10
        }
        
        return min(100, max(0, score))
    }
    
    // 儲蓄能力評分
    private static func calculateSavingsScore(_ metrics: FinancialHealthMetrics) -> Int {
        var score = 50
        
        // 儲蓄率 (0-30分)
        if metrics.savingsRate >= 0.2 { // 儲蓄率20%以上
            score += 30
        } else if metrics.savingsRate >= 0.1 {
            score += 20
        } else if metrics.savingsRate >= 0.05 {
            score += 10
        }
        
        // 緊急基金 (0-20分)
        let emergencyFundMonths = metrics.emergencyFund / metrics.monthlyExpenses
        if emergencyFundMonths >= 6 {
            score += 20
        } else if emergencyFundMonths >= 3 {
            score += 10
        }
        
        return min(100, max(0, score))
    }
    
    // 債務管理評分
    private static func calculateDebtScore(_ metrics: FinancialHealthMetrics) -> Int {
        var score = 50
        
        // 債務收入比 (0-30分)
        if metrics.debtToIncomeRatio <= 0.2 { // 債務不超過收入20%
            score += 30
        } else if metrics.debtToIncomeRatio <= 0.4 {
            score += 20
        } else if metrics.debtToIncomeRatio <= 0.6 {
            score += 10
        }
        
        // 債務償還比率 (0-20分)
        if metrics.debtServiceRatio <= 0.1 { // 債務償還不超過收入10%
            score += 20
        } else if metrics.debtServiceRatio <= 0.2 {
            score += 10
        }
        
        return min(100, max(0, score))
    }
    
    // 投資成長評分
    private static func calculateInvestmentScore(_ metrics: FinancialHealthMetrics) -> Int {
        var score = 50
        
        // 投資報酬率 (0-30分)
        if metrics.investmentReturn >= 0.08 { // 8%以上報酬
            score += 30
        } else if metrics.investmentReturn >= 0.05 {
            score += 20
        } else if metrics.investmentReturn >= 0.03 {
            score += 10
        }
        
        // 投資組合分散度 (0-20分)
        score += Int(metrics.portfolioDiversification * 20)
        
        return min(100, max(0, score))
    }
    
    // 風險保護評分
    private static func calculateProtectionScore(_ metrics: FinancialHealthMetrics) -> Int {
        var score = 50
        
        // 保險覆蓋率 (0-30分)
        score += Int(metrics.insuranceCoverage * 30)
        
        // 風險保護度 (0-20分)
        score += Int(metrics.riskProtection * 20)
        
        return min(100, max(0, score))
    }
    
    // 生成改善建議
    private static func generateRecommendations(_ scores: [FinancialHealthDimension: Int], _ metrics: FinancialHealthMetrics) -> [String] {
        var recommendations: [String] = []
        
        // 檢查是否有數據（如果所有指標都是0，說明沒有數據）
        let hasData = metrics.monthlyIncome > 0 || metrics.monthlyExpenses > 0 || 
                      metrics.totalInvestments > 0 || metrics.totalDebt > 0
        
        // 如果沒有數據，提供初始設置建議
        if !hasData {
            recommendations.append("recommendation.setup.initial_data")
            recommendations.append("recommendation.setup.add_transactions")
            return recommendations
        }
        
        // 根據各維度評分生成建議
        for (dimension, score) in scores {
            // 如果分數低於80，都提供改善建議
            if score < 80 {
                switch dimension {
                case .income:
                    if metrics.incomeStability < 0.8 || metrics.monthlyIncome <= 0 {
                        recommendations.append("recommendation.income.stability")
                    }
                    if metrics.incomeGrowth < 0.03 {
                        recommendations.append("recommendation.income.growth")
                    }
                    
                case .expenses:
                    if metrics.expenseRatio > 0.7 || metrics.monthlyExpenses <= 0 {
                        recommendations.append("recommendation.expenses.control")
                    }
                    if metrics.expenseGrowth > 0.1 {
                        recommendations.append("recommendation.expenses.tracking")
                    }
                    
                case .savings:
                    if metrics.savingsRate < 0.1 || metrics.monthlySavings <= 0 {
                        recommendations.append("recommendation.savings.rate")
                    }
                    if metrics.emergencyFund < metrics.monthlyExpenses * 3 {
                        recommendations.append("recommendation.savings.emergency")
                    }
                    
                case .debt:
                    if metrics.debtToIncomeRatio > 0.4 || metrics.totalDebt > 0 {
                        if metrics.debtToIncomeRatio > 0.4 {
                            recommendations.append("recommendation.debt.reduction")
                        } else {
                            recommendations.append("recommendation.debt.management")
                        }
                    }
                    
                case .investment:
                    if metrics.totalInvestments <= 0 {
                        recommendations.append("recommendation.investment.start")
                    } else if metrics.investmentReturn < 0.05 {
                        recommendations.append("recommendation.investment.optimization")
                    }
                    if metrics.portfolioDiversification < 0.6 {
                        recommendations.append("recommendation.investment.diversification")
                    }
                    
                case .protection:
                    if metrics.insuranceCoverage < 0.8 {
                        recommendations.append("recommendation.protection.insurance")
                    }
                    if metrics.riskProtection < 0.7 {
                        recommendations.append("recommendation.protection.risk")
                    }
                    if metrics.estatePlanning < 0.5 {
                        recommendations.append("recommendation.protection.estate")
                    }
                }
            }
        }
        
        // 如果沒有任何建議，表示財務狀況良好，提供維持建議
        if recommendations.isEmpty {
            recommendations.append("recommendation.maintain.current_state")
            recommendations.append("recommendation.maintain.review_regularly")
        }
        
        return recommendations
    }
}

