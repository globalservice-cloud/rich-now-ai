//
//  WatchlistManager.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/28.
//

import Foundation
import SwiftData
import Combine
import os.log

// 市場數據服務協議
protocol MarketDataService {
    func fetchPrice(symbol: String, type: WatchlistItemType, market: String) async throws -> Double
    func fetchMarketData(symbol: String, type: WatchlistItemType, market: String) async throws -> WatchlistMarketData
}

// 關注列表市場數據結構
struct WatchlistMarketData {
    let symbol: String
    let name: String
    let currentPrice: Double
    let previousClose: Double
    let change: Double
    let changePercentage: Double
    let volume: Double
    let marketCap: Double?
    let timestamp: Date
}

// 關注列表管理器
@MainActor
class WatchlistManager: ObservableObject {
    static let shared = WatchlistManager()
    
    @Published var watchlistItems: [WatchlistItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var lastUpdateTime: Date?
    
    private var modelContext: ModelContext?
    private var cancellables = Set<AnyCancellable>()
    private var updateTimer: Timer?
    private var marketDataService: MarketDataService?
    private let logger = Logger(subsystem: "com.richnowai", category: "WatchlistManager")
    
    private init() {
        setupAutoUpdate()
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadWatchlist()
    }
    
    func setMarketDataService(_ service: MarketDataService) {
        self.marketDataService = service
    }
    
    // MARK: - 關注列表管理
    
    func loadWatchlist() {
        guard let modelContext = modelContext else {
            errorMessage = "ModelContext not initialized"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let descriptor = FetchDescriptor<WatchlistItem>(
                sortBy: [SortDescriptor(\.addedDate, order: .reverse)]
            )
            let items = try modelContext.fetch(descriptor)
            
            self.watchlistItems = items
            self.isLoading = false
            
            // 自動更新價格
            Task {
                await updateAllPrices()
            }
        } catch {
            self.errorMessage = "Failed to load watchlist: \(error.localizedDescription)"
            self.isLoading = false
        }
    }
    
    func addToWatchlist(
        symbol: String,
        name: String,
        type: WatchlistItemType,
        market: String = "TWSE",
        currency: String = "TWD",
        priceAlert: Double? = nil
    ) {
        guard let modelContext = modelContext else {
            errorMessage = "ModelContext not initialized"
            return
        }
        
        // 檢查是否已經存在
        let existingItem = watchlistItems.first { $0.symbol == symbol && $0.market == market }
        if existingItem != nil {
            errorMessage = "此標的已在關注列表中"
            return
        }
        
        let item = WatchlistItem(
            symbol: symbol,
            name: name,
            type: type,
            market: market,
            currency: currency,
            priceAlert: priceAlert
        )
        
        modelContext.insert(item)
        
        do {
            try modelContext.save()
            watchlistItems.append(item)
            
            // 立即更新價格
            Task {
                await updatePrice(for: item)
            }
        } catch {
            errorMessage = "Failed to add to watchlist: \(error.localizedDescription)"
        }
    }
    
    func removeFromWatchlist(_ item: WatchlistItem) {
        guard let modelContext = modelContext else {
            errorMessage = "ModelContext not initialized"
            return
        }
        
        modelContext.delete(item)
        
        do {
            try modelContext.save()
            watchlistItems.removeAll { $0.id == item.id }
        } catch {
            errorMessage = "Failed to remove from watchlist: \(error.localizedDescription)"
        }
    }
    
    func updatePrice(for item: WatchlistItem) async {
        guard let service = marketDataService else {
            // 沒有服務時，使用模擬數據
            let mockPrice = Double.random(in: 50...200)
            item.updatePrice(mockPrice, previousPrice: item.currentPrice)
            return
        }
        
        do {
            let data = try await service.fetchMarketData(
                symbol: item.symbol,
                type: item.watchlistType,
                market: item.market
            )
            
            item.updatePrice(data.currentPrice, previousPrice: data.previousClose)
            
            // 檢查價格提醒
            if item.isPriceAlertTriggered {
                let priceString = String(format: "%.2f", item.currentPrice)
                logger.info("價格提醒觸發: \(item.symbol) 當前價格: \(priceString)")
                // TODO: 發送本地通知給用戶
            }
            
            // 保存更新
            try await saveContext()
            
        } catch {
            errorMessage = "Failed to update price for \(item.symbol): \(error.localizedDescription)"
        }
    }
    
    func updateAllPrices() async {
        guard !watchlistItems.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        
        await withTaskGroup(of: Void.self) { group in
            for item in watchlistItems {
                group.addTask {
                    await self.updatePrice(for: item)
                }
            }
        }
        
        isLoading = false
        lastUpdateTime = Date()
        
        // 保存更新
        try? await saveContext()
    }
    
    private func saveContext() async throws {
        guard let modelContext = modelContext else { return }
        try modelContext.save()
    }
    
    // MARK: - 自動更新
    
    private func setupAutoUpdate() {
        // 每5分鐘自動更新一次價格
        updateTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.updateAllPrices()
            }
        }
    }
    
    deinit {
        updateTimer?.invalidate()
    }
}

// MARK: - 模擬市場數據服務（開發階段使用）

class MockMarketDataService: MarketDataService {
    func fetchPrice(symbol: String, type: WatchlistItemType, market: String) async throws -> Double {
        // 模擬延遲
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
        
        // 返回模擬價格
        return Double.random(in: 50...200)
    }
    
    func fetchMarketData(symbol: String, type: WatchlistItemType, market: String) async throws -> WatchlistMarketData {
        try await Task.sleep(nanoseconds: 500_000_000)
        
        let price = Double.random(in: 50...200)
        let previousClose = price * Double.random(in: 0.95...1.05)
        let change = price - previousClose
        let changePercentage = (change / previousClose) * 100
        
        return WatchlistMarketData(
            symbol: symbol,
            name: "Mock \(symbol)",
            currentPrice: price,
            previousClose: previousClose,
            change: change,
            changePercentage: changePercentage,
            volume: Double.random(in: 1000...100000),
            marketCap: price * Double.random(in: 1000000...10000000),
            timestamp: Date()
        )
    }
}

