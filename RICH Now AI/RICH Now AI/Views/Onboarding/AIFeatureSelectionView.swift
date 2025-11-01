//
//  AIFeatureSelectionView.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/27.
//

import SwiftUI

struct AIFeatureSelectionView: View {
    @StateObject private var subscriptionManager = UserSubscriptionManager.shared
    @State private var selectedOption: AIOption = .appleNative
    @State private var showAPIKeyInput = false
    @State private var showSubscriptionStore = false
    @State private var showAnimation = false
    
    let onComplete: () -> Void
    
    enum AIOption: String, CaseIterable {
        case appleNative = "apple_native"
        case inputAPIKey = "input_api_key"
        case subscribe = "subscribe"
        
        var title: String {
            switch self {
            case .appleNative: return "使用 Apple 原生功能"
            case .inputAPIKey: return "輸入我的 OpenAI API Key"
            case .subscribe: return "訂閱獲得 AI 功能"
            }
        }
        
        var subtitle: String {
            switch self {
            case .appleNative: return "免費使用語音輸入和圖片識別"
            case .inputAPIKey: return "無限制使用所有 AI 功能"
            case .subscribe: return "選擇適合的訂閱方案"
            }
        }
        
        var icon: String {
            switch self {
            case .appleNative: return "🍎"
            case .inputAPIKey: return "🔑"
            case .subscribe: return "💎"
            }
        }
        
        var color: String {
            switch self {
            case .appleNative: return "#8B5CF6"
            case .inputAPIKey: return "#EF4444"
            case .subscribe: return "#F59E0B"
            }
        }
    }
    
    var body: some View {
        ZStack {
            // 背景
            LinearGradient(
                colors: [Color(hex: "#1E3A8A")!, Color(hex: "#312E81")!],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // 標題區域
                VStack(spacing: 20) {
                    Text("🤖")
                        .font(.system(size: 80))
                        .scaleEffect(showAnimation ? 1.0 : 0.8)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showAnimation)
                    
                    VStack(spacing: 12) {
                        Text("選擇 AI 功能方案")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text("選擇最適合您的 AI 功能使用方式")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .opacity(showAnimation ? 1.0 : 0.0)
                    .offset(y: showAnimation ? 0 : 20)
                    .animation(.easeOut(duration: 0.8).delay(0.3), value: showAnimation)
                }
                
                // 選項列表
                VStack(spacing: 16) {
                    ForEach(AIOption.allCases, id: \.self) { option in
                        AIOptionCard(
                            option: option,
                            isSelected: selectedOption == option,
                            onTap: {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    selectedOption = option
                                }
                            }
                        )
                        .opacity(showAnimation ? 1.0 : 0.0)
                        .offset(x: showAnimation ? 0 : -50)
                        .animation(.easeOut(duration: 0.6).delay(0.5 + Double(AIOption.allCases.firstIndex(of: option) ?? 0) * 0.1), value: showAnimation)
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // 繼續按鈕
                VStack(spacing: 16) {
                    Button(action: {
                        handleOptionSelection()
                    }) {
                        HStack {
                            Text(getButtonText())
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
                    
                    // 功能對比提示
                    if selectedOption == .appleNative {
                        Text("💡 您可以隨時在設定中升級到 AI 功能")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                }
                .opacity(showAnimation ? 1.0 : 0.0)
                .offset(y: showAnimation ? 0 : 20)
                .animation(.easeOut(duration: 0.8).delay(0.8), value: showAnimation)
            }
        }
        .onAppear {
            startAnimation()
        }
        .sheet(isPresented: $showAPIKeyInput) {
            OpenAIOAuthView(
                onSuccess: {
                    subscriptionManager.updateTier(.byok)
                    onComplete()
                },
                onCancel: {
                    showAPIKeyInput = false
                }
            )
        }
        .sheet(isPresented: $showSubscriptionStore) {
            SubscriptionStoreView()
        }
    }
    
    private func startAnimation() {
        withAnimation {
            showAnimation = true
        }
    }
    
    private func getButtonText() -> String {
        switch selectedOption {
        case .appleNative:
            return "開始使用免費功能"
        case .inputAPIKey:
            return "輸入 API Key"
        case .subscribe:
            return "查看訂閱方案"
        }
    }
    
    private func handleOptionSelection() {
        switch selectedOption {
        case .appleNative:
            // 使用免費版，直接完成
            subscriptionManager.updateTier(.free)
            onComplete()
            
        case .inputAPIKey:
            // 顯示 API Key 輸入頁面
            showAPIKeyInput = true
            
        case .subscribe:
            // 顯示訂閱商店
            showSubscriptionStore = true
        }
    }
}

struct AIOptionCard: View {
    let option: AIFeatureSelectionView.AIOption
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 20) {
                // 圖示
                Text(option.icon)
                    .font(.system(size: 32))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(option.title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(option.subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color(hex: option.color))
                } else {
                    Image(systemName: "circle")
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(isSelected ? Color(hex: option.color)!.opacity(0.2) : Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(isSelected ? Color(hex: option.color)! : .clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    AIFeatureSelectionView {
        print("完成選擇")
    }
}
