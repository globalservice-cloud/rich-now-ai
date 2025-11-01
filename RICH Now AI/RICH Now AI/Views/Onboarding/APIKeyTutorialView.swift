//
//  APIKeyTutorialView.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/27.
//

import SwiftUI

struct APIKeyTutorialView: View {
    @State private var currentStep = 0
    @State private var showAnimation = false
    @State private var showAPIKeyInput = false
    
    let onComplete: () -> Void
    let onSkip: () -> Void
    
    private let steps = [
        TutorialStep(
            title: "前往 OpenAI 官網",
            description: "在瀏覽器中打開 platform.openai.com",
            icon: "🌐",
            action: "打開網站"
        ),
        TutorialStep(
            title: "登入或註冊帳戶",
            description: "使用您的 Email 或 Google/Microsoft 帳戶登入",
            icon: "👤",
            action: "登入帳戶"
        ),
        TutorialStep(
            title: "前往 API Keys 頁面",
            description: "點擊左側選單中的 'API Keys' 選項",
            icon: "🔑",
            action: "前往頁面"
        ),
        TutorialStep(
            title: "創建新的 API Key",
            description: "點擊 'Create new secret key' 按鈕",
            icon: "➕",
            action: "創建 Key"
        ),
        TutorialStep(
            title: "複製 API Key",
            description: "複製生成的 API Key（格式：sk-xxx...）",
            icon: "📋",
            action: "複製 Key"
        ),
        TutorialStep(
            title: "貼上到 App 中",
            description: "將 API Key 貼上到下方輸入框",
            icon: "📱",
            action: "輸入 Key"
        )
    ]
    
    var body: some View {
        ZStack {
            // 背景
            LinearGradient(
                colors: [Color(hex: "#1E3A8A")!, Color(hex: "#312E81")!],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 頂部標題
                VStack(spacing: 16) {
                    Text("🔑")
                        .font(.system(size: 60))
                        .scaleEffect(showAnimation ? 1.0 : 0.8)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showAnimation)
                    
                    Text("如何獲取 OpenAI API Key")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("跟著步驟操作，幾分鐘就能完成設定")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                .opacity(showAnimation ? 1.0 : 0.0)
                .offset(y: showAnimation ? 0 : -20)
                .animation(.easeOut(duration: 0.8).delay(0.2), value: showAnimation)
                
                // 步驟指示器
                HStack(spacing: 8) {
                    ForEach(0..<steps.count, id: \.self) { index in
                        Circle()
                            .fill(index <= currentStep ? Color.white : Color.white.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .scaleEffect(index == currentStep ? 1.2 : 1.0)
                            .animation(.spring(response: 0.3), value: currentStep)
                    }
                }
                .padding(.top, 20)
                .opacity(showAnimation ? 1.0 : 0.0)
                .offset(y: showAnimation ? 0 : -10)
                .animation(.easeOut(duration: 0.6).delay(0.4), value: showAnimation)
                
                // 步驟內容
                VStack(spacing: 20) {
                    if currentStep < steps.count {
                        TutorialStepView(
                            step: steps[currentStep],
                            stepNumber: currentStep + 1,
                            totalSteps: steps.count
                        )
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 30)
                
                Spacer()
                
                // 底部按鈕
                VStack(spacing: 16) {
                    if currentStep < steps.count - 1 {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentStep += 1
                            }
                        }) {
                            HStack {
                                Text("下一步")
                                    .font(.system(size: 18, weight: .semibold))
                                Image(systemName: "arrow.right")
                            }
                            .foregroundColor(Color(hex: "#1E3A8A"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(.white)
                            .cornerRadius(15)
                        }
                        .padding(.horizontal, 40)
                    } else {
                        VStack(spacing: 12) {
                            Button(action: {
                                showAPIKeyInput = true
                            }) {
                                HStack {
                                    Text("輸入 API Key")
                                        .font(.system(size: 18, weight: .semibold))
                                    Image(systemName: "key.fill")
                                }
                                .foregroundColor(Color(hex: "#1E3A8A"))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(.white)
                                .cornerRadius(15)
                            }
                            .padding(.horizontal, 40)
                            
                            Button(action: onSkip) {
                                Text("稍後再說")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                    }
                    
                    // 上一步按鈕
                    if currentStep > 0 {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentStep -= 1
                            }
                        }) {
                            Text("上一步")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
                .padding(.bottom, 40)
                .opacity(showAnimation ? 1.0 : 0.0)
                .offset(y: showAnimation ? 0 : 20)
                .animation(.easeOut(duration: 0.8).delay(0.6), value: showAnimation)
            }
        }
        .onAppear {
            startAnimation()
        }
        .sheet(isPresented: $showAPIKeyInput) {
            OpenAIOAuthView(
                onSuccess: {
                    onComplete()
                },
                onCancel: {
                    showAPIKeyInput = false
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

struct TutorialStep {
    let title: String
    let description: String
    let icon: String
    let action: String
}

struct TutorialStepView: View {
    let step: TutorialStep
    let stepNumber: Int
    let totalSteps: Int
    
    var body: some View {
        VStack(spacing: 20) {
            // 圖示
            Text(step.icon)
                .font(.system(size: 60))
                .scaleEffect(1.0)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: stepNumber)
            
            // 內容
            VStack(spacing: 12) {
                Text(step.title)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text(step.description)
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // 操作提示
            HStack {
                Image(systemName: "hand.tap.fill")
                    .foregroundColor(Color(hex: "#F59E0B"))
                Text(step.action)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "#F59E0B"))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(hex: "#F59E0B")!.opacity(0.2))
            )
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

#Preview {
    APIKeyTutorialView(
        onComplete: {
            print("完成教學")
        },
        onSkip: {
            print("跳過教學")
        }
    )
}
