//
//  VGLAProgressManager.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/27.
//

import Foundation
import Combine

// VGLA 測驗進度管理器
@MainActor
class VGLAProgressManager: ObservableObject {
    @Published var currentProgress: VGLAProgress?
    @Published var hasIncompleteTest: Bool = false
    
    private let progressKey = "vgla_test_progress"
    private let incompleteTestKey = "vgla_has_incomplete_test"
    
    init() {
        loadProgress()
    }
    
    // 開始新測驗
    func startNewTest() -> VGLAProgress {
        let progress = VGLAProgress()
        currentProgress = progress
        saveProgress()
        return progress
    }
    
    // 更新測驗進度
    func updateProgress(questionIndex: Int, phase: VGLAQuestion.VGLAPhase, responses: [VGLAResponse]) {
        guard var progress = currentProgress else { return }
        
        progress = progress.updateProgress(
            questionIndex: questionIndex,
            phase: phase,
            responses: responses
        )
        
        currentProgress = progress
        saveProgress()
    }
    
    // 完成測驗
    func completeTest(responses: [VGLAResponse]) {
        guard var progress = currentProgress else { return }
        
        progress = progress.completeTest(responses: responses)
        currentProgress = progress
        clearProgress()
    }
    
    // 恢復測驗
    func resumeTest() -> VGLAProgress? {
        loadProgress()
        return currentProgress
    }
    
    // 放棄測驗
    func abandonTest() {
        clearProgress()
    }
    
    // 檢查是否有未完成的測驗
    func checkForIncompleteTest() -> Bool {
        loadProgress()
        return currentProgress != nil && !currentProgress!.isCompleted
    }
    
    // 獲取測驗進度百分比
    func getProgressPercentage() -> Double {
        guard let progress = currentProgress else { return 0.0 }
        
        let totalQuestions = 60 // 30 喜歡 + 30 不喜歡
        let currentQuestion = progress.currentQuestionIndex
        
        return Double(currentQuestion) / Double(totalQuestions) * 100.0
    }
    
    // 獲取當前階段進度
    func getPhaseProgress() -> (current: Int, total: Int, phase: VGLAQuestion.VGLAPhase) {
        guard let progress = currentProgress else { return (0, 30, .like) }
        
        let phaseQuestions = 30
        let currentInPhase = progress.currentQuestionIndex % phaseQuestions
        
        return (currentInPhase, phaseQuestions, progress.currentPhase)
    }
    
    // 保存進度到 UserDefaults
    private func saveProgress() {
        guard let progress = currentProgress else { return }
        
        do {
            let data = try JSONEncoder().encode(progress)
            UserDefaults.standard.set(data, forKey: progressKey)
            UserDefaults.standard.set(true, forKey: incompleteTestKey)
        } catch {
            print("保存 VGLA 測驗進度失敗: \(error)")
        }
    }
    
    // 從 UserDefaults 載入進度
    private func loadProgress() {
        guard let data = UserDefaults.standard.data(forKey: progressKey) else {
            currentProgress = nil
            hasIncompleteTest = false
            return
        }
        
        do {
            let progress = try JSONDecoder().decode(VGLAProgress.self, from: data)
            currentProgress = progress
            hasIncompleteTest = !progress.isCompleted
        } catch {
            print("載入 VGLA 測驗進度失敗: \(error)")
            currentProgress = nil
            hasIncompleteTest = false
        }
    }
    
    // 清除進度
    private func clearProgress() {
        UserDefaults.standard.removeObject(forKey: progressKey)
        UserDefaults.standard.set(false, forKey: incompleteTestKey)
        currentProgress = nil
        hasIncompleteTest = false
    }
    
    // 獲取測驗統計信息
    func getTestStats() -> (totalTime: TimeInterval, questionsAnswered: Int, phase: VGLAQuestion.VGLAPhase) {
        guard let progress = currentProgress else {
            return (0, 0, .like)
        }
        
        let totalTime = progress.lastUpdatedTime.timeIntervalSince(progress.startTime)
        let questionsAnswered = progress.responses.count
        
        return (totalTime, questionsAnswered, progress.currentPhase)
    }
}
