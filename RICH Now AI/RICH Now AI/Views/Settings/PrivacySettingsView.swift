//
//  PrivacySettingsView.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import SwiftUI

struct PrivacySettingsView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var settingsManager = SettingsManager.shared
    @State private var dataSharing: Bool = false
    @State private var analyticsTracking: Bool = true
    @State private var crashReporting: Bool = true
    @State private var biometricAuth: Bool = false
    @State private var sessionTimeout: Int = 30
    @State private var autoLock: Bool = true
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Toggle("數據分享", isOn: $dataSharing)
                        .onChange(of: dataSharing) {
                            updatePrivacySettings()
                        }
                    
                    Text("允許與第三方服務分享匿名數據以改善應用程式")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } header: {
                    Text("數據分享")
                }
                
                Section {
                    Toggle("分析追蹤", isOn: $analyticsTracking)
                        .onChange(of: analyticsTracking) {
                            updatePrivacySettings()
                        }
                    
                    Text("收集使用數據以改善應用程式體驗")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } header: {
                    Text("分析設定")
                }
                
                Section {
                    Toggle("崩潰報告", isOn: $crashReporting)
                        .onChange(of: crashReporting) {
                            updatePrivacySettings()
                        }
                    
                    Text("自動發送崩潰報告以幫助修復問題")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } header: {
                    Text("錯誤報告")
                }
                
                Section {
                    Toggle("生物識別認證", isOn: $biometricAuth)
                        .onChange(of: biometricAuth) {
                            updateSecuritySettings()
                        }
                    
                    Text("使用 Face ID 或 Touch ID 保護您的數據")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } header: {
                    Text("安全設定")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("會話超時")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Picker("會話超時", selection: $sessionTimeout) {
                            Text("15 分鐘").tag(15)
                            Text("30 分鐘").tag(30)
                            Text("1 小時").tag(60)
                            Text("2 小時").tag(120)
                            Text("永不").tag(0)
                        }
                        .pickerStyle(.menu)
                        .onChange(of: sessionTimeout) {
                            updateSecuritySettings()
                        }
                        
                        Text("應用程式自動鎖定的時間間隔")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("會話管理")
                }
                
                Section {
                    Toggle("自動鎖定", isOn: $autoLock)
                        .onChange(of: autoLock) {
                            updateSecuritySettings()
                        }
                    
                    Text("當應用程式進入背景時自動鎖定")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } header: {
                    Text("自動鎖定")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("隱私設定摘要")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        let securityLevel = calculateSecurityLevel()
                        
                        Text("安全等級：\(securityLevel)")
                            .font(.body)
                            .foregroundColor(securityLevel == "高" ? .green : securityLevel == "中" ? .orange : .red)
                        
                        Text("您的隱私和安全設定已優化")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("設定摘要")
                }
            }
            .navigationTitle("隱私與安全")
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
            dataSharing = settings.dataSharing
            analyticsTracking = settings.analyticsTracking
            crashReporting = settings.crashReporting
            biometricAuth = settings.biometricAuth
            sessionTimeout = settings.sessionTimeout
            autoLock = settings.autoLock
        }
    }
    
    private func updatePrivacySettings() {
        settingsManager.updatePrivacySettings(
            dataSharing: dataSharing,
            analyticsTracking: analyticsTracking,
            crashReporting: crashReporting
        )
    }
    
    private func updateSecuritySettings() {
        settingsManager.updateSecuritySettings(
            biometricAuth: biometricAuth,
            sessionTimeout: sessionTimeout,
            autoLock: autoLock
        )
    }
    
    private func calculateSecurityLevel() -> String {
        var score = 0
        
        if biometricAuth { score += 2 }
        if autoLock { score += 1 }
        if sessionTimeout <= 30 { score += 1 }
        if !dataSharing { score += 1 }
        
        if score >= 4 { return "高" }
        if score >= 2 { return "中" }
        return "低"
    }
}

#Preview {
    PrivacySettingsView()
}
