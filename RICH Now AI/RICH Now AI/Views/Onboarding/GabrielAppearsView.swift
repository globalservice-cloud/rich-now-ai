//
//  GabrielAppearsView.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import SwiftUI

struct GabrielAppearsView: View {
    let gabrielGender: GabrielGender
    var onContinue: () -> Void
    
    @State private var gabrielOpacity: Double = 0
    @State private var gabrielScale: CGFloat = 0.5
    @State private var glowOpacity: Double = 0
    @State private var messageOpacity: Double = 0
    
    var body: some View {
        ZStack {
            // 背景漸層
            LinearGradient(
                colors: [Color(hex: "#1E3A8A") ?? .blue, Color(hex: "#312E81") ?? .purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // 加百列頭像出現
                ZStack {
                    // 外層光暈
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color(hex: "#F59E0B")!.opacity(0.3), .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 150
                            )
                        )
                        .frame(width: 300, height: 300)
                        .opacity(glowOpacity)
                    
                    // 內層光圈
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                        .frame(width: 180, height: 180)
                        .opacity(gabrielOpacity)
                    
                    // 頭像
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.white, .white.opacity(0.9)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Image(systemName: gabrielGender == .male ? "person.fill" : "person.fill")
                            .font(.system(size: 70))
                            .foregroundColor(Color(hex: "#1E3A8A"))
                    }
                    .frame(width: 150, height: 150)
                    .clipShape(Circle())
                    .shadow(color: .white.opacity(0.5), radius: 20)
                    .opacity(gabrielOpacity)
                    .scaleEffect(gabrielScale)
                }
                
                // 歡迎訊息
                VStack(spacing: 16) {
                    Text("你好！我是\(gabrielGender.displayName) 🌟")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(getGreetingMessage())
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .lineSpacing(8)
                }
                .opacity(messageOpacity)
                
                Spacer()
                
                // 繼續按鈕
                Button(action: onContinue) {
                    Text("繼續")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(hex: "#1E3A8A"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(.white)
                        )
                        .padding(.horizontal, 40)
                }
                .opacity(messageOpacity)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            performAnimation()
        }
    }
    
    private func performAnimation() {
        // 第一階段：光暈出現
        withAnimation(.easeOut(duration: 0.8)) {
            glowOpacity = 1.0
        }
        
        // 第二階段：加百列出現
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 1.2, dampingFraction: 0.6)) {
                gabrielOpacity = 1.0
                gabrielScale = 1.0
            }
        }
        
        // 第三階段：訊息顯示
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeIn(duration: 0.8)) {
                messageOpacity = 1.0
            }
        }
    }
    
    private func getGreetingMessage() -> String {
        switch gabrielGender {
        case .male:
            return "我將成為你最了解你的財務守護天使長和親密好友。\n\n未來的日子裡，我會陪伴你建立健康的財務，實現你的每一個夢想。"
        case .female:
            return "我將成為你最了解你的財務守護天使和親密好友。\n\n未來的日子裡，我會溫柔地陪伴你建立健康的財務，實現你的每一個夢想。"
        }
    }
}

#Preview {
    GabrielAppearsView(gabrielGender: .male) {
        print("Continue tapped")
    }
}

