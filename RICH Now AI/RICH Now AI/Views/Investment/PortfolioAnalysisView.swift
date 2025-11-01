//
//  PortfolioAnalysisView.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import SwiftUI
import Charts

struct PortfolioAnalysisView: View {
    let portfolio: InvestmentPortfolio?
    @StateObject private var portfolioManager = InvestmentPortfolioManager.shared
    @State private var analysis: PortfolioAnalysis?
    @State private var showingRebalancing = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let portfolio = portfolio {
                    // 分析概覽
                    AnalysisOverviewCard(portfolio: portfolio)
                    
                    // 風險分析
                    RiskAnalysisCard(portfolio: portfolio)
                    
                    // 分散化分析
                    DiversificationAnalysisCard(portfolio: portfolio)
                    
                    // 資產配置分析
                    AssetAllocationAnalysisCard(portfolio: portfolio)
                    
                    // 再平衡建議
                    RebalancingRecommendationsCard(
                        portfolio: portfolio,
                        showingRebalancing: $showingRebalancing
                    )
                    
                    // 投資建議
                    InvestmentRecommendationsCard(portfolio: portfolio)
                } else {
                    EmptyAnalysisView()
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
        .onAppear {
            if let portfolio = portfolio {
                analysis = portfolioManager.getPortfolioAnalysis(portfolio)
            }
        }
        .sheet(isPresented: $showingRebalancing) {
            RebalancingView(portfolio: portfolio)
        }
    }
}

// 分析概覽卡片
struct AnalysisOverviewCard: View {
    let portfolio: InvestmentPortfolio
    @StateObject private var portfolioManager = InvestmentPortfolioManager.shared
    
    var analysis: PortfolioAnalysis? {
        portfolioManager.getPortfolioAnalysis(portfolio)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizationManager.shared.localizedString("investment.analysis_overview"))
                .font(.headline)
                .fontWeight(.semibold)
            
            if let analysis = analysis {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
                    AnalysisScoreItem(
                        title: LocalizationManager.shared.localizedString("investment.diversification"),
                        score: analysis.diversificationScore,
                        color: .blue
                    )
                    
                    AnalysisScoreItem(
                        title: LocalizationManager.shared.localizedString("investment.risk"),
                        score: analysis.riskScore,
                        color: .orange
                    )
                    
                    AnalysisScoreItem(
                        title: LocalizationManager.shared.localizedString("investment.performance"),
                        score: analysis.performanceScore,
                        color: .green
                    )
                }
                
                // 總體評分
                HStack {
                    Text(LocalizationManager.shared.localizedString("investment.overall_score"))
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    let overallScore = (analysis.diversificationScore + analysis.riskScore + analysis.performanceScore) / 3
                    Text("\(overallScore * 100, specifier: "%.0f")%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(getScoreColor(overallScore))
                }
                .padding(.top, 8)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
    
    private func getScoreColor(_ score: Double) -> Color {
        if score >= 0.8 {
            return .green
        } else if score >= 0.6 {
            return .orange
        } else {
            return .red
        }
    }
}

// 分析評分項目
struct AnalysisScoreItem: View {
    let title: String
    let score: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.3), lineWidth: 8)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0, to: score)
                    .stroke(color, lineWidth: 8)
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0), value: score)
                
                Text("\(Int(score * 100))")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

// 風險分析卡片
struct RiskAnalysisCard: View {
    let portfolio: InvestmentPortfolio
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizationManager.shared.localizedString("investment.risk_analysis"))
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
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
                        .padding(.vertical, 6)
                        .background(portfolio.riskLevel.color.opacity(0.1))
                        .cornerRadius(8)
                }
                
                // 風險評分
                HStack {
                    Text(LocalizationManager.shared.localizedString("investment.risk_score"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(portfolio.riskScore, specifier: "%.1f")/5.0")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(getRiskColor(portfolio.riskScore))
                }
                
                // 風險描述
                Text(portfolio.riskLevel.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
    
    private func getRiskColor(_ score: Double) -> Color {
        if score <= 2.0 {
            return .green
        } else if score <= 3.0 {
            return .orange
        } else {
            return .red
        }
    }
}

// 分散化分析卡片
struct DiversificationAnalysisCard: View {
    let portfolio: InvestmentPortfolio
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizationManager.shared.localizedString("investment.diversification_analysis"))
                .font(.headline)
                .fontWeight(.semibold)
            
            let score = calculateDiversificationScore()
            VStack(spacing: 12) {
                // 分散化評分
                HStack {
                    Text(LocalizationManager.shared.localizedString("investment.diversification_score"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(score * 100))%")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(getDiversificationColor(score))
                }
                
                // 投資類型數量
                HStack {
                    Text(LocalizationManager.shared.localizedString("investment.investment_types"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(portfolio.assetAllocation.count)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                // 最大配置
                if let maxAllocation = portfolio.assetAllocation.max(by: { $0.value < $1.value }) {
                    HStack {
                        Text(LocalizationManager.shared.localizedString("investment.largest_allocation"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(maxAllocation.key.displayName): \(maxAllocation.value, specifier: "%.1f")%")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
                
                // 分散化建議
                if score < 0.6 {
                    Text(LocalizationManager.shared.localizedString("investment.diversification_recommendation"))
                        .font(.caption)
                        .foregroundColor(.orange)
                        .padding(.top, 4)
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
    
    private func calculateDiversificationScore() -> Double {
        let allocation = portfolio.assetAllocation
        let numberOfTypes = allocation.count
        let maxAllocation = allocation.values.max() ?? 0
        
        let typeScore = min(1.0, Double(numberOfTypes) / 6.0)
        let concentrationScore = max(0, 1.0 - (maxAllocation / 100.0))
        
        return (typeScore + concentrationScore) / 2.0
    }
    
    private func getDiversificationColor(_ score: Double) -> Color {
        if score >= 0.8 {
            return .green
        } else if score >= 0.6 {
            return .orange
        } else {
            return .red
        }
    }
}

// 資產配置分析卡片
struct AssetAllocationAnalysisCard: View {
    let portfolio: InvestmentPortfolio
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizationManager.shared.localizedString("investment.asset_allocation_analysis"))
                .font(.headline)
                .fontWeight(.semibold)
            
            if portfolio.assetAllocation.isEmpty {
                Text(LocalizationManager.shared.localizedString("investment.no_allocations"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(portfolio.assetAllocation.sorted(by: { $0.value > $1.value })), id: \.key) { type, percentage in
                        AssetAllocationAnalysisRow(
                            type: type,
                            percentage: percentage,
                            isOverAllocated: percentage > 50
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

// 資產配置分析行
struct AssetAllocationAnalysisRow: View {
    let type: InvestmentType
    let percentage: Double
    let isOverAllocated: Bool
    
    var body: some View {
        HStack {
            Image(systemName: type.icon)
                .foregroundColor(type.color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(type.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if isOverAllocated {
                    Text(LocalizationManager.shared.localizedString("investment.over_allocated"))
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(percentage, specifier: "%.1f")%")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isOverAllocated ? .orange : .primary)
                
                ProgressView(value: percentage, total: 100)
                    .progressViewStyle(LinearProgressViewStyle(tint: isOverAllocated ? .orange : type.color))
                    .frame(width: 80)
            }
        }
    }
}

// 再平衡建議卡片
struct RebalancingRecommendationsCard: View {
    let portfolio: InvestmentPortfolio
    @Binding var showingRebalancing: Bool
    @StateObject private var portfolioManager = InvestmentPortfolioManager.shared
    
    var recommendations: [RebalancingRecommendation] {
        portfolioManager.getRebalancingRecommendations(for: portfolio)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(LocalizationManager.shared.localizedString("investment.rebalancing_recommendations"))
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if !recommendations.isEmpty {
                    Button(action: { showingRebalancing = true }) {
                        Text(LocalizationManager.shared.localizedString("investment.view_all"))
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            if recommendations.isEmpty {
                Text(LocalizationManager.shared.localizedString("investment.no_rebalancing_needed"))
                    .font(.subheadline)
                    .foregroundColor(.green)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 8) {
                    ForEach(recommendations.prefix(3), id: \.investmentType) { recommendation in
                        RebalancingRecommendationRow(recommendation: recommendation)
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

// 再平衡建議行
struct RebalancingRecommendationRow: View {
    let recommendation: RebalancingRecommendation
    
    var body: some View {
        HStack {
            Image(systemName: recommendation.investmentType.icon)
                .foregroundColor(recommendation.investmentType.color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(recommendation.investmentType.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(recommendation.currentPercentage, specifier: "%.1f")% → \(recommendation.targetPercentage, specifier: "%.1f")%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(recommendation.action.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(recommendation.action == .increase ? .green : .red)
                
                Text("\(abs(recommendation.difference), specifier: "%.1f")%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// 再平衡明細視圖
struct RebalancingView: View {
    let portfolio: InvestmentPortfolio?
    @Environment(\.dismiss) private var dismiss
    @StateObject private var portfolioManager = InvestmentPortfolioManager.shared
    
    private var recommendations: [RebalancingRecommendation] {
        guard let portfolio else { return [] }
        return portfolioManager.getRebalancingRecommendations(for: portfolio)
    }
    
    private var analysis: PortfolioAnalysis? {
        guard let portfolio else { return nil }
        return portfolioManager.getPortfolioAnalysis(portfolio)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let portfolio {
                        if !portfolio.assetAllocation.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text(LocalizationManager.shared.localizedString("investment.current_allocation"))
                                    .font(.headline)
                                AllocationBreakdownView(allocation: portfolio.assetAllocation)
                            }
                        }
                        
                        if let analysis, !analysis.targetAllocation.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text(LocalizationManager.shared.localizedString("investment.target_allocation"))
                                    .font(.headline)
                                AllocationBreakdownView(allocation: analysis.targetAllocation)
                            }
                        }
                        
                        if recommendations.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 48))
                                    .foregroundColor(.green)
                                
                                Text(LocalizationManager.shared.localizedString("investment.no_rebalancing_needed"))
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 40)
                        } else {
                            VStack(alignment: .leading, spacing: 16) {
                                Text(LocalizationManager.shared.localizedString("investment.rebalancing_recommendations"))
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                ForEach(recommendations, id: \.investmentType) { recommendation in
                                    RebalancingRecommendationRow(recommendation: recommendation)
                                        .padding(.vertical, 4)
                                    
                                    Divider()
                                }
                            }
                        }
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "questionmark.circle")
                                .font(.system(size: 48))
                                .foregroundColor(.orange)
                            Text(LocalizationManager.shared.localizedString("investment.no_portfolio_selected"))
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 40)
                    }
                }
                .padding(20)
            }
            .navigationTitle(LocalizationManager.shared.localizedString("investment.rebalancing"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { dismiss() }) {
                        Text(LocalizationManager.shared.localizedString("common.close"))
                    }
                }
            }
        }
    }
}

private struct AllocationBreakdownView: View {
    let allocation: [InvestmentType: Double]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(allocation.sorted(by: { $0.value > $1.value }), id: \.key) { item in
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: item.key.icon)
                            .foregroundColor(item.key.color)
                        Text(item.key.displayName)
                    }
                    
                    Spacer()
                    
                    Text("\(item.value, specifier: "%.1f")%")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
        }
    }
}

// 投資建議卡片
struct InvestmentRecommendationsCard: View {
    let portfolio: InvestmentPortfolio
    @StateObject private var portfolioManager = InvestmentPortfolioManager.shared
    
    var analysis: PortfolioAnalysis? {
        portfolioManager.getPortfolioAnalysis(portfolio)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizationManager.shared.localizedString("investment.recommendations"))
                .font(.headline)
                .fontWeight(.semibold)
            
            if let analysis = analysis, !analysis.recommendations.isEmpty {
                VStack(spacing: 8) {
                    ForEach(analysis.recommendations, id: \.self) { recommendation in
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.yellow)
                                .frame(width: 24)
                            
                            Text(recommendation)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.yellow.opacity(0.1))
                        )
                    }
                }
            } else {
                Text(LocalizationManager.shared.localizedString("investment.no_recommendations"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
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

// 空分析視圖
struct EmptyAnalysisView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                Text(LocalizationManager.shared.localizedString("investment.no_analysis_data"))
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(LocalizationManager.shared.localizedString("investment.no_analysis_data.description"))
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
    PortfolioAnalysisView(portfolio: nil)
}
