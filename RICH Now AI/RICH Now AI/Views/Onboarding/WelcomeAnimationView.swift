//
//  WelcomeAnimationView.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import SwiftUI

struct WelcomeAnimationView: View {
    let onAnimationComplete: () -> Void
    let onSkip: () -> Void
    
    @State private var isAnimating = true
    @State private var showSkipButton = false
    @State private var animationPhase = 0
    @State private var starOpacity: Double = 0.0
    @State private var carOffset: CGFloat = -200
    @State private var textOpacity: Double = 0.0
    @State private var angelOpacity: Double = 0.0
    @State private var angelScale: CGFloat = 0.5
    @State private var textScale: CGFloat = 0.8
    @State private var shimmerOffset: CGFloat = -200
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // 背景漸層 - 星空效果
            LinearGradient(
                colors: [
                    Color(red: 0.06, green: 0.09, blue: 0.16),
                    Color(red: 0.12, green: 0.23, blue: 0.54),
                    Color(red: 0.19, green: 0.18, blue: 0.51),
                    Color(red: 0.12, green: 0.11, blue: 0.29)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // 星空背景
            StarFieldView()
                .opacity(starOpacity)
            
            // 光暈效果
            if animationPhase >= 2 {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.1),
                                Color.blue.opacity(0.05),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 50,
                            endRadius: 200
                        )
                    )
                    .frame(width: 400, height: 400)
                    .scaleEffect(pulseScale)
                    .opacity(angelOpacity * 0.6)
            }
            
            VStack(spacing: 30) {
                Spacer()
                
                // 流星動畫
                if animationPhase >= 1 {
                    MeteorView()
                        .offset(x: carOffset)
                        .opacity(animationPhase >= 1 ? 1.0 : 0.0)
                        .animation(.easeInOut(duration: 1.5), value: carOffset)
                }
                
                // 加百列天使形象
                if animationPhase >= 2 {
                    GabrielAngelView()
                        .opacity(angelOpacity)
                        .scaleEffect(angelScale)
                        .animation(.spring(response: 0.8, dampingFraction: 0.6), value: angelScale)
                        .animation(.easeInOut(duration: 1.0), value: angelOpacity)
                }
                
                // 文字內容
                if animationPhase >= 3 {
                    VStack(spacing: 20) {
                        Text(LocalizationManager.shared.localizedString("welcome.animation.title"))
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .opacity(textOpacity)
                            .scaleEffect(textScale)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: textScale)
                            .animation(.easeInOut(duration: 1.0), value: textOpacity)
                        
                        Text(LocalizationManager.shared.localizedString("welcome.animation.subtitle"))
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .opacity(textOpacity)
                            .scaleEffect(textScale)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: textScale)
                            .animation(.easeInOut(duration: 1.0).delay(0.2), value: textOpacity)
                        
                        Text(LocalizationManager.shared.localizedString("welcome.animation.description"))
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                            .opacity(textOpacity)
                            .scaleEffect(textScale)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4), value: textScale)
                            .animation(.easeInOut(duration: 1.0).delay(0.4), value: textOpacity)
                    }
                }
                
                Spacer()
            }
            
            // 跳過按鈕
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        onSkip()
                    }) {
                        Text(LocalizationManager.shared.localizedString("welcome.animation.skip"))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.black.opacity(0.3))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                            )
                    }
                    .opacity(showSkipButton ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 0.5), value: showSkipButton)
                }
                .padding(.top, 50)
                .padding(.horizontal, 20)
                
                Spacer()
            }
        }
        .onAppear {
            startAnimationSequence()
        }
    }
    
    private func startAnimationSequence() {
        // 階段 1: 顯示星空 (0.5秒)
        withAnimation(.easeInOut(duration: 0.8)) {
            starOpacity = 1.0
        }
        
        // 階段 2: 流星出現 (1秒後)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            animationPhase = 1
            withAnimation(.easeInOut(duration: 1.5)) {
                carOffset = 200
            }
        }
        
        // 階段 3: 天使出現 (2.5秒後)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            animationPhase = 2
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                angelScale = 1.0
            }
            withAnimation(.easeInOut(duration: 1.0)) {
                angelOpacity = 1.0
            }
            
            // 開始脈衝動畫
            startPulseAnimation()
        }
        
        // 階段 4: 文字出現 (4秒後)
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            animationPhase = 3
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                textScale = 1.0
            }
            withAnimation(.easeInOut(duration: 1.0)) {
                textOpacity = 1.0
            }
        }
        
        // 階段 5: 動畫完成 (7秒後)
        DispatchQueue.main.asyncAfter(deadline: .now() + 7.0) {
            withAnimation(.easeInOut(duration: 1.0)) {
                isAnimating = false
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                onAnimationComplete()
            }
        }
        
        // 顯示跳過按鈕 (立即顯示)
        withAnimation(.easeInOut(duration: 0.5)) {
            showSkipButton = true
        }
    }
    
    private func startPulseAnimation() {
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            pulseScale = 1.2
        }
    }
}

#Preview {
    WelcomeAnimationView(
        onAnimationComplete: {
            print("動畫完成")
        },
        onSkip: {
            print("跳過動畫")
        }
    )
}
