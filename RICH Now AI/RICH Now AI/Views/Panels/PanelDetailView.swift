//
//  PanelDetailView.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import SwiftUI
import StoreKit

struct PanelDetailView: View {
    let panel: VGLAPanel
    @StateObject private var storeManager = PanelStoreKitManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var isPurchasing = false
    @State private var showingPurchaseAlert = false
    @State private var purchaseAlertMessage = ""
    
    var product: Product? {
        storeManager.getProduct(for: panel.type)
    }
    
    var isPurchased: Bool {
        storeManager.isPurchased(panel.type)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // 面板標題和圖示
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: panel.type.icon)
                                .font(.system(size: 60))
                                .foregroundColor(panel.type.primaryColor)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text(panel.name)
                                    .font(.title)
                                    .fontWeight(.bold)
                                
                                Text(panel.type.dimension.displayName)
                                    .font(.headline)
                                    .foregroundColor(panel.type.primaryColor)
                                
                                if isPurchased {
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                        Text(LocalizationManager.shared.localizedString("panel.store.purchased"))
                                            .font(.subheadline)
                                            .foregroundColor(.green)
                                    }
                                } else if panel.isDefault {
                                    HStack {
                                        Image(systemName: "gift.fill")
                                            .foregroundColor(.blue)
                                        Text(LocalizationManager.shared.localizedString("panel.store.free"))
                                            .font(.subheadline)
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                            
                            Spacer()
                        }
                        
                        Text(panel.panelDescription)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(panel.type.primaryColor.opacity(0.1))
                    )
                    
                    // 功能特色
                    VStack(alignment: .leading, spacing: 16) {
                        Text(LocalizationManager.shared.localizedString("panel.features.title"))
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 1), spacing: 12) {
                            ForEach(panel.features, id: \.self) { feature in
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(panel.type.primaryColor)
                                    
                                    Text(feature)
                                        .font(.subheadline)
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(panel.type.primaryColor.opacity(0.05))
                                )
                            }
                        }
                    }
                    
                    // 標籤
                    if !panel.tags.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(LocalizationManager.shared.localizedString("panel.tags.title"))
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                                ForEach(panel.tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(panel.type.secondaryColor.opacity(0.2))
                                        .foregroundColor(panel.type.primaryColor)
                                        .cornerRadius(16)
                                }
                            }
                        }
                    }
                    
                    // 維度說明
                    VStack(alignment: .leading, spacing: 12) {
                        Text(LocalizationManager.shared.localizedString("panel.dimension.title"))
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        HStack {
                            Image(systemName: panel.type.icon)
                                .foregroundColor(panel.type.primaryColor)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(panel.type.dimension.displayName)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Text(panel.type.dimension.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(panel.type.primaryColor.opacity(0.1))
                        )
                    }
                    
                    // 購買區域
                    if !isPurchased && !panel.isDefault {
                        VStack(spacing: 16) {
                            // 價格資訊
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    if let product = product {
                                        Text(product.displayPrice)
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(panel.type.primaryColor)
                                        
                                        Text(LocalizationManager.shared.localizedString("panel.price.one_time"))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text(LocalizationManager.shared.localizedString("panel.value"))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Text(LocalizationManager.shared.localizedString("panel.value.description"))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.trailing)
                                }
                            }
                            
                            // 購買按鈕
                            Button(action: { purchasePanel() }) {
                                HStack {
                                    if isPurchasing {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "cart.fill")
                                    }
                                    Text(LocalizationManager.shared.localizedString("panel.store.purchase"))
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(panel.type.primaryColor)
                                .cornerRadius(12)
                            }
                            .disabled(isPurchasing)
                            
                            // 購買說明
                            VStack(spacing: 8) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.caption)
                                    Text(LocalizationManager.shared.localizedString("panel.purchase.benefits.1"))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.caption)
                                    Text(LocalizationManager.shared.localizedString("panel.purchase.benefits.2"))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.caption)
                                    Text(LocalizationManager.shared.localizedString("panel.purchase.benefits.3"))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(panel.type.primaryColor.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(panel.type.primaryColor.opacity(0.2), lineWidth: 1)
                                )
                        )
                    } else if isPurchased {
                        // 已購買狀態
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.title2)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(LocalizationManager.shared.localizedString("panel.store.purchased"))
                                        .font(.headline)
                                        .foregroundColor(.green)
                                    
                                    Text(LocalizationManager.shared.localizedString("panel.purchased.description"))
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                            
                            Button(action: { 
                                // 導航到面板使用頁面
                            }) {
                                HStack {
                                    Image(systemName: "play.fill")
                                    Text(LocalizationManager.shared.localizedString("panel.use_now"))
                                }
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(panel.type.primaryColor)
                                .cornerRadius(8)
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.green.opacity(0.1))
                        )
                    } else if panel.isDefault {
                        // 免費面板狀態
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "gift.fill")
                                    .foregroundColor(.blue)
                                    .font(.title2)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(LocalizationManager.shared.localizedString("panel.store.free"))
                                        .font(.headline)
                                        .foregroundColor(.blue)
                                    
                                    Text(LocalizationManager.shared.localizedString("panel.free.description"))
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                            
                            Button(action: { 
                                // 導航到面板使用頁面
                            }) {
                                HStack {
                                    Image(systemName: "play.fill")
                                    Text(LocalizationManager.shared.localizedString("panel.use_now"))
                                }
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(panel.type.primaryColor)
                                .cornerRadius(8)
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.blue.opacity(0.1))
                        )
                    }
                }
                .padding(20)
            }
            .navigationTitle(panel.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizationManager.shared.localizedString("common.close")) {
                        dismiss()
                    }
                }
            }
            .alert(LocalizationManager.shared.localizedString("panel.store.purchase.alert"), isPresented: $showingPurchaseAlert) {
                Button(LocalizationManager.shared.localizedString("common.ok")) { }
            } message: {
                Text(purchaseAlertMessage)
            }
        }
    }
    
    private func purchasePanel() {
        guard let product = product else { return }
        
        isPurchasing = true
        
        Task {
            do {
                let transaction = try await storeManager.purchase(product)
                if transaction != nil {
                    // 購買成功
                    await MainActor.run {
                        isPurchasing = false
                        purchaseAlertMessage = LocalizationManager.shared.localizedString("panel.store.purchase.success")
                        showingPurchaseAlert = true
                    }
                } else {
                    await MainActor.run {
                        isPurchasing = false
                    }
                }
            } catch {
                await MainActor.run {
                    isPurchasing = false
                    purchaseAlertMessage = LocalizationManager.shared.localizedString("panel.store.purchase.error")
                    showingPurchaseAlert = true
                }
            }
        }
    }
}

// 預覽
#Preview {
    PanelDetailView(panel: VGLAPanel(
        type: .vision_mission,
        name: "Mission Vision Panel",
        description: "Define your financial mission and purpose",
        isUnlocked: false,
        isPurchased: false,
        purchasePrice: 2.99,
        currency: "USD",
        category: "vision",
        tags: ["mission", "purpose", "values"],
        features: ["Mission statement", "Value alignment", "Purpose tracking"],
        isDefault: false,
        sortOrder: 2
    ))
}
