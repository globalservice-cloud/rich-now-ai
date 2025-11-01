//
//  FinancialHealthRecommendationsView.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import SwiftUI

struct FinancialHealthRecommendationsView: View {
    let recommendations: [String]
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPriority: RecommendationPriority? = nil
    
    enum RecommendationPriority: String, CaseIterable {
        case high = "high"
        case medium = "medium"
        case low = "low"
        
        var displayName: String {
            return LocalizationManager.shared.localizedString("recommendation.priority.\(self.rawValue)")
        }
        
        var color: Color {
            switch self {
            case .high: return .red
            case .medium: return .orange
            case .low: return .green
            }
        }
    }
    
    var filteredRecommendations: [String] {
        if selectedPriority != nil {
            // 這裡可以根據優先級過濾建議
            return recommendations
        }
        return recommendations
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 優先級篩選器
                if !recommendations.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            // 全部
                            FilterChip(
                                title: LocalizationManager.shared.localizedString("recommendation.filter.all"),
                                isSelected: selectedPriority == nil,
                                color: .blue
                            ) {
                                selectedPriority = nil
                            }
                            
                            // 高優先級
                            FilterChip(
                                title: LocalizationManager.shared.localizedString("recommendation.priority.high"),
                                isSelected: selectedPriority == .high,
                                color: .red
                            ) {
                                selectedPriority = .high
                            }
                            
                            // 中優先級
                            FilterChip(
                                title: LocalizationManager.shared.localizedString("recommendation.priority.medium"),
                                isSelected: selectedPriority == .medium,
                                color: .orange
                            ) {
                                selectedPriority = .medium
                            }
                            
                            // 低優先級
                            FilterChip(
                                title: LocalizationManager.shared.localizedString("recommendation.priority.low"),
                                isSelected: selectedPriority == .low,
                                color: .green
                            ) {
                                selectedPriority = .low
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.vertical, 12)
                }
                
                // 建議列表
                if recommendations.isEmpty {
                    EmptyRecommendationsView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(Array(filteredRecommendations.enumerated()), id: \.offset) { index, recommendation in
                                RecommendationCard(
                                    recommendation: recommendation,
                                    priority: getPriority(for: recommendation),
                                    index: index + 1
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle(LocalizationManager.shared.localizedString("financial_health.recommendations.title"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizationManager.shared.localizedString("common.close")) {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func getPriority(for recommendation: String) -> RecommendationPriority {
        if recommendation.contains(".income") || recommendation.contains(".debt") {
            return .high
        } else if recommendation.contains(".expenses") || recommendation.contains(".savings") {
            return .medium
        }
        return .low
    }
}

// 篩選晶片
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let onTap: () -> Void
    
    var body: some View {
        Button { onTap() } label: {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : color)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? color : color.opacity(0.1))
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// 建議卡片
struct RecommendationCard: View {
    let recommendation: String
    let priority: FinancialHealthRecommendationsView.RecommendationPriority
    let index: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 標題和優先級
            HStack {
                // 編號
                Text("\(index)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
                    .background(
                        Circle()
                            .fill(priority.color)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(LocalizationManager.shared.localizedString("recommendation.title"))
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(priority.displayName)
                        .font(.caption)
                        .foregroundColor(priority.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(priority.color.opacity(0.1))
                        .cornerRadius(8)
                }
                
                Spacer()
            }
            
            // 建議內容
            Text(LocalizationManager.shared.localizedString(recommendation))
                .font(.body)
                .foregroundColor(.primary)
                .lineLimit(nil)
            
            // 行動按鈕
            HStack {
                Button {
                    // 標記為已讀
                } label: {
                    HStack {
                        Image(systemName: "checkmark")
                        Text(LocalizationManager.shared.localizedString("recommendation.mark_read"))
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue.opacity(0.1))
                    )
                }
                
                Spacer()
                
                Button {
                    // 了解更多
                } label: {
                    HStack {
                        Text(LocalizationManager.shared.localizedString("recommendation.learn_more"))
                        Image(systemName: "arrow.right")
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
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

// 空建議視圖
struct EmptyRecommendationsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            VStack(spacing: 8) {
                Text(LocalizationManager.shared.localizedString("financial_health.recommendations.none"))
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(LocalizationManager.shared.localizedString("financial_health.recommendations.none.description"))
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            Button {
                // 重新評估
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text(LocalizationManager.shared.localizedString("financial_health.recommendations.reassess"))
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
    FinancialHealthRecommendationsView(recommendations: [
        "recommendation.savings.emergency",
        "recommendation.investment.optimization",
        "recommendation.protection.insurance"
    ])
}
