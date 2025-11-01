//
//  OpenAILoginExplanationView.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/27.
//

import SwiftUI

struct OpenAILoginExplanationView: View {
    @State private var showAnimation = false
    @State private var showLoginView = false
    @State private var showOAuthView = false
    let onContinue: () -> Void
    
    var body: some View {
        ZStack {
            // 背景漸層
            LinearGradient(
                colors: [Color(hex: "#1E3A8A")!, Color(hex: "#312E81")!],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // 頂部圖示和標題
                VStack(spacing: 24) {
                    // OpenAI 圖示
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 80))
                        .foregroundColor(.white)
                        .scaleEffect(showAnimation ? 1.0 : 0.8)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showAnimation)
                    
                    VStack(spacing: 16) {
                        Text("為什麼需要登入 OpenAI？")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text("為了提供最佳的 AI 財務顧問體驗")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    .opacity(showAnimation ? 1.0 : 0.0)
                    .offset(y: showAnimation ? 0 : 20)
                    .animation(.easeOut(duration: 0.8).delay(0.3), value: showAnimation)
                }
                
                // 說明內容
                VStack(spacing: 20) {
                    ExplanationCard(
                        icon: "sparkles",
                        title: "個人化 AI 對話",
                        description: "基於你的 VGLA 測驗結果，提供量身定制的財務建議",
                        delay: 0.5
                    )
                    
                    ExplanationCard(
                        icon: "mic.fill",
                        title: "語音互動功能",
                        description: "支援語音輸入，讓你可以自然地與 AI 財務顧問對話",
                        delay: 0.7
                    )
                    
                    ExplanationCard(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "即時財務分析",
                        description: "利用 GPT-4 的強大分析能力，提供即時、準確的財務洞察",
                        delay: 0.9
                    )
                    
                    ExplanationCard(
                        icon: "lock.shield.fill",
                        title: "安全與隱私",
                        description: "你的財務資料完全保密，只會用於提供個人化建議",
                        delay: 1.1
                    )
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // 底部按鈕
                VStack(spacing: 16) {
                    // OAuth 登入按鈕
                    Button(action: {
                        showOAuthView = true
                    }) {
                        HStack {
                            Image(systemName: "person.circle.fill")
                            Text("使用 OpenAI 帳號登入")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        .foregroundColor(Color(hex: "#1E3A8A"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.white)
                        .cornerRadius(15)
                    }
                    .opacity(showAnimation ? 1.0 : 0.0)
                    .offset(y: showAnimation ? 0 : 30)
                    .animation(.easeOut(duration: 0.8).delay(1.3), value: showAnimation)
                    
                    // 手動輸入 API Key 按鈕
                    Button(action: {
                        showLoginView = true
                    }) {
                        HStack {
                            Image(systemName: "key.fill")
                            Text("手動輸入 API Key")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.white.opacity(0.8))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .opacity(showAnimation ? 1.0 : 0.0)
                    .offset(y: showAnimation ? 0 : 20)
                    .animation(.easeOut(duration: 0.8).delay(1.5), value: showAnimation)
                    
                    Text("登入後即可享受完整的 AI 財務顧問服務")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .opacity(showAnimation ? 1.0 : 0.0)
                        .offset(y: showAnimation ? 0 : 20)
                        .animation(.easeOut(duration: 0.8).delay(1.7), value: showAnimation)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            startAnimation()
        }
        .sheet(isPresented: $showLoginView) {
            OpenAILoginView()
        }
        .sheet(isPresented: $showOAuthView) {
            OpenAIOAuthView(
                onSuccess: {
                    showOAuthView = false
                    onContinue()
                },
                onCancel: {
                    showOAuthView = false
                }
            )
        }
    }
    
    private func startAnimation() {
        withAnimation {
            showAnimation = true
        }
    }
}

struct ExplanationCard: View {
    let icon: String
    let title: String
    let description: String
    let delay: Double
    
    @State private var showCard = false
    
    var body: some View {
        HStack(spacing: 16) {
            // 圖示
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(Color(hex: "#F59E0B"))
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(Color(hex: "#F59E0B")!.opacity(0.2))
                )
            
            // 文字內容
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .opacity(showCard ? 1.0 : 0.0)
        .offset(x: showCard ? 0 : -50)
        .animation(.easeOut(duration: 0.6).delay(delay), value: showCard)
        .onAppear {
            withAnimation {
                showCard = true
            }
        }
    }
}

#Preview {
    OpenAILoginExplanationView {
        // 預覽用的繼續動作
    }
}
