//
//  APIUsageView.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import SwiftUI
import SwiftData
import Charts

struct APIUsageView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var usageTracker = APIUsageTracker.shared
    @StateObject private var keyManager = APIKeyManager.shared
    @State private var selectedPeriod: APIUsagePeriod = .daily
    @State private var showingAPIKeySettings = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 用量概覽卡片
                    usageOverviewCard
                    
                    // 用量統計圖表
                    usageChartSection
                    
                    // 配額限制卡片
                    quotaLimitCard
                    
                    // 自備 Key 狀態
                    apiKeyStatusCard
                    
                    // 緊急重置按鈕
                    emergencyResetCard
                    
                    // 用量詳情
                    usageDetailsSection
                }
                .padding()
            }
            .navigationTitle("API 用量追蹤")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("API Key 設定") {
                        showingAPIKeySettings = true
                    }
                }
            }
            .onAppear {
                usageTracker.setModelContext(modelContext)
                keyManager.setModelContext(modelContext)
            }
            .sheet(isPresented: $showingAPIKeySettings) {
                APIKeySettingsView()
            }
        }
    }
    
    // MARK: - 用量概覽卡片
    
    private var usageOverviewCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("用量概覽")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Picker("時間範圍", selection: $selectedPeriod) {
                    ForEach(APIUsagePeriod.allCases, id: \.self) { period in
                        Text(period.displayName).tag(period)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            if let usage = selectedPeriod == .daily ? usageTracker.dailyUsage : usageTracker.monthlyUsage {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    UsageMetricCard(
                        title: "請求次數",
                        value: "\(usage.totalRequests)",
                        icon: "arrow.up.circle.fill",
                        color: .blue
                    )
                    
                    UsageMetricCard(
                        title: "Token 使用",
                        value: "\(usage.totalTokens)",
                        icon: "number.circle.fill",
                        color: .green
                    )
                    
                    UsageMetricCard(
                        title: "總成本",
                        value: "$\(String(format: "%.2f", usage.totalCost))",
                        icon: "dollarsign.circle.fill",
                        color: .orange
                    )
                    
                    UsageMetricCard(
                        title: "自備 Key 使用",
                        value: "\(String(format: "%.1f", usage.userProvidedKeyUsage * 100))%",
                        icon: "key.fill",
                        color: .purple
                    )
                }
            } else {
                ProgressView("載入用量數據中...")
                    .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - 用量統計圖表
    
    private var usageChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("用量趨勢")
                .font(.headline)
                .foregroundColor(.primary)
            
            if let dailyUsage = usageTracker.dailyUsage {
                Chart {
                    BarMark(
                        x: .value("服務", "GPT-4o"),
                        y: .value("請求", dailyUsage.totalRequests / 2)
                    )
                    .foregroundStyle(.blue)
                    
                    BarMark(
                        x: .value("服務", "Whisper"),
                        y: .value("請求", dailyUsage.totalRequests / 4)
                    )
                    .foregroundStyle(.green)
                    
                    BarMark(
                        x: .value("服務", "Vision"),
                        y: .value("請求", dailyUsage.totalRequests / 4)
                    )
                    .foregroundStyle(.orange)
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
            } else {
                ProgressView("載入圖表中...")
                    .frame(height: 200)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - 配額限制卡片
    
    private var quotaLimitCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("配額限制")
                .font(.headline)
                .foregroundColor(.primary)
            
            if let quota = usageTracker.currentQuota {
                VStack(spacing: 8) {
                    QuotaLimitRow(
                        title: "每日請求限制",
                        current: Double(usageTracker.dailyUsage?.totalRequests ?? 0),
                        limit: Double(quota.dailyRequestLimit),
                        unit: "次"
                    )
                    
                    QuotaLimitRow(
                        title: "每日 Token 限制",
                        current: Double(usageTracker.dailyUsage?.totalTokens ?? 0),
                        limit: Double(quota.dailyTokenLimit),
                        unit: "個"
                    )
                    
                    QuotaLimitRow(
                        title: "每日成本限制",
                        current: usageTracker.dailyUsage?.totalCost ?? 0.0,
                        limit: quota.dailyCostLimit,
                        unit: "美元"
                    )
                }
            } else {
                Text("載入配額限制中...")
                    .foregroundColor(.secondary)
            }
            
            if usageTracker.isNearLimit {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    
                    Text(usageTracker.limitWarning ?? "用量接近限制")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - 緊急重置卡片
    
    private var emergencyResetCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("緊急重置")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("如果遇到API使用限制問題，可以嘗試重置用量統計")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(spacing: 12) {
                Button("重置用量統計") {
                    usageTracker.resetUsageLimits()
                }
                .buttonStyle(.bordered)
                .foregroundColor(.blue)
                
                Button("強制重置配額") {
                    usageTracker.forceResetQuota()
                }
                .buttonStyle(.bordered)
                .foregroundColor(.orange)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - 自備 Key 狀態卡片
    
    private var apiKeyStatusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("自備 API Key 狀態")
                .font(.headline)
                .foregroundColor(.primary)
            
            if let activeKey = keyManager.activeKey {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    
                    VStack(alignment: .leading) {
                        Text(activeKey.keyName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("\(activeKey.service) • 使用 \(activeKey.usageCount) 次")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(8)
            } else {
                HStack {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.orange)
                    
                    Text("未設定自備 API Key")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - 用量詳情
    
    private var usageDetailsSection: some View {
        let hasUsageData = (selectedPeriod == .daily ? usageTracker.dailyUsage : usageTracker.monthlyUsage) != nil
        
        return VStack(alignment: .leading, spacing: 12) {
            Text("用量詳情")
                .font(.headline)
                .foregroundColor(.primary)
            
            if hasUsageData {
                Text(usageTracker.getUsageReport(period: selectedPeriod))
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
            } else {
                Text("無用量數據")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - 用量指標卡片

struct UsageMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// MARK: - 配額限制行

struct QuotaLimitRow: View {
    let title: String
    let current: Double
    let limit: Double
    let unit: String
    
    private var progress: Double {
        guard limit > 0 else { return 0 }
        return min(current / limit, 1.0)
    }
    
    private var progressColor: Color {
        if progress >= 0.9 { return .red }
        if progress >= 0.7 { return .orange }
        return .green
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(Int(current)) / \(Int(limit)) \(unit)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: progressColor))
        }
    }
}

// MARK: - 預覽

#Preview {
    APIUsageView()
}
