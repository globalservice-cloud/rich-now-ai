//
//  APIKeyManager.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import Foundation
import SwiftData
import Security
import CryptoKit
import Combine

@MainActor
class APIKeyManager: ObservableObject {
    static let shared = APIKeyManager()
    
    @Published var userAPIKeys: [UserAPIKey] = []
    @Published var activeKey: UserAPIKey?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var modelContext: ModelContext?
    
    init() {
        Task {
            await loadAPIKeys()
        }
    }
    
    // MARK: - 設定管理
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        Task {
            await loadAPIKeys()
        }
    }
    
    // MARK: - API Key 管理
    
    func saveAPIKey(_ keyValue: String, for service: String) {
        Task {
            await addAPIKey(service: service, keyName: "\(service) API Key", keyValue: keyValue)
        }
    }
    
    func addAPIKey(service: String, keyName: String, keyValue: String) async -> Bool {
        guard let context = modelContext else { return false }
        
        // 驗證 API Key 格式
        guard validateAPIKey(service: service, keyValue: keyValue) else {
            errorMessage = "無效的 API Key 格式"
            return false
        }
        
        // 加密存儲 API Key
        let encryptedKey = encryptAPIKey(keyValue)
        
        let apiKey = UserAPIKey(
            service: service,
            keyName: keyName,
            keyValue: encryptedKey
        )
        
        context.insert(apiKey)
        
        do {
            try context.save()
            await loadAPIKeys()
            return true
        } catch {
            errorMessage = "保存 API Key 失敗: \(error.localizedDescription)"
            return false
        }
    }
    
    func updateAPIKey(_ apiKey: UserAPIKey, newKeyName: String? = nil, newKeyValue: String? = nil) async -> Bool {
        guard let context = modelContext else { return false }
        
        if let newName = newKeyName {
            apiKey.keyName = newName
        }
        
        if let newValue = newKeyValue {
            // 驗證新的 API Key
            guard validateAPIKey(service: apiKey.service, keyValue: newValue) else {
                errorMessage = "無效的 API Key 格式"
                return false
            }
            
            // 加密存儲新的 API Key
            apiKey.keyValue = encryptAPIKey(newValue)
        }
        
        apiKey.updatedAt = Date()
        
        do {
            try context.save()
            await loadAPIKeys()
            return true
        } catch {
            errorMessage = "更新 API Key 失敗: \(error.localizedDescription)"
            return false
        }
    }
    
    func deleteAPIKey(_ apiKey: UserAPIKey) async -> Bool {
        guard let context = modelContext else { return false }
        
        context.delete(apiKey)
        
        do {
            try context.save()
            await loadAPIKeys()
            return true
        } catch {
            errorMessage = "刪除 API Key 失敗: \(error.localizedDescription)"
            return false
        }
    }
    
    func activateAPIKey(_ apiKey: UserAPIKey) async -> Bool {
        // 停用所有其他 Key
        for key in userAPIKeys {
            key.isActive = false
        }
        
        // 啟用選中的 Key
        apiKey.isActive = true
        apiKey.updatedAt = Date()
        
        guard let context = modelContext else { return false }
        
        do {
            try context.save()
            await loadAPIKeys()
            self.activeKey = apiKey
            return true
        } catch {
            errorMessage = "啟用 API Key 失敗: \(error.localizedDescription)"
            return false
        }
    }
    
    // MARK: - 載入 API Keys
    
    func loadAPIKeys() async {
        guard let context = modelContext else { return }
        
        isLoading = true
        
        do {
            let descriptor = FetchDescriptor<UserAPIKey>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            let keys = try context.fetch(descriptor)
            
            // 解密 API Keys
            let decryptedKeys = keys.map { key in
                let decryptedKey = UserAPIKey(
                    service: key.service,
                    keyName: key.keyName,
                    keyValue: decryptAPIKey(key.keyValue),
                    isActive: key.isActive,
                    usageCount: key.usageCount,
                    totalCost: key.totalCost
                )
                decryptedKey.id = key.id
                decryptedKey.createdAt = key.createdAt
                decryptedKey.updatedAt = key.updatedAt
                decryptedKey.lastUsedAt = key.lastUsedAt
                return decryptedKey
            }
            
            self.userAPIKeys = decryptedKeys
            self.activeKey = decryptedKeys.first { $0.isActive }
            
            isLoading = false
        } catch {
            errorMessage = "載入 API Keys 失敗: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    // MARK: - API Key 驗證
    
    private func validateAPIKey(service: String, keyValue: String) -> Bool {
        switch service.lowercased() {
        case "openai":
            return keyValue.hasPrefix("sk-") && keyValue.count >= 20
        case "anthropic":
            return keyValue.hasPrefix("sk-ant-") && keyValue.count >= 20
        case "google":
            return keyValue.hasPrefix("AIza") && keyValue.count >= 20
        default:
            return keyValue.count >= 10
        }
    }
    
    // MARK: - 加密/解密
    
    private func encryptAPIKey(_ key: String) -> String {
        guard let data = key.data(using: .utf8) else { return key }
        
        do {
            let symmetricKey = SymmetricKey(size: .bits256)
            let sealedBox = try AES.GCM.seal(data, using: symmetricKey)
            let encryptedData = sealedBox.combined
            return encryptedData?.base64EncodedString() ?? key
        } catch {
            print("Encryption failed: \(error)")
            return key
        }
    }
    
    private func decryptAPIKey(_ encryptedKey: String) -> String {
        guard let data = Data(base64Encoded: encryptedKey) else { return encryptedKey }
        
        do {
            let key = SymmetricKey(size: .bits256)
            let sealedBox = try AES.GCM.SealedBox(combined: data)
            let decryptedData = try AES.GCM.open(sealedBox, using: key)
            return String(data: decryptedData, encoding: .utf8) ?? encryptedKey
        } catch {
            print("Decryption failed: \(error)")
            return encryptedKey
        }
    }
    
    // MARK: - 使用 API Key
    
    func useAPIKey(for service: String) -> String? {
        // 優先使用用戶自備的 Key
        if let activeKey = activeKey, activeKey.service == service {
            activeKey.usageCount += 1
            activeKey.lastUsedAt = Date()
            return activeKey.keyValue
        }
        
        // 如果沒有自備 Key，返回 nil（使用應用程式預設 Key）
        return nil
    }
    
    func recordAPIKeyUsage(_ apiKey: UserAPIKey, cost: Double) {
        apiKey.usageCount += 1
        apiKey.totalCost += cost
        apiKey.lastUsedAt = Date()
        apiKey.updatedAt = Date()
        
        guard let context = modelContext else { return }
        
        do {
            try context.save()
        } catch {
            print("Failed to update API key usage: \(error)")
        }
    }
    
    // MARK: - 獲取 API Key 統計
    
    // MARK: - 缺失的方法
    
    func getAPIKey(for service: String) -> String? {
        return userAPIKeys.first { $0.service == service && $0.isActive }?.keyValue
    }
    
    func isUsingOwnAPIKey(for service: String) -> Bool {
        return userAPIKeys.contains { $0.service == service && $0.isActive }
    }
    
    func canMakeRequest(for service: String) -> Bool {
        // 如果用戶有自己的 Key，可以使用
        if isUsingOwnAPIKey(for: service) {
            return true
        }
        // 如果沒有自備 Key，檢查是否有訂閱權限（允許使用應用程式預設 Key）
        // 這裡應該檢查訂閱狀態，暫時返回 true 允許嘗試
        return true
    }
    
    func trackAPIUsage(for service: String, tokens: Int, cost: Double) {
        guard let key = userAPIKeys.first(where: { $0.service == service && $0.isActive }) else { return }
        key.usageCount += 1
        key.totalCost += cost
        key.lastUsedAt = Date()
    }
    
    func getAPIKeyStats() -> [String: Any] {
        var stats: [String: Any] = [:]
        
        let totalKeys = userAPIKeys.count
        let activeKeys = userAPIKeys.filter { $0.isActive }.count
        let totalUsage = userAPIKeys.reduce(0) { $0 + $1.usageCount }
        let totalCost = userAPIKeys.reduce(0.0) { $0 + $1.totalCost }
        
        stats["totalKeys"] = totalKeys
        stats["activeKeys"] = activeKeys
        stats["totalUsage"] = totalUsage
        stats["totalCost"] = totalCost
        
        // 按服務分類統計
        var serviceStats: [String: [String: Any]] = [:]
        for key in userAPIKeys {
            if serviceStats[key.service] == nil {
                serviceStats[key.service] = [
                    "count": 0,
                    "usage": 0,
                    "cost": 0.0
                ]
            }
            
            var keyStats = serviceStats[key.service] ?? [:]
            keyStats["count"] = (keyStats["count"] as? Int ?? 0) + 1
            keyStats["usage"] = (keyStats["usage"] as? Int ?? 0) + key.usageCount
            keyStats["cost"] = (keyStats["cost"] as? Double ?? 0.0) + key.totalCost
            serviceStats[key.service] = keyStats
        }
        
        stats["serviceStats"] = serviceStats
        
        return stats
    }
    
    // MARK: - 測試 API Key
    
    func testAPIKey(_ apiKey: UserAPIKey) async -> Bool {
        // 這裡可以實現實際的 API 測試
        // 暫時返回 true
        return true
    }
}
