//
//  OpenAIExplanationView.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/27.
//

import SwiftUI

struct OpenAIExplanationView: View {
    @State private var isAnimating = false
    @State private var showNextView = false
    @State private var currentStep = 0
    @State private var showOpenAILogin = false
    
    let explanationSteps = [
        "為了提供最佳的 AI 體驗",
        "我們需要您登入 OpenAI 帳戶",
        "這樣加百列就能使用最先進的 GPT 技術",
        "為您提供最專業的財務建議"
    ]
    
    let benefits = [
        ("🤖", "智能對話", "基於 GPT-4 的深度理解能力"),
        ("💡", "個性化建議", "根據您的財務狀況量身定制"),
        ("📊", "專業分析", "提供詳細的財務數據分析"),
        ("🛡️", "安全可靠", "您的數據受到最高級別保護")
    ]
    
    var body: some View {
        ZStack {
            // 背景漸層
            LinearGradient(
                colors: [Color(hex: "#1E3A8A")!, Color(hex: "#312E81")!],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // RICH Now AI 圖示
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color(hex: "#F59E0B")!, Color(hex: "#D97706")!]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                            .scaleEffect(isAnimating ? 1.05 : 1.0)
                            .animation(
                                Animation.easeInOut(duration: 2.0)
                                    .repeatForever(autoreverses: true),
                                value: isAnimating
                            )
                        
                        Image("AppIcon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 70, height: 70)
                            .clipShape(Circle())
                    }
                    
                    Text("RICH Now AI")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .opacity(showNextView ? 1.0 : 0.0)
                .offset(y: showNextView ? 0 : -20)
                .animation(.easeOut(duration: 0.8).delay(0.2), value: showNextView)
                
                // 說明標題
                VStack(spacing: 16) {
                    Text("為什麼需要登入 OpenAI？")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("為了給您最好的 AI 體驗")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                .opacity(showNextView ? 1.0 : 0.0)
                .offset(y: showNextView ? 0 : 20)
                .animation(.easeOut(duration: 0.8).delay(0.4), value: showNextView)
                
                // 逐步說明
                VStack(spacing: 12) {
                    ForEach(0..<explanationSteps.count, id: \.self) { index in
                        HStack(spacing: 12) {
                            Text("\(index + 1)")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 24, height: 24)
                                .background(Circle().fill(Color(hex: "#F59E0B")!))
                            
                            Text(explanationSteps[index])
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.leading)
                            
                            Spacer()
                        }
                        .opacity(showNextView ? 1.0 : 0.0)
                        .offset(x: showNextView ? 0 : -30)
                        .animation(.easeOut(duration: 0.6).delay(0.6 + Double(index) * 0.1), value: showNextView)
                    }
                }
                .padding(.horizontal, 20)
                
                // 功能特色
                VStack(spacing: 16) {
                    Text("您將獲得的功能")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                        ForEach(Array(benefits.enumerated()), id: \.offset) { index, benefit in
                            BenefitCard(
                                icon: benefit.0,
                                title: benefit.1,
                                description: benefit.2
                            )
                            .opacity(showNextView ? 1.0 : 0.0)
                            .offset(y: showNextView ? 0 : 20)
                            .animation(.easeOut(duration: 0.6).delay(0.8 + Double(index) * 0.1), value: showNextView)
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // 繼續按鈕
                Button(action: {
                    withAnimation {
                        showOpenAILogin = true
                    }
                }) {
                    HStack {
                        Text("開始登入 OpenAI")
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
                .padding(.bottom, 40)
                .opacity(showNextView ? 1.0 : 0.0)
                .offset(y: showNextView ? 0 : 20)
                .animation(.easeOut(duration: 0.8).delay(1.2), value: showNextView)
            }
        }
        .onAppear {
            startAnimation()
        }
        .fullScreenCover(isPresented: $showOpenAILogin) {
            OpenAILoginView()
        }
    }
    
    private func startAnimation() {
        withAnimation {
            showNextView = true
        }
    }
}

struct BenefitCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(icon)
                .font(.system(size: 24))
            
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Text(description)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

#Preview {
    OpenAIExplanationView()
}
