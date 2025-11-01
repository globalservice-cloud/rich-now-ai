//
//  PortfolioHoldingsView.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import SwiftUI

struct PortfolioHoldingsView: View {
    let portfolio: InvestmentPortfolio?
    @StateObject private var portfolioManager = InvestmentPortfolioManager.shared
    @State private var searchText = ""
    @State private var sortOption: SortOption = .value
    @State private var filterOption: FilterOption = .all
    
    enum SortOption: String, CaseIterable {
        case value = "value"
        case gainLoss = "gain_loss"
        case name = "name"
        case type = "type"
        
        var displayName: String {
            return LocalizationManager.shared.localizedString("investment.sort.\(self.rawValue)")
        }
    }
    
    enum FilterOption: String, CaseIterable {
        case all = "all"
        case stocks = "stocks"
        case bonds = "bonds"
        case crypto = "crypto"
        case others = "others"
        
        var displayName: String {
            return LocalizationManager.shared.localizedString("investment.filter.\(self.rawValue)")
        }
    }
    
    var filteredInvestments: [Investment] {
        guard let portfolio = portfolio else { return [] }
        
        var investments = portfolio.investments
        
        // 搜尋過濾
        if !searchText.isEmpty {
            investments = investments.filter { investment in
                investment.name.localizedCaseInsensitiveContains(searchText) ||
                investment.symbol.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // 類型過濾
        switch filterOption {
        case .all:
            break
        case .stocks:
            investments = investments.filter { investmentType(for: $0) == .stock }
        case .bonds:
            investments = investments.filter { investmentType(for: $0) == .bond }
        case .crypto:
            investments = investments.filter { investmentType(for: $0) == .crypto }
        case .others:
            investments = investments.filter {
                let type = investmentType(for: $0)
                return ![InvestmentType.stock, .bond, .crypto].contains(type)
            }
        }
        
        // 排序
        switch sortOption {
        case .value:
            investments = investments.sorted { $0.currentValue > $1.currentValue }
        case .gainLoss:
            investments = investments.sorted { $0.totalReturnPercentage > $1.totalReturnPercentage }
        case .name:
            investments = investments.sorted { $0.name < $1.name }
        case .type:
            investments = investments.sorted { investmentType(for: $0).rawValue < investmentType(for: $1).rawValue }
        }
        
        return investments
    }
    
    private func investmentType(for investment: Investment) -> InvestmentType {
        InvestmentType(rawValue: investment.type) ?? .other
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if let portfolio = portfolio, !portfolio.investments.isEmpty {
                // 搜尋和篩選
                VStack(spacing: 12) {
                    // 搜尋欄
                    SearchBar(text: $searchText)
                        .padding(.horizontal, 16)
                    
                    // 篩選和排序
                    HStack {
                        // 篩選器
                        Menu {
                            ForEach(FilterOption.allCases, id: \.self) { option in
                                Button(action: { filterOption = option }) {
                                    HStack {
                                        Text(option.displayName)
                                        if filterOption == option {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: "line.3.horizontal.decrease")
                                Text(filterOption.displayName)
                            }
                            .font(.subheadline)
                            .foregroundColor(.blue)
                        }
                        
                        Spacer()
                        
                        // 排序器
                        Menu {
                            ForEach(SortOption.allCases, id: \.self) { option in
                                Button(action: { sortOption = option }) {
                                    HStack {
                                        Text(option.displayName)
                                        if sortOption == option {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: "arrow.up.arrow.down")
                                Text(sortOption.displayName)
                            }
                            .font(.subheadline)
                            .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 8)
                
                // 投資列表
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredInvestments, id: \.id) { investment in
                            InvestmentCard(investment: investment)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
            } else {
                // 空狀態
                EmptyHoldingsView()
            }
        }
    }
}

// 投資卡片
struct InvestmentCard: View {
    let investment: Investment
    @State private var showingDetail = false
    
    var body: some View {
        let investmentType = InvestmentType(rawValue: investment.type) ?? .other
        let riskLevel = investment.riskLevel
        let formattedCurrentValue = String(format: "$%.2f", investment.currentValue)
        let formattedShares = String(format: "%.2f", investment.shares)
        let formattedCurrentPrice = String(format: "$%.2f", investment.currentPrice)
        let dayChangePrefix = investment.dailyChange >= 0 ? "+" : ""
        let formattedDayChange = String(format: "%@%.2f%%", dayChangePrefix, investment.dailyChangePercentage)
        let totalReturnPrefix = investment.totalReturn >= 0 ? "+" : ""
        let formattedTotalReturn = String(format: "%@%.2f%%", totalReturnPrefix, investment.totalReturnPercentage)
        
        Button {
            showingDetail = true
        } label: {
            VStack(spacing: 12) {
                // 標題行
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(investment.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        Text(investment.symbol)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(formattedCurrentValue)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("\(formattedShares) shares")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // 績效行
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(LocalizationManager.shared.localizedString("investment.current_price"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(formattedCurrentPrice)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .center, spacing: 2) {
                        Text(LocalizationManager.shared.localizedString("investment.day_change"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(formattedDayChange)
                            .font(.subheadline)
                            .fontWeight(.medium)
                                    .foregroundColor(investment.dailyChange >= 0 ? .green : .red)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(LocalizationManager.shared.localizedString("investment.total_gain_loss"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(formattedTotalReturn)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(investment.totalReturn >= 0 ? .green : .red)
                    }
                }
                
                // 類型標籤
                HStack {
                    HStack {
                        Image(systemName: investmentType.icon)
                            .foregroundColor(investmentType.color)
                        Text(investmentType.displayName)
                            .font(.caption)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(investmentType.color.opacity(0.1))
                    .cornerRadius(8)
                    
                    Spacer()
                    
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(riskLevel.color)
                        Text(riskLevel.displayName)
                            .font(.caption)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(riskLevel.color.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingDetail) {
            InvestmentDetailView(investment: investment)
        }
    }
}

// 投資詳情視圖
struct InvestmentDetailView: View {
    let investment: Investment
    @Environment(\.dismiss) private var dismiss
    
    private var investmentType: InvestmentType {
        InvestmentType(rawValue: investment.type) ?? .other
    }
    
    var body: some View {
        let formattedCurrentPrice = String(format: "$%.2f", investment.currentPrice)
        let formattedCurrentValue = String(format: "$%.2f", investment.currentValue)
        let formattedShares = String(format: "%.2f", investment.shares)
        let formattedAverageCost = String(format: "$%.2f", investment.averageCost)
        let totalReturnPrefix = investment.totalReturn >= 0 ? "+" : ""
        let formattedTotalReturn = String(format: "%@%.2f%%", totalReturnPrefix, investment.totalReturnPercentage)
        let dayChangePrefix = investment.dailyChange >= 0 ? "+" : ""
        let formattedDayChange = String(format: "%@%.2f%%", dayChangePrefix, investment.dailyChangePercentage)
        
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(investment.name)
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text(investment.symbol)
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    
                    infoRow(title: LocalizationManager.shared.localizedString("investment.current_price"), value: formattedCurrentPrice)
                    infoRow(title: LocalizationManager.shared.localizedString("investment.total_value"), value: formattedCurrentValue)
                    infoRow(title: LocalizationManager.shared.localizedString("investment.shares_owned"), value: formattedShares)
                    infoRow(title: LocalizationManager.shared.localizedString("investment.average_cost"), value: formattedAverageCost)
                    
                    infoRow(
                        title: LocalizationManager.shared.localizedString("investment.total_gain_loss"),
                        value: formattedTotalReturn,
                        valueColor: investment.totalReturn >= 0 ? .green : .red
                    )
                    
                    infoRow(
                        title: LocalizationManager.shared.localizedString("investment.day_change"),
                        value: formattedDayChange,
                        valueColor: investment.dailyChange >= 0 ? .green : .red
                    )
                    
                    infoRow(
                        title: LocalizationManager.shared.localizedString("investment.type"),
                        value: investmentType.displayName
                    )
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle(LocalizationManager.shared.localizedString("investment.detail"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { dismiss() }) {
                        Text(LocalizationManager.shared.localizedString("common.close"))
                    }
                }
            }
        }
    }
    
    private func infoRow(title: String, value: String, valueColor: Color = .primary) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(valueColor)
        }
    }
}

// 搜尋欄
struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField(LocalizationManager.shared.localizedString("investment.search_placeholder"), text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray6))
        )
    }
}

// 空持倉視圖
struct EmptyHoldingsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                Text(LocalizationManager.shared.localizedString("investment.no_holdings"))
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(LocalizationManager.shared.localizedString("investment.no_holdings.description"))
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: {
                // 添加投資
            }) {
                HStack {
                    Image(systemName: "plus")
                    Text(LocalizationManager.shared.localizedString("investment.add_investment"))
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
    }
}

// 預覽
#Preview {
    PortfolioHoldingsView(portfolio: nil)
}
