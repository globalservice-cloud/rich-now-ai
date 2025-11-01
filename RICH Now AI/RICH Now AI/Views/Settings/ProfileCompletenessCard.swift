//
//  ProfileCompletenessCard.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/12/19.
//

import SwiftUI

/// 個人資料完成度提示卡片
struct ProfileCompletenessCard: View {
    let completeness: ProfileCompleteness
    @State private var showDetails = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.orange)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("個人資料尚未完整")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("完成個人資料可獲得更好的使用體驗")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        showDetails.toggle()
                    }
                }) {
                    Image(systemName: showDetails ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // 進度條
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("完成度")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(completeness.completionPercentage))%")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [Color.orange, Color.yellow],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * CGFloat(completeness.completionPercentage / 100), height: 8)
                    }
                }
                .frame(height: 8)
            }
            
            // 詳細資訊（可展開）
            if showDetails && !completeness.missingFields.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                    
                    Text("缺少的資料：")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    ForEach(completeness.missingFields, id: \.self) { field in
                        HStack(spacing: 8) {
                            Image(systemName: "circle")
                                .font(.caption2)
                                .foregroundColor(.orange)
                            Text(field)
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

#Preview {
    ProfileCompletenessCard(
        completeness: ProfileCompleteness(
            isComplete: false,
            missingFields: ["電子郵件", "性別", "報告頻率"],
            completionPercentage: 50.0
        )
    )
    .padding()
}

