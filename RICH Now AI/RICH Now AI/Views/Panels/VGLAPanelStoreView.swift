//
//  VGLAPanelStoreView.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import SwiftUI

struct VGLAPanelStoreView: View {
    var body: some View {
        PanelStoreView()
    }
}

// SearchBar 已移至 PortfolioHoldingsView.swift

// VGLA 維度選擇器
struct VGLADimensionSelector: View {
    @Binding var selectedDimension: VGLADimension
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(VGLADimension.allCases, id: \.self) { dimension in
                    VGLADimensionButton(
                        dimension: dimension,
                        isSelected: selectedDimension == dimension,
                        onTap: { selectedDimension = dimension }
                    )
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

// VGLA 維度按鈕
struct VGLADimensionButton: View {
    let dimension: VGLADimension
    let isSelected: Bool
    let onTap: () -> Void
    
    private var panelType: VGLAPanelType {
        switch dimension {
        case .vision: return .vision_dream
        case .goal: return .goal_short
        case .logic: return .logic_analysis
        case .action: return .action_immediate
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: panelType.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : panelType.primaryColor)
                
                Text(dimension.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? panelType.primaryColor : Color(.systemGray6))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// VGLA 維度說明
struct VGLADimensionDescription: View {
    let dimension: VGLADimension
    
    private var panelType: VGLAPanelType {
        switch dimension {
        case .vision: return .vision_dream
        case .goal: return .goal_short
        case .logic: return .logic_analysis
        case .action: return .action_immediate
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: panelType.icon)
                .font(.title)
                .foregroundColor(panelType.primaryColor)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(dimension.displayName)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(dimension.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(panelType.primaryColor.opacity(0.1))
        )
    }
}

// 我的面板視圖
struct MyVGLAPanelsView: View {
    @StateObject private var panelManager = VGLAPanelManager.shared
    @State private var selectedPanel: VGLAPanel?
    @State private var showingPanelDetail = false
    
    var myPanels: [VGLAPanel] {
        panelManager.getPurchasedPanels()
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                    ForEach(myPanels, id: \.id) { panel in
                        VGLAPanelView(
                            panel: panel,
                            isSelected: selectedPanel?.id == panel.id,
                            onTap: {
                                selectedPanel = panel
                                showingPanelDetail = true
                            }
                        )
                    }
                }
                .padding(16)
            }
            .navigationTitle("panel.my_panels.title".localized)
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingPanelDetail) {
                if let panel = selectedPanel {
                    VGLAPanelDetailView(panel: panel)
                }
            }
        }
    }
}

// 面板統計視圖
struct VGLAPanelStatsView: View {
    @StateObject private var panelManager = VGLAPanelManager.shared
    
    var stats: (total: Int, purchased: Int, default: Int, premium: Int) {
        let allPanels = panelManager.availablePanels
        let purchased = allPanels.filter { $0.isPurchased }
        let defaultPanels = allPanels.filter { $0.isDefault }
        let premiumPanels = allPanels.filter { !$0.isDefault }
        
        return (
            total: allPanels.count,
            purchased: purchased.count,
            default: defaultPanels.count,
            premium: premiumPanels.count
        )
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // 總體統計
            HStack {
                StatCard(
                    title: "panel.stats.total".localized,
                    value: "\(stats.total)",
                    icon: "square.grid.3x3",
                    color: .blue
                )
                
                StatCard(
                    title: "panel.stats.purchased".localized,
                    value: "\(stats.purchased)",
                    icon: "checkmark.circle",
                    color: .green
                )
            }
            
            HStack {
                StatCard(
                    title: "panel.stats.default".localized,
                    value: "\(stats.default)",
                    icon: "star",
                    color: .orange
                )
                
                StatCard(
                    title: "panel.stats.premium".localized,
                    value: "\(stats.premium)",
                    icon: "crown",
                    color: .purple
                )
            }
        }
        .padding(16)
    }
}

// StatCard 已移至 APIKeySettingsView.swift

// 預覽
#Preview {
    VGLAPanelStoreView()
}
