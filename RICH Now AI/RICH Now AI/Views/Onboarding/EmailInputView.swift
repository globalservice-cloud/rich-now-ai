//
//  EmailInputView.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/27.
//

import SwiftUI

struct EmailInputView: View {
    @ObservedObject var state: OnboardingState
    @State private var emailText: String = ""
    @State private var showAnimation = false
    @State private var showError = false
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
                    Text("請輸入您的 Email")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("我們將使用此 Email 發送財務報告給您")
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
                    VStack(spacing: 8) {
                        TextField("請輸入您的 Email", text: $emailText)
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color.white.opacity(0.2))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 15)
                                            .stroke(showError ? Color.red : Color.white.opacity(0.3), lineWidth: 1)
                                    )
                            )
                            .focused($isTextFieldFocused)
                            .onSubmit {
                                submitEmail()
                            }
                        
                        if showError {
                            Text("請輸入有效的 Email 格式")
                                .font(.system(size: 14))
                                .foregroundColor(.red)
                        }
                    }
                    
                    Text("例如：example@email.com")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.horizontal, 40)
                .opacity(showAnimation ? 1.0 : 0.0)
                .offset(y: showAnimation ? 0 : 20)
                .animation(.easeOut(duration: 0.8).delay(0.5), value: showAnimation)
                
                Spacer()
                
                // 按鈕區域
                VStack(spacing: 12) {
                    // 繼續按鈕
                    if !emailText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Button(action: submitEmail) {
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
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    
                    // 稍後再說按鈕
                    Button(action: skipEmail) {
                        Text("稍後再說")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.bottom, 40)
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
    
    private func submitEmail() {
        let trimmedEmail = emailText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedEmail.isEmpty {
            showError = true
            return
        }
        
        if isValidEmail(trimmedEmail) {
            state.userEmail = trimmedEmail
            withAnimation {
                state.nextStep()
            }
        } else {
            showError = true
        }
    }
    
    private func skipEmail() {
        state.userEmail = ""
        withAnimation {
            state.nextStep()
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func startAnimation() {
        withAnimation {
            showAnimation = true
        }
    }
}

#Preview {
    EmailInputView(state: OnboardingState())
}
