//
//  LanguageSelectionView.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import SwiftUI

struct LanguageSelectionView: View {
    let onLanguageSelected: (LocalizationManager.AppLanguage) -> Void
    
    @EnvironmentObject var localizationManager: LocalizationManager
    @State private var selectedLanguage: LocalizationManager.AppLanguage?
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
            
            VStack(spacing: 40) {
                Spacer()
                
                // 標題區域
                VStack(spacing: 20) {
                    Text("🌍")
                        .font(.system(size: 80))
                        .scaleEffect(showAnimation ? 1.0 : 0.8)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showAnimation)
                    
                    VStack(spacing: 12) {
                        Text("Select Your Language")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text("Choose your preferred language for the app")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .opacity(showAnimation ? 1.0 : 0.0)
                    .offset(y: showAnimation ? 0 : 20)
                    .animation(.easeOut(duration: 0.8).delay(0.3), value: showAnimation)
                }
                
                // 語言選項
                VStack(spacing: 16) {
                    ForEach(LocalizationManager.AppLanguage.allCases, id: \.self) { language in
                        LanguageCard(
                            language: language,
                            isSelected: selectedLanguage == language,
                            onTap: {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    selectedLanguage = language
                                }
                            }
                        )
                        .opacity(showAnimation ? 1.0 : 0.0)
                        .offset(x: showAnimation ? 0 : -50)
                        .animation(.easeOut(duration: 0.6).delay(0.5 + Double(LocalizationManager.AppLanguage.allCases.firstIndex(of: language) ?? 0) * 0.1), value: showAnimation)
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // 繼續按鈕
                if selectedLanguage != nil {
                    Button(action: {
                        if let language = selectedLanguage {
                            localizationManager.changeLanguage(to: language)
                            onLanguageSelected(language)
                        }
                    }) {
                        HStack {
                            Text("Continue")
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

struct LanguageCard: View {
    let language: LocalizationManager.AppLanguage
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // 國旗圖示
                Text(language.flag)
                    .font(.system(size: 32))
                
                // 語言資訊
                VStack(alignment: .leading, spacing: 4) {
                    Text(language.displayName)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(getLanguageDescription(for: language))
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
    
    private func getLanguageDescription(for language: LocalizationManager.AppLanguage) -> String {
        switch language {
        case .english:
            return "English interface for global users"
        case .traditionalChinese:
            return "繁體中文介面，適合台灣用戶"
        case .simplifiedChinese:
            return "简体中文界面，适合大陆用户"
        }
    }
}

#Preview {
    LanguageSelectionView { language in
        print("Selected language: \(language)")
    }
}
