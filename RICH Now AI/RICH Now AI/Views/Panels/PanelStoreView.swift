//
//  PanelStoreView.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import SwiftUI
import StoreKit

struct PanelStoreView: View {
    @StateObject private var storeManager = PanelStoreKitManager.shared
    @StateObject private var panelManager = VGLAPanelManager.shared
    @State private var selectedTab = 0
    @State private var showingPurchaseAlert = false
    @State private var purchaseAlertMessage = ""
    @State private var selectedProduct: Product?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 標題和搜尋
                VStack(spacing: 16) {
                    HStack {
                        Text(LocalizationManager.shared.localizedString("panel.store.title"))
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Button(action: restorePurchases) {
                            Image(systemName: "arrow.clockwise")
                                .font(.title2)
                        }
                    }
                    
                    // 標籤選擇器
                    Picker("Store Category", selection: $selectedTab) {
                        Text(LocalizationManager.shared.localizedString("panel.store.individual")).tag(0)
                        Text(LocalizationManager.shared.localizedString("panel.store.bundles")).tag(1)
                        Text(LocalizationManager.shared.localizedString("panel.store.recommended")).tag(2)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                // 內容視圖
                TabView(selection: $selectedTab) {
                    // 個別面板
                    IndividualPanelsView()
                        .tag(0)
                    
                    // 套裝面板
                    BundlePanelsView()
                        .tag(1)
                    
                    // 推薦面板
                    RecommendedPanelsView()
                        .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationBarHidden(true)
            .alert(LocalizationManager.shared.localizedString("panel.store.purchase.alert"), isPresented: $showingPurchaseAlert) {
                Button(LocalizationManager.shared.localizedString("common.ok")) { }
            } message: {
                Text(purchaseAlertMessage)
            }
        }
        .onAppear {
            Task {
                await storeManager.requestProducts()
            }
        }
    }
    
    private func restorePurchases() {
        Task {
            do {
                try await storeManager.restorePurchases()
                purchaseAlertMessage = LocalizationManager.shared.localizedString("panel.store.restore.success")
                showingPurchaseAlert = true
            } catch {
                purchaseAlertMessage = LocalizationManager.shared.localizedString("panel.store.restore.error")
                showingPurchaseAlert = true
            }
        }
    }
}

// 個別面板視圖
struct IndividualPanelsView: View {
    @StateObject private var storeManager = PanelStoreKitManager.shared
    @StateObject private var panelManager = VGLAPanelManager.shared
    @State private var selectedDimension: VGLADimension = .vision
    
    var panelsForDimension: [VGLAPanel] {
        panelManager.getPanelsByDimension(selectedDimension)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // 維度選擇器
            VGLADimensionSelector(selectedDimension: $selectedDimension)
                .padding(.horizontal, 16)
            
            // 面板網格
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                    ForEach(panelsForDimension, id: \.id) { panel in
                        PanelStoreCard(panel: panel)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
        }
    }
}

// 套裝面板視圖
struct BundlePanelsView: View {
    @StateObject private var storeManager = PanelStoreKitManager.shared
    
    var bundleProducts: [Product] {
        storeManager.products.filter { product in
            product.id.contains("bundle")
        }
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                ForEach(bundleProducts, id: \.id) { product in
                    BundleProductCard(product: product)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
    }
}

// 推薦面板視圖
struct RecommendedPanelsView: View {
    @StateObject private var storeManager = PanelStoreKitManager.shared
    @StateObject private var panelManager = VGLAPanelManager.shared
    
    var recommendedPanels: [VGLAPanel] {
        // 基於用戶的 VGLA 結果推薦面板
        panelManager.getDefaultPanels() + panelManager.availablePanels.filter { !$0.isDefault }.prefix(6)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 推薦標題
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(.orange)
                    
                    Text(LocalizationManager.shared.localizedString("panel.store.recommended.title"))
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                
                // 推薦面板網格
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                    ForEach(recommendedPanels, id: \.id) { panel in
                        PanelStoreCard(panel: panel)
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 20)
        }
    }
}

// 面板商店卡片
struct PanelStoreCard: View {
    let panel: VGLAPanel
    @StateObject private var storeManager = PanelStoreKitManager.shared
    @State private var isPurchasing = false
    @State private var showingDetail = false
    
    var product: Product? {
        storeManager.getProduct(for: panel.type)
    }
    
    var isPurchased: Bool {
        storeManager.isPurchased(panel.type)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 面板標題和圖示
            HStack {
                Image(systemName: panel.type.icon)
                    .font(.title2)
                    .foregroundColor(panel.type.primaryColor)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(panel.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    Text(panel.type.dimension.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // 狀態指示器
                if isPurchased {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else if panel.isDefault {
                    Image(systemName: "gift.fill")
                        .foregroundColor(.blue)
                } else {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.gray)
                }
            }
            
            // 面板描述
            Text(panel.panelDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(3)
            
            // 功能標籤
            if !panel.features.isEmpty {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 4) {
                    ForEach(panel.features.prefix(4), id: \.self) { feature in
                        Text(feature)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(panel.type.secondaryColor.opacity(0.2))
                            .foregroundColor(panel.type.primaryColor)
                            .cornerRadius(8)
                    }
                }
            }
            
            Spacer()
            
            // 價格和購買按鈕
            if isPurchased {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(LocalizationManager.shared.localizedString("panel.store.purchased"))
                        .font(.subheadline)
                        .foregroundColor(.green)
                    Spacer()
                }
            } else if panel.isDefault {
                HStack {
                    Image(systemName: "gift.fill")
                        .foregroundColor(.blue)
                    Text(LocalizationManager.shared.localizedString("panel.store.free"))
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    Spacer()
                }
            } else if let product = product {
                VStack(spacing: 8) {
                    HStack {
                        Text(product.displayPrice)
                            .font(.headline)
                            .foregroundColor(panel.type.primaryColor)
                        
                        Spacer()
                    }
                    
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
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(panel.type.primaryColor)
                        .cornerRadius(8)
                    }
                    .disabled(isPurchasing)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(panel.type.primaryColor.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(panel.type.primaryColor.opacity(0.2), lineWidth: 1)
                )
        )
        .onTapGesture {
            showingDetail = true
        }
        .sheet(isPresented: $showingDetail) {
            PanelDetailView(panel: panel)
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
                    }
                } else {
                    await MainActor.run {
                        isPurchasing = false
                    }
                }
            } catch {
                await MainActor.run {
                    isPurchasing = false
                }
            }
        }
    }
}

// 套裝產品卡片
struct BundleProductCard: View {
    let product: Product
    @StateObject private var storeManager = PanelStoreKitManager.shared
    @State private var isPurchasing = false
    
    var isPurchased: Bool {
        storeManager.purchasedProducts.contains(product.id)
    }
    
    var bundleInfo: (title: String, description: String, color: Color) {
        switch product.id {
        case "com.richnowai.panel.bundle.vision":
            return (
                title: LocalizationManager.shared.localizedString("panel.bundle.vision.title"),
                description: LocalizationManager.shared.localizedString("panel.bundle.vision.description"),
                color: Color.blue
            )
        case "com.richnowai.panel.bundle.goal":
            return (
                title: LocalizationManager.shared.localizedString("panel.bundle.goal.title"),
                description: LocalizationManager.shared.localizedString("panel.bundle.goal.description"),
                color: Color.green
            )
        case "com.richnowai.panel.bundle.logic":
            return (
                title: LocalizationManager.shared.localizedString("panel.bundle.logic.title"),
                description: LocalizationManager.shared.localizedString("panel.bundle.logic.description"),
                color: Color.orange
            )
        case "com.richnowai.panel.bundle.action":
            return (
                title: LocalizationManager.shared.localizedString("panel.bundle.action.title"),
                description: LocalizationManager.shared.localizedString("panel.bundle.action.description"),
                color: Color.purple
            )
        case "com.richnowai.panel.bundle.all":
            return (
                title: LocalizationManager.shared.localizedString("panel.bundle.all.title"),
                description: LocalizationManager.shared.localizedString("panel.bundle.all.description"),
                color: Color.red
            )
        default:
            return (
                title: "Bundle",
                description: "Panel Bundle",
                color: Color.gray
            )
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 套裝標題
            HStack {
                Image(systemName: "square.stack.3d.up.fill")
                    .font(.title)
                    .foregroundColor(bundleInfo.color)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(bundleInfo.title)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(LocalizationManager.shared.localizedString("panel.bundle.subtitle"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isPurchased {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                }
            }
            
            // 套裝描述
            Text(bundleInfo.description)
                .font(.body)
                .foregroundColor(.secondary)
            
            // 包含的面板
            VStack(alignment: .leading, spacing: 8) {
                Text(LocalizationManager.shared.localizedString("panel.bundle.includes"))
                    .font(.headline)
                    .fontWeight(.semibold)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                    ForEach(getIncludedPanels(), id: \.self) { panelName in
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(bundleInfo.color)
                            Text(panelName)
                                .font(.subheadline)
                        }
                    }
                }
            }
            
            // 價格和購買按鈕
            HStack {
                VStack(alignment: .leading) {
                    Text(product.displayPrice)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(bundleInfo.color)
                    
                    if let originalPrice = getOriginalPrice() {
                        Text(originalPrice)
                            .font(.subheadline)
                            .strikethrough()
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if isPurchased {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(LocalizationManager.shared.localizedString("panel.store.purchased"))
                            .font(.subheadline)
                            .foregroundColor(.green)
                    }
                } else {
                    Button(action: { purchaseBundle() }) {
                        HStack {
                            if isPurchasing {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "cart.fill")
                            }
                            Text(LocalizationManager.shared.localizedString("panel.store.purchase"))
                        }
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(bundleInfo.color)
                        .cornerRadius(12)
                    }
                    .disabled(isPurchasing)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(bundleInfo.color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(bundleInfo.color.opacity(0.3), lineWidth: 2)
                )
        )
    }
    
    private func getIncludedPanels() -> [String] {
        switch product.id {
        case "com.richnowai.panel.bundle.vision":
            return [
                LocalizationManager.shared.localizedString("vglapanel.vision_mission.name"),
                LocalizationManager.shared.localizedString("vglapanel.vision_legacy.name"),
                LocalizationManager.shared.localizedString("vglapanel.vision_impact.name")
            ]
        case "com.richnowai.panel.bundle.goal":
            return [
                LocalizationManager.shared.localizedString("vglapanel.goal_medium.name"),
                LocalizationManager.shared.localizedString("vglapanel.goal_long.name"),
                LocalizationManager.shared.localizedString("vglapanel.goal_life.name")
            ]
        case "com.richnowai.panel.bundle.logic":
            return [
                LocalizationManager.shared.localizedString("vglapanel.logic_strategy.name"),
                LocalizationManager.shared.localizedString("vglapanel.logic_risk.name"),
                LocalizationManager.shared.localizedString("vglapanel.logic_optimization.name")
            ]
        case "com.richnowai.panel.bundle.action":
            return [
                LocalizationManager.shared.localizedString("vglapanel.action_plan.name"),
                LocalizationManager.shared.localizedString("vglapanel.action_execution.name"),
                LocalizationManager.shared.localizedString("vglapanel.action_review.name")
            ]
        case "com.richnowai.panel.bundle.all":
            return [
                LocalizationManager.shared.localizedString("panel.bundle.all_panels")
            ]
        default:
            return []
        }
    }
    
    private func getOriginalPrice() -> String? {
        // 這裡可以返回原價（如果有折扣的話）
        return nil
    }
    
    private func purchaseBundle() {
        isPurchasing = true
        
        Task {
            do {
                let transaction = try await storeManager.purchase(product)
                if transaction != nil {
                    // 購買成功
                    await MainActor.run {
                        isPurchasing = false
                    }
                } else {
                    await MainActor.run {
                        isPurchasing = false
                    }
                }
            } catch {
                await MainActor.run {
                    isPurchasing = false
                }
            }
        }
    }
}

// 預覽
#Preview {
    PanelStoreView()
}
