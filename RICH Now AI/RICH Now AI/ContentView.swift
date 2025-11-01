//
//  ContentView.swift
//  RICH Now AI
//
//  Created by Chang Yao tiem on 2025/10/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]
    @StateObject private var userStateManager = UserStateManager.shared
    @StateObject private var designSystem = DesignSystemManager.shared
    @StateObject private var progressManager = OnboardingProgressManager.shared
    @AppStorage("hasSeenWelcomeAnimation") private var hasSeenWelcomeAnimation: Bool = false
    @AppStorage("hasSelectedLanguage") private var hasSelectedLanguage: Bool = false
    @AppStorage("hasCompletedFirstLaunch") private var hasCompletedFirstLaunch: Bool = false
    @AppStorage("hasPermanentlySkippedOnboarding") private var hasPermanentlySkippedOnboarding: Bool = false
    
    // 添加載入狀態
    @State private var isInitializing = true
    @State private var showContinueOnboarding = false
    
    var body: some View {
        Group {
            if isInitializing {
                // 啟動畫面
                LaunchScreenView()
                    .onAppear {
                        // 快速初始化，避免阻塞
                        Task {
                            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
                            await MainActor.run {
                                isInitializing = false
                            }
                        }
                    }
            } else if hasPermanentlySkippedOnboarding || (userStateManager.isOnboardingCompleted && !users.isEmpty) {
                // 主應用程式（財務儀表板）- 已經完成迎賓流程或永久跳過
                MainAppView()
                    .onAppear {
                        // 如果是永久跳過，確保所有相關標記都已設置
                        if hasPermanentlySkippedOnboarding {
                            userStateManager.saveOnboardingCompleted()
                            hasCompletedFirstLaunch = true
                            hasSeenWelcomeAnimation = true
                        }
                        
                        // 檢查是否有未完成的迎賓流程（僅在未永久跳過時）
                        if !hasPermanentlySkippedOnboarding && progressManager.hasIncompleteOnboarding && !showContinueOnboarding {
                            // 延遲顯示，避免與啟動畫面衝突
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                showContinueOnboarding = true
                            }
                        }
                    }
                    .sheet(isPresented: $showContinueOnboarding) {
                        ContinueOnboardingView(isPresented: $showContinueOnboarding) {
                            // 返回迎賓流程（僅在未永久跳過時）
                            if !hasPermanentlySkippedOnboarding {
                                userStateManager.isOnboardingCompleted = false
                                hasSeenWelcomeAnimation = false
                            }
                        }
                    }
            } else if !hasSelectedLanguage {
                // 語言選擇（首次啟動）
                LanguageSelectionView { language in
                    hasSelectedLanguage = true
                    // 保存語言選擇狀態
                    UserDefaults.standard.set(true, forKey: "hasSelectedLanguage")
                }
                .environmentObject(LocalizationManager.shared)
            } else if !hasSeenWelcomeAnimation && !hasCompletedFirstLaunch && !hasPermanentlySkippedOnboarding {
                // 首次迎賓動畫（只在首次啟動時顯示，且未永久跳過）
                WelcomeAnimationView(
                    onAnimationComplete: {
                        hasSeenWelcomeAnimation = true
                    },
                    onSkip: {
                        // 跳過迎賓動畫時，也永久跳過整個迎賓流程
                        hasSeenWelcomeAnimation = true
                        hasPermanentlySkippedOnboarding = true
                        hasCompletedFirstLaunch = true
                        userStateManager.saveOnboardingCompleted()
                    }
                )
            } else if !hasCompletedFirstLaunch && !hasPermanentlySkippedOnboarding {
                // 迎賓流程（首次啟動，且未永久跳過）
                OnboardingCoordinatorView()
                    .onAppear {
                        // 完成迎賓流程後，標記首次啟動完成
                        if userStateManager.isOnboardingCompleted && !users.isEmpty {
                            hasCompletedFirstLaunch = true
                        }
                    }
            } else {
                // 如果已經完成首次啟動或永久跳過，直接顯示主應用
                MainAppView()
            }
        }
        .applyDesignSystem() // 應用設計系統
        .onAppear {
            designSystem.updateThemeConfiguration()
        }
    }
}

// MARK: - 延遲載入視圖
struct LazyView<Content: View>: View {
    let build: () -> Content
    
    init(_ build: @escaping () -> Content) {
        self.build = build
    }
    
    var body: some View {
        build()
    }
}

// MARK: - 啟動畫面
struct LaunchScreenView: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // 背景漸層
            LinearGradient(
                colors: [Color.safeHex("#1E3A8A", default: .blue), Color.safeHex("#312E81", default: .purple)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // App Icon - 使用完整的圓形圖示設計
                ZStack {
                    // 外層光暈效果
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.safeHex("#F59E0B", default: .orange).opacity(0.3),
                                    Color.safeHex("#D97706", default: .orange).opacity(0.1),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 40,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)
                        .scaleEffect(isAnimating ? 1.2 : 1.0)
                        .animation(AnimationOptimizer.shared.canAnimate() ? 
                            DesignSystemManager.shared.getEaseAnimation(duration: 2.0).repeatForever(autoreverses: true) : 
                            .linear(duration: 0), 
                            value: isAnimating)
                    
                    // 背景圓形
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.safeHex("#F59E0B", default: .orange),
                                    Color.safeHex("#D97706", default: .orange)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .shadow(color: Color.safeHex("#F59E0B", default: .orange).opacity(0.5), radius: 20, x: 0, y: 10)
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                        .animation(AnimationOptimizer.shared.canAnimate() ? 
                            DesignSystemManager.shared.getEaseAnimation(duration: 2.0).repeatForever(autoreverses: true) : 
                            .linear(duration: 0), 
                            value: isAnimating)
                    
                    // App Icon 圖片
                    // 嘗試從 bundle 載入 AppIcon
                    Group {
                        if let iconName = Bundle.main.object(forInfoDictionaryKey: "CFBundleIcons") as? [String: Any],
                           let primaryIcon = iconName["CFBundlePrimaryIcon"] as? [String: Any],
                           let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
                           let firstIcon = iconFiles.first,
                           let uiImage = UIImage(named: firstIcon) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                                )
                        } else if let uiImage = UIImage(named: "AppIcon") {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                                )
                        } else {
                            // 使用 SF Symbols 作為備用，並添加 RICH 文字
                            VStack(spacing: 4) {
                                Image(systemName: "dollarsign.circle.fill")
                                    .font(.system(size: 60))
                                Text("RICH")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .frame(width: 100, height: 100)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.2))
                            )
                        }
                    }
                }
                
                // App 名稱
                VStack(spacing: 8) {
                    Text("RICH Now AI")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("智慧財務管理")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                // 載入指示器
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.2)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// 主應用程式視圖
struct MainAppView: View {
    @State private var showAdvancedAssessment = false
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @StateObject private var tabController = TabController.shared
    @StateObject private var designSystem = DesignSystemManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // 離線狀態指示器
            OfflineIndicator()
            
            TabView(selection: $tabController.selectedTab) {
                // 財務儀表板 - 預設載入
                FinancialHealthDashboardView()
                    .tabItem {
                        Label(LocalizationManager.shared.localizedString("dashboard.title"), systemImage: "house.fill")
                    }
                    .tag(0)
                
                // AI 對話 - 延遲載入
                LazyView {
                    ChatView(
                        conversationManager: ConversationManager.shared,
                        transactionParser: TransactionParser(),
                        openAIService: OpenAIService.shared
                    )
                }
                .tabItem {
                    Label(LocalizationManager.shared.localizedString("chat.title"), systemImage: "message.fill")
                }
                .tag(1)
                
                // 記帳 - 延遲載入
                LazyView {
                    TransactionEntryView()
                }
                .tabItem {
                    Label(LocalizationManager.shared.localizedString("transaction.title"), systemImage: "plus.circle.fill")
                }
                .tag(2)
                
                // VGLA 面板 - 延遲載入
                LazyView {
                    VGLAPanelMainView()
                }
                .tabItem {
                    Label(LocalizationManager.shared.localizedString("panels.title"), systemImage: "square.grid.2x2.fill")
                }
                .tag(3)
                
                // 報表 - 延遲載入
                LazyView {
                    ReportsView()
                }
                .tabItem {
                    Label(LocalizationManager.shared.localizedString("reports.title"), systemImage: "chart.bar.fill")
                }
                .tag(4)
                
                // 設定
                LazyView {
                    SettingsView(showAdvancedAssessment: $showAdvancedAssessment)
                }
                .tabItem {
                    Label(LocalizationManager.shared.localizedString("settings.title"), systemImage: "gearshape.fill")
                }
                .tag(TabController.Tab.settings.rawValue)
            }
            .animation(designSystem.getSpringAnimation(), value: tabController.selectedTab)
        }
        .applyDesignSystem() // 應用設計系統到主應用視圖
        .sheet(isPresented: $showAdvancedAssessment) {
            AdvancedAssessmentView { result in
                showAdvancedAssessment = false
                if let result = result {
                    print("TKI Assessment completed: \(result)")
                }
            }
        }
    }
}

// 交易記帳視圖
struct TransactionEntryView: View {
    @State private var showTextAccounting = false
    @State private var showPhotoAccounting = false
    @State private var showTransactionHistory = false
    @State private var showMainMenu = false
    
    var body: some View {
        NavigationBarContainer(
            title: LocalizationManager.shared.localizedString("transaction.title"),
            showBackButton: true,
            showMenuButton: true,
            onBack: {
                // 返回主頁的邏輯
            },
            onMenu: {
                showMainMenu = true
            }
        ) {
            VStack(spacing: 20) {
                // 標題區域
                VStack(spacing: 12) {
                    Text("💰")
                        .font(.system(size: 50))
                    
                    Text(LocalizationManager.shared.localizedString("transaction.subtitle"))
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                // 功能按鈕
                VStack(spacing: 16) {
                    // 文字記帳
                    Button(action: { showTextAccounting = true }) {
                        HStack {
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(LocalizationManager.shared.localizedString("text_accounting.title"))
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                Text(LocalizationManager.shared.localizedString("text_accounting.subtitle"))
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(20)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0.12, green: 0.23, blue: 0.54), Color(red: 0.19, green: 0.18, blue: 0.51)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                    }
                    
                    // 拍照記帳
                    Button(action: { showPhotoAccounting = true }) {
                        HStack {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.green)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("拍照記帳")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                Text("拍攝發票自動識別")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .padding(20)
                        .background(Color(.systemGray6))
                        .cornerRadius(16)
                    }
                    
                    // 交易歷史
                    Button(action: { showTransactionHistory = true }) {
                        HStack {
                            Image(systemName: "list.bullet.rectangle")
                                .font(.system(size: 20))
                                .foregroundColor(.blue)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(LocalizationManager.shared.localizedString("transaction.history_title"))
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                Text(LocalizationManager.shared.localizedString("transaction.history_subtitle"))
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .padding(20)
                        .background(Color(.systemGray6))
                        .cornerRadius(16)
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .sheet(isPresented: $showTextAccounting) {
                TextAccountingView()
            }
            .sheet(isPresented: $showPhotoAccounting) {
                PhotoAccountingView()
            }
            .sheet(isPresented: $showTransactionHistory) {
                TransactionHistoryView()
            }
            .sheet(isPresented: $showMainMenu) {
                MainMenuView(isPresented: $showMainMenu)
            }
        }
    }
}

// ReportsView 已移至 Views/Reports/ReportsView.swift

// SettingsView 已移至 Views/Settings/SettingsView.swift
// 完整的 SettingsView 實作已移至 Views/Settings/SettingsView.swift

#Preview {
    ContentView()
        .modelContainer(for: User.self, inMemory: true)
}
