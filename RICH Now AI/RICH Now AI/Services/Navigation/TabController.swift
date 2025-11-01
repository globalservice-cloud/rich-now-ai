//
//  TabController.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/28.
//

import Foundation
import SwiftUI
import Combine

// Tab 控制器 - 用於在應用程式間共享選中的 tab
@MainActor
class TabController: ObservableObject {
    static let shared = TabController()
    
    @Published var selectedTab: Int = 0 {
        didSet {
            // 保存到 UserDefaults
            UserDefaults.standard.set(selectedTab, forKey: "selectedTab")
        }
    }
    
    @Published var navigationPath: NavigationPath = NavigationPath()
    
    private init() {
        // 從 UserDefaults 載入最後選中的 tab
        self.selectedTab = UserDefaults.standard.integer(forKey: "selectedTab")
    }
    
    // 切換到指定的 tab
    func switchToTab(_ tab: Int) {
        selectedTab = tab
    }
    
    // 定義的 tab 索引
    enum Tab: Int, CaseIterable {
        case dashboard = 0
        case chat = 1
        case transaction = 2
        case panels = 3
        case reports = 4
        case settings = 5
        
        var title: String {
            switch self {
            case .dashboard: return "財務儀表板"
            case .chat: return "AI 對話"
            case .transaction: return "記帳"
            case .panels: return "VGLA 面板"
            case .reports: return "報表"
            case .settings: return "設定"
            }
        }
    }
}

