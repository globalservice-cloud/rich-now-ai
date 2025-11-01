//
//  FinancialPlanningView.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/28.
//

import SwiftUI
import SwiftData

struct FinancialPlanningView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var goals: [FinancialGoal]
    @Query private var transactions: [Transaction]
    
    @State private var selectedTimeframe: PlanningTimeframe = .monthly
    
    enum PlanningTimeframe: String, CaseIterable {
        case weekly = "weekly"
        case monthly = "monthly"
        case quarterly = "quarterly"
        case yearly = "yearly"
        
        var displayName: String {
            switch self {
            case .weekly: return "每週"
            case .monthly: return "每月"
            case .quarterly: return "每季"
            case .yearly: return "每年"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 時間範圍選擇
                    Picker("時間範圍", selection: $selectedTimeframe) {
                        ForEach(PlanningTimeframe.allCases, id: \.self) { timeframe in
                            Text(timeframe.displayName).tag(timeframe)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    // 財務摘要
                    FinancialSummaryCard(goals: goals, transactions: transactions)
                    
                    // 目標進度
                    GoalsProgressCard(goals: goals.filter { $0.status == GoalStatus.active.rawValue })
                    
                    // 建議行動
                    PlanningSuggestionsCard()
                }
                .padding()
            }
            .navigationTitle("財務規劃")
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

// 財務摘要卡片
struct FinancialSummaryCard: View {
    let goals: [FinancialGoal]
    let transactions: [Transaction]
    
    var totalIncome: Double {
        transactions
            .filter { $0.getTransactionType() == .income }
            .reduce(0) { $0 + $1.amount }
    }
    
    var totalExpenses: Double {
        transactions
            .filter { $0.getTransactionType() == .expense }
            .reduce(0) { $0 + $1.amount }
    }
    
    var totalSavings: Double {
        totalIncome - totalExpenses
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("財務摘要")
                .font(.headline)
            
            HStack {
                SummaryItem(title: "收入", amount: totalIncome, color: .green)
                SummaryItem(title: "支出", amount: totalExpenses, color: .red)
                SummaryItem(title: "儲蓄", amount: totalSavings, color: .blue)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(radius: 4)
        )
    }
}

struct SummaryItem: View {
    let title: String
    let amount: Double
    let color: Color
    
    var body: some View {
        VStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(String(format: "%.0f", amount))
                .font(.headline)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }
}

// 目標進度卡片
struct GoalsProgressCard: View {
    let goals: [FinancialGoal]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("目標進度")
                .font(.headline)
            
            if goals.isEmpty {
                Text("目前沒有進行中的目標")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(goals, id: \.id) { goal in
                    GoalProgressRow(goal: goal)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(radius: 4)
        )
    }
}

struct GoalProgressRow: View {
    let goal: FinancialGoal
    
    var progress: Double {
        goal.targetAmount > 0 ? goal.currentAmount / goal.targetAmount : 0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(goal.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: progress)
                .tint(.blue)
            
            HStack {
                Text("已達成: $\(Int(goal.currentAmount))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("目標: $\(Int(goal.targetAmount))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// 規劃建議卡片
struct PlanningSuggestionsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("建議行動")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 12) {
                SuggestionRow(
                    icon: "lightbulb.fill",
                    text: "建議每月儲蓄至少收入的20%"
                )
                SuggestionRow(
                    icon: "calendar.badge.clock",
                    text: "定期檢視目標進度，適時調整"
                )
                SuggestionRow(
                    icon: "chart.line.uptrend.xyaxis",
                    text: "考慮投資以增加資產成長"
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(radius: 4)
        )
    }
}

struct SuggestionRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.orange)
            Text(text)
                .font(.subheadline)
            Spacer()
        }
    }
}

#Preview {
    FinancialPlanningView()
        .modelContainer(for: [FinancialGoal.self, Transaction.self])
}

