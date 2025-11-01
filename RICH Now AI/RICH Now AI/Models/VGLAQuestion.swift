//
//  VGLAQuestion.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import Foundation
import Combine

// VGLA 測驗題目模型
struct VGLAQuestion: Identifiable, Codable {
    let id: Int
    let text: String
    let dimension: VGLADimension
    let phase: VGLAPhase
    
    enum VGLAPhase: String, Codable, CaseIterable {
        case like = "like"           // 喜歡階段
        case dislike = "dislike"     // 不喜歡階段
        
        var displayName: String {
            switch self {
            case .like: return "喜歡"
            case .dislike: return "不喜歡"
            }
        }
        
        var description: String {
            switch self {
            case .like: return "選擇你最喜歡的選項"
            case .dislike: return "選擇你最不喜歡的選項"
            }
        }
    }
    
    enum VGLADimension: String, Codable, CaseIterable {
        case vision = "V"     // 願景
        case goal = "G"       // 目標
        case logic = "L"      // 邏輯
        case action = "A"     // 行動
        
        var displayName: String {
            switch self {
            case .vision: return "願景思考"
            case .goal: return "感性關懷"
            case .logic: return "邏輯分析"
            case .action: return "行動實踐"
            }
        }
        
        var icon: String {
            switch self {
            case .vision: return "🌟"
            case .goal: return "💝"
            case .logic: return "🧠"
            case .action: return "⚡"
            }
        }
    }
    
    struct VGLAOption: Identifiable, Codable {
        let id: String
        let text: String
        let dimension: VGLADimension
        let icon: String
        
        enum VGLADimension: String, Codable, CaseIterable {
            case vision = "V"     // 願景
            case goal = "G"       // 目標
            case logic = "L"      // 邏輯
            case action = "A"     // 行動
            
            var displayName: String {
                switch self {
                case .vision: return "願景思考"
                case .goal: return "感性關懷"
                case .logic: return "邏輯分析"
                case .action: return "行動實踐"
                }
            }
            
            var icon: String {
                switch self {
                case .vision: return "🌟"
                case .goal: return "💝"
                case .logic: return "🧠"
                case .action: return "⚡"
                }
            }
            
            var color: String {
                switch self {
                case .vision: return "#F59E0B"
                case .goal: return "#EC4899"
                case .logic: return "#3B82F6"
                case .action: return "#10B981"
                }
            }
        }
    }
}

// VGLA 測驗答案
struct VGLAResponse: Identifiable, Codable, Equatable {
    let id: Int
    let questionId: Int
    let selectedOption: String
    let dimension: VGLAQuestion.VGLADimension
    let timestamp: Date
    
    init(questionId: Int, selectedOption: String, dimension: VGLAQuestion.VGLADimension) {
        self.id = questionId
        self.questionId = questionId
        self.selectedOption = selectedOption
        self.dimension = dimension
        self.timestamp = Date()
    }
    
    static func == (lhs: VGLAResponse, rhs: VGLAResponse) -> Bool {
        return lhs.questionId == rhs.questionId && lhs.selectedOption == rhs.selectedOption
    }
}

// VGLA 測驗進度模型
struct VGLAProgress: Codable {
    let testId: String
    let currentQuestionIndex: Int
    let currentPhase: VGLAQuestion.VGLAPhase
    let responses: [VGLAResponse]
    let startTime: Date
    let lastUpdatedTime: Date
    let isCompleted: Bool
    
    init(testId: String = UUID().uuidString) {
        self.testId = testId
        self.currentQuestionIndex = 0
        self.currentPhase = .like
        self.responses = []
        self.startTime = Date()
        self.lastUpdatedTime = Date()
        self.isCompleted = false
    }
    
    init(testId: String, currentQuestionIndex: Int, currentPhase: VGLAQuestion.VGLAPhase, responses: [VGLAResponse], startTime: Date, lastUpdatedTime: Date, isCompleted: Bool) {
        self.testId = testId
        self.currentQuestionIndex = currentQuestionIndex
        self.currentPhase = currentPhase
        self.responses = responses
        self.startTime = startTime
        self.lastUpdatedTime = lastUpdatedTime
        self.isCompleted = isCompleted
    }
    
    // 更新進度
    func updateProgress(questionIndex: Int, phase: VGLAQuestion.VGLAPhase, responses: [VGLAResponse]) -> VGLAProgress {
        return VGLAProgress(
            testId: self.testId,
            currentQuestionIndex: questionIndex,
            currentPhase: phase,
            responses: responses,
            startTime: self.startTime,
            lastUpdatedTime: Date(),
            isCompleted: false
        )
    }
    
    // 完成測驗
    func completeTest(responses: [VGLAResponse]) -> VGLAProgress {
        return VGLAProgress(
            testId: self.testId,
            currentQuestionIndex: self.currentQuestionIndex,
            currentPhase: self.currentPhase,
            responses: responses,
            startTime: self.startTime,
            lastUpdatedTime: Date(),
            isCompleted: true
        )
    }
}

// VGLA 測驗結果
struct VGLAResult: Codable {
    let scores: [String: Int]  // V, G, L, A 分數
    let likeScores: [String: Int]  // 正向分數
    let dislikeScores: [String: Int]  // 逆向分數
    let totalScores: [String: Int]  // 綜合分數
    let order: [String]  // 排序結果
    let primaryType: String  // 主要類型
    let secondaryType: String  // 次要類型
    let combinationType: String  // 組合型態
    let analysisDate: Date
    
    init(responses: [VGLAResponse]) {
        self.analysisDate = Date()
        
        // 初始化分數
        var likeScores: [String: Int] = ["V": 0, "G": 0, "L": 0, "A": 0]
        var dislikeScores: [String: Int] = ["V": 0, "G": 0, "L": 0, "A": 0]
        
        for response in responses {
            let dimension = response.dimension.rawValue
            
            // 根據題目類型計分
            if response.questionId <= 30 {
                // LIKE 題目（1-30）- 正向計分
                likeScores[dimension, default: 0] += 1
            } else {
                // DISLIKE 題目（31-60）- 負向計分
                dislikeScores[dimension, default: 0] -= 1
            }
        }
        
        self.likeScores = likeScores
        self.dislikeScores = dislikeScores
        
        // 計算綜合分數（Like + Dislike）
        var totalScores: [String: Int] = [:]
        for dimension in VGLAQuestion.VGLADimension.allCases {
            let dimensionKey = dimension.rawValue
            totalScores[dimensionKey] = (likeScores[dimensionKey] ?? 0) + (dislikeScores[dimensionKey] ?? 0)
        }
        
        self.totalScores = totalScores
        self.scores = totalScores
        
        // 排序並找出前兩名
        let sortedScores = totalScores.sorted { $0.value > $1.value }
        self.order = sortedScores.map { $0.key }
        
        if sortedScores.count >= 2 {
            self.primaryType = sortedScores[0].key
            self.secondaryType = sortedScores[1].key
            self.combinationType = "\(sortedScores[0].key)\(sortedScores[1].key)"
        } else {
            self.primaryType = "V"
            self.secondaryType = "G"
            self.combinationType = "VG"
        }
    }
    
    // 獲取組合型態描述
    func getCombinationDescription() -> String {
        switch combinationType {
        case "VA":
            return "願景實踐者 - 喜歡有美好的夢想，並且能直接看到成果"
        case "VG":
            return "願景關懷者 - 喜歡有美好的願景，並且可以幫助人"
        case "VL":
            return "願景分析者 - 喜歡有美好的願景，並且有邏輯規劃"
        case "AV":
            return "行動願景者 - 喜歡快速行動，並且有遠大目標"
        case "AG":
            return "行動關懷者 - 喜歡快速行動，並且關心他人"
        case "AL":
            return "行動分析者 - 喜歡快速行動，並且有系統規劃"
        case "GV":
            return "關懷願景者 - 喜歡幫助他人，並且有美好願景"
        case "GA":
            return "關懷行動者 - 喜歡幫助他人，並且快速執行"
        case "GL":
            return "關懷分析者 - 喜歡幫助他人，並且有邏輯思考"
        case "LV":
            return "邏輯願景者 - 喜歡系統思考，並且有遠大目標"
        case "LA":
            return "邏輯行動者 - 喜歡系統思考，並且快速執行"
        case "LG":
            return "邏輯關懷者 - 喜歡系統思考，並且關心他人"
        default:
            return "獨特思考者 - 擁有獨特的思考模式"
        }
    }
    
    // 加百列詳細說明功能
    var strengths: [String] {
        return getStrengths(for: VGLAQuestion.VGLADimension(rawValue: primaryType) ?? .vision)
    }
    
    var challenges: [String] {
        // 找出最低分的向度作為盲點
        let blindSpotType = order.last ?? "A"
        return getChallenges(for: VGLAQuestion.VGLADimension(rawValue: blindSpotType) ?? .action)
    }
    
    var positiveTraits: [String] {
        return getPositiveTraits(for: VGLAQuestion.VGLADimension(rawValue: primaryType) ?? .vision)
    }
    
    var weaknesses: [String] {
        // 找出最低分的向度作為盲點
        let blindSpotType = order.last ?? "A"
        return getWeaknesses(for: VGLAQuestion.VGLADimension(rawValue: blindSpotType) ?? .action)
    }
    
    var howOthersSeeYou: [String] {
        return getHowOthersSeeYou(
            for: VGLAQuestion.VGLADimension(rawValue: primaryType) ?? .vision,
            secondary: VGLAQuestion.VGLADimension(rawValue: secondaryType) ?? .goal
        )
    }
    
    private func getStrengths(for dimension: VGLAQuestion.VGLADimension) -> [String] {
        switch dimension {
        case .vision:
            return [
                "具有遠見卓識，能看見長遠目標",
                "善於創造願景，激勵他人",
                "在複雜情況下保持方向感",
                "能夠將抽象概念具體化"
            ]
        case .goal:
            return [
                "具有強烈的同理心",
                "善於建立和維護人際關係",
                "能夠營造和諧的工作環境",
                "對他人需求敏感且關懷"
            ]
        case .logic:
            return [
                "邏輯思維清晰，分析能力強",
                "善於制定系統化流程",
                "注重細節和準確性",
                "能夠客觀評估情況"
            ]
        case .action:
            return [
                "執行力強，行動迅速",
                "能夠快速適應變化",
                "善於抓住機會",
                "在壓力下仍能保持效率"
            ]
        }
    }
    
    private func getChallenges(for dimension: VGLAQuestion.VGLADimension) -> [String] {
        switch dimension {
        case .vision:
            return [
                "可能過於理想化，忽略現實限制",
                "在細節執行上可能缺乏耐心",
                "需要學習平衡願景與實際行動"
            ]
        case .goal:
            return [
                "可能過度在意他人感受，忽略自己需求",
                "在需要強硬決策時可能猶豫不決",
                "需要學習設定界限"
            ]
        case .logic:
            return [
                "可能過度分析，導致決策緩慢",
                "在快速變化的環境中可能感到不適",
                "需要學習靈活應變"
            ]
        case .action:
            return [
                "可能缺乏長遠規劃",
                "在需要深思熟慮時可能過於急躁",
                "需要學習耐心和策略思考"
            ]
        }
    }
    
    private func getPositiveTraits(for dimension: VGLAQuestion.VGLADimension) -> [String] {
        switch dimension {
        case .vision:
            return ["願景領導者", "創新思維", "激勵他人", "戰略思考"]
        case .goal:
            return ["團隊合作者", "情感智慧", "溝通協調", "關懷他人"]
        case .logic:
            return ["分析專家", "系統思考", "品質保證", "客觀判斷"]
        case .action:
            return ["行動派", "效率專家", "機會把握", "快速適應"]
        }
    }
    
    private func getWeaknesses(for dimension: VGLAQuestion.VGLADimension) -> [String] {
        switch dimension {
        case .vision:
            return ["可能忽略細節", "執行力不足", "過於理想化"]
        case .goal:
            return ["決策猶豫", "過度妥協", "自我犧牲"]
        case .logic:
            return ["行動緩慢", "過度分析", "缺乏彈性"]
        case .action:
            return ["缺乏規劃", "衝動行事", "忽略細節"]
        }
    }
    
    private func getHowOthersSeeYou(for primary: VGLAQuestion.VGLADimension, secondary: VGLAQuestion.VGLADimension) -> [String] {
        let primaryTraits = getPositiveTraits(for: primary)
        let secondaryTraits = getPositiveTraits(for: secondary)
        
        return primaryTraits + secondaryTraits
    }
    
    // 獲取雷達圖數據
    func getRadarData() -> [(String, Double)] {
        let maxScore = 30.0  // 每個向度最高 30 分
        return [
            ("V", Double(scores["V"] ?? 0) / maxScore),
            ("G", Double(scores["G"] ?? 0) / maxScore),
            ("L", Double(scores["L"] ?? 0) / maxScore),
            ("A", Double(scores["A"] ?? 0) / maxScore)
        ]
    }
}

// VGLA 測驗管理器
class VGLATestManager: ObservableObject {
    @Published var currentQuestionIndex: Int = 0
    @Published var currentPhase: VGLAQuestion.VGLAPhase = .like
    @Published var responses: [VGLAResponse] = []
    @Published var isCompleted: Bool = false
    @Published var result: VGLAResult?
    
    let questions: [VGLAQuestion]
    
    init() {
        self.questions = VGLAQuestionBank.generateQuestions()
    }
    
    var currentQuestion: VGLAQuestion? {
        guard currentQuestionIndex < questions.count else { return nil }
        return questions[currentQuestionIndex]
    }
    
    var progress: Double {
        return Double(currentQuestionIndex) / Double(questions.count)
    }
    
    var canGoToPreviousQuestion: Bool {
        return currentQuestionIndex > 0
    }
    
    var canGoToNextQuestion: Bool {
        return currentQuestionIndex < questions.count - 1
    }
    
    var isTestComplete: Bool {
        return isCompleted
    }
    
    // 獲取當前題目的回答
    var currentResponse: VGLAResponse? {
        guard let question = currentQuestion else { return nil }
        return responses.first { $0.questionId == question.id }
    }
    
    // currentPhase 現在是 @Published 屬性
    
    func selectOption(_ option: String) {
        guard let question = currentQuestion else { return }
        
        // 根據選項文字找到對應的維度
        let options = VGLAQuestionBank.getOptions()
        guard let optionIndex = options.firstIndex(of: option) else { return }
        let selectedDimension = VGLAQuestionBank.getDimensionForOption(optionIndex)
        
        let response = VGLAResponse(
            questionId: question.id,
            selectedOption: option,
            dimension: selectedDimension
        )
        
        // 檢查是否已經有這個題目的回答，如果有則更新，否則添加
        if let existingIndex = responses.firstIndex(where: { $0.questionId == question.id }) {
            responses[existingIndex] = response
        } else {
            responses.append(response)
        }
        
        // 更新階段
        if currentQuestionIndex == 29 {
            currentPhase = VGLAQuestion.VGLAPhase.dislike
        }
        
        // 自動進入下一題
        if currentQuestionIndex < questions.count - 1 {
            nextQuestion()
        } else {
            // 最後一題，檢查是否完成
            completeTest()
        }
    }
    
    func nextQuestion() {
        if currentQuestionIndex < questions.count - 1 {
            currentQuestionIndex += 1
        }
    }
    
    func previousQuestion() {
        if currentQuestionIndex > 0 {
            currentQuestionIndex -= 1
        }
    }
    
    private func completeTest() {
        isCompleted = true
        result = VGLAResult(responses: responses)
    }
    
    func reset() {
        currentQuestionIndex = 0
        currentPhase = .like
        responses = []
        isCompleted = false
        result = nil
    }
    
    // 開始測驗
    func startTest() {
        reset()
    }
    
    // 恢復測驗
    func resumeTest(from progress: VGLAProgress) {
        currentQuestionIndex = progress.currentQuestionIndex
        currentPhase = progress.currentPhase
        responses = progress.responses
        isCompleted = false
        result = nil
    }
}

// VGLA 題庫
struct VGLAQuestionBank {
    static func generateQuestions() -> [VGLAQuestion] {
        var questions: [VGLAQuestion] = []
        
        // 標準 VGLA 60 題測驗題庫
        let scenarios = [
            "團隊合作", "會議討論", "專案啟動", "面對衝突", "面對截稿期限",
            "學習新工具", "提出創新", "評估風險", "回應回饋", "分析數據",
            "優化流程", "跨部門協作", "服務客戶", "危機處理", "資源分配",
            "品質把關", "面對變革", "任務委派", "指導新人", "腦力激盪",
            "溝通表達", "面對不確定性", "時間安排", "撰寫文件", "體察他人情緒",
            "談判協調", "小規模試驗", "遵循規範", "工作節奏", "成果慶祝"
        ]
        
        // 創建 30 個 "喜歡" 問題
        for (index, scenario) in scenarios.enumerated() {
            let dimension = VGLAQuestion.VGLADimension.allCases[index % 4]
            let questionText = "在「\(scenario)」的情境中，我最傾向的做法是："
            
            questions.append(VGLAQuestion(
                id: index + 1,
                text: questionText,
                dimension: dimension,
                phase: .like
            ))
        }
        
        // 創建 30 個 "不喜歡" 問題
        for (index, scenario) in scenarios.enumerated() {
            let dimension = VGLAQuestion.VGLADimension.allCases[index % 4]
            let questionText = "在「\(scenario)」的情境中，我最不喜歡／最不像我的做法是："
            
            questions.append(VGLAQuestion(
                id: index + 31,
                text: questionText,
                dimension: dimension,
                phase: .dislike
            ))
        }
        
        return questions
    }
    
    // 獲取選項文字
    static func getOptions() -> [String] {
        return [
            "我會先描繪長期方向與意義",        // A - V (願景)
            "我會先顧及彼此感受，營造良好氛圍",  // B - G (感性)
            "我會先釐清規則、流程與依據",        // C - L (邏輯)
            "我會立刻採取行動，先做出可見進展"   // D - A (行動)
        ]
    }
    
    // 獲取選項對應的維度
    static func getDimensionForOption(_ optionIndex: Int) -> VGLAQuestion.VGLADimension {
        switch optionIndex {
        case 0: return .vision    // A = 願景
        case 1: return .goal      // B = 感性
        case 2: return .logic     // C = 邏輯
        case 3: return .action    // D = 行動
        default: return .vision
        }
    }
}
