//
//  AnimationOptimizer.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/12/19.
//

import Foundation
import SwiftUI
import Combine

/// 動畫優化器 - 管理動畫性能，減少不必要的動畫計算
@MainActor
class AnimationOptimizer: ObservableObject {
    static let shared = AnimationOptimizer()
    
    @Published var isAnimationsEnabled: Bool = true
    @Published var reduceMotion: Bool = false
    @Published var animationComplexity: AnimationComplexity = .normal
    
    private var cancellables = Set<AnyCancellable>()
    private var activeAnimations: Set<UUID> = []
    private let maxConcurrentAnimations = 10
    
    private init() {
        checkAccessibilitySettings()
        observeSettings()
    }
    
    // MARK: - 設置管理
    
    private func checkAccessibilitySettings() {
        reduceMotion = UIAccessibility.isReduceMotionEnabled
        
        // 監聽無障礙設置變化
        NotificationCenter.default.publisher(for: UIAccessibility.reduceMotionStatusDidChangeNotification)
            .sink { [weak self] _ in
                self?.reduceMotion = UIAccessibility.isReduceMotionEnabled
            }
            .store(in: &cancellables)
    }
    
    private func observeSettings() {
        DesignSystemManager.shared.$enableAnimations
            .assign(to: \.isAnimationsEnabled, on: self)
            .store(in: &cancellables)
        
        DesignSystemManager.shared.$reduceMotion
            .assign(to: \.reduceMotion, on: self)
            .store(in: &cancellables)
    }
    
    // MARK: - 動畫管理
    
    /// 檢查是否可以執行動畫
    func canAnimate() -> Bool {
        return isAnimationsEnabled && !reduceMotion && activeAnimations.count < maxConcurrentAnimations
    }
    
    /// 註冊動畫
    func registerAnimation(_ id: UUID) {
        guard canAnimate() else { return }
        activeAnimations.insert(id)
    }
    
    /// 註銷動畫
    func unregisterAnimation(_ id: UUID) {
        activeAnimations.remove(id)
    }
    
    /// 獲取優化後的動畫
    func getOptimizedAnimation(_ baseAnimation: Animation) -> Animation {
        guard canAnimate() else {
            return .linear(duration: 0)
        }
        
        switch animationComplexity {
        case .low:
            return simplifyAnimation(baseAnimation)
        case .normal:
            return baseAnimation
        case .high:
            return enhanceAnimation(baseAnimation)
        }
    }
    
    private func simplifyAnimation(_ animation: Animation) -> Animation {
        // 簡化動畫，減少計算成本
        // 使用更快的動畫參數
        return .spring(response: 0.3, dampingFraction: 0.8)
    }
    
    private func enhanceAnimation(_ animation: Animation) -> Animation {
        // 增強動畫效果（在性能允許的情況下）
        return animation
    }
    
    /// 清理所有動畫
    func clearAllAnimations() {
        activeAnimations.removeAll()
    }
}

// MARK: - 動畫複雜度

enum AnimationComplexity {
    case low      // 低複雜度，優先性能
    case normal   // 正常複雜度
    case high     // 高複雜度，優先視覺效果
    
    var displayName: String {
        switch self {
        case .low: return "低複雜度（性能優先）"
        case .normal: return "正常"
        case .high: return "高複雜度（視覺優先）"
        }
    }
}

