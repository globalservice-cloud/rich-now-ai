//
//  VGLAAnalyzer.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import Foundation
import Combine
import SwiftData

// VGLA 分析結果
struct VGLAnalysisResult: Codable {
    let primaryType: String
    let secondaryType: String
    let tertiaryType: String
    let blindSpotType: String
    let strengths: [String]
    let growthAreas: [String]
    let financialAdvice: String
    let communicationStyle: String
    let decisionMakingStyle: String
}

// VGLA 財務建議
struct VGLAFinancialAdvice: Codable {
    let approach: String
    let tools: [String]
    let warnings: [String]
    let encouragements: [String]
    let biblicalPrinciples: [String]
}

@MainActor
class VGLAAnalyzer: ObservableObject {
    static let shared = VGLAAnalyzer()
    
    private let openAIService = OpenAIService.shared
    
    private init() {}
    
    // MARK: - VGLA 分數計算
    
    func calculateVGLAscore(answers: [Int: String]) -> VGLAScore {
        var score = VGLAScore()
        
        // 處理最喜歡題目 (1-30)
        for i in 1...30 {
            if let answer = answers[i] {
                if let dimension = getDimensionFromAnswer(answer) {
                    score.like[dimension.rawValue] = (score.like[dimension.rawValue] ?? 0) + 1
                }
            }
        }
        
        // 處理最不喜歡題目 (31-60)
        for i in 31...60 {
            if let answer = answers[i] {
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
    
    // MARK: - VGLA 分析
    
    func analyzeVGLA(score: VGLAScore) async throws -> VGLAnalysisResult {
        let primaryType = score.orderTotal.first ?? "V"
        let secondaryType = score.orderTotal.count > 1 ? score.orderTotal[1] : ""
        let tertiaryType = score.orderTotal.count > 2 ? score.orderTotal[2] : ""
        let blindSpotType = score.orderTotal.count > 3 ? score.orderTotal[3] : ""
        
        // 使用 AI 分析 VGLA 結果
        let analysisPrompt = createAnalysisPrompt(score: score)
        let aiResponse = try await openAIService.chat(messages: [
            OpenAIMessage(role: "system", content: analysisPrompt),
            OpenAIMessage(role: "user", content: "請分析我的 VGLA 測驗結果")
        ])
        
        return parseAnalysisResult(aiResponse, primaryType: primaryType, secondaryType: secondaryType, tertiaryType: tertiaryType, blindSpotType: blindSpotType)
    }
    
    // MARK: - 財務建議生成
    
    func generateFinancialAdvice(vglaType: String, financialProfile: FinancialProfile) async throws -> VGLAFinancialAdvice {
        let advicePrompt = createFinancialAdvicePrompt(vglaType: vglaType, profile: financialProfile)
        
        let aiResponse = try await openAIService.chat(messages: [
            OpenAIMessage(role: "system", content: advicePrompt),
            OpenAIMessage(role: "user", content: "請根據我的 VGLA 類型和財務狀況提供個性化建議")
        ])
        
        return parseFinancialAdvice(aiResponse)
    }
    
    // MARK: - 對話風格客製化
    
    func getCustomizedPrompt(for vglaType: String, context: String) -> String {
        let basePrompt = """
        你是加百列，一位友善有智慧的 CFO 級別財務顧問。你的使命是成為使用者最了解他們的親密好友，真實地幫助他們建立健康的財務狀況。
        
        你的角色定位：
        - 最了解使用者的親密好友
        - 真誠關心使用者的財務健康
        - 循循善誘，即使面對固執錯誤的財務觀念也不放棄
        - 所有建議都必須基於聖經原則
        
        核心聖經原則：
        1. 金錢是神的恩賜，我們是管家（馬太福音 25:14-30）
        2. 不要貪愛錢財（希伯來書 13:5）
        3. 要誠實處理財務（箴言 11:1）
        4. 要慷慨奉獻（哥林多後書 9:7）
        5. 要為未來做準備（箴言 21:5）
        """
        
        let typeSpecificPrompt = getTypeSpecificPrompt(for: vglaType)
        let contextPrompt = getContextPrompt(context: context)
        
        return "\(basePrompt)\n\n\(typeSpecificPrompt)\n\n\(contextPrompt)"
    }
    
    // 根據組合型態獲取客製化提示
    func getCustomizedPromptForCombination(combinationType: VGLACombinationType, context: String) -> String {
        let basePrompt = """
        你是加百列，使用者最了解他們的親密好友和 CFO 財務顧問。
        
        使用者的思考模式組合：\(combinationType.displayName)（\(combinationType.rawValue)）
        特質描述：\(combinationType.description)
        
        你要用最適合他們的方式溝通：
        \(combinationType.communicationStyle)
        
        財務建議方式：
        \(combinationType.financialApproach)
        
        記住：你是他們最親密的財務好友，要真誠關心他們，循循善誘地幫助他們建立正確的理財觀念。
        即使他們有固執錯誤的想法，你也要耐心引導，不放棄。
        """
        
        let contextPrompt = getContextPrompt(context: context)
        
        return "\(basePrompt)\n\n\(contextPrompt)"
    }
    
    // MARK: - 私有方法
    
    private func getDimensionFromAnswer(_ answer: String) -> Dimension? {
        switch answer.uppercased() {
        case "A": return .A
        case "B": return .G
        case "C": return .L
        case "D": return .V
        default: return nil
        }
    }
    
    private func createAnalysisPrompt(score: VGLAScore) -> String {
        return """
        你是一位專業的 VGLA 分析師。請根據以下分數分析使用者的思考特質：
        
        正向分數（最喜歡）：
        - Vision (V): \(score.like["Vision"] ?? 0)
        - Gracious (G): \(score.like["Gracious"] ?? 0)
        - Logic (L): \(score.like["Logic"] ?? 0)
        - Action (A): \(score.like["Action"] ?? 0)
        
        逆向分數（最不喜歡）：
        - Vision (V): \(score.dislike["Vision"] ?? 0)
        - Gracious (G): \(score.dislike["Gracious"] ?? 0)
        - Logic (L): \(score.dislike["Logic"] ?? 0)
        - Action (A): \(score.dislike["Action"] ?? 0)
        
        綜合排序：\(score.orderTotal.joined(separator: " > "))
        
        請提供：
        1. 主要優勢
        2. 成長空間
        3. 財務決策建議
        4. 溝通風格
        5. 決策模式
        """
    }
    
    private func createFinancialAdvicePrompt(vglaType: String, profile: FinancialProfile) -> String {
        return """
        根據使用者的 VGLA 類型：\(vglaType)
        以及財務狀況：
        - 月收入：\(profile.monthlyIncome)
        - 月支出：\(profile.monthlyExpenses)
        - 淨資產：\(profile.netWorth)
        - 緊急預備金：\(profile.emergencyFund)
        - 風險承受度：\(profile.riskTolerance)
        
        請提供個性化的財務建議，包括：
        1. 適合的理財方法
        2. 推薦的工具
        3. 需要注意的風險
        4. 鼓勵的話語
        5. 相關聖經原則
        """
    }
    
    private func getTypeSpecificPrompt(for vglaType: String) -> String {
        switch vglaType {
        case "V":
            return """
            V 型（願景型）使用者特質：
            - 重視長期意義與影響
            - 喜歡從夢想與願景切入
            - 需要看到財務規劃的整體圖像
            - 容易忽略細節和短期執行
            
            對話建議：
            - 從「10 年後你希望過什麼樣的生活？」開始
            - 強調財務規劃如何幫助實現人生願景
            - 使用故事和比喻說明概念
            - 提醒要平衡夢想與現實
            """
            
        case "G":
            return """
            G 型（感性型）使用者特質：
            - 重視家人與關係
            - 關注情感與價值觀
            - 需要溫暖、支持性的語氣
            - 容易因情感因素影響財務決策
            
            對話建議：
            - 從「你想為家人實現什麼？」開始
            - 強調財務安全如何保護所愛的人
            - 用愛心和同理心溝通
            - 提醒要平衡愛心與智慧
            """
            
        case "L":
            return """
            L 型（邏輯型）使用者特質：
            - 重視數據與分析
            - 需要清晰的邏輯架構
            - 喜歡詳細的計算和比較
            - 容易過度分析而延遲行動
            
            對話建議：
            - 從「我們先整理一下你目前的財務狀況」開始
            - 提供具體的數據和計算
            - 用邏輯和理性說明
            - 提醒要平衡分析與行動
            """
            
        case "A":
            return """
            A 型（行動型）使用者特質：
            - 重視立即行動和結果
            - 喜歡具體、可執行的建議
            - 需要快速、高效的對話
            - 容易衝動而缺乏深思熟慮
            
            對話建議：
            - 從「你最想先達成哪個財務目標？」開始
            - 提供立即可行動的步驟
            - 用簡潔明瞭的方式說明
            - 提醒要平衡行動與規劃
            """
            
        default:
            return "請根據使用者的具體情況提供個性化建議。"
        }
    }
    
    private func getContextPrompt(context: String) -> String {
        switch context {
        case "onboarding":
            return "這是首次見面，請溫暖地自我介紹，說明 VGLA 測驗的意義，並引導使用者完成測驗。"
        case "financial_advice":
            return "請根據使用者的財務狀況提供具體的理財建議，並引用相關聖經原則。"
        case "goal_setting":
            return "請幫助使用者設定財務目標，並提供達成目標的具體步驟。"
        case "transaction_analysis":
            return "請分析使用者的交易記錄，提供支出優化建議。"
        default:
            return "請根據對話內容提供適當的回應。"
        }
    }
    
    private func parseAnalysisResult(_ response: String, primaryType: String, secondaryType: String, tertiaryType: String, blindSpotType: String) -> VGLAnalysisResult {
        // 解析 AI 回應，提取分析結果
        // 這裡會實作 JSON 解析邏輯
        
        return VGLAnalysisResult(
            primaryType: primaryType,
            secondaryType: secondaryType,
            tertiaryType: tertiaryType,
            blindSpotType: blindSpotType,
            strengths: ["分析能力強", "邏輯思維清晰"],
            growthAreas: ["需要更多行動力", "加強人際溝通"],
            financialAdvice: "建議採用穩健的投資策略，定期檢視財務狀況",
            communicationStyle: "理性、數據導向",
            decisionMakingStyle: "邏輯分析後決策"
        )
    }
    
    private func parseFinancialAdvice(_ response: String) -> VGLAFinancialAdvice {
        // 解析 AI 回應，提取財務建議
        // 這裡會實作 JSON 解析邏輯
        
        return VGLAFinancialAdvice(
            approach: "穩健理財法",
            tools: ["記帳 App", "投資平台", "保險規劃"],
            warnings: ["避免衝動投資", "注意風險控制"],
            encouragements: ["你的理財規劃很有條理", "持續努力會有成果"],
            biblicalPrinciples: ["馬太福音 25:14-30", "箴言 21:5"]
        )
    }
}
