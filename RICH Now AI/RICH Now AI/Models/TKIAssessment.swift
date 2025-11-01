//
//  TKIAssessment.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import Foundation
import SwiftData

// MARK: - TKI 衝突處理模式
enum TKIMode: String, Codable, CaseIterable {
    case competing = "competing"           // 競爭型
    case collaborating = "collaborating"   // 合作型
    case compromising = "compromising"     // 妥協型
    case avoiding = "avoiding"             // 迴避型
    case accommodating = "accommodating"  // 順應型
    
    var displayName: String {
        "tki.\(self.rawValue)"
    }
    
    var financialDecisionStyleKey: String {
        switch self {
        case .competing:
            return "tki.competing.financial_style"
        case .collaborating:
            return "tki.collaborating.financial_style"
        case .compromising:
            return "tki.compromising.financial_style"
        case .avoiding:
            return "tki.avoiding.financial_style"
        case .accommodating:
            return "tki.accommodating.financial_style"
        }
    }
    
}

// MARK: - TKI 問題結構
struct TKIQuestion: Codable, Identifiable {
    let id: Int
    let questionNumber: Int
    let optionA: String
    let optionB: String
    let modeA: TKIMode
    let modeB: TKIMode
    
    var localizedOptionA: String {
        return "tki.question_\(questionNumber)_option_a".localized
    }
    
    var localizedOptionB: String {
        return "tki.question_\(questionNumber)_option_b".localized
    }
}

// MARK: - TKI 答案
struct TKIAnswer: Codable {
    let questionId: Int
    let selectedMode: TKIMode
    let timestamp: Date
    
    init(questionId: Int, selectedMode: TKIMode) {
        self.questionId = questionId
        self.selectedMode = selectedMode
        self.timestamp = Date()
    }
}

// MARK: - TKI 結果
struct TKIResult: Codable {
    let scores: [TKIMode: Int]
    let primaryMode: TKIMode
    let secondaryMode: TKIMode
    private let financialDecisionStyleKey: String
    private let recommendationLocalizationKeys: [String]
    
    var financialDecisionStyleKeyValue: String { financialDecisionStyleKey }
    var recommendationKeys: [String] { recommendationLocalizationKeys }
    let completedAt: Date
    
    init(scores: [TKIMode: Int]) {
        self.scores = scores
        self.completedAt = Date()
        
        // 找出主要和次要模式
        let sortedModes = scores.sorted { $0.value > $1.value }
        self.primaryMode = sortedModes.first?.key ?? .compromising
        self.secondaryMode = sortedModes.count > 1 ? sortedModes[1].key : .compromising
        
        // 生成財務決策風格描述
        self.financialDecisionStyleKey = primaryMode.financialDecisionStyleKey
        
        // 生成建議
        self.recommendationLocalizationKeys = TKIResult.generateRecommendationKeys(
            primary: primaryMode,
            secondary: secondaryMode,
            scores: scores
        )
    }
    
    private static func generateRecommendationKeys(
        primary: TKIMode,
        secondary: TKIMode,
        scores: [TKIMode: Int]
    ) -> [String] {
        var recommendations: [String] = []
        
        // 根據主要模式給出建議
        switch primary {
        case .competing:
            recommendations.append("tki.recommendation.competing.1")
            recommendations.append("tki.recommendation.competing.2")
        case .collaborating:
            recommendations.append("tki.recommendation.collaborating.1")
            recommendations.append("tki.recommendation.collaborating.2")
        case .compromising:
            recommendations.append("tki.recommendation.compromising.1")
            recommendations.append("tki.recommendation.compromising.2")
        case .avoiding:
            recommendations.append("tki.recommendation.avoiding.1")
            recommendations.append("tki.recommendation.avoiding.2")
        case .accommodating:
            recommendations.append("tki.recommendation.accommodating.1")
            recommendations.append("tki.recommendation.accommodating.2")
        }
        
        // 根據分數分布給出平衡建議
        let totalScore = scores.values.reduce(0, +)
        let maxScore = scores.values.max() ?? 0
        let balanceRatio = Double(maxScore) / Double(totalScore)
        
        if balanceRatio > 0.4 {
            recommendations.append("tki.recommendation.balanced")
        }
        
        return recommendations
    }
    
    // nonisolated 編碼方法
    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(scores, forKey: .scores)
        try container.encode(primaryMode, forKey: .primaryMode)
        try container.encode(secondaryMode, forKey: .secondaryMode)
        try container.encode(financialDecisionStyleKey, forKey: .financialDecisionStyleKey)
        try container.encode(recommendationLocalizationKeys, forKey: .recommendationLocalizationKeys)
        try container.encode(completedAt, forKey: .completedAt)
    }
    
    // nonisolated 解碼方法
    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        scores = try container.decode([TKIMode: Int].self, forKey: .scores)
        primaryMode = try container.decode(TKIMode.self, forKey: .primaryMode)
        secondaryMode = try container.decode(TKIMode.self, forKey: .secondaryMode)
        financialDecisionStyleKey = try container.decode(String.self, forKey: .financialDecisionStyleKey)
        recommendationLocalizationKeys = try container.decode([String].self, forKey: .recommendationLocalizationKeys)
        completedAt = try container.decode(Date.self, forKey: .completedAt)
    }
    
    private enum CodingKeys: String, CodingKey {
        case scores
        case primaryMode
        case secondaryMode
        case financialDecisionStyleKey
        case recommendationLocalizationKeys
        case completedAt
    }
}

// MARK: - TKI 測驗結果儲存
@Model
final class TKIAssessment {
    @Attribute(.unique) var id: UUID = UUID()
    var userId: UUID
    var questionsData: Data // JSON encoded [TKIQuestion]
    var answersData: Data // JSON encoded [TKIAnswer]
    var resultData: Data? // JSON encoded TKIResult
    var completedAt: Date?
    var createdAt: Date
    
    // 關聯
    @Relationship(deleteRule: .nullify, inverse: \User.tkiAssessment) var user: User?
    
    init(userId: UUID, questions: [TKIQuestion]) {
        self.userId = userId
        self.createdAt = Date()
        
        do {
            self.questionsData = try JSONEncoder().encode(questions)
            self.answersData = try JSONEncoder().encode([TKIAnswer]())
        } catch {
            fatalError("Failed to encode TKI data: \(error)")
        }
    }
    
    func updateAnswers(_ answers: [TKIAnswer]) {
        do {
            self.answersData = try JSONEncoder().encode(answers)
        } catch {
            print("Failed to encode TKI answers: \(error)")
        }
    }
    
    func completeAssessment(with result: TKIResult) {
        self.completedAt = Date()
        do {
            self.resultData = try JSONEncoder().encode(result)
        } catch {
            print("Failed to encode TKI result: \(error)")
        }
    }
    
    func getQuestions() -> [TKIQuestion] {
        do {
            return try JSONDecoder().decode([TKIQuestion].self, from: questionsData)
        } catch {
            print("Failed to decode TKI questions: \(error)")
            return []
        }
    }
    
    func getAnswers() -> [TKIAnswer] {
        do {
            return try JSONDecoder().decode([TKIAnswer].self, from: answersData)
        } catch {
            print("Failed to decode TKI answers: \(error)")
            return []
        }
    }
    
    func getResult() -> TKIResult? {
        guard let data = resultData else { return nil }
        do {
            return try JSONDecoder().decode(TKIResult.self, from: data)
        } catch {
            print("Failed to decode TKI result: \(error)")
            return nil
        }
    }
    
    // nonisolated 方法用於在非隔離上下文中訪問結果
    nonisolated func getResultData() -> Data? {
        return resultData
    }
    
    nonisolated func getQuestionsData() -> Data {
        return questionsData
    }
    
    nonisolated func getAnswersData() -> Data {
        return answersData
    }
}

// MARK: - 擴展 String 支援本地化 (已移至 LocalizationManager.swift)
