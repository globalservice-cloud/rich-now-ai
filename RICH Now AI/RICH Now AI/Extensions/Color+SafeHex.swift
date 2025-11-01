//
//  Color+SafeHex.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/12/19.
//

import SwiftUI

extension Color {
    /// 安全地從 hex 字符串創建顏色，失敗時返回預設顏色
    static func safeHex(_ hex: String, default defaultColor: Color = .blue) -> Color {
        return Color(hex: hex) ?? defaultColor
    }
    
    /// 從設計系統獲取安全顏色
    static func designSystemPrimary(_ style: DesignStyle? = nil) -> Color {
        let designSystem = DesignSystemManager.shared
        let designStyle = style ?? designSystem.designStyle
        return designStyle.primaryColor
    }
    
    /// 從設計系統獲取安全次要顏色
    static func designSystemSecondary(_ style: DesignStyle? = nil) -> Color {
        let designSystem = DesignSystemManager.shared
        let designStyle = style ?? designSystem.designStyle
        return designStyle.secondaryColor
    }
}


