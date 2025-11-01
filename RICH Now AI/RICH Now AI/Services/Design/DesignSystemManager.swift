//
//  DesignSystemManager.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/12/19.
//

import Foundation
import SwiftUI
import Combine

/// 設計系統管理器 - 統一管理應用程式的設計風格、主題和動畫
@MainActor
class DesignSystemManager: ObservableObject {
    static let shared = DesignSystemManager()
    
    // 當前設計設置
    @Published var designStyle: DesignStyle = .modern
    @Published var colorScheme: ColorScheme = .system
    @Published var fontSize: FontSize = .medium
    @Published var currentTheme: ThemeConfiguration?
    
    // 動畫設置
    @Published var enableAnimations: Bool = true
    @Published var animationSpeed: AnimationSpeed = .normal
    @Published var reduceMotion: Bool = false
    
    private let settingsManager = SettingsManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        loadSettings()
        setupObservers()
        checkAccessibilitySettings()
    }
    
    // MARK: - 設置管理
    
    private func loadSettings() {
        if let settings = settingsManager.currentSettings {
            designStyle = DesignStyle(rawValue: settings.designStyle) ?? .modern
            colorScheme = ColorScheme(rawValue: settings.colorScheme) ?? .system
            fontSize = FontSize(rawValue: settings.fontSize) ?? .medium
        }
        
        // 載入當前主題配置
        updateThemeConfiguration()
    }
    
    private func setupObservers() {
        // 監聽設置變化
        settingsManager.objectWillChange
            .sink { [weak self] _ in
                self?.loadSettings()
            }
            .store(in: &cancellables)
    }
    
    private func checkAccessibilitySettings() {
        // 檢查是否啟用了減少動畫
        reduceMotion = UIAccessibility.isReduceMotionEnabled
    }
    
    // MARK: - 主題配置
    
    func updateThemeConfiguration() {
        currentTheme = ThemeConfiguration(
            designStyle: designStyle,
            colorScheme: colorScheme,
            fontSize: fontSize
        )
    }
    
    func updateDesignStyle(_ style: DesignStyle) {
        designStyle = style
        updateThemeConfiguration()
        settingsManager.updateDesignStyle(style)
    }
    
    func updateColorScheme(_ scheme: ColorScheme) {
        colorScheme = scheme
        updateThemeConfiguration()
        settingsManager.updateColorScheme(scheme)
        
        // 應用顏色方案到視圖
        applyColorScheme(scheme)
    }
    
    func updateFontSize(_ size: FontSize) {
        fontSize = size
        updateThemeConfiguration()
        settingsManager.updateFontSize(size)
    }
    
    private func applyColorScheme(_ scheme: ColorScheme) {
        // 設置顏色方案會在 ContentView 層級處理
        // 這裡只是更新設置
    }
    
    // MARK: - 動畫管理
    
    /// 根據設置獲取動畫
    func getAnimation(_ baseAnimation: Animation = .default) -> Animation {
        guard enableAnimations, !reduceMotion else {
            return .linear(duration: 0)
        }
        
        switch animationSpeed {
        case .slow:
            return baseAnimation.speed(0.7)
        case .normal:
            return baseAnimation
        case .fast:
            return baseAnimation.speed(1.5)
        }
    }
    
    /// 根據設置獲取彈簧動畫
    func getSpringAnimation(response: Double = 0.5, dampingFraction: Double = 0.8) -> Animation {
        guard enableAnimations, !reduceMotion else {
            return .linear(duration: 0)
        }
        
        let adjustedResponse = response / animationSpeed.speedMultiplier
        return .spring(response: adjustedResponse, dampingFraction: dampingFraction)
    }
    
    /// 根據設置獲取緩動動畫
    func getEaseAnimation(duration: Double = 0.3) -> Animation {
        guard enableAnimations, !reduceMotion else {
            return .linear(duration: 0)
        }
        
        let adjustedDuration = duration / animationSpeed.speedMultiplier
        return .easeInOut(duration: adjustedDuration)
    }
}

// MARK: - 主題配置

struct ThemeConfiguration {
    let designStyle: DesignStyle
    let colorScheme: ColorScheme
    let fontSize: FontSize
    
    // 顏色
    var primaryColor: Color {
        designStyle.primaryColor
    }
    
    var secondaryColor: Color {
        designStyle.secondaryColor
    }
    
    var backgroundColor: Color {
        designStyle.backgroundColor
    }
    
    var textColor: Color {
        designStyle.textColor
    }
    
    // 字體
    var fontScale: CGFloat {
        fontSize.scaleFactor
    }
    
    // 間距
    var spacing: CGFloat {
        designStyle.spacing
    }
    
    // 圓角
    var cornerRadius: CGFloat {
        designStyle.cornerRadius
    }
}

// MARK: - 動畫速度

enum AnimationSpeed: String, CaseIterable {
    case slow = "slow"
    case normal = "normal"
    case fast = "fast"
    
    var displayName: String {
        switch self {
        case .slow: return "慢速"
        case .normal: return "正常"
        case .fast: return "快速"
        }
    }
    
    var speedMultiplier: Double {
        switch self {
        case .slow: return 0.7
        case .normal: return 1.0
        case .fast: return 1.5
        }
    }
}

// MARK: - 設計風格擴展

extension DesignStyle {
    var primaryColor: Color {
        switch self {
        case .modern:
            return Color.safeHex("#1E3A8A", default: .blue)
        case .classic:
            return Color.safeHex("#8B4513", default: .brown)
        case .minimalist:
            return Color.safeHex("#000000", default: .black)
        case .colorful:
            return Color.safeHex("#FF6B6B", default: .red)
        case .dark:
            return Color.safeHex("#4A90E2", default: .blue)
        }
    }
    
    var secondaryColor: Color {
        switch self {
        case .modern:
            return Color.safeHex("#312E81", default: .purple)
        case .classic:
            return Color.safeHex("#A0522D", default: .brown)
        case .minimalist:
            return Color.safeHex("#666666", default: .gray)
        case .colorful:
            return Color.safeHex("#4ECDC4", default: .cyan)
        case .dark:
            return Color.safeHex("#2E3A59", default: .indigo)
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .modern:
            return Color(.systemBackground)
        case .classic:
            return Color.safeHex("#F5F5DC", default: Color(.systemBackground))
        case .minimalist:
            return Color(.systemBackground)
        case .colorful:
            return Color.safeHex("#FFF8E1", default: Color(.systemBackground))
        case .dark:
            return Color.safeHex("#1A1A1A", default: .black)
        }
    }
    
    var textColor: Color {
        switch self {
        case .modern, .minimalist:
            return Color(.label)
        case .classic:
            return Color.safeHex("#3E2723", default: Color(.label))
        case .colorful:
            return Color.safeHex("#424242", default: Color(.label))
        case .dark:
            return Color(.white)
        }
    }
    
    var spacing: CGFloat {
        switch self {
        case .modern:
            return 16
        case .classic:
            return 20
        case .minimalist:
            return 12
        case .colorful:
            return 18
        case .dark:
            return 16
        }
    }
    
    var cornerRadius: CGFloat {
        switch self {
        case .modern:
            return 16
        case .classic:
            return 8
        case .minimalist:
            return 4
        case .colorful:
            return 20
        case .dark:
            return 12
        }
    }
    
    var shadowStyle: ShadowStyle {
        switch self {
        case .modern:
            return ShadowStyle(radius: 8, opacity: 0.1)
        case .classic:
            return ShadowStyle(radius: 4, opacity: 0.15)
        case .minimalist:
            return ShadowStyle(radius: 2, opacity: 0.05)
        case .colorful:
            return ShadowStyle(radius: 12, opacity: 0.2)
        case .dark:
            return ShadowStyle(radius: 6, opacity: 0.3)
        }
    }
}

struct ShadowStyle {
    let radius: CGFloat
    let opacity: Double
}

