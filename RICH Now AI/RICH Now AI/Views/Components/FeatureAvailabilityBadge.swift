//
//  FeatureAvailabilityBadge.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import SwiftUI

struct FeatureAvailabilityBadge: View {
    let isOnline: Bool
    let featureName: String
    let description: String?
    
    init(isOnline: Bool, featureName: String, description: String? = nil) {
        self.isOnline = isOnline
        self.featureName = featureName
        self.description = description
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isOnline ? "checkmark.circle.fill" : "wifi.slash")
                .foregroundColor(isOnline ? .green : .gray)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(featureName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                if let description = description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 功能可用性列表

struct FeatureAvailabilityList: View {
    @StateObject private var networkMonitor = NetworkMonitor.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("功能可用性")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 8) {
                // 離線可用功能
                FeatureAvailabilityBadge(
                    isOnline: true,
                    featureName: "文字記帳",
                    description: "使用本地規則解析"
                )
                
                FeatureAvailabilityBadge(
                    isOnline: true,
                    featureName: "查看交易記錄",
                    description: "瀏覽本地數據"
                )
                
                FeatureAvailabilityBadge(
                    isOnline: true,
                    featureName: "財務儀表板",
                    description: "查看本地統計"
                )
                
                FeatureAvailabilityBadge(
                    isOnline: true,
                    featureName: "投資組合",
                    description: "查看本地數據"
                )
                
                FeatureAvailabilityBadge(
                    isOnline: true,
                    featureName: "VGLA/TKI 測驗",
                    description: "本地測驗功能"
                )
                
                FeatureAvailabilityBadge(
                    isOnline: true,
                    featureName: "設定管理",
                    description: "本地設定"
                )
                
                Divider()
                
                // 需要網路功能
                FeatureAvailabilityBadge(
                    isOnline: networkMonitor.isConnected,
                    featureName: "AI 對話（加百列）",
                    description: networkMonitor.isConnected ? "需要網路連線" : "離線時不可用"
                )
                
                FeatureAvailabilityBadge(
                    isOnline: networkMonitor.isConnected,
                    featureName: "語音記帳",
                    description: networkMonitor.isConnected ? "需要 Whisper API" : "離線時不可用"
                )
                
                FeatureAvailabilityBadge(
                    isOnline: networkMonitor.isConnected,
                    featureName: "照片記帳",
                    description: networkMonitor.isConnected ? "需要 Vision API" : "離線時不可用"
                )
                
                FeatureAvailabilityBadge(
                    isOnline: networkMonitor.isConnected,
                    featureName: "AI 報告生成",
                    description: networkMonitor.isConnected ? "需要 GPT-4 API" : "離線時不可用"
                )
                
                FeatureAvailabilityBadge(
                    isOnline: networkMonitor.isConnected,
                    featureName: "訂閱管理",
                    description: networkMonitor.isConnected ? "需要 StoreKit" : "離線時不可用"
                )
                
                FeatureAvailabilityBadge(
                    isOnline: networkMonitor.isConnected,
                    featureName: "CloudKit 同步",
                    description: networkMonitor.isConnected ? "需要網路連線" : "離線時不可用"
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - 功能狀態指示器

struct FeatureStatusIndicator: View {
    let isOnline: Bool
    let size: CGFloat
    
    init(isOnline: Bool, size: CGFloat = 12) {
        self.isOnline = isOnline
        self.size = size
    }
    
    var body: some View {
        Circle()
            .fill(isOnline ? Color.green : Color.gray)
            .frame(width: size, height: size)
            .overlay(
                Image(systemName: isOnline ? "checkmark" : "wifi.slash")
                    .font(.system(size: size * 0.6, weight: .bold))
                    .foregroundColor(.white)
            )
    }
}

// MARK: - 預覽

#Preview {
    VStack {
        FeatureAvailabilityList()
        Spacer()
    }
    .padding()
}
