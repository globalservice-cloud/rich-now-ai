//
//  InvestmentPortfolioManager.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import Foundation
import SwiftData
import Combine

// 投資組合管理器
@MainActor
class InvestmentPortfolioManager: ObservableObject {
    static let shared = InvestmentPortfolioManager()
    
    @Published var portfolios: [InvestmentPortfolio] = []
    @Published var currentPortfolio: InvestmentPortfolio?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var marketData: [String: MarketData] = [:]
    
    private var modelContext: ModelContext?
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // ModelContext 將從外部注入
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadPortfolios()
    }
    
    // MARK: - 投資組合管理
    
    func loadPortfolios() {
        guard let modelContext = modelContext else {
            errorMessage = "ModelContext not initialized"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let descriptor = FetchDescriptor<InvestmentPortfolio>()
            let fetchedPortfolios = try modelContext.fetch(descriptor)
            
            self.portfolios = fetchedPortfolios
            self.currentPortfolio = fetchedPortfolios.first
            
            // 更新所有投資組合的數據
            for portfolio in portfolios {
                updatePortfolioData(portfolio)
            }
            
            self.isLoading = false
        } catch {
            self.errorMessage = "Failed to load portfolios: \(error.localizedDescription)"
            self.isLoading = false
        }
    }
    
    func createPortfolio(name: String, description: String? = nil, riskLevel: RiskLevel = .moderate) -> InvestmentPortfolio {
        let portfolio = InvestmentPortfolio(name: name, description: description, riskLevel: riskLevel)
        
        guard let modelContext = modelContext else {
            errorMessage = "ModelContext not initialized"
            return portfolio
        }
        
        modelContext.insert(portfolio)
        
        do {
            try modelContext.save()
            portfolios.append(portfolio)
            currentPortfolio = portfolio
        } catch {
            errorMessage = "Failed to create portfolio: \(error.localizedDescription)"
        }
        
        return portfolio
    }
    
    func updatePortfolio(_ portfolio: InvestmentPortfolio) {
        portfolio.updatedAt = Date()
        portfolio.calculateTotalValue()
        
        guard let modelContext = modelContext else {
            errorMessage = "ModelContext not initialized"
            return
        }
        
        do {
            try modelContext.save()
        } catch {
            errorMessage = "Failed to update portfolio: \(error.localizedDescription)"
        }
    }
    
    func deletePortfolio(_ portfolio: InvestmentPortfolio) {
        guard let modelContext = modelContext else {
            errorMessage = "ModelContext not initialized"
            return
        }
        
        modelContext.delete(portfolio)
        
        do {
            try modelContext.save()
            portfolios.removeAll { $0.id == portfolio.id }
            if currentPortfolio?.id == portfolio.id {
                currentPortfolio = portfolios.first
            }
        } catch {
            errorMessage = "Failed to delete portfolio: \(error.localizedDescription)"
        }
    }
    
    // MARK: - 投資管理
    
    func addInvestment(to portfolio: InvestmentPortfolio, symbol: String, name: String, type: InvestmentType, shares: Double, averageCost: Double, riskLevel: RiskLevel = .moderate) -> Investment {
        let investment = Investment(symbol: symbol, name: name, type: type, shares: shares, averageCost: averageCost, riskLevel: riskLevel)
        investment.portfolio = portfolio
        investment.riskLevel = riskLevel
        
        guard let modelContext = modelContext else {
            errorMessage = "ModelContext not initialized"
            return investment
        }
        
        modelContext.insert(investment)
        
        do {
            try modelContext.save()
            portfolio.investments.append(investment)
            updatePortfolioData(portfolio)
        } catch {
            errorMessage = "Failed to add investment: \(error.localizedDescription)"
        }
        
        return investment
    }
    
    func updateInvestment(_ investment: Investment) {
        // 更新投資數據
        investment.currentValue = investment.shares * investment.currentPrice
        
        if let portfolio = investment.portfolio {
            updatePortfolioData(portfolio)
        }
        
        guard let modelContext = modelContext else {
            errorMessage = "ModelContext not initialized"
            return
        }
        
        do {
            try modelContext.save()
        } catch {
            errorMessage = "Failed to update investment: \(error.localizedDescription)"
        }
    }
    
    func deleteInvestment(_ investment: Investment) {
        if let portfolio = investment.portfolio {
            portfolio.investments.removeAll { $0.id == investment.id }
            updatePortfolioData(portfolio)
        }
        
        guard let modelContext = modelContext else {
            errorMessage = "ModelContext not initialized"
            return
        }
        
        modelContext.delete(investment)
        
        do {
            try modelContext.save()
        } catch {
            errorMessage = "Failed to delete investment: \(error.localizedDescription)"
        }
    }
    
    // MARK: - 交易管理
    
    func addTransaction(to investment: Investment, type: InvestmentTransactionType, shares: Double, price: Double, amount: Double, fees: Double = 0, date: Date = Date(), notes: String? = nil) {
        let transaction = InvestmentTransaction(
            transactionType: type.rawValue,
            symbol: investment.symbol,
            shares: shares,
            price: price,
            date: date,
            fees: fees,
            notes: notes
        )
        
        transaction.investment = investment
        
        guard let modelContext = modelContext else {
            errorMessage = "ModelContext not initialized"
            return
        }
        
        modelContext.insert(transaction)
        
        // 更新投資數據
        investment.addTransaction(transaction)
        updateInvestment(investment)
    }
    
    // MARK: - 數據更新
    
    func updatePortfolioData(_ portfolio: InvestmentPortfolio) {
        // 更新所有投資的當前價格
        for investment in portfolio.investments {
            updateInvestmentPrice(investment)
        }
        
        // 重新計算投資組合總值
        portfolio.calculateTotalValue()
        
        guard let modelContext = modelContext else {
            errorMessage = "ModelContext not initialized"
            return
        }
        
        do {
            try modelContext.save()
        } catch {
            errorMessage = "Failed to update portfolio data: \(error.localizedDescription)"
        }
    }
    
    func updateInvestmentPrice(_ investment: Investment) {
        // 這裡應該從市場數據API獲取實時價格
        // 暫時使用模擬數據
        let simulatedPrice = generateSimulatedPrice(for: investment)
        investment.currentPrice = simulatedPrice
        // 更新投資數據
        investment.currentValue = investment.shares * investment.currentPrice
    }
    
    private func generateSimulatedPrice(for investment: Investment) -> Double {
        // 模擬價格變動
        let basePrice = investment.averageCost > 0 ? investment.averageCost : 100.0
        let volatility = getVolatility(for: InvestmentType(rawValue: investment.type) ?? .other)
        let randomChange = Double.random(in: -volatility...volatility)
        
        return basePrice * (1 + randomChange)
    }
    
    private func getVolatility(for type: InvestmentType) -> Double {
        switch type {
        case .stock: return 0.05
        case .bond: return 0.02
        case .mutual_fund: return 0.03
        case .etf: return 0.04
        case .crypto: return 0.15
        case .real_estate: return 0.01
        case .commodity: return 0.08
        case .forex: return 0.12
        case .other: return 0.05
        }
    }
    
    // MARK: - 分析功能
    
    func getPortfolioAnalysis(_ portfolio: InvestmentPortfolio) -> PortfolioAnalysis {
        return PortfolioCalculator.analyzePortfolio(portfolio)
    }
    
    func getInvestmentPerformance(_ investment: Investment) -> InvestmentPerformance {
        // 這裡應該使用歷史數據計算實際績效
        // 暫時返回模擬數據
        return InvestmentPerformance(
            totalReturn: investment.totalReturnPercentage / 100,
            annualizedReturn: 0.08,
            volatility: 0.12,
            sharpeRatio: 0.5,
            maxDrawdown: 0.15,
            beta: 1.0,
            alpha: 0.02
        )
    }
    
    // MARK: - 市場數據
    
    func fetchMarketData(for symbols: [String]) async {
        // 這裡應該從實際的市場數據API獲取數據
        // 暫時使用模擬數據
        for symbol in symbols {
            let marketData = MarketData(
                symbol: symbol,
                price: Double.random(in: 50...200),
                change: Double.random(in: -5...5),
                changePercentage: Double.random(in: -0.1...0.1),
                volume: Int.random(in: 1000000...10000000),
                marketCap: Double.random(in: 1000000000...100000000000),
                lastUpdated: Date()
            )
            
            self.marketData[symbol] = marketData
        }
    }
    
    // MARK: - 再平衡建議
    
    func getRebalancingRecommendations(for portfolio: InvestmentPortfolio) -> [RebalancingRecommendation] {
        let analysis = getPortfolioAnalysis(portfolio)
        var recommendations: [RebalancingRecommendation] = []
        
        for (type, currentPercentage) in analysis.currentAllocation {
            if let targetPercentage = analysis.targetAllocation[type] {
                let difference = currentPercentage - targetPercentage
                
                if abs(difference) > 5 { // 偏差超過5%
                    let recommendation = RebalancingRecommendation(
                        investmentType: type,
                        currentPercentage: currentPercentage,
                        targetPercentage: targetPercentage,
                        difference: difference,
                        action: difference > 0 ? .reduce : .increase
                    )
                    recommendations.append(recommendation)
                }
            }
        }
        
        return recommendations.sorted { abs($0.difference) > abs($1.difference) }
    }
}

// 市場數據模型
struct MarketData {
    let symbol: String
    let price: Double
    let change: Double
    let changePercentage: Double
    let volume: Int
    let marketCap: Double
    let lastUpdated: Date
}

// 再平衡建議
struct RebalancingRecommendation {
    let investmentType: InvestmentType
    let currentPercentage: Double
    let targetPercentage: Double
    let difference: Double
    let action: RebalancingAction
    
    enum RebalancingAction {
        case increase
        case reduce
        
        var displayName: String {
            switch self {
            case .increase:
                return LocalizationManager.shared.localizedString("investment.rebalancing.increase")
            case .reduce:
                return LocalizationManager.shared.localizedString("investment.rebalancing.reduce")
            }
        }
    }
}
