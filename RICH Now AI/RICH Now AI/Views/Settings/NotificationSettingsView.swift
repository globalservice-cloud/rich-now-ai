//
//  NotificationSettingsView.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import SwiftUI

struct NotificationSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var settingsManager = SettingsManager.shared
    @State private var dailyReminders: Bool = true
    @State private var weeklyReports: Bool = true
    @State private var monthlyReports: Bool = true
    @State private var budgetAlerts: Bool = true
    @State private var investmentAlerts: Bool = true
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Toggle("每日提醒", isOn: $dailyReminders)
                        .onChange(of: dailyReminders) {
                            updateNotificationSettings()
                        }
                    
                    Text("每日提醒您記帳和檢查財務狀況")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } header: {
                    Text("日常提醒")
                }
                
                Section {
                    Toggle("週報通知", isOn: $weeklyReports)
                        .onChange(of: weeklyReports) {
                            updateNotificationSettings()
                        }
                    
                    Text("每週發送財務週報到您的電子郵件")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } header: {
                    Text("報告通知")
                }
                
                Section {
                    Toggle("月報通知", isOn: $monthlyReports)
                        .onChange(of: monthlyReports) {
                            updateNotificationSettings()
                        }
                    
                    Text("每月發送詳細財務月報到您的電子郵件")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } header: {
                    Text("月報通知")
                }
                
                Section {
                    Toggle("預算警報", isOn: $budgetAlerts)
                        .onChange(of: budgetAlerts) {
                            updateNotificationSettings()
                        }
                    
                    Text("當支出接近或超過預算時發送警報")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } header: {
                    Text("預算管理")
                }
                
                Section {
                    Toggle("投資警報", isOn: $investmentAlerts)
                        .onChange(of: investmentAlerts) {
                            updateNotificationSettings()
                        }
                    
                    Text("投資組合變動和市場重要資訊通知")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } header: {
                    Text("投資管理")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("通知設定摘要")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        let enabledCount = [dailyReminders, weeklyReports, monthlyReports, budgetAlerts, investmentAlerts].filter { $0 }.count
                        
                        Text("已啟用 \(enabledCount) 個通知設定")
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        if enabledCount == 0 {
                            Text("您已停用所有通知")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("設定摘要")
                }
            }
            .navigationTitle("通知設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadCurrentSettings()
            }
        }
    }
    
    private func loadCurrentSettings() {
        if let settings = settingsManager.currentSettings {
            dailyReminders = settings.dailyReminders
            weeklyReports = settings.weeklyReports
            monthlyReports = settings.monthlyReports
            budgetAlerts = settings.budgetAlerts
            investmentAlerts = settings.investmentAlerts
        }
    }
    
    private func updateNotificationSettings() {
        settingsManager.updateNotificationSettings(
            dailyReminders: dailyReminders,
            weeklyReports: weeklyReports,
            monthlyReports: monthlyReports,
            budgetAlerts: budgetAlerts,
            investmentAlerts: investmentAlerts
        )
    }
}

#Preview {
    NotificationSettingsView()
}
