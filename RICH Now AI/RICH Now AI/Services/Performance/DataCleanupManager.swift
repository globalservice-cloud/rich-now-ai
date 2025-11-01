//
//  DataCleanupManager.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/28.
//

import Foundation
import SwiftData
import Combine
import os.log

@MainActor
class DataCleanupManager: ObservableObject {
    static let shared = DataCleanupManager()
    
    @Published var isCleaning = false
    @Published var cleanupProgress: Double = 0.0
    @Published var lastCleanupDate: Date?
    
    private let logger = Logger(subsystem: "com.richnowai", category: "DataCleanupManager")
    private var modelContext: ModelContext?
    
    private init() {}
    
    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - 主要清理方法
    
    func cleanupUnusedData() async {
        guard let context = modelContext else {
            logger.error("Model context not available")
            return
        }
        
        isCleaning = true
        cleanupProgress = 0.0
        
        // 1. 清理過期的 API 使用記錄
        await cleanupExpiredAPIUsage(context: context)
        cleanupProgress = 0.2
        
        // 2. 清理未使用的圖片快取
        await cleanupUnusedImageCache()
        cleanupProgress = 0.4
        
        // 3. 清理臨時文件
        await cleanupTemporaryFiles()
        cleanupProgress = 0.6
        
        // 4. 清理過期的會話記錄
        await cleanupExpiredConversations(context: context)
        cleanupProgress = 0.8
        
        // 5. 清理未使用的用戶設定
        await cleanupUnusedUserSettings(context: context)
        cleanupProgress = 1.0
        
        lastCleanupDate = Date()
        logger.info("Data cleanup completed successfully")
        
        isCleaning = false
    }
    
    // MARK: - 具體清理實現
    
    private func cleanupExpiredAPIUsage(context: ModelContext) async {
        let cutoffDate = Date().addingTimeInterval(-30 * 24 * 60 * 60) // 30天前
        
        do {
            let descriptor = FetchDescriptor<APIUsage>(
                predicate: #Predicate<APIUsage> { usage in
                    usage.date < cutoffDate
                }
            )
            
            let expiredUsage = try context.fetch(descriptor)
            
            for usage in expiredUsage {
                context.delete(usage)
            }
            
            try context.save()
            logger.info("Cleaned up \(expiredUsage.count) expired API usage records")
            
        } catch {
            logger.error("Failed to cleanup expired API usage: \(error.localizedDescription)")
        }
    }
    
    private func cleanupUnusedImageCache() async {
        // 清理未使用的圖片快取
        ImageCacheManager.shared.clearCache()
        logger.info("Cleaned up unused image cache")
    }
    
    private func cleanupTemporaryFiles() async {
        let tempDir = FileManager.default.temporaryDirectory
        let cutoffDate = Date().addingTimeInterval(-24 * 60 * 60) // 24小時前
        
        do {
            let tempFiles = try FileManager.default.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: [.creationDateKey])
            
            var cleanedCount = 0
            for file in tempFiles {
                let attributes = try FileManager.default.attributesOfItem(atPath: file.path)
                if let creationDate = attributes[.creationDate] as? Date,
                   creationDate < cutoffDate {
                    try FileManager.default.removeItem(at: file)
                    cleanedCount += 1
                }
            }
            
            logger.info("Cleaned up \(cleanedCount) temporary files")
            
        } catch {
            logger.error("Failed to cleanup temporary files: \(error.localizedDescription)")
        }
    }
    
    private func cleanupExpiredConversations(context: ModelContext) async {
        let cutoffDate = Date().addingTimeInterval(-90 * 24 * 60 * 60) // 90天前
        
        do {
            let descriptor = FetchDescriptor<Conversation>(
                predicate: #Predicate<Conversation> { conversation in
                    conversation.createdAt < cutoffDate
                }
            )
            
            let expiredConversations = try context.fetch(descriptor)
            
            for conversation in expiredConversations {
                context.delete(conversation)
            }
            
            try context.save()
            logger.info("Cleaned up \(expiredConversations.count) expired conversations")
            
        } catch {
            logger.error("Failed to cleanup expired conversations: \(error.localizedDescription)")
        }
    }
    
    private func cleanupUnusedUserSettings(context: ModelContext) async {
        do {
            let descriptor = FetchDescriptor<UserSettings>()
            let allSettings = try context.fetch(descriptor)
            
            var cleanedCount = 0
            for settings in allSettings {
                // 檢查是否有未使用的設定
                if settings.isUnused() {
                    context.delete(settings)
                    cleanedCount += 1
                }
            }
            
            try context.save()
            logger.info("Cleaned up \(cleanedCount) unused user settings")
            
        } catch {
            logger.error("Failed to cleanup unused user settings: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 定期清理
    
    func schedulePeriodicCleanup() {
        // 每天執行一次清理
        Timer.scheduledTimer(withTimeInterval: 24 * 60 * 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.cleanupUnusedData()
            }
        }
    }
    
    // MARK: - 清理統計
    
    func getCleanupStats() -> CleanupStats {
        return CleanupStats(
            lastCleanupDate: lastCleanupDate,
            isCleaning: isCleaning,
            cleanupProgress: cleanupProgress
        )
    }
}

// MARK: - 支援類型

struct CleanupStats {
    let lastCleanupDate: Date?
    let isCleaning: Bool
    let cleanupProgress: Double
    
    var timeSinceLastCleanup: TimeInterval? {
        guard let lastCleanup = lastCleanupDate else { return nil }
        return Date().timeIntervalSince(lastCleanup)
    }
    
    var needsCleanup: Bool {
        guard let timeSince = timeSinceLastCleanup else { return true }
        return timeSince > 24 * 60 * 60 // 24小時
    }
}

// MARK: - UserSettings 擴展

extension UserSettings {
    func isUnused() -> Bool {
        // 檢查設定是否被使用
        // 這裡可以根據具體的業務邏輯來判斷
        return false
    }
}
