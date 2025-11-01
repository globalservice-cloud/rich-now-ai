//
//  SafeColorReplacer.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/12/19.
//  Utility script to help replace unsafe Color(hex:)! with safe alternatives
//

import SwiftUI

/// 安全的顏色輔助方法集合
struct SafeColorHelper {
    /// 常見的應用顏色常數
    struct AppColors {
        static let primaryBlue = Color.safeHex("#1E3A8A", default: .blue)
        static let primaryPurple = Color.safeHex("#312E81", default: .purple)
        static let accentOrange = Color.safeHex("#F59E0B", default: .orange)
        static let accentPink = Color.safeHex("#EC4899", default: .pink)
        static let accentBlue = Color.safeHex("#3B82F6", default: .blue)
        static let accentGreen = Color.safeHex("#10B981", default: .green)
        static let accentRed = Color.safeHex("#EF4444", default: .red)
        static let accentCyan = Color.safeHex("#06B6D4", default: .cyan)
        static let accentPurple = Color.safeHex("#8B5CF6", default: .purple)
        
        // VGLA 類型顏色
        static let vglaV = Color.safeHex("#F59E0B", default: .orange) // 願景型
        static let vglaG = Color.safeHex("#EC4899", default: .pink)   // 感性型
        static let vglaL = Color.safeHex("#3B82F6", default: .blue)   // 邏輯型
        static let vglaA = Color.safeHex("#10B981", default: .green)  // 行動型
    }
}


