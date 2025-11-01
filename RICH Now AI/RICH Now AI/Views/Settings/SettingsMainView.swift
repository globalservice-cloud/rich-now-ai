//
//  SettingsMainView.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import SwiftUI
import SwiftData

struct SettingsMainView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var settingsManager = SettingsManager.shared
    @State private var showingProfileSettings = false
    @State private var showingAppearanceSettings = false
    @State private var showingGabrielSettings = false
    @State private var showingNotificationSettings = false
    @State private var showingPrivacySettings = false
    @State private var showingSecuritySettings = false
    @State private var showingBackupSettings = false
    @State private var showingInvoiceCarrier = false
    @State private var showingAPIUsage = false
    @State private var showingAIPreferences = false
    @State private var showingAbout = false
    @State private var showingWelcomeReplayConfirmation = false
    
    var body: some View {
        NavigationView {
            List {
                // 個人資料設定
                Section {
                    ProfileSettingsRow(
                        userName: settingsManager.currentSettings?.userName ?? "",
                        userEmail: settingsManager.currentSettings?.reportEmail ?? "",
                        showCompletionIndicator: true
                    ) {
                        showingProfileSettings = true
                    }
                } header: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("個人資料")
                        if OnboardingProgressManager.shared.hasIncompleteOnboarding {
                            let completeness = OnboardingProgressManager.shared.checkProfileCompleteness()
                            if completeness.completionPercentage < 100 {
                                HStack(spacing: 4) {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .font(.caption2)
                                        .foregroundColor(.orange)
                                    Text("完成度: \(Int(completeness.completionPercentage))%")
                                        .font(.caption2)
                                        .foregroundColor(.orange)
                                }
                            }
                        }
                    }
                }
                
                // 外觀設定
                Section {
                    AppearanceSettingsRow(
                        designStyle: DesignStyle(rawValue: settingsManager.currentSettings?.designStyle ?? "modern") ?? .modern,
                        colorScheme: ColorScheme(rawValue: settingsManager.currentSettings?.colorScheme ?? "system") ?? .system,
                        fontSize: FontSize(rawValue: settingsManager.currentSettings?.fontSize ?? "medium") ?? .medium
                    ) {
                        showingAppearanceSettings = true
                    }
                } header: {
                    Text("外觀設定")
                }
                
                // 加百列設定
                Section {
                    GabrielSettingsRow(
                        gender: GabrielGender(rawValue: settingsManager.currentSettings?.gabrielGender ?? "male") ?? .male,
                        outfit: GabrielOutfit(rawValue: settingsManager.currentSettings?.gabrielOutfit ?? "classic") ?? .classic,
                        personality: GabrielPersonality(rawValue: settingsManager.currentSettings?.gabrielPersonality ?? "wise") ?? .wise
                    ) {
                        showingGabrielSettings = true
                    }
                } header: {
                    Text("加百列設定")
                }
                
                // 通知設定
                Section {
                    NotificationSettingsRow(
                        dailyReminders: settingsManager.currentSettings?.dailyReminders ?? true,
                        weeklyReports: settingsManager.currentSettings?.weeklyReports ?? true,
                        monthlyReports: settingsManager.currentSettings?.monthlyReports ?? true
                    ) {
                        showingNotificationSettings = true
                    }
                } header: {
                    Text("通知設定")
                }
                
                // 隱私與安全
                Section {
                    PrivacySecurityRow(
                        biometricAuth: settingsManager.currentSettings?.biometricAuth ?? false,
                        dataSharing: settingsManager.currentSettings?.dataSharing ?? false
                    ) {
                        showingPrivacySettings = true
                    }
                } header: {
                    Text("隱私與安全")
                }
                
                // 備份與同步
                Section {
                    BackupSyncRow(
                        autoBackup: settingsManager.currentSettings?.autoBackup ?? true,
                        cloudSync: settingsManager.currentSettings?.cloudSync ?? true
                    ) {
                        showingBackupSettings = true
                    }
                } header: {
                    Text("備份與同步")
                }
                
                // 記帳設定
                Section {
                    InvoiceCarrierRow {
                        showingInvoiceCarrier = true
                    }
                } header: {
                    Text("記帳設定")
                }
                
                // AI 偏好設定
                Section {
                    AIPreferenceRow {
                        showingAIPreferences = true
                    }
                } header: {
                    Text("AI 設定")
                }
                
                // API 用量追蹤
                Section {
                    APIUsageRow {
                        showingAPIUsage = true
                    }
                } header: {
                    Text("API 管理")
                }
                
                // 應用體驗
                Section {
                    Button(action: {
                        // 顯示確認提示
                        showingWelcomeReplayConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise.circle.fill")
                                .foregroundColor(.blue)
                                .font(.title3)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("重置迎賓流程")
                                    .font(.body)
                                    .foregroundColor(.primary)
                                
                                Text("重新體驗應用程式介紹和設定流程")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                } header: {
                    Text("應用體驗")
                } footer: {
                    Text("重置後，迎賓流程將在下次啟動應用時顯示")
                }
                
                // 關於與支援
                Section {
                    AboutSupportRow {
                        showingAbout = true
                    }
                } header: {
                    Text("關於與支援")
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                settingsManager.setModelContext(modelContext)
            }
            .sheet(isPresented: $showingProfileSettings) {
                ProfileSettingsView()
                    .environmentObject(LocalizationManager.shared)
            }
            .sheet(isPresented: $showingAppearanceSettings) {
                AppearanceSettingsView()
            }
            .sheet(isPresented: $showingGabrielSettings) {
                GabrielSettingsView()
            }
            .sheet(isPresented: $showingNotificationSettings) {
                NotificationSettingsView()
            }
            .sheet(isPresented: $showingPrivacySettings) {
                PrivacySettingsView()
            }
            .sheet(isPresented: $showingSecuritySettings) {
                SecuritySettingsView()
            }
            .sheet(isPresented: $showingBackupSettings) {
                BackupSettingsView()
            }
            .sheet(isPresented: $showingInvoiceCarrier) {
                InvoiceCarrierManagementView()
            }
            .sheet(isPresented: $showingAPIUsage) {
                APIUsageView()
            }
            .sheet(isPresented: $showingAIPreferences) {
                AIPreferenceSettingsView()
            }
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
            .alert("重置迎賓流程", isPresented: $showingWelcomeReplayConfirmation) {
                Button("確定") {
                    // 重置所有迎賓相關狀態
                    UserDefaults.standard.set(false, forKey: "hasSeenWelcomeAnimation")
                    UserDefaults.standard.set(false, forKey: "hasCompletedFirstLaunch")
                    UserDefaults.standard.set(false, forKey: "hasPermanentlySkippedOnboarding")
                    
                    // 重置用戶狀態管理器
                    UserStateManager.shared.isOnboardingCompleted = false
                    UserDefaults.standard.set(false, forKey: "isOnboardingCompleted")
                    
                    // 清除迎賓進度
                    OnboardingProgressManager.shared.clearProgress()
                    
                    // 通知用戶需要重新啟動應用
                    // 由於 @AppStorage 的更改會自動觸發視圖更新，理論上下次回到 ContentView 時應該會生效
                    // 但為了確保立即生效，我們可以添加一個通知或提示
                }
                Button("取消", role: .cancel) {
                    // 取消操作，不執行任何操作
                }
            } message: {
                Text("重置後，迎賓流程將在下次啟動應用時顯示。這將清除您之前的迎賓進度。您確定要重置嗎？")
            }
        }
    }
}

// MARK: - 設定行組件

struct ProfileSettingsRow: View {
    let userName: String
    let userEmail: String
    var showCompletionIndicator: Bool = false
    let action: () -> Void
    
    @StateObject private var progressManager = OnboardingProgressManager.shared
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(userName.isEmpty ? "未設定" : userName)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        if showCompletionIndicator {
                            let completeness = progressManager.checkProfileCompleteness()
                            if !completeness.isComplete {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    
                    Text(userEmail.isEmpty ? "未設定電子郵件" : userEmail)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if showCompletionIndicator && progressManager.hasIncompleteOnboarding {
                        let completeness = progressManager.checkProfileCompleteness()
                        if !completeness.missingFields.isEmpty {
                            Text("缺少：\(completeness.missingFields.prefix(2).joined(separator: "、"))\(completeness.missingFields.count > 2 ? "..." : "")")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

struct AppearanceSettingsRow: View {
    let designStyle: DesignStyle
    let colorScheme: ColorScheme
    let fontSize: FontSize
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "paintbrush.fill")
                    .foregroundColor(.purple)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("外觀設定")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("\(designStyle.displayName) • \(colorScheme.displayName) • \(fontSize.displayName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

struct GabrielSettingsRow: View {
    let gender: GabrielGender
    let outfit: GabrielOutfit
    let personality: GabrielPersonality
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "person.fill")
                    .foregroundColor(.orange)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("加百列設定")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("\(gender.displayName) • \(outfit.displayName) • \(personality.displayName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

struct NotificationSettingsRow: View {
    let dailyReminders: Bool
    let weeklyReports: Bool
    let monthlyReports: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "bell.fill")
                    .foregroundColor(.red)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("通知設定")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    let enabledCount = [dailyReminders, weeklyReports, monthlyReports].filter { $0 }.count
                    Text("\(enabledCount) 個通知已啟用")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

struct PrivacySecurityRow: View {
    let biometricAuth: Bool
    let dataSharing: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "lock.fill")
                    .foregroundColor(.green)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("隱私與安全")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(biometricAuth ? "生物識別已啟用" : "生物識別未啟用")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

struct BackupSyncRow: View {
    let autoBackup: Bool
    let cloudSync: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "icloud.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("備份與同步")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(autoBackup ? "自動備份已啟用" : "自動備份已停用")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

struct APIUsageRow: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("API 用量追蹤")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("用量統計、配額限制、自備 Key 管理")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

struct InvoiceCarrierRow: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "qrcode")
                    .foregroundColor(.green)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("發票載具管理")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("連結載具、自動同步發票")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

struct AIPreferenceRow: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.purple)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("AI 偏好設定")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("原生 AI、處理策略、性能監控")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

struct AboutSupportRow: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.gray)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("關於與支援")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("版本資訊、說明文件、聯絡我們")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - SecuritySettingsView

struct SecuritySettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("安全設定")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()
                
                Text("安全設定功能開發中...")
                    .font(.body)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .navigationTitle("安全設定")
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

// MARK: - 預覽

#Preview {
    SettingsMainView()
}
