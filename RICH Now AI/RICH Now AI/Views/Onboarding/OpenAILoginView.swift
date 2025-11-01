//
//  OpenAILoginView.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/27.
//

import SwiftUI

struct OpenAILoginView: View {
    @State private var apiKey = ""
    @State private var isAPIKeyValid = false
    @State private var showAPIKeyError = false
    @State private var isLoading = false
    @State private var showSuccess = false
    @State private var isAnimating = false
    @State private var showMainApp = false
    
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
                .opacity(showSuccess ? 1.0 : 0.0)
                .offset(y: showSuccess ? 0 : -20)
                .animation(.easeOut(duration: 0.8).delay(0.2), value: showSuccess)
                
                // 登入標題
                VStack(spacing: 16) {
                    Text("登入 OpenAI")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("請輸入您的 OpenAI API Key")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                .opacity(showSuccess ? 1.0 : 0.0)
                .offset(y: showSuccess ? 0 : 20)
                .animation(.easeOut(duration: 0.8).delay(0.4), value: showSuccess)
                
                // API Key 輸入區域
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("OpenAI API Key")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        TextField("sk-...", text: $apiKey)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(10)
                            .foregroundColor(.white)
                            .accentColor(.white)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(showAPIKeyError ? Color.red : Color.white.opacity(0.3), lineWidth: 1)
                            )
                            .onChange(of: apiKey) { _, newValue in
                                validateAPIKey(newValue)
                            }
                        
                        if showAPIKeyError {
                            Text("請輸入有效的 OpenAI API Key")
                                .font(.system(size: 14))
                                .foregroundColor(.red)
                        }
                    }
                    
                    // 如何獲取 API Key 的說明
                    VStack(alignment: .leading, spacing: 12) {
                        Text("如何獲取 API Key？")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .top, spacing: 8) {
                                Text("1.")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(Color(hex: "#F59E0B"))
                                Text("前往 OpenAI 官網 (platform.openai.com)")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                            
                            HStack(alignment: .top, spacing: 8) {
                                Text("2.")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(Color(hex: "#F59E0B"))
                                Text("登入您的帳戶或註冊新帳戶")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                            
                            HStack(alignment: .top, spacing: 8) {
                                Text("3.")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(Color(hex: "#F59E0B"))
                                Text("在 API Keys 頁面創建新的 API Key")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                            
                            HStack(alignment: .top, spacing: 8) {
                                Text("4.")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(Color(hex: "#F59E0B"))
                                Text("複製 API Key 並貼上到上方輸入框")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
                .padding(.horizontal, 20)
                .opacity(showSuccess ? 1.0 : 0.0)
                .offset(y: showSuccess ? 0 : 20)
                .animation(.easeOut(duration: 0.8).delay(0.6), value: showSuccess)
                
                Spacer()
                
                // 登入按鈕
                VStack(spacing: 16) {
                    Button(action: {
                        handleLogin()
                    }) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "#1E3A8A")!))
                                    .scaleEffect(0.8)
                            } else {
                                Text("完成登入")
                                    .font(.system(size: 18, weight: .semibold))
                                Image(systemName: "arrow.right")
                            }
                        }
                        .foregroundColor(Color(hex: "#1E3A8A"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(isAPIKeyValid ? .white : Color.gray.opacity(0.5))
                        .cornerRadius(15)
                    }
                    .disabled(!isAPIKeyValid || isLoading)
                    .padding(.horizontal, 40)
                    
                    Button(action: {
                        // 跳過登入，使用預設設定
                        handleSkipLogin()
                    }) {
                        Text("稍後再設定")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .opacity(showSuccess ? 1.0 : 0.0)
                .offset(y: showSuccess ? 0 : 20)
                .animation(.easeOut(duration: 0.8).delay(0.8), value: showSuccess)
            }
        }
        .onAppear {
            startAnimation()
        }
        .fullScreenCover(isPresented: $showMainApp) {
            OnboardingCoordinatorView()
        }
    }
    
    private func startAnimation() {
        withAnimation {
            showSuccess = true
        }
        withAnimation {
            isAnimating = true
        }
    }
    
    private func validateAPIKey(_ key: String) {
        let isValid = key.hasPrefix("sk-") && key.count > 20
        isAPIKeyValid = isValid
        showAPIKeyError = !key.isEmpty && !isValid
    }
    
    private func handleLogin() {
        guard isAPIKeyValid else { return }
        
        isLoading = true
        
        // 模擬 API Key 驗證過程
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isLoading = false
            
            // 保存 API Key 並導航到主應用
            // TODO: 實際保存 API Key 到 Keychain
            withAnimation {
                showMainApp = true
            }
        }
    }
    
    private func handleSkipLogin() {
        // 跳過登入，導航到主應用
        withAnimation {
            showMainApp = true
        }
    }
}

#Preview {
    OpenAILoginView()
}
