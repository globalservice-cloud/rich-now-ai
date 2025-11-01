//
//  GabrielSelectionView.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import SwiftUI

struct GabrielSelectionView: View {
    @Binding var selectedGabriel: GabrielGender?
    var onSelect: (GabrielGender) -> Void
    
    @State private var hoveredGender: GabrielGender?
    @State private var showGlow: Bool = false
    
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
                
                // 標題區域
                VStack(spacing: 16) {
                    Text("✨")
                        .font(.system(size: 60))
                        .scaleEffect(showGlow ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: showGlow)
                    
                    Text("歡迎來到 Rich Now AI")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("請選擇你的財務守護天使")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.bottom, 20)
                
                // 加百列選擇卡片
                HStack(spacing: 30) {
                    GabrielCard(
                        gender: .male,
                        isHovered: hoveredGender == .male,
                        isSelected: selectedGabriel == .male
                    ) {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                            selectedGabriel = .male
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            onSelect(.male)
                        }
                    }
                    .onTapGesture {
                        hoveredGender = .male
                    }
                    
                    GabrielCard(
                        gender: .female,
                        isHovered: hoveredGender == .female,
                        isSelected: selectedGabriel == .female
                    ) {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                            selectedGabriel = .female
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            onSelect(.female)
                        }
                    }
                    .onTapGesture {
                        hoveredGender = .female
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                // 底部提示
                Text("選擇後將為你量身打造專屬的理財體驗")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.bottom, 40)
            }
        }
        .onAppear {
            showGlow = true
        }
    }
}

struct GabrielCard: View {
    let gender: GabrielGender
    let isHovered: Bool
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var isAnimating = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 20) {
                // 頭像圓圈
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: isSelected ? [.white, .white.opacity(0.8)] : [.white.opacity(0.2), .white.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 140, height: 140)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 2)
                        )
                        .shadow(color: isSelected ? .white.opacity(0.5) : .clear, radius: 20, x: 0, y: 0)
                    
                    // 加百列頭像
                    GabrielAvatarView(gender: gender, size: 80, showFullBody: false)
                }
                .scaleEffect(isHovered || isSelected ? 1.1 : 1.0)
                .animation(.spring(response: 0.3), value: isHovered)
                .animation(.spring(response: 0.3), value: isSelected)
                
                // 名稱
                Text(gender.displayName)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                
                // 特質標籤
                VStack(spacing: 8) {
                    ForEach(gender.characteristics, id: \.self) { trait in
                        Text(trait)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(isSelected ? .white : .white.opacity(0.7))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(isSelected ? Color(hex: "#F59E0B")!.opacity(0.3) : Color.white.opacity(0.1))
                            )
                    }
                }
            }
            .padding(30)
            .frame(maxWidth: 200)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(
                        LinearGradient(
                            colors: isSelected ? 
                                [Color(hex: "#F59E0B")!.opacity(0.3), Color(hex: "#F59E0B")!.opacity(0.1)] :
                                [Color.white.opacity(0.1), Color.white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(
                                isSelected ? Color(hex: "#F59E0B")! : Color.white.opacity(0.2),
                                lineWidth: isSelected ? 3 : 1
                            )
                    )
            )
            .shadow(
                color: isSelected ? Color(hex: "#F59E0B")!.opacity(0.5) : .clear,
                radius: 20, x: 0, y: 10
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    GabrielSelectionView(selectedGabriel: .constant(nil)) { gender in
        print("Selected: \(gender)")
    }
}

