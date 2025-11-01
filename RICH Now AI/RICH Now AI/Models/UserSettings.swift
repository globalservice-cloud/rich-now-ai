//
//  UserSettings.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import Foundation
import SwiftData

// 用戶設定模型
@Model
class UserSettings {
    @Attribute(.unique) var id: UUID = UUID()
    
    // 基本設定
    var userName: String = ""
    var preferredLanguage: String = "en"
    var reportEmail: String = ""
    
    // 設計風格設定
    var designStyle: String = "modern"
    var colorScheme: String = "system"
    var fontSize: String = "medium"
    
    // 加百列設定
    var gabrielGender: String = "male"
    var gabrielOutfit: String = "classic"
    var gabrielPersonality: String = "wise"
    var gabrielMood: String = "friendly"
    
    // 通知設定
    var dailyReminders: Bool = true
    var weeklyReports: Bool = true
    var monthlyReports: Bool = true
    var budgetAlerts: Bool = true
    var investmentAlerts: Bool = true
    
    // 隱私設定
    var dataSharing: Bool = false
    var analyticsTracking: Bool = true
    var crashReporting: Bool = true
    
    // 安全設定
    var biometricAuth: Bool = false
    var sessionTimeout: Int = 30 // 分鐘
    var autoLock: Bool = true
    
    // 備份設定
    var autoBackup: Bool = true
    var backupFrequency: String = "weekly"
    var cloudSync: Bool = true
    
    // AI 偏好設定
    var aiProcessingStrategy: String = "nativeFirst"
    var allowOfflineAI: Bool = true
    var nativeAIConfidenceThreshold: Double = 0.85
    var enableHybridVerification: Bool = false
    var preferNativeAI: Bool = true
    var autoFallbackToOpenAI: Bool = true
    var enablePerformanceMonitoring: Bool = true
    
    // 創建時間
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    init() {
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// 設計風格枚舉
enum DesignStyle: String, CaseIterable, Codable {
    case modern = "modern"
    case classic = "classic"
    case minimalist = "minimalist"
    case colorful = "colorful"
    case dark = "dark"
    
    var displayName: String {
        switch self {
        case .modern: return "現代風格"
        case .classic: return "經典風格"
        case .minimalist: return "極簡風格"
        case .colorful: return "繽紛風格"
        case .dark: return "深色風格"
        }
    }
    
    var icon: String {
        switch self {
        case .modern: return "paintbrush.fill"
        case .classic: return "book.fill"
        case .minimalist: return "circle.fill"
        case .colorful: return "paintpalette.fill"
        case .dark: return "moon.fill"
        }
    }
}

// 顏色方案枚舉
enum ColorScheme: String, CaseIterable, Codable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    
    var displayName: String {
        switch self {
        case .system: return "跟隨系統"
        case .light: return "淺色模式"
        case .dark: return "深色模式"
        }
    }
}

// 字體大小枚舉
enum FontSize: String, CaseIterable, Codable {
    case small = "small"
    case medium = "medium"
    case large = "large"
    case extraLarge = "extraLarge"
    
    var displayName: String {
        switch self {
        case .small: return "小"
        case .medium: return "中"
        case .large: return "大"
        case .extraLarge: return "特大"
        }
    }
    
    var scaleFactor: CGFloat {
        switch self {
        case .small: return 0.9
        case .medium: return 1.0
        case .large: return 1.1
        case .extraLarge: return 1.2
        }
    }
}

// 加百列相關枚舉已移至 Gabriel.swift

// 備份頻率枚舉
enum BackupFrequency: String, CaseIterable, Codable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    
    var displayName: String {
        switch self {
        case .daily: return "每日"
        case .weekly: return "每週"
        case .monthly: return "每月"
        }
    }
}
