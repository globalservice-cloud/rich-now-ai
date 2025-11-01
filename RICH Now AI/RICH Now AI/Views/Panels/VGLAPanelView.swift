//
//  VGLAPanelView.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import SwiftUI

struct VGLAPanelView: View {
    let panel: VGLAPanel
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
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
                    if panel.isPurchased {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else if panel.isUnlocked {
                        Image(systemName: "lock.open.fill")
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
                
                // 價格資訊
                if !panel.isDefault && !panel.isPurchased {
                    HStack {
                        Text("$\(String(format: "%.2f", panel.purchasePrice))")
                            .font(.headline)
                            .foregroundColor(panel.type.primaryColor)
                        
                        Spacer()
                        
                        Text("purchase".localized)
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(panel.type.primaryColor)
                            .cornerRadius(12)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(panel.type.primaryColor.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? panel.type.primaryColor : Color.clear,
                                lineWidth: 2
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// VGLA 面板網格視圖
struct VGLAPanelGridView: View {
    let panels: [VGLAPanel]
    let selectedPanel: VGLAPanel?
    let onPanelTap: (VGLAPanel) -> Void
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(panels, id: \.id) { panel in
                VGLAPanelView(
                    panel: panel,
                    isSelected: selectedPanel?.id == panel.id,
                    onTap: { onPanelTap(panel) }
                )
            }
        }
        .padding(.horizontal, 16)
    }
}

// VGLA 面板詳細視圖
struct VGLAPanelDetailView: View {
    let panel: VGLAPanel
    @State private var showingPurchase = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 面板標題
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: panel.type.icon)
                            .font(.largeTitle)
                            .foregroundColor(panel.type.primaryColor)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(panel.name)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text(panel.type.dimension.displayName)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
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
                    Text("panel.features.title".localized)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 1), spacing: 8) {
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
                        Text("panel.tags.title".localized)
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
                
                // 購買按鈕
                if !panel.isDefault && !panel.isPurchased {
                    VStack(spacing: 16) {
                        HStack {
                            Text("panel.price".localized)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("$\(String(format: "%.2f", panel.purchasePrice))")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(panel.type.primaryColor)
                        }
                        
                        Button(action: { showingPurchase = true }) {
                            HStack {
                                Image(systemName: "cart.fill")
                                Text("panel.purchase.button".localized)
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(panel.type.primaryColor)
                            .cornerRadius(12)
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(panel.type.primaryColor.opacity(0.05))
                    )
                } else if panel.isPurchased {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        
                        Text("panel.purchased".localized)
                            .font(.headline)
                            .foregroundColor(.green)
                        
                        Spacer()
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.green.opacity(0.1))
                    )
                }
            }
            .padding(20)
        }
        .navigationTitle(panel.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingPurchase) {
            PanelPurchaseView(panel: panel)
        }
    }
}

// 面板購買視圖
struct PanelPurchaseView: View {
    let panel: VGLAPanel
    @Environment(\.dismiss) private var dismiss
    @StateObject private var panelManager = VGLAPanelManager.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // 面板資訊
                VStack(spacing: 16) {
                    Image(systemName: panel.type.icon)
                        .font(.system(size: 60))
                        .foregroundColor(panel.type.primaryColor)
                    
                    Text(panel.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text(panel.panelDescription)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(panel.type.primaryColor.opacity(0.1))
                )
                
                // 價格資訊
                VStack(spacing: 12) {
                    Text("panel.purchase.confirm".localized)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                    
                    Text("$\(String(format: "%.2f", panel.purchasePrice))")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(panel.type.primaryColor)
                }
                
                Spacer()
                
                // 購買按鈕
                VStack(spacing: 12) {
                    Button(action: purchasePanel) {
                        HStack {
                            Image(systemName: "cart.fill")
                            Text("panel.purchase.confirm.button".localized)
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(panel.type.primaryColor)
                        .cornerRadius(12)
                    }
                    
                    Button(action: { dismiss() }) {
                        Text("common.cancel".localized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(20)
            .navigationTitle("panel.purchase.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("common.close".localized) {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func purchasePanel() {
        // 這裡應該整合 StoreKit 購買流程
        panelManager.purchasePanel(panel)
        dismiss()
    }
}

// 預覽
#Preview {
    VGLAPanelView(
        panel: VGLAPanel(
            type: .vision_dream,
            name: "Dream Vision Panel",
            description: "Visualize your financial dreams and aspirations",
            isUnlocked: true,
            isPurchased: true
        ),
        isSelected: false,
        onTap: {}
    )
    .padding()
}
