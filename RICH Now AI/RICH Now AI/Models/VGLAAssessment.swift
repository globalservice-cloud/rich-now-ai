//
//  VGLAAssessment.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import Foundation
import SwiftData

// VGLA 四向度定義
enum Dimension: String, Codable, CaseIterable {
    case V = "Vision"    // 願景型（描繪長期方向與意義）
    case G = "Gracious"  // 感性型（顧及彼此感受，營造良好氛圍）
    case L = "Logic"     // 邏輯型（釐清規則、流程與依據）
    case A = "Action"    // 行動型（立刻採取行動，做出可見進展）
}

// VGLA 分數結構
struct VGLAScore: Codable {
    var like: [String: Int]      // 最喜歡分數
    var dislike: [String: Int]   // 最不喜歡分數
    var total: [String: Int]     // 綜合分數
    var orderLike: [String]      // 正向排序
    var orderDislike: [String]   // 逆向排序
    var orderTotal: [String]     // 綜合排序
    
    init() {
        self.like = [:]
        self.dislike = [:]
        self.total = [:]
        self.orderLike = []
        self.orderDislike = []
        self.orderTotal = []
        
        // 初始化所有向度為 0
        for dimension in Dimension.allCases {
            self.like[dimension.rawValue] = 0
            self.dislike[dimension.rawValue] = 0
            self.total[dimension.rawValue] = 0
        }
    }
}

// VGLA 測驗題目已在 VGLAQuestion.swift 中定義

@Model
final class VGLAAssessment {
    // 測驗狀態
    var isCompleted: Bool
    var startedAt: Date
    var completedAt: Date?
    var currentQuestionIndex: Int
    
    // 測驗答案 (題目ID: 選項)
    var answers: [String: String] // JSON 格式存儲
    
    // 計分結果
    var score: Data? // VGLAScore 的 JSON 格式
    var primaryType: String?
    var secondaryType: String?
    var tertiaryType: String?
    var blindSpotType: String?
    
    // 報告生成
    var reportGenerated: Bool
    var reportGeneratedAt: Date?
    var reportData: Data? // 完整報告的 JSON 格式
    
    // 關聯
    @Relationship(deleteRule: .nullify, inverse: \User.vglaAssessment) var user: User?
    
    init() {
        self.isCompleted = false
        self.startedAt = Date()
        self.currentQuestionIndex = 0
        self.answers = [:]
        self.reportGenerated = false
    }
    
    // 更新答案
    func updateAnswer(questionId: Int, answer: String) {
        answers["\(questionId)"] = answer
    }
    
    // 獲取當前問題
    func getCurrentQuestion() -> VGLAQuestion? {
        // 這裡會從題庫中獲取問題
        // 實際實作時會從 JSON 檔案載入
        return nil
    }
    
    // 計算分數
    func calculateScore() -> VGLAScore {
        var score = VGLAScore()
        
        // 處理最喜歡題目 (1-30)
        for i in 1...30 {
            if let answer = answers["\(i)"] {
                if let dimension = getDimensionFromAnswer(answer) {
                    score.like[dimension.rawValue] = (score.like[dimension.rawValue] ?? 0) + 1
                }
            }
        }
        
        // 處理最不喜歡題目 (31-60)
        for i in 31...60 {
            if let answer = answers["\(i)"] {
                if let dimension = getDimensionFromAnswer(answer) {
                    score.dislike[dimension.rawValue] = (score.dislike[dimension.rawValue] ?? 0) - 1
                }
            }
        }
        
        // 計算總分
        for dimension in Dimension.allCases {
            let likeScore = score.like[dimension.rawValue] ?? 0
            let dislikeScore = score.dislike[dimension.rawValue] ?? 0
            score.total[dimension.rawValue] = likeScore + dislikeScore
        }
        
        // 產生排序
        score.orderLike = score.like.sorted { $0.value > $1.value }.map { $0.key }
        score.orderDislike = score.dislike.sorted { $0.value > $1.value }.map { $0.key }
        score.orderTotal = score.total.sorted { $0.value > $1.value }.map { $0.key }
        
        return score
    }
    
    // 完成測驗
    @MainActor
    func completeAssessment() {
        self.isCompleted = true
        self.completedAt = Date()
        
        let calculatedScore = calculateScore()
        self.score = try? JSONEncoder().encode(calculatedScore)
        
        // 設定主要類型
        if let primary = calculatedScore.orderTotal.first {
            self.primaryType = primary
        }
        if calculatedScore.orderTotal.count > 1 {
            self.secondaryType = calculatedScore.orderTotal[1]
        }
        if calculatedScore.orderTotal.count > 2 {
            self.tertiaryType = calculatedScore.orderTotal[2]
        }
        if calculatedScore.orderTotal.count > 3 {
            self.blindSpotType = calculatedScore.orderTotal[3]
        }
    }
    
    // 從答案選項獲取向度
    private func getDimensionFromAnswer(_ answer: String) -> Dimension? {
        switch answer.uppercased() {
        case "A": return .A
        case "B": return .G
        case "C": return .L
        case "D": return .V
        default: return nil
        }
    }
    
    // 獲取分數物件
    @MainActor
    func getScore() -> VGLAScore? {
        guard let scoreData = score else { return nil }
        return try? JSONDecoder().decode(VGLAScore.self, from: scoreData)
    }
}
