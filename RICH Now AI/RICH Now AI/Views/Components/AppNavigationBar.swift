//
//  AppNavigationBar.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/27.
//

import SwiftUI

struct AppNavigationBar: View {
    let title: String
    let showBackButton: Bool
    let showMenuButton: Bool
    let onBack: (() -> Void)?
    let onMenu: (() -> Void)?
    let onHome: (() -> Void)?
    let showBreadcrumb: Bool
    let breadcrumb: String?
    
    @StateObject private var navigationCoordinator = NavigationCoordinator.shared
    @State private var isBackButtonPressed = false
    
    init(
        title: String,
        showBackButton: Bool = true,
        showMenuButton: Bool = true,
        showBreadcrumb: Bool = false,
        breadcrumb: String? = nil,
        onBack: (() -> Void)? = nil,
        onMenu: (() -> Void)? = nil,
        onHome: (() -> Void)? = nil
    ) {
        self.title = title
        self.showBackButton = showBackButton
        self.showMenuButton = showMenuButton
        self.showBreadcrumb = showBreadcrumb
        self.breadcrumb = breadcrumb
        self.onBack = onBack
        self.onMenu = onMenu
        self.onHome = onHome
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 麵包屑導航（如果啟用）
            if showBreadcrumb {
                let breadcrumbText = breadcrumb ?? navigationCoordinator.breadcrumb
                if !breadcrumbText.isEmpty {
                    HStack {
                        Text(breadcrumbText)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 4)
                }
            }
            
            // 主要導航欄
            HStack(spacing: 12) {
                // 左側按鈕區域
                HStack(spacing: 8) {
                    if showBackButton {
                        Button(action: {
                            // 觸覺反饋
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                            
                            isBackButtonPressed = true
                            
                            // 執行返回操作
                            if let onBack = onBack {
                                onBack()
                            } else {
                                navigationCoordinator.goBack()
                            }
                            
                            // 重置按鈕狀態
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                isBackButtonPressed = false
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("返回")
                                    .font(.system(size: 15, weight: .medium))
                            }
                            .foregroundColor(Color.safeHex("#1E3A8A", default: .blue))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(isBackButtonPressed ? Color.safeHex("#1E3A8A", default: .blue).opacity(0.1) : Color.clear)
                            )
                        }
                        .disabled(!navigationCoordinator.canGoBack && onBack == nil)
                        .opacity(navigationCoordinator.canGoBack || onBack != nil ? 1.0 : 0.5)
                    }
                    
                    if showMenuButton {
                        Button(action: {
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                            if let onMenu = onMenu {
                                onMenu()
                            } else {
                                navigationCoordinator.showingMainMenu = true
                            }
                        }) {
                            Image(systemName: "line.3.horizontal")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(Color.safeHex("#1E3A8A", default: .blue))
                                .frame(width: 36, height: 36)
                                .background(
                                    Circle()
                                        .fill(Color.safeHex("#1E3A8A", default: .blue).opacity(0.1))
                                )
                        }
                    }
                }
                
                Spacer()
                
                // 標題區域
                VStack(spacing: 2) {
                    Text(title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
                
                // 右側按鈕區域
                HStack(spacing: 8) {
                    if let onHome = onHome {
                        Button(action: {
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                            onHome()
                        }) {
                            Image(systemName: "house.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color.safeHex("#1E3A8A", default: .blue))
                                .frame(width: 36, height: 36)
                                .background(
                                    Circle()
                                        .fill(Color.safeHex("#1E3A8A", default: .blue).opacity(0.1))
                                )
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(
            Color(.systemBackground)
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
    }
}

// MARK: - 導航欄容器視圖
struct NavigationBarContainer<Content: View>: View {
    let title: String
    let showBackButton: Bool
    let showMenuButton: Bool
    let showBreadcrumb: Bool
    let onBack: (() -> Void)?
    let onMenu: (() -> Void)?
    let onHome: (() -> Void)?
    let content: Content
    
    @StateObject private var navigationCoordinator = NavigationCoordinator.shared
    
    init(
        title: String,
        showBackButton: Bool = true,
        showMenuButton: Bool = true,
        showBreadcrumb: Bool = false,
        onBack: (() -> Void)? = nil,
        onMenu: (() -> Void)? = nil,
        onHome: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.showBackButton = showBackButton
        self.showMenuButton = showMenuButton
        self.showBreadcrumb = showBreadcrumb
        self.onBack = onBack
        self.onMenu = onMenu
        self.onHome = onHome
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            AppNavigationBar(
                title: title,
                showBackButton: showBackButton,
                showMenuButton: showMenuButton,
                showBreadcrumb: showBreadcrumb,
                breadcrumb: navigationCoordinator.breadcrumb,
                onBack: onBack ?? {
                    navigationCoordinator.goBack()
                },
                onMenu: onMenu ?? {
                    navigationCoordinator.showingMainMenu = true
                },
                onHome: onHome ?? {
                    navigationCoordinator.goToHome()
                }
            )
            
            content
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onEnded { value in
                            // 從左側邊緣滑動返回
                            if value.startLocation.x < 20 && value.translation.width > 100 {
                                if navigationCoordinator.canGoBack {
                                    navigationCoordinator.goBack()
                                }
                            }
                        }
                )
        }
    }
}

// MARK: - 主選單視圖
struct MainMenuView: View {
    @Binding var isPresented: Bool
    @StateObject private var tabController = TabController.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 標題區域
                HStack {
                    Text("主選單")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)
                
                // 選單項目
                VStack(spacing: 0) {
                    MenuItem(
                        icon: "house.fill",
                        title: "財務儀表板",
                        subtitle: "查看財務健康狀況",
                        isSelected: tabController.selectedTab == 0
                    ) {
                        tabController.switchToTab(0)
                        isPresented = false
                    }
                    
                    MenuItem(
                        icon: "message.fill",
                        title: "AI 對話",
                        subtitle: "與加百列對話",
                        isSelected: tabController.selectedTab == 1
                    ) {
                        tabController.switchToTab(1)
                        isPresented = false
                    }
                    
                    MenuItem(
                        icon: "plus.circle.fill",
                        title: "記帳",
                        subtitle: "記錄財務交易",
                        isSelected: tabController.selectedTab == 2
                    ) {
                        tabController.switchToTab(2)
                        isPresented = false
                    }
                    
                    MenuItem(
                        icon: "square.grid.2x2.fill",
                        title: "VGLA 面板",
                        subtitle: "個人化財務工具",
                        isSelected: tabController.selectedTab == 3
                    ) {
                        tabController.switchToTab(3)
                        isPresented = false
                    }
                    
                    MenuItem(
                        icon: "chart.bar.fill",
                        title: "報表",
                        subtitle: "財務分析報告",
                        isSelected: tabController.selectedTab == 4
                    ) {
                        tabController.switchToTab(4)
                        isPresented = false
                    }
                    
                    MenuItem(
                        icon: "gearshape.fill",
                        title: "設定",
                        subtitle: "應用程式設定",
                        isSelected: tabController.selectedTab == TabController.Tab.settings.rawValue
                    ) {
                        tabController.switchToTab(TabController.Tab.settings.rawValue)
                        isPresented = false
                    }
                }
                
                Spacer()
            }
            .background(Color(.systemBackground))
        }
    }
}

// MARK: - 選單項目
struct MenuItem: View {
    let icon: String
    let title: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? Color(hex: "#1E3A8A") : .primary)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "#1E3A8A"))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.safeHex("#1E3A8A", default: .blue).opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    VStack {
        AppNavigationBar(
            title: "財務儀表板",
            onBack: { print("Back tapped") },
            onMenu: { print("Menu tapped") },
            onHome: { print("Home tapped") }
        )
        
        Spacer()
    }
}
