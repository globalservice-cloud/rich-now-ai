//
//  SubscriptionAnalyticsView.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import SwiftUI
import SwiftData
import Charts

struct SubscriptionAnalyticsView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var analyticsService = SubscriptionAnalyticsService.shared
    @State private var selectedTimeframe: Timeframe = .month
    @State private var showingUpgradeDowngrade = false
    
    enum Timeframe: String, CaseIterable {
        case week = "week"
        case month = "month"
        case quarter = "quarter"
        case year = "year"
        
        var displayName: String {
            switch self {
            case .week: return "週"
            case .month: return "月"
            case .quarter: return "季"
            case .year: return "年"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 時間範圍選擇器
                    timeframeSelector
                    
                    // 關鍵指標卡片
                    keyMetricsSection
                    
                    // 收入趨勢圖表
                    revenueChartSection
                    
                    // 訂閱分布圖表
                    subscriptionDistributionSection
                    
                    // 升級/降級按鈕
                    upgradeDowngradeSection
                    
                    // 分析報告
                    analyticsReportSection
                }
                .padding()
            }
            .navigationTitle("訂閱分析")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                analyticsService.setModelContext(modelContext)
                Task {
                    await analyticsService.analyzeSubscriptionHistory()
                }
            }
            .sheet(isPresented: $showingUpgradeDowngrade) {
                UpgradeDowngradeView()
            }
        }
    }
    
    // MARK: - 時間範圍選擇器
    
    private var timeframeSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("時間範圍")
                .font(.headline)
                .foregroundColor(.primary)
            
            Picker("時間範圍", selection: $selectedTimeframe) {
                ForEach(Timeframe.allCases, id: \.self) { timeframe in
                    Text(timeframe.displayName).tag(timeframe)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - 關鍵指標卡片
    
    private var keyMetricsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("關鍵指標")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                if let analytics = analyticsService.analytics {
                    MetricCard(
                        title: "總收入",
                        value: "$\(String(format: "%.2f", analytics.totalRevenue))",
                        icon: "dollarsign.circle.fill",
                        color: .green
                    )
                    
                    MetricCard(
                        title: "總交易數",
                        value: "\(analytics.totalTransactions)",
                        icon: "creditcard.fill",
                        color: .blue
                    )
                    
                    MetricCard(
                        title: "平均每用戶收入",
                        value: "$\(String(format: "%.2f", analytics.averageRevenuePerUser))",
                        icon: "person.circle.fill",
                        color: .orange
                    )
                    
                    MetricCard(
                        title: "留存率",
                        value: "\(String(format: "%.1f", analytics.retentionRate * 100))%",
                        icon: "heart.fill",
                        color: .red
                    )
                } else {
                    ProgressView("載入分析數據中...")
                        .frame(maxWidth: .infinity)
                        .gridCellColumns(2)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - 收入趨勢圖表
    
    private var revenueChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("收入趨勢")
                .font(.headline)
                .foregroundColor(.primary)
            
            if let analytics = analyticsService.analytics {
                Chart {
                    BarMark(
                        x: .value("方案", "基礎"),
                        y: .value("收入", analytics.totalRevenue * 0.3)
                    )
                    .foregroundStyle(.blue)
                    
                    BarMark(
                        x: .value("方案", "進階"),
                        y: .value("收入", analytics.totalRevenue * 0.5)
                    )
                    .foregroundStyle(.orange)
                    
                    BarMark(
                        x: .value("方案", "專業"),
                        y: .value("收入", analytics.totalRevenue * 0.2)
                    )
                    .foregroundStyle(.red)
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
    
    // MARK: - 訂閱分布圖表
    
    private var subscriptionDistributionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("訂閱分布")
                .font(.headline)
                .foregroundColor(.primary)
            
            if let analytics = analyticsService.analytics {
                VStack(spacing: 8) {
                    DistributionRow(
                        plan: "基礎方案",
                        count: analytics.monthlyActiveSubscribers / 3,
                        color: .blue
                    )
                    
                    DistributionRow(
                        plan: "進階方案",
                        count: analytics.monthlyActiveSubscribers / 2,
                        color: .orange
                    )
                    
                    DistributionRow(
                        plan: "專業方案",
                        count: analytics.monthlyActiveSubscribers / 6,
                        color: .red
                    )
                }
            } else {
                ProgressView("載入分布數據中...")
                    .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - 升級/降級按鈕
    
    private var upgradeDowngradeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("訂閱管理")
                .font(.headline)
                .foregroundColor(.primary)
            
            Button("升級/降級訂閱") {
                showingUpgradeDowngrade = true
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - 分析報告
    
    private var analyticsReportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("分析報告")
                .font(.headline)
                .foregroundColor(.primary)
            
            if analyticsService.analytics != nil {
                Text(analyticsService.getAnalyticsReport())
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
            } else {
                ProgressView("生成報告中...")
                    .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - 指標卡片

struct MetricCard: View {
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

// MARK: - 分布行

struct DistributionRow: View {
    let plan: String
    let count: Int
    let color: Color
    
    var body: some View {
        HStack {
            Text(plan)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text("\(count)")
                .font(.body)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 升級/降級視圖

struct UpgradeDowngradeView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var analyticsService = SubscriptionAnalyticsService.shared
    @State private var selectedFromPlan = "basic"
    @State private var selectedToPlan = "premium"
    @State private var reason = ""
    @State private var isProcessing = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("從方案") {
                    Picker("從方案", selection: $selectedFromPlan) {
                        Text("基礎方案").tag("basic")
                        Text("進階方案").tag("premium")
                        Text("專業方案").tag("pro")
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("到方案") {
                    Picker("到方案", selection: $selectedToPlan) {
                        Text("基礎方案").tag("basic")
                        Text("進階方案").tag("premium")
                        Text("專業方案").tag("pro")
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("原因（可選）") {
                    TextField("請說明升級/降級原因", text: $reason, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section {
                    Button(isProcessing ? "處理中..." : "確認變更") {
                        processChange()
                    }
                    .disabled(isProcessing || selectedFromPlan == selectedToPlan)
                }
            }
            .navigationTitle("訂閱變更")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .alert("變更結果", isPresented: $showAlert) {
                Button("確定") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func processChange() {
        isProcessing = true
        
        Task {
            let changeType = selectedToPlan > selectedFromPlan ? "upgrade" : "downgrade"
            let success = changeType == "upgrade" ? 
                await analyticsService.upgradeSubscription(from: selectedFromPlan, to: selectedToPlan, reason: reason) :
                await analyticsService.downgradeSubscription(from: selectedFromPlan, to: selectedToPlan, reason: reason)
            
            await MainActor.run {
                isProcessing = false
                if success {
                    alertMessage = "訂閱變更成功！"
                    showAlert = true
                    dismiss()
                } else {
                    alertMessage = "訂閱變更失敗，請稍後再試。"
                    showAlert = true
                }
            }
        }
    }
}

// MARK: - 預覽

#Preview {
    SubscriptionAnalyticsView()
}
