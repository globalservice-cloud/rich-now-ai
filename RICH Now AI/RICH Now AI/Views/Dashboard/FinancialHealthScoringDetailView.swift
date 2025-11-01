//
//  FinancialHealthScoringDetailView.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/29.
//

import SwiftUI
import SwiftData

// 輔助函數（與 FinancialHealthDashboardView 共用）
private func dimensionDisplayName(_ dimension: FinancialHealthDimension) -> String {
    LocalizationManager.shared.localizedString("financial_health.dimension.\(dimension.rawValue)")
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

private func levelColor(_ level: FinancialHealthLevel) -> Color {
    switch level {
    case .excellent: return .green
    case .good: return .blue
    case .fair: return .yellow
    case .poor: return .orange
    case .critical: return .red
    }
}

// 財務健康評分詳情視圖（顯示評分方式和可調整分數）
struct FinancialHealthScoringDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]
    @StateObject private var healthManager = FinancialHealthManager.shared
    
    @State private var dimensionScores: [FinancialHealthDimension: Int] = [:]
    @State private var scoreOverrides: [FinancialHealthDimension: Int?] = [:]
    @State private var showingEditSheet: FinancialHealthDimension? = nil
    @State private var editingScore: Int = 0
    @State private var showingResetAlert = false
    
    var body: some View {
        NavigationView {
            Group {
                if healthManager.isLoading || dimensionScores.isEmpty {
                    // 載入狀態
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("正在載入評分數據...")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("如果長時間無響應，請確保已添加交易記錄")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // 總體評分卡片
                            OverallScoreCard(overallScore: calculateOverallScore())
                            
                            // 六大維度評分詳情
                            ForEach(FinancialHealthDimension.allCases, id: \.self) { dimension in
                                DimensionScoringCard(
                                    dimension: dimension,
                                    currentScore: getEffectiveScore(for: dimension),
                                    calculatedScore: dimensionScores[dimension] ?? 0,
                                    hasOverride: scoreOverrides[dimension] != nil,
                                    scoringMethod: getScoringMethod(for: dimension),
                                    metrics: healthManager.currentMetrics,
                                    onEdit: {
                                        editingScore = getEffectiveScore(for: dimension)
                                        showingEditSheet = dimension
                                    },
                                    onReset: {
                                        scoreOverrides[dimension] = nil
                                        saveScoreOverrides()
                                    }
                                )
                            }
                    
                            // 重置按鈕
                            Button(action: {
                                showingResetAlert = true
                            }) {
                                HStack {
                                    Image(systemName: "arrow.counterclockwise")
                                    Text("重置所有手動調整")
                                }
                                .font(.subheadline)
                                .foregroundColor(.red)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(12)
                            }
                            .padding(.horizontal)
                        }
                        .padding()
                    }
                    .refreshable {
                        await healthManager.refreshHealthScore()
                        loadScores()
                    }
                }
            }
            .navigationTitle("評分詳情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            await healthManager.refreshHealthScore()
                            loadScores()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .onAppear {
                // 確保 modelContext 已設置
                healthManager.setModelContext(modelContext)
                // 延遲一下確保數據載入完成
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    loadScores()
                }
            }
            .onChange(of: healthManager.currentScore.dimensions) { _, newDimensions in
                if !newDimensions.isEmpty {
                    dimensionScores = newDimensions
                }
            }
            .sheet(item: Binding(
                get: { showingEditSheet },
                set: { showingEditSheet = $0 }
            )) { dimension in
                ScoreEditSheet(
                    dimension: dimension,
                    currentScore: editingScore,
                    calculatedScore: dimensionScores[dimension] ?? 0,
                    onSave: { newScore in
                        scoreOverrides[dimension] = newScore
                        saveScoreOverrides()
                        refreshScores()
                    },
                    onCancel: {
                        showingEditSheet = nil
                    }
                )
            }
            .alert("重置所有手動調整", isPresented: $showingResetAlert) {
                Button("確定", role: .destructive) {
                    resetAllOverrides()
                }
                Button("取消", role: .cancel) { }
            } message: {
                Text("此操作將清除所有手動調整的分數，恢復為系統自動計算的分數。")
            }
        }
    }
    
    private func loadScores() {
        // 確保 healthManager 已經初始化
        if healthManager.currentScore.dimensions.isEmpty {
            // 如果還沒有數據，嘗試刷新
            Task {
                await healthManager.refreshHealthScore()
                await MainActor.run {
                    dimensionScores = healthManager.currentScore.dimensions
                    loadScoreOverrides()
                }
            }
        } else {
            dimensionScores = healthManager.currentScore.dimensions
            loadScoreOverrides()
        }
    }
    
    private func loadScoreOverrides() {
        guard !users.isEmpty else { return }
        
        // 從 User 模型讀取覆蓋分數（需要先添加這個功能到 User 模型）
        // 暫時使用 UserDefaults
        for dimension in FinancialHealthDimension.allCases {
            let key = "scoreOverride_\(dimension.rawValue)"
            if let overrideValue = UserDefaults.standard.object(forKey: key) as? Int {
                scoreOverrides[dimension] = overrideValue
            } else {
                scoreOverrides[dimension] = nil
            }
        }
    }
    
    private func saveScoreOverrides() {
        guard !users.isEmpty else { return }
        
        // 保存到 UserDefaults（之後可以移到 User 模型）
        for (dimension, overrideValue) in scoreOverrides {
            let key = "scoreOverride_\(dimension.rawValue)"
            if let value = overrideValue {
                UserDefaults.standard.set(value, forKey: key)
            } else {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
        
        // 刷新健康評分
        refreshScores()
    }
    
    private func resetAllOverrides() {
        for dimension in FinancialHealthDimension.allCases {
            scoreOverrides[dimension] = nil
            UserDefaults.standard.removeObject(forKey: "scoreOverride_\(dimension.rawValue)")
        }
        saveScoreOverrides()
        refreshScores()
    }
    
    private func getEffectiveScore(for dimension: FinancialHealthDimension) -> Int {
        if let overrideValue = scoreOverrides[dimension], let value = overrideValue {
            return value
        }
        return dimensionScores[dimension] ?? 0
    }
    
    private func calculateOverallScore() -> Int {
        let scores = FinancialHealthDimension.allCases.map { getEffectiveScore(for: $0) }
        return scores.reduce(0, +) / scores.count
    }
    
    private func refreshScores() {
        Task {
            await healthManager.refreshHealthScore()
            await MainActor.run {
                dimensionScores = healthManager.currentScore.dimensions
                loadScoreOverrides()
            }
        }
    }
    
    private func getScoringMethod(for dimension: FinancialHealthDimension) -> ScoringMethod {
        let metrics = healthManager.currentMetrics
        
        switch dimension {
        case .income:
            return ScoringMethod(
                dimension: dimension,
                baseScore: 50,
                factors: [
                    ScoringFactor(
                        name: "收入穩定性",
                        weight: 30,
                        currentValue: metrics.incomeStability,
                        targetValue: 1.0,
                        description: "計算過去12個月的收入波動程度，穩定性 = 1 - (標準差 / 平均值)",
                        formula: "穩定度 × 30分"
                    ),
                    ScoringFactor(
                        name: "收入成長率",
                        weight: 20,
                        currentValue: metrics.incomeGrowth,
                        targetValue: 0.05,
                        description: "最近6個月收入與前6個月的成長率",
                        formula: "成長率 > 5%: +20分\n成長率 > 0%: +10分"
                    )
                ]
            )
            
        case .expenses:
            return ScoringMethod(
                dimension: dimension,
                baseScore: 50,
                factors: [
                    ScoringFactor(
                        name: "支出收入比",
                        weight: 40,
                        currentValue: metrics.expenseRatio,
                        targetValue: 0.5,
                        description: "月支出占月收入的比例",
                        formula: "≤50%: +40分\n≤70%: +20分\n≤90%: +10分"
                    ),
                    ScoringFactor(
                        name: "支出成長控制",
                        weight: 10,
                        currentValue: metrics.expenseGrowth,
                        targetValue: 0.03,
                        description: "支出成長率應控制在3%以內",
                        formula: "≤3%: +10分"
                    )
                ]
            )
            
        case .savings:
            return ScoringMethod(
                dimension: dimension,
                baseScore: 50,
                factors: [
                    ScoringFactor(
                        name: "儲蓄率",
                        weight: 30,
                        currentValue: metrics.savingsRate,
                        targetValue: 0.2,
                        description: "月儲蓄金額占月收入的比例",
                        formula: "≥20%: +30分\n≥10%: +20分\n≥5%: +10分"
                    ),
                    ScoringFactor(
                        name: "緊急基金",
                        weight: 20,
                        currentValue: metrics.monthlyExpenses > 0 ? metrics.emergencyFund / metrics.monthlyExpenses : 0,
                        targetValue: 6.0,
                        description: "緊急基金可支撐的月數",
                        formula: "≥6個月: +20分\n≥3個月: +10分"
                    )
                ]
            )
            
        case .debt:
            return ScoringMethod(
                dimension: dimension,
                baseScore: 50,
                factors: [
                    ScoringFactor(
                        name: "債務收入比",
                        weight: 30,
                        currentValue: metrics.debtToIncomeRatio,
                        targetValue: 0.2,
                        description: "總債務占年收入的比例",
                        formula: "≤20%: +30分\n≤40%: +20分\n≤60%: +10分"
                    ),
                    ScoringFactor(
                        name: "債務償還比率",
                        weight: 20,
                        currentValue: metrics.debtServiceRatio,
                        targetValue: 0.1,
                        description: "月債務償還金額占月收入的比例",
                        formula: "≤10%: +20分\n≤20%: +10分"
                    )
                ]
            )
            
        case .investment:
            return ScoringMethod(
                dimension: dimension,
                baseScore: 50,
                factors: [
                    ScoringFactor(
                        name: "投資報酬率",
                        weight: 30,
                        currentValue: metrics.investmentReturn,
                        targetValue: 0.08,
                        description: "投資組合的年度報酬率",
                        formula: "≥8%: +30分\n≥5%: +20分\n≥3%: +10分"
                    ),
                    ScoringFactor(
                        name: "投資組合分散度",
                        weight: 20,
                        currentValue: metrics.portfolioDiversification,
                        targetValue: 1.0,
                        description: "投資組合的資產分散程度（0-1）",
                        formula: "分散度 × 20分"
                    )
                ]
            )
            
        case .protection:
            return ScoringMethod(
                dimension: dimension,
                baseScore: 50,
                factors: [
                    ScoringFactor(
                        name: "保險覆蓋率",
                        weight: 30,
                        currentValue: metrics.insuranceCoverage,
                        targetValue: 1.0,
                        description: "保險保障的完整程度（0-1）",
                        formula: "覆蓋率 × 30分"
                    ),
                    ScoringFactor(
                        name: "風險保護度",
                        weight: 20,
                        currentValue: metrics.riskProtection,
                        targetValue: 1.0,
                        description: "整體風險保護的完整程度（0-1）",
                        formula: "保護度 × 20分"
                    )
                ]
            )
        }
    }
}

// 總體評分卡片
struct OverallScoreCard: View {
    let overallScore: Int
    
    var level: FinancialHealthLevel {
        FinancialHealthLevel.level(for: overallScore)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Text("總體財務健康評分")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("\(overallScore)")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(levelColor(level))
            
            Text(levelDisplayName(level))
                .font(.subheadline)
                .foregroundColor(levelColor(level))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(levelColor(level).opacity(0.1))
                .cornerRadius(20)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

// 維度評分卡片
struct DimensionScoringCard: View {
    let dimension: FinancialHealthDimension
    let currentScore: Int
    let calculatedScore: Int
    let hasOverride: Bool
    let scoringMethod: ScoringMethod
    let metrics: FinancialHealthMetrics
    let onEdit: () -> Void
    let onReset: () -> Void
    
    var level: FinancialHealthLevel {
        FinancialHealthLevel.level(for: currentScore)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 標題和當前分數
            HStack {
                Image(systemName: dimension.icon)
                    .font(.title2)
                    .foregroundColor(dimensionColor(dimension))
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(dimensionDisplayName(dimension))
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    HStack(spacing: 8) {
                        if hasOverride {
                            Label("手動調整", systemImage: "hand.raised.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                        } else {
                            Label("自動計算", systemImage: "cpu")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(currentScore) 分")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(levelColor(level))
                    
                    if hasOverride {
                        Text("計算值: \(calculatedScore) 分")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(levelDisplayName(level))
                        .font(.caption)
                        .foregroundColor(levelColor(level))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(levelColor(level).opacity(0.1))
                        .cornerRadius(8)
                }
            }
            
            Divider()
            
            // 評分方式說明
            VStack(alignment: .leading, spacing: 12) {
                Text("評分方式")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                Text("基礎分數: \(scoringMethod.baseScore)分")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ForEach(scoringMethod.factors, id: \.name) { factor in
                    ScoringFactorView(factor: factor)
                }
            }
            
            Divider()
            
            // 操作按鈕
            HStack(spacing: 12) {
                if hasOverride {
                    Button(action: onReset) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("恢復自動計算")
                        }
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                
                Button(action: onEdit) {
                    HStack {
                        Image(systemName: "pencil")
                        Text(hasOverride ? "調整分數" : "手動設定")
                    }
                    .font(.subheadline)
                    .foregroundColor(.orange)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

// 評分因子視圖
struct ScoringFactorView: View {
    let factor: ScoringFactor
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(factor.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("最多 \(factor.weight)分")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(factor.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            
            HStack {
                Text("當前值: \(formatValue(factor.currentValue))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text("計算公式：\(factor.formula)")
                .font(.caption)
                .foregroundColor(.blue)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(6)
        }
        .padding(.vertical, 4)
    }
    
    private func formatValue(_ value: Double) -> String {
        if value >= 1 {
            return String(format: "%.0f", value)
        } else if value >= 0.01 {
            return String(format: "%.2f", value)
        } else {
            return String(format: "%.4f", value)
        }
    }
}

// 分數編輯表單
struct ScoreEditSheet: View {
    let dimension: FinancialHealthDimension
    @State var currentScore: Int
    let calculatedScore: Int
    let onSave: (Int) -> Void
    let onCancel: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // 說明文字
                VStack(spacing: 8) {
                    Text(dimensionDisplayName(dimension))
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("系統計算分數: \(calculatedScore)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("您可以手動設定此維度的分數，覆蓋系統自動計算的值。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top)
                
                // 分數調整器
                VStack(spacing: 16) {
                    Text("\(currentScore) 分")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(levelColor(FinancialHealthLevel.level(for: currentScore)))
                    
                    Slider(value: Binding(
                        get: { Double(currentScore) },
                        set: { currentScore = Int($0) }
                    ), in: 0...100, step: 1)
                    .tint(dimensionColor(dimension))
                    
                    HStack {
                        Text("0")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("100")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // 快速設定按鈕
                    HStack(spacing: 12) {
                        QuickScoreButton(value: calculatedScore, label: "恢復計算值", isSelected: currentScore == calculatedScore) {
                            currentScore = calculatedScore
                        }
                        
                        QuickScoreButton(value: 50, label: "50", isSelected: currentScore == 50) {
                            currentScore = 50
                        }
                        
                        QuickScoreButton(value: 80, label: "80", isSelected: currentScore == 80) {
                            currentScore = 80
                        }
                        
                        QuickScoreButton(value: 100, label: "100", isSelected: currentScore == 100) {
                            currentScore = 100
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
                
                Spacer()
                
                // 操作按鈕
                HStack(spacing: 16) {
                    Button("取消") {
                        dismiss()
                        onCancel()
                    }
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color(.systemGray5))
                    .cornerRadius(12)
                    
                    Button("保存") {
                        onSave(currentScore)
                        dismiss()
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(dimensionColor(dimension))
                    .cornerRadius(12)
                }
            }
            .padding()
            .navigationTitle("調整分數")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct QuickScoreButton: View {
    let value: Int
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .cornerRadius(8)
        }
    }
}

// 評分方法數據結構
struct ScoringMethod {
    let dimension: FinancialHealthDimension
    let baseScore: Int
    let factors: [ScoringFactor]
}

struct ScoringFactor {
    let name: String
    let weight: Int
    let currentValue: Double
    let targetValue: Double
    let description: String
    let formula: String
}

// 注意：FinancialHealthDimension 已經符合 Identifiable（如果需要的話）

