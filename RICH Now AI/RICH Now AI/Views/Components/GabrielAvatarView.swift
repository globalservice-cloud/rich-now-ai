//
//  GabrielAvatarView.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/27.
//

import SwiftUI

struct GabrielAvatarView: View {
    let gender: GabrielGender
    let size: CGFloat
    let showFullBody: Bool
    @State private var isAnimating = false
    
    init(gender: GabrielGender, size: CGFloat = 120, showFullBody: Bool = false) {
        self.gender = gender
        self.size = size
        self.showFullBody = showFullBody
    }
    
    var body: some View {
        ZStack {
            if showFullBody {
                // 全身形象
                VStack(spacing: 0) {
                    // 頭部
                    headView
                        .scaleEffect(isAnimating ? 1.05 : 1.0)
                        .animation(AnimationOptimizer.shared.canAnimate() ? 
                            DesignSystemManager.shared.getEaseAnimation(duration: 2.0).repeatForever(autoreverses: true) : 
                            .linear(duration: 0), 
                            value: isAnimating)
                    
                    // 身體
                    bodyView
                        .scaleEffect(isAnimating ? 1.02 : 1.0)
                        .animation(AnimationOptimizer.shared.canAnimate() ? 
                            DesignSystemManager.shared.getEaseAnimation(duration: 2.5).repeatForever(autoreverses: true) : 
                            .linear(duration: 0), 
                            value: isAnimating)
                }
            } else {
                // 頭像
                headView
                    .scaleEffect(isAnimating ? 1.05 : 1.0)
                    .animation(AnimationOptimizer.shared.canAnimate() ? 
                        DesignSystemManager.shared.getEaseAnimation(duration: 2.0).repeatForever(autoreverses: true) : 
                        .linear(duration: 0), 
                        value: isAnimating)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
    
    @ViewBuilder
    private var headView: some View {
        ZStack {
            // 外層光暈效果
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.4),
                            Color.blue.opacity(0.2),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.8
                    )
                )
                .frame(width: size * 1.4, height: size * 1.4)
                .blur(radius: 12)
            
            // 內層光暈
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.6),
                            Color.white.opacity(0.2),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.6
                    )
                )
                .frame(width: size * 1.2, height: size * 1.2)
                .blur(radius: 8)
            
            // 頭部圓圈
            Circle()
                .fill(
                    LinearGradient(
                        colors: gender == .male ? 
                            [Color.safeHex("#FEF3C7", default: .yellow), Color.safeHex("#FDE68A", default: .yellow), Color.safeHex("#F59E0B", default: .orange)] :
                            [Color.safeHex("#FDF2F8", default: .pink), Color.safeHex("#FCE7F3", default: .pink), Color.safeHex("#EC4899", default: .pink)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.9), Color.white.opacity(0.4)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 4
                        )
                )
                .shadow(color: Color.white.opacity(0.6), radius: 15, x: 0, y: 0)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            
            // 面部特徵
            VStack(spacing: size * 0.08) {
                // 眼睛
                HStack(spacing: size * 0.18) {
                    eyeView
                    eyeView
                }
                
                // 鼻子
                Circle()
                    .fill(Color.safeHex("#F59E0B", default: .orange).opacity(0.4))
                    .frame(width: size * 0.06, height: size * 0.05)
                
                // 嘴巴
                if gender == .male {
                    // 男性：自信微笑
                    Path { path in
                        path.addArc(
                            center: CGPoint(x: 0, y: 0),
                            radius: size * 0.15,
                            startAngle: .degrees(0),
                            endAngle: .degrees(180),
                            clockwise: false
                        )
                    }
                    .stroke(Color.safeHex("#1E3A8A", default: .blue), lineWidth: 3)
                    .frame(width: size * 0.3, height: size * 0.15)
                } else {
                    // 女性：溫柔微笑
                    Path { path in
                        path.addArc(
                            center: CGPoint(x: 0, y: 0),
                            radius: size * 0.12,
                            startAngle: .degrees(0),
                            endAngle: .degrees(180),
                            clockwise: false
                        )
                    }
                    .stroke(Color.safeHex("#EC4899", default: .pink), lineWidth: 3)
                    .frame(width: size * 0.24, height: size * 0.12)
                }
            }
            
            // 天使翅膀裝飾
            if gender == .male {
                // 男性：強壯的翅膀
                HStack(spacing: size * 0.9) {
                    wingView
                    wingView
                }
                .offset(y: -size * 0.15)
            } else {
                // 女性：優雅的翅膀
                HStack(spacing: size * 0.8) {
                    wingView
                    wingView
                }
                .offset(y: -size * 0.15)
            }
            
            // 頭頂光環
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.8), Color.yellow.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )
                .frame(width: size * 1.3, height: size * 0.3)
                .offset(y: -size * 0.4)
                .rotationEffect(.degrees(isAnimating ? 5 : -5))
                .animation(AnimationOptimizer.shared.canAnimate() ? 
                    DesignSystemManager.shared.getEaseAnimation(duration: 3.0).repeatForever(autoreverses: true) : 
                    .linear(duration: 0), 
                    value: isAnimating)
        }
    }
    
    @ViewBuilder
    private var eyeView: some View {
        ZStack {
            // 眼白
            Circle()
                .fill(Color.white)
                .frame(width: size * 0.14, height: size * 0.12)
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
            
            // 眼球
            Circle()
                .fill(gender == .male ? Color.safeHex("#1E3A8A", default: .blue) : Color.safeHex("#EC4899", default: .pink))
                .frame(width: size * 0.1, height: size * 0.1)
            
            // 瞳孔
            Circle()
                .fill(Color.black)
                .frame(width: size * 0.06, height: size * 0.06)
            
            // 高光
            Circle()
                .fill(Color.white)
                .frame(width: size * 0.03, height: size * 0.03)
                .offset(x: -size * 0.015, y: -size * 0.015)
            
            // 額外高光
            Circle()
                .fill(Color.white.opacity(0.6))
                .frame(width: size * 0.02, height: size * 0.02)
                .offset(x: size * 0.01, y: -size * 0.01)
        }
    }
    
    @ViewBuilder
    private var wingView: some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: 0))
            path.addCurve(
                to: CGPoint(x: size * 0.35, y: size * 0.12),
                control1: CGPoint(x: size * 0.12, y: -size * 0.08),
                control2: CGPoint(x: size * 0.25, y: size * 0.02)
            )
            path.addCurve(
                to: CGPoint(x: size * 0.25, y: size * 0.35),
                control1: CGPoint(x: size * 0.4, y: size * 0.18),
                control2: CGPoint(x: size * 0.35, y: size * 0.28)
            )
            path.addCurve(
                to: CGPoint(x: 0, y: size * 0.28),
                control1: CGPoint(x: size * 0.12, y: size * 0.4),
                control2: CGPoint(x: size * 0.06, y: size * 0.35)
            )
            path.closeSubpath()
        }
        .fill(
            LinearGradient(
                colors: [
                    Color.white.opacity(0.9),
                    Color.white.opacity(0.6),
                    Color.white.opacity(0.3)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .stroke(
            LinearGradient(
                colors: [Color.white.opacity(0.8), Color.white.opacity(0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            lineWidth: 2
        )
        .frame(width: size * 0.35, height: size * 0.35)
        .shadow(color: Color.white.opacity(0.3), radius: 5, x: 0, y: 0)
    }
    
    @ViewBuilder
    private var bodyView: some View {
        VStack(spacing: 4) {
            // 身體
            RoundedRectangle(cornerRadius: size * 0.1)
                .fill(
                    LinearGradient(
                        colors: gender == .male ? 
                            [Color.safeHex("#1E3A8A", default: .blue), Color.safeHex("#312E81", default: .purple)] :
                            [Color.safeHex("#EC4899", default: .pink), Color.safeHex("#BE185D", default: .pink)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size * 0.6, height: size * 0.8)
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.1)
                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                )
            
            // 翅膀（全身時顯示）
            HStack(spacing: size * 0.1) {
                wingView
                    .frame(width: size * 0.4, height: size * 0.4)
                wingView
                    .frame(width: size * 0.4, height: size * 0.4)
            }
            .offset(y: -size * 0.2)
        }
    }
}

// MARK: - 加百列頭像預覽
struct GabrielAvatarPreview: View {
    var body: some View {
        VStack(spacing: 30) {
            Text("加百列天使形象")
                .font(.title)
                .fontWeight(.bold)
            
            HStack(spacing: 40) {
                VStack {
                    GabrielAvatarView(gender: .male, size: 100, showFullBody: false)
                    Text("男性天使長")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    GabrielAvatarView(gender: .female, size: 100, showFullBody: false)
                    Text("女性天使")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack(spacing: 40) {
                VStack {
                    GabrielAvatarView(gender: .male, size: 80, showFullBody: true)
                    Text("男性全身形象")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    GabrielAvatarView(gender: .female, size: 80, showFullBody: true)
                    Text("女性全身形象")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
    }
}

#Preview {
    GabrielAvatarPreview()
}
