//
//  LocalizationManager.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    @Published var currentLanguage: AppLanguage
    private let userDefaults: UserDefaults
    private let languageStorageKey = "selectedLanguage"
    
    enum AppLanguage: String, CaseIterable {
        case english = "en"
        case traditionalChinese = "zh-Hant"
        case simplifiedChinese = "zh-Hans"
        
        var displayName: String {
            switch self {
            case .english: return "English"
            case .traditionalChinese: return "繁體中文"
            case .simplifiedChinese: return "简体中文"
            }
        }
        
        var flag: String {
            switch self {
            case .english: return "🇺🇸"
            case .traditionalChinese: return "🇹🇼"
            case .simplifiedChinese: return "🇨🇳"
            }
        }
        
        var locale: Locale {
            switch self {
            case .english: return Locale(identifier: "en")
            case .traditionalChinese: return Locale(identifier: "zh-Hant")
            case .simplifiedChinese: return Locale(identifier: "zh-Hans")
            }
        }
    }
    
    private init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        userDefaults.register(defaults: [languageStorageKey: "en"])
        let savedCode = userDefaults.string(forKey: languageStorageKey) ?? "en"
        self.currentLanguage = AppLanguage(rawValue: savedCode) ?? .english
    }
    
    func changeLanguage(to language: AppLanguage) {
        guard currentLanguage != language else { 
            print("⚠️ 語言未變更，跳過更新: \(language.displayName)")
            return // 避免重複設置相同語言
        }
        
        print("🔄 開始切換語言: \(currentLanguage.displayName) -> \(language.displayName)")
        
        // 更新當前語言（會觸發 @Published 變更，通知所有觀察者）
        currentLanguage = language
        
        // 保存到 UserDefaults
        userDefaults.set(language.rawValue, forKey: languageStorageKey)
        
        // 更新應用程式的語言設定（需要使用正確的格式）
        let languageCodes = [language.rawValue]
        userDefaults.set(languageCodes, forKey: "AppleLanguages")
        userDefaults.synchronize()
        
        // 通知系統語言變更
        NotificationCenter.default.post(name: .languageChanged, object: language)
        
        // 驗證 Bundle 是否存在並測試翻譯
        let bundlePath = Bundle.main.path(forResource: language.rawValue, ofType: "lproj")
        if let path = bundlePath {
            print("✅ 語言已切換到: \(language.displayName) (\(language.rawValue))")
            print("   ✅ Bundle 路徑: \(path)")
        } else {
            print("⚠️ 語言已切換，但找不到 Bundle 路徑: \(language.rawValue)")
        }
        
        // 測試翻譯
        let testKey = "common.ok"
        let testTranslation = localizedString(testKey)
        print("   🧪 翻譯測試 '\(testKey)': '\(testTranslation)'")
    }
    
    func localizedString(_ key: String, comment: String = "") -> String {
        // 獲取當前語言的 Bundle
        guard let path = Bundle.main.path(forResource: currentLanguage.rawValue, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            // 如果找不到對應語言的 Bundle，嘗試使用主 Bundle
            // 這會回退到系統默認語言或 Base 語言
            let fallbackString = NSLocalizedString(key, tableName: nil, bundle: Bundle.main, value: key, comment: comment)
            
            // 如果還是返回 key，嘗試從英文 Bundle 載入
            if fallbackString == key {
                if let enPath = Bundle.main.path(forResource: "en", ofType: "lproj"),
                   let enBundle = Bundle(path: enPath) {
                    return NSLocalizedString(key, tableName: nil, bundle: enBundle, value: key, comment: comment)
                }
            }
            return fallbackString
        }
        
        // 使用指定語言的 Bundle 獲取本地化字符串
        let localizedString = NSLocalizedString(key, tableName: nil, bundle: bundle, value: key, comment: comment)
        
        // 如果找不到對應的翻譯，回退到英文
        if localizedString == key && currentLanguage != .english {
            if let enPath = Bundle.main.path(forResource: "en", ofType: "lproj"),
               let enBundle = Bundle(path: enPath) {
                return NSLocalizedString(key, tableName: nil, bundle: enBundle, value: key, comment: comment)
            }
        }
        
        return localizedString
    }
    
    func localizedString(_ key: String, arguments: CVarArg...) -> String {
        let format = localizedString(key)
        return String(format: format, arguments: arguments)
    }
    
    // 財務術語本地化
    func localizedCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = currentLanguage.locale
        
        switch currentLanguage {
        case .english:
            formatter.currencyCode = "USD"
        case .traditionalChinese, .simplifiedChinese:
            formatter.currencyCode = "TWD"
        }
        
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(amount)"
    }
    
    func localizedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = currentLanguage.locale
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    func localizedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = currentLanguage.locale
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// 通知名稱
extension Notification.Name {
    static let languageChanged = Notification.Name("languageChanged")
}

// SwiftUI 擴展
extension LocalizationManager {
    func localizedText(_ key: String) -> Text {
        Text(localizedString(key))
    }
}

// 便利方法
extension String {
    var localized: String {
        return LocalizationManager.shared.localizedString(self)
    }
    
    func localized(_ arguments: CVarArg...) -> String {
        return LocalizationManager.shared.localizedString(self, arguments: arguments)
    }
}
