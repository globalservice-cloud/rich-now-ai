//
//  IncomeStabilityGoalView.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/28.
//

import SwiftUI
import SwiftData

// 收入穩定性目標視圖
struct IncomeStabilityGoalView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    @Query private var goals: [FinancialGoal]
    
    @StateObject private var healthManager = FinancialHealthManager.shared
    @State private var currentStability: Double = 0.0
    @State private var targetStability: Double = 0.8 // 預設目標 80%
    @State private var monthlyIncome: Double = 0.0
    @State private var showGoalSetting = false
    @State private var showActionPlan = false
    @State private var hasIncomeData: Bool = false
    
    var stabilityGap: Double {
        max(0, targetStability - currentStability)
    }
    
    var stabilityScore: Int {
        Int(currentStability * 100)
    }
    
    var targetScore: Int {
        Int(targetStability * 100)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 標題
                    VStack(spacing: 8) {
                        Text("收入穩定性分析")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("了解您目前的收入穩定狀況")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)
                    
                    // 當前狀態卡片
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("當前穩定度")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text("\(stabilityScore)%")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(stabilityColor)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("目標穩定度")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text("\(targetScore)%")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        // 進度條
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("達成進度")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(Int((currentStability / targetStability) * 100))%")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                            }
                            
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    // 背景
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(.systemGray5))
                                        .frame(height: 12)
                                    
                                    // 當前進度
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(
                                            LinearGradient(
                                                colors: [stabilityColor, stabilityColor.opacity(0.7)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: geometry.size.width * min(1.0, currentStability / targetStability), height: 12)
                                    
                                    // 目標線
                                    if currentStability < targetStability {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.blue.opacity(0.3))
                                            .frame(width: 2, height: 16)
                                            .offset(x: geometry.size.width * (targetStability / 1.0) - 1)
                                    }
                                }
                            }
                            .frame(height: 12)
                            
                            // 差距顯示
                            if stabilityGap > 0 {
                                HStack {
                                    Image(systemName: "arrow.up.circle.fill")
                                        .foregroundColor(.orange)
                                        .font(.caption)
                                    
                                    Text("距離目標還差 \(Int(stabilityGap * 100))%")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                        .fontWeight(.medium)
                                }
                                .padding(.top, 4)
                            } else {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.caption)
                                    
                                    Text("已達成目標！")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                        .fontWeight(.medium)
                                }
                                .padding(.top, 4)
                            }
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    )
                    
                    // 詳細資訊卡片
                    VStack(spacing: 16) {
                        HStack {
                            Text("詳細資訊")
                                .font(.headline)
                            Spacer()
                        }
                        
                        InfoRow(
                            title: "月平均收入",
                            value: "NT$ \(String(format: "%.0f", monthlyIncome))",
                            icon: "dollarsign.circle.fill",
                            iconColor: .green
                        )
                        
                        InfoRow(
                            title: "收入波動率",
                            value: "\(Int((1 - currentStability) * 100))%",
                            icon: "chart.line.uptrend.xyaxis.fill",
                            iconColor: stabilityGap > 0.2 ? .red : .orange
                        )
                        
                        InfoRow(
                            title: "評估期間",
                            value: "過去 12 個月",
                            icon: "calendar",
                            iconColor: .blue
                        )
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemGray6))
                    )
                    
                    // 目標設定
                    if stabilityGap > 0 {
                        VStack(spacing: 16) {
                            HStack {
                                Text("改善建議")
                                    .font(.headline)
                                Spacer()
                            }
                            
                            // 建議列表
                            VStack(alignment: .leading, spacing: 12) {
                                RecommendationItem(
                                    icon: "target",
                                    title: "多元化收入來源",
                                    description: "建立多個穩定的收入來源，降低單一來源的風險"
                                )
                                
                                RecommendationItem(
                                    icon: "calendar.badge.plus",
                                    title: "穩定工作安排",
                                    description: "確保每月有穩定的收入進帳"
                                )
                                
                                RecommendationItem(
                                    icon: "chart.line.uptrend.xyaxis",
                                    title: "收入成長規劃",
                                    description: "制定長期收入成長計劃，提高平均值"
                                )
                            }
                            
                            // 行動計劃按鈕
                            Button(action: {
                                showActionPlan = true
                            }) {
                                HStack {
                                    Image(systemName: "list.bullet.clipboard.fill")
                                    Text("查看行動計劃")
                                }
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(
                                    LinearGradient(
                                        colors: [Color(red: 0.12, green: 0.23, blue: 0.54), Color(red: 0.19, green: 0.18, blue: 0.51)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                        )
                    }
                    
                    // 設定目標按鈕
                    Button(action: {
                        showGoalSetting = true
                    }) {
                        HStack {
                            Image(systemName: "slider.horizontal.3")
                            Text("調整目標")
                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .navigationTitle("收入穩定性")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadStabilityData()
            }
            .onChange(of: transactions.count) { _, _ in
                // 當交易記錄數量變化時，重新載入數據
                loadStabilityData()
            }
            .refreshable {
                // 支援下拉刷新
                await loadStabilityDataAsync()
            }
            .sheet(isPresented: $showGoalSetting) {
                GoalSettingView(
                    currentTarget: targetStability,
                    onSave: { newTarget in
                        targetStability = newTarget
                        saveGoal()
                    }
                )
            }
            .sheet(isPresented: $showActionPlan) {
                IncomeStabilityActionPlanView(
                    currentStability: currentStability,
                    targetStability: targetStability,
                    stabilityGap: stabilityGap,
                    monthlyIncome: monthlyIncome
                )
            }
        }
    }
    
    private var stabilityColor: Color {
        if currentStability >= 0.8 {
            return .green
        } else if currentStability >= 0.6 {
            return .orange
        } else {
            return .red
        }
    }
    
    private func loadStabilityData() {
        Task {
            await loadStabilityDataAsync()
        }
    }
    
    @MainActor
    private func loadStabilityDataAsync() async {
        // 先刷新健康評分，確保數據最新
        await healthManager.refreshHealthScore()
        
        // 檢查是否有收入交易記錄
        let incomeTransactions = transactions.filter { $0.type == TransactionType.income.rawValue }
        hasIncomeData = !incomeTransactions.isEmpty
        
        // 直接計算收入穩定性（從交易記錄）
        currentStability = healthManager.calculateIncomeStability(from: transactions)
        
        // 計算月平均收入
        let lastMonth = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        let recentIncomeTransactions = transactions.filter {
            $0.type == TransactionType.income.rawValue && $0.date >= lastMonth
        }
        monthlyIncome = recentIncomeTransactions.reduce(0) { $0 + $1.amount }
        
        // 如果沒有最近的收入記錄，嘗試從所有收入記錄計算平均值
        if monthlyIncome == 0 {
            let last12Months = Calendar.current.date(byAdding: .month, value: -12, to: Date()) ?? Date()
            let incomeTransactions = transactions.filter {
                $0.type == TransactionType.income.rawValue && $0.date >= last12Months
            }
            
            let monthlyIncomes = Dictionary(grouping: incomeTransactions) { transaction in
                Calendar.current.dateInterval(of: .month, for: transaction.date)?.start ?? transaction.date
            }.mapValues { $0.reduce(0) { $0 + $1.amount } }
            
            if !monthlyIncomes.isEmpty {
                monthlyIncome = monthlyIncomes.values.reduce(0, +) / Double(monthlyIncomes.count)
            }
        }
        
        // 載入目標（如果有的話）
        if let savedTarget = UserDefaults.standard.object(forKey: "incomeStabilityTarget") as? Double {
            targetStability = savedTarget
        } else if goals.contains(where: { $0.title.contains("收入穩定性") }) {
            // 可以從目標中解析目標穩定度
            // 目前先使用預設值
        }
        
        print("📊 收入穩定性數據已更新: 穩定度=\(Int(currentStability * 100))%, 月收入=\(monthlyIncome), 有收入資料=\(hasIncomeData)")
    }
    
    private func saveGoal() {
        // 保存目標到 UserDefaults 或 FinancialGoal
        UserDefaults.standard.set(targetStability, forKey: "incomeStabilityTarget")
    }
}

// 資訊行
struct InfoRow: View {
    let title: String
    let value: String
    let icon: String
    let iconColor: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .frame(width: 24)
            
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
        }
    }
}

// 建議項目
struct RecommendationItem: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .font(.title3)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

// 目標設定視圖
struct GoalSettingView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State var currentTarget: Double
    let onSave: (Double) -> Void
    
    @State private var targetPercentage: Double
    
    init(currentTarget: Double, onSave: @escaping (Double) -> Void) {
        self.currentTarget = currentTarget
        self.onSave = onSave
        self._targetPercentage = State(initialValue: currentTarget * 100)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("\(Int(targetPercentage))%")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.blue)
                    
                    Text("目標收入穩定度")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                
                // 滑桿
                VStack(spacing: 16) {
                    Slider(value: $targetPercentage, in: 0...100, step: 1)
                        .tint(.blue)
                    
                    HStack {
                        Text("0%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("100%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                
                // 建議值
                VStack(alignment: .leading, spacing: 12) {
                    Text("建議目標")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    GoalOptionCard(
                        title: "基本穩定",
                        percentage: 60,
                        description: "適合收入有一定波動的情況",
                        isSelected: Int(targetPercentage) == 60,
                        onSelect: { targetPercentage = 60 }
                    )
                    
                    GoalOptionCard(
                        title: "良好穩定",
                        percentage: 80,
                        description: "推薦目標，達到良好財務健康",
                        isSelected: Int(targetPercentage) == 80,
                        onSelect: { targetPercentage = 80 }
                    )
                    
                    GoalOptionCard(
                        title: "優秀穩定",
                        percentage: 90,
                        description: "頂級目標，收入非常穩定",
                        isSelected: Int(targetPercentage) == 90,
                        onSelect: { targetPercentage = 90 }
                    )
                }
                
                Spacer()
                
                // 保存按鈕
                Button(action: {
                    onSave(targetPercentage / 100.0)
                    dismiss()
                }) {
                    Text("確認設定")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0.12, green: 0.23, blue: 0.54), Color(red: 0.19, green: 0.18, blue: 0.51)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .navigationTitle("設定目標")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        onSave(targetPercentage / 100.0)
                        dismiss()
                    }
                }
            }
        }
    }
}

// 目標選項卡片
struct GoalOptionCard: View {
    let title: String
    let percentage: Int
    let description: String
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("\(percentage)%")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(isSelected ? .blue : .secondary)
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
                    .font(.title3)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
    }
}

// 行動計劃視圖
struct IncomeStabilityActionPlanView: View {
    @Environment(\.dismiss) private var dismiss
    
    let currentStability: Double
    let targetStability: Double
    let stabilityGap: Double
    let monthlyIncome: Double
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 標題
                    VStack(spacing: 8) {
                        Text("行動計劃")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("提升收入穩定度 \(Int(stabilityGap * 100))%")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)
                    
                    // 計劃步驟
                    VStack(spacing: 16) {
                        ActionStep(
                            number: 1,
                            title: "記錄所有收入來源",
                            description: "完整記錄過去 12 個月的所有收入交易，包括薪資、獎金、兼職等",
                            action: "開始記錄"
                        )
                        
                        ActionStep(
                            number: 2,
                            title: "分析收入模式",
                            description: "查看收入時間分佈，識別不穩定的月份和原因",
                            action: "查看分析"
                        )
                        
                        ActionStep(
                            number: 3,
                            title: "建立穩定收入",
                            description: "尋找固定薪資工作或建立定期收入來源，減少收入波動",
                            action: "了解建議"
                        )
                        
                        ActionStep(
                            number: 4,
                            title: "設定月度收入目標",
                            description: "基於平均收入設定月度最低收入目標，確保達到 \(Int(monthlyIncome * 0.9)) 元",
                            action: "設定目標"
                        )
                        
                        ActionStep(
                            number: 5,
                            title: "建立應急基金",
                            description: "儲蓄 3-6 個月的收入作為緩衝，應對收入波動",
                            action: "建立基金"
                        )
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 20)
            }
            .navigationTitle("行動計劃")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// 行動步驟
struct ActionStep: View {
    let number: Int
    let title: String
    let description: String
    let action: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // 步驟編號
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Text("\(number)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.blue)
            }
            
            // 內容
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                Button(action: {}) {
                    Text(action)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.blue)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
                .padding(.top, 4)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

#Preview {
    IncomeStabilityGoalView()
}

