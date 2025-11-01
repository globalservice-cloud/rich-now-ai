//
//  NavigationExtensions.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/12/19.
//

import SwiftUI

// MARK: - Sheet 視圖擴展 - 支持手勢關閉

extension View {
    /// 可拖拽關閉的 Sheet 視圖修飾符
    func draggableDismiss(isPresented: Binding<Bool>, threshold: CGFloat = 100) -> some View {
        self
            .gesture(
                DragGesture()
                    .onEnded { value in
                        if value.translation.height > threshold {
                            isPresented.wrappedValue = false
                        }
                    }
            )
    }
    
    /// 添加快捷操作按鈕
    func quickActions(_ actions: [QuickAction]) -> some View {
        self.overlay(
            QuickActionsView(actions: actions),
            alignment: .bottomTrailing
        )
    }
}

// MARK: - 快捷操作

struct QuickAction: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let action: () -> Void
    let color: Color
}

struct QuickActionsView: View {
    let actions: [QuickAction]
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 12) {
            if isExpanded {
                ForEach(actions) { action in
                    NavigationQuickActionButton(action: action) {
                        action.action()
                        withAnimation(.spring(response: 0.3)) {
                            isExpanded = false
                        }
                    }
                }
                .transition(.scale.combined(with: .opacity))
            }
            
            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
                
                // 觸覺反饋
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
            }) {
                Image(systemName: isExpanded ? "xmark.circle.fill" : "plus.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(
                        Circle()
                            .fill(Color(hex: "#1E3A8A")!)
                            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                    )
            }
            .rotationEffect(.degrees(isExpanded ? 45 : 0))
            .transition(.scale)
        }
        .padding(.trailing, 20)
        .padding(.bottom, 80)
    }
}

struct NavigationQuickActionButton: View {
    let action: QuickAction
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Text(action.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                
                Image(systemName: action.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(action.color)
                    .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
            )
        }
    }
}

// MARK: - 導航動畫修飾符

struct NavigationTransition: ViewModifier {
    let direction: TransitionDirection
    
    enum TransitionDirection {
        case forward
        case backward
    }
    
    func body(content: Content) -> some View {
        content
            .transition(
                .asymmetric(
                    insertion: direction == .forward ? 
                        .move(edge: .trailing).combined(with: .opacity) :
                        .move(edge: .leading).combined(with: .opacity),
                    removal: direction == .forward ?
                        .move(edge: .leading).combined(with: .opacity) :
                        .move(edge: .trailing).combined(with: .opacity)
                )
            )
    }
}

extension View {
    func navigationTransition(_ direction: NavigationTransition.TransitionDirection) -> some View {
        modifier(NavigationTransition(direction: direction))
    }
}

// MARK: - 智能導航按鈕

struct SmartNavigationButton: View {
    let destination: NavigationDestination
    let title: String
    let icon: String
    let subtitle: String?
    let style: ButtonStyle
    
    @StateObject private var navigationCoordinator = NavigationCoordinator.shared
    
    enum ButtonStyle {
        case primary
        case secondary
        case card
    }
    
    init(
        destination: NavigationDestination,
        title: String,
        icon: String,
        subtitle: String? = nil,
        style: ButtonStyle = .secondary
    ) {
        self.destination = destination
        self.title = title
        self.icon = icon
        self.subtitle = subtitle
        self.style = style
    }
    
    var body: some View {
        Button(action: {
            // 觸覺反饋
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            // 導航到目標
            navigationCoordinator.navigate(to: destination)
        }) {
            switch style {
            case .primary:
                primaryButtonContent
            case .secondary:
                secondaryButtonContent
            case .card:
                cardButtonContent
            }
        }
        .buttonStyle(.plain)
    }
    
    private var primaryButtonContent: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color(hex: "#1E3A8A")!, Color(hex: "#312E81")!],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(16)
    }
    
    private var secondaryButtonContent: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(20)
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private var cardButtonContent: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 32, weight: .medium))
                .foregroundColor(Color(hex: "#1E3A8A"))
            
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

