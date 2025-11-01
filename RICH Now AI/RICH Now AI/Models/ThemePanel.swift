//
//  ThemePanel.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import Foundation
import SwiftUI
import SwiftData

// 面板分類
enum ThemePanelCategory: String, Codable, CaseIterable {
    case basic = "basic"           // 基礎面板（VGLA 16 種）
    case special = "special"       // 特殊主題
    case seasonal = "seasonal"     // 季節限定
    case festival = "festival"     // 節慶主題
    case collaboration = "collaboration" // 品牌聯名
    case achievement = "achievement"     // 成就解鎖
}

// 面板主題模型
@Model
final class ThemePanel {
    // 基本資訊
    var id: String
    var name: String
    var displayName: String
    var category: String // ThemePanelCategory.rawValue
    var panelDescription: String
    
    // VGLA 推薦
    var vglaSuggested: [String] // 推薦的 VGLA 組合型態
    var isVGLADefault: Bool // 是否為該 VGLA 的預設面板
    
    // 定價
    var isPremium: Bool
    var price: Double
    var currency: String
    
    // 視覺資源
    var previewImageURL: String
    var thumbnailImageURL: String
    
    // 顏色配置
    var primaryColorHex: String
    var secondaryColorHex: String
    var accentColorHex: String
    var backgroundColorHex: String
    var gradientColorsHex: [String]
    
    // 設計風格
    var iconStyle: String // minimalist, illustrative, geometric, organic
    var chartStyle: String // modern, classic, playful, professional
    var fontFamily: String // system, rounded, serif, monospace
    var borderRadius: Double
    var shadowIntensity: Double
    
    // 動畫效果
    var hasAnimations: Bool
    var transitionStyle: String // fade, slide, morph, ripple
    var animationSpeed: String // slow, normal, fast
    
    // 特殊元素
    var hasCustomIcons: Bool
    var hasBiblicalQuotes: Bool
    var hasSeasonalElements: Bool
    var hasParticleEffects: Bool
    
    // 狀態
    var isAvailable: Bool
    var releaseDate: Date
    var expiryDate: Date? // 限時面板的過期日期
    
    // 統計
    var downloadCount: Int
    var ratingAverage: Double
    var ratingCount: Int
    
    // 時間戳記
    var createdAt: Date
    var updatedAt: Date
    
    init(id: String, name: String, displayName: String, category: ThemePanelCategory) {
        self.id = id
        self.name = name
        self.displayName = displayName
        self.category = category.rawValue
        self.panelDescription = ""
        self.vglaSuggested = []
        self.isVGLADefault = false
        self.isPremium = false
        self.price = 0
        self.currency = "TWD"
        self.previewImageURL = ""
        self.thumbnailImageURL = ""
        self.primaryColorHex = "#007AFF"
        self.secondaryColorHex = "#5856D6"
        self.accentColorHex = "#FF9500"
        self.backgroundColorHex = "#FFFFFF"
        self.gradientColorsHex = []
        self.iconStyle = "minimalist"
        self.chartStyle = "modern"
        self.fontFamily = "system"
        self.borderRadius = 12.0
        self.shadowIntensity = 0.1
        self.hasAnimations = true
        self.transitionStyle = "fade"
        self.animationSpeed = "normal"
        self.hasCustomIcons = false
        self.hasBiblicalQuotes = false
        self.hasSeasonalElements = false
        self.hasParticleEffects = false
        self.isAvailable = true
        self.releaseDate = Date()
        self.downloadCount = 0
        self.ratingAverage = 0
        self.ratingCount = 0
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // 獲取分類枚舉
    func getCategory() -> ThemePanelCategory? {
        return ThemePanelCategory(rawValue: category)
    }
    
    // 獲取顏色
    func getPrimaryColor() -> Color {
        return Color(hex: primaryColorHex) ?? .blue
    }
    
    func getSecondaryColor() -> Color {
        return Color(hex: secondaryColorHex) ?? .purple
    }
    
    func getAccentColor() -> Color {
        return Color(hex: accentColorHex) ?? .orange
    }
    
    func getBackgroundColor() -> Color {
        return Color(hex: backgroundColorHex) ?? .white
    }
    
    func getGradientColors() -> [Color] {
        return gradientColorsHex.compactMap { Color(hex: $0) }
    }
    
    // 檢查是否推薦給特定 VGLA 類型
    func isRecommendedFor(vglaType: String) -> Bool {
        return vglaSuggested.contains(vglaType)
    }
    
    // 更新評分
    func updateRating(newRating: Double) {
        let totalRating = ratingAverage * Double(ratingCount) + newRating
        ratingCount += 1
        ratingAverage = totalRating / Double(ratingCount)
        updatedAt = Date()
    }
}

// 使用者面板偏好
@Model
final class UserThemePreference {
    var activeThemeId: String
    var ownedThemeIds: [String] // 擁有的面板 ID
    var favoriteThemeIds: [String] // 收藏的面板 ID
    var lastChangedDate: Date
    var totalThemesPurchased: Int
    
    // 關聯
    @Relationship(deleteRule: .nullify) var user: User?
    
    init(activeThemeId: String) {
        self.activeThemeId = activeThemeId
        self.ownedThemeIds = [activeThemeId]
        self.favoriteThemeIds = []
        self.lastChangedDate = Date()
        self.totalThemesPurchased = 0
    }
    
    // 檢查是否擁有面板
    func ownsTheme(_ themeId: String) -> Bool {
        return ownedThemeIds.contains(themeId)
    }
    
    // 添加擁有的面板
    func addOwnedTheme(_ themeId: String) {
        if !ownedThemeIds.contains(themeId) {
            ownedThemeIds.append(themeId)
            totalThemesPurchased += 1
        }
    }
    
    // 切換面板
    func switchTheme(to themeId: String) {
        self.activeThemeId = themeId
        self.lastChangedDate = Date()
    }
    
    // 收藏面板
    func toggleFavorite(_ themeId: String) {
        if favoriteThemeIds.contains(themeId) {
            favoriteThemeIds.removeAll { $0 == themeId }
        } else {
            favoriteThemeIds.append(themeId)
        }
    }
    
    // 檢查是否收藏
    func isFavorite(_ themeId: String) -> Bool {
        return favoriteThemeIds.contains(themeId)
    }
}

// Color 擴展：支援 hex 字串 (已移至 Color+Hex.swift)

// View 擴展：應用面板主題
extension View {
    func applyTheme(_ theme: ThemePanel) -> some View {
        self.modifier(ThemeModifier(theme: theme))
    }
}

// 面板主題修飾器
struct ThemeModifier: ViewModifier {
    let theme: ThemePanel
    
    func body(content: Content) -> some View {
        content
            .accentColor(theme.getAccentColor())
            .background(theme.getBackgroundColor())
            .animation(theme.hasAnimations ? .default : .none, value: theme.id)
    }
}
