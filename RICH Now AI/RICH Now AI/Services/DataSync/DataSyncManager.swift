//
//  DataSyncManager.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import Foundation
import SwiftData
import CloudKit
import Combine

@MainActor
class DataSyncManager: ObservableObject {
    static let shared = DataSyncManager()
    
    @Published var isSyncing: Bool = false
    @Published var lastSyncDate: Date?
    @Published var syncError: String?
    
    private let cloudKitManager = CloudKitManager.shared
    private var modelContext: ModelContext?
    
    private init() {}
    
    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Sync Operations
    
    func syncAllData() async {
        guard let context = modelContext else {
            print("ModelContext not configured")
            return
        }
        
        await MainActor.run {
            self.isSyncing = true
            self.syncError = nil
        }
        
        do {
            // 檢查 CloudKit 狀態
            await cloudKitManager.checkAccountStatus()
            
            guard cloudKitManager.isSignedIn else {
                await MainActor.run {
                    self.syncError = "CloudKit account not available"
                    self.isSyncing = false
                }
                return
            }
            
            // 獲取當前用戶
            let userDescriptor = FetchDescriptor<User>()
            let users = try context.fetch(userDescriptor)
            
            guard let currentUser = users.first else {
                await MainActor.run {
                    self.syncError = "No user found"
                    self.isSyncing = false
                }
                return
            }
            
            // 同步用戶資料到 CloudKit
            await cloudKitManager.syncUserData(currentUser)
            
            // 更新同步時間
            await MainActor.run {
                self.lastSyncDate = Date()
                self.isSyncing = false
            }
            
        } catch {
            await MainActor.run {
                self.syncError = error.localizedDescription
                self.isSyncing = false
            }
        }
    }
    
    func syncUserProfile(_ user: User) async {
        await cloudKitManager.syncUserData(user)
    }
    
    func syncAssessmentResults(_ user: User) async {
        await cloudKitManager.syncUserData(user)
    }
    
    // MARK: - Data Backup
    
    func backupUserData(_ user: User) async -> Bool {
        await cloudKitManager.syncUserData(user)
        if case .error = cloudKitManager.syncStatus {
            return false
        }
        return true
    }
    
    // MARK: - Data Recovery
    
    func restoreUserData(userId: UUID) async -> Bool {
        do {
            let records = try await cloudKitManager.restoreUserData(userId: userId)
            
            guard let context = modelContext else {
                print("ModelContext not configured")
                return false
            }
            
            // 處理恢復的記錄
            for record in records {
                await processRestoredRecord(record, context: context)
            }
            
            return true
        } catch {
            print("Restore failed: \(error)")
            return false
        }
    }
    
    private func processRestoredRecord(_ record: CKRecord, context: ModelContext) async {
        switch record.recordType {
        case "UserProfile":
            await restoreUserProfile(record, context: context)
        case "VGLAAssessment":
            await restoreVGLAAssessment(record, context: context)
        case "TKIAssessment":
            await restoreTKIAssessment(record, context: context)
        case "Transaction":
            await restoreTransaction(record, context: context)
        case "FinancialGoal":
            await restoreFinancialGoal(record, context: context)
        default:
            print("Unknown record type: \(record.recordType)")
        }
    }
    
    private func restoreUserProfile(_ record: CKRecord, context: ModelContext) async {
        // 實現用戶資料恢復邏輯
        print("Restoring user profile: \(record.recordID)")
    }
    
    private func restoreVGLAAssessment(_ record: CKRecord, context: ModelContext) async {
        // 實現 VGLA 測驗結果恢復邏輯
        print("Restoring VGLA assessment: \(record.recordID)")
    }
    
    private func restoreTKIAssessment(_ record: CKRecord, context: ModelContext) async {
        // 實現 TKI 測驗結果恢復邏輯
        print("Restoring TKI assessment: \(record.recordID)")
    }
    
    private func restoreTransaction(_ record: CKRecord, context: ModelContext) async {
        // 實現交易記錄恢復邏輯
        print("Restoring transaction: \(record.recordID)")
    }
    
    private func restoreFinancialGoal(_ record: CKRecord, context: ModelContext) async {
        // 實現財務目標恢復邏輯
        print("Restoring financial goal: \(record.recordID)")
    }
    
    // MARK: - Conflict Resolution
    
    func resolveDataConflicts() async {
        // 實現資料衝突解決邏輯
        print("Resolving data conflicts...")
    }
    
    // MARK: - Sync Status
    
    var syncStatus: String {
        if isSyncing {
            return "Syncing..."
        } else if let error = syncError {
            return "Error: \(error)"
        } else if let lastSync = lastSyncDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return "Last sync: \(formatter.string(from: lastSync))"
        } else {
            return "Not synced"
        }
    }
}
