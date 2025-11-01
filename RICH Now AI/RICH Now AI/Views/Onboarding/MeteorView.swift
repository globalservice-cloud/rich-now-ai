//
//  MeteorView.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import SwiftUI

struct MeteorView: View {
    @State private var trailOpacity: Double = 0.0
    @State private var rotationAngle: Double = 0.0
    
    var body: some View {
        ZStack {
            // 流星尾巴
            Path { path in
                let startPoint = CGPoint(x: 0, y: 0)
                let endPoint = CGPoint(x: -100, y: 50)
                
                path.move(to: startPoint)
                path.addLine(to: endPoint)
            }
            .stroke(
                LinearGradient(
                    colors: [
                        Color.white,
                        Color.blue.opacity(0.8),
                        Color.cyan.opacity(0.6),
                        Color.clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                style: StrokeStyle(lineWidth: 3, lineCap: .round)
            )
            .opacity(trailOpacity)
            
            // 流星主體
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white,
                            Color.blue.opacity(0.8),
                            Color.cyan.opacity(0.6)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 8
                    )
                )
                .frame(width: 16, height: 16)
                .shadow(color: .white, radius: 4)
        }
        .rotationEffect(.degrees(rotationAngle))
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5)) {
                trailOpacity = 1.0
            }
            
            withAnimation(.easeInOut(duration: 1.0)) {
                rotationAngle = 45.0
            }
        }
    }
}

#Preview {
    MeteorView()
        .background(Color.black)
}
