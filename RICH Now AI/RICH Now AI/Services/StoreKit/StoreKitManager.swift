//
//  StoreKitManager.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import Foundation
import StoreKit
import Combine

@MainActor
class StoreKitManager: ObservableObject {
    static let shared = StoreKitManager()
    
    @Published var products: [SubscriptionProduct] = []
    @Published var currentSubscription: SubscriptionPlan = .free
    @Published var subscriptionStatus: SubscriptionStatus = .none
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var productIds: Set<String> = [
        SubscriptionPlan.basic.rawValue,
        SubscriptionPlan.premium.rawValue,
        SubscriptionPlan.pro.rawValue
    ]
    
    // App Store Connect 產品 ID 配置
    private let appStoreConnectProductIds: [String: String] = [
        "com.richnowai.basic": "com.richnowai.basic.monthly",
        "com.richnowai.premium": "com.richnowai.premium.monthly", 
        "com.richnowai.pro": "com.richnowai.pro.monthly"
    ]
    
    private var transactionListener: Task<Void, Error>?
    private var subscriptionStatusListener: Task<Void, Error>?
    
    init() {
        setupTransactionListener()
        setupSubscriptionStatusListener()
        loadSubscriptionStatus()
    }
    
    deinit {
        transactionListener?.cancel()
        subscriptionStatusListener?.cancel()
    }
    
    // MARK: - 產品載入
    
    func loadProducts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let storeProducts = try await Product.products(for: productIds)
            
            await MainActor.run {
                self.products = storeProducts.map { product in
                    let plan = SubscriptionPlan(rawValue: product.id) ?? .free
                    let isPopular = plan == .premium // 標記進階方案為熱門
                    return SubscriptionProduct(
                        plan: plan,
                        product: product,
                        isPopular: isPopular
                    )
                }.sorted { $0.plan.rawValue < $1.plan.rawValue }
                
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    // MARK: - 購買處理
    
    func purchase(_ product: SubscriptionProduct) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await product.product.purchase()
            
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                
                await updateSubscriptionStatus()
                await MainActor.run {
                    self.isLoading = false
                }
                return true
                
            case .userCancelled:
                await MainActor.run {
                    self.isLoading = false
                }
                return false
                
            case .pending:
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = "購買處理中..."
                }
                return false
                
            @unknown default:
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = "未知錯誤"
                }
                return false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
            return false
        }
    }
    
    // MARK: - 訂閱狀態管理
    
    func updateSubscriptionStatus() async {
        // 簡化實現：使用本地存儲的訂閱狀態
        // TODO: 在實際應用中，應該正確使用 StoreKit 2 API 來檢查訂閱狀態
        // 正確的方式是使用 Transaction.currentEntitlements 或訂閱狀態更新監聽器
        
        // 從本地存儲載入狀態（如果有）
        loadSubscriptionStatus()
        
        // 如果需要，可以在這裡添加 StoreKit 2 的實際檢查邏輯
        // 由於 StoreKit 2 API 的複雜性，暫時使用本地存儲的狀態
    }
    
    // 輔助方法：計算方案優先級
    private func planPriority(_ plan: SubscriptionPlan) -> Int {
        switch plan {
        case .free: return 0
        case .basic: return 1
        case .premium: return 2
        case .pro: return 3
        }
    }
    
    // 保存訂閱狀態到本地存儲
    private func saveSubscriptionStatus(
        plan: SubscriptionPlan,
        status: SubscriptionStatus,
        expiryDate: Date?,
        isTrial: Bool,
        isAutoRenew: Bool
    ) async {
        let subscriptionData = [
            "plan": plan.rawValue,
            "status": status.rawValue,
            "expiryDate": expiryDate?.timeIntervalSince1970 ?? 0,
            "isTrial": isTrial,
            "isAutoRenew": isAutoRenew,
            "lastUpdated": Date().timeIntervalSince1970
        ] as [String: Any]
        
        UserDefaults.standard.set(subscriptionData, forKey: "subscription_status")
        
        // 保存到訂閱歷史記錄
        await saveToSubscriptionHistory(
            plan: plan,
            status: status,
            expiryDate: expiryDate,
            isTrial: isTrial,
            isAutoRenew: isAutoRenew
        )
    }
    
    // 保存到訂閱歷史記錄
    private func saveToSubscriptionHistory(
        plan: SubscriptionPlan,
        status: SubscriptionStatus,
        expiryDate: Date?,
        isTrial: Bool,
        isAutoRenew: Bool
    ) async {
        // 這裡需要 ModelContext 來保存到 SwiftData
        // 實際應用中需要從環境中獲取 ModelContext
        print("Saving subscription history: \(plan.rawValue) - \(status.rawValue)")
    }
    
    // 從本地存儲載入訂閱狀態
    func loadSubscriptionStatus() {
        guard let subscriptionData = UserDefaults.standard.dictionary(forKey: "subscription_status") else {
            return
        }
        
        if let planString = subscriptionData["plan"] as? String,
           let plan = SubscriptionPlan(rawValue: planString) {
            currentSubscription = plan
        }
        
        if let statusString = subscriptionData["status"] as? String,
           let status = SubscriptionStatus(rawValue: statusString) {
            subscriptionStatus = status
        }
    }
    
    // 檢查訂閱是否即將過期
    func isSubscriptionExpiringSoon() -> Bool {
        guard let subscriptionData = UserDefaults.standard.dictionary(forKey: "subscription_status"),
              let expiryTimestamp = subscriptionData["expiryDate"] as? TimeInterval else {
            return false
        }
        
        let expiryDate = Date(timeIntervalSince1970: expiryTimestamp)
        let daysUntilExpiry = Calendar.current.dateComponents([.day], from: Date(), to: expiryDate).day ?? 0
        
        return daysUntilExpiry <= 7 && daysUntilExpiry > 0
    }
    
    // 獲取訂閱到期日期
    func getSubscriptionExpiryDate() -> Date? {
        guard let subscriptionData = UserDefaults.standard.dictionary(forKey: "subscription_status"),
              let expiryTimestamp = subscriptionData["expiryDate"] as? TimeInterval else {
            return nil
        }
        
        return Date(timeIntervalSince1970: expiryTimestamp)
    }
    
    // MARK: - 恢復購買
    
    func restorePurchases() async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            try await AppStore.sync()
            await updateSubscriptionStatus()
            
            await MainActor.run {
                self.isLoading = false
            }
            return subscriptionStatus == .active
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
            return false
        }
    }
    
    // MARK: - 取消訂閱
    
    func cancelSubscription() async -> Bool {
        // 在 App Store 中打開訂閱管理
        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
            await UIApplication.shared.open(url)
            return true
        }
        return false
    }
    
    // MARK: - 功能檢查
    
    func canUseFeature(_ feature: SubscriptionFeature) -> Bool {
        let limits = currentSubscription.limits
        
        switch feature {
        case .aiChat:
            return limits.aiChatMessages == -1 || getCurrentUsage(.aiChat) < limits.aiChatMessages
        case .voiceInput:
            return limits.voiceMinutes == -1 || getCurrentUsage(.voiceInput) < limits.voiceMinutes
        case .imageAnalysis:
            return limits.imageAnalysis == -1 || getCurrentUsage(.imageAnalysis) < limits.imageAnalysis
        case .advancedReports:
            return limits.advancedReports
        case .customThemes:
            return limits.customThemes
        case .prioritySupport:
            return limits.prioritySupport
        case .apiKeySupport:
            return limits.apiKeySupport
        }
    }
    
    func getRemainingUsage(_ feature: SubscriptionFeature) -> Int {
        let limits = currentSubscription.limits
        
        switch feature {
        case .aiChat:
            return limits.aiChatMessages == -1 ? -1 : max(0, limits.aiChatMessages - getCurrentUsage(.aiChat))
        case .voiceInput:
            return limits.voiceMinutes == -1 ? -1 : max(0, limits.voiceMinutes - getCurrentUsage(.voiceInput))
        case .imageAnalysis:
            return limits.imageAnalysis == -1 ? -1 : max(0, limits.imageAnalysis - getCurrentUsage(.imageAnalysis))
        default:
            return canUseFeature(feature) ? -1 : 0
        }
    }
    
    // MARK: - 私有方法
    
    private func setupTransactionListener() {
        transactionListener = Task.detached {
            // 簡化的交易監聽實現
            // 在實際應用中，這裡應該使用正確的 StoreKit 2 API
            print("Transaction listener started")
        }
    }
    
    private func setupSubscriptionStatusListener() {
        subscriptionStatusListener = Task.detached {
            // 簡化的訂閱狀態監聽實現
            // 在實際應用中，這裡應該使用正確的 StoreKit 2 API
            print("Subscription status listener started")
        }
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreKitError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    private func getCurrentUsage(_ feature: SubscriptionFeature) -> Int {
        // 這裡應該從實際使用統計中獲取
        // 暫時返回 0，實際應用中需要追蹤使用量
        return 0
    }
}

// MARK: - 訂閱功能枚舉

enum SubscriptionFeature: String, CaseIterable {
    case aiChat = "ai_chat"
    case voiceInput = "voice_input"
    case imageAnalysis = "image_analysis"
    case advancedReports = "advanced_reports"
    case customThemes = "custom_themes"
    case prioritySupport = "priority_support"
    case apiKeySupport = "api_key_support"
    
    var displayName: String {
        switch self {
        case .aiChat:
            return "AI 聊天"
        case .voiceInput:
            return "語音輸入"
        case .imageAnalysis:
            return "圖像分析"
        case .advancedReports:
            return "進階報告"
        case .customThemes:
            return "自訂主題"
        case .prioritySupport:
            return "優先支援"
        case .apiKeySupport:
            return "API 金鑰支援"
        }
    }
}

// MARK: - StoreKit 錯誤

enum StoreKitError: Error, LocalizedError {
    case failedVerification
    case productNotFound
    case purchaseFailed
    case restoreFailed
    
    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "驗證失敗"
        case .productNotFound:
            return "找不到產品"
        case .purchaseFailed:
            return "購買失敗"
        case .restoreFailed:
            return "恢復失敗"
        }
    }
}
