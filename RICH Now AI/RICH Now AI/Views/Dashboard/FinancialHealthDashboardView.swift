//
//  FinancialHealthDashboardView.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import SwiftUI
import Charts


private func dimensionDisplayName(_ dimension: FinancialHealthDimension) -> String {
    LocalizationManager.shared.localizedString("financial_health.dimension.\(dimension.rawValue)")
}

private func dimensionDescription(_ dimension: FinancialHealthDimension) -> String {
    LocalizationManager.shared.localizedString("financial_health.dimension.\(dimension.rawValue).description")
}

private func dimensionColor(_ dimension: FinancialHealthDimension) -> Color {
    switch dimension {
    case .income: return .green
    case .expenses: return .orange
    case .savings: return .blue
    case .debt: return .red
    case .investment: return .purple
    case .protection: return .yellow
    }
}

private func levelDisplayName(_ level: FinancialHealthLevel) -> String {
    LocalizationManager.shared.localizedString("financial_health.level.\(level.rawValue)")
}

private func levelDescription(_ level: FinancialHealthLevel) -> String {
    LocalizationManager.shared.localizedString("financial_health.level.\(level.rawValue).description")
}

private func levelColor(_ level: FinancialHealthLevel) -> Color {
    switch level {
    case .excellent: return .green
    case .good: return .blue
    case .fair: return .yellow
    case .poor: return .orange
    case .critical: return .red
    }
}

struct FinancialHealthDashboardView: View {
    @StateObject private var healthManager = FinancialHealthManager.shared
    @Environment(\.modelContext) private var modelContext
    @State private var selectedDimension: FinancialHealthDimension? = nil
    @State private var showingDetail = false
    @State private var showingRecommendations = false
    @State private var showingDimensionGuide: FinancialHealthDimension? = nil
    @State private var showingScoringDetail = false
    @State private var hasInitialized = false
    @State private var showMainMenu = false
    
    var body: some View {
        NavigationBarContainer(
            title: LocalizationManager.shared.localizedString("dashboard.title"),
            showBackButton: false, // 首頁不需要返回按鈕
            showMenuButton: true,
            onMenu: {
                showMainMenu = true
            }
        ) {
            Group {
                if !hasInitialized {
                    // 快速載入畫面
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("準備中...")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            // 總體健康評分卡片
                            OverallHealthCard(score: healthManager.currentScore)
                                .onTapGesture {
                                    showingDetail = true
                                }
                            
                            // 六大維度評分
                            DimensionsOverviewCard(
                                dimensions: healthManager.currentScore.dimensions,
                                selectedDimension: $selectedDimension,
                                onDimensionTap: { dimension in
                                    showingDimensionGuide = dimension
                                }
                            )
                            
                            // 評分詳情按鈕
                            Button(action: {
                                showingScoringDetail = true
                            }) {
                                HStack {
                                    Image(systemName: "info.circle.fill")
                                    Text("查看評分詳情與調整方式")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        colors: [Color.blue, Color.blue.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                            }
                            .padding(.horizontal, 16)
                            
                            // 趨勢圖表 - 延遲載入
                            if !healthManager.historicalScores.isEmpty {
                                LazyView {
                                    TrendsChartCard(historicalScores: healthManager.historicalScores)
                                }
                            }
                            
                            // 改善建議 - 延遲載入
                            LazyView {
                                FinancialRecommendationsCard(
                                    recommendations: healthManager.currentScore.recommendations,
                                    onViewAll: { showingRecommendations = true }
                                )
                            }
                            
                            // 快速行動 - 延遲載入
                            LazyView {
                                QuickActionsCard()
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)
                    }
                    .refreshable {
                        await healthManager.refreshHealthScore()
                    }
                }
            }
            .sheet(isPresented: $showingDetail) {
                FinancialHealthDetailView(score: healthManager.currentScore)
            }
            .sheet(isPresented: $showingRecommendations) {
                FinancialHealthRecommendationsView(recommendations: healthManager.currentScore.recommendations)
            }
            .sheet(item: $showingDimensionGuide) { dimension in
                FinancialHealthDimensionGuideView(dimension: dimension) {
                    showingDimensionGuide = nil
                }
            }
            .sheet(isPresented: $showingScoringDetail) {
                FinancialHealthScoringDetailView()
            }
            .sheet(isPresented: $showMainMenu) {
                MainMenuView(isPresented: $showMainMenu)
            }
            .onAppear {
                if !hasInitialized {
                    healthManager.setModelContext(modelContext)
                    Task {
                        // 快速初始化，避免阻塞 UI
                        await MainActor.run {
                            hasInitialized = true
                        }
                        await healthManager.loadHealthData()
                    }
                }
            }
        }
    }
}

// 總體健康評分卡片
struct OverallHealthCard: View {
    let score: FinancialHealthScore
    
    var body: some View {
        VStack(spacing: 16) {
            // 評分圓環
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: CGFloat(score.overall) / 100)
                    .stroke(levelColor(score.level), lineWidth: 8)
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0), value: score.overall)
                
                VStack {
                    Text("\(score.overall)")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(levelColor(score.level))
                    
                    Text(LocalizationManager.shared.localizedString("financial_health.score"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // 健康等級
            VStack(spacing: 8) {
                Text(levelDisplayName(score.level))
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(levelColor(score.level))
                
                Text(levelDescription(score.level))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // 最後更新時間
            Text("\(LocalizationManager.shared.localizedString("financial_health.last_updated")): \(score.lastUpdated, formatter: dateFormatter)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
}

// 六大維度概覽卡片
struct DimensionsOverviewCard: View {
    let dimensions: [FinancialHealthDimension: Int]
    @Binding var selectedDimension: FinancialHealthDimension?
    var onDimensionTap: (FinancialHealthDimension) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizationManager.shared.localizedString("financial_health.dimensions.title"))
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(Array(FinancialHealthDimension.allCases), id: \.self) { dimension in
                    DimensionCard(
                        dimension: dimension,
                        score: dimensions[dimension] ?? 0,
                        isSelected: selectedDimension == dimension
                    ) {
                        onDimensionTap(dimension)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

// 維度卡片
struct DimensionCard: View {
    let dimension: FinancialHealthDimension
    let score: Int
    let isSelected: Bool
    let onTap: () -> Void
    
    var level: FinancialHealthLevel {
        FinancialHealthLevel.level(for: score)
    }
    
    var body: some View {
        Button {
            onTap()
        } label: {
            VStack(spacing: 12) {
                // 圖示和名稱
                HStack {
                    Image(systemName: dimension.icon)
                        .font(.title2)
                        .foregroundColor(dimensionColor(dimension))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(dimensionDisplayName(dimension))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Text(dimensionDescription(dimension))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                }
                
                // 評分
                HStack {
                    Text("\(score)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(levelColor(level))
                    
                    Spacer()
                    
                    Text(levelDisplayName(level))
                        .font(.caption)
                        .foregroundColor(levelColor(level))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(levelColor(level).opacity(0.1))
                        .cornerRadius(8)
                }
                
                // 進度條
                ProgressView(value: Double(score), total: 100)
                    .progressViewStyle(LinearProgressViewStyle(tint: levelColor(level)))
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? dimensionColor(dimension).opacity(0.1) : Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? dimensionColor(dimension) : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// 趨勢圖表卡片
struct TrendsChartCard: View {
    let historicalScores: [FinancialHealthScore]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizationManager.shared.localizedString("financial_health.trends.title"))
                .font(.headline)
                .fontWeight(.semibold)
            
            if #available(iOS 16.0, *) {
                Chart(historicalScores.prefix(12), id: \.lastUpdated) { score in
                    LineMark(
                        x: .value("Date", score.lastUpdated),
                        y: .value("Score", score.overall)
                    )
                    .foregroundStyle(.blue)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    
                    AreaMark(
                        x: .value("Date", score.lastUpdated),
                        y: .value("Score", score.overall)
                    )
                    .foregroundStyle(.blue.opacity(0.1))
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                        AxisValueLabel(format: .dateTime.month().day())
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .stride(by: 10)) { value in
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
            } else {
                // iOS 15 及以下版本的替代圖表
                SimpleTrendsView(scores: historicalScores)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

// 簡單趨勢視圖（iOS 15 兼容）
struct SimpleTrendsView: View {
    let scores: [FinancialHealthScore]
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 4) {
            ForEach(Array(scores.prefix(12).enumerated()), id: \.offset) { index, score in
                VStack {
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: 20, height: CGFloat(score.overall) * 2)
                        .cornerRadius(4)
                    
                    Text("\(index + 1)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(height: 200)
    }
}

// 建議卡片
struct FinancialRecommendationsCard: View {
    let recommendations: [String]
    let onViewAll: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(LocalizationManager.shared.localizedString("financial_health.recommendations.title"))
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button {
                    onViewAll()
                } label: {
                    Text(LocalizationManager.shared.localizedString("common.view_all"))
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
            
            if recommendations.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title)
                        .foregroundColor(.green)
                    
                    Text(LocalizationManager.shared.localizedString("financial_health.recommendations.none"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                VStack(spacing: 8) {
                    ForEach(recommendations.prefix(3), id: \.self) { recommendation in
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.orange)
                                .font(.caption)
                            
                            Text(LocalizationManager.shared.localizedString(recommendation))
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.orange.opacity(0.1))
                        )
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

// 快速行動卡片
struct QuickActionsCard: View {
    @StateObject private var tabController = TabController.shared
    @State private var showGoalSetting = false
    @State private var showFinancialPlan = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizationManager.shared.localizedString("financial_health.quick_actions.title"))
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                QuickActionButton(
                    title: LocalizationManager.shared.localizedString("financial_health.quick_actions.add_transaction"),
                    icon: "plus.circle.fill",
                    color: .blue
                ) {
                    // 切換到記帳 tab
                    tabController.switchToTab(TabController.Tab.transaction.rawValue)
                }
                
                QuickActionButton(
                    title: LocalizationManager.shared.localizedString("financial_health.quick_actions.set_goal"),
                    icon: "target",
                    color: .green
                ) {
                    // 顯示目標設定頁面
                    showGoalSetting = true
                }
                
                QuickActionButton(
                    title: LocalizationManager.shared.localizedString("financial_health.quick_actions.analyze"),
                    icon: "chart.bar.fill",
                    color: .orange
                ) {
                    // 切換到報表 tab
                    tabController.switchToTab(TabController.Tab.reports.rawValue)
                }
                
                QuickActionButton(
                    title: LocalizationManager.shared.localizedString("financial_health.quick_actions.plan"),
                    icon: "calendar",
                    color: .purple
                ) {
                    // 顯示財務規劃頁面
                    showFinancialPlan = true
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .sheet(isPresented: $showGoalSetting) {
            FinancialGoalSettingView()
        }
        .sheet(isPresented: $showFinancialPlan) {
            FinancialPlanningView()
        }
    }
}

// 快速行動按鈕
struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.1))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// 預覽
#Preview {
    FinancialHealthDashboardView()
}
