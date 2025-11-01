//
//  WelcomeView.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import SwiftUI

struct WelcomeView: View {
    @State private var isAnimating = false
    @State private var showNextView = false
    @State private var currentMessageIndex = 0
    @State private var showOpenAIExplanation = false
    @State private var showOpenAILogin = false
    
    let welcomeMessages = [
        "你好！我是加百列，你的 AI CFO 財務顧問",
        "我將陪伴你建立正確的理財觀念",
        "讓我們一起探索你的財務目標",
        "基於聖經原則，幫助你成為金錢的好管家"
    ]
    
    var body: some View {
        ZStack {
            // 背景漸層
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.1),
                    Color.purple.opacity(0.1),
                    Color.green.opacity(0.1)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // RICH Now AI 圖示
                VStack(spacing: 20) {
                    ZStack {
                        // 外層光暈效果
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color(hex: "#F59E0B")!.opacity(0.3),
                                        Color(hex: "#D97706")!.opacity(0.1),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 60,
                                    endRadius: 100
                                )
                            )
                            .frame(width: 200, height: 200)
                            .scaleEffect(isAnimating ? 1.2 : 1.0)
                            .animation(
                                Animation.easeInOut(duration: 2.0)
                                    .repeatForever(autoreverses: true),
                                value: isAnimating
                            )
                        
                        // 背景圓形
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color(hex: "#F59E0B")!, Color(hex: "#D97706")!]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                            .scaleEffect(isAnimating ? 1.1 : 1.0)
                            .animation(
                                Animation.easeInOut(duration: 2.0)
                                    .repeatForever(autoreverses: true),
                                value: isAnimating
                            )
                            .shadow(color: Color(hex: "#F59E0B")!.opacity(0.3), radius: 10, x: 0, y: 5)
                        
                        // 自定義圖標設計
                        ZStack {
                            // 金幣圖標
                            Circle()
                                .fill(Color.white)
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Text("💰")
                                        .font(.system(size: 30))
                                )
                            
                            // AI 標識
                            Circle()
                                .fill(Color(hex: "#1E3A8A")!)
                                .frame(width: 20, height: 20)
                                .overlay(
                                    Text("AI")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundColor(.white)
                                )
                                .offset(x: 25, y: -25)
                        }
                    }
                    
                    VStack(spacing: 8) {
                        Text("RICH Now AI")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                        
                        Text("智慧財務管理")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("基於聖經原則的理財顧問")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .opacity(0.8)
                    }
                }
                
                // 歡迎訊息
                VStack(spacing: 16) {
                    Text(welcomeMessages[currentMessageIndex])
                        .font(.title2)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.primary)
                        .opacity(isAnimating ? 1.0 : 0.0)
                        .animation(.easeInOut(duration: 0.8), value: isAnimating)
                    
                    // 進度指示器
                    HStack(spacing: 8) {
                        ForEach(0..<welcomeMessages.count, id: \.self) { index in
                            Circle()
                                .fill(index <= currentMessageIndex ? Color.blue : Color.gray.opacity(0.3))
                                .frame(width: 8, height: 8)
                                .scaleEffect(index == currentMessageIndex ? 1.2 : 1.0)
                                .animation(.easeInOut(duration: 0.3), value: currentMessageIndex)
                        }
                    }
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                // 開始按鈕區域
                VStack(spacing: 16) {
                    // 主要開始按鈕
                    VStack(spacing: 12) {
                        Button(action: {
                            withAnimation {
                                showOpenAIExplanation = true
                            }
                        }) {
                            HStack {
                                Image(systemName: "key.fill")
                                    .font(.headline)
                                
                                Text("開始財務富足之旅")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                Image(systemName: "arrow.right")
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color(hex: "#F59E0B")!, Color(hex: "#D97706")!]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                        }
                        .scaleEffect(isAnimating ? 1.05 : 1.0)
                        .animation(
                            Animation.easeInOut(duration: 1.5)
                                .repeatForever(autoreverses: true),
                            value: isAnimating
                        )
                        
                        Text("基於聖經原則的智慧理財")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            startAnimation()
        }
        .fullScreenCover(isPresented: $showOpenAIExplanation) {
            OpenAIExplanationView()
        }
        .fullScreenCover(isPresented: $showOpenAILogin) {
            OpenAILoginView()
        }
        .fullScreenCover(isPresented: $showNextView) {
            OnboardingCoordinatorView()
        }
    }
    
    private func startAnimation() {
        isAnimating = true
        
        // 自動切換訊息
        Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { timer in
            if currentMessageIndex < welcomeMessages.count - 1 {
                withAnimation(.easeInOut(duration: 0.5)) {
                    currentMessageIndex += 1
                }
            } else {
                timer.invalidate()
            }
        }
    }
    
}

#Preview {
    WelcomeView()
}
