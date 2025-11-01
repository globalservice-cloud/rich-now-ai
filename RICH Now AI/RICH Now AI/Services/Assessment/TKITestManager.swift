//
//  TKITestManager.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import Foundation
import SwiftData
import Combine

class TKITestManager: ObservableObject {
    @Published var currentQuestionIndex: Int = 0
    @Published var answers: [TKIAnswer] = []
    @Published var isCompleted: Bool = false
    @Published var result: TKIResult?
    
    let questions: [TKIQuestion]
    
    init() {
        self.questions = TKITestManager.generateQuestions()
    }
    
    var currentQuestion: TKIQuestion? {
        guard currentQuestionIndex < questions.count else { return nil }
        return questions[currentQuestionIndex]
    }
    
    var progress: Double {
        return Double(currentQuestionIndex) / Double(questions.count)
    }
    
    var canGoNext: Bool {
        return currentQuestionIndex < questions.count - 1
    }
    
    var canGoPrevious: Bool {
        return currentQuestionIndex > 0
    }
    
    func selectAnswer(_ mode: TKIMode) {
        guard let question = currentQuestion else { return }
        
        // 移除舊答案（如果存在）
        answers.removeAll { $0.questionId == question.id }
        
        // 添加新答案
        let answer = TKIAnswer(questionId: question.id, selectedMode: mode)
        answers.append(answer)
    }
    
    func getAnswer(for questionId: Int) -> TKIMode? {
        return answers.first { $0.questionId == questionId }?.selectedMode
    }
    
    func nextQuestion() {
        if canGoNext {
            currentQuestionIndex += 1
        }
    }
    
    func previousQuestion() {
        if canGoPrevious {
            currentQuestionIndex -= 1
        }
    }
    
    func completeAssessment() {
        guard answers.count == questions.count else { return }
        
        // 計算分數
        var scores: [TKIMode: Int] = [:]
        for mode in TKIMode.allCases {
            scores[mode] = answers.filter { $0.selectedMode == mode }.count
        }
        
        // 生成結果
        self.result = TKIResult(scores: scores)
        self.isCompleted = true
    }
    
    func reset() {
        currentQuestionIndex = 0
        answers.removeAll()
        isCompleted = false
        result = nil
    }
    
    // MARK: - 問題生成
    private static func generateQuestions() -> [TKIQuestion] {
        var questions: [TKIQuestion] = []
        
        // 30 題 TKI 配對選擇題
        let questionData: [(String, String, TKIMode, TKIMode)] = [
            // 1-6: 競爭 vs 合作
            ("tki.question_1_option_a", "tki.question_1_option_b", .competing, .collaborating),
            ("tki.question_2_option_a", "tki.question_2_option_b", .competing, .collaborating),
            ("tki.question_3_option_a", "tki.question_3_option_b", .competing, .collaborating),
            ("tki.question_4_option_a", "tki.question_4_option_b", .competing, .collaborating),
            ("tki.question_5_option_a", "tki.question_5_option_b", .competing, .collaborating),
            ("tki.question_6_option_a", "tki.question_6_option_b", .competing, .collaborating),
            
            // 7-12: 競爭 vs 妥協
            ("tki.question_7_option_a", "tki.question_7_option_b", .competing, .compromising),
            ("tki.question_8_option_a", "tki.question_8_option_b", .competing, .compromising),
            ("tki.question_9_option_a", "tki.question_9_option_b", .competing, .compromising),
            ("tki.question_10_option_a", "tki.question_10_option_b", .competing, .compromising),
            ("tki.question_11_option_a", "tki.question_11_option_b", .competing, .compromising),
            ("tki.question_12_option_a", "tki.question_12_option_b", .competing, .compromising),
            
            // 13-18: 競爭 vs 迴避
            ("tki.question_13_option_a", "tki.question_13_option_b", .competing, .avoiding),
            ("tki.question_14_option_a", "tki.question_14_option_b", .competing, .avoiding),
            ("tki.question_15_option_a", "tki.question_15_option_b", .competing, .avoiding),
            ("tki.question_16_option_a", "tki.question_16_option_b", .competing, .avoiding),
            ("tki.question_17_option_a", "tki.question_17_option_b", .competing, .avoiding),
            ("tki.question_18_option_a", "tki.question_18_option_b", .competing, .avoiding),
            
            // 19-24: 競爭 vs 順應
            ("tki.question_19_option_a", "tki.question_19_option_b", .competing, .accommodating),
            ("tki.question_20_option_a", "tki.question_20_option_b", .competing, .accommodating),
            ("tki.question_21_option_a", "tki.question_21_option_b", .competing, .accommodating),
            ("tki.question_22_option_a", "tki.question_22_option_b", .competing, .accommodating),
            ("tki.question_23_option_a", "tki.question_23_option_b", .competing, .accommodating),
            ("tki.question_24_option_a", "tki.question_24_option_b", .competing, .accommodating),
            
            // 25-30: 其他組合
            ("tki.question_25_option_a", "tki.question_25_option_b", .collaborating, .compromising),
            ("tki.question_26_option_a", "tki.question_26_option_b", .collaborating, .avoiding),
            ("tki.question_27_option_a", "tki.question_27_option_b", .collaborating, .accommodating),
            ("tki.question_28_option_a", "tki.question_28_option_b", .compromising, .avoiding),
            ("tki.question_29_option_a", "tki.question_29_option_b", .compromising, .accommodating),
            ("tki.question_30_option_a", "tki.question_30_option_b", .avoiding, .accommodating)
        ]
        
        for (index, data) in questionData.enumerated() {
            let question = TKIQuestion(
                id: index + 1,
                questionNumber: index + 1,
                optionA: data.0,
                optionB: data.1,
                modeA: data.2,
                modeB: data.3
            )
            questions.append(question)
        }
        
        return questions
    }
}
