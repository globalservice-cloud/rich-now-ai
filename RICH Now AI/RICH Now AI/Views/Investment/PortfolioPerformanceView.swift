//
//  PortfolioPerformanceView.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import SwiftUI
import Charts

struct PortfolioPerformanceView: View {
    let portfolio: InvestmentPortfolio?
    @StateObject private var portfolioManager = InvestmentPortfolioManager.shared
    @State private var selectedTimeframe: Timeframe = .oneMonth
    
    enum Timeframe: String, CaseIterable {
        case oneWeek = "1w"
        case oneMonth = "1m"
        case threeMonths = "3m"
        case sixMonths = "6m"
        case oneYear = "1y"
        case allTime = "all"
        
        var displayName: String {
            return LocalizationManager.shared.localizedString("investment.timeframe.\(self.rawValue)")
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let portfolio = portfolio {
                    // 時間範圍選擇器
                    TimeframeSelector(selectedTimeframe: $selectedTimeframe)
                        .padding(.horizontal, 16)
                    
                    // 績效概覽
                    PerformanceOverviewCard(portfolio: portfolio)
                    
                    // 績效圖表
                    PerformanceChartCard(portfolio: portfolio, timeframe: selectedTimeframe)
                    
                    // 詳細績效指標
                    PerformanceMetricsCard(portfolio: portfolio)
                    
                    // 投資績效比較
                    InvestmentPerformanceComparison(portfolio: portfolio)
                } else {
                    EmptyPerformanceView()
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
    }
}

// 時間範圍選擇器
struct TimeframeSelector: View {
    @Binding var selectedTimeframe: PortfolioPerformanceView.Timeframe
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(PortfolioPerformanceView.Timeframe.allCases, id: \.self) { timeframe in
                    Button(action: { selectedTimeframe = timeframe }) {
                        Text(timeframe.displayName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(selectedTimeframe == timeframe ? .white : .blue)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(selectedTimeframe == timeframe ? Color.blue : Color.blue.opacity(0.1))
                            )
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

// 績效概覽卡片
struct PerformanceOverviewCard: View {
    let portfolio: InvestmentPortfolio
    
    var body: some View {
        VStack(spacing: 16) {
            // 總體績效
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(LocalizationManager.shared.localizedString("investment.total_return"))
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("\(portfolio.totalGainLoss >= 0 ? "+" : "")\(portfolio.totalGainLossPercentage, specifier: "%.2f")%")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(portfolio.totalGainLoss >= 0 ? .green : .red)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(LocalizationManager.shared.localizedString("investment.total_value"))
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("$\(portfolio.totalValue, specifier: "%.2f")")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.primary)
                }
            }
            
            // 日變化
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(LocalizationManager.shared.localizedString("investment.day_change"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("+$1,234.56 (+2.34%)")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(LocalizationManager.shared.localizedString("investment.best_performer"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("AAPL (+5.2%)")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
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

// 績效圖表卡片
struct PerformanceChartCard: View {
    let portfolio: InvestmentPortfolio
    let timeframe: PortfolioPerformanceView.Timeframe
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizationManager.shared.localizedString("investment.performance_chart"))
                .font(.headline)
                .fontWeight(.semibold)
            
            if #available(iOS 16.0, *) {
                Chart {
                    // 這裡應該使用實際的歷史數據
                    // 暫時使用模擬數據
                    ForEach(generateMockData(), id: \.date) { dataPoint in
                        LineMark(
                            x: .value("Date", dataPoint.date),
                            y: .value("Value", dataPoint.value)
                        )
                        .foregroundStyle(.blue)
                        .lineStyle(StrokeStyle(lineWidth: 3))
                        
                        AreaMark(
                            x: .value("Date", dataPoint.date),
                            y: .value("Value", dataPoint.value)
                        )
                        .foregroundStyle(.blue.opacity(0.1))
                    }
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                        AxisValueLabel(format: .dateTime.month().day())
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let doubleValue = value.as(Double.self) {
                                Text("$\(doubleValue, specifier: "%.0f")")
                            }
                        }
                    }
                }
            } else {
                // iOS 15 及以下版本的替代圖表
                SimplePerformanceChart(data: generateMockData())
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
    
    private func generateMockData() -> [PerformanceDataPoint] {
        let days = getDaysForTimeframe(timeframe)
        var data: [PerformanceDataPoint] = []
        var currentValue = portfolio.totalValue
        
        for i in 0..<days {
            let date = Calendar.current.date(byAdding: .day, value: -i, to: Date()) ?? Date()
            let change = Double.random(in: -0.05...0.05) // 模擬每日變化
            currentValue *= (1 + change)
            
            data.append(PerformanceDataPoint(date: date, value: currentValue))
        }
        
        return data.reversed()
    }
    
    private func getDaysForTimeframe(_ timeframe: PortfolioPerformanceView.Timeframe) -> Int {
        switch timeframe {
        case .oneWeek: return 7
        case .oneMonth: return 30
        case .threeMonths: return 90
        case .sixMonths: return 180
        case .oneYear: return 365
        case .allTime: return 365
        }
    }
}

// 績效數據點
struct PerformanceDataPoint {
    let date: Date
    let value: Double
}

// 簡單績效圖表（iOS 15 兼容）
struct SimplePerformanceChart: View {
    let data: [PerformanceDataPoint]
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 2) {
            ForEach(Array(data.enumerated()), id: \.offset) { index, dataPoint in
                VStack {
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: 4, height: CGFloat(dataPoint.value / 1000)) // 縮放高度
                        .cornerRadius(2)
                    
                    if index % 7 == 0 { // 每7天顯示一個日期
                        Text(dataPoint.date, formatter: {
                            let formatter = DateFormatter()
                            formatter.dateStyle = .short
                            return formatter
                        }())
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .frame(height: 200)
    }
}

// 績效指標卡片
struct PerformanceMetricsCard: View {
    let portfolio: InvestmentPortfolio
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizationManager.shared.localizedString("investment.performance_metrics"))
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                MetricItem(
                    title: LocalizationManager.shared.localizedString("investment.annualized_return"),
                    value: "8.5%",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .green
                )
                
                MetricItem(
                    title: LocalizationManager.shared.localizedString("investment.volatility"),
                    value: "12.3%",
                    icon: "waveform.path.ecg",
                    color: .orange
                )
                
                MetricItem(
                    title: LocalizationManager.shared.localizedString("investment.sharpe_ratio"),
                    value: "0.69",
                    icon: "chart.bar.fill",
                    color: .blue
                )
                
                MetricItem(
                    title: LocalizationManager.shared.localizedString("investment.max_drawdown"),
                    value: "-15.2%",
                    icon: "arrow.down.circle.fill",
                    color: .red
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

// 指標項目
struct MetricItem: View {
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

// 投資績效比較
struct InvestmentPerformanceComparison: View {
    let portfolio: InvestmentPortfolio
    
    var topPerformers: [Investment] {
        Array(portfolio.investments.sorted { $0.totalReturnPercentage > $1.totalReturnPercentage }.prefix(3))
    }
    
    var worstPerformers: [Investment] {
        Array(portfolio.investments.sorted { $0.totalReturnPercentage < $1.totalReturnPercentage }.prefix(3))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizationManager.shared.localizedString("investment.performance_comparison"))
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                // 最佳表現者
                VStack(alignment: .leading, spacing: 8) {
                    Text(LocalizationManager.shared.localizedString("investment.top_performers"))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                    
                    ForEach(Array(topPerformers), id: \.id) { investment in
                        PerformanceComparisonRow(
                            investment: investment,
                            isPositive: true
                        )
                    }
                }
                
                Divider()
                
                // 最差表現者
                VStack(alignment: .leading, spacing: 8) {
                    Text(LocalizationManager.shared.localizedString("investment.worst_performers"))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.red)
                    
                    ForEach(Array(worstPerformers), id: \.id) { investment in
                        PerformanceComparisonRow(
                            investment: investment,
                            isPositive: false
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

// 績效比較行
struct PerformanceComparisonRow: View {
    let investment: Investment
    let isPositive: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(investment.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(investment.symbol)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(investment.totalReturn >= 0 ? "+" : "")\(investment.totalReturnPercentage, specifier: "%.2f")%")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(investment.totalReturn >= 0 ? .green : .red)
                
                Text("$\(investment.currentValue, specifier: "%.2f")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// 空績效視圖
struct EmptyPerformanceView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                Text(LocalizationManager.shared.localizedString("investment.no_performance_data"))
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(LocalizationManager.shared.localizedString("investment.no_performance_data.description"))
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

// 預覽
#Preview {
    PortfolioPerformanceView(portfolio: nil)
}
