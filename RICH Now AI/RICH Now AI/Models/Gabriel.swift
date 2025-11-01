//
//  Gabriel.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import Foundation
import SwiftUI
import SwiftData
import Combine

// 加百列的對話風格
enum GabrielConversationStyle: String, CaseIterable, Codable {
    case formal = "formal"         // 正式
    case casual = "casual"         // 隨意
    case friendly = "friendly"     // 友善
    case professional = "professional" // 專業
    
    var displayName: String {
        switch self {
        case .formal:
            return LocalizationManager.shared.localizedString("gabriel.conversation.formal")
        case .casual:
            return LocalizationManager.shared.localizedString("gabriel.conversation.casual")
        case .friendly:
            return LocalizationManager.shared.localizedString("gabriel.conversation.friendly")
        case .professional:
            return LocalizationManager.shared.localizedString("gabriel.conversation.professional")
        }
    }
}

// 加百列的服裝類型
enum GabrielOutfit: String, CaseIterable, Codable {
    case classic = "classic"         // 經典
    case modern = "modern"           // 現代
    case casual = "casual"           // 休閒
    case formal = "formal"           // 正式
    case festive = "festive"         // 節慶
    case seasonal = "seasonal"       // 季節性
    
    var displayName: String {
        switch self {
        case .classic:
            return LocalizationManager.shared.localizedString("gabriel.outfit.classic")
        case .modern:
            return LocalizationManager.shared.localizedString("gabriel.outfit.modern")
        case .casual:
            return LocalizationManager.shared.localizedString("gabriel.outfit.casual")
        case .formal:
            return LocalizationManager.shared.localizedString("gabriel.outfit.formal")
        case .festive:
            return LocalizationManager.shared.localizedString("gabriel.outfit.festive")
        case .seasonal:
            return LocalizationManager.shared.localizedString("gabriel.outfit.seasonal")
        }
    }
    
    var icon: String {
        switch self {
        case .classic: return "person.circle"
        case .modern: return "person.circle.fill"
        case .casual: return "tshirt"
        case .formal: return "suit.heart"
        case .festive: return "party.popper"
        case .seasonal: return "leaf"
        }
    }
}

// 加百列的人格類型
enum GabrielPersonality: String, CaseIterable, Codable {
    case wise = "wise"           // 智慧型
    case encouraging = "encouraging" // 鼓勵型
    case analytical = "analytical"    // 分析型
    case supportive = "supportive"   // 支持型
    
    var displayName: String {
        switch self {
        case .wise:
            return LocalizationManager.shared.localizedString("gabriel.personality.wise")
        case .encouraging:
            return LocalizationManager.shared.localizedString("gabriel.personality.encouraging")
        case .analytical:
            return LocalizationManager.shared.localizedString("gabriel.personality.analytical")
        case .supportive:
            return LocalizationManager.shared.localizedString("gabriel.personality.supportive")
        }
    }
    
    var description: String {
        switch self {
        case .wise:
            return LocalizationManager.shared.localizedString("gabriel.personality.wise.description")
        case .encouraging:
            return LocalizationManager.shared.localizedString("gabriel.personality.encouraging.description")
        case .analytical:
            return LocalizationManager.shared.localizedString("gabriel.personality.analytical.description")
        case .supportive:
            return LocalizationManager.shared.localizedString("gabriel.personality.supportive.description")
        }
    }
}

// 加百列的情緒狀態
enum GabrielMood: String, CaseIterable, Codable {
    case friendly = "friendly"       // 友善
    case excited = "excited"         // 興奮
    case concerned = "concerned"     // 關心
    case calm = "calm"              // 平靜
    case joyful = "joyful"          // 喜樂
    case empathetic = "empathetic"   // 同理心
    
    var displayName: String {
        switch self {
        case .friendly:
            return LocalizationManager.shared.localizedString("gabriel.mood.friendly")
        case .excited:
            return LocalizationManager.shared.localizedString("gabriel.mood.excited")
        case .concerned:
            return LocalizationManager.shared.localizedString("gabriel.mood.concerned")
        case .calm:
            return LocalizationManager.shared.localizedString("gabriel.mood.calm")
        case .joyful:
            return LocalizationManager.shared.localizedString("gabriel.mood.joyful")
        case .empathetic:
            return LocalizationManager.shared.localizedString("gabriel.mood.empathetic")
        }
    }
    
    var description: String {
        switch self {
        case .friendly:
            return LocalizationManager.shared.localizedString("gabriel.mood.friendly.description")
        case .excited:
            return LocalizationManager.shared.localizedString("gabriel.mood.excited.description")
        case .concerned:
            return LocalizationManager.shared.localizedString("gabriel.mood.concerned.description")
        case .calm:
            return LocalizationManager.shared.localizedString("gabriel.mood.calm.description")
        case .joyful:
            return LocalizationManager.shared.localizedString("gabriel.mood.joyful.description")
        case .empathetic:
            return LocalizationManager.shared.localizedString("gabriel.mood.empathetic.description")
        }
    }
}

// 加百列性別選擇
enum GabrielGender: String, Codable, CaseIterable {
    case male = "male"     // 男性天使長
    case female = "female" // 女性天使
    
    var displayName: String {
        switch self {
        case .male: return "加百列天使長"
        case .female: return "加百列天使"
        }
    }
    
    var characteristics: [String] {
        switch self {
        case .male: return ["堅定", "智慧", "成熟", "專業"]
        case .female: return ["溫柔", "體貼", "親切", "關懷"]
        }
    }
    
    var avatarImageName: String {
        switch self {
        case .male: return "gabriel_male"
        case .female: return "gabriel_female"
        }
    }
    
    var voiceStyle: String {
        switch self {
        case .male: return "成熟、穩重、專業的聲音"
        case .female: return "溫柔、親切、關懷的聲音"
        }
    }
}

// 對話風格
enum ConversationStyle: String, Codable, CaseIterable {
    case formal = "formal"           // 正式
    case friendly = "friendly"       // 親切
    case casual = "casual"           // 輕鬆
    case professional = "professional" // 專業
    
    var displayName: String {
        switch self {
        case .formal: return "正式"
        case .friendly: return "親切"
        case .casual: return "輕鬆"
        case .professional: return "專業"
        }
    }
    
    var icon: String {
        switch self {
        case .formal: return "👔"
        case .friendly: return "😊"
        case .casual: return "🎉"
        case .professional: return "💼"
        }
    }
    
    var description: String {
        switch self {
        case .formal: return "禮貌、尊重、有距離感"
        case .friendly: return "親切、溫暖、像朋友"
        case .casual: return "輕鬆、隨意、像家人"
        case .professional: return "專業、高效、像顧問"
        }
    }
    
    // 根據對話風格調整提示詞
    func getSystemPromptModifier() -> String {
        switch self {
        case .formal:
            return "請用正式、禮貌的語氣與使用者對話，保持適當的專業距離。使用敬語，稱呼使用者為「您」。"
        case .friendly:
            return "請用親切、溫暖的語氣與使用者對話，像是關心的朋友。使用「你」稱呼，表達真誠的關懷。"
        case .casual:
            return "請用輕鬆、隨意的語氣與使用者對話，像是親密的家人。可以使用口語化表達，展現親近感。"
        case .professional:
            return "請用專業、高效的語氣與使用者對話，像是資深的財務顧問。提供具體、可行的建議。"
        }
    }
}

// 報告頻率設定
enum ReportFrequency: String, Codable, CaseIterable {
    case daily = "daily"           // 每天
    case weekly = "weekly"         // 每週
    case biweekly = "biweekly"     // 雙週
    case monthly = "monthly"       // 每月
    case quarterly = "quarterly"   // 每季
    case yearly = "yearly"         // 每年
    case never = "never"          // 不要寄給我
    
    var displayName: String {
        switch self {
        case .daily: return "每天"
        case .weekly: return "每週"
        case .biweekly: return "雙週"
        case .monthly: return "每月"
        case .quarterly: return "每季"
        case .yearly: return "每年"
        case .never: return "不要寄給我"
        }
    }
    
    var icon: String {
        switch self {
        case .daily: return "📅"
        case .weekly: return "📊"
        case .biweekly: return "📈"
        case .monthly: return "📋"
        case .quarterly: return "📊"
        case .yearly: return "📈"
        case .never: return "🔕"
        }
    }
    
    var description: String {
        switch self {
        case .daily: return "每天收到財務日報"
        case .weekly: return "每週日收到財務週報"
        case .biweekly: return "每兩週收到財務報告"
        case .monthly: return "每月初收到財務月報"
        case .quarterly: return "每季收到財務季報"
        case .yearly: return "每年收到財務年報"
        case .never: return "不接收 Email 報告"
        }
    }
}

// 用戶性別選擇
enum UserGender: String, Codable, CaseIterable {
    case male = "male"           // 男性
    case female = "female"       // 女性
    case preferNotToSay = "prefer_not_to_say"  // 不透露
    
    var displayName: String {
        switch self {
        case .male: return "男性"
        case .female: return "女性"
        case .preferNotToSay: return "不透露"
        }
    }
    
    var icon: String {
        switch self {
        case .male: return "👨"
        case .female: return "👩"
        case .preferNotToSay: return "🤐"
        }
    }
}

// 迎賓流程步驟
enum OnboardingStep: Int, CaseIterable {
    case selectGabriel = 0      // 選擇加百列性別
    case gabrielAppears = 1     // 加百列現身
    case getName = 2            // 獲取稱呼
    case getGender = 3          // 獲取性別
    case getEmail = 4           // 獲取 Email
    case setReportFrequency = 5 // 設定報告頻率
    case setConversationStyle = 6 // 設定對話風格
    case introduceVGLA = 7      // 介紹 VGLA
    case vglaAssessment = 8     // VGLA 測驗
    case vglaResult = 9         // VGLA 結果揭曉
    case selectAIFeatures = 10  // 選擇 AI 功能方案
    case themePanel = 11        // 專屬面板驚喜
    case complete = 12          // 完成迎賓
    
    var title: String {
        switch self {
        case .selectGabriel: return "選擇你的守護者"
        case .gabrielAppears: return "加百列現身"
        case .getName: return "認識彼此"
        case .getGender: return "了解你"
        case .getEmail: return "保持聯繫"
        case .setReportFrequency: return "報告設定"
        case .setConversationStyle: return "對話風格"
        case .introduceVGLA: return "VGLA 介紹"
        case .vglaAssessment: return "性格探索"
        case .vglaResult: return "驚喜揭曉"
        case .selectAIFeatures: return "AI 功能選擇"
        case .themePanel: return "專屬面板"
        case .complete: return "開始旅程"
        }
    }
    
    var canSkip: Bool {
        switch self {
        case .getEmail, .setReportFrequency, .setConversationStyle:
            return true
        default:
            return false
        }
    }
}

// 迎賓對話訊息
struct OnboardingMessage: Identifiable {
    let id = UUID()
    let speaker: MessageSpeaker
    let content: String
    let quickReplies: [String]?
    let animation: AnimationType
    let timestamp: Date
    
    init(speaker: MessageSpeaker, content: String, quickReplies: [String]? = nil, animation: AnimationType = .fadeIn) {
        self.speaker = speaker
        self.content = content
        self.quickReplies = quickReplies
        self.animation = animation
        self.timestamp = Date()
    }
}

enum MessageSpeaker: Equatable {
    case gabriel(GabrielGender)
    case user
    case system
}

enum AnimationType {
    case fadeIn
    case slideIn
    case bounce
    case glow
    case none
}

// 迎賓狀態管理
class OnboardingState: ObservableObject {
    @Published var currentStep: OnboardingStep = .selectGabriel
    @Published var selectedGabriel: GabrielGender?
    @Published var userName: String = ""
    @Published var userGender: UserGender?
    @Published var userEmail: String = ""
    @Published var reportFrequency: ReportFrequency = .monthly
    @Published var conversationStyle: ConversationStyle = .friendly
    @Published var messages: [OnboardingMessage] = []
    @Published var isComplete: Bool = false
    @Published var hasShownWelcome: Bool = false
    
    // VGLA 測驗相關
    @Published var vglaAnswers: [Int: String] = [:] // 題號 : 答案
    @Published var vglaCurrentQuestion: Int = 1
    @Published var vglaIsComplete: Bool = false
    @Published var vglaResult: VGLAResult?
    
    func nextStep() {
        if let nextStep = OnboardingStep(rawValue: currentStep.rawValue + 1) {
            currentStep = nextStep
        }
        
        // 保存加百列性別選擇
        if let gabriel = selectedGabriel {
            UserDefaults.standard.set(gabriel.rawValue, forKey: "selectedGabrielGender")
        }
        
        // 注意：進度保存由 OnboardingCoordinatorView 的 onChange 處理，避免重複保存
    }
    
    func skipStep() {
        if currentStep.canSkip {
            nextStep()
        }
    }
    
    func addMessage(_ message: OnboardingMessage) {
        withAnimation {
            messages.append(message)
        }
    }
    
    func addGabrielMessage(_ content: String, quickReplies: [String]? = nil) {
        guard let gabriel = selectedGabriel else { return }
        let message = OnboardingMessage(
            speaker: .gabriel(gabriel),
            content: content,
            quickReplies: quickReplies,
            animation: .slideIn
        )
        addMessage(message)
    }
    
    func addUserMessage(_ content: String) {
        let message = OnboardingMessage(
            speaker: .user,
            content: content,
            animation: .slideIn
        )
        addMessage(message)
    }
    
    // 獲取加百列的個性化問候
    func getGabrielGreeting() -> String {
        guard let gabriel = selectedGabriel else { return "你好！" }
        
        switch gabriel {
        case .male:
            return "你好！我是加百列，你的財務守護天使長。我將以智慧和堅定，引導你實現財務目標。"
        case .female:
            return "你好！我是加百列，你的財務守護天使。我會用溫柔和關懷，陪伴你實現每一個夢想。"
        }
    }
    
    // 根據用戶名生成個性化回應
    func getPersonalizedResponse(for userName: String) -> String {
        let responses = [
            "\(userName)，好名字！很高興認識你 ✨",
            "\(userName)，這個名字真好聽！期待與你一起成長 💝",
            "很開心認識你，\(userName)！讓我們一起創造美好的未來 🌟"
        ]
        return responses.randomElement() ?? "\(userName)，很高興認識你！"
    }
}

// MARK: - 加百列模型
@Model
final class Gabriel {
    @Attribute(.unique) var id: UUID = UUID()
    var gender: GabrielGender
    var personality: GabrielPersonality
    var mood: GabrielMood
    var conversationStyle: GabrielConversationStyle
    var createdAt: Date
    var updatedAt: Date
    
    init(gender: GabrielGender, personality: GabrielPersonality, mood: GabrielMood, conversationStyle: GabrielConversationStyle) {
        self.gender = gender
        self.personality = personality
        self.mood = mood
        self.conversationStyle = conversationStyle
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

