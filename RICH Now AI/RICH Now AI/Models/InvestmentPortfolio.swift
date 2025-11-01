//
//  InvestmentPortfolio.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import Foundation
import SwiftData
import SwiftUI

// InvestmentType 已移至 Models/Investment.swift

// 投資風險等級
enum RiskLevel: String, CaseIterable, Codable {
    case conservative = "conservative" // 保守型
    case moderate = "moderate"         // 穩健型
    case aggressive = "aggressive"     // 積極型
    case veryAggressive = "very_aggressive" // 非常積極型
    
    var displayName: String {
        return LocalizationManager.shared.localizedString("investment.risk.\(self.rawValue)")
    }
    
    var description: String {
        return LocalizationManager.shared.localizedString("investment.risk.\(self.rawValue).description")
    }
    
    var color: Color {
        switch self {
        case .conservative: return .green
        case .moderate: return .blue
        case .aggressive: return .orange
        case .veryAggressive: return .red
        }
    }
}

// 投資交易類型
enum InvestmentTransactionType: String, CaseIterable, Codable {
    case buy = "buy"           // 買入
    case sell = "sell"         // 賣出
    case dividend = "dividend" // 股息
    case interest = "interest" // 利息
    case split = "split"       // 股票分割
    case merger = "merger"     // 合併
    case spinOff = "spin_off"  // 分拆
    
    var displayName: String {
        return LocalizationManager.shared.localizedString("investment.transaction.\(self.rawValue)")
    }
    
    var icon: String {
        switch self {
        case .buy: return "plus.circle"
        case .sell: return "minus.circle"
        case .dividend: return "dollarsign.circle"
        case .interest: return "percent"
        case .split: return "arrow.triangle.2.circlepath"
        case .merger: return "arrow.merge"
        case .spinOff: return "arrow.branch"
        }
    }
}

// 投資組合模型
@Model
final class InvestmentPortfolio {
    @Attribute(.unique) var id: UUID = UUID()
    var name: String
    var portfolioDescription: String?
    var totalValue: Double
    var totalCost: Double
    var totalGainLoss: Double
    var totalGainLossPercentage: Double
    var riskLevel: RiskLevel
    var createdAt: Date
    var updatedAt: Date
    
    // 關聯
    @Relationship(deleteRule: .cascade) var investments: [Investment]
    @Relationship(deleteRule: .nullify, inverse: \User.investmentPortfolios) var user: User?
    
    init(name: String, description: String? = nil, riskLevel: RiskLevel = .moderate) {
        self.name = name
        self.portfolioDescription = description
        self.totalValue = 0.0
        self.totalCost = 0.0
        self.totalGainLoss = 0.0
        self.totalGainLossPercentage = 0.0
        self.riskLevel = riskLevel
        self.createdAt = Date()
        self.updatedAt = Date()
        self.investments = []
    }
    
    // 計算總價值
    func calculateTotalValue() {
        totalValue = investments.reduce(0) { $0 + $1.currentValue }
        totalCost = investments.reduce(0) { $0 + $1.totalCost }
        totalGainLoss = totalValue - totalCost
        totalGainLossPercentage = totalCost > 0 ? (totalGainLoss / totalCost) * 100 : 0
        updatedAt = Date()
    }
    
    // 資產配置
    var assetAllocation: [InvestmentType: Double] {
        var allocation: [InvestmentType: Double] = [:]
        for investment in investments {
            let percentage = totalValue > 0 ? (investment.currentValue / totalValue) * 100 : 0
            if let investmentType = InvestmentType(rawValue: investment.type) {
                allocation[investmentType, default: 0] += percentage
            }
        }
        return allocation
    }
    
    // 更新統計數據
    func updateStatistics() {
        calculateTotalValue()
    }
    
    // 獲取總回報
    var totalReturn: Double {
        return totalGainLoss
    }
    
    // 獲取總回報百分比
    var totalReturnPercentage: Double {
        return totalGainLossPercentage
    }
    
    // 獲取日變化
    var dailyChange: Double {
        // 簡化實現，實際應該計算前一天的變化
        return totalGainLoss * 0.01
    }
    
    // 獲取日變化百分比
    var dailyChangePercentage: Double {
        // 簡化實現，實際應該計算前一天的變化百分比
        return totalGainLossPercentage * 0.01
    }
    
    // 獲取資產配置
    func getAssetAllocation() -> [InvestmentType: Double] {
        return assetAllocation
    }
    
    // 風險評估
    var riskScore: Double {
        let riskWeights: [RiskLevel: Double] = [
            .conservative: 1.0,
            .moderate: 2.0,
            .aggressive: 3.0,
            .veryAggressive: 4.0
        ]
        
        let weightedRisk = investments.reduce(into: 0.0) { total, investment in
            let weight = investment.currentValue / totalValue
            total += (weight * (riskWeights[riskLevel] ?? 2.0))
        }
        
        return totalValue > 0 ? weightedRisk : 0
    }
}

// Investment 類別已移至 Investment.swift

// InvestmentTransaction 類別已移至 Investment.swift

// 投資績效分析
struct InvestmentPerformance {
    let totalReturn: Double         // 總報酬率
    let annualizedReturn: Double    // 年化報酬率
    let volatility: Double          // 波動率
    let sharpeRatio: Double         // 夏普比率
    let maxDrawdown: Double         // 最大回撤
    let beta: Double                // 貝塔值
    let alpha: Double               // 阿爾法值
    
    var riskLevel: RiskLevel {
        if volatility < 0.1 {
            return .conservative
        } else if volatility < 0.2 {
            return .moderate
        } else if volatility < 0.3 {
            return .aggressive
        } else {
            return .veryAggressive
        }
    }
}

// 投資組合分析
struct PortfolioAnalysis {
    let diversificationScore: Double    // 分散化評分
    let riskScore: Double               // 風險評分
    let performanceScore: Double        // 績效評分
    let recommendations: [String]       // 建議
    let rebalancingNeeded: Bool         // 是否需要再平衡
    let targetAllocation: [InvestmentType: Double] // 目標配置
    let currentAllocation: [InvestmentType: Double] // 當前配置
}

// 投資組合計算器
class PortfolioCalculator {
    
    // 計算投資組合績效
    static func calculatePerformance(for portfolio: InvestmentPortfolio) -> InvestmentPerformance {
        let totalReturn = portfolio.totalGainLossPercentage / 100
        let annualizedReturn = calculateAnnualizedReturn(portfolio: portfolio)
        let volatility = calculateVolatility(portfolio: portfolio)
        let sharpeRatio = calculateSharpeRatio(returnRate: annualizedReturn, volatility: volatility)
        let maxDrawdown = calculateMaxDrawdown(portfolio: portfolio)
        let beta = calculateBeta(portfolio: portfolio)
        let alpha = calculateAlpha(portfolio: portfolio, beta: beta)
        
        return InvestmentPerformance(
            totalReturn: totalReturn,
            annualizedReturn: annualizedReturn,
            volatility: volatility,
            sharpeRatio: sharpeRatio,
            maxDrawdown: maxDrawdown,
            beta: beta,
            alpha: alpha
        )
    }
    
    // 分析投資組合
    static func analyzePortfolio(_ portfolio: InvestmentPortfolio) -> PortfolioAnalysis {
        let diversificationScore = calculateDiversificationScore(portfolio)
        let riskScore = portfolio.riskScore
        let performanceScore = calculatePerformanceScore(portfolio)
        let recommendations = generateRecommendations(portfolio)
        let rebalancingNeeded = checkRebalancingNeeded(portfolio)
        let targetAllocation = getTargetAllocation(for: portfolio.riskLevel)
        let currentAllocation = portfolio.assetAllocation
        
        return PortfolioAnalysis(
            diversificationScore: diversificationScore,
            riskScore: riskScore,
            performanceScore: performanceScore,
            recommendations: recommendations,
            rebalancingNeeded: rebalancingNeeded,
            targetAllocation: targetAllocation,
            currentAllocation: currentAllocation
        )
    }
    
    // 計算年化報酬率
    private static func calculateAnnualizedReturn(portfolio: InvestmentPortfolio) -> Double {
        let daysSinceCreation = Calendar.current.dateComponents([.day], from: portfolio.createdAt, to: Date()).day ?? 1
        let years = Double(daysSinceCreation) / 365.0
        
        guard years > 0 else { return 0 }
        
        let totalReturn = portfolio.totalGainLossPercentage / 100
        return pow(1 + totalReturn, 1 / years) - 1
    }
    
    // 計算波動率
    private static func calculateVolatility(portfolio: InvestmentPortfolio) -> Double {
        // 簡化計算，實際應該使用歷史價格數據
        let baseVolatility: [RiskLevel: Double] = [
            .conservative: 0.05,
            .moderate: 0.12,
            .aggressive: 0.20,
            .veryAggressive: 0.30
        ]
        
        return baseVolatility[portfolio.riskLevel] ?? 0.12
    }
    
    // 計算夏普比率
    private static func calculateSharpeRatio(returnRate: Double, volatility: Double) -> Double {
        let riskFreeRate = 0.02 // 假設無風險利率為2%
        return volatility > 0 ? (returnRate - riskFreeRate) / volatility : 0
    }
    
    // 計算最大回撤
    private static func calculateMaxDrawdown(portfolio: InvestmentPortfolio) -> Double {
        // 簡化計算，實際應該使用歷史數據
        return portfolio.riskLevel == .veryAggressive ? 0.25 : 0.15
    }
    
    // 計算貝塔值
    private static func calculateBeta(portfolio: InvestmentPortfolio) -> Double {
        let betaByRisk: [RiskLevel: Double] = [
            .conservative: 0.5,
            .moderate: 1.0,
            .aggressive: 1.3,
            .veryAggressive: 1.5
        ]
        
        return betaByRisk[portfolio.riskLevel] ?? 1.0
    }
    
    // 計算阿爾法值
    private static func calculateAlpha(portfolio: InvestmentPortfolio, beta: Double) -> Double {
        let marketReturn = 0.08 // 假設市場報酬率為8%
        let riskFreeRate = 0.02
        let expectedReturn = riskFreeRate + beta * (marketReturn - riskFreeRate)
        let actualReturn = calculateAnnualizedReturn(portfolio: portfolio)
        
        return actualReturn - expectedReturn
    }
    
    // 計算分散化評分
    private static func calculateDiversificationScore(_ portfolio: InvestmentPortfolio) -> Double {
        let allocation = portfolio.assetAllocation
        let numberOfTypes = allocation.count
        let maxAllocation = allocation.values.max() ?? 0
        
        // 分散化評分：類型數量越多，最大配置越小，評分越高
        let typeScore = min(1.0, Double(numberOfTypes) / 6.0) // 最多6種類型
        let concentrationScore = max(0, 1.0 - (maxAllocation / 100.0))
        
        return (typeScore + concentrationScore) / 2.0
    }
    
    // 計算績效評分
    private static func calculatePerformanceScore(_ portfolio: InvestmentPortfolio) -> Double {
        let returnScore = min(1.0, max(0, portfolio.totalGainLossPercentage / 20.0)) // 20%為滿分
        let riskAdjustedScore = portfolio.totalGainLossPercentage / max(1.0, portfolio.riskScore * 10)
        
        return (returnScore + riskAdjustedScore) / 2.0
    }
    
    // 生成建議
    private static func generateRecommendations(_ portfolio: InvestmentPortfolio) -> [String] {
        var recommendations: [String] = []
        
        let allocation = portfolio.assetAllocation
        
        // 檢查過度集中
        if let maxAllocation = allocation.values.max(), maxAllocation > 50 {
            recommendations.append(LocalizationManager.shared.localizedString("investment.recommendation.diversify"))
        }
        
        // 檢查風險過高
        if portfolio.riskScore > 3.0 {
            recommendations.append(LocalizationManager.shared.localizedString("investment.recommendation.reduce_risk"))
        }
        
        // 檢查績效
        if portfolio.totalGainLossPercentage < -10 {
            recommendations.append(LocalizationManager.shared.localizedString("investment.recommendation.review_strategy"))
        }
        
        return recommendations
    }
    
    // 檢查是否需要再平衡
    private static func checkRebalancingNeeded(_ portfolio: InvestmentPortfolio) -> Bool {
        let targetAllocation = getTargetAllocation(for: portfolio.riskLevel)
        let currentAllocation = portfolio.assetAllocation
        
        for (type, targetPercentage) in targetAllocation {
            let currentPercentage = currentAllocation[type] ?? 0
            if abs(currentPercentage - targetPercentage) > 5 { // 偏差超過5%
                return true
            }
        }
        
        return false
    }
    
    // 獲取目標配置
    private static func getTargetAllocation(for riskLevel: RiskLevel) -> [InvestmentType: Double] {
        switch riskLevel {
        case .conservative:
            return [
                .bond: 60,
                .stock: 30,
                .mutual_fund: 10
            ]
        case .moderate:
            return [
                .stock: 50,
                .bond: 30,
                .mutual_fund: 15,
                .etf: 5
            ]
        case .aggressive:
            return [
                .stock: 60,
                .etf: 20,
                .mutual_fund: 15,
                .crypto: 5
            ]
        case .veryAggressive:
            return [
                .stock: 40,
                .crypto: 30,
                .etf: 20,
                .commodity: 10
            ]
        }
    }
}

