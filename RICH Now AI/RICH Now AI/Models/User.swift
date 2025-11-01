//
//  User.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import Foundation
import SwiftData

@Model
final class User {
    // 基本資訊
    @Attribute(.unique) var id: UUID = UUID()
    var name: String
    var email: String
    var age: Int
    var occupation: String
    var familyStatus: String // 單身、已婚、有子女等
    var createdAt: Date
    var lastLoginAt: Date
    
    // VGLA 測驗結果
    var vglaCompleted: Bool
    var vglaPrimaryType: String? // V, G, L, A
    var vglaSecondaryType: String?
    var vglaCombinationType: String? // VA, VG, LG, etc.
    var vglaScore: Data? // JSON 格式的完整分數
    
    // TKI 測驗結果
    var tkiCompleted: Bool
    var tkiPrimaryMode: String? // competing, collaborating, etc.
    var tkiSecondaryMode: String?
    var tkiScores: Data? // JSON 格式的完整分數
    var tkiCompletedAt: Date?
    
    // API 設定
    var hasOwnAPIKey: Bool
    var openAIAPIKey: String? // 加密存儲
    var subscriptionType: String // free, pro
    var subscriptionExpiresAt: Date?
    
    // 財務健康評分
    var financialHealthScore: Int // 0-100
    var lastHealthScoreUpdate: Date
    
    // VGLA 面板
    @Relationship(deleteRule: .cascade) var vglaPanels: [VGLAPanel] = []
    
    // 財務健康報告
    @Relationship(deleteRule: .cascade) var financialHealthReports: [FinancialHealthReport] = []
    
    // 投資組合
    @Relationship(deleteRule: .cascade) var investmentPortfolios: [InvestmentPortfolio] = []
    
    // 關聯資料
    @Relationship(deleteRule: .cascade) var conversations: [Conversation] = []
    @Relationship(deleteRule: .cascade) var transactions: [Transaction] = []
    @Relationship(deleteRule: .cascade) var financialProfile: FinancialProfile?
    @Relationship(deleteRule: .cascade) var goals: [FinancialGoal] = []
    @Relationship(deleteRule: .cascade) var budgets: [Budget] = []
    @Relationship(deleteRule: .cascade) var reports: [Report] = []
    @Relationship(deleteRule: .cascade) var vglaAssessment: VGLAAssessment?
    @Relationship(deleteRule: .cascade) var vglaProfile: VGLAProfile?
    @Relationship(deleteRule: .cascade) var tkiAssessment: TKIAssessment?
    @Relationship(deleteRule: .cascade) var investments: [RICH_Now_AI.Investment] = []
    @Relationship(deleteRule: .cascade) var portfolios: [InvestmentPortfolio] = []
    
    // 投資關注列表
    @Relationship(deleteRule: .cascade) var watchlistItems: [WatchlistItem] = []
    
    // 發票載具
    @Relationship(deleteRule: .cascade) var invoiceCarriers: [InvoiceCarrier] = []
    
    // 家庭群組
    @Relationship(deleteRule: .nullify) var familyGroup: FamilyGroup?
    
    init(name: String, email: String, age: Int, occupation: String, familyStatus: String) {
        self.name = name
        self.email = email
        self.age = age
        self.occupation = occupation
        self.familyStatus = familyStatus
        self.createdAt = Date()
        self.lastLoginAt = Date()
        self.vglaCompleted = false
        self.tkiCompleted = false
        self.hasOwnAPIKey = false
        self.subscriptionType = "free"
        self.financialHealthScore = 0
        self.lastHealthScoreUpdate = Date()
    }
    
    // 更新登入時間
    func updateLastLogin() {
        self.lastLoginAt = Date()
    }
    
    // 更新財務健康評分
    func updateFinancialHealthScore(_ score: Int) {
        self.financialHealthScore = max(0, min(100, score))
        self.lastHealthScoreUpdate = Date()
    }
    
    // 檢查是否為 Pro 使用者
    var isProUser: Bool {
        return subscriptionType == "pro" && 
               (subscriptionExpiresAt == nil || subscriptionExpiresAt! > Date())
    }
    
    // 檢查 API 使用限制
    var canUseAI: Bool {
        if hasOwnAPIKey && openAIAPIKey != nil {
            return true
        }
        return isProUser
    }
    
    // 更新 TKI 測驗結果
    func updateTKIResult(_ result: TKIResult) {
        self.tkiCompleted = true
        self.tkiPrimaryMode = result.primaryMode.rawValue
        self.tkiSecondaryMode = result.secondaryMode.rawValue
        self.tkiCompletedAt = result.completedAt
        
        // 儲存完整分數
        do {
            self.tkiScores = try JSONEncoder().encode(result.scores)
        } catch {
            print("Failed to encode TKI scores: \(error)")
        }
    }
    
    // 獲取 TKI 分數
    func getTKIScores() -> [String: Int]? {
        guard let data = tkiScores else { return nil }
        do {
            return try JSONDecoder().decode([String: Int].self, from: data)
        } catch {
            print("Failed to decode TKI scores: \(error)")
            return nil
        }
    }
    
    // 檢查是否有整合分析
    var hasIntegratedAnalysis: Bool {
        return vglaCompleted && tkiCompleted
    }
}
