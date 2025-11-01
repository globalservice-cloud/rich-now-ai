//
//  InvestmentWatchlist.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/28.
//

import Foundation
import SwiftData
import SwiftUI

// 關注標的類型
enum WatchlistItemType: String, Codable, CaseIterable {
    case stock = "stock"           // 股票
    case fund = "fund"             // 基金
    case gold = "gold"             // 黃金
    case futures = "futures"       // 期貨
    case bond = "bond"             // 債券
    
    var displayName: String {
        switch self {
        case .stock: return "股票"
        case .fund: return "基金"
        case .gold: return "黃金"
        case .futures: return "期貨"
        case .bond: return "債券"
        }
    }
    
    var icon: String {
        switch self {
        case .stock: return "chart.line.uptrend.xyaxis"
        case .fund: return "chart.pie.fill"
        case .gold: return "bitcoinsign.circle.fill"
        case .futures: return "arrow.triangle.2.circlepath"
        case .bond: return "shield.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .stock: return .blue
        case .fund: return .green
        case .gold: return .yellow
        case .futures: return .orange
        case .bond: return .purple
        }
    }
}

// 關注標的
@Model
final class WatchlistItem {
    @Attribute(.unique) var id: UUID = UUID()
    var symbol: String              // 代碼（如：2330, TSM等）
    var name: String                // 名稱
    var type: String                // WatchlistItemType.rawValue
    var market: String              // 市場（如：TWSE, NYSE, TSE等）
    var currency: String            // 計價幣別
    var currentPrice: Double        // 當前價格
    var previousClose: Double       // 前收盤價
    var change: Double              // 漲跌
    var changePercentage: Double    // 漲跌幅
    var volume: Double              // 成交量
    var marketCap: Double?          // 市值
    var priceAlert: Double?         // 價格提醒（達到此價格時提醒）
    var isAlertEnabled: Bool        // 是否啟用價格提醒
    var notes: String?              // 備註
    var addedDate: Date             // 加入關注日期
    var lastUpdated: Date           // 最後更新時間
    
    // 關聯
    @Relationship(deleteRule: .nullify, inverse: \User.watchlistItems) var user: User?
    
    init(
        symbol: String,
        name: String,
        type: WatchlistItemType,
        market: String = "TWSE",
        currency: String = "TWD",
        priceAlert: Double? = nil
    ) {
        self.symbol = symbol
        self.name = name
        self.type = type.rawValue
        self.market = market
        self.currency = currency
        self.currentPrice = 0.0
        self.previousClose = 0.0
        self.change = 0.0
        self.changePercentage = 0.0
        self.volume = 0.0
        self.marketCap = nil
        self.priceAlert = priceAlert
        self.isAlertEnabled = priceAlert != nil
        self.notes = nil
        self.addedDate = Date()
        self.lastUpdated = Date()
    }
    
    var watchlistType: WatchlistItemType {
        get { WatchlistItemType(rawValue: type) ?? .stock }
        set { type = newValue.rawValue }
    }
    
    // 更新價格
    func updatePrice(_ price: Double, previousPrice: Double? = nil) {
        let prevPrice = previousPrice ?? previousClose
        self.previousClose = prevPrice
        self.currentPrice = price
        self.change = price - prevPrice
        self.changePercentage = prevPrice > 0 ? (change / prevPrice) * 100 : 0
        self.lastUpdated = Date()
    }
    
    // 檢查是否觸發價格提醒
    var isPriceAlertTriggered: Bool {
        guard let alert = priceAlert, isAlertEnabled else { return false }
        return currentPrice >= alert
    }
    
    // 是否上漲
    var isRising: Bool {
        return change > 0
    }
}

