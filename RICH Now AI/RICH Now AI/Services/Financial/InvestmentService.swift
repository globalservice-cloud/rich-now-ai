//
//  InvestmentService.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import Foundation
import Combine
import SwiftData
import NaturalLanguage
import os.log

// MarketData 已移至 InvestmentPortfolioManager.swift

// 投資建議
struct InvestmentAdvice: Codable {
    let symbol: String
    let action: String // "buy", "sell", "hold"
    let confidence: Double
    let reason: String
    let targetPrice: Double?
    let stopLoss: Double?
    let timeHorizon: String
    let riskLevel: String
}

// PortfolioAnalysis 已移至 Models/InvestmentPortfolio.swift

@MainActor
class InvestmentService: ObservableObject {
    static let shared = InvestmentService()
    
    private let openAIService = OpenAIService.shared
    private let aiProcessingRouter = AIProcessingRouter.shared
    private let naturalLanguageProcessor = NaturalLanguageProcessor.shared
    private let settingsManager = SettingsManager.shared
    private let performanceMonitor = AIPerformanceMonitor.shared
    private let logger = Logger(subsystem: "com.richnowai", category: "InvestmentService")
    
    @Published var marketData: [String: MarketData] = [:]
    @Published var isLoading: Bool = false
    @Published var lastUpdate: Date?
    @Published var currentProcessingMethod: String = "未知"
    @Published var isOfflineMode: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupNetworkMonitoring()
    }
    
    // MARK: - 市場數據更新
    
    func updateMarketData(for symbols: [String]) async throws {
        isLoading = true
        defer { isLoading = false }
        
        // 這裡會整合真實的金融 API（如 Yahoo Finance, Alpha Vantage 等）
        // 目前使用模擬數據
        for symbol in symbols {
            let mockData = generateMockMarketData(for: symbol)
            marketData[symbol] = mockData
        }
        
        lastUpdate = Date()
    }
    
    // MARK: - 投資組合分析
    
    func analyzePortfolio(_ portfolio: InvestmentPortfolio) async throws -> PortfolioAnalysis {
        // 更新投資標的的市場數據
        let symbols = portfolio.investments.map { $0.symbol }
        try await updateMarketData(for: symbols)
        
        // 更新投資標的的當前價格
        for investment in portfolio.investments {
            if let data = marketData[investment.symbol] {
                investment.updateCurrentPrice(data.price)
            }
        }
        
        // 重新計算投資組合統計
        portfolio.updateStatistics()
        
        // 生成 AI 投資建議
        let advice = try await generateInvestmentAdvice(portfolio: portfolio)
        
        return PortfolioAnalysis(
            diversificationScore: calculateDiversificationScore(portfolio: portfolio),
            riskScore: calculateRiskScore(portfolio: portfolio),
            performanceScore: calculatePerformanceScore(portfolio: portfolio),
            recommendations: advice.map { $0.reason },
            rebalancingNeeded: calculateRebalancingNeeded(portfolio: portfolio),
            targetAllocation: getTargetAllocation(portfolio: portfolio),
            currentAllocation: portfolio.getAssetAllocation()
        )
    }
    
    // MARK: - 輔助方法
    
    private func calculatePerformanceScore(portfolio: InvestmentPortfolio) -> Double {
        // 簡化的績效評分計算
        return portfolio.totalReturnPercentage / 100.0
    }
    
    private func calculateRebalancingNeeded(portfolio: InvestmentPortfolio) -> Bool {
        // 簡化的再平衡判斷
        return false
    }
    
    private func getTargetAllocation(portfolio: InvestmentPortfolio) -> [InvestmentType: Double] {
        // 簡化的目標配置
        return portfolio.getAssetAllocation()
    }
    
    // MARK: - 網路監控
    
    private func setupNetworkMonitoring() {
        NetworkMonitor.shared.$isConnected
            .sink { [weak self] isConnected in
                self?.isOfflineMode = !isConnected
            }
            .store(in: &cancellables)
    }
    
    // MARK: - AI 投資建議
    
    func generateInvestmentAdvice(portfolio: InvestmentPortfolio) async throws -> [InvestmentAdvice] {
        currentProcessingMethod = "處理中..."
        
        // 使用智能 AI 處理路由器
        let result = try await generateAdviceWithIntelligentRouting(portfolio: portfolio)
        
        currentProcessingMethod = result.source == .native ? "原生 AI" : "OpenAI"
        
        logger.info("投資建議生成完成: 方法=\(String(describing: result.source)), 信心度=\(result.confidence), 時間=\(result.processingTime)")
        
        return result.data
    }
    
    // MARK: - 智能路由投資建議生成
    
    private func generateAdviceWithIntelligentRouting(portfolio: InvestmentPortfolio) async throws -> AIProcessingRouter.ProcessingResult<[InvestmentAdvice]> {
        let settings = settingsManager.currentSettings
        let strategy = settings?.aiProcessingStrategy ?? "nativeFirst"
        
        switch strategy {
        case "nativeOnly":
            return try await generateAdviceWithNativeOnly(portfolio: portfolio)
        case "nativeFirst":
            return try await generateAdviceWithNativeFirst(portfolio: portfolio)
        case "openAIFirst":
            return try await generateAdviceWithOpenAIFirst(portfolio: portfolio)
        case "hybrid":
            return try await generateAdviceWithHybrid(portfolio: portfolio)
        case "auto":
            return try await generateAdviceWithAuto(portfolio: portfolio)
        default:
            return try await generateAdviceWithNativeFirst(portfolio: portfolio)
        }
    }
    
    // MARK: - 原生 AI 投資建議生成
    
    private func generateAdviceWithNativeOnly(portfolio: InvestmentPortfolio) async throws -> AIProcessingRouter.ProcessingResult<[InvestmentAdvice]> {
        let startTime = Date()
        
        let advice = try await generateNativeInvestmentAdvice(portfolio: portfolio)
        let processingTime = Date().timeIntervalSince(startTime)
        
        performanceMonitor.recordNativeAIProcessing(
            success: true,
            processingTime: processingTime,
            confidence: 0.8
        )
        
        return AIProcessingRouter.ProcessingResult(
            data: advice,
            source: .native,
            confidence: 0.8,
            processingTime: processingTime,
            fallbackUsed: false
        )
    }
    
    private func generateAdviceWithNativeFirst(portfolio: InvestmentPortfolio) async throws -> AIProcessingRouter.ProcessingResult<[InvestmentAdvice]> {
        do {
            let nativeResult = try await generateAdviceWithNativeOnly(portfolio: portfolio)
            let confidenceThreshold = settingsManager.currentSettings?.nativeAIConfidenceThreshold ?? 0.85
            
            if nativeResult.confidence >= confidenceThreshold {
                return nativeResult
            } else {
                logger.info("原生 AI 信心度不足 (\(nativeResult.confidence))，降級到 OpenAI")
                throw AIProcessingError.insufficientConfidence
            }
        } catch {
            logger.info("原生 AI 失敗，降級到 OpenAI: \(error.localizedDescription)")
            return try await generateAdviceWithOpenAI(portfolio: portfolio)
        }
    }
    
    private func generateAdviceWithOpenAIFirst(portfolio: InvestmentPortfolio) async throws -> AIProcessingRouter.ProcessingResult<[InvestmentAdvice]> {
        do {
            return try await generateAdviceWithOpenAI(portfolio: portfolio)
        } catch {
            logger.info("OpenAI 失敗，降級到原生 AI: \(error.localizedDescription)")
            return try await generateAdviceWithNativeOnly(portfolio: portfolio)
        }
    }
    
    private func generateAdviceWithHybrid(portfolio: InvestmentPortfolio) async throws -> AIProcessingRouter.ProcessingResult<[InvestmentAdvice]> {
        async let nativeTask = try? generateAdviceWithNativeOnly(portfolio: portfolio)
        async let openAITask = try? generateAdviceWithOpenAI(portfolio: portfolio)
        
        let (nativeResult, openAIResult) = await (nativeTask, openAITask)
        
        if let native = nativeResult, let openai = openAIResult {
            // 比較結果，選擇更可靠的
            if native.confidence >= openai.confidence {
                logger.info("混合模式選擇原生 AI 結果")
                return native
            } else {
                logger.info("混合模式選擇 OpenAI 結果")
                return openai
            }
        } else if let native = nativeResult {
            logger.info("混合模式僅原生 AI 成功")
            return native
        } else if let openai = openAIResult {
            logger.info("混合模式僅 OpenAI 成功")
            return openai
        } else {
            throw AIProcessingError.textProcessingFailed
        }
    }
    
    private func generateAdviceWithAuto(portfolio: InvestmentPortfolio) async throws -> AIProcessingRouter.ProcessingResult<[InvestmentAdvice]> {
        let portfolioComplexity = assessPortfolioComplexity(portfolio: portfolio)
        let deviceCapability = getDeviceCapability()
        
        if deviceCapability >= 0.7 && portfolioComplexity < 0.6 {
            // 設備能力強，投資組合不複雜，優先使用原生 AI
            return try await generateAdviceWithNativeFirst(portfolio: portfolio)
        } else {
            // 設備能力一般或投資組合複雜，使用混合策略
            return try await generateAdviceWithHybrid(portfolio: portfolio)
        }
    }
    
    // MARK: - 原生 AI 投資建議實現
    
    private func generateNativeInvestmentAdvice(portfolio: InvestmentPortfolio) async throws -> [InvestmentAdvice] {
        // 使用 Natural Language Framework 分析投資組合
        let analysis = await analyzePortfolioWithNativeAI(portfolio: portfolio)
        
        // 基於分析結果生成建議
        var advice: [InvestmentAdvice] = []
        
        for investment in portfolio.investments {
            let recommendation = generateRecommendationForInvestment(
                investment: investment,
                analysis: analysis
            )
            advice.append(recommendation)
        }
        
        return advice
    }
    
    private func analyzePortfolioWithNativeAI(portfolio: InvestmentPortfolio) async -> PortfolioAnalysisResult {
        // 使用 Natural Language Framework 分析投資組合
        let diversificationScore = calculateDiversificationScore(portfolio: portfolio)
        let riskScore = calculateRiskScore(portfolio: portfolio)
        let performanceScore = calculatePerformanceScore(portfolio: portfolio)
        
        return PortfolioAnalysisResult(
            diversificationScore: diversificationScore,
            riskScore: riskScore,
            performanceScore: performanceScore,
            confidence: 0.8
        )
    }
    
    private func generateRecommendationForInvestment(
        investment: Investment,
        analysis: PortfolioAnalysisResult
    ) -> InvestmentAdvice {
        // 基於投資表現和風險分析生成建議
        let returnPercentage = investment.totalReturnPercentage
        let riskLevel = analysis.riskScore > 0.7 ? "高" : analysis.riskScore > 0.4 ? "中" : "低"
        
        var action: String
        var reason: String
        var confidence: Double
        
        if returnPercentage > 20 {
            action = "hold"
            reason = "表現優異，建議繼續持有"
            confidence = 0.9
        } else if returnPercentage < -10 {
            action = "sell"
            reason = "表現不佳，建議考慮賣出"
            confidence = 0.8
        } else {
            action = "buy"
            reason = "表現穩定，可考慮加碼"
            confidence = 0.7
        }
        
        return InvestmentAdvice(
            symbol: investment.symbol,
            action: action,
            confidence: confidence,
            reason: reason,
            targetPrice: investment.currentPrice * 1.1,
            stopLoss: investment.currentPrice * 0.9,
            timeHorizon: "6個月",
            riskLevel: riskLevel
        )
    }
    
    // MARK: - OpenAI 投資建議生成
    
    private func generateAdviceWithOpenAI(portfolio: InvestmentPortfolio) async throws -> AIProcessingRouter.ProcessingResult<[InvestmentAdvice]> {
        let startTime = Date()
        
        let advice = try await generateOpenAIInvestmentAdvice(portfolio: portfolio)
        let processingTime = Date().timeIntervalSince(startTime)
        let cost = 0.0 // 簡化實現，實際應用中需要計算成本
        
        performanceMonitor.recordOpenAIProcessing(
            success: true,
            processingTime: processingTime,
            cost: cost
        )
        
        return AIProcessingRouter.ProcessingResult(
            data: advice,
            source: .openAI,
            confidence: 1.0,
            processingTime: processingTime,
            fallbackUsed: false
        )
    }
    
    private func generateOpenAIInvestmentAdvice(portfolio: InvestmentPortfolio) async throws -> [InvestmentAdvice] {
        let prompt = createInvestmentAdvicePrompt(portfolio: portfolio)
        
        let aiResponse = try await openAIService.chat(messages: [
            OpenAIMessage(role: "system", content: prompt),
            OpenAIMessage(role: "user", content: "請分析我的投資組合並提供建議")
        ])
        
        return try parseInvestmentAdvice(aiResponse)
    }
    
    // MARK: - 買賣建議
    
    func getBuySellRecommendations(for investment: Investment) async throws -> InvestmentAdvice {
        let prompt = createBuySellPrompt(investment: investment)
        
        let aiResponse = try await openAIService.chat(messages: [
            OpenAIMessage(role: "system", content: prompt),
            OpenAIMessage(role: "user", content: "請分析這檔投資標的並提供買賣建議")
        ])
        
        return try parseSingleAdvice(aiResponse, symbol: investment.symbol)
    }
    
    // MARK: - 私有方法
    
    private func generateMockMarketData(for symbol: String) -> MarketData {
        // 生成模擬市場數據
        let basePrice = Double.random(in: 50...500)
        let change = Double.random(in: -10...10)
        let changePercent = (change / basePrice) * 100
        
        return MarketData(
            symbol: symbol,
            price: basePrice + change,
            change: change,
            changePercentage: changePercent,
            volume: Int.random(in: 1000...100000),
            marketCap: Double.random(in: 1000000000...10000000000),
            lastUpdated: Date()
        )
    }
    
    private func createInvestmentAdvicePrompt(portfolio: InvestmentPortfolio) -> String {
        let investmentsInfo = portfolio.investments.map { investment in
            """
            - \(investment.symbol) (\(investment.name)):
              持有: \(String(format: "%.0f", investment.shares)) 股
              成本: NT$ \(String(format: "%.2f", investment.averageCost))
              現價: NT$ \(String(format: "%.2f", investment.currentPrice))
              報酬: \(String(format: "%.1f", investment.totalReturnPercentage))%
            """
        }.joined(separator: "\n")
        
        return """
        你是一位專業的投資顧問，請分析以下投資組合並提供建議：
        
        投資組合總覽：
        - 總價值: NT$ \(String(format: "%.0f", portfolio.totalValue))
        - 總報酬: NT$ \(String(format: "%.0f", portfolio.totalReturn)) (\(String(format: "%.1f", portfolio.totalReturnPercentage))%)
        - 日變動: NT$ \(String(format: "%.0f", portfolio.dailyChange)) (\(String(format: "%.1f", portfolio.dailyChangePercentage))%)
        
        投資標的詳情：
        \(investmentsInfo)
        
        請提供：
        1. 整體投資組合評估
        2. 各標的的買賣建議（買入/賣出/持有）
        3. 風險評估與建議
        4. 資產配置優化建議
        5. 基於聖經原則的理財智慧
        
        請以 JSON 格式回應，包含每個標的的建議。
        """
    }
    
    private func createBuySellPrompt(investment: Investment) -> String {
        return """
        請分析以下投資標的並提供買賣建議：
        
        標的資訊：
        - 代碼: \(investment.symbol)
        - 名稱: \(investment.name)
        - 類型: \(investment.type)
        - 持有股數: \(String(format: "%.0f", investment.shares))
        - 平均成本: NT$ \(String(format: "%.2f", investment.averageCost))
        - 當前價格: NT$ \(String(format: "%.2f", investment.currentPrice))
        - 總報酬: \(String(format: "%.1f", investment.totalReturnPercentage))%
        - 持有天數: \(investment.holdingDays) 天
        
        請提供：
        1. 買賣建議（買入/賣出/持有）
        2. 建議理由
        3. 目標價格
        4. 風險評估
        5. 時間建議
        
        請以 JSON 格式回應。
        """
    }
    
    private func parseInvestmentAdvice(_ response: String) throws -> [InvestmentAdvice] {
        // 解析 AI 回應為投資建議
        // 這裡會實作 JSON 解析邏輯
        return []
    }
    
    private func parseSingleAdvice(_ response: String, symbol: String) throws -> InvestmentAdvice {
        // 解析單一投資建議
        return InvestmentAdvice(
            symbol: symbol,
            action: "hold",
            confidence: 0.7,
            reason: "建議繼續持有",
            targetPrice: nil,
            stopLoss: nil,
            timeHorizon: "中期",
            riskLevel: "中"
        )
    }
    
    private func calculateRiskScore(portfolio: InvestmentPortfolio) -> Double {
        // 計算投資組合風險分數
        let allocation = portfolio.getAssetAllocation()
        var riskScore = 0.0
        
        // 根據資產類型計算風險
        for (type, percentage) in allocation {
            switch type {
            case .stock:
                riskScore += percentage * 0.8
            case .etf:
                riskScore += percentage * 0.6
            case .bond:
                riskScore += percentage * 0.3
            case .crypto:
                riskScore += percentage * 1.0
            default:
                riskScore += percentage * 0.5
            }
        }
        
        return min(1.0, riskScore / 100.0)
    }
    
    private func calculateDiversificationScore(portfolio: InvestmentPortfolio) -> Double {
        let allocation = portfolio.getAssetAllocation()
        let assetCount = allocation.count
        
        // 多樣化評分：資產種類越多，分數越高
        if assetCount >= 5 {
            return 1.0
        } else if assetCount >= 3 {
            return 0.8
        } else if assetCount >= 2 {
            return 0.6
        } else {
            return 0.3
        }
    }
    
    private func getTopPerformers(portfolio: InvestmentPortfolio) -> [String] {
        return portfolio.investments
            .filter { $0.totalReturnPercentage > 0 }
            .sorted { $0.totalReturnPercentage > $1.totalReturnPercentage }
            .prefix(3)
            .map { $0.symbol }
    }
    
    private func getUnderPerformers(portfolio: InvestmentPortfolio) -> [String] {
        return portfolio.investments
            .filter { $0.totalReturnPercentage < -5 }
            .sorted { $0.totalReturnPercentage < $1.totalReturnPercentage }
            .prefix(3)
            .map { $0.symbol }
    }
    
    // MARK: - 市場提醒
    
    func checkMarketAlerts(for portfolio: InvestmentPortfolio) -> [String] {
        var alerts: [String] = []
        
        for investment in portfolio.investments {
            // 檢查大幅波動
            if abs(investment.dailyChangePercentage) > 5 {
                alerts.append("\(investment.symbol) 今日波動 \(String(format: "%.1f", investment.dailyChangePercentage))%")
            }
            
            // 檢查獲利了結機會
            if investment.totalReturnPercentage > 20 {
                alerts.append("\(investment.symbol) 獲利已達 \(String(format: "%.1f", investment.totalReturnPercentage))%，可考慮獲利了結")
            }
            
            // 檢查停損提醒
            if investment.totalReturnPercentage < -10 {
                alerts.append("\(investment.symbol) 虧損 \(String(format: "%.1f", abs(investment.totalReturnPercentage)))%，請檢視是否停損")
            }
        }
        
        return alerts
    }
    
    // MARK: - 輔助方法
    
    private func assessPortfolioComplexity(portfolio: InvestmentPortfolio) -> Double {
        let investmentCount = portfolio.investments.count
        let assetTypes = Set(portfolio.investments.map { $0.type }).count
        
        var complexity: Double = 0.0
        
        // 基於投資標的數量
        if investmentCount > 10 {
            complexity += 0.4
        } else if investmentCount > 5 {
            complexity += 0.2
        }
        
        // 基於資產類型多樣性
        if assetTypes > 5 {
            complexity += 0.3
        } else if assetTypes > 3 {
            complexity += 0.2
        }
        
        // 基於投資金額分散度
        let totalValue = portfolio.totalValue
        let maxInvestment = portfolio.investments.map { $0.currentValue }.max() ?? 0
        let concentration = maxInvestment / totalValue
        
        if concentration > 0.5 {
            complexity += 0.3 // 集中投資增加複雜度
        }
        
        return min(complexity, 1.0)
    }
    
    private func getDeviceCapability() -> Double {
        // 簡化實現，實際應根據設備型號、RAM、Neural Engine 等判斷
        return 0.8 // 假設為中高端設備
    }
    
    private func estimateTokensForPortfolio(portfolio: InvestmentPortfolio) -> Int {
        // 估算投資組合分析所需的 token 數量
        let baseTokens = 100
        let investmentTokens = portfolio.investments.count * 50
        let analysisTokens = 200
        
        return baseTokens + investmentTokens + analysisTokens
    }
    
}


// MARK: - 投資組合分析結果

struct PortfolioAnalysisResult {
    let diversificationScore: Double
    let riskScore: Double
    let performanceScore: Double
    let confidence: Double
}
