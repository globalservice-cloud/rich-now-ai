//
//  AIPreferenceSettingsView.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/28.
//

import SwiftUI

struct AIPreferenceSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var settingsManager = SettingsManager.shared
    @StateObject private var aiRouter = AIProcessingRouter.shared
    @StateObject private var performanceMonitor = AIPerformanceMonitor.shared
    
    @State private var aiProcessingStrategy: String = "nativeFirst"
    @State private var allowOfflineAI: Bool = true
    @State private var nativeAIConfidenceThreshold: Double = 0.85
    @State private var enableHybridVerification: Bool = false
    @State private var preferNativeAI: Bool = true
    @State private var autoFallbackToOpenAI: Bool = true
    @State private var enablePerformanceMonitoring: Bool = true
    
    @State private var showingPerformanceReport = false
    @State private var showingResetConfirmation = false
    
    var body: some View {
        NavigationView {
            Form {
                // AI 處理策略選擇
                strategySection
                
                // 原生 AI 設定
                nativeAISection
                
                // 混合模式設定
                hybridModeSection
                
                // 性能監控設定
                performanceSection
                
                // 統計和報告
                statisticsSection
                
                // 重置選項
                resetSection
            }
            .navigationTitle("AI 偏好設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("完成") {
                        saveSettings()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("重置") {
                        showingResetConfirmation = true
                    }
                }
            }
        }
        .onAppear {
            loadCurrentSettings()
        }
        .sheet(isPresented: $showingPerformanceReport) {
            PerformanceReportView()
        }
        .alert("重置設定", isPresented: $showingResetConfirmation) {
            Button("取消", role: .cancel) { }
            Button("重置", role: .destructive) {
                resetToDefaults()
            }
        } message: {
            Text("這將重置所有 AI 偏好設定為預設值。您確定要繼續嗎？")
        }
    }
    
    // MARK: - 策略選擇區塊
    
    private var strategySection: some View {
        Section {
            Picker("AI 處理策略", selection: $aiProcessingStrategy) {
                ForEach(AIProcessingRouter.AIProcessingStrategy.allCases, id: \.rawValue) { strategy in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(strategy.displayName)
                            .font(.headline)
                        Text(strategy.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .tag(strategy.rawValue)
                }
            }
            .pickerStyle(.menu)
            
            Text("選擇 AI 處理策略將影響應用的性能和成本。")
                .font(.caption)
                .foregroundColor(.secondary)
        } header: {
            Text("處理策略")
        } footer: {
            Text("建議：新用戶選擇「原生 AI 優先」以獲得最佳體驗和成本效益。")
        }
    }
    
    // MARK: - 原生 AI 設定區塊
    
    private var nativeAISection: some View {
        Section {
            Toggle("偏好使用原生 AI", isOn: $preferNativeAI)
                .onChange(of: preferNativeAI) {
                    if preferNativeAI {
                        aiProcessingStrategy = "nativeFirst"
                    }
                }
            
            Toggle("允許離線 AI", isOn: $allowOfflineAI)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("信心度閾值")
                    Spacer()
                    Text("\(String(format: "%.0f", nativeAIConfidenceThreshold * 100))%")
                        .foregroundColor(.secondary)
                }
                
                Slider(value: $nativeAIConfidenceThreshold, in: 0.5...1.0, step: 0.05)
                
                Text("當原生 AI 信心度低於此值時，將自動切換到 OpenAI")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Toggle("自動降級到 OpenAI", isOn: $autoFallbackToOpenAI)
        } header: {
            Text("原生 AI 設定")
        } footer: {
            Text("原生 AI 處理速度快且無需網路，但可能在某些複雜任務上準確度較低。")
        }
    }
    
    // MARK: - 混合模式設定區塊
    
    private var hybridModeSection: some View {
        Section {
            Toggle("啟用混合驗證", isOn: $enableHybridVerification)
                .onChange(of: enableHybridVerification) {
                    if enableHybridVerification {
                        aiProcessingStrategy = "hybrid"
                    }
                }
            
            if enableHybridVerification {
                VStack(alignment: .leading, spacing: 8) {
                    Text("混合模式說明")
                        .font(.headline)
                    
                    Text("• 同時使用原生 AI 和 OpenAI 進行處理")
                    Text("• 比較兩種結果並選擇最佳答案")
                    Text("• 提供最高準確度但會增加處理時間和成本")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.vertical, 4)
            }
        } header: {
            Text("混合模式")
        } footer: {
            Text("混合模式提供最高準確度，但會增加處理時間和 API 成本。")
        }
    }
    
    // MARK: - 性能監控區塊
    
    private var performanceSection: some View {
        Section {
            Toggle("啟用性能監控", isOn: $enablePerformanceMonitoring)
            
            if enablePerformanceMonitoring {
                Button("查看性能報告") {
                    showingPerformanceReport = true
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("原生 AI 成功率")
                        Spacer()
                        Text("\(String(format: "%.1f", performanceMonitor.metrics.nativeAISuccessRate * 100))%")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("OpenAI 成功率")
                        Spacer()
                        Text("\(String(format: "%.1f", performanceMonitor.metrics.openAISuccessRate * 100))%")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("平均信心度")
                        Spacer()
                        Text("\(String(format: "%.2f", performanceMonitor.metrics.averageConfidence))")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("成本節省")
                        Spacer()
                        Text("$\(String(format: "%.2f", performanceMonitor.metrics.costSavings))")
                            .foregroundColor(.green)
                    }
                }
                .font(.caption)
            }
        } header: {
            Text("性能監控")
        } footer: {
            Text("性能監控幫助您了解 AI 處理效果並優化設定。")
        }
    }
    
    // MARK: - 統計區塊
    
    private var statisticsSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Text("使用統計")
                    .font(.headline)
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("原生 AI 使用")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(performanceMonitor.metrics.nativeAISuccessRate > 0 ? "\(Int(performanceMonitor.metrics.nativeAISuccessRate * 100))%" : "無數據")")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("OpenAI 使用")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(performanceMonitor.metrics.openAISuccessRate > 0 ? "\(Int(performanceMonitor.metrics.openAISuccessRate * 100))%" : "無數據")")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                }
                
                Divider()
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("平均處理時間")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(String(format: "%.2f", (performanceMonitor.metrics.visionProcessingTime + performanceMonitor.metrics.speechProcessingTime) / 2))s")
                            .font(.title3)
                            .fontWeight(.medium)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("總成本節省")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("$\(String(format: "%.2f", performanceMonitor.metrics.costSavings))")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }
                }
            }
            .padding(.vertical, 8)
        } header: {
            Text("使用統計")
        }
    }
    
    // MARK: - 重置區塊
    
    private var resetSection: some View {
        Section {
            Button("重置為預設設定") {
                showingResetConfirmation = true
            }
            .foregroundColor(.red)
            
            Button("清除性能數據") {
                performanceMonitor.resetStatistics()
            }
            .foregroundColor(.orange)
        } header: {
            Text("重置選項")
        } footer: {
            Text("重置設定將恢復所有 AI 偏好為預設值。清除性能數據將重置所有統計信息。")
        }
    }
    
    // MARK: - 輔助方法
    
    private func loadCurrentSettings() {
        // 從 UserDefaults 載入當前設定
        aiProcessingStrategy = UserDefaults.standard.string(forKey: "aiProcessingStrategy") ?? "nativeFirst"
        allowOfflineAI = UserDefaults.standard.bool(forKey: "allowOfflineAI")
        nativeAIConfidenceThreshold = UserDefaults.standard.double(forKey: "nativeAIConfidenceThreshold")
        if nativeAIConfidenceThreshold == 0 {
            nativeAIConfidenceThreshold = 0.85
        }
        enableHybridVerification = UserDefaults.standard.bool(forKey: "enableHybridVerification")
        preferNativeAI = UserDefaults.standard.bool(forKey: "preferNativeAI")
        autoFallbackToOpenAI = UserDefaults.standard.bool(forKey: "autoFallbackToOpenAI")
        enablePerformanceMonitoring = UserDefaults.standard.bool(forKey: "enablePerformanceMonitoring")
    }
    
    private func saveSettings() {
        // 保存設定到 UserDefaults
        UserDefaults.standard.set(aiProcessingStrategy, forKey: "aiProcessingStrategy")
        UserDefaults.standard.set(allowOfflineAI, forKey: "allowOfflineAI")
        UserDefaults.standard.set(nativeAIConfidenceThreshold, forKey: "nativeAIConfidenceThreshold")
        UserDefaults.standard.set(enableHybridVerification, forKey: "enableHybridVerification")
        UserDefaults.standard.set(preferNativeAI, forKey: "preferNativeAI")
        UserDefaults.standard.set(autoFallbackToOpenAI, forKey: "autoFallbackToOpenAI")
        UserDefaults.standard.set(enablePerformanceMonitoring, forKey: "enablePerformanceMonitoring")
        
        // 更新 AI 路由器設定
        if let strategy = AIProcessingRouter.AIProcessingStrategy(rawValue: aiProcessingStrategy) {
            aiRouter.updateStrategy(strategy)
        }
        
        // 更新性能監控設定
        if enablePerformanceMonitoring {
            performanceMonitor.startMonitoring()
        } else {
            performanceMonitor.stopMonitoring()
        }
    }
    
    private func resetToDefaults() {
        aiProcessingStrategy = "nativeFirst"
        allowOfflineAI = true
        nativeAIConfidenceThreshold = 0.85
        enableHybridVerification = false
        preferNativeAI = true
        autoFallbackToOpenAI = true
        enablePerformanceMonitoring = true
        
        saveSettings()
    }
}

// MARK: - 性能報告視圖

struct PerformanceReportView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var performanceMonitor = AIPerformanceMonitor.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let report = performanceMonitor.performanceReport {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("性能報告")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text(report.summary)
                                .font(.body)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                        }
                        
                        // 圖表區域
                        VStack(alignment: .leading, spacing: 16) {
                            Text("趨勢分析")
                                .font(.headline)
                            
                            // 這裡可以添加圖表視圖
                            Text("圖表功能將在後續版本中添加")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                        
                        // 建議區域
                        if !report.recommendations.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("優化建議")
                                    .font(.headline)
                                
                                ForEach(Array(report.recommendations.enumerated()), id: \.offset) { index, recommendation in
                                    HStack(alignment: .top, spacing: 8) {
                                        Text("\(index + 1).")
                                            .fontWeight(.medium)
                                        Text(recommendation)
                                            .font(.body)
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                    } else {
                        Text("暫無性能數據")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
            }
            .navigationTitle("性能報告")
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

#Preview {
    AIPreferenceSettingsView()
}
