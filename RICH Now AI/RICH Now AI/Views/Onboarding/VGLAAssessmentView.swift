//
//  VGLAAssessmentView.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import SwiftUI

struct VGLAAssessmentView: View {
    @StateObject private var testManager = VGLATestManager()
    @StateObject private var progressManager = VGLAProgressManager()
    @StateObject private var profileManager = UserProfileManager.shared
    @State private var showResult = false
    @State private var isTransitioning = false
    @State private var showResumeDialog = false
    @State private var showPaywall = false
    var onComplete: (VGLAResult) -> Void
    
    var body: some View {
        ZStack {
            // 背景
            LinearGradient(
                colors: [Color(hex: "#F3F4F6")!, Color(hex: "#E5E7EB")!],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // 檢查付費狀態
            if !profileManager.canAccessVGLA() {
                VGLAPaywallView(
                    onPurchase: {
                        // 模擬購買成功，升級到 Basic 方案
                        profileManager.updateSubscription(tier: "basic")
                        showPaywall = false
                    },
                    onSkip: {
                        onComplete(VGLAResult(responses: []))
                    }
                )
                .onAppear {
                    showPaywall = true
                }
                .sheet(isPresented: $showPaywall) {
                    VGLAPaywallView(
                        onPurchase: {
                            profileManager.updateSubscription(tier: "basic")
                            showPaywall = false
                        },
                        onSkip: {
                            onComplete(VGLAResult(responses: []))
                        }
                    )
                }
            } else {
                VStack(spacing: 0) {
                    // 頂部進度條
                    VGLAProgressBar(
                        currentQuestion: testManager.currentQuestionIndex + 1,
                        totalQuestions: 60,
                        phase: testManager.currentPhase.displayName,
                        progress: testManager.progress
                    )
                    .padding(.top, 8)
                    
                    // 測驗內容
                    if let question = testManager.currentQuestion {
                        VGLAQuestionCard(
                            question: question,
                            currentResponse: testManager.currentResponse,
                            onSelectOption: { option in
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                    isTransitioning = true
                                    testManager.selectOption(option)
                                    
                                    // 同步進度
                                    syncProgressWithTestManager()
                                    
                                    // 延遲後自動進入下一題
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            isTransitioning = false
                                            if testManager.currentQuestionIndex < testManager.questions.count - 1 {
                                                testManager.nextQuestion()
                                            } else {
                                                // 測驗完成
                                                if let result = testManager.result {
                                                    profileManager.completeVGLA(result: result)
                                                    onComplete(result)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }
                    
                    Spacer()
                    
                    // 底部導航按鈕
                    VGLANavigationButtons(
                        canGoBack: testManager.canGoToPreviousQuestion,
                        canGoForward: testManager.canGoToNextQuestion,
                        onPrevious: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                testManager.previousQuestion()
                            }
                        },
                        onNext: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                testManager.nextQuestion()
                            }
                        }
                    )
                }
                .onAppear {
                    checkForIncompleteTest()
                }
                .alert("繼續測驗", isPresented: $showResumeDialog) {
                    Button("繼續") {
                        resumeTest()
                    }
                    Button("重新開始") {
                        startNewTest()
                    }
                    Button("取消", role: .cancel) {
                        onComplete(VGLAResult(responses: []))
                    }
                } message: {
                    if let progress = progressManager.currentProgress {
                        let stats = progressManager.getTestStats()
                        let phaseProgress = progressManager.getPhaseProgress()
                        Text("您上次測驗進行到第 \(phaseProgress.current + 1) 題（\(progress.currentPhase.displayName)階段），已花費 \(Int(stats.totalTime / 60)) 分鐘。是否要繼續？")
                    }
                }
            }
        }
    }
    
    // MARK: - 測驗管理方法
    
    private func checkForIncompleteTest() {
        if progressManager.checkForIncompleteTest() {
            showResumeDialog = true
        } else {
            startNewTest()
        }
    }
    
    private func startNewTest() {
        _ = progressManager.startNewTest()
        testManager.startTest()
        // 同步進度
        syncProgressWithTestManager()
    }
    
    private func resumeTest() {
        guard let progress = progressManager.resumeTest() else {
            startNewTest()
            return
        }
        
        // 恢復測驗狀態
        testManager.resumeTest(from: progress)
        syncProgressWithTestManager()
    }
    
    private func syncProgressWithTestManager() {
        // 當測驗管理器狀態改變時，同步到進度管理器
        DispatchQueue.main.async {
            self.progressManager.updateProgress(
                questionIndex: self.testManager.currentQuestionIndex,
                phase: self.testManager.currentPhase,
                responses: self.testManager.responses
            )
        }
    }
}

// MARK: - Progress Bar

struct VGLAProgressBar: View {
    let currentQuestion: Int
    let totalQuestions: Int
    let phase: String
    let progress: Double
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("第 \(currentQuestion) 題，共 \(totalQuestions) 題")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(phase)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "#1E3A8A"))
            }
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: Color(hex: "#1E3A8A") ?? .blue))
                .scaleEffect(x: 1, y: 2, anchor: .center)
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Question Card

struct VGLAQuestionCard: View {
    let question: VGLAQuestion
    let currentResponse: VGLAResponse?
    let onSelectOption: (String) -> Void
    
    @State private var selectedOption: String?
    @State private var showOptions = false
    
    var body: some View {
        VStack(spacing: 24) {
            // 問題標題
            VStack(spacing: 12) {
                Text(getQuestionPrompt())
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                
                Text(question.text)
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
            }
            .padding(.horizontal, 20)
            
            // 選項
            if showOptions {
                VStack(spacing: 12) {
                    ForEach(VGLAQuestionBank.getOptions(), id: \.self) { option in
                        VGLAOptionButton(
                            option: option,
                            isSelected: selectedOption == option,
                            onTap: {
                                selectedOption = option
                                onSelectOption(option)
                            }
                        )
                    }
                }
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.9)),
                    removal: .opacity.combined(with: .scale(scale: 1.1))
                ))
            }
        }
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .onAppear {
            // 如果有之前的回答，顯示它；否則重置選擇狀態
            selectedOption = currentResponse?.selectedOption
            withAnimation {
                showOptions = true
            }
        }
        .onChange(of: currentResponse) { _, newResponse in
            // 當回答改變時更新選擇狀態
            selectedOption = newResponse?.selectedOption
        }
    }
    
    private func getQuestionPrompt() -> String {
        switch question.phase {
        case .like:
            return "請選擇您最喜歡的選項："
        case .dislike:
            return "請選擇您最不喜歡的選項："
        }
    }
}

// MARK: - Option Button

struct VGLAOptionButton: View {
    let option: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(option)
                    .font(.system(size: 16))
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(nil)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .frame(minHeight: 50) // 最小觸控高度 50pt，超過44pt標準
            .frame(maxWidth: .infinity, alignment: .leading) // 確保整個寬度可點擊
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color(hex: "#1E3A8A")! : Color(.systemGray6))
            )
            .contentShape(Rectangle()) // 確保整個區域都可點擊
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Navigation Buttons

struct VGLANavigationButtons: View {
    let canGoBack: Bool
    let canGoForward: Bool
    let onPrevious: () -> Void
    let onNext: () -> Void
    
    var body: some View {
        HStack(spacing: 20) {
            Button(action: onPrevious) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                    Text("上一題")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(canGoBack ? .white : .gray)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .frame(minHeight: 44) // 最小觸控高度 44pt
                .frame(minWidth: 100) // 最小觸控寬度
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(canGoBack ? Color(hex: "#6B7280")! : Color(hex: "#E5E7EB")!)
                )
            }
            .disabled(!canGoBack)
            .opacity(canGoBack ? 1.0 : 0.6)
            .buttonStyle(PlainButtonStyle())
            .contentShape(Rectangle()) // 確保整個區域都可點擊
            
            Spacer()
            
            Button(action: onNext) {
                HStack(spacing: 8) {
                    Text("下一題")
                        .font(.system(size: 16, weight: .semibold))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(canGoForward ? .white : .gray)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .frame(minHeight: 44) // 最小觸控高度 44pt
                .frame(minWidth: 100) // 最小觸控寬度
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(canGoForward ? Color(hex: "#3B82F6")! : Color(hex: "#E5E7EB")!)
                )
            }
            .disabled(!canGoForward)
            .opacity(canGoForward ? 1.0 : 0.6)
            .buttonStyle(PlainButtonStyle())
            .contentShape(Rectangle()) // 確保整個區域都可點擊
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

#Preview {
    VGLAAssessmentView { result in
        print("Test completed: \(result.combinationType)")
    }
}