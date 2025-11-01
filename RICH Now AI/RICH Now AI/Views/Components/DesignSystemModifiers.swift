//
//  DesignSystemModifiers.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/12/19.
//

import SwiftUI

// MARK: - 設計系統視圖修飾符

extension View {
    /// 應用當前設計系統主題
    func applyDesignSystem() -> some View {
        self.modifier(DesignSystemModifier())
    }
    
    /// 應用自定義設計風格
    func applyDesignStyle(_ style: DesignStyle) -> some View {
        self.modifier(CustomDesignStyleModifier(style: style))
    }
    
    /// 應用顏色方案
    func applyColorScheme(_ scheme: ColorScheme) -> some View {
        self.modifier(ColorSchemeModifier(scheme: scheme))
    }
    
    /// 應用字體大小
    func applyFontSize(_ size: FontSize) -> some View {
        self.modifier(FontSizeModifier(size: size))
    }
    
    /// 應用設計風格的陰影
    func applyDesignShadow(_ style: DesignStyle) -> some View {
        self.modifier(DesignShadowModifier(style: style))
    }
    
    /// 帶有動畫的過渡效果（根據設計系統設置）
    func animatedTransition(_ transition: AnyTransition) -> some View {
        self.modifier(AnimatedTransitionModifier(transition: transition))
    }
}

// MARK: - 設計系統修飾符

struct DesignSystemModifier: ViewModifier {
    @StateObject private var designSystem = DesignSystemManager.shared
    @Environment(\.colorScheme) var systemColorScheme
    
    func body(content: Content) -> some View {
        content
            .preferredColorScheme(designSystem.colorScheme.systemColorScheme)
            .environment(\.fontSizeScale, designSystem.fontSize.scaleFactor)
            .animation(designSystem.getAnimation(), value: designSystem.designStyle)
            .animation(designSystem.getAnimation(), value: designSystem.colorScheme)
    }
}

struct CustomDesignStyleModifier: ViewModifier {
    let style: DesignStyle
    
    func body(content: Content) -> some View {
        content
            .accentColor(style.primaryColor)
            .background(style.backgroundColor)
            .foregroundColor(style.textColor)
    }
}

struct ColorSchemeModifier: ViewModifier {
    let scheme: ColorScheme
    @Environment(\.colorScheme) var systemColorScheme
    
    func body(content: Content) -> some View {
        content
            .preferredColorScheme(scheme.systemColorScheme)
    }
}

extension ColorScheme {
    var systemColorScheme: SwiftUI.ColorScheme? {
        switch self {
        case .system:
            return nil // 跟隨系統
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

struct FontSizeModifier: ViewModifier {
    let size: FontSize
    
    func body(content: Content) -> some View {
        content
            .environment(\.fontSizeScale, size.scaleFactor)
    }
}

struct DesignShadowModifier: ViewModifier {
    let style: DesignStyle
    let shadowStyle: ShadowStyle
    
    init(style: DesignStyle) {
        self.style = style
        self.shadowStyle = style.shadowStyle
    }
    
    func body(content: Content) -> some View {
        content
            .shadow(
                color: .black.opacity(shadowStyle.opacity),
                radius: shadowStyle.radius,
                x: 0,
                y: shadowStyle.radius / 2
            )
    }
}

struct AnimatedTransitionModifier: ViewModifier {
    let transition: AnyTransition
    @StateObject private var designSystem = DesignSystemManager.shared
    
    func body(content: Content) -> some View {
        content
            .transition(transition)
            .animation(designSystem.getAnimation(), value: UUID())
    }
}

// MARK: - 環境值擴展

private struct FontSizeScaleKey: EnvironmentKey {
    static let defaultValue: CGFloat = 1.0
}

extension EnvironmentValues {
    var fontSizeScale: CGFloat {
        get { self[FontSizeScaleKey.self] }
        set { self[FontSizeScaleKey.self] = newValue }
    }
}

// MARK: - 動畫工具函數

struct AnimationHelpers {
    /// 創建標準的彈簧動畫
    static func spring(response: Double = 0.5, dampingFraction: Double = 0.8) -> Animation {
        DesignSystemManager.shared.getSpringAnimation(
            response: response,
            dampingFraction: dampingFraction
        )
    }
    
    /// 創建標準的緩動動畫
    static func ease(duration: Double = 0.3) -> Animation {
        DesignSystemManager.shared.getEaseAnimation(duration: duration)
    }
    
    /// 創建帶有延遲的動畫
    static func delayedSpring(response: Double = 0.5, dampingFraction: Double = 0.8, delay: Double = 0) -> Animation {
        DesignSystemManager.shared.getSpringAnimation(
            response: response,
            dampingFraction: dampingFraction
        ).delay(delay)
    }
}

// MARK: - 主題面板應用修飾符（增強版）

extension View {
    /// 應用主題面板的所有設計元素
    func applyThemePanel(_ theme: ThemePanel) -> some View {
        self.modifier(EnhancedThemeModifier(theme: theme))
    }
}

struct EnhancedThemeModifier: ViewModifier {
    let theme: ThemePanel
    @StateObject private var designSystem = DesignSystemManager.shared
    
    func body(content: Content) -> some View {
        content
            .accentColor(theme.getAccentColor())
            .background(theme.getBackgroundColor())
            .foregroundColor(theme.getPrimaryColor())
            .font(.custom(theme.fontFamily, size: 16))
            .animation(
                theme.hasAnimations && designSystem.enableAnimations ? 
                    designSystem.getAnimation(getTransitionAnimation(theme.transitionStyle)) : 
                    .linear(duration: 0),
                value: theme.id
            )
    }
    
    private func getTransitionAnimation(_ style: String) -> Animation {
        switch style {
        case "fade":
            return .easeInOut(duration: 0.3)
        case "slide":
            return .spring(response: 0.5, dampingFraction: 0.8)
        case "morph":
            return .spring(response: 0.6, dampingFraction: 0.7)
        case "ripple":
            return .spring(response: 0.4, dampingFraction: 0.6)
        default:
            return .default
        }
    }
}

// Note: getPrimaryColor() is already defined in ThemePanel.swift

