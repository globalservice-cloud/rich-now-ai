//
//  FinancialHealthDetailView.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import SwiftUI
import Charts


private func detailDimensionDisplayName(_ dimension: FinancialHealthDimension) -> String {
    LocalizationManager.shared.localizedString("financial_health.dimension.\(dimension.rawValue)")
}

private func detailDimensionDescription(_ dimension: FinancialHealthDimension) -> String {
    LocalizationManager.shared.localizedString("financial_health.dimension.\(dimension.rawValue).description")
}

private func detailDimensionColor(_ dimension: FinancialHealthDimension) -> Color {
    switch dimension {
    case .income: return .green
    case .expenses: return .orange
    case .savings: return .blue
    case .debt: return .red
    case .investment: return .purple
    case .protection: return .yellow
    }
}

private func detailLevelDisplayName(_ level: FinancialHealthLevel) -> String {
    LocalizationManager.shared.localizedString("financial_health.level.\(level.rawValue)")
}

private func detailLevelDescription(_ level: FinancialHealthLevel) -> String {
    LocalizationManager.shared.localizedString("financial_health.level.\(level.rawValue).description")
}

private func detailLevelColor(_ level: FinancialHealthLevel) -> Color {
    switch level {
    case .excellent: return .green
    case .good: return .blue
    case .fair: return .yellow
    case .poor: return .orange
    case .critical: return .red
    }
}

struct FinancialHealthDetailView: View {
    let score: FinancialHealthScore
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 標題和總體評分
                VStack(spacing: 16) {
                    // 總體評分圓環
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 12)
                            .frame(width: 150, height: 150)
                        
                        Circle()
                            .trim(from: 0, to: CGFloat(score.overall) / 100)
                            .stroke(detailLevelColor(score.level), lineWidth: 12)
                            .frame(width: 150, height: 150)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 1.5), value: score.overall)
                        
                        VStack {
                            Text("\(score.overall)")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(detailLevelColor(score.level))
                            
                            Text(LocalizationManager.shared.localizedString("financial_health.score"))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // 健康等級
                    VStack(spacing: 8) {
                        Text(detailLevelDisplayName(score.level))
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(detailLevelColor(score.level))
                        
                        Text(detailLevelDescription(score.level))
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                }
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(detailLevelColor(score.level).opacity(0.1))
                )
                .padding(.horizontal, 16)
                
                // 標籤選擇器
                Picker("Detail View", selection: $selectedTab) {
                    Text(LocalizationManager.shared.localizedString("financial_health.detail.dimensions")).tag(0)
                    Text(LocalizationManager.shared.localizedString("financial_health.detail.breakdown")).tag(1)
                    Text(LocalizationManager.shared.localizedString("financial_health.detail.insights")).tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
                // 內容視圖
                TabView(selection: $selectedTab) {
                    // 維度詳情
                    DimensionsDetailView(dimensions: score.dimensions)
                        .tag(0)
                    
                    // 評分分解
                    ScoreBreakdownView(score: score)
                        .tag(1)
                    
                    // 洞察分析
                    InsightsView(score: score)
                        .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle(LocalizationManager.shared.localizedString("financial_health.detail.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizationManager.shared.localizedString("common.close")) {
                        dismiss()
                    }
                }
            }
        }
    }
}

// 維度詳情視圖
struct DimensionsDetailView: View {
    let dimensions: [FinancialHealthDimension: Int]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(Array(FinancialHealthDimension.allCases), id: \.self) { dimension in
                    DimensionDetailCard(
                        dimension: dimension,
                        score: dimensions[dimension] ?? 0
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
    }
}

// 維度詳情卡片
struct DimensionDetailCard: View {
    let dimension: FinancialHealthDimension
    let score: Int
    
    var level: FinancialHealthLevel {
        FinancialHealthLevel.level(for: score)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 標題和評分
            HStack {
                Image(systemName: dimension.icon)
                    .font(.title2)
                    .foregroundColor(detailDimensionColor(dimension))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(detailDimensionDisplayName(dimension))
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(detailDimensionDescription(dimension))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(score)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(detailLevelColor(level))
                    
                    Text(detailLevelDisplayName(level))
                        .font(.caption)
                        .foregroundColor(detailLevelColor(level))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(detailLevelColor(level).opacity(0.1))
                        .cornerRadius(8)
                }
            }
            
            // 進度條
            ProgressView(value: Double(score), total: 100)
                .progressViewStyle(LinearProgressViewStyle(tint: detailLevelColor(level)))
                .frame(height: 8)
            
            // 評分說明
            VStack(alignment: .leading, spacing: 8) {
                Text(LocalizationManager.shared.localizedString("financial_health.dimension.\(dimension.rawValue).criteria"))
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(LocalizationManager.shared.localizedString("financial_health.dimension.\(dimension.rawValue).description.detail"))
                    .font(.caption)
                    .foregroundColor(.secondary)
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

// 評分分解視圖
struct ScoreBreakdownView: View {
    let score: FinancialHealthScore
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 總體評分分解
                VStack(alignment: .leading, spacing: 16) {
                    Text(LocalizationManager.shared.localizedString("financial_health.breakdown.overall"))
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    VStack(spacing: 12) {
                        ForEach(Array(FinancialHealthDimension.allCases), id: \.self) { dimension in
                            let dimensionScore = score.dimensions[dimension] ?? 0
                            let levelColor = detailLevelColor(FinancialHealthLevel.level(for: dimensionScore))
                            
                            HStack {
                                Image(systemName: dimension.icon)
                                    .foregroundColor(detailDimensionColor(dimension))
                                    .frame(width: 24)
                                
                                Text(detailDimensionDisplayName(dimension))
                                    .font(.subheadline)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                Text("\(dimensionScore)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(levelColor)
                                    .frame(width: 30)
                                
                                ProgressView(value: Double(dimensionScore), total: 100)
                                    .progressViewStyle(LinearProgressViewStyle(tint: detailDimensionColor(dimension)))
                                    .frame(width: 80)
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
                
                // 評分說明
                VStack(alignment: .leading, spacing: 12) {
                    Text(LocalizationManager.shared.localizedString("financial_health.breakdown.explanation.title"))
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(LocalizationManager.shared.localizedString("financial_health.breakdown.explanation.content"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                )
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
    }
}

// 洞察分析視圖
struct InsightsView: View {
    let score: FinancialHealthScore
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 優勢分析
                VStack(alignment: .leading, spacing: 16) {
                    Text(LocalizationManager.shared.localizedString("financial_health.insights.strengths"))
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    let strengths = getStrengths(from: score.dimensions)
                    
                    if strengths.isEmpty {
                        Text(LocalizationManager.shared.localizedString("financial_health.insights.no_strengths"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        VStack(spacing: 8) {
                            ForEach(strengths, id: \.self) { strength in
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    
                                    Text(strength)
                                        .font(.subheadline)
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.green.opacity(0.1))
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
                
                // 改善領域
                VStack(alignment: .leading, spacing: 16) {
                    Text(LocalizationManager.shared.localizedString("financial_health.insights.improvements"))
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    let improvements = getImprovements(from: score.dimensions)
                    
                    if improvements.isEmpty {
                        Text(LocalizationManager.shared.localizedString("financial_health.insights.no_improvements"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        VStack(spacing: 8) {
                            ForEach(improvements, id: \.self) { improvement in
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.orange)
                                    
                                Text(improvement)
                                        .font(.subheadline)
                                    
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
                
                // 建議行動
                if !score.recommendations.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(LocalizationManager.shared.localizedString("financial_health.insights.recommendations"))
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 8) {
                            ForEach(score.recommendations, id: \.self) { recommendation in
                                HStack {
                                    Image(systemName: "lightbulb.fill")
                                        .foregroundColor(.blue)
                                    
                                    Text(LocalizationManager.shared.localizedString(recommendation))
                                        .font(.subheadline)
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.blue.opacity(0.1))
                                )
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
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
    }
    
    private func getStrengths(from dimensions: [FinancialHealthDimension: Int]) -> [String] {
        return dimensions.compactMap { (dimension, score) in
            if score >= 80 {
                return LocalizationManager.shared.localizedString("financial_health.insights.strength.\(dimension.rawValue)")
            }
            return nil
        }
    }
    
    private func getImprovements(from dimensions: [FinancialHealthDimension: Int]) -> [String] {
        return dimensions.compactMap { (dimension, score) in
            if score < 70 {
                return LocalizationManager.shared.localizedString("financial_health.insights.improvement.\(dimension.rawValue)")
            }
            return nil
        }
    }
}

// 預覽
#Preview {
    FinancialHealthDetailView(score: FinancialHealthScore(
        overall: 75,
        dimensions: [
            .income: 80,
            .expenses: 70,
            .savings: 60,
            .debt: 85,
            .investment: 65,
            .protection: 70
        ],
        recommendations: ["recommendation.savings.rate", "recommendation.investment.optimization"],
        lastUpdated: Date(),
        gabrielInsight: "您的財務健康狀況良好，建議繼續保持。"
    ))
}
