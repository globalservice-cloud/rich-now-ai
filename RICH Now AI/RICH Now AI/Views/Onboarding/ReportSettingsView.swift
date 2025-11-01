//
//  ReportSettingsView.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/27.
//

import SwiftUI

struct ReportSettingsView: View {
    @ObservedObject var state: OnboardingState
    @State private var selectedFrequency: ReportFrequency = .monthly
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
            
            ScrollView {
                VStack(spacing: 30) {
                    // 頂部間距
                    Spacer()
                        .frame(height: 20)
                    
                    // 加百列頭像
                    if let gabriel = state.selectedGabriel {
                        GabrielAvatarView(gender: gabriel, size: 120, showFullBody: false)
                            .scaleEffect(showAnimation ? 1.0 : 0.8)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showAnimation)
                    }
                    
                    // 標題區域
                    VStack(spacing: 16) {
                        Text("財務報告設定")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text("請選擇您希望多久收到一次財務報告")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .opacity(showAnimation ? 1.0 : 0.0)
                    .offset(y: showAnimation ? 0 : 20)
                    .animation(.easeOut(duration: 0.8).delay(0.3), value: showAnimation)
                    
                    // 報告頻率選項
                    VStack(spacing: 12) {
                        ForEach(ReportFrequency.allCases, id: \.self) { frequency in
                            ReportFrequencyCard(
                                frequency: frequency,
                                isSelected: selectedFrequency == frequency,
                                onTap: {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                        selectedFrequency = frequency
                                    }
                                }
                            )
                            .opacity(showAnimation ? 1.0 : 0.0)
                            .offset(x: showAnimation ? 0 : -50)
                            .animation(.easeOut(duration: 0.6).delay(0.5 + Double(ReportFrequency.allCases.firstIndex(of: frequency) ?? 0) * 0.1), value: showAnimation)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // 底部間距
                    Spacer()
                        .frame(height: 40)
                    
                    // 繼續按鈕
                    Button(action: {
                        state.reportFrequency = selectedFrequency
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
            .scrollIndicators(.hidden)
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

struct ReportFrequencyCard: View {
    let frequency: ReportFrequency
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // 圖示
                Text(frequency.icon)
                    .font(.system(size: 24))
                
                // 頻率資訊
                VStack(alignment: .leading, spacing: 4) {
                    Text(frequency.displayName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(frequency.description)
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
}

#Preview {
    ReportSettingsView(state: OnboardingState())
}
