//
//  InterfaceTemplate.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/27.
//

import Foundation
import SwiftUI

// MARK: - 介面設計模板
enum InterfaceTemplate: String, CaseIterable, Identifiable {
    case classic = "classic"
    case modern = "modern"
    case elegant = "elegant"
    case vibrant = "vibrant"
    case minimal = "minimal"
    case dark = "dark"
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .classic:
            return LocalizationManager.shared.localizedString("template.classic")
        case .modern:
            return LocalizationManager.shared.localizedString("template.modern")
        case .elegant:
            return LocalizationManager.shared.localizedString("template.elegant")
        case .vibrant:
            return LocalizationManager.shared.localizedString("template.vibrant")
        case .minimal:
            return LocalizationManager.shared.localizedString("template.minimal")
        case .dark:
            return LocalizationManager.shared.localizedString("template.dark")
        }
    }
    
    var description: String {
        switch self {
        case .classic:
            return LocalizationManager.shared.localizedString("template.classic.description")
        case .modern:
            return LocalizationManager.shared.localizedString("template.modern.description")
        case .elegant:
            return LocalizationManager.shared.localizedString("template.elegant.description")
        case .vibrant:
            return LocalizationManager.shared.localizedString("template.vibrant.description")
        case .minimal:
            return LocalizationManager.shared.localizedString("template.minimal.description")
        case .dark:
            return LocalizationManager.shared.localizedString("template.dark.description")
        }
    }
    
    var previewColors: [Color] {
        switch self {
        case .classic:
            return [Color(hex: "#F59E0B")!, Color(hex: "#D97706")!]
        case .modern:
            return [Color(hex: "#1E3A8A")!, Color(hex: "#312E81")!]
        case .elegant:
            return [Color(hex: "#7C3AED")!, Color(hex: "#5B21B6")!]
        case .vibrant:
            return [Color(hex: "#EC4899")!, Color(hex: "#BE185D")!]
        case .minimal:
            return [Color(hex: "#6B7280")!, Color(hex: "#374151")!]
        case .dark:
            return [Color(hex: "#1F2937")!, Color(hex: "#111827")!]
        }
    }
    
    var icon: String {
        switch self {
        case .classic:
            return "star.fill"
        case .modern:
            return "sparkles"
        case .elegant:
            return "crown.fill"
        case .vibrant:
            return "heart.fill"
        case .minimal:
            return "circle.fill"
        case .dark:
            return "moon.fill"
        }
    }
}

// MARK: - 模板配置
struct TemplateConfiguration {
    let primaryColor: Color
    let secondaryColor: Color
    let backgroundColor: Color
    let textColor: Color
    let accentColor: Color
    let cornerRadius: CGFloat
    let shadowRadius: CGFloat
    let fontFamily: String
    let animationStyle: AnimationStyle
    
    enum AnimationStyle {
        case smooth
        case bouncy
        case subtle
        case none
    }
}

// MARK: - 模板管理器
class InterfaceTemplateManager {
    static let shared = InterfaceTemplateManager()
    
    private(set) var currentTemplate: InterfaceTemplate = .classic
    private(set) var configuration: TemplateConfiguration
    
    private init() {
        self.configuration = InterfaceTemplateManager.getConfiguration(for: .classic)
        loadSavedTemplate()
    }
    
    func setTemplate(_ template: InterfaceTemplate) {
        currentTemplate = template
        configuration = InterfaceTemplateManager.getConfiguration(for: template)
        saveTemplate()
    }
    
    private func loadSavedTemplate() {
        if let savedTemplate = UserDefaults.standard.string(forKey: "selected_interface_template"),
           let template = InterfaceTemplate(rawValue: savedTemplate) {
            currentTemplate = template
            configuration = InterfaceTemplateManager.getConfiguration(for: template)
        }
    }
    
    private func saveTemplate() {
        UserDefaults.standard.set(currentTemplate.rawValue, forKey: "selected_interface_template")
    }
    
    static func getConfiguration(for template: InterfaceTemplate) -> TemplateConfiguration {
        switch template {
        case .classic:
            return TemplateConfiguration(
                primaryColor: Color(hex: "#F59E0B")!,
                secondaryColor: Color(hex: "#D97706")!,
                backgroundColor: Color(hex: "#FEF3C7")!,
                textColor: Color(hex: "#1F2937")!,
                accentColor: Color(hex: "#1E3A8A")!,
                cornerRadius: 12,
                shadowRadius: 8,
                fontFamily: "System",
                animationStyle: .smooth
            )
        case .modern:
            return TemplateConfiguration(
                primaryColor: Color(hex: "#1E3A8A")!,
                secondaryColor: Color(hex: "#312E81")!,
                backgroundColor: Color(hex: "#F8FAFC")!,
                textColor: Color(hex: "#1E293B")!,
                accentColor: Color(hex: "#3B82F6")!,
                cornerRadius: 16,
                shadowRadius: 12,
                fontFamily: "System",
                animationStyle: .bouncy
            )
        case .elegant:
            return TemplateConfiguration(
                primaryColor: Color(hex: "#7C3AED")!,
                secondaryColor: Color(hex: "#5B21B6")!,
                backgroundColor: Color(hex: "#FAF5FF")!,
                textColor: Color(hex: "#2D1B69")!,
                accentColor: Color(hex: "#A855F7")!,
                cornerRadius: 20,
                shadowRadius: 15,
                fontFamily: "System",
                animationStyle: .subtle
            )
        case .vibrant:
            return TemplateConfiguration(
                primaryColor: Color(hex: "#EC4899")!,
                secondaryColor: Color(hex: "#BE185D")!,
                backgroundColor: Color(hex: "#FDF2F8")!,
                textColor: Color(hex: "#831843")!,
                accentColor: Color(hex: "#F472B6")!,
                cornerRadius: 14,
                shadowRadius: 10,
                fontFamily: "System",
                animationStyle: .bouncy
            )
        case .minimal:
            return TemplateConfiguration(
                primaryColor: Color(hex: "#6B7280")!,
                secondaryColor: Color(hex: "#374151")!,
                backgroundColor: Color(hex: "#F9FAFB")!,
                textColor: Color(hex: "#111827")!,
                accentColor: Color(hex: "#9CA3AF")!,
                cornerRadius: 8,
                shadowRadius: 4,
                fontFamily: "System",
                animationStyle: .subtle
            )
        case .dark:
            return TemplateConfiguration(
                primaryColor: Color(hex: "#1F2937")!,
                secondaryColor: Color(hex: "#111827")!,
                backgroundColor: Color(hex: "#0F172A")!,
                textColor: Color(hex: "#F1F5F9")!,
                accentColor: Color(hex: "#3B82F6")!,
                cornerRadius: 12,
                shadowRadius: 8,
                fontFamily: "System",
                animationStyle: .smooth
            )
        }
    }
}

// MARK: - 模板視圖修飾器
struct TemplateModifier: ViewModifier {
    @State private var templateManager = InterfaceTemplateManager.shared
    
    func body(content: Content) -> some View {
        content
            .foregroundColor(templateManager.configuration.textColor)
            .background(templateManager.configuration.backgroundColor)
    }
}

extension View {
    func applyTemplate() -> some View {
        modifier(TemplateModifier())
    }
}