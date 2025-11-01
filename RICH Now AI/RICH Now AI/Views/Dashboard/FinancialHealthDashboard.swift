//
//  FinancialHealthDashboard.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import SwiftUI
import Charts
import Combine

// FinancialHealthDimension 和 FinancialHealthScore 已移至 Models/FinancialHealth.swift
// FinancialHealthCalculator 已移至 Models/FinancialHealth.swift

// FinancialHealthDashboardView 已移至 FinancialHealthDashboardView.swift

// MARK: - 財務健康分數卡片
struct FinancialHealthScoreCard: View {
    let score: FinancialHealthScore
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("財務健康評分")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(score.overall)/100")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(scoreColor)
            }
            
            // 進度條
            ProgressView(value: Double(score.overall), total: 100)
                .progressViewStyle(LinearProgressViewStyle(tint: scoreColor))
            
            // 加百列洞察
            if !score.gabrielInsight.isEmpty {
                Text(score.gabrielInsight)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
    
    private var scoreColor: Color {
        switch score.overall {
        case 80...100: return .green
        case 60...79: return .orange
        default: return .red
        }
    }
}

// MARK: - 財務健康概覽視圖
struct FinancialHealthOverviewView: View {
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // 這裡可以添加概覽內容
                Text("財務健康概覽")
                    .font(.title2)
                    .padding()
            }
        }
    }
}

// FinancialHealthRecommendationsView 已移至 FinancialHealthRecommendationsView.swift

#Preview {
    FinancialHealthDashboardView()
}