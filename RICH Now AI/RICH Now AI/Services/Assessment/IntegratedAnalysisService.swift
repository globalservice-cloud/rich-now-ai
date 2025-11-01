//
//  IntegratedAnalysisService.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import Foundation

// MARK: - 整合分析服務
class IntegratedAnalysisService {
    
    // MARK: - 整合分析結果
    struct IntegratedAnalysisResult {
        let vglaType: String
        let tkiMode: TKIMode?
        let combinedPersonality: String
        let financialDecisionStyle: String
        let strengths: [String]
        let challenges: [String]
        let recommendations: [String]
        let gabrielPersonality: String
        let conversationStyle: String
    }
    
    // MARK: - 主要分析方法
    static func analyzeCombinedProfile(
        vglaResult: VGLAScore,
        tkiResult: TKIResult?
    ) -> IntegratedAnalysisResult {
        
        let vglaType = determineVGLACombination(vglaResult)
        let tkiMode = tkiResult?.primaryMode
        
        let combinedPersonality = generateCombinedPersonality(
            vglaType: vglaType,
            tkiMode: tkiMode
        )
        
        let financialDecisionStyle = generateFinancialDecisionStyle(
            vglaType: vglaType,
            tkiMode: tkiMode
        )
        
        let (strengths, challenges) = analyzeStrengthsAndChallenges(
            vglaType: vglaType,
            tkiMode: tkiMode
        )
        
        let recommendations = generateRecommendations(
            vglaType: vglaType,
            tkiMode: tkiMode,
            strengths: strengths,
            challenges: challenges
        )
        
        let (gabrielPersonality, conversationStyle) = determineGabrielStyle(
            vglaType: vglaType,
            tkiMode: tkiMode
        )
        
        return IntegratedAnalysisResult(
            vglaType: vglaType,
            tkiMode: tkiMode,
            combinedPersonality: combinedPersonality,
            financialDecisionStyle: financialDecisionStyle,
            strengths: strengths,
            challenges: challenges,
            recommendations: recommendations,
            gabrielPersonality: gabrielPersonality,
            conversationStyle: conversationStyle
        )
    }
    
    // MARK: - VGLA 組合判斷
    private static func determineVGLACombination(_ score: VGLAScore) -> String {
        let scores = [
            ("V", score.total["V"] ?? 0),
            ("G", score.total["G"] ?? 0),
            ("L", score.total["L"] ?? 0),
            ("A", score.total["A"] ?? 0)
        ]
        
        let sortedScores = scores.sorted { $0.1 > $1.1 }
        let primary = sortedScores[0].0
        let secondary = sortedScores[1].0
        
        return "\(primary)\(secondary)"
    }
    
    // MARK: - 整合性格分析
    @MainActor
    private static func generateCombinedPersonality(
        vglaType: String,
        tkiMode: TKIMode?
    ) -> String {
        
        let vglaDescription = getVGLADescription(vglaType)
        
        if let mode = tkiMode {
            let tkiDescription = LocalizationManager.shared.localizedString(mode.displayName)
            return LocalizationManager.shared.localizedString("integrated.personality.with_tki")
                .replacingOccurrences(of: "%VGLA%", with: vglaDescription)
                .replacingOccurrences(of: "%TKI%", with: tkiDescription)
        } else {
            return LocalizationManager.shared.localizedString("integrated.personality.vgla_only")
                .replacingOccurrences(of: "%VGLA%", with: vglaDescription)
        }
    }
    
    // MARK: - 財務決策風格
    @MainActor
    private static func generateFinancialDecisionStyle(
        vglaType: String,
        tkiMode: TKIMode?
    ) -> String {
        
        let vglaStyle = getVGLAFinancialStyle(vglaType)
        
        if let mode = tkiMode {
            let tkiStyle = LocalizationManager.shared.localizedString(mode.financialDecisionStyleKey)
            return LocalizationManager.shared.localizedString("integrated.financial_style.with_tki")
                .replacingOccurrences(of: "%VGLA%", with: vglaStyle)
                .replacingOccurrences(of: "%TKI%", with: tkiStyle)
        } else {
            return vglaStyle
        }
    }
    
    // MARK: - 優勢與挑戰分析
    @MainActor
    private static func analyzeStrengthsAndChallenges(
        vglaType: String,
        tkiMode: TKIMode?
    ) -> (strengths: [String], challenges: [String]) {
        
        var strengths: [String] = []
        var challenges: [String] = []
        
        // VGLA 優勢
        strengths.append(contentsOf: getVGLAStrengths(vglaType))
        
        // TKI 優勢
        if let mode = tkiMode {
            strengths.append(contentsOf: getTKIStrengths(mode))
        }
        
        // VGLA 挑戰
        challenges.append(contentsOf: getVGLAChallenges(vglaType))
        
        // TKI 挑戰
        if let mode = tkiMode {
            challenges.append(contentsOf: getTKIChallenges(mode))
        }
        
        return (strengths, challenges)
    }
    
    // MARK: - 建議生成
    @MainActor
    private static func generateRecommendations(
        vglaType: String,
        tkiMode: TKIMode?,
        strengths: [String],
        challenges: [String]
    ) -> [String] {
        
        var recommendations: [String] = []
        
        // 基於 VGLA 的建議
        recommendations.append(contentsOf: getVGLARecommendations(vglaType))
        
        // 基於 TKI 的建議
        if let mode = tkiMode {
            recommendations.append(contentsOf: getTKIRecommendations(mode))
        }
        
        // 整合建議
        recommendations.append(contentsOf: getIntegratedRecommendations(
            vglaType: vglaType,
            tkiMode: tkiMode
        ))
        
        return Array(Set(recommendations)) // 去重
    }
    
    // MARK: - 加百列風格設定
    private static func determineGabrielStyle(
        vglaType: String,
        tkiMode: TKIMode?
    ) -> (personality: String, conversationStyle: String) {
        
        let gabrielPersonality = getGabrielPersonality(vglaType: vglaType, tkiMode: tkiMode)
        let conversationStyle = getConversationStyle(vglaType: vglaType, tkiMode: tkiMode)
        
        return (gabrielPersonality, conversationStyle)
    }
    
    // MARK: - 輔助方法
    
    private static func getVGLADescription(_ type: String) -> String {
        return LocalizationManager.shared.localizedString("vgla.combination.\(type.lowercased()).description")
    }
    
    private static func getVGLAFinancialStyle(_ type: String) -> String {
        return LocalizationManager.shared.localizedString("vgla.combination.\(type.lowercased()).financial_style")
    }
    
    private static func getVGLAStrengths(_ type: String) -> [String] {
        return [
            LocalizationManager.shared.localizedString("vgla.combination.\(type.lowercased()).strength.1"),
            LocalizationManager.shared.localizedString("vgla.combination.\(type.lowercased()).strength.2")
        ]
    }
    
    private static func getVGLAChallenges(_ type: String) -> [String] {
        return [
            LocalizationManager.shared.localizedString("vgla.combination.\(type.lowercased()).challenge.1"),
            LocalizationManager.shared.localizedString("vgla.combination.\(type.lowercased()).challenge.2")
        ]
    }
    
    private static func getVGLARecommendations(_ type: String) -> [String] {
        return [
            LocalizationManager.shared.localizedString("vgla.combination.\(type.lowercased()).recommendation.1"),
            LocalizationManager.shared.localizedString("vgla.combination.\(type.lowercased()).recommendation.2")
        ]
    }
    
    private static func getTKIStrengths(_ mode: TKIMode) -> [String] {
        return [
            LocalizationManager.shared.localizedString("tki.\(mode.rawValue).strength.1"),
            LocalizationManager.shared.localizedString("tki.\(mode.rawValue).strength.2")
        ]
    }
    
    private static func getTKIChallenges(_ mode: TKIMode) -> [String] {
        return [
            LocalizationManager.shared.localizedString("tki.\(mode.rawValue).challenge.1"),
            LocalizationManager.shared.localizedString("tki.\(mode.rawValue).challenge.2")
        ]
    }
    
    private static func getTKIRecommendations(_ mode: TKIMode) -> [String] {
        return [
            LocalizationManager.shared.localizedString("tki.\(mode.rawValue).recommendation.1"),
            LocalizationManager.shared.localizedString("tki.\(mode.rawValue).recommendation.2")
        ]
    }
    
    private static func getIntegratedRecommendations(
        vglaType: String,
        tkiMode: TKIMode?
    ) -> [String] {
        
        var recommendations: [String] = []
        
        // 根據特定組合給出建議
        let combination = "\(vglaType)\(tkiMode?.rawValue ?? "")"
        
        switch combination {
        case "VAcompeting":
            recommendations.append(LocalizationManager.shared.localizedString("integrated.recommendation.va_competing"))
        case "LGcollaborating":
            recommendations.append(LocalizationManager.shared.localizedString("integrated.recommendation.lg_collaborating"))
        case "GAaccommodating":
            recommendations.append(LocalizationManager.shared.localizedString("integrated.recommendation.ga_accommodating"))
        default:
            recommendations.append(LocalizationManager.shared.localizedString("integrated.recommendation.general"))
        }
        
        return recommendations
    }
    
    private static func getGabrielPersonality(
        vglaType: String,
        tkiMode: TKIMode?
    ) -> String {
        
        if let mode = tkiMode {
            return LocalizationManager.shared.localizedString("gabriel.personality.\(vglaType.lowercased())_\(mode.rawValue)")
        } else {
            return LocalizationManager.shared.localizedString("gabriel.personality.\(vglaType.lowercased())_only")
        }
    }
    
    private static func getConversationStyle(
        vglaType: String,
        tkiMode: TKIMode?
    ) -> String {
        
        if let mode = tkiMode {
            return LocalizationManager.shared.localizedString("gabriel.conversation_style.\(vglaType.lowercased())_\(mode.rawValue)")
        } else {
            return LocalizationManager.shared.localizedString("gabriel.conversation_style.\(vglaType.lowercased())_only")
        }
    }
}

// MARK: - 擴展 String 支援本地化 (已移至 LocalizationManager)
