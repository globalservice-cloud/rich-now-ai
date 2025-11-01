//
//  VGLAPanel.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import Foundation
import SwiftData
import SwiftUI
import Combine

// VGLA 面板類型
enum VGLAPanelType: String, CaseIterable, Codable {
    // Vision 面板 (4種)
    case vision_dream = "vision_dream"           // 夢想願景面板
    case vision_mission = "vision_mission"       // 使命願景面板
    case vision_legacy = "vision_legacy"         // 傳承願景面板
    case vision_impact = "vision_impact"         // 影響願景面板
    
    // Goal 面板 (4種)
    case goal_short = "goal_short"               // 短期目標面板
    case goal_medium = "goal_medium"             // 中期目標面板
    case goal_long = "goal_long"                 // 長期目標面板
    case goal_life = "goal_life"                 // 人生目標面板
    
    // Logic 面板 (4種)
    case logic_analysis = "logic_analysis"       // 分析邏輯面板
    case logic_strategy = "logic_strategy"       // 策略邏輯面板
    case logic_risk = "logic_risk"               // 風險邏輯面板
    case logic_optimization = "logic_optimization" // 優化邏輯面板
    
    // Action 面板 (4種)
    case action_immediate = "action_immediate"  // 立即行動面板
    case action_plan = "action_plan"             // 計劃行動面板
    case action_execution = "action_execution"    // 執行行動面板
    case action_review = "action_review"         // 檢視行動面板
    
    var dimension: VGLADimension {
        switch self {
        case .vision_dream, .vision_mission, .vision_legacy, .vision_impact:
            return .vision
        case .goal_short, .goal_medium, .goal_long, .goal_life:
            return .goal
        case .logic_analysis, .logic_strategy, .logic_risk, .logic_optimization:
            return .logic
        case .action_immediate, .action_plan, .action_execution, .action_review:
            return .action
        }
    }
    
    var displayName: String {
        return LocalizationManager.shared.localizedString("vglapanel.\(self.rawValue).name")
    }
    
    var description: String {
        return LocalizationManager.shared.localizedString("vglapanel.\(self.rawValue).description")
    }
    
    var icon: String {
        switch self {
        case .vision_dream: return "sparkles"
        case .vision_mission: return "target"
        case .vision_legacy: return "tree"
        case .vision_impact: return "globe"
        case .goal_short: return "clock"
        case .goal_medium: return "calendar"
        case .goal_long: return "infinity"
        case .goal_life: return "heart"
        case .logic_analysis: return "chart.bar"
        case .logic_strategy: return "chess.pawn"
        case .logic_risk: return "exclamationmark.triangle"
        case .logic_optimization: return "gear"
        case .action_immediate: return "bolt"
        case .action_plan: return "list.bullet"
        case .action_execution: return "play"
        case .action_review: return "checkmark.circle"
        }
    }
    
    var primaryColor: Color {
        switch dimension {
        case .vision:
            return Color(red: 0.2, green: 0.6, blue: 1.0) // 藍色系
        case .goal:
            return Color(red: 0.0, green: 0.8, blue: 0.4) // 綠色系
        case .logic:
            return Color(red: 0.9, green: 0.4, blue: 0.0) // 橙色系
        case .action:
            return Color(red: 0.8, green: 0.2, blue: 0.8) // 紫色系
        }
    }
    
    var secondaryColor: Color {
        switch dimension {
        case .vision:
            return Color(red: 0.4, green: 0.7, blue: 1.0)
        case .goal:
            return Color(red: 0.2, green: 0.9, blue: 0.6)
        case .logic:
            return Color(red: 1.0, green: 0.6, blue: 0.2)
        case .action:
            return Color(red: 0.9, green: 0.4, blue: 0.9)
        }
    }
}

// VGLA 維度
enum VGLADimension: String, CaseIterable, Codable {
    case vision = "vision"
    case goal = "goal"
    case logic = "logic"
    case action = "action"
    
    var displayName: String {
        return LocalizationManager.shared.localizedString("vgla.dimension.\(self.rawValue)")
    }
    
    var description: String {
        return LocalizationManager.shared.localizedString("vgla.dimension.\(self.rawValue).description")
    }
}

// VGLA 面板資料模型
@Model
final class VGLAPanel {
    @Attribute(.unique) var id: UUID = UUID()
    var type: VGLAPanelType
    var name: String
    var panelDescription: String
    var isUnlocked: Bool
    var isPurchased: Bool
    var purchasePrice: Double
    var currency: String
    var category: String
    var tags: [String]
    var features: [String]
    var isDefault: Bool
    var sortOrder: Int
    var createdAt: Date
    var updatedAt: Date
    
    // 關聯
    @Relationship(deleteRule: .nullify, inverse: \User.vglaPanels) var user: User?
    
    init(type: VGLAPanelType, name: String, description: String, isUnlocked: Bool = false, isPurchased: Bool = false, purchasePrice: Double = 0.0, currency: String = "USD", category: String = "basic", tags: [String] = [], features: [String] = [], isDefault: Bool = false, sortOrder: Int = 0) {
        self.type = type
        self.name = name
        self.panelDescription = description
        self.isUnlocked = isUnlocked
        self.isPurchased = isPurchased
        self.purchasePrice = purchasePrice
        self.currency = currency
        self.category = category
        self.tags = tags
        self.features = features
        self.isDefault = isDefault
        self.sortOrder = sortOrder
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// VGLA 面板配置
struct VGLAPanelConfiguration {
    let type: VGLAPanelType
    let name: String
    let description: String
    let isDefault: Bool
    let purchasePrice: Double
    let category: String
    let tags: [String]
    let features: [String]
    let sortOrder: Int
    
    static let allPanels: [VGLAPanelConfiguration] = [
        // Vision 面板
        VGLAPanelConfiguration(
            type: .vision_dream,
            name: "Dream Vision Panel",
            description: "Visualize your financial dreams and aspirations",
            isDefault: true,
            purchasePrice: 0.0,
            category: "vision",
            tags: ["dream", "aspiration", "visualization"],
            features: ["Dream tracking", "Visualization tools", "Inspiration quotes"],
            sortOrder: 1
        ),
        VGLAPanelConfiguration(
            type: .vision_mission,
            name: "Mission Vision Panel",
            description: "Define your financial mission and purpose",
            isDefault: false,
            purchasePrice: 2.99,
            category: "vision",
            tags: ["mission", "purpose", "values"],
            features: ["Mission statement", "Value alignment", "Purpose tracking"],
            sortOrder: 2
        ),
        VGLAPanelConfiguration(
            type: .vision_legacy,
            name: "Legacy Vision Panel",
            description: "Plan your financial legacy and generational wealth",
            isDefault: false,
            purchasePrice: 4.99,
            category: "vision",
            tags: ["legacy", "generation", "inheritance"],
            features: ["Legacy planning", "Generational wealth", "Estate planning"],
            sortOrder: 3
        ),
        VGLAPanelConfiguration(
            type: .vision_impact,
            name: "Impact Vision Panel",
            description: "Create positive financial impact in your community",
            isDefault: false,
            purchasePrice: 3.99,
            category: "vision",
            tags: ["impact", "community", "philanthropy"],
            features: ["Impact tracking", "Community goals", "Philanthropy planning"],
            sortOrder: 4
        ),
        
        // Goal 面板
        VGLAPanelConfiguration(
            type: .goal_short,
            name: "Short-term Goals Panel",
            description: "Track and achieve your immediate financial goals",
            isDefault: true,
            purchasePrice: 0.0,
            category: "goal",
            tags: ["short-term", "immediate", "quick-wins"],
            features: ["Goal tracking", "Progress monitoring", "Deadline management"],
            sortOrder: 5
        ),
        VGLAPanelConfiguration(
            type: .goal_medium,
            name: "Medium-term Goals Panel",
            description: "Plan and execute your 1-3 year financial objectives",
            isDefault: false,
            purchasePrice: 2.99,
            category: "goal",
            tags: ["medium-term", "planning", "objectives"],
            features: ["Strategic planning", "Milestone tracking", "Resource allocation"],
            sortOrder: 6
        ),
        VGLAPanelConfiguration(
            type: .goal_long,
            name: "Long-term Goals Panel",
            description: "Build your 5+ year financial future",
            isDefault: false,
            purchasePrice: 4.99,
            category: "goal",
            tags: ["long-term", "future", "retirement"],
            features: ["Retirement planning", "Future forecasting", "Long-term strategy"],
            sortOrder: 7
        ),
        VGLAPanelConfiguration(
            type: .goal_life,
            name: "Life Goals Panel",
            description: "Align your financial goals with life aspirations",
            isDefault: false,
            purchasePrice: 3.99,
            category: "goal",
            tags: ["life", "aspiration", "holistic"],
            features: ["Life alignment", "Holistic planning", "Aspiration tracking"],
            sortOrder: 8
        ),
        
        // Logic 面板
        VGLAPanelConfiguration(
            type: .logic_analysis,
            name: "Analysis Logic Panel",
            description: "Deep dive into your financial data and patterns",
            isDefault: true,
            purchasePrice: 0.0,
            category: "logic",
            tags: ["analysis", "data", "insights"],
            features: ["Data analysis", "Pattern recognition", "Insight generation"],
            sortOrder: 9
        ),
        VGLAPanelConfiguration(
            type: .logic_strategy,
            name: "Strategy Logic Panel",
            description: "Develop comprehensive financial strategies",
            isDefault: false,
            purchasePrice: 2.99,
            category: "logic",
            tags: ["strategy", "planning", "framework"],
            features: ["Strategic framework", "Scenario planning", "Decision trees"],
            sortOrder: 10
        ),
        VGLAPanelConfiguration(
            type: .logic_risk,
            name: "Risk Logic Panel",
            description: "Assess and manage financial risks effectively",
            isDefault: false,
            purchasePrice: 4.99,
            category: "logic",
            tags: ["risk", "management", "assessment"],
            features: ["Risk assessment", "Mitigation strategies", "Contingency planning"],
            sortOrder: 11
        ),
        VGLAPanelConfiguration(
            type: .logic_optimization,
            name: "Optimization Logic Panel",
            description: "Optimize your financial performance and efficiency",
            isDefault: false,
            purchasePrice: 3.99,
            category: "logic",
            tags: ["optimization", "efficiency", "performance"],
            features: ["Performance optimization", "Efficiency analysis", "ROI tracking"],
            sortOrder: 12
        ),
        
        // Action 面板
        VGLAPanelConfiguration(
            type: .action_immediate,
            name: "Immediate Action Panel",
            description: "Take quick actions to improve your financial situation",
            isDefault: true,
            purchasePrice: 0.0,
            category: "action",
            tags: ["immediate", "quick", "urgent"],
            features: ["Quick actions", "Urgent tasks", "Immediate improvements"],
            sortOrder: 13
        ),
        VGLAPanelConfiguration(
            type: .action_plan,
            name: "Action Planning Panel",
            description: "Create detailed action plans for your financial goals",
            isDefault: false,
            purchasePrice: 2.99,
            category: "action",
            tags: ["planning", "detailed", "structured"],
            features: ["Action planning", "Task breakdown", "Timeline creation"],
            sortOrder: 14
        ),
        VGLAPanelConfiguration(
            type: .action_execution,
            name: "Execution Action Panel",
            description: "Execute your financial plans with precision",
            isDefault: false,
            purchasePrice: 4.99,
            category: "action",
            tags: ["execution", "implementation", "precision"],
            features: ["Execution tracking", "Implementation monitoring", "Performance metrics"],
            sortOrder: 15
        ),
        VGLAPanelConfiguration(
            type: .action_review,
            name: "Review Action Panel",
            description: "Review and adjust your financial actions regularly",
            isDefault: false,
            purchasePrice: 3.99,
            category: "action",
            tags: ["review", "adjustment", "improvement"],
            features: ["Regular reviews", "Adjustment tracking", "Continuous improvement"],
            sortOrder: 16
        )
    ]
}

// VGLA 面板管理器
@MainActor
class VGLAPanelManager: ObservableObject {
    static let shared = VGLAPanelManager()
    
    @Published var availablePanels: [VGLAPanel] = []
    @Published var userPanels: [VGLAPanel] = []
    @Published var purchasedPanels: [VGLAPanel] = []
    
    private init() {
        loadPanels()
    }
    
    func loadPanels() {
        // 載入所有可用的面板配置
        availablePanels = VGLAPanelConfiguration.allPanels.map { config in
            VGLAPanel(
                type: config.type,
                name: config.name,
                description: config.description,
                isUnlocked: config.isDefault,
                isPurchased: config.isDefault,
                purchasePrice: config.purchasePrice,
                currency: "USD",
                category: config.category,
                tags: config.tags,
                features: config.features,
                isDefault: config.isDefault,
                sortOrder: config.sortOrder
            )
        }
    }
    
    func getPanelsByDimension(_ dimension: VGLADimension) -> [VGLAPanel] {
        return availablePanels.filter { $0.type.dimension == dimension }
    }
    
    func getDefaultPanels() -> [VGLAPanel] {
        return availablePanels.filter { $0.isDefault }
    }
    
    func getPurchasedPanels() -> [VGLAPanel] {
        return availablePanels.filter { $0.isPurchased }
    }
    
    func purchasePanel(_ panel: VGLAPanel) {
        if let index = availablePanels.firstIndex(where: { $0.id == panel.id }) {
            availablePanels[index].isPurchased = true
            availablePanels[index].isUnlocked = true
            availablePanels[index].updatedAt = Date()
        }
    }
    
    func unlockPanel(_ panel: VGLAPanel) {
        if let index = availablePanels.firstIndex(where: { $0.id == panel.id }) {
            availablePanels[index].isUnlocked = true
            availablePanels[index].updatedAt = Date()
        }
    }
}
