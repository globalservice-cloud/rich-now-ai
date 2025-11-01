//
//  IncomeSuggestionService.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import Foundation
import Combine
import SwiftData

// 收入建議服務
@MainActor
class IncomeSuggestionService: ObservableObject {
    static let shared = IncomeSuggestionService()
    
    private let openAIService = OpenAIService.shared
    private let vglaAnalyzer = VGLAAnalyzer.shared
    
    @Published var suggestions: [IncomeSuggestion] = []
    @Published var isLoading: Bool = false
    
    private init() {}
    
    // MARK: - 生成收入建議
    
    func generateIncomeSuggestions(for user: User) async throws -> [IncomeSuggestion] {
        isLoading = true
        defer { isLoading = false }
        
        // 根據使用者 VGLA 類型和財務狀況生成建議
        let vglaType = user.vglaPrimaryType ?? "V"
        let financialProfile = user.financialProfile
        
        // 建立 AI 提示
        let prompt = createIncomeSuggestionPrompt(user: user, vglaType: vglaType, profile: financialProfile)
        
        // 呼叫 AI 生成建議
        let aiResponse = try await openAIService.chat(messages: [
            OpenAIMessage(role: "system", content: prompt),
            OpenAIMessage(role: "user", content: "請根據我的情況提供增加收入的建議")
        ])
        
        // 解析 AI 回應
        let parsedSuggestions = try parseIncomeSuggestions(aiResponse, vglaType: vglaType)
        
        // 計算匹配分數
        let scoredSuggestions = calculateMatchScores(suggestions: parsedSuggestions, vglaType: vglaType)
        
        await MainActor.run {
            self.suggestions = scoredSuggestions
        }
        
        return scoredSuggestions
    }
    
    // MARK: - 預設收入建議庫
    
    func getDefaultSuggestions(for vglaType: String) -> [IncomeSuggestion] {
        switch vglaType {
        case "V":
            return getVisionTypeSuggestions()
        case "G":
            return getGraciousTypeSuggestions()
        case "L":
            return getLogicTypeSuggestions()
        case "A":
            return getActionTypeSuggestions()
        default:
            return getGeneralSuggestions()
        }
    }
    
    // MARK: - 私有方法
    
    private func createIncomeSuggestionPrompt(user: User, vglaType: String, profile: FinancialProfile?) -> String {
        return """
        你是一位專業的財務顧問，專門提供增加收入的建議。請根據以下資訊提供個性化建議：
        
        使用者資訊：
        - 年齡：\(user.age)
        - 職業：\(user.occupation)
        - 家庭狀況：\(user.familyStatus)
        - VGLA 類型：\(vglaType)
        - 財務健康評分：\(user.financialHealthScore)/100
        
        財務狀況：
        - 月收入：NT$ \(String(format: "%.0f", profile?.monthlyIncome ?? 0))
        - 月支出：NT$ \(String(format: "%.0f", profile?.monthlyExpenses ?? 0))
        - 淨資產：NT$ \(String(format: "%.0f", profile?.netWorth ?? 0))
        - 風險承受度：\(profile?.riskTolerance ?? "moderate")
        
        請提供 5-8 個具體可行的收入建議，包括：
        1. 自由接案/技能變現
        2. 網路事業/電商
        3. 投資理財
        4. 兼職工作
        5. 被動收入
        6. 技能提升/學習
        7. 創業機會
        8. 其他創意收入來源
        
        每個建議需包含：
        - 標題和描述
        - 預期收入範圍
        - 時間投入
        - 所需技能
        - 風險等級
        - 相關聖經原則
        - 具體執行步驟
        - 推薦資源
        
        請以 JSON 格式回應，並確保建議符合使用者的 VGLA 類型特質。
        """
    }
    
    private func parseIncomeSuggestions(_ response: String, vglaType: String) throws -> [IncomeSuggestion] {
        // 嘗試解析 JSON 回應
        if let data = response.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            return json.compactMap { dict in
                createSuggestionFromDict(dict, vglaType: vglaType)
            }
        }
        
        // 如果無法解析 JSON，返回預設建議
        return getDefaultSuggestions(for: vglaType)
    }
    
    private func createSuggestionFromDict(_ dict: [String: Any], vglaType: String) -> IncomeSuggestion? {
        guard let title = dict["title"] as? String,
              let description = dict["description"] as? String else {
            return nil
        }
        
        return IncomeSuggestion(
            id: UUID().uuidString,
            type: IncomeSuggestionType(rawValue: dict["type"] as? String ?? "other") ?? .other,
            title: title,
            suggestionDescription: description,
            potentialIncome: dict["potentialIncome"] as? String ?? "NT$5,000-15,000/月",
            timeInvestment: dict["timeInvestment"] as? String ?? "5-10 小時/週",
            skillRequirements: dict["skillRequirements"] as? [String] ?? [],
            riskLevel: dict["riskLevel"] as? String ?? "中",
            biblicalPrinciple: dict["biblicalPrinciple"] as? String ?? "勤勞致富（箴言 10:4）",
            steps: dict["steps"] as? [String] ?? [],
            resources: dict["resources"] as? [String] ?? [],
            isRecommended: dict["isRecommended"] as? Bool ?? false,
            matchScore: calculateMatchScore(dict: dict, vglaType: vglaType)
        )
    }
    
    private func calculateMatchScore(dict: [String: Any], vglaType: String) -> Double {
        // 根據 VGLA 類型計算匹配分數
        let type = dict["type"] as? String ?? "other"
        
        switch vglaType {
        case "V":
            return ["online_business", "investment", "passive_income"].contains(type) ? 0.9 : 0.6
        case "G":
            return ["freelance", "skill_development", "part_time"].contains(type) ? 0.9 : 0.6
        case "L":
            return ["investment", "skill_development", "freelance"].contains(type) ? 0.9 : 0.6
        case "A":
            return ["freelance", "part_time", "online_business"].contains(type) ? 0.9 : 0.6
        default:
            return 0.7
        }
    }
    
    private func calculateMatchScores(suggestions: [IncomeSuggestion], vglaType: String) -> [IncomeSuggestion] {
        return suggestions.map { suggestion in
            let updatedSuggestion = suggestion
            updatedSuggestion.matchScore = calculateMatchScore(dict: [
                "type": suggestion.type
            ], vglaType: vglaType)
            return updatedSuggestion
        }.sorted { $0.matchScore > $1.matchScore }
    }
    
    // MARK: - 預設建議庫
    
    private func getVisionTypeSuggestions() -> [IncomeSuggestion] {
        return [
            IncomeSuggestion(
                id: "vision_1",
                type: .online_business,
                title: "建立個人品牌與內容創作",
                suggestionDescription: "利用你的願景思維，建立個人品牌，透過部落格、YouTube、Podcast 分享專業知識",
                potentialIncome: "NT$10,000-50,000/月",
                timeInvestment: "10-15 小時/週",
                skillRequirements: ["內容創作", "社群經營", "品牌行銷"],
                riskLevel: "中",
                biblicalPrinciple: "才幹的比喻（馬太福音 25:14-30）",
                steps: [
                    "選擇專業領域",
                    "建立內容平台",
                    "持續創作優質內容",
                    "建立粉絲社群",
                    "變現模式設計"
                ],
                resources: ["YouTube Creator Academy", "Medium Partner Program", "Patreon"],
                isRecommended: true,
                matchScore: 0.9
            ),
            IncomeSuggestion(
                id: "vision_2",
                type: .investment,
                title: "長期投資與資產配置",
                suggestionDescription: "運用你的長期思維，建立穩健的投資組合，追求長期財富增長",
                potentialIncome: "NT$5,000-20,000/月",
                timeInvestment: "2-5 小時/週",
                skillRequirements: ["投資知識", "風險管理", "市場分析"],
                riskLevel: "中",
                biblicalPrinciple: "智慧投資（箴言 21:5）",
                steps: [
                    "學習投資基礎知識",
                    "制定投資策略",
                    "選擇投資標的",
                    "定期檢視調整",
                    "長期持有"
                ],
                resources: ["投資理財書籍", "線上課程", "投資平台"],
                isRecommended: true,
                matchScore: 0.8
            )
        ]
    }
    
    private func getGraciousTypeSuggestions() -> [IncomeSuggestion] {
        return [
            IncomeSuggestion(
                id: "gracious_1",
                type: .freelance,
                title: "顧問服務與人際關係變現",
                suggestionDescription: "利用你善於建立關係的特質，提供顧問服務，幫助他人解決問題",
                potentialIncome: "NT$15,000-40,000/月",
                timeInvestment: "8-12 小時/週",
                skillRequirements: ["溝通技巧", "專業知識", "客戶服務"],
                riskLevel: "低",
                biblicalPrinciple: "彼此相愛（約翰福音 13:34）",
                steps: [
                    "識別專業技能",
                    "建立服務項目",
                    "建立客戶關係",
                    "提供優質服務",
                    "口碑行銷"
                ],
                resources: ["Upwork", "Freelancer", "104外包網"],
                isRecommended: true,
                matchScore: 0.9
            ),
            IncomeSuggestion(
                id: "gracious_2",
                type: .skill_development,
                title: "教學與培訓服務",
                suggestionDescription: "分享你的知識和經驗，透過教學幫助他人成長",
                potentialIncome: "NT$8,000-25,000/月",
                timeInvestment: "6-10 小時/週",
                skillRequirements: ["教學技巧", "專業知識", "耐心"],
                riskLevel: "低",
                biblicalPrinciple: "教導他人（提摩太後書 2:2）",
                steps: [
                    "確定教學領域",
                    "準備教學材料",
                    "尋找學員",
                    "提供優質教學",
                    "建立口碑"
                ],
                resources: ["線上教學平台", "實體補習班", "企業內訓"],
                isRecommended: true,
                matchScore: 0.8
            )
        ]
    }
    
    private func getLogicTypeSuggestions() -> [IncomeSuggestion] {
        return [
            IncomeSuggestion(
                id: "logic_1",
                type: .freelance,
                title: "數據分析與技術服務",
                suggestionDescription: "運用你的邏輯思維，提供數據分析、程式設計等技術服務",
                potentialIncome: "NT$20,000-60,000/月",
                timeInvestment: "10-20 小時/週",
                skillRequirements: ["程式設計", "數據分析", "邏輯思維"],
                riskLevel: "中",
                biblicalPrinciple: "智慧與知識（箴言 2:6）",
                steps: [
                    "提升技術技能",
                    "建立作品集",
                    "尋找專案機會",
                    "提供優質服務",
                    "建立長期合作"
                ],
                resources: ["GitHub", "Stack Overflow", "技術社群"],
                isRecommended: true,
                matchScore: 0.9
            ),
            IncomeSuggestion(
                id: "logic_2",
                type: .investment,
                title: "量化投資與策略開發",
                suggestionDescription: "運用邏輯分析能力，開發投資策略，進行量化投資",
                potentialIncome: "NT$10,000-30,000/月",
                timeInvestment: "5-10 小時/週",
                skillRequirements: ["投資知識", "程式設計", "數學統計"],
                riskLevel: "高",
                biblicalPrinciple: "智慧理財（路加福音 16:10）",
                steps: [
                    "學習量化投資",
                    "開發投資策略",
                    "回測驗證",
                    "實盤測試",
                    "優化調整"
                ],
                resources: ["Python 金融庫", "投資平台 API", "量化投資課程"],
                isRecommended: true,
                matchScore: 0.8
            )
        ]
    }
    
    private func getActionTypeSuggestions() -> [IncomeSuggestion] {
        return [
            IncomeSuggestion(
                id: "action_1",
                type: .part_time,
                title: "快速變現的兼職工作",
                suggestionDescription: "利用你的行動力，快速找到能立即產生收入的兼職工作",
                potentialIncome: "NT$8,000-20,000/月",
                timeInvestment: "10-15 小時/週",
                skillRequirements: ["執行力", "時間管理", "快速學習"],
                riskLevel: "低",
                biblicalPrinciple: "勤勞工作（帖撒羅尼迦前書 4:11）",
                steps: [
                    "尋找適合的兼職",
                    "快速上手工作",
                    "提高工作效率",
                    "建立良好關係",
                    "爭取更多機會"
                ],
                resources: ["104 兼職", "小雞上工", "Tasker"],
                isRecommended: true,
                matchScore: 0.9
            ),
            IncomeSuggestion(
                id: "action_2",
                type: .online_business,
                title: "快速啟動的網路事業",
                suggestionDescription: "運用你的行動力，快速建立網路事業，如電商、代購等",
                potentialIncome: "NT$15,000-50,000/月",
                timeInvestment: "15-25 小時/週",
                skillRequirements: ["市場敏感度", "執行力", "客戶服務"],
                riskLevel: "中",
                biblicalPrinciple: "抓住機會（傳道書 9:10）",
                steps: [
                    "選擇產品或服務",
                    "快速建立銷售管道",
                    "測試市場反應",
                    "優化營運流程",
                    "擴大業務規模"
                ],
                resources: ["蝦皮", "PChome", "Facebook 社團"],
                isRecommended: true,
                matchScore: 0.8
            )
        ]
    }
    
    private func getGeneralSuggestions() -> [IncomeSuggestion] {
        return [
            IncomeSuggestion(
                id: "general_1",
                type: .skill_development,
                title: "技能提升與證照考取",
                suggestionDescription: "投資自己，提升技能，增加職場競爭力",
                potentialIncome: "NT$5,000-15,000/月",
                timeInvestment: "5-10 小時/週",
                skillRequirements: ["學習能力", "毅力", "時間管理"],
                riskLevel: "低",
                biblicalPrinciple: "智慧勝過金銀（箴言 16:16）",
                steps: [
                    "評估現有技能",
                    "選擇提升方向",
                    "制定學習計劃",
                    "持續學習實踐",
                    "考取相關證照"
                ],
                resources: ["線上課程平台", "專業證照", "技能培訓"],
                isRecommended: true,
                matchScore: 0.7
            )
        ]
    }
}
