//
//  SettingsManager.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import Foundation
import SwiftData
import Combine

@MainActor
class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    @Published var currentSettings: UserSettings?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var modelContext: ModelContext?
    
    init() {
        loadSettings()
    }
    
    // MARK: - 設定管理
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadSettings()
    }
    
    func loadSettings() {
        guard let context = modelContext else { return }
        
        isLoading = true
        
        do {
            let descriptor = FetchDescriptor<UserSettings>()
            let settings = try context.fetch(descriptor)
            
            if let existingSettings = settings.first {
                self.currentSettings = existingSettings
            } else {
                // 創建預設設定
                let newSettings = UserSettings()
                context.insert(newSettings)
                try context.save()
                self.currentSettings = newSettings
            }
            
            isLoading = false
        } catch {
            errorMessage = "Failed to load settings: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    func saveSettings() {
        guard let context = modelContext, let settings = currentSettings else { return }
        
        do {
            settings.updatedAt = Date()
            try context.save()
        } catch {
            errorMessage = "Failed to save settings: \(error.localizedDescription)"
        }
    }
    
    // MARK: - 基本設定更新
    
    func updateUserName(_ name: String) {
        currentSettings?.userName = name
        saveSettings()
    }
    
    func updateLanguage(_ language: String) {
        currentSettings?.preferredLanguage = language
        saveSettings()
        
        // 同步更新 LocalizationManager
        if let appLanguage = LocalizationManager.AppLanguage(rawValue: language) {
            Task { @MainActor in
                LocalizationManager.shared.changeLanguage(to: appLanguage)
            }
        }
    }
    
    func updateReportEmail(_ email: String) {
        currentSettings?.reportEmail = email
        saveSettings()
    }
    
    // MARK: - 設計風格設定
    
    func updateDesignStyle(_ style: DesignStyle) {
        currentSettings?.designStyle = style.rawValue
        saveSettings()
    }
    
    func updateColorScheme(_ scheme: ColorScheme) {
        currentSettings?.colorScheme = scheme.rawValue
        saveSettings()
    }
    
    func updateFontSize(_ size: FontSize) {
        currentSettings?.fontSize = size.rawValue
        saveSettings()
    }
    
    // MARK: - 加百列設定
    
    func updateGabrielGender(_ gender: GabrielGender) {
        currentSettings?.gabrielGender = gender.rawValue
        saveSettings()
    }
    
    func updateGabrielOutfit(_ outfit: GabrielOutfit) {
        currentSettings?.gabrielOutfit = outfit.rawValue
        saveSettings()
    }
    
    func updateGabrielPersonality(_ personality: GabrielPersonality) {
        currentSettings?.gabrielPersonality = personality.rawValue
        saveSettings()
    }
    
    func updateGabrielMood(_ mood: GabrielMood) {
        currentSettings?.gabrielMood = mood.rawValue
        saveSettings()
    }
    
    // MARK: - 通知設定
    
    func updateNotificationSettings(
        dailyReminders: Bool? = nil,
        weeklyReports: Bool? = nil,
        monthlyReports: Bool? = nil,
        budgetAlerts: Bool? = nil,
        investmentAlerts: Bool? = nil
    ) {
        if let daily = dailyReminders {
            currentSettings?.dailyReminders = daily
        }
        if let weekly = weeklyReports {
            currentSettings?.weeklyReports = weekly
        }
        if let monthly = monthlyReports {
            currentSettings?.monthlyReports = monthly
        }
        if let budget = budgetAlerts {
            currentSettings?.budgetAlerts = budget
        }
        if let investment = investmentAlerts {
            currentSettings?.investmentAlerts = investment
        }
        
        saveSettings()
    }
    
    // MARK: - 隱私設定
    
    func updatePrivacySettings(
        dataSharing: Bool? = nil,
        analyticsTracking: Bool? = nil,
        crashReporting: Bool? = nil
    ) {
        if let sharing = dataSharing {
            currentSettings?.dataSharing = sharing
        }
        if let analytics = analyticsTracking {
            currentSettings?.analyticsTracking = analytics
        }
        if let crash = crashReporting {
            currentSettings?.crashReporting = crash
        }
        
        saveSettings()
    }
    
    // MARK: - 安全設定
    
    func updateSecuritySettings(
        biometricAuth: Bool? = nil,
        sessionTimeout: Int? = nil,
        autoLock: Bool? = nil
    ) {
        if let biometric = biometricAuth {
            currentSettings?.biometricAuth = biometric
        }
        if let timeout = sessionTimeout {
            currentSettings?.sessionTimeout = timeout
        }
        if let lock = autoLock {
            currentSettings?.autoLock = lock
        }
        
        saveSettings()
    }
    
    // MARK: - 備份設定
    
    func updateBackupSettings(
        autoBackup: Bool? = nil,
        backupFrequency: BackupFrequency? = nil,
        cloudSync: Bool? = nil
    ) {
        if let backup = autoBackup {
            currentSettings?.autoBackup = backup
        }
        if let frequency = backupFrequency {
            currentSettings?.backupFrequency = frequency.rawValue
        }
        if let sync = cloudSync {
            currentSettings?.cloudSync = sync
        }
        
        saveSettings()
    }
    
    // MARK: - 重置設定
    
    func resetToDefaults() {
        guard let context = modelContext else { return }
        
        do {
            // 刪除現有設定
            if let settings = currentSettings {
                context.delete(settings)
            }
            
            // 創建新的預設設定
            let newSettings = UserSettings()
            context.insert(newSettings)
            try context.save()
            
            self.currentSettings = newSettings
        } catch {
            errorMessage = "Failed to reset settings: \(error.localizedDescription)"
        }
    }
    
    // MARK: - 匯出/匯入設定
    
    func exportSettings() -> Data? {
        // 簡化的設定導出，不支援 JSON 編碼
        errorMessage = "Settings export not implemented"
        return nil
    }
    
    func importSettings(from data: Data) -> Bool {
        // 簡化的設定導入，不支援 JSON 解碼
        errorMessage = "Settings import not implemented"
        return false
    }
}
