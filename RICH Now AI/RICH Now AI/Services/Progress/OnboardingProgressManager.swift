//
//  OnboardingProgressManager.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/12/19.
//

import Foundation
import Combine
import os.log

/// 迎賓流程進度管理器 - 保存和恢復迎賓流程進度
@MainActor
class OnboardingProgressManager: ObservableObject {
    static let shared = OnboardingProgressManager()
    
    @Published var hasIncompleteOnboarding: Bool = false
    @Published var savedOnboardingState: OnboardingProgress?
    
    private let userDefaults = UserDefaults.standard
    private let progressKey = "onboardingProgress"
    private let incompleteKey = "hasIncompleteOnboarding"
    private let logger = Logger(subsystem: "com.richnowai", category: "OnboardingProgressManager")
    
    // 防抖機制：避免過度保存
    private var lastSaveTime: Date = Date.distantPast
    private let saveThrottleInterval: TimeInterval = 1.0 // 至少間隔1秒才保存一次
    
    private init() {
        loadProgress()
    }
    
    // MARK: - 保存進度
    
    /// 保存迎賓流程的當前進度（帶防抖機制）
    func saveProgress(from state: OnboardingState) {
        // 防抖檢查：如果距離上次保存時間太短，則跳過
        let now = Date()
        guard now.timeIntervalSince(lastSaveTime) >= saveThrottleInterval else {
            logger.debug("跳過保存：距離上次保存時間太短")
            return
        }
        
        let progress = OnboardingProgress(
            currentStep: state.currentStep.rawValue,
            selectedGabriel: state.selectedGabriel?.rawValue,
            userName: state.userName,
            userGender: state.userGender?.rawValue,
            userEmail: state.userEmail,
            reportFrequency: state.reportFrequency.rawValue,
            conversationStyle: state.conversationStyle.rawValue,
            hasShownWelcome: state.hasShownWelcome,
            vglaAnswers: state.vglaAnswers,
            vglaCurrentQuestion: state.vglaCurrentQuestion,
            vglaIsComplete: state.vglaIsComplete,
            savedAt: Date()
        )
        
        // 檢查進度是否真的有變化
        if let lastProgress = savedOnboardingState,
           lastProgress.currentStep == progress.currentStep,
           lastProgress.userName == progress.userName,
           lastProgress.userEmail == progress.userEmail,
           lastProgress.vglaCurrentQuestion == progress.vglaCurrentQuestion {
            // 如果沒有實質變化，跳過保存
            logger.debug("跳過保存：進度無變化")
            return
        }
        
        saveProgress(progress)
        lastSaveTime = now
        logger.info("迎賓流程進度已保存: 步驟 \(state.currentStep.rawValue)")
    }
    
    private func saveProgress(_ progress: OnboardingProgress) {
        do {
            let data = try JSONEncoder().encode(progress)
            userDefaults.set(data, forKey: progressKey)
            userDefaults.set(true, forKey: incompleteKey)
            savedOnboardingState = progress
            hasIncompleteOnboarding = true
            logger.debug("進度保存成功")
        } catch {
            logger.error("保存迎賓流程進度失敗: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 載入進度
    
    /// 從儲存載入進度
    func loadProgress() {
        guard let data = userDefaults.data(forKey: progressKey) else {
            hasIncompleteOnboarding = false
            savedOnboardingState = nil
            return
        }
        
        do {
            let progress = try JSONDecoder().decode(OnboardingProgress.self, from: data)
            savedOnboardingState = progress
            hasIncompleteOnboarding = !progress.isComplete
            logger.info("載入迎賓流程進度: 步驟 \(progress.currentStep)")
        } catch {
            logger.error("載入迎賓流程進度失敗: \(error.localizedDescription)")
            hasIncompleteOnboarding = false
            savedOnboardingState = nil
        }
    }
    
    /// 恢復進度到 OnboardingState
    func restoreProgress(to state: OnboardingState) {
        guard let progress = savedOnboardingState else {
            logger.warning("沒有可恢復的進度")
            return
        }
        
        // 恢復基本資訊
        if let step = OnboardingStep(rawValue: progress.currentStep) {
            state.currentStep = step
        }
        
        if let gabrielRaw = progress.selectedGabriel,
           let gabriel = GabrielGender(rawValue: gabrielRaw) {
            state.selectedGabriel = gabriel
        }
        
        state.userName = progress.userName
        
        if let genderRaw = progress.userGender,
           let gender = UserGender(rawValue: genderRaw) {
            state.userGender = gender
        }
        
        state.userEmail = progress.userEmail
        
        if let frequency = ReportFrequency(rawValue: progress.reportFrequency) {
            state.reportFrequency = frequency
        }
        
        if let style = ConversationStyle(rawValue: progress.conversationStyle) {
            state.conversationStyle = style
        }
        
        state.hasShownWelcome = progress.hasShownWelcome
        
        // 恢復 VGLA 測驗進度
        state.vglaAnswers = progress.vglaAnswers
        state.vglaCurrentQuestion = progress.vglaCurrentQuestion
        state.vglaIsComplete = progress.vglaIsComplete
        
        logger.info("迎賓流程進度已恢復: 步驟 \(progress.currentStep), VGLA 進度 \(progress.vglaCurrentQuestion)/60")
    }
    
    /// 更新已保存的進度（用於從設定頁面更新資料後同步）
    func updateSavedProgress(userName: String? = nil, userEmail: String? = nil, userGender: String? = nil, reportFrequency: String? = nil, conversationStyle: String? = nil) {
        guard let progress = savedOnboardingState else { return }
        
        // 創建更新的進度
        let updatedProgress = OnboardingProgress(
            currentStep: progress.currentStep,
            selectedGabriel: progress.selectedGabriel,
            userName: userName ?? progress.userName,
            userGender: userGender ?? progress.userGender,
            userEmail: userEmail ?? progress.userEmail,
            reportFrequency: reportFrequency ?? progress.reportFrequency,
            conversationStyle: conversationStyle ?? progress.conversationStyle,
            hasShownWelcome: progress.hasShownWelcome,
            vglaAnswers: progress.vglaAnswers,
            vglaCurrentQuestion: progress.vglaCurrentQuestion,
            vglaIsComplete: progress.vglaIsComplete,
            savedAt: Date()
        )
        
        saveProgress(updatedProgress)
        logger.info("已更新保存的迎賓流程進度")
    }
    
    // MARK: - 清除進度
    
    /// 清除已保存的進度
    func clearProgress() {
        userDefaults.removeObject(forKey: progressKey)
        userDefaults.removeObject(forKey: incompleteKey)
        hasIncompleteOnboarding = false
        savedOnboardingState = nil
        logger.info("迎賓流程進度已清除")
    }
    
    // MARK: - 檢查完整性
    
    /// 檢查個人資料是否完整（使用 UserProfile 或 OnboardingProgress）
    func checkProfileCompleteness() -> ProfileCompleteness {
        let userProfile = UserStateManager.shared.userProfile
        
        var missingFields: [String] = []
        var completedCount = 0
        let totalFields = 6
        
        // 檢查各項資料（優先使用 UserProfile，否則使用 OnboardingProgress）
        let userName = userProfile?.name ?? savedOnboardingState?.userName ?? ""
        let userEmail = userProfile?.email ?? savedOnboardingState?.userEmail ?? ""
        let userGender = userProfile?.gender ?? savedOnboardingState?.userGender
        let gabrielGender = userProfile?.gabrielGender ?? savedOnboardingState?.selectedGabriel
        let reportFrequency = userProfile?.reportFrequency ?? savedOnboardingState?.reportFrequency ?? ""
        let conversationStyle = userProfile?.conversationStyle ?? savedOnboardingState?.conversationStyle ?? ""
        
        // 檢查各項資料
        if userName.isEmpty {
            missingFields.append("稱呼")
        } else {
            completedCount += 1
        }
        
        if userEmail.isEmpty {
            missingFields.append("電子郵件")
        } else {
            completedCount += 1
        }
        
        if userGender == nil || userGender == "" {
            missingFields.append("性別")
        } else {
            completedCount += 1
        }
        
        if gabrielGender == nil || gabrielGender == "" {
            missingFields.append("加百列性別")
        } else {
            completedCount += 1
        }
        
        if reportFrequency.isEmpty {
            missingFields.append("報告頻率")
        } else {
            completedCount += 1
        }
        
        if conversationStyle.isEmpty {
            missingFields.append("對話風格")
        } else {
            completedCount += 1
        }
        
        let completionPercentage = Double(completedCount) / Double(totalFields) * 100.0
        let vglaComplete = savedOnboardingState?.vglaIsComplete ?? UserStateManager.shared.hasCompletedVGLA
        let isComplete = missingFields.isEmpty && vglaComplete
        
        return ProfileCompleteness(
            isComplete: isComplete,
            missingFields: missingFields,
            completionPercentage: completionPercentage
        )
    }
}

// MARK: - 進度數據模型

struct OnboardingProgress: Codable {
    let currentStep: Int
    let selectedGabriel: String?
    let userName: String
    let userGender: String?
    let userEmail: String
    let reportFrequency: String
    let conversationStyle: String
    let hasShownWelcome: Bool
    let vglaAnswers: [Int: String]
    let vglaCurrentQuestion: Int
    let vglaIsComplete: Bool
    let savedAt: Date
    
    var isComplete: Bool {
        // 如果 VGLA 測驗已完成，則認為迎賓流程完成
        return vglaIsComplete && !userName.isEmpty
    }
}

// MARK: - 資料完整性檢查

struct ProfileCompleteness {
    let isComplete: Bool
    let missingFields: [String]
    let completionPercentage: Double
    
    var displayMessage: String {
        if isComplete {
            return "個人資料完整"
        } else {
            return "缺少：\(missingFields.joined(separator: "、"))"
        }
    }
}

