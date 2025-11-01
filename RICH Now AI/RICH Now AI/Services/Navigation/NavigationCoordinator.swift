//
//  NavigationCoordinator.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/12/19.
//

import Foundation
import SwiftUI
import Combine

/// 統一的導航協調器 - 管理應用程式的導航狀態和流程
@MainActor
class NavigationCoordinator: ObservableObject {
    static let shared = NavigationCoordinator()
    
    // 導航路徑
    @Published var navigationStack: [NavigationDestination] = []
    @Published var presentedSheet: SheetDestination?
    @Published var presentedFullScreen: FullScreenDestination?
    @Published var showingMainMenu = false
    
    // 導航歷史記錄
    private var navigationHistory: [NavigationDestination] = []
    private let maxHistorySize = 10
    
    private init() {}
    
    // MARK: - 導航操作
    
    /// 導航到指定目的地
    func navigate(to destination: NavigationDestination) {
        navigationStack.append(destination)
        
        // 保存到歷史記錄
        navigationHistory.append(destination)
        if navigationHistory.count > maxHistorySize {
            navigationHistory.removeFirst()
        }
    }
    
    /// 返回上一頁
    func goBack() {
        guard !navigationStack.isEmpty else { return }
        navigationStack.removeLast()
    }
    
    /// 返回根頁面
    func goToRoot() {
        navigationStack.removeAll()
    }
    
    /// 返回主頁（儀表板）
    func goToHome() {
        TabController.shared.switchToTab(0)
        goToRoot()
        dismissAllModals()
    }
    
    /// 顯示 Sheet
    func presentSheet(_ destination: SheetDestination) {
        dismissAllModals() // 先關閉其他模態
        presentedSheet = destination
    }
    
    /// 顯示全屏模態
    func presentFullScreen(_ destination: FullScreenDestination) {
        dismissAllModals()
        presentedFullScreen = destination
    }
    
    /// 關閉所有模態視圖
    func dismissAllModals() {
        presentedSheet = nil
        presentedFullScreen = nil
        showingMainMenu = false
    }
    
    /// 檢查是否可以返回
    var canGoBack: Bool {
        !navigationStack.isEmpty
    }
    
    /// 獲取當前頁面
    var currentDestination: NavigationDestination? {
        navigationStack.last
    }
    
    /// 獲取導航路徑（用於麵包屑）
    var breadcrumb: String {
        navigationStack.map { $0.title }.joined(separator: " > ")
    }
}

// MARK: - 導航目的地

enum NavigationDestination: Identifiable, Hashable {
    case dashboard
    case chat
    case transaction
    case transactionText
    case transactionPhoto
    case transactionHistory
    case panels
    case panelDetail(String)
    case reports
    case reportDetail(String)
    case settings
    case settingsProfile
    case settingsAPI
    case investment
    case watchlist
    case invoiceCarrier
    
    var id: String {
        switch self {
        case .dashboard: return "dashboard"
        case .chat: return "chat"
        case .transaction: return "transaction"
        case .transactionText: return "transaction.text"
        case .transactionPhoto: return "transaction.photo"
        case .transactionHistory: return "transaction.history"
        case .panels: return "panels"
        case .panelDetail(let id): return "panel.detail.\(id)"
        case .reports: return "reports"
        case .reportDetail(let id): return "report.detail.\(id)"
        case .settings: return "settings"
        case .settingsProfile: return "settings.profile"
        case .settingsAPI: return "settings.api"
        case .investment: return "investment"
        case .watchlist: return "watchlist"
        case .invoiceCarrier: return "invoice.carrier"
        }
    }
    
    var title: String {
        switch self {
        case .dashboard: return LocalizationManager.shared.localizedString("dashboard.title")
        case .chat: return LocalizationManager.shared.localizedString("chat.title")
        case .transaction: return LocalizationManager.shared.localizedString("transaction.title")
        case .transactionText: return LocalizationManager.shared.localizedString("text_accounting.title")
        case .transactionPhoto: return "拍照記帳"
        case .transactionHistory: return LocalizationManager.shared.localizedString("transaction.history_title")
        case .panels: return LocalizationManager.shared.localizedString("panels.title")
        case .panelDetail(let name): return name
        case .reports: return LocalizationManager.shared.localizedString("reports.title")
        case .reportDetail(let name): return name
        case .settings: return LocalizationManager.shared.localizedString("settings.title")
        case .settingsProfile: return "個人資料"
        case .settingsAPI: return "API 設定"
        case .investment: return LocalizationManager.shared.localizedString("investment.title")
        case .watchlist: return "投資關注"
        case .invoiceCarrier: return "發票載具"
        }
    }
    
    var icon: String {
        switch self {
        case .dashboard: return "house.fill"
        case .chat: return "message.fill"
        case .transaction: return "plus.circle.fill"
        case .transactionText: return "text.bubble.fill"
        case .transactionPhoto: return "camera.fill"
        case .transactionHistory: return "list.bullet.rectangle"
        case .panels: return "square.grid.2x2.fill"
        case .panelDetail: return "square.stack.3d.up.fill"
        case .reports: return "chart.bar.fill"
        case .reportDetail: return "doc.text.fill"
        case .settings: return "gearshape.fill"
        case .settingsProfile: return "person.circle.fill"
        case .settingsAPI: return "key.fill"
        case .investment: return "chart.line.uptrend.xyaxis"
        case .watchlist: return "eye.fill"
        case .invoiceCarrier: return "qrcode"
        }
    }
}

enum SheetDestination: Identifiable {
    case textAccounting
    case photoAccounting
    case transactionHistory
    case mainMenu
    case settings
    case goalSetting
    case financialPlan
    case addWatchlistItem
    case invoiceCarrierManagement
    case vglaAssessment
    case tkiAssessment
    
    var id: String {
        switch self {
        case .textAccounting: return "textAccounting"
        case .photoAccounting: return "photoAccounting"
        case .transactionHistory: return "transactionHistory"
        case .mainMenu: return "mainMenu"
        case .settings: return "settings"
        case .goalSetting: return "goalSetting"
        case .financialPlan: return "financialPlan"
        case .addWatchlistItem: return "addWatchlistItem"
        case .invoiceCarrierManagement: return "invoiceCarrierManagement"
        case .vglaAssessment: return "vglaAssessment"
        case .tkiAssessment: return "tkiAssessment"
        }
    }
}

enum FullScreenDestination: Identifiable {
    case onboarding
    case vglaResult
    case reportDetail(String)
    
    var id: String {
        switch self {
        case .onboarding: return "onboarding"
        case .vglaResult: return "vglaResult"
        case .reportDetail(let id): return "reportDetail.\(id)"
        }
    }
}

