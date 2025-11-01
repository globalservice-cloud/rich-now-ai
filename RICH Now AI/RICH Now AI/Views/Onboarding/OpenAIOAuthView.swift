//
//  OpenAIOAuthView.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/27.
//

import SwiftUI

struct OpenAIOAuthView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var showLoginInput = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showPassword = false
    
    let onSuccess: () -> Void
    let onCancel: () -> Void
    
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
                    Text("🔐")
                        .font(.system(size: 80))
                        .scaleEffect(showLoginInput ? 1.0 : 0.8)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showLoginInput)
                    
                    VStack(spacing: 12) {
                        Text("登入 OpenAI 帳戶")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text("請輸入您的 OpenAI 帳號和密碼")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .opacity(showLoginInput ? 1.0 : 0.0)
                    .offset(y: showLoginInput ? 0 : 20)
                    .animation(.easeOut(duration: 0.8).delay(0.3), value: showLoginInput)
                }
                
                // 登入輸入區域
                VStack(spacing: 20) {
                    // Email 輸入
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email 帳號")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                        
                        TextField("your@email.com", text: $email)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(10)
                            .foregroundColor(.white)
                            .accentColor(.white)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    }
                    
                    // 密碼輸入
                    VStack(alignment: .leading, spacing: 8) {
                        Text("密碼")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                        
                        HStack {
                            if showPassword {
                                TextField("請輸入密碼", text: $password)
                            } else {
                                SecureField("請輸入密碼", text: $password)
                            }
                            
                            Button(action: {
                                showPassword.toggle()
                            }) {
                                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(10)
                        .foregroundColor(.white)
                        .accentColor(.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                    }
                    
                    // 按鈕區域
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
                                    Image(systemName: "person.circle.fill")
                                        .font(.system(size: 20))
                                }
                                Text(isLoading ? "登入中..." : "登入")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            .foregroundColor(Color(hex: "#1E3A8A"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(email.isEmpty || password.isEmpty ? Color.gray.opacity(0.5) : .white)
                            .cornerRadius(15)
                        }
                        .disabled(email.isEmpty || password.isEmpty || isLoading)
                        
                        Button(action: onCancel) {
                            Text("取消")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
                .opacity(showLoginInput ? 1.0 : 0.0)
                .offset(y: showLoginInput ? 0 : 20)
                .animation(.easeOut(duration: 0.8).delay(0.6), value: showLoginInput)
                
                Spacer()
            }
            .padding(.horizontal, 40)
        }
        .onAppear {
            startAnimation()
        }
        .alert("錯誤", isPresented: .constant(errorMessage != nil)) {
            Button("確定") {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "")
        }
    }
    
    private func startAnimation() {
        withAnimation {
            showLoginInput = true
        }
    }
    
    private func handleLogin() {
        guard !email.isEmpty && !password.isEmpty else {
            errorMessage = "請輸入帳號和密碼"
            return
        }
        
        guard isValidEmail(email) else {
            errorMessage = "請輸入有效的 Email 格式"
            return
        }
        
        isLoading = true
        
        // 模擬登入過程
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.isLoading = false
            
            // 模擬登入成功
            self.saveLoginCredentials()
            self.onSuccess()
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func saveLoginCredentials() {
        // 保存登入憑證到 UserDefaults
        UserDefaults.standard.set(email, forKey: "openai_email")
        UserDefaults.standard.set(true, forKey: "openai_logged_in")
        
        // 這裡可以添加更安全的憑證存儲方式
        // 例如使用 Keychain 來存儲密碼
    }
}

#Preview {
    OpenAIOAuthView(
        onSuccess: {
            print("登入成功")
        },
        onCancel: {
            print("取消登入")
        }
    )
}
