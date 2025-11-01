//
//  GabrielAngelView.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import SwiftUI

struct GabrielAngelView: View {
    @State private var wingFlap: Double = 0.0
    @State private var glowIntensity: Double = 0.0
    @State private var haloRotation: Double = 0.0
    
    var body: some View {
        ZStack {
            // 光環
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.yellow.opacity(0.8),
                            Color.orange.opacity(0.6),
                            Color.clear
                        ],
                        startPoint: .center,
                        endPoint: .trailing
                    ),
                    lineWidth: 4
                )
                .frame(width: 120, height: 120)
                .rotationEffect(.degrees(haloRotation))
                .opacity(glowIntensity)
            
            // 天使身體
            VStack(spacing: 0) {
                // 翅膀
                HStack(spacing: 20) {
                    // 左翅膀
                    WingView()
                        .scaleEffect(x: -1, y: 1) // 水平翻轉
                        .rotationEffect(.degrees(wingFlap))
                    
                    // 天使身體
                    VStack(spacing: 8) {
                        // 頭部
                        Circle()
                            .fill(Color.white)
                            .frame(width: 40, height: 40)
                            .overlay(
                                Circle()
                                    .stroke(Color.blue.opacity(0.3), lineWidth: 2)
                            )
                        
                        // 身體
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [Color.white, Color.blue.opacity(0.1)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 30, height: 50)
                    }
                    
                    // 右翅膀
                    WingView()
                        .rotationEffect(.degrees(-wingFlap))
                }
                
                // 光效
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.8),
                                Color.blue.opacity(0.4),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 30
                        )
                    )
                    .frame(width: 60, height: 60)
                    .blur(radius: 2)
                    .opacity(glowIntensity)
            }
        }
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        // 光效動畫
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            glowIntensity = 1.0
        }
        
        // 翅膀拍動
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            wingFlap = 15.0
        }
        
        // 光環旋轉
        withAnimation(.linear(duration: 10.0).repeatForever(autoreverses: false)) {
            haloRotation = 360.0
        }
    }
}

struct WingView: View {
    var body: some View {
        Path { path in
            // 翅膀形狀
            path.move(to: CGPoint(x: 0, y: 20))
            path.addCurve(
                to: CGPoint(x: 30, y: 0),
                control1: CGPoint(x: 15, y: -10),
                control2: CGPoint(x: 25, y: -5)
            )
            path.addCurve(
                to: CGPoint(x: 0, y: 20),
                control1: CGPoint(x: 25, y: 5),
                control2: CGPoint(x: 15, y: 10)
            )
        }
        .fill(
            LinearGradient(
                colors: [
                    Color.white.opacity(0.9),
                    Color.blue.opacity(0.3),
                    Color.cyan.opacity(0.2)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .frame(width: 30, height: 40)
    }
}

#Preview {
    GabrielAngelView()
        .background(Color.black)
}
