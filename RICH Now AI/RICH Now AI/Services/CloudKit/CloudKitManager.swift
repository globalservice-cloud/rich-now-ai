//
//  CloudKitManager.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import Foundation
import CloudKit
import SwiftData
import Combine

@MainActor
class CloudKitManager: ObservableObject {
    static let shared = CloudKitManager()
    
    @Published var isSignedIn: Bool = false
    @Published var accountStatus: CKAccountStatus = .couldNotDetermine
    @Published var syncStatus: SyncStatus = .idle
    
    private var container: CKContainer?
    private var privateDatabase: CKDatabase?
    
    enum SyncStatus {
        case idle
        case syncing
        case success
        case error(String)
    }
    
    private init() {
        // 暫時禁用 CloudKit 初始化，避免啟動時崩潰
        // TODO: 在 CloudKit 正確配置後重新啟用
        print("CloudKit initialization disabled for now")
        self.isSignedIn = false
        self.accountStatus = .couldNotDetermine
    }
    
    private func initializeCloudKit() async {
        // 暫時禁用 CloudKit 初始化
        print("CloudKit initialization is currently disabled")
        await MainActor.run {
            self.isSignedIn = false
            self.accountStatus = .couldNotDetermine
        }
    }
    
    // MARK: - Account Status
    
    func checkAccountStatus() async {
        guard let container = container else {
            print("CloudKit container not initialized")
            await MainActor.run {
                self.isSignedIn = false
                self.accountStatus = .couldNotDetermine
            }
            return
        }
        
        do {
            let status = try await container.accountStatus()
            await MainActor.run {
                self.accountStatus = status
                self.isSignedIn = (status == .available)
            }
        } catch {
            print("Failed to check account status: \(error)")
            await MainActor.run {
                self.isSignedIn = false
            }
        }
    }
    
    // MARK: - CloudKit Sync
    
    private func ensureCloudKitAvailable() -> Bool {
        guard container != nil && privateDatabase != nil else {
            print("CloudKit not available")
            return false
        }
        return true
    }
    
    func requestPermission() async -> Bool {
        guard let container = container else {
            print("CloudKit container not initialized")
            return false
        }
        
        if #available(iOS 17, *) {
            // iOS 17 之後不再需要申請此權限
            return true
        } else {
            do {
                let status = try await container.requestApplicationPermission(.userDiscoverability)
                return status == .granted
            } catch {
                print("Failed to request permission: \(error)")
                return false
            }
        }
    }
    
    func syncUserData(_ user: User) async {
        guard ensureCloudKitAvailable() else {
            await MainActor.run {
                self.syncStatus = .error("CloudKit not available")
            }
            return
        }
        
        await MainActor.run {
            self.syncStatus = .syncing
        }
        
        do {
            // 同步用戶基本資訊
            try await syncUserProfile(user)
            
            // 同步 VGLA 測驗結果
            if let vglaAssessment = user.vglaAssessment {
                try await syncVGLAAssessment(vglaAssessment, userId: user.id)
            }
            
            // 同步 TKI 測驗結果
            if let tkiAssessment = user.tkiAssessment {
                try await syncTKIAssessment(tkiAssessment, userId: user.id)
            }
            
            // 同步財務資料
            try await syncFinancialData(user)
            
            await MainActor.run {
                self.syncStatus = .success
            }
        } catch {
            print("Sync failed: \(error)")
            await MainActor.run {
                self.syncStatus = .error(error.localizedDescription)
            }
        }
    }
    
    private func syncUserProfile(_ user: User) async throws {
        guard let privateDatabase = privateDatabase else {
            throw NSError(domain: "CloudKitManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "CloudKit not available"])
        }
        
        let record = CKRecord(recordType: "UserProfile", recordID: CKRecord.ID(recordName: user.id.uuidString))
        
        record["name"] = user.name
        record["email"] = user.email
        record["age"] = user.age
        record["occupation"] = user.occupation
        record["familyStatus"] = user.familyStatus
        record["createdAt"] = user.createdAt
        record["lastLoginAt"] = user.lastLoginAt
        record["financialHealthScore"] = user.financialHealthScore
        record["subscriptionType"] = user.subscriptionType
        
        // VGLA 結果
        record["vglaCompleted"] = user.vglaCompleted
        record["vglaPrimaryType"] = user.vglaPrimaryType
        record["vglaSecondaryType"] = user.vglaSecondaryType
        record["vglaCombinationType"] = user.vglaCombinationType
        
        // TKI 結果
        record["tkiCompleted"] = user.tkiCompleted
        record["tkiPrimaryMode"] = user.tkiPrimaryMode
        record["tkiSecondaryMode"] = user.tkiSecondaryMode
        
        try await privateDatabase.save(record)
    }
    
    private func syncVGLAAssessment(_ assessment: VGLAAssessment, userId: UUID) async throws {
        guard let privateDatabase = privateDatabase else {
            throw NSError(domain: "CloudKitManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "CloudKit not available"])
        }
        
        let record = CKRecord(recordType: "VGLAAssessment", recordID: CKRecord.ID(recordName: "\(userId.uuidString)_vgla"))
        
        record["userId"] = userId.uuidString
        record["isCompleted"] = assessment.isCompleted
        record["startedAt"] = assessment.startedAt
        record["completedAt"] = assessment.completedAt
        record["currentQuestionIndex"] = assessment.currentQuestionIndex
        // 將 answers 字典轉換為 JSON 字串
        if let answersData = try? JSONSerialization.data(withJSONObject: assessment.answers),
           let answersString = String(data: answersData, encoding: .utf8) {
            record["answers"] = answersString
        }
        record["score"] = assessment.score
        record["primaryType"] = assessment.primaryType
        record["secondaryType"] = assessment.secondaryType
        record["tertiaryType"] = assessment.tertiaryType
        record["blindSpotType"] = assessment.blindSpotType
        record["reportGenerated"] = assessment.reportGenerated
        record["reportGeneratedAt"] = assessment.reportGeneratedAt
        record["reportData"] = assessment.reportData
        
        try await privateDatabase.save(record)
    }
    
    private func syncTKIAssessment(_ assessment: TKIAssessment, userId: UUID) async throws {
        guard let privateDatabase = privateDatabase else {
            throw NSError(domain: "CloudKitManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "CloudKit not available"])
        }
        
        let record = CKRecord(recordType: "TKIAssessment", recordID: CKRecord.ID(recordName: "\(userId.uuidString)_tki"))
        
        record["userId"] = userId.uuidString
        record["questionsData"] = assessment.questionsData
        record["answersData"] = assessment.answersData
        record["resultData"] = assessment.resultData
        record["completedAt"] = assessment.completedAt
        record["createdAt"] = assessment.createdAt
        
        try await privateDatabase.save(record)
    }
    
    private func syncFinancialData(_ user: User) async throws {
        guard let privateDatabase = privateDatabase else {
            throw NSError(domain: "CloudKitManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "CloudKit not available"])
        }
        
        // 同步交易記錄
        for transaction in user.transactions {
            let record = CKRecord(recordType: "Transaction", recordID: CKRecord.ID(recordName: "\(user.id.uuidString)_\(transaction.id.uuidString)"))
            
            record["userId"] = user.id.uuidString
            record["amount"] = transaction.amount
            record["category"] = transaction.category
            record["transactionDescription"] = transaction.transactionDescription
            record["date"] = transaction.date
            record["type"] = transaction.type
            record["tags"] = transaction.tags
            
            try await privateDatabase.save(record)
        }
        
        // 同步財務目標
        for goal in user.goals {
            let record = CKRecord(recordType: "FinancialGoal", recordID: CKRecord.ID(recordName: "\(user.id.uuidString)_\(goal.id.uuidString)"))
            
            record["userId"] = user.id.uuidString
            record["title"] = goal.title
            record["goalDescription"] = goal.goalDescription
            record["targetAmount"] = goal.targetAmount
            record["currentAmount"] = goal.currentAmount
            record["targetDate"] = goal.targetDate
            record["priority"] = goal.priority
            record["isCompleted"] = goal.status == GoalStatus.completed.rawValue
            record["createdAt"] = goal.createdAt
            
            try await privateDatabase.save(record)
        }
    }
    
    // MARK: - Data Recovery
    
    func restoreUserData(userId: UUID) async throws -> [CKRecord] {
        guard let privateDatabase = privateDatabase else {
            throw NSError(domain: "CloudKitManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "CloudKit not available"])
        }
        
        let predicate = NSPredicate(format: "userId == %@", userId.uuidString)
        let query = CKQuery(recordType: "UserProfile", predicate: predicate)
        
        let (results, _) = try await privateDatabase.records(matching: query)
        return results.compactMap { result in
            switch result.1 {
            case .success(let record):
                return record
            case .failure:
                return nil
            }
        }
    }
    
    // MARK: - Conflict Resolution
    
    func resolveConflict(localRecord: CKRecord, remoteRecord: CKRecord) -> CKRecord {
        // 使用最新的修改時間
        if let localDate = localRecord.modificationDate,
           let remoteDate = remoteRecord.modificationDate {
            return localDate > remoteDate ? localRecord : remoteRecord
        }
        
        // 預設使用遠端記錄
        return remoteRecord
    }
}
