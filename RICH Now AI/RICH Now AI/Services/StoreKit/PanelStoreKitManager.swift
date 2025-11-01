//
//  PanelStoreKitManager.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import Foundation
import StoreKit
import Combine

// 面板產品配置
struct PanelProduct {
    let id: String
    let panelType: VGLAPanelType
    let name: String
    let description: String
    let price: String
    let currency: String
    let isPopular: Bool
    let discount: String?
    let features: [String]
}

// 面板商店管理器
@MainActor
class PanelStoreKitManager: ObservableObject {
    static let shared = PanelStoreKitManager()
    
    @Published var products: [Product] = []
    @Published var purchasedProducts: Set<String> = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // 面板產品 ID 配置
    private let panelProductIDs = [
        "com.richnowai.panel.vision_mission",
        "com.richnowai.panel.vision_legacy",
        "com.richnowai.panel.vision_impact",
        "com.richnowai.panel.goal_medium",
        "com.richnowai.panel.goal_long",
        "com.richnowai.panel.goal_life",
        "com.richnowai.panel.logic_strategy",
        "com.richnowai.panel.logic_risk",
        "com.richnowai.panel.logic_optimization",
        "com.richnowai.panel.action_plan",
        "com.richnowai.panel.action_execution",
        "com.richnowai.panel.action_review"
    ]
    
    // 面板套裝產品 ID
    private let bundleProductIDs = [
        "com.richnowai.panel.bundle.vision",
        "com.richnowai.panel.bundle.goal",
        "com.richnowai.panel.bundle.logic",
        "com.richnowai.panel.bundle.action",
        "com.richnowai.panel.bundle.all"
    ]
    
    private var updateListenerTask: Task<Void, Error>? = nil
    
    private init() {
        updateListenerTask = listenForTransactions()
        Task {
            await requestProducts()
            await updateCustomerProductStatus()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - 產品管理
    
    func requestProducts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let allProductIDs = panelProductIDs + bundleProductIDs
            let storeProducts = try await Product.products(for: allProductIDs)
            
            await MainActor.run {
                self.products = storeProducts
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load products: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    func updateCustomerProductStatus() async {
        let purchasedProductIDs: Set<String> = []
        
        // 簡化版本，暫時不檢查購買狀態
        // 在實際應用中，這裡應該檢查 Transaction.currentEntitlements
        
        await MainActor.run {
            self.purchasedProducts = purchasedProductIDs
        }
    }
    
    // MARK: - 購買功能
    
    func purchase(_ product: Product) async throws -> StoreKit.Transaction? {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updateCustomerProductStatus()
            await transaction.finish()
            return transaction
            
        case .userCancelled, .pending:
            return nil
            
        @unknown default:
            throw StoreError.unknown
        }
    }
    
    func restorePurchases() async throws {
        try await AppStore.sync()
        await updateCustomerProductStatus()
    }
    
    // MARK: - 產品查詢
    
    func getProduct(for panelType: VGLAPanelType) -> Product? {
        let productID = getProductID(for: panelType)
        return products.first { $0.id == productID }
    }
    
    func getBundleProducts(for dimension: VGLADimension) -> [Product] {
        let bundleID = getBundleID(for: dimension)
        return products.filter { $0.id == bundleID }
    }
    
    func isPurchased(_ panelType: VGLAPanelType) -> Bool {
        let productID = getProductID(for: panelType)
        return purchasedProducts.contains(productID)
    }
    
    func isBundlePurchased(_ dimension: VGLADimension) -> Bool {
        let bundleID = getBundleID(for: dimension)
        return purchasedProducts.contains(bundleID)
    }
    
    // MARK: - 私有方法
    
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            // 簡化的交易監聽實現
            // 在實際應用中，這裡應該使用正確的 StoreKit 2 API
            print("Transaction listener started")
        }
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    private func getProductID(for panelType: VGLAPanelType) -> String {
        switch panelType {
        case .vision_mission:
            return "com.richnowai.panel.vision_mission"
        case .vision_legacy:
            return "com.richnowai.panel.vision_legacy"
        case .vision_impact:
            return "com.richnowai.panel.vision_impact"
        case .goal_medium:
            return "com.richnowai.panel.goal_medium"
        case .goal_long:
            return "com.richnowai.panel.goal_long"
        case .goal_life:
            return "com.richnowai.panel.goal_life"
        case .logic_strategy:
            return "com.richnowai.panel.logic_strategy"
        case .logic_risk:
            return "com.richnowai.panel.logic_risk"
        case .logic_optimization:
            return "com.richnowai.panel.logic_optimization"
        case .action_plan:
            return "com.richnowai.panel.action_plan"
        case .action_execution:
            return "com.richnowai.panel.action_execution"
        case .action_review:
            return "com.richnowai.panel.action_review"
        default:
            return "" // 免費面板不需要產品 ID
        }
    }
    
    private func getBundleID(for dimension: VGLADimension) -> String {
        switch dimension {
        case .vision:
            return "com.richnowai.panel.bundle.vision"
        case .goal:
            return "com.richnowai.panel.bundle.goal"
        case .logic:
            return "com.richnowai.panel.bundle.logic"
        case .action:
            return "com.richnowai.panel.bundle.action"
        }
    }
}

// 商店錯誤類型
enum StoreError: Error, LocalizedError {
    case failedVerification
    case productUnavailable
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "Product verification failed"
        case .productUnavailable:
            return "Product is not available"
        case .unknown:
            return "Unknown error occurred"
        }
    }
}