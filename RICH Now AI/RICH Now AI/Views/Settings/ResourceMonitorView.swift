//
//  ResourceMonitorView.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/12/19.
//

import SwiftUI

/// 資源監控儀表板視圖
struct ResourceMonitorView: View {
    @StateObject private var resourceMonitor = ResourceMonitor.shared
    @State private var showDetails = false
    
    var body: some View {
        List {
            // 系統健康狀態
            Section {
                SystemHealthCard(health: resourceMonitor.systemHealth)
            } header: {
                Text("系統健康狀態")
            }
            
            // 資源使用情況
            Section {
                ResourceUsageCard(usage: resourceMonitor.resourceUsage)
            } header: {
                Text("資源使用情況")
            }
            
            // 活動優化
            if !resourceMonitor.activeOptimizations.isEmpty {
                Section {
                    ActiveOptimizationsCard(optimizations: resourceMonitor.activeOptimizations)
                } header: {
                    Text("活動優化")
                }
            }
            
            // 建議
            if !resourceMonitor.recommendations.isEmpty {
                Section {
                    RecommendationsCard(recommendations: resourceMonitor.recommendations)
                } header: {
                    Text("優化建議")
                }
            }
            
            // 操作按鈕
            Section {
                Button(action: {
                    Task {
                        await resourceMonitor.forceOptimization()
                    }
                }) {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("強制優化")
                    }
                }
            }
        }
        .navigationTitle("資源監控")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - 系統健康卡片

struct SystemHealthCard: View {
    let health: SystemHealth
    
    var body: some View {
        VStack(spacing: 16) {
            // 整體健康狀態
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("整體狀態")
                        .font(.headline)
                    Text(health.overall.displayName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(health.overall.color)
                }
                
                Spacer()
                
                Circle()
                    .fill(health.overall.color)
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: health.overall == .good ? "checkmark.circle.fill" : 
                              health.overall == .warning ? "exclamationmark.triangle.fill" : 
                              "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                    )
            }
            
            Divider()
            
            // 各項健康指標
            HStack(spacing: 20) {
                HealthIndicator(title: "記憶體", status: health.memory)
                HealthIndicator(title: "CPU", status: health.cpu)
                HealthIndicator(title: "網路", status: health.network)
            }
        }
        .padding()
    }
}

struct HealthIndicator: View {
    let title: String
    let status: HealthStatus
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: status == .good ? "checkmark.circle.fill" : 
                  status == .warning ? "exclamationmark.triangle.fill" : 
                  "xmark.circle.fill")
                .font(.title3)
                .foregroundColor(status.color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 資源使用卡片

struct ResourceUsageCard: View {
    let usage: ResourceUsage
    
    var body: some View {
        VStack(spacing: 20) {
            // 記憶體使用
            UsageBar(
                title: "記憶體",
                value: usage.memory.percentage,
                used: formatBytes(usage.memory.usedBytes),
                total: formatBytes(usage.memory.totalBytes),
                color: usage.memory.pressure == .critical ? .red : 
                       usage.memory.pressure == .warning ? .orange : .green
            )
            
            // CPU 使用
            UsageBar(
                title: "CPU",
                value: usage.cpu.percentage,
                used: "\(Int(usage.cpu.percentage * 100))%",
                total: usage.cpu.isLowPowerMode ? "低電量模式" : "正常",
                color: usage.cpu.percentage > 0.7 ? .red : 
                       usage.cpu.percentage > 0.5 ? .orange : .green
            )
            
            // 快取使用
            UsageBar(
                title: "圖片快取",
                value: usage.cache.memoryUsage,
                used: String(format: "%.1f MB", usage.cache.diskSize),
                total: "\(usage.cache.itemCount) 項",
                color: usage.cache.memoryUsage > 0.8 ? .orange : .blue
            )
        }
        .padding()
    }
    
    private func formatBytes(_ bytes: Double) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

struct UsageBar: View {
    let title: String
    let value: Double
    let used: String
    let total: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text("\(used) / \(total)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [color, color.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat(value), height: 8)
                }
            }
            .frame(height: 8)
        }
    }
}

// MARK: - 活動優化卡片

struct ActiveOptimizationsCard: View {
    let optimizations: [Optimization]
    
    var body: some View {
        ForEach(optimizations, id: \.self) { optimization in
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text(optimization.displayName)
                    .font(.subheadline)
                Spacer()
            }
            .padding(.vertical, 4)
        }
    }
}

// MARK: - 建議卡片

struct RecommendationsCard: View {
    let recommendations: [Recommendation]
    
    var body: some View {
        ForEach(recommendations) { recommendation in
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: recommendation.type.icon)
                        .foregroundColor(recommendation.priority.color)
                    Text(recommendation.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(recommendation.priority.color)
                }
                
                Text(recommendation.message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let action = recommendation.action {
                    Button(action: action) {
                        Text("執行")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    .padding(.top, 4)
                }
            }
            .padding(.vertical, 4)
        }
    }
}

