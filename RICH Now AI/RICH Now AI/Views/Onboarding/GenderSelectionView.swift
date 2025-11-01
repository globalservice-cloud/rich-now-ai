//
//  GenderSelectionView.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/27.
//

import SwiftUI

struct GenderSelectionView: View {
    @ObservedObject var state: OnboardingState
    @State private var selectedGender: UserGender?
    @State private var showAnimation = false
    
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
                
                // 加百列頭像
                if let gabriel = state.selectedGabriel {
                    GabrielAvatarView(gender: gabriel, size: 120, showFullBody: false)
                        .scaleEffect(showAnimation ? 1.0 : 0.8)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showAnimation)
                }
                
                // 標題區域
                VStack(spacing: 16) {
                    Text("請選擇您的性別")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("這將幫助我們為您提供更個性化的服務")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .opacity(showAnimation ? 1.0 : 0.0)
                .offset(y: showAnimation ? 0 : 20)
                .animation(.easeOut(duration: 0.8).delay(0.3), value: showAnimation)
                
                // 性別選項
                VStack(spacing: 16) {
                    ForEach(UserGender.allCases, id: \.self) { gender in
                        UserGenderCard(
                            gender: gender,
                            isSelected: selectedGender == gender,
                            onTap: {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    selectedGender = gender
                                }
                            }
                        )
                        .opacity(showAnimation ? 1.0 : 0.0)
                        .offset(x: showAnimation ? 0 : -50)
                        .animation(.easeOut(duration: 0.6).delay(0.5 + Double(UserGender.allCases.firstIndex(of: gender) ?? 0) * 0.1), value: showAnimation)
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // 繼續按鈕
                if selectedGender != nil {
                    Button(action: {
                        state.userGender = selectedGender
                        withAnimation {
                            state.nextStep()
                        }
                    }) {
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
        }
    }
    
    private func startAnimation() {
        withAnimation {
            showAnimation = true
        }
    }
}

struct UserGenderCard: View {
    let gender: UserGender
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 20) {
                // 性別圖示
                Text(gender.icon)
                    .font(.system(size: 32))
                
                // 性別資訊
                VStack(alignment: .leading, spacing: 4) {
                    Text(gender.displayName)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(getGenderDescription(for: gender))
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                // 選擇指示器
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color(hex: "#F59E0B"))
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
                    .fill(isSelected ? Color(hex: "#F59E0B")!.opacity(0.2) : Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(isSelected ? Color(hex: "#F59E0B")! : .clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func getGenderDescription(for gender: UserGender) -> String {
        switch gender {
        case .male:
            return "男性用戶"
        case .female:
            return "女性用戶"
        case .preferNotToSay:
            return "選擇不透露性別"
        }
    }
}

#Preview {
    GenderSelectionView(state: OnboardingState())
}
