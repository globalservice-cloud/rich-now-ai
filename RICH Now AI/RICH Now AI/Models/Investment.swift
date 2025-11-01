//
//  Investment.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import Foundation
import SwiftData
import SwiftUI

// 投資標的類型
enum InvestmentType: String, Codable, CaseIterable {
    case stock = "stock"           // 股票
    case etf = "etf"             // ETF
    case mutual_fund = "mutual_fund" // 共同基金
    case bond = "bond"           // 債券
    case crypto = "crypto"        // 加密貨幣
    case real_estate = "real_estate" // 不動產
    case commodity = "commodity"   // 商品
    case forex = "forex"         // 外匯
    case other = "other"         // 其他
    
    var displayName: String {
        switch self {
        case .stock: return "股票"
        case .etf: return "ETF"
        case .mutual_fund: return "共同基金"
        case .bond: return "債券"
        case .crypto: return "加密貨幣"
        case .real_estate: return "不動產"
        case .commodity: return "商品"
        case .forex: return "外匯"
        case .other: return "其他"
        }
    }
    
    var icon: String {
        switch self {
        case .stock: return "chart.line.uptrend.xyaxis"
        case .etf: return "chart.bar.fill"
        case .mutual_fund: return "chart.pie.fill"
        case .bond: return "shield.fill"
        case .crypto: return "bitcoinsign.circle.fill"
        case .real_estate: return "house.fill"
        case .commodity: return "cube.fill"
        case .forex: return "dollarsign.circle.fill"
        case .other: return "questionmark.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .stock: return .blue
        case .etf: return .green
        case .mutual_fund: return .purple
        case .bond: return .orange
        case .crypto: return .yellow
        case .real_estate: return .brown
        case .commodity: return .red
        case .forex: return .cyan
        case .other: return .gray
        }
    }
}

// 投資標的
@Model
final class Investment {
    // 基本資訊
    var symbol: String // 股票代碼或標的識別碼
    var name: String
    var type: String // InvestmentType.rawValue
    var currency: String // 計價幣別
    
    // 持有資訊
    var shares: Double // 持有股數/單位
    var averageCost: Double // 平均成本
    var totalCost: Double // 總成本
    var currentPrice: Double // 當前價格
    var currentValue: Double // 當前價值
    var riskLevelRaw: String // 風險等級

    // 績效指標
    var totalReturn: Double // 總報酬
    var totalReturnPercentage: Double // 總報酬率
    var dailyChange: Double // 日變動
    var dailyChangePercentage: Double // 日變動率
    
    // 時間戳記
    var purchaseDate: Date
    var lastUpdated: Date
    var createdAt: Date
    
    // 關聯
    @Relationship(deleteRule: .nullify, inverse: \User.investments) var user: User?
    @Relationship(deleteRule: .nullify, inverse: \InvestmentPortfolio.investments) var portfolio: InvestmentPortfolio?
    @Relationship(deleteRule: .cascade) var transactions: [InvestmentTransaction] = []
    
    init(symbol: String, name: String, type: InvestmentType, shares: Double, averageCost: Double, riskLevel: RiskLevel = .moderate, purchaseDate: Date = Date()) {
        self.symbol = symbol
        self.name = name
        self.type = type.rawValue
        self.currency = "TWD"
        self.shares = shares
        self.averageCost = averageCost
        self.totalCost = shares * averageCost
        self.currentPrice = averageCost
        self.currentValue = shares * averageCost
        self.totalReturn = 0
        self.totalReturnPercentage = 0
        self.dailyChange = 0
        self.dailyChangePercentage = 0
        self.purchaseDate = purchaseDate
        self.riskLevelRaw = riskLevel.rawValue
        self.lastUpdated = Date()
        self.createdAt = Date()
    }
    
    // 更新當前價格
    func updateCurrentPrice(_ newPrice: Double) {
        self.currentPrice = newPrice
        self.currentValue = shares * newPrice
        self.totalReturn = currentValue - totalCost
        self.totalReturnPercentage = totalCost > 0 ? (totalReturn / totalCost) * 100 : 0
        self.lastUpdated = Date()
    }
    
    // 計算日變動
    func calculateDailyChange(previousPrice: Double) {
        self.dailyChange = currentPrice - previousPrice
        self.dailyChangePercentage = previousPrice > 0 ? (dailyChange / previousPrice) * 100 : 0
    }
    
    // 添加投資交易
    func addTransaction(_ transaction: InvestmentTransaction) {
        self.transactions.append(transaction)
        updateHoldings()
    }
    
    // 更新持有資訊
    private func updateHoldings() {
        let totalShares = transactions.reduce(0) { $0 + $1.shares }
        let totalCost = transactions.reduce(0) { $0 + ($1.shares * $1.price) }
        
        self.shares = totalShares
        self.totalCost = totalCost
        self.averageCost = totalShares > 0 ? totalCost / totalShares : 0
        self.currentValue = shares * currentPrice
        self.totalReturn = currentValue - totalCost
        self.totalReturnPercentage = totalCost > 0 ? (totalReturn / totalCost) * 100 : 0
    }
    
    // 獲取投資類型枚舉
    func getInvestmentType() -> InvestmentType? {
        return InvestmentType(rawValue: type)
    }
    
    // 檢查是否為獲利
    var isProfitable: Bool {
        return totalReturn > 0
    }
    
    // 獲取投資天數
    var holdingDays: Int {
        let calendar = Calendar.current
        return calendar.dateComponents([.day], from: purchaseDate, to: Date()).day ?? 0
    }
    
    var riskLevel: RiskLevel {
        get { RiskLevel(rawValue: riskLevelRaw) ?? .moderate }
        set { riskLevelRaw = newValue.rawValue }
    }
}

// 投資交易記錄
@Model
final class InvestmentTransaction {
    // 交易類型
    var transactionType: String // "buy", "sell", "dividend", "split"
    var symbol: String
    var shares: Double
    var price: Double
    var totalAmount: Double
    var date: Date
    var fees: Double // 手續費
    var notes: String?
    
    // 關聯
    @Relationship(deleteRule: .nullify, inverse: \Investment.transactions) var investment: Investment?
    
    init(transactionType: String, symbol: String, shares: Double, price: Double, date: Date = Date(), fees: Double = 0, notes: String? = nil) {
        self.transactionType = transactionType
        self.symbol = symbol
        self.shares = shares
        self.price = price
        self.totalAmount = shares * price
        self.date = date
        self.fees = fees
        self.notes = notes
    }
    
    var type: InvestmentTransactionType {
        return InvestmentTransactionType(rawValue: transactionType) ?? .buy
    }
}

// InvestmentPortfolio 類別已移至 InvestmentPortfolio.swift
