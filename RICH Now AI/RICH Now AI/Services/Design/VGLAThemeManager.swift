//
//  VGLAThemeManager.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/28.
//

import Foundation
import SwiftUI
import Combine

/// VGLA 主題管理器 - 根據 VGLA 類型自動切換設計風格
@MainActor
class VGLAThemeManager: ObservableObject {
    static let shared = VGLAThemeManager()
    
    @Published var currentVGLATheme: VGLATheme?
    @Published var isAutoThemeEnabled: Bool = true
    
    private let settingsManager = SettingsManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        loadSettings()
    }
    
    // MARK: - 設置管理
    
    private func loadSettings() {
        // VGLA 主題自動切換默認啟用
        isAutoThemeEnabled = true
        
        // 監聽設置變化（可以從 UserDefaults 讀取自定義設置）
        if let autoTheme = UserDefaults.standard.object(forKey: "autoVGLATheme") as? Bool {
            isAutoThemeEnabled = autoTheme
        }
    }
    
    // MARK: - 主題切換
    
    /// 根據 VGLA 組合類型獲取對應主題
    func getTheme(for vglaType: String) -> VGLATheme {
        guard !vglaType.isEmpty && vglaType.count == 2 else {
            return VGLATheme.defaultTheme
        }
        
        let type = vglaType.uppercased()
        return VGLATheme.themes[type] ?? VGLATheme.defaultTheme
    }
    
    /// 更新當前主題（根據用戶的 VGLA 類型）
    func updateTheme(for vglaType: String?) {
        guard isAutoThemeEnabled, let vglaType = vglaType, !vglaType.isEmpty else {
            currentVGLATheme = nil
            return
        }
        
        currentVGLATheme = getTheme(for: vglaType)
    }
    
    /// 手動設置主題
    func setTheme(_ theme: VGLATheme) {
        currentVGLATheme = theme
    }
    
    // MARK: - 應用主題到視圖
    
    func applyTheme(_ theme: VGLATheme) -> VGLAThemeStyle {
        return VGLAThemeStyle(theme: theme)
    }
}

// MARK: - VGLA 主題定義

struct VGLATheme: Identifiable, Codable {
    let id: String
    let name: String
    let vglaType: String
    let description: String
    
    // 顏色配置
    let primaryColor: String
    let secondaryColor: String
    let accentColor: String
    let backgroundColor: String
    let surfaceColor: String
    
    // 設計風格
    let iconStyle: IconStyle
    let cardStyle: CardStyle
    let typography: TypographyStyle
    let spacing: SpacingStyle
    let borderRadius: CGFloat
    
    // 動畫效果
    let animationStyle: AnimationStyle
    
    // 特殊元素
    let hasGradients: Bool
    let hasShadows: Bool
    let hasGlassEffect: Bool
    
    static let defaultTheme = VGLATheme(
        id: "default",
        name: "預設主題",
        vglaType: "通用",
        description: "適用於所有類型的預設主題",
        primaryColor: "#1E3A8A",
        secondaryColor: "#312E81",
        accentColor: "#F59E0B",
        backgroundColor: "#F3F4F6",
        surfaceColor: "#FFFFFF",
        iconStyle: .minimalist,
        cardStyle: .modern,
        typography: .system,
        spacing: .medium,
        borderRadius: 16,
        animationStyle: .smooth,
        hasGradients: true,
        hasShadows: true,
        hasGlassEffect: false
    )
    
    static let themes: [String: VGLATheme] = [
        // Vision + Goal (VG)
        "VG": VGLATheme(
            id: "vg",
            name: "願景目標型",
            vglaType: "VG",
            description: "充滿夢想和目標的視覺化設計",
            primaryColor: "#2563EB", // 藍色系
            secondaryColor: "#3B82F6",
            accentColor: "#60A5FA",
            backgroundColor: "#EFF6FF",
            surfaceColor: "#FFFFFF",
            iconStyle: .illustrative,
            cardStyle: .modern,
            typography: .rounded,
            spacing: .large,
            borderRadius: 20,
            animationStyle: .gentle,
            hasGradients: true,
            hasShadows: true,
            hasGlassEffect: true
        ),
        "GV": VGLATheme.themes["VG"]!,
        
        // Vision + Logic (VL)
        "VL": VGLATheme(
            id: "vl",
            name: "視覺邏輯型",
            vglaType: "VL",
            description: "清晰的數據視覺化與邏輯思考",
            primaryColor: "#0EA5E9", // 青色系
            secondaryColor: "#06B6D4",
            accentColor: "#22D3EE",
            backgroundColor: "#F0FDFA",
            surfaceColor: "#FFFFFF",
            iconStyle: .geometric,
            cardStyle: .minimal,
            typography: .monospace,
            spacing: .medium,
            borderRadius: 12,
            animationStyle: .precise,
            hasGradients: false,
            hasShadows: false,
            hasGlassEffect: false
        ),
        "LV": VGLATheme.themes["VL"]!,
        
        // Vision + Action (VA)
        "VA": VGLATheme(
            id: "va",
            name: "視覺行動型",
            vglaType: "VA",
            description: "快速響應的動態設計風格",
            primaryColor: "#10B981", // 綠色系
            secondaryColor: "#34D399",
            accentColor: "#6EE7B7",
            backgroundColor: "#ECFDF5",
            surfaceColor: "#FFFFFF",
            iconStyle: .dynamic,
            cardStyle: .modern,
            typography: .rounded,
            spacing: .medium,
            borderRadius: 16,
            animationStyle: .energetic,
            hasGradients: true,
            hasShadows: true,
            hasGlassEffect: false
        ),
        "AV": VGLATheme.themes["VA"]!,
        
        // Goal + Logic (GL)
        "GL": VGLATheme(
            id: "gl",
            name: "目標邏輯型",
            vglaType: "GL",
            description: "平衡目標與分析的穩健設計",
            primaryColor: "#8B5CF6", // 紫色系
            secondaryColor: "#A78BFA",
            accentColor: "#C4B5FD",
            backgroundColor: "#F5F3FF",
            surfaceColor: "#FFFFFF",
            iconStyle: .balanced,
            cardStyle: .classic,
            typography: .system,
            spacing: .medium,
            borderRadius: 16,
            animationStyle: .balanced,
            hasGradients: true,
            hasShadows: true,
            hasGlassEffect: false
        ),
        "LG": VGLATheme.themes["GL"]!,
        
        // Goal + Action (GA)
        "GA": VGLATheme(
            id: "ga",
            name: "目標行動型",
            vglaType: "GA",
            description: "充滿活力的目標導向設計",
            primaryColor: "#F59E0B", // 橙色系
            secondaryColor: "#FBBF24",
            accentColor: "#FCD34D",
            backgroundColor: "#FFFBEB",
            surfaceColor: "#FFFFFF",
            iconStyle: .vibrant,
            cardStyle: .modern,
            typography: .rounded,
            spacing: .medium,
            borderRadius: 18,
            animationStyle: .energetic,
            hasGradients: true,
            hasShadows: true,
            hasGlassEffect: false
        ),
        "AG": VGLATheme.themes["GA"]!,
        
        // Logic + Action (LA)
        "LA": VGLATheme(
            id: "la",
            name: "邏輯行動型",
            vglaType: "LA",
            description: "高效執行的系統化設計",
            primaryColor: "#DC2626", // 紅色系
            secondaryColor: "#EF4444",
            accentColor: "#F87171",
            backgroundColor: "#FEF2F2",
            surfaceColor: "#FFFFFF",
            iconStyle: .geometric,
            cardStyle: .minimal,
            typography: .system,
            spacing: .compact,
            borderRadius: 12,
            animationStyle: .fast,
            hasGradients: false,
            hasShadows: true,
            hasGlassEffect: false
        ),
        "AL": VGLATheme.themes["LA"]!
    ]
}

// MARK: - 設計風格枚舉

enum IconStyle: String, Codable {
    case minimalist = "minimalist"
    case illustrative = "illustrative"
    case geometric = "geometric"
    case dynamic = "dynamic"
    case balanced = "balanced"
    case vibrant = "vibrant"
}

enum CardStyle: String, Codable {
    case modern = "modern"
    case classic = "classic"
    case minimal = "minimal"
}

enum TypographyStyle: String, Codable {
    case system = "system"
    case rounded = "rounded"
    case serif = "serif"
    case monospace = "monospace"
}

enum SpacingStyle: String, Codable {
    case compact = "compact"
    case medium = "medium"
    case large = "large"
}

enum AnimationStyle: String, Codable {
    case gentle = "gentle"
    case smooth = "smooth"
    case precise = "precise"
    case energetic = "energetic"
    case balanced = "balanced"
    case fast = "fast"
}

// MARK: - 主題樣式應用器

struct VGLAThemeStyle: ViewModifier {
    let theme: VGLATheme
    
    func body(content: Content) -> some View {
        content
            .accentColor(Color(hex: theme.accentColor))
            .tint(Color(hex: theme.accentColor))
    }
}

extension View {
    func applyVGLATheme(_ theme: VGLATheme) -> some View {
        self.modifier(VGLAThemeStyle(theme: theme))
    }
}

