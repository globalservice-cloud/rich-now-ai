//
//  NameInputView.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/27.
//

import SwiftUI

struct NameInputView: View {
    @ObservedObject var state: OnboardingState
    @State private var nameText: String = ""
    @State private var showAnimation = false
    @FocusState private var isTextFieldFocused: Bool
    
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
                
                // 加百列頭像
                if let gabriel = state.selectedGabriel {
                    GabrielAvatarView(gender: gabriel, size: 120, showFullBody: false)
                        .scaleEffect(showAnimation ? 1.0 : 0.8)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showAnimation)
                }
                
                // 標題區域
                VStack(spacing: 20) {
                    Text("請輸入您的稱呼")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("我們希望用您喜歡的方式稱呼您")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .opacity(showAnimation ? 1.0 : 0.0)
                .offset(y: showAnimation ? 0 : 20)
                .animation(.easeOut(duration: 0.8).delay(0.3), value: showAnimation)
                
                // 輸入區域
                VStack(spacing: 20) {
                    TextField("請輸入您的稱呼", text: $nameText)
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.white.opacity(0.2))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 15)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .focused($isTextFieldFocused)
                        .onSubmit {
                            if !nameText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                submitName()
                            }
                        }
                    
                    Text("例如：小明、王先生、Lisa 等")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.horizontal, 40)
                .opacity(showAnimation ? 1.0 : 0.0)
                .offset(y: showAnimation ? 0 : 20)
                .animation(.easeOut(duration: 0.8).delay(0.5), value: showAnimation)
                
                Spacer()
                
                // 繼續按鈕
                if !nameText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Button(action: submitName) {
                        HStack {
                            Text("繼續")
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
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .onAppear {
            startAnimation()
            // 延遲聚焦，讓動畫完成後再聚焦
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                isTextFieldFocused = true
            }
        }
    }
    
    private func submitName() {
        let trimmedName = nameText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedName.isEmpty {
            state.userName = trimmedName
            withAnimation {
                state.nextStep()
            }
        }
    }
    
    private func startAnimation() {
        withAnimation {
            showAnimation = true
        }
    }
}

#Preview {
    NameInputView(state: OnboardingState())
}
