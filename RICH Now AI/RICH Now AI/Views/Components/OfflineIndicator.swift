//
//  OfflineIndicator.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import SwiftUI

struct OfflineIndicator: View {
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @StateObject private var syncManager = SyncManager.shared
    @State private var showingDetails = false
    
    var body: some View {
        if !networkMonitor.isConnected {
            VStack(spacing: 0) {
                // 離線橫幅
                HStack {
                    Image(systemName: "wifi.slash")
                        .foregroundColor(.white)
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("離線模式")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("部分功能需要網路連線")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        showingDetails = true
                    }) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.white)
                            .font(.title3)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.red)
                
                // 同步狀態（如果正在同步）
                if syncManager.isSyncing {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        
                        Text("正在同步數據...")
                            .font(.caption)
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.red.opacity(0.8))
                }
            }
            .sheet(isPresented: $showingDetails) {
                OfflineDetailsView()
            }
        }
    }
}

// MARK: - 離線詳情視圖

struct OfflineDetailsView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var networkMonitor = NetworkMonitor.shared
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "wifi.slash")
                                .foregroundColor(.red)
                                .font(.title2)
                            
                            Text("離線模式說明")
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                        
                        Text("您目前處於離線狀態，部分功能可能無法使用。")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("網路狀態")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        OfflineFeatureRow(
                            title: "文字記帳",
                            isAvailable: true,
                            description: "使用本地規則解析"
                        )
                        
                        OfflineFeatureRow(
                            title: "查看交易記錄",
                            isAvailable: true,
                            description: "瀏覽本地數據"
                        )
                        
                        OfflineFeatureRow(
                            title: "財務儀表板",
                            isAvailable: true,
                            description: "查看本地統計"
                        )
                        
                        OfflineFeatureRow(
                            title: "投資組合",
                            isAvailable: true,
                            description: "查看本地數據"
                        )
                    }
                } header: {
                    Text("離線可用功能")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        OfflineFeatureRow(
                            title: "AI 對話（加百列）",
                            isAvailable: false,
                            description: "需要網路連線"
                        )
                        
                        OfflineFeatureRow(
                            title: "語音記帳",
                            isAvailable: false,
                            description: "需要 Whisper API"
                        )
                        
                        OfflineFeatureRow(
                            title: "照片記帳",
                            isAvailable: false,
                            description: "需要 Vision API"
                        )
                        
                        OfflineFeatureRow(
                            title: "AI 報告生成",
                            isAvailable: false,
                            description: "需要 GPT-4 API"
                        )
                    }
                } header: {
                    Text("需要網路功能")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("數據同步")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("當網路恢復時，應用程式會自動同步您的數據到 iCloud。")
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        Text("• 交易記錄會自動同步")
                        Text("• 設定會自動同步")
                        Text("• 投資組合會自動同步")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                } header: {
                    Text("同步說明")
                }
            }
            .navigationTitle("離線模式")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - 離線功能行

struct OfflineFeatureRow: View {
    let title: String
    let isAvailable: Bool
    let description: String
    
    var body: some View {
        HStack {
            Image(systemName: isAvailable ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(isAvailable ? .green : .red)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 2)
    }
}

// MARK: - 離線橫幅

struct OfflineBanner: View {
    let message: String
    let icon: String
    let onRetry: (() -> Void)?
    
    init(message: String, icon: String, onRetry: (() -> Void)? = nil) {
        self.message = message
        self.icon = icon
        self.onRetry = onRetry
    }
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.white)
                .font(.title3)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.white)
            
            Spacer()
            
            if let onRetry = onRetry {
                Button("重試") {
                    onRetry()
                }
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.2))
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.orange)
    }
}

// MARK: - 預覽

#Preview {
    VStack {
        OfflineIndicator()
        Spacer()
    }
}
