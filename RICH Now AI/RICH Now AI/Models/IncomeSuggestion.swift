//
//  IncomeSuggestion.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/27.
//

import Foundation
import SwiftData

@Model
class IncomeSuggestion {
    var id: String
    var type: String
    var title: String
    var suggestionDescription: String
    var potentialIncome: String
    var timeInvestment: String
    var skillRequirements: [String]
    var riskLevel: String
    var biblicalPrinciple: String
    var steps: [String]
    var resources: [String]
    var isRecommended: Bool
    var matchScore: Double
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: String,
        type: IncomeSuggestionType,
        title: String,
        suggestionDescription: String,
        potentialIncome: String,
        timeInvestment: String,
        skillRequirements: [String],
        riskLevel: String,
        biblicalPrinciple: String,
        steps: [String],
        resources: [String],
        isRecommended: Bool,
        matchScore: Double
    ) {
        self.id = id
        self.type = type.rawValue
        self.title = title
        self.suggestionDescription = suggestionDescription
        self.potentialIncome = potentialIncome
        self.timeInvestment = timeInvestment
        self.skillRequirements = skillRequirements
        self.riskLevel = riskLevel
        self.biblicalPrinciple = biblicalPrinciple
        self.steps = steps
        self.resources = resources
        self.isRecommended = isRecommended
        self.matchScore = matchScore
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// 收入建議類型
enum IncomeSuggestionType: String, CaseIterable {
    case online_business = "online_business"
    case investment = "investment"
    case freelance = "freelance"
    case skill_development = "skill_development"
    case part_time = "part_time"
    case consulting = "consulting"
    case creative = "creative"
    case service = "service"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .online_business: return "網路事業"
        case .investment: return "投資理財"
        case .freelance: return "自由職業"
        case .skill_development: return "技能發展"
        case .part_time: return "兼職工作"
        case .consulting: return "諮詢服務"
        case .creative: return "創意工作"
        case .service: return "服務業"
        case .other: return "其他"
        }
    }
}

// 收入建議類別
enum IncomeCategory: String, CaseIterable {
    case freelancing = "freelancing"
    case consulting = "consulting"
    case onlineBusiness = "online_business"
    case investment = "investment"
    case realEstate = "real_estate"
    case passiveIncome = "passive_income"
    case sideHustle = "side_hustle"
    case creative = "creative"
    case technology = "technology"
    case service = "service"
    
    var displayName: String {
        switch self {
        case .freelancing: return "自由職業"
        case .consulting: return "諮詢服務"
        case .onlineBusiness: return "網路事業"
        case .investment: return "投資理財"
        case .realEstate: return "房地產"
        case .passiveIncome: return "被動收入"
        case .sideHustle: return "副業"
        case .creative: return "創意工作"
        case .technology: return "科技服務"
        case .service: return "服務業"
        }
    }
    
    var icon: String {
        switch self {
        case .freelancing: return "💼"
        case .consulting: return "🎯"
        case .onlineBusiness: return "💻"
        case .investment: return "📈"
        case .realEstate: return "🏠"
        case .passiveIncome: return "💰"
        case .sideHustle: return "⚡"
        case .creative: return "🎨"
        case .technology: return "🔧"
        case .service: return "🤝"
        }
    }
}

// 難度等級
enum DifficultyLevel: String, CaseIterable {
    case beginner = "beginner"
    case intermediate = "intermediate"
    case advanced = "advanced"
    case expert = "expert"
    
    var displayName: String {
        switch self {
        case .beginner: return "初級"
        case .intermediate: return "中級"
        case .advanced: return "高級"
        case .expert: return "專家級"
        }
    }
    
    var color: String {
        switch self {
        case .beginner: return "#10B981" // 綠色
        case .intermediate: return "#F59E0B" // 黃色
        case .advanced: return "#EF4444" // 紅色
        case .expert: return "#8B5CF6" // 紫色
        }
    }
}
