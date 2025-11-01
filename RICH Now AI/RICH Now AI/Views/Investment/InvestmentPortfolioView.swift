//
//  InvestmentPortfolioView.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import SwiftUI
import SwiftData
import Charts

struct InvestmentPortfolioView: View {
    @StateObject private var portfolioManager = InvestmentPortfolioManager.shared
    @State private var selectedTab = 0
    @State private var showingAddInvestment = false
    @State private var showingWatchlist = false
    @State private var showingPortfolioSettings = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 投資組合選擇器
                if !portfolioManager.portfolios.isEmpty {
                    PortfolioSelectorView(
                        portfolios: portfolioManager.portfolios,
                        selectedPortfolio: $portfolioManager.currentPortfolio
                    )
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                
                // 標籤選擇器
                Picker("Portfolio View", selection: $selectedTab) {
                    Text(LocalizationManager.shared.localizedString("investment.overview")).tag(0)
                    Text(LocalizationManager.shared.localizedString("investment.holdings")).tag(1)
                    Text(LocalizationManager.shared.localizedString("investment.performance")).tag(2)
                    Text(LocalizationManager.shared.localizedString("investment.analysis")).tag(3)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                
                // 內容視圖
                TabView(selection: $selectedTab) {
                    // 概覽
                    PortfolioOverviewView(portfolio: portfolioManager.currentPortfolio)
                        .tag(0)
                    
                    // 持倉
                    PortfolioHoldingsView(portfolio: portfolioManager.currentPortfolio)
                        .tag(1)
                    
                    // 績效
                    PortfolioPerformanceView(portfolio: portfolioManager.currentPortfolio)
                        .tag(2)
                    
                    // 分析
                    PortfolioAnalysisView(portfolio: portfolioManager.currentPortfolio)
                        .tag(3)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle(LocalizationManager.shared.localizedString("investment.title"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showingAddInvestment = true }) {
                            Label(LocalizationManager.shared.localizedString("investment.add_investment"), systemImage: "plus")
                        }
                        
                        Button(action: { showingWatchlist = true }) {
                            Label("投資關注", systemImage: "eye")
                        }
                        
                        Button(action: { showingPortfolioSettings = true }) {
                            Label(LocalizationManager.shared.localizedString("investment.portfolio_settings"), systemImage: "gearshape")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingAddInvestment) {
                AddInvestmentView()
            }
            .sheet(isPresented: $showingWatchlist) {
                WatchlistView()
            }
            .sheet(isPresented: $showingPortfolioSettings) {
                PortfolioSettingsView()
            }
            .onAppear {
                portfolioManager.loadPortfolios()
            }
        }
    }
}

// 投資組合選擇器
struct PortfolioSelectorView: View {
    let portfolios: [InvestmentPortfolio]
    @Binding var selectedPortfolio: InvestmentPortfolio?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(portfolios, id: \.id) { portfolio in
                    PortfolioCard(
                        portfolio: portfolio,
                        isSelected: selectedPortfolio?.id == portfolio.id
                    ) {
                        selectedPortfolio = portfolio
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

// 投資組合卡片
struct PortfolioCard: View {
    let portfolio: InvestmentPortfolio
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(portfolio.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                    }
                }
                
                Text(portfolio.portfolioDescription ?? "")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(LocalizationManager.shared.localizedString("investment.total_value"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("$\(portfolio.totalValue, specifier: "%.2f")")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(portfolio.totalGainLoss >= 0 ? .green : .red)
                    }
                    
                    HStack {
                        Text(LocalizationManager.shared.localizedString("investment.gain_loss"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(portfolio.totalGainLoss >= 0 ? "+" : "")\(portfolio.totalGainLossPercentage, specifier: "%.2f")%")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(portfolio.totalGainLoss >= 0 ? .green : .red)
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .frame(width: 200)
    }
}

// 投資組合概覽視圖
struct PortfolioOverviewView: View {
    let portfolio: InvestmentPortfolio?
    @StateObject private var portfolioManager = InvestmentPortfolioManager.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let portfolio = portfolio {
                    // 總體績效卡片
                    OverallPerformanceCard(portfolio: portfolio)
                    
                    // 資產配置圖表
                    AssetAllocationCard(portfolio: portfolio)
                    
                    // 快速統計
                    QuickStatsCard(portfolio: portfolio)
                    
                    // 最近交易
                    RecentTransactionsCard(portfolio: portfolio)
                } else {
                    EmptyPortfolioView()
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
    }
}

// 總體績效卡片
struct OverallPerformanceCard: View {
    let portfolio: InvestmentPortfolio
    
    var body: some View {
        VStack(spacing: 16) {
            // 總價值
            VStack(spacing: 8) {
                Text(LocalizationManager.shared.localizedString("investment.total_value"))
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text("$\(portfolio.totalValue, specifier: "%.2f")")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.primary)
            }
            
            // 損益
            HStack(spacing: 20) {
                VStack {
                    Text(LocalizationManager.shared.localizedString("investment.total_gain_loss"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("$\(portfolio.totalGainLoss, specifier: "%.2f")")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(portfolio.totalGainLoss >= 0 ? .green : .red)
                }
                
                VStack {
                    Text(LocalizationManager.shared.localizedString("investment.percentage"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(portfolio.totalGainLoss >= 0 ? "+" : "")\(portfolio.totalGainLossPercentage, specifier: "%.2f")%")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(portfolio.totalGainLoss >= 0 ? .green : .red)
                }
            }
            
            // 風險等級
            HStack {
                Text(LocalizationManager.shared.localizedString("investment.risk_level"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(portfolio.riskLevel.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(portfolio.riskLevel.color)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(portfolio.riskLevel.color.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

// 資產配置卡片
struct AssetAllocationCard: View {
    let portfolio: InvestmentPortfolio
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizationManager.shared.localizedString("investment.asset_allocation"))
                .font(.headline)
                .fontWeight(.semibold)
            
            if portfolio.investments.isEmpty {
                Text(LocalizationManager.shared.localizedString("investment.no_investments"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                // 資產配置列表
                VStack(spacing: 8) {
                    ForEach(Array(portfolio.assetAllocation.sorted(by: { $0.value > $1.value })), id: \.key) { type, percentage in
                        AssetAllocationRow(
                            type: type,
                            percentage: percentage,
                            value: portfolio.totalValue * percentage / 100
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

// 資產配置行
struct AssetAllocationRow: View {
    let type: InvestmentType
    let percentage: Double
    let value: Double
    
    var body: some View {
        HStack {
            Image(systemName: type.icon)
                .foregroundColor(type.color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(type.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("$\(value, specifier: "%.2f")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(percentage, specifier: "%.1f")%")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                ProgressView(value: percentage, total: 100)
                    .progressViewStyle(LinearProgressViewStyle(tint: type.color))
                    .frame(width: 60)
            }
        }
    }
}

// 快速統計卡片
struct QuickStatsCard: View {
    let portfolio: InvestmentPortfolio
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizationManager.shared.localizedString("investment.quick_stats"))
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                StatItem(
                    title: LocalizationManager.shared.localizedString("investment.total_investments"),
                    value: "\(portfolio.investments.count)",
                    icon: "chart.bar.fill",
                    color: .blue
                )
                
                StatItem(
                    title: LocalizationManager.shared.localizedString("investment.diversification"),
                    value: "\(Int(portfolio.assetAllocation.count))",
                    icon: "square.grid.3x3.fill",
                    color: .green
                )
                
                StatItem(
                    title: LocalizationManager.shared.localizedString("investment.risk_score"),
                    value: String(format: "%.1f", portfolio.riskScore),
                    icon: "exclamationmark.triangle.fill",
                    color: portfolio.riskScore > 3 ? .red : .orange
                )
                
                StatItem(
                    title: LocalizationManager.shared.localizedString("investment.last_updated"),
                    value: DateFormatter.shortDate.string(from: portfolio.updatedAt),
                    icon: "clock.fill",
                    color: .gray
                )
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

// 統計項目
struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
}

// 最近交易卡片
struct RecentTransactionsCard: View {
    let portfolio: InvestmentPortfolio
    
    var recentTransactions: [InvestmentTransaction] {
        let allTransactions = portfolio.investments.flatMap { $0.transactions }
        return Array(allTransactions.sorted { $0.date > $1.date }.prefix(5))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizationManager.shared.localizedString("investment.recent_transactions"))
                .font(.headline)
                .fontWeight(.semibold)
            
            if recentTransactions.isEmpty {
                Text(LocalizationManager.shared.localizedString("investment.no_transactions"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 8) {
                    ForEach(recentTransactions, id: \.id) { transaction in
                        TransactionRow(transaction: transaction)
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

// 交易行
struct TransactionRow: View {
    let transaction: InvestmentTransaction
    
    var body: some View {
        HStack {
            Image(systemName: transaction.type.icon)
                .foregroundColor(transaction.type == .buy ? .green : .red)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.type.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(transaction.date, formatter: DateFormatter.shortDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("$\(transaction.totalAmount, specifier: "%.2f")")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(transaction.type == .buy ? .green : .red)
                
                Text("\(transaction.shares, specifier: "%.2f") shares")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// 空投資組合視圖
struct EmptyPortfolioView: View {
    @StateObject private var portfolioManager = InvestmentPortfolioManager.shared
    @State private var showingCreatePortfolio = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                Text(LocalizationManager.shared.localizedString("investment.no_portfolio"))
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(LocalizationManager.shared.localizedString("investment.no_portfolio.description"))
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: {
                showingCreatePortfolio = true
            }) {
                HStack {
                    Image(systemName: "plus")
                    Text(LocalizationManager.shared.localizedString("investment.create_portfolio"))
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue)
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .sheet(isPresented: $showingCreatePortfolio) {
            CreatePortfolioView()
        }
    }
}

// 創建投資組合視圖
struct CreatePortfolioView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var portfolioManager = InvestmentPortfolioManager.shared
    
    @State private var name = ""
    @State private var description = ""
    @State private var riskLevel: RiskLevel = .moderate
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本資訊")) {
                    TextField("投資組合名稱", text: $name)
                    
                    TextField("描述", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                    
                    Picker("風險等級", selection: $riskLevel) {
                        ForEach(RiskLevel.allCases, id: \.self) { level in
                            Text(level.displayName).tag(level)
                        }
                    }
                }
                
                Section {
                    Button("創建") {
                        createPortfolio()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .navigationTitle("創建投資組合")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                portfolioManager.setModelContext(modelContext)
            }
        }
    }
    
    private func createPortfolio() {
        let portfolio = portfolioManager.createPortfolio(
            name: name,
            description: description.isEmpty ? nil : description,
            riskLevel: riskLevel
        )
        
        if portfolio.totalValue == 0 { // 創建成功
            dismiss()
        }
    }
}

// 預覽
#Preview {
    InvestmentPortfolioView()
}

// DateFormatter.shortDate 已移至 DateFormatter+Extensions.swift

// 添加投資視圖
struct AddInvestmentView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var portfolioManager = InvestmentPortfolioManager.shared
    
    @State private var symbol = ""
    @State private var name = ""
    @State private var selectedType: InvestmentType = .stock
    @State private var shares = ""
    @State private var price = ""
    @State private var purchaseDate = Date()
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("投資資訊")) {
                    TextField("股票代碼", text: $symbol)
                    
                    TextField("投資名稱", text: $name)
                    
                    Picker("投資類型", selection: $selectedType) {
                        ForEach(InvestmentType.allCases, id: \.self) { type in
                            HStack {
                                Image(systemName: type.icon)
                                    .foregroundColor(type.color)
                                Text(type.displayName)
                            }
                            .tag(type)
                        }
                    }
                }
                
                Section(header: Text("持有資訊")) {
                    TextField("股數/單位", text: $shares)
                        .keyboardType(.decimalPad)
                    
                    TextField("成本價格", text: $price)
                        .keyboardType(.decimalPad)
                    
                    DatePicker("購買日期", selection: $purchaseDate, displayedComponents: .date)
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                Section {
                    Button("保存") {
                        saveInvestment()
                    }
                    .disabled(symbol.isEmpty || name.isEmpty || shares.isEmpty || price.isEmpty)
                }
            }
            .navigationTitle("添加投資")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                portfolioManager.setModelContext(modelContext)
            }
        }
    }
    
    private func saveInvestment() {
        guard let sharesValue = Double(shares),
              let priceValue = Double(price),
              let portfolio = portfolioManager.currentPortfolio else {
            errorMessage = "請先創建投資組合"
            return
        }
        
        let investment = Investment(
            symbol: symbol,
            name: name,
            type: selectedType,
            shares: sharesValue,
            averageCost: priceValue,
            purchaseDate: purchaseDate
        )
        
        investment.portfolio = portfolio
        portfolio.investments.append(investment)
        
        modelContext.insert(investment)
        
        do {
            try modelContext.save()
            portfolioManager.updatePortfolio(portfolio)
            dismiss()
        } catch {
            errorMessage = "保存失敗: \(error.localizedDescription)"
        }
    }
}

// 投資組合設定視圖
struct PortfolioSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var description = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("投資組合資訊") {
                    TextField("名稱", text: $name)
                    TextField("描述", text: $description)
                }
            }
            .navigationTitle("投資組合設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        // 保存邏輯
                        dismiss()
                    }
                }
            }
        }
    }
}
