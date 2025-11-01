//
//  AccountingMainView.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import SwiftUI
import SwiftData

struct AccountingMainView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    
    @State private var selectedTab = 0
    @State private var showTextAccounting = false
    @State private var showTransactionHistory = false
    
    // 計算統計數據
    private var todayTransactions: [Transaction] {
        let today = Calendar.current.startOfDay(for: Date())
        return transactions.filter { Calendar.current.isDate($0.date, inSameDayAs: today) }
    }
    
    private var todayIncome: Double {
        todayTransactions.filter { $0.isIncome }.reduce(0) { $0 + $1.amount }
    }
    
    private var todayExpense: Double {
        todayTransactions.filter { $0.isExpense }.reduce(0) { $0 + $1.amount }
    }
    
    private var thisMonthTransactions: [Transaction] {
        let startOfMonth = Calendar.current.dateInterval(of: .month, for: Date())?.start ?? Date()
        return transactions.filter { $0.date >= startOfMonth }
    }
    
    private var thisMonthIncome: Double {
        thisMonthTransactions.filter { $0.isIncome }.reduce(0) { $0 + $1.amount }
    }
    
    private var thisMonthExpense: Double {
        thisMonthTransactions.filter { $0.isExpense }.reduce(0) { $0 + $1.amount }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 標題區域
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(LocalizationManager.shared.localizedString("accounting.title"))
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Text(LocalizationManager.shared.localizedString("accounting.subtitle"))
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button(action: { showTextAccounting = true }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.blue)
                        }
                    }
                    
                    // 快速統計卡片
                    HStack(spacing: 12) {
                        StatCardView(
                            title: LocalizationManager.shared.localizedString("accounting.today_income"),
                            amount: todayIncome,
                            color: .green,
                            icon: "arrow.up.circle.fill"
                        )
                        
                        StatCardView(
                            title: LocalizationManager.shared.localizedString("accounting.today_expense"),
                            amount: todayExpense,
                            color: .red,
                            icon: "arrow.down.circle.fill"
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                // 主要內容
                TabView(selection: $selectedTab) {
                    // 今日交易
                    TodayTransactionsView(transactions: todayTransactions)
                        .tag(0)
                    
                    // 本月統計
                    MonthlyStatsView(
                        income: thisMonthIncome,
                        expense: thisMonthExpense,
                        transactions: thisMonthTransactions
                    )
                    .tag(1)
                    
                    // 分類統計
                    CategoryStatsView(transactions: thisMonthTransactions)
                        .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                // 自定義 Tab 指示器
                HStack(spacing: 20) {
                    TabButton(
                        title: LocalizationManager.shared.localizedString("accounting.today"),
                        icon: "calendar",
                        isSelected: selectedTab == 0
                    ) {
                        selectedTab = 0
                    }
                    
                    TabButton(
                        title: LocalizationManager.shared.localizedString("accounting.monthly"),
                        icon: "chart.bar",
                        isSelected: selectedTab == 1
                    ) {
                        selectedTab = 1
                    }
                    
                    TabButton(
                        title: LocalizationManager.shared.localizedString("accounting.categories"),
                        icon: "tag",
                        isSelected: selectedTab == 2
                    ) {
                        selectedTab = 2
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 10)
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showTextAccounting) {
            TextAccountingView()
        }
        .sheet(isPresented: $showTransactionHistory) {
            TransactionHistoryView()
        }
    }
}

// 統計卡片視圖
struct StatCardView: View {
    let title: String
    let amount: Double
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            Text(amount, format: .currency(code: "TWD"))
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// Tab 按鈕
struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isSelected ? .blue : .secondary)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isSelected ? .blue : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }
}

// 今日交易視圖
struct TodayTransactionsView: View {
    let transactions: [Transaction]
    @State private var showAllTransactions = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(LocalizationManager.shared.localizedString("accounting.today_transactions"))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                if !transactions.isEmpty {
                    Button(LocalizationManager.shared.localizedString("common.view_all")) {
                        showAllTransactions = true
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 20)
            
            if transactions.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "list.bullet.rectangle")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    
                    Text(LocalizationManager.shared.localizedString("accounting.no_transactions_today"))
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(Array(transactions.prefix(5))) { transaction in
                        TransactionRowView(transaction: transaction)
                            .padding(.horizontal, 20)
                    }
                }
            }
        }
    }
}

// 本月統計視圖
struct MonthlyStatsView: View {
    let income: Double
    let expense: Double
    let transactions: [Transaction]
    
    private var netAmount: Double {
        income - expense
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // 主要統計
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(LocalizationManager.shared.localizedString("accounting.monthly_income"))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Text(income, format: .currency(code: "TWD"))
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.green)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 8) {
                        Text(LocalizationManager.shared.localizedString("accounting.monthly_expense"))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Text(expense, format: .currency(code: "TWD"))
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.red)
                    }
                }
                .padding(20)
                .background(Color(.systemGray6))
                .cornerRadius(16)
                
                // 淨額
                HStack {
                    Text(LocalizationManager.shared.localizedString("accounting.net_amount"))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(netAmount, format: .currency(code: "TWD"))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(netAmount >= 0 ? .green : .red)
                }
                .padding(16)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .padding(.horizontal, 20)
            
            // 交易數量統計
            VStack(alignment: .leading, spacing: 12) {
                Text(LocalizationManager.shared.localizedString("accounting.transaction_count"))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 20)
                
                HStack(spacing: 12) {
                    StatItemView(
                        title: LocalizationManager.shared.localizedString("accounting.total"),
                        value: "\(transactions.count)",
                        color: .blue
                    )
                    
                    StatItemView(
                        title: LocalizationManager.shared.localizedString("accounting.income_count"),
                        value: "\(transactions.filter { $0.isIncome }.count)",
                        color: .green
                    )
                    
                    StatItemView(
                        title: LocalizationManager.shared.localizedString("accounting.expense_count"),
                        value: "\(transactions.filter { $0.isExpense }.count)",
                        color: .red
                    )
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

// 分類統計視圖
struct CategoryStatsView: View {
    let transactions: [Transaction]
    
    private var categoryStats: [(String, Double, Int)] {
        let grouped = Dictionary(grouping: transactions) { $0.category }
        return grouped.map { (category, transactions) in
            let total = transactions.reduce(0) { $0 + $1.amount }
            return (category, total, transactions.count)
        }.sorted { $0.1 > $1.1 }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizationManager.shared.localizedString("accounting.category_stats"))
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)
                .padding(.horizontal, 20)
            
            if categoryStats.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "chart.pie")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    
                    Text(LocalizationManager.shared.localizedString("accounting.no_category_data"))
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(Array(categoryStats.enumerated()), id: \.offset) { index, stat in
                        CategoryStatRowView(
                            category: stat.0,
                            amount: stat.1,
                            count: stat.2,
                            rank: index + 1
                        )
                        .padding(.horizontal, 20)
                    }
                }
            }
        }
    }
}

// 統計項目視圖
struct StatItemView: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(color)
            
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// 分類統計行視圖
struct CategoryStatRowView: View {
    let category: String
    let amount: Double
    let count: Int
    let rank: Int
    
    var body: some View {
        HStack(spacing: 12) {
            // 排名
            Text("#\(rank)")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Color.blue)
                .cornerRadius(12)
            
            // 分類名稱
            Text(category)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
            
            Spacer()
            
            // 金額和數量
            VStack(alignment: .trailing, spacing: 2) {
                Text(amount, format: .currency(code: "TWD"))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text("\(count) \(LocalizationManager.shared.localizedString("accounting.transactions"))")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

#Preview {
    AccountingMainView()
}
