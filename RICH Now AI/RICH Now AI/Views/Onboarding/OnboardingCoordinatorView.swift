//
//  OnboardingCoordinatorView.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import SwiftUI

struct OnboardingCoordinatorView: View {
    @StateObject private var onboardingState = OnboardingState()
    @StateObject private var userStateManager = UserStateManager.shared
    @StateObject private var progressManager = OnboardingProgressManager.shared
    @State private var showDashboard = false
    @State private var showSkipConfirmation = false
    
    var body: some View {
        if showDashboard {
            MainAppView()
        } else {
            ZStack {
                // 確保有背景色，避免黑屏
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                currentStepView
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                
                // 跳過按鈕（顯示在右上角）
                if shouldShowSkipButton {
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: {
                                showSkipConfirmation = true
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "forward.fill")
                                        .font(.system(size: 14, weight: .medium))
                                    Text("跳過")
                                        .font(.system(size: 16, weight: .medium))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.black.opacity(0.3))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 20)
                                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                        )
                                )
                            }
                            .padding(.top, 50)
                            .padding(.trailing, 20)
                        }
                        Spacer()
                    }
                }
            }
            .alert("跳過迎賓流程", isPresented: $showSkipConfirmation) {
                Button("取消", role: .cancel) { }
                Button("跳過") {
                    skipOnboarding()
                }
            } message: {
                Text("跳過後將直接進入應用程式主頁面，您可以稍後在設定中完成個人資料設定。")
            }
            .onAppear {
                // 嘗試恢復之前保存的進度
                if progressManager.hasIncompleteOnboarding {
                    progressManager.restoreProgress(to: onboardingState)
                    
                    // 如果恢復到完成步驟，自動跳轉到主應用
                    if onboardingState.currentStep == .complete {
                        // 稍微延遲，確保視圖已載入
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            if !onboardingState.isComplete {
                                // 如果還沒有標記為完成，先標記並保存
                                if !onboardingState.userName.isEmpty {
                                    let userProfile = UserProfile(
                                        name: onboardingState.userName,
                                        email: onboardingState.userEmail,
                                        gender: onboardingState.userGender?.rawValue,
                                        gabrielGender: onboardingState.selectedGabriel?.rawValue,
                                        reportFrequency: onboardingState.reportFrequency.rawValue,
                                        conversationStyle: onboardingState.conversationStyle.rawValue
                                    )
                                    userStateManager.saveUserProfile(userProfile)
                                }
                                userStateManager.saveOnboardingCompleted()
                                onboardingState.isComplete = true
                            }
                            
                            withAnimation {
                                showDashboard = true
                            }
                        }
                    }
                }
            }
            .onChange(of: onboardingState.currentStep) { oldValue, newValue in
                // 只在步驟真正改變時保存
                guard oldValue != newValue else { return }
                progressManager.saveProgress(from: onboardingState)
            }
            .onChange(of: onboardingState.userName) { oldValue, newValue in
                // 只在有實際變化時保存（避免空字串觸發）
                guard oldValue != newValue && !newValue.isEmpty else { return }
                progressManager.saveProgress(from: onboardingState)
            }
            .onChange(of: onboardingState.userEmail) { oldValue, newValue in
                // 只在有實際變化時保存（避免空字串觸發）
                guard oldValue != newValue && !newValue.isEmpty else { return }
                progressManager.saveProgress(from: onboardingState)
            }
            .onChange(of: onboardingState.vglaAnswers.count) { _, _ in
                // 只在VGLA答案有變化時保存（使用count避免字典比較複雜）
                progressManager.saveProgress(from: onboardingState)
            }
            .onChange(of: onboardingState.vglaCurrentQuestion) { oldValue, newValue in
                // 只在題目編號真正改變時保存
                guard oldValue != newValue else { return }
                progressManager.saveProgress(from: onboardingState)
            }
        }
    }
    
    /// 判斷是否應該顯示跳過按鈕
    private var shouldShowSkipButton: Bool {
        // 在歡迎動畫和最終完成頁面不顯示跳過按鈕
        switch onboardingState.currentStep {
        case .selectGabriel:
            return onboardingState.hasShownWelcome
        case .complete:
            return false
        default:
            return true
        }
    }
    
    /// 跳過整個迎賓流程（永久跳過）
    private func skipOnboarding() {
        // 保存當前進度（如果有的話）
        if !onboardingState.userName.isEmpty || !onboardingState.userEmail.isEmpty {
            progressManager.saveProgress(from: onboardingState)
        }
        
        // 保存預設設定
        let defaultProfile = UserProfile(
            name: onboardingState.userName.isEmpty ? "使用者" : onboardingState.userName,
            email: onboardingState.userEmail.isEmpty ? nil : onboardingState.userEmail,
            gender: onboardingState.userGender?.rawValue,
            gabrielGender: onboardingState.selectedGabriel?.rawValue ?? GabrielGender.male.rawValue,
            reportFrequency: onboardingState.reportFrequency.rawValue,
            conversationStyle: onboardingState.conversationStyle.rawValue
        )
        userStateManager.saveUserProfile(defaultProfile)
        userStateManager.saveOnboardingCompleted()
        
        // 永久標記迎賓流程已跳過（除非在設定中重置）
        UserDefaults.standard.set(true, forKey: "hasPermanentlySkippedOnboarding")
        UserDefaults.standard.set(true, forKey: "hasCompletedFirstLaunch")
        UserDefaults.standard.set(true, forKey: "hasSeenWelcomeAnimation")
        
        // 清除進度（因為已經完成跳過）
        progressManager.clearProgress()
        
        withAnimation {
            showDashboard = true
        }
    }
    
    @ViewBuilder
    private var currentStepView: some View {
        switch onboardingState.currentStep {
        case .selectGabriel:
            if !onboardingState.hasShownWelcome {
                WelcomeAnimationView(
                    onAnimationComplete: {
                        withAnimation {
                            onboardingState.hasShownWelcome = true
                        }
                    },
                    onSkip: {
                        withAnimation {
                            onboardingState.hasShownWelcome = true
                        }
                    }
                )
            } else {
                GabrielSelectionView(selectedGabriel: $onboardingState.selectedGabriel) { gender in
                    onboardingState.selectedGabriel = gender
                    withAnimation {
                        onboardingState.nextStep()
                    }
                }
            }
            
        case .gabrielAppears:
            if let gabriel = onboardingState.selectedGabriel {
                GabrielAppearsView(gabrielGender: gabriel) {
                    withAnimation {
                        onboardingState.nextStep()
                    }
                }
            } else {
                Color.clear
                    .onAppear {
                        withAnimation {
                            onboardingState.nextStep()
                        }
                    }
            }
            
        case .getName:
            NameInputView(state: onboardingState)
            
        case .getGender:
            GenderSelectionView(state: onboardingState)
            
        case .getEmail:
            EmailInputView(state: onboardingState)
            
        case .setReportFrequency:
            ReportSettingsView(state: onboardingState)
            
        case .setConversationStyle:
            OnboardingConversationView(state: onboardingState)
            
        case .introduceVGLA:
            VGLAIntroductionView {
                withAnimation {
                    onboardingState.nextStep()
                }
            }
            
        case .vglaAssessment:
            VGLAAssessmentView { result in
                onboardingState.vglaResult = result
                // 保存 VGLA 結果
                userStateManager.saveVGLAResult(result)
                withAnimation {
                    onboardingState.nextStep()
                }
            }
            
        case .vglaResult:
            if let result = onboardingState.vglaResult {
                VGLAResultView(
                    result: result,
                    userName: onboardingState.userName
                ) {
                    withAnimation {
                        onboardingState.nextStep()
                    }
                }
            }
            
        case .selectAIFeatures:
            AIFeatureSelectionView {
                withAnimation {
                    onboardingState.nextStep()
                }
            }
            
        case .themePanel:
            if let result = onboardingState.vglaResult {
                ThemePanelSurpriseView(
                    combinationType: result.combinationType,
                    userName: onboardingState.userName,
                    onApply: {
                        applyExclusivePanel(combinationType: result.combinationType)
                        withAnimation {
                            onboardingState.nextStep()
                        }
                    },
                    onSkip: {
                        withAnimation {
                            onboardingState.nextStep()
                        }
                    }
                )
            }
            
        case .complete:
            // 如果已經完成迎賓流程，直接跳轉到主應用
            if onboardingState.isComplete || userStateManager.isOnboardingCompleted {
                Color.clear
                    .onAppear {
                        // 延遲一下確保視圖已載入
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation {
                                showDashboard = true
                            }
                        }
                    }
            } else if let result = onboardingState.vglaResult {
                OnboardingCompleteView(
                    userName: onboardingState.userName,
                    combinationType: result.combinationType
                ) {
                    // 保存用戶資料和完成狀態
                    let userProfile = UserProfile(
                        name: onboardingState.userName,
                        email: onboardingState.userEmail,
                        gender: onboardingState.userGender?.rawValue,
                        gabrielGender: onboardingState.selectedGabriel?.rawValue,
                        reportFrequency: onboardingState.reportFrequency.rawValue,
                        conversationStyle: onboardingState.conversationStyle.rawValue
                    )
                    userStateManager.saveUserProfile(userProfile)
                    userStateManager.saveOnboardingCompleted()
                    
                    withAnimation {
                        onboardingState.isComplete = true
                        showDashboard = true
                    }
                }
            } else {
                // 如果沒有 VGLA 結果但步驟已到 complete，自動完成迎賓
                Color.clear
                    .onAppear {
                        // 保存用戶資料（如果有）
                        if !onboardingState.userName.isEmpty {
                            let userProfile = UserProfile(
                                name: onboardingState.userName,
                                email: onboardingState.userEmail,
                                gender: onboardingState.userGender?.rawValue,
                                gabrielGender: onboardingState.selectedGabriel?.rawValue,
                                reportFrequency: onboardingState.reportFrequency.rawValue,
                                conversationStyle: onboardingState.conversationStyle.rawValue
                            )
                            userStateManager.saveUserProfile(userProfile)
                        }
                        userStateManager.saveOnboardingCompleted()
                        onboardingState.isComplete = true
                        
                        // 延遲一下確保狀態已更新
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation {
                                showDashboard = true
                            }
                        }
                    }
            }
        }
    }
}

// MARK: - VGLA Introduction View

struct VGLAIntroductionView: View {
    var onContinue: () -> Void
    
    @State private var showDimensions = false
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.safeHex("#1E3A8A", default: .blue), Color.safeHex("#312E81", default: .purple)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // 標題
                VStack(spacing: 16) {
                    Text("✨")
                        .font(.system(size: 60))
                    
                    Text("VGLA 性格探索")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("讓我真正了解你的獨特之處")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                // 四個向度介紹
                VStack(spacing: 20) {
                    VGLADimensionCard(icon: "🌟", title: "V 願景思考", description: "追求意義與長遠目標", color: Color.safeHex("#F59E0B", default: .orange))
                        .opacity(showDimensions ? 1 : 0)
                        .offset(x: showDimensions ? 0 : -50)
                    
                    VGLADimensionCard(icon: "💝", title: "G 感性關懷", description: "重視關係與他人感受", color: Color.safeHex("#EC4899", default: .pink))
                        .opacity(showDimensions ? 1 : 0)
                        .offset(x: showDimensions ? 0 : -50)
                        .animation(.spring().delay(0.1), value: showDimensions)
                    
                    VGLADimensionCard(icon: "🧠", title: "L 邏輯分析", description: "講究規則與系統思考", color: Color.safeHex("#3B82F6", default: .blue))
                        .opacity(showDimensions ? 1 : 0)
                        .offset(x: showDimensions ? 0 : -50)
                        .animation(.spring().delay(0.2), value: showDimensions)
                    
                    VGLADimensionCard(icon: "⚡", title: "A 行動實踐", description: "快速執行與看見成果", color: Color.safeHex("#10B981", default: .green))
                        .opacity(showDimensions ? 1 : 0)
                        .offset(x: showDimensions ? 0 : -50)
                        .animation(.spring().delay(0.3), value: showDimensions)
                }
                .padding(.horizontal)
                
                Spacer()
                
                // 繼續按鈕
                Button(action: onContinue) {
                    HStack {
                        Text("開始探索")
                            .font(.system(size: 18, weight: .semibold))
                        Image(systemName: "arrow.right")
                    }
                    .foregroundColor(Color(hex: "#1E3A8A"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(.white)
                    .cornerRadius(15)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            withAnimation {
                showDimensions = true
            }
        }
    }
}

private struct VGLADimensionCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Text(icon)
                .font(.system(size: 28))
                .frame(width: 48, height: 48)
                .background(color.opacity(0.15))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.75))
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.08))
        )
    }
}

// DimensionCard 已移至 FinancialHealthDashboardView.swift


// ThemePanelSurpriseView 已在 ThemePanelSurpriseView.swift 中定義

struct OnboardingCompleteView: View {
    let userName: String
    let combinationType: String
    var onContinue: () -> Void
    
    @State private var celebrate = false
    @State private var showRewards = false
    @State private var showButton = false
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.safeHex("#1E3A8A", default: .blue), Color.safeHex("#312E81", default: .purple)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // 慶祝動畫
                VStack(spacing: 20) {
                    Text("🎉")
                        .font(.system(size: 80))
                        .scaleEffect(celebrate ? 1.2 : 1.0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.5).repeatForever(autoreverses: true), value: celebrate)
                    
                    VStack(spacing: 16) {
                        Text("一切準備就緒！")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("\(userName)，讓我們開始你的理財之旅")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    .opacity(showRewards ? 1 : 0)
                    .offset(y: showRewards ? 0 : 20)
                    .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.5), value: showRewards)
                }
                
                // 獎勵展示
                if showRewards {
                    VStack(spacing: 16) {
                        RewardItem(icon: "🎨", title: "\(combinationType) 專屬面板", description: "永久免費")
                        RewardItem(icon: "💬", title: "AI 對話", description: "首月 100 次免費")
                        RewardItem(icon: "🏅", title: "迎新徽章", description: "專屬成就")
                        RewardItem(icon: "📊", title: "財務分析", description: "個性化建議")
                    }
                    .padding()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                Spacer()
                
                // 開始按鈕
                if showButton {
                    Button(action: onContinue) {
                        HStack {
                            Text("開始我的理財之旅")
                                .font(.system(size: 18, weight: .semibold))
                            Image(systemName: "arrow.right")
                        }
                        .foregroundColor(Color.safeHex("#1E3A8A", default: .blue))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.white)
                        .cornerRadius(15)
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .onAppear {
            startCelebration()
        }
    }
    
    private func startCelebration() {
        // 第一階段：慶祝動畫
        celebrate = true
        
        // 第二階段：獎勵展示
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation {
                showRewards = true
            }
        }
        
        // 第三階段：開始按鈕
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation {
                showButton = true
            }
        }
    }
}

struct RewardItem: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Text(icon)
                .font(.system(size: 32))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.white.opacity(0.1))
        )
    }
}

// MARK: - 專屬面板套用

extension OnboardingCoordinatorView {
    fileprivate func applyExclusivePanel(combinationType: String) {
        let exclusivePanel = createExclusivePanel(for: combinationType)
        
        // TODO: 實際保存至使用者設定（需要注入 ModelContext）
        print("Applying exclusive panel for combination: \(combinationType)")
        print("Panel details: \(exclusivePanel)")
    }
    
    private func createExclusivePanel(for combinationType: String) -> [String: Any] {
        switch combinationType {
        case "VA":
            return [
                "name": "Vision-Action 專屬面板",
                "description": "為願景驅動的行動者量身定制",
                "features": ["快速決策工具", "願景追蹤器", "行動計劃模板"],
                "color": "blue",
                "icon": "vision.action"
            ]
        case "VG":
            return [
                "name": "Vision-Goal 專屬面板",
                "description": "為願景導向的目標設定者設計",
                "features": ["長期規劃工具", "目標分解器", "進度追蹤器"],
                "color": "green",
                "icon": "vision.goal"
            ]
        case "LG":
            return [
                "name": "Logic-Goal 專屬面板",
                "description": "為邏輯性的目標達成者打造",
                "features": ["數據分析工具", "邏輯決策樹", "效率優化器"],
                "color": "purple",
                "icon": "logic.goal"
            ]
        case "LA":
            return [
                "name": "Logic-Action 專屬面板",
                "description": "為邏輯驅動的行動者準備",
                "features": ["系統化工具", "流程優化器", "執行追蹤器"],
                "color": "orange",
                "icon": "logic.action"
            ]
        case "GA":
            return [
                "name": "Goal-Action 專屬面板",
                "description": "為目標導向的行動者定制",
                "features": ["目標管理工具", "行動計劃器", "成果追蹤器"],
                "color": "red",
                "icon": "goal.action"
            ]
        default:
            return [
                "name": "通用專屬面板",
                "description": "為您的個性特質量身定制",
                "features": ["個性化工具", "智能建議", "專屬功能"],
                "color": "gray",
                "icon": "personalized"
            ]
        }
    }
}

#Preview {
    OnboardingCoordinatorView()
}
