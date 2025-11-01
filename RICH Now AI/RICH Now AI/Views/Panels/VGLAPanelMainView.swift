//
//  VGLAPanelMainView.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import SwiftUI

struct VGLAPanelMainView: View {
    @StateObject private var panelManager = VGLAPanelManager.shared
    @State private var selectedTab = 0
    @State private var showMainMenu = false
    
    var body: some View {
        NavigationBarContainer(
            title: LocalizationManager.shared.localizedString("panels.title"),
            showBackButton: true,
            showMenuButton: true,
            onBack: {
                // 返回主頁的邏輯
            },
            onMenu: {
                showMainMenu = true
            }
        ) {
            TabView(selection: $selectedTab) {
                // 我的面板
                MyVGLAPanelsView()
                    .tabItem {
                        Image(systemName: "square.grid.2x2")
                        Text("panel.my_panels.title".localized)
                    }
                    .tag(0)
                
                // 面板商店
                VGLAPanelStoreView()
                    .tabItem {
                        Image(systemName: "storefront")
                        Text("panel.store.title".localized)
                    }
                    .tag(1)
                
                // 面板統計
                VGLAPanelStatsView()
                    .tabItem {
                        Image(systemName: "chart.bar")
                        Text("panel.stats.title".localized)
                    }
                    .tag(2)
            }
            .onAppear {
                panelManager.loadPanels()
            }
            .sheet(isPresented: $showMainMenu) {
                MainMenuView(isPresented: $showMainMenu)
            }
        }
    }
}

// VGLA 面板推薦視圖
struct VGLAPanelRecommendationView: View {
    @StateObject private var panelManager = VGLAPanelManager.shared
    let userVGLAProfile: VGLAProfile?
    
    var recommendedPanels: [VGLAPanel] {
        guard
            let profile = userVGLAProfile,
            let latestScore = latestScore(from: profile)
        else {
            return panelManager.getDefaultPanels()
        }
        
        let primaryDimension = primaryDimension(from: latestScore)
        return panelManager.getPanelsByDimension(primaryDimension)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 推薦標題
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.orange)
                
                Text("panel.recommendation.title".localized)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            // 推薦說明
            Text("panel.recommendation.description".localized)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // 推薦面板
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(recommendedPanels.prefix(3), id: \.id) { panel in
                        VGLAPanelCard(panel: panel)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.orange.opacity(0.1))
        )
    }
    
    private func latestScore(from profile: VGLAProfile) -> VGLAScore? {
        guard let record = profile.historyRecords.sorted(by: { $0.testDate > $1.testDate }).first else {
            return nil
        }
        
        return try? JSONDecoder().decode(VGLAScore.self, from: record.scoreData)
    }
    
    private func primaryDimension(from score: VGLAScore) -> VGLADimension {
        let vScore = score.total["V"] ?? 0
        let gScore = score.total["G"] ?? 0
        let lScore = score.total["L"] ?? 0
        let aScore = score.total["A"] ?? 0
        
        let maxScore = max(vScore, gScore, lScore, aScore)
        
        if vScore == maxScore { return .vision }
        if gScore == maxScore { return .goal }
        if lScore == maxScore { return .logic }
        return .action
    }
}

// VGLA 面板卡片
struct VGLAPanelCard: View {
    let panel: VGLAPanel
    @State private var showingDetail = false
    
    var body: some View {
        Button(action: { showingDetail = true }) {
            VStack(alignment: .leading, spacing: 12) {
                // 面板圖示和標題
                HStack {
                    Image(systemName: panel.type.icon)
                        .font(.title2)
                        .foregroundColor(panel.type.primaryColor)
                    
                    Spacer()
                    
                    if panel.isPurchased {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(panel.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    Text(panel.type.dimension.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(panel.panelDescription)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                
                Spacer()
                
                // 價格或狀態
                if panel.isPurchased {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("panel.purchased".localized)
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                } else if !panel.isDefault {
                    Text("$\(String(format: "%.2f", panel.purchasePrice))")
                        .font(.headline)
                        .foregroundColor(panel.type.primaryColor)
                }
            }
            .padding(16)
            .frame(width: 200, height: 180)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(panel.type.primaryColor.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(panel.type.primaryColor.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingDetail) {
            VGLAPanelDetailView(panel: panel)
        }
    }
}

// VGLA 面板快速操作
struct VGLAPanelQuickActions: View {
    @StateObject private var panelManager = VGLAPanelManager.shared
    
    var body: some View {
        VStack(spacing: 12) {
            // 快速操作標題
            HStack {
                Text("panel.quick_actions.title".localized)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            // 操作按鈕
            HStack(spacing: 12) {
                QuickActionButton(
                    title: "panel.quick_actions.browse".localized,
                    icon: "storefront",
                    color: .blue
                ) {
                    // 導航到商店
                }
                
                QuickActionButton(
                    title: "panel.quick_actions.my_panels".localized,
                    icon: "square.grid.2x2",
                    color: .green
                ) {
                    // 導航到我的面板
                }
                
                QuickActionButton(
                    title: "panel.quick_actions.stats".localized,
                    icon: "chart.bar",
                    color: .orange
                ) {
                    // 導航到統計
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
    }
}

// QuickActionButton 已移至 FinancialHealthDashboardView.swift

// 預覽
#Preview {
    VGLAPanelMainView()
}
