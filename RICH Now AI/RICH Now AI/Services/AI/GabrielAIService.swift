//
//  GabrielAIService.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import Foundation
import SwiftData
import Combine

// 加百列 AI 角色服務
@MainActor
class GabrielAIService: ObservableObject {
    static let shared = GabrielAIService()
    
    @Published var currentPersonality: GabrielPersonality = .wise
    @Published var currentMood: GabrielMood = .friendly
    @Published var conversationStyle: ConversationStyle = .encouraging
    
    // 加百列的人格類型
    enum GabrielPersonality: String, CaseIterable {
        case wise = "wise"           // 智慧型
        case encouraging = "encouraging" // 鼓勵型
        case analytical = "analytical"    // 分析型
        case supportive = "supportive"   // 支持型
        
        var displayName: String {
            switch self {
            case .wise:
                return "gabriel.personality.wise".localized
            case .encouraging:
                return "gabriel.personality.encouraging".localized
            case .analytical:
                return "gabriel.personality.analytical".localized
            case .supportive:
                return "gabriel.personality.supportive".localized
            }
        }
        
        var description: String {
            switch self {
            case .wise:
                return "gabriel.personality.wise.description".localized
            case .encouraging:
                return "gabriel.personality.encouraging.description".localized
            case .analytical:
                return "gabriel.personality.analytical.description".localized
            case .supportive:
                return "gabriel.personality.supportive.description".localized
            }
        }
    }
    
    // 加百列的情緒狀態
    enum GabrielMood: String, CaseIterable {
        case friendly = "friendly"       // 友善
        case excited = "excited"         // 興奮
        case concerned = "concerned"     // 關心
        case proud = "proud"            // 自豪
        case thoughtful = "thoughtful" // 深思
        
        var emoji: String {
            switch self {
            case .friendly: return "😊"
            case .excited: return "🎉"
            case .concerned: return "🤔"
            case .proud: return "😌"
            case .thoughtful: return "💭"
            }
        }
        
        var displayName: String {
            switch self {
            case .friendly:
                return "gabriel.mood.friendly".localized
            case .excited:
                return "gabriel.mood.excited".localized
            case .concerned:
                return "gabriel.mood.concerned".localized
            case .proud:
                return "gabriel.mood.proud".localized
            case .thoughtful:
                return "gabriel.mood.thoughtful".localized
            }
        }
    }
    
    // 對話風格
    enum ConversationStyle: String, CaseIterable {
        case encouraging = "encouraging"   // 鼓勵式
        case analytical = "analytical"      // 分析式
        case storytelling = "storytelling"  // 故事式
        case direct = "direct"             // 直接式
        
        var displayName: String {
            switch self {
            case .encouraging:
                return "gabriel.style.encouraging".localized
            case .analytical:
                return "gabriel.style.analytical".localized
            case .storytelling:
                return "gabriel.style.storytelling".localized
            case .direct:
                return "gabriel.style.direct".localized
            }
        }
    }
    
    private init() {}
    
    // MARK: - 人格適應
    
    func adaptPersonality(for user: User) {
        // 根據用戶的 VGLA 和 TKI 結果調整加百列的人格
        if let vglaType = user.vglaPrimaryType {
            switch vglaType {
            case "V": // 願景型
                currentPersonality = .wise
                conversationStyle = .storytelling
            case "G": // 目標型
                currentPersonality = .encouraging
                conversationStyle = .encouraging
            case "L": // 邏輯型
                currentPersonality = .analytical
                conversationStyle = .analytical
            case "A": // 行動型
                currentPersonality = .supportive
                conversationStyle = .direct
            default:
                currentPersonality = .wise
                conversationStyle = .encouraging
            }
        }
        
        // 根據 TKI 結果調整情緒
        if let tkiMode = user.tkiPrimaryMode {
            switch tkiMode {
            case "competing":
                currentMood = .excited
            case "collaborating":
                currentMood = .friendly
            case "compromising":
                currentMood = .thoughtful
            case "avoiding":
                currentMood = .concerned
            case "accommodating":
                currentMood = .proud
            default:
                currentMood = .friendly
            }
        }
    }
    
    // MARK: - 回應生成
    
    func generatePersonalizedResponse(
        userMessage: String,
        user: User,
        context: String
    ) -> String {
        adaptPersonality(for: user)
        
        let baseResponse = generateBaseResponse(
            userMessage: userMessage,
            context: context
        )
        
        let personalizedResponse = personalizeResponse(
            baseResponse,
            personality: currentPersonality,
            mood: currentMood,
            style: conversationStyle
        )
        
        return personalizedResponse
    }
    
    private func generateBaseResponse(
        userMessage: String,
        context: String
    ) -> String {
        // 這裡會調用 OpenAI API 生成基礎回應
        // 實際實作時會整合 OpenAI 服務
        return "這是一個基礎回應，需要整合 OpenAI API"
    }
    
    private func personalizeResponse(
        _ baseResponse: String,
        personality: GabrielPersonality,
        mood: GabrielMood,
        style: ConversationStyle
    ) -> String {
        var response = baseResponse
        
        // 根據人格添加前綴
        switch personality {
        case .wise:
            response = "💡 " + response
        case .encouraging:
            response = "🌟 " + response
        case .analytical:
            response = "📊 " + response
        case .supportive:
            response = "🤝 " + response
        }
        
        // 根據情緒添加表情
        response = mood.emoji + " " + response
        
        // 根據風格調整語調
        switch style {
        case .encouraging:
            response = addEncouragingTone(response)
        case .analytical:
            response = addAnalyticalTone(response)
        case .storytelling:
            response = addStorytellingTone(response)
        case .direct:
            response = addDirectTone(response)
        }
        
        return response
    }
    
    private func addEncouragingTone(_ response: String) -> String {
        let encouragingPhrases = [
            "我相信你能做到的！",
            "每一步都是進步！",
            "你正在朝著正確的方向前進！"
        ]
        
        if let phrase = encouragingPhrases.randomElement() {
            return response + "\n\n" + phrase
        }
        return response
    }
    
    private func addAnalyticalTone(_ response: String) -> String {
        let analyticalPhrases = [
            "讓我們來分析一下這個情況...",
            "從數據的角度來看...",
            "這需要更深入的思考..."
        ]
        
        if let phrase = analyticalPhrases.randomElement() {
            return phrase + "\n\n" + response
        }
        return response
    }
    
    private func addStorytellingTone(_ response: String) -> String {
        let storyPhrases = [
            "讓我分享一個故事...",
            "這讓我想起了一個例子...",
            "曾經有人面臨過類似的挑戰..."
        ]
        
        if let phrase = storyPhrases.randomElement() {
            return phrase + "\n\n" + response
        }
        return response
    }
    
    private func addDirectTone(_ response: String) -> String {
        let directPhrases = [
            "直接來說...",
            "重點是...",
            "簡單來說..."
        ]
        
        if let phrase = directPhrases.randomElement() {
            return phrase + "\n\n" + response
        }
        return response
    }
    
    // MARK: - 情境回應
    
    func generateContextualResponse(
        context: String,
        user: User
    ) -> String {
        switch context {
        case "welcome":
            return generateWelcomeMessage(for: user)
        case "financial_advice":
            return generateFinancialAdvice(for: user)
        case "transaction_analysis":
            return generateTransactionAnalysis(for: user)
        case "goal_setting":
            return generateGoalSettingAdvice(for: user)
        case "encouragement":
            return generateEncouragement(for: user)
        default:
            return generateGeneralResponse(for: user)
        }
    }
    
    private func generateWelcomeMessage(for user: User) -> String {
        let name = user.name
        let vglaType = user.vglaPrimaryType ?? "V"
        
        return """
        🌟 歡迎，\(name)！
        
        我是加百列，你的財務守護天使。根據你的 VGLA 測驗結果（\(vglaType) 型），我將為你提供個人化的財務建議。
        
        讓我們一起建立健康的財務習慣，讓金錢成為祝福你和他人的工具！
        """
    }
    
    private func generateFinancialAdvice(for user: User) -> String {
        return """
        💰 財務建議
        
        基於你的財務狀況，我建議：
        1. 建立緊急基金
        2. 制定預算計劃
        3. 開始投資理財
        
        需要我為你詳細說明任何一項嗎？
        """
    }
    
    private func generateTransactionAnalysis(for user: User) -> String {
        return """
        📊 交易分析
        
        讓我為你分析最近的交易模式：
        - 支出趨勢
        - 節省機會
        - 投資建議
        
        有什麼特別想了解的嗎？
        """
    }
    
    private func generateGoalSettingAdvice(for user: User) -> String {
        return """
        🎯 目標設定
        
        設定財務目標是成功的第一步：
        1. 短期目標（1年內）
        2. 中期目標（3-5年）
        3. 長期目標（10年以上）
        
        你想從哪個目標開始？
        """
    }
    
    private func generateEncouragement(for user: User) -> String {
        return """
        🌈 鼓勵的話
        
        記住，財務自由不是一夜之間的事，而是每天的小步累積。
        
        你已經在正確的道路上了！繼續保持，我會一直陪伴你。
        """
    }
    
    private func generateGeneralResponse(for user: User) -> String {
        return """
        💬 一般回應
        
        我隨時準備為你提供幫助。無論是財務問題、生活建議，還是任何你想討論的話題，我都在這裡。
        
        有什麼我可以為你做的嗎？
        """
    }
    
    // MARK: - 聖經原則整合
    
    func integrateBiblicalPrinciples(_ response: String) -> String {
        let biblicalPrinciples = [
            "「你要記念耶和華你的神，因為得貨財的力量是他給你的。」（申命記 8:18）",
            "「殷勤人的手必掌權；懶惰的人必服苦。」（箴言 12:24）",
            "「智慧人積存知識；愚妄人的口速致敗壞。」（箴言 10:14）"
        ]
        
        if let principle = biblicalPrinciples.randomElement() {
            return response + "\n\n📖 " + principle
        }
        
        return response
    }
}
