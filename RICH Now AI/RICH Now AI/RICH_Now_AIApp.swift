//
//  RICH_Now_AIApp.swift
//  RICH Now AI
//
//  Created by Chang Yao tiem on 2025/10/26.
//

import SwiftUI
import SwiftData
import CloudKit
import Combine

@main
struct RICH_Now_AIApp: App {
    @StateObject private var dataSyncManager = DataSyncManager.shared
    @StateObject private var migrationManager = DataMigrationManager.shared
    @StateObject private var syncManager = SyncManager.shared
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @StateObject private var oauthService = OpenAIOAuthService()
    
    // 整合性能優化管理器
    @StateObject private var performanceManager = PerformanceManager.shared
    @StateObject private var memoryOptimizer = MemoryOptimizer.shared
    @StateObject private var aiOptimizer = AppleNativeAIOptimizer.shared
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            User.self,
            VGLAAssessment.self,
            VGLAReport.self,
            VGLAProfile.self,
            VGLAHistoryRecord.self,
            TKIAssessment.self,
            Conversation.self,
            Transaction.self,
            FinancialProfile.self,
            FinancialGoal.self,
            Budget.self,
            Report.self,
            Investment.self,
            InvestmentTransaction.self,
            InvestmentPortfolio.self,
            FinancialHealthReport.self,
            ThemePanel.self,
            Gabriel.self,
            SubscriptionHistory.self,
            SubscriptionAnalytics.self,
            SubscriptionChange.self,
            UserSettings.self,
            APIUsage.self,
            APIUsageStats.self,
            APIQuotaLimit.self,
            UserAPIKey.self,
            InvoiceCarrier.self,
            FamilyGroup.self,
            FamilyMember.self,
            FamilyBudget.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema, 
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(sharedModelContainer)
                .environmentObject(dataSyncManager)
                .environmentObject(migrationManager)
                .environmentObject(syncManager)
                .environmentObject(networkMonitor)
                .environmentObject(oauthService)
                .environmentObject(performanceManager)
                .environmentObject(memoryOptimizer)
                .environmentObject(aiOptimizer)
                .environmentObject(LocalizationManager.shared)
                .onAppear {
                    // 延遲初始化，避免阻塞 UI
                    Task.detached(priority: .background) {
                        await initializeServices()
                    }
                    
                    // 初始化性能優化
                    Task { @MainActor in
                        setupPerformanceOptimizations()
                    }
                    
                    // 檢查並恢復進度
                    Task { @MainActor in
                        checkAndRestoreProgress()
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    // 應用程式從背景恢復時，重新檢查進度
                    Task { @MainActor in
                        OnboardingProgressManager.shared.loadProgress()
                    }
                }
                .onChange(of: networkMonitor.isConnected) { _, isConnected in
                    if isConnected {
                        // 使用 MainActor 確保在主執行緒執行，因為 SyncManager 是 @MainActor
                        Task { @MainActor in
                            await syncManager.syncWhenOnline()
                        }
                    }
                }
                .onOpenURL { url in
                    // 處理 OAuth 回調
                    if url.scheme == "richnowai" && url.host == "oauth" {
                        oauthService.handleCallback(url: url)
                    }
                }
        }
        .modelContainer(sharedModelContainer)
    }
    
    // MARK: - 進度檢查和恢復
    
    private func checkAndRestoreProgress() {
        Task { @MainActor in
            let progressManager = OnboardingProgressManager.shared
            progressManager.loadProgress()
            
            // 如果有未完成的進度，記錄但不自動恢復（讓用戶選擇是否繼續）
            if progressManager.hasIncompleteOnboarding {
                print("檢測到未完成的迎賓流程進度")
                // 可以在這裡顯示提示，讓用戶選擇是否繼續
            }
        }
    }
    
    // MARK: - 服務初始化
    private func initializeServices() async {
        // 配置資料同步管理器
        await MainActor.run {
            dataSyncManager.configure(modelContext: sharedModelContainer.mainContext)
            syncManager.setModelContext(sharedModelContainer.mainContext)
        }
        
        // 執行資料遷移（低優先級）
        await migrationManager.performMigrationIfNeeded()
        
        // 驗證資料完整性（低優先級）
        _ = await migrationManager.validateDataIntegrity()
        
        // 延遲同步，避免影響啟動速度
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2秒延遲
        // 使用 MainActor 確保在主執行緒執行（同步調用已在主執行緒）
        await syncManager.syncWhenOnline()
    }
    
    // MARK: - 性能優化設置
    private func setupPerformanceOptimizations() {
        // 設定數據清理管理器
        DataCleanupManager.shared.setup(modelContext: sharedModelContainer.mainContext)
        
        // 啟動定期清理
        DataCleanupManager.shared.schedulePeriodicCleanup()
        
        // 設定 AI 優化級別
        aiOptimizer.setOptimizationLevel(.balanced)
    }
}
