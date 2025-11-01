//
//  SubscriptionTestView.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import SwiftUI
import StoreKit

struct SubscriptionTestView: View {
    @StateObject private var storeKitManager = StoreKitManager.shared
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var testResults: [TestResult] = []
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 訂閱狀態顯示
                    subscriptionStatusSection
                    
                    // 產品列表
                    productsSection
                    
                    // 測試按鈕
                    testButtonsSection
                    
                    // 測試結果
                    testResultsSection
                    
                    // 錯誤訊息
                    if let error = errorMessage {
                        errorSection(error: error)
                    }
                }
                .padding()
            }
            .navigationTitle("Subscription Test")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadProducts()
            }
        }
    }
    
    // MARK: - 訂閱狀態顯示
    
    private var subscriptionStatusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("當前訂閱狀態")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("方案:")
                        .fontWeight(.medium)
                    Spacer()
                    Text(storeKitManager.currentSubscription.displayName)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                
                HStack {
                    Text("狀態:")
                        .fontWeight(.medium)
                    Spacer()
                    Text(storeKitManager.subscriptionStatus.rawValue)
                        .fontWeight(.bold)
                        .foregroundColor(storeKitManager.subscriptionStatus == .active ? .green : .red)
                }
                
                if let expiryDate = storeKitManager.getSubscriptionExpiryDate() {
                    HStack {
                        Text("到期日:")
                            .fontWeight(.medium)
                        Spacer()
                        Text(expiryDate, style: .date)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                    }
                }
                
                if storeKitManager.isSubscriptionExpiringSoon() {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("訂閱即將過期")
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - 產品列表
    
    private var productsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("可用產品")
                .font(.headline)
                .foregroundColor(.primary)
            
            if storeKitManager.isLoading {
                ProgressView("載入產品中...")
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if storeKitManager.products.isEmpty {
                Text("沒有可用的產品")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(storeKitManager.products, id: \.plan.rawValue) { product in
                        productRow(product: product)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func productRow(product: SubscriptionProduct) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(product.plan.displayName)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if product.isPopular {
                    Text("熱門")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange)
                        .cornerRadius(4)
                }
            }
            
            Text(product.plan.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                Text(product.plan.price)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                
                Spacer()
                
                Button("購買") {
                    purchaseProduct(product)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isLoading)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - 測試按鈕
    
    private var testButtonsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("測試功能")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                Button("載入產品") {
                    loadProducts()
                }
                .buttonStyle(.bordered)
                .disabled(isLoading)
                
                Button("恢復購買") {
                    restorePurchases()
                }
                .buttonStyle(.bordered)
                .disabled(isLoading)
                
                Button("更新狀態") {
                    updateSubscriptionStatus()
                }
                .buttonStyle(.bordered)
                .disabled(isLoading)
                
                Button("取消訂閱") {
                    cancelSubscription()
                }
                .buttonStyle(.bordered)
                .disabled(isLoading)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - 測試結果
    
    private var testResultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("測試結果")
                .font(.headline)
                .foregroundColor(.primary)
            
            if testResults.isEmpty {
                Text("尚未進行測試")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(testResults, id: \.id) { result in
                        testResultRow(result: result)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func testResultRow(result: TestResult) -> some View {
        HStack {
            Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(result.success ? .green : .red)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(result.testName)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(result.message)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(result.timestamp, style: .time)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
    
    // MARK: - 錯誤訊息
    
    private func errorSection(error: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("錯誤訊息")
                .font(.headline)
                .foregroundColor(.red)
            
            Text(error)
                .font(.body)
                .foregroundColor(.red)
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - 測試方法
    
    private func loadProducts() {
        isLoading = true
        errorMessage = nil
        
        Task {
            await storeKitManager.loadProducts()
            await MainActor.run {
                self.isLoading = false
                if let error = storeKitManager.errorMessage {
                    self.errorMessage = error
                } else {
                    self.addTestResult("載入產品", success: true, message: "成功載入 \(storeKitManager.products.count) 個產品")
                }
            }
        }
    }
    
    private func purchaseProduct(_ product: SubscriptionProduct) {
        isLoading = true
        errorMessage = nil
        
        Task {
            let success = await storeKitManager.purchase(product)
            await MainActor.run {
                self.isLoading = false
                if success {
                    self.addTestResult("購買產品", success: true, message: "成功購買 \(product.plan.displayName)")
                } else {
                    self.addTestResult("購買產品", success: false, message: "購買失敗")
                }
            }
        }
    }
    
    private func restorePurchases() {
        isLoading = true
        errorMessage = nil
        
        Task {
            let success = await storeKitManager.restorePurchases()
            await MainActor.run {
                self.isLoading = false
                if success {
                    self.addTestResult("恢復購買", success: true, message: "成功恢復購買")
                } else {
                    self.addTestResult("恢復購買", success: false, message: "恢復購買失敗")
                }
            }
        }
    }
    
    private func updateSubscriptionStatus() {
        isLoading = true
        errorMessage = nil
        
        Task {
            await storeKitManager.updateSubscriptionStatus()
            await MainActor.run {
                self.isLoading = false
                self.addTestResult("更新狀態", success: true, message: "訂閱狀態已更新")
            }
        }
    }
    
    private func cancelSubscription() {
        isLoading = true
        errorMessage = nil
        
        Task {
            let success = await storeKitManager.cancelSubscription()
            await MainActor.run {
                self.isLoading = false
                if success {
                    self.addTestResult("取消訂閱", success: true, message: "已開啟訂閱管理頁面")
                } else {
                    self.addTestResult("取消訂閱", success: false, message: "無法開啟訂閱管理頁面")
                }
            }
        }
    }
    
    private func addTestResult(_ testName: String, success: Bool, message: String) {
        let result = TestResult(
            testName: testName,
            success: success,
            message: message,
            timestamp: Date()
        )
        testResults.insert(result, at: 0)
        
        // 限制結果數量
        if testResults.count > 20 {
            testResults = Array(testResults.prefix(20))
        }
    }
}

// MARK: - 測試結果結構

struct TestResult {
    let id = UUID()
    let testName: String
    let success: Bool
    let message: String
    let timestamp: Date
}

// MARK: - 預覽

#Preview {
    SubscriptionTestView()
}
