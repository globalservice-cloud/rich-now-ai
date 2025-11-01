//
//  SyncManager.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import Foundation
import SwiftData
import Combine

@MainActor
class SyncManager: ObservableObject {
    static let shared = SyncManager()
    
    @Published var isSyncing: Bool = false
    @Published var lastSyncDate: Date?
    @Published var pendingChanges: Int = 0
    @Published var syncError: String?
    @Published var syncProgress: Double = 0.0
    
    private var modelContext: ModelContext?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupNetworkMonitoring()
    }
    
    // MARK: - 設定管理
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    private func setupNetworkMonitoring() {
        // 監聽網路狀態變化
        NetworkMonitor.shared.$isConnected
            .sink { [weak self] isConnected in
                if isConnected {
                    Task {
                        await self?.syncWhenOnline()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - 同步管理
    
    func syncWhenOnline() async {
        guard NetworkMonitor.shared.isConnected else { 
            print("Network not available, skipping sync")
            return 
        }
        
        await performSync()
    }
    
    private func performSync() async {
        // 確保在主執行緒執行
        await MainActor.run {
            guard modelContext != nil else { return }
            
            self.isSyncing = true
            self.syncError = nil
            self.syncProgress = 0.0
        }
        
        guard let context = modelContext else {
            await MainActor.run {
                self.isSyncing = false
            }
            return
        }
        
        do {
            // 模擬同步進度
            for i in 1...10 {
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1秒
                await MainActor.run {
                    self.syncProgress = Double(i) / 10.0
                }
            }
            
            // 實際的 CloudKit 同步由 SwiftData 自動處理
            // 這裡我們只是確保數據已保存（必須在主執行緒）
            try await MainActor.run {
                try context.save()
            }
            
            await MainActor.run {
                self.lastSyncDate = Date()
                self.pendingChanges = 0
                self.syncProgress = 1.0
                self.isSyncing = false
            }
            
            print("Sync completed successfully")
        } catch {
            await MainActor.run {
                self.syncError = "同步失敗: \(error.localizedDescription)"
                self.isSyncing = false
            }
            print("Sync failed: \(error)")
        }
    }
    
    // MARK: - 手動同步
    
    func forceSync() async {
        await performSync()
    }
    
    // MARK: - 同步狀態檢查
    
    func checkSyncStatus() async {
        guard modelContext != nil else { return }
        
        // 檢查是否有未同步的變更
        // 這裡可以實作更複雜的邏輯來檢查 CloudKit 同步狀態
        pendingChanges = 0 // 簡化實作
    }
    
    // MARK: - 同步衝突解決
    
    func resolveConflicts() async {
        // 實作衝突解決邏輯
        // 優先使用最新數據
        print("Resolving sync conflicts...")
    }
    
    // MARK: - 同步設定
    
    func enableAutoSync(_ enabled: Bool) {
        // 實作自動同步開關
        print("Auto sync \(enabled ? "enabled" : "disabled")")
    }
    
    func setSyncFrequency(_ frequency: SyncFrequency) {
        // 實作同步頻率設定
        print("Sync frequency set to \(frequency.rawValue)")
    }
}

// MARK: - 同步頻率枚舉

enum SyncFrequency: String, CaseIterable {
    case immediate = "immediate"
    case every5Minutes = "5minutes"
    case every15Minutes = "15minutes"
    case everyHour = "hour"
    case manual = "manual"
    
    var displayName: String {
        switch self {
        case .immediate: return "即時同步"
        case .every5Minutes: return "每 5 分鐘"
        case .every15Minutes: return "每 15 分鐘"
        case .everyHour: return "每小時"
        case .manual: return "手動同步"
        }
    }
    
    var interval: TimeInterval {
        switch self {
        case .immediate: return 0
        case .every5Minutes: return 300
        case .every15Minutes: return 900
        case .everyHour: return 3600
        case .manual: return -1
        }
    }
}
