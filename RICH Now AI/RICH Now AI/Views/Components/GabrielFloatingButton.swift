//
//  GabrielFloatingButton.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/12/19.
//

import SwiftUI
import Combine

/// 加百列浮動按鈕 - 可以自由調整位置，始終可見
struct GabrielFloatingButton: View {
    @StateObject private var settingsManager = SettingsManager.shared
    @StateObject private var chatManager = ConversationManager.shared
    @AppStorage("selectedGabrielGender") private var selectedGabrielGender: String = "male"
    @AppStorage("gabrielFloatingButtonEnabled") private var isEnabled: Bool = true
    @AppStorage("gabrielFloatingButtonPositionX") private var positionX: Double = 0.85
    @AppStorage("gabrielFloatingButtonPositionY") private var positionY: Double = 0.85
    @AppStorage("gabrielFloatingButtonSize") private var buttonSize: Double = 70
    
    @State private var offset: CGSize = .zero
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false
    @State private var showChat = false
    @State private var showSettings = false
    @State private var pulseScale: CGFloat = 1.0
    @State private var isAnimating = false
    
    var body: some View {
        if isEnabled {
            GeometryReader { geometry in
                let screenWidth = geometry.size.width
                let screenHeight = geometry.size.height
                let finalPosition = calculateFinalPosition(
                    screenWidth: screenWidth,
                    screenHeight: screenHeight
                )
                
                ZStack {
                    // 浮動按鈕
                    Button(action: {
                        // 觸覺反饋
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                        
                        showChat = true
                    }) {
                        ZStack {
                            // 背景光暈
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [
                                            Color.safeHex("#1E3A8A", default: .blue).opacity(0.3),
                                            Color.safeHex("#312E81", default: .purple).opacity(0.2),
                                            Color.clear
                                        ],
                                        center: .center,
                                        startRadius: CGFloat(buttonSize * 0.5),
                                        endRadius: CGFloat(buttonSize * 0.8)
                                    )
                                )
                                .frame(width: CGFloat(buttonSize * 1.6), height: CGFloat(buttonSize * 1.6))
                                .blur(radius: 10)
                                .opacity(isAnimating ? 0.8 : 0.5)
                                .scaleEffect(pulseScale)
                            
                            // 加百列頭像
                            GabrielAvatarView(
                                gender: getGabrielGender(),
                                size: CGFloat(buttonSize),
                                showFullBody: false
                            )
                            
                            // 通知指示器（如果有新消息）
                            if hasNewMessages {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 16, height: 16)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: 2)
                                    )
                                    .offset(x: CGFloat(buttonSize * 0.35), y: -CGFloat(buttonSize * 0.35))
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .scaleEffect(isDragging ? 0.9 : 1.0)
                    .shadow(color: .black.opacity(0.2), radius: isDragging ? 5 : 10, x: 0, y: isDragging ? 2 : 5)
                    .offset(x: finalPosition.x + dragOffset.width, y: finalPosition.y + dragOffset.height)
                    .gesture(
                        DragGesture(minimumDistance: 10)
                            .onChanged { value in
                                if !isDragging {
                                    isDragging = true
                                }
                                dragOffset = value.translation
                            }
                            .onEnded { value in
                                // 計算最終位置
                                let newX = finalPosition.x + value.translation.width
                                let newY = finalPosition.y + value.translation.height
                                
                                // 確保按鈕不會超出屏幕邊界
                                let safeX = max(CGFloat(buttonSize * 0.5), min(newX, screenWidth - CGFloat(buttonSize * 0.5)))
                                let safeY = max(CGFloat(buttonSize * 0.5) + getSafeAreaTop(geometry), min(newY, screenHeight - CGFloat(buttonSize * 0.5) - getSafeAreaBottom(geometry)))
                                
                                // 保存位置（標準化到 0-1 範圍）
                                positionX = Double(safeX / screenWidth)
                                positionY = Double(safeY / screenHeight)
                                
                                // 重置拖動狀態
                                dragOffset = .zero
                                isDragging = false
                                
                                // 觸覺反饋
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                            }
                    )
                    .contextMenu {
                        Button(action: {
                            showSettings = true
                        }) {
                            Label("設定", systemImage: "gearshape.fill")
                        }
                        
                        Button(action: {
                            isEnabled = false
                        }) {
                            Label("隱藏", systemImage: "eye.slash.fill")
                        }
                    }
                }
                .frame(width: screenWidth, height: screenHeight, alignment: .topLeading)
                .onAppear {
                    startPulseAnimation()
                }
                .sheet(isPresented: $showChat) {
                    ChatView(
                        conversationManager: chatManager,
                        transactionParser: TransactionParser(),
                        openAIService: OpenAIService.shared
                    )
                }
                .sheet(isPresented: $showSettings) {
                    GabrielFloatingButtonSettingsView(
                        isEnabled: $isEnabled,
                        positionX: $positionX,
                        positionY: $positionY,
                        buttonSize: $buttonSize
                    )
                }
            }
        }
    }
    
    private func getGabrielGender() -> GabrielGender {
        return GabrielGender(rawValue: selectedGabrielGender) ?? .male
    }
    
    private func calculateFinalPosition(screenWidth: CGFloat, screenHeight: CGFloat) -> CGPoint {
        let x = screenWidth * CGFloat(positionX)
        let y = screenHeight * CGFloat(positionY)
        return CGPoint(x: x, y: y)
    }
    
    private func getSafeAreaTop(_ geometry: GeometryProxy) -> CGFloat {
        return geometry.safeAreaInsets.top
    }
    
    private func getSafeAreaBottom(_ geometry: GeometryProxy) -> CGFloat {
        return geometry.safeAreaInsets.bottom
    }
    
    private var hasNewMessages: Bool {
        // 檢查是否有未讀消息（可以從 ConversationManager 獲取）
        return false // 暫時返回 false，實際應用中需要實現消息計數
    }
    
    private func startPulseAnimation() {
        withAnimation(
            AnimationOptimizer.shared.canAnimate() ?
                Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true) :
                .linear(duration: 0)
        ) {
            pulseScale = 1.15
            isAnimating = true
        }
    }
}

/// 加百列浮動按鈕設定視圖
struct GabrielFloatingButtonSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var isEnabled: Bool
    @Binding var positionX: Double
    @Binding var positionY: Double
    @Binding var buttonSize: Double
    
    @State private var previewPositionX: Double = 0.85
    @State private var previewPositionY: Double = 0.85
    @State private var previewButtonSize: Double = 70
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Toggle("啟用浮動按鈕", isOn: $isEnabled)
                } header: {
                    Text("基本設定")
                } footer: {
                    Text("啟用後，加百列頭像將顯示為浮動按鈕，點擊即可快速開啟對話")
                }
                
                Section {
                    VStack(spacing: 16) {
                        // 按鈕大小
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("按鈕大小")
                                    .font(.subheadline)
                                Spacer()
                                Text("\(Int(buttonSize))")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Slider(value: $buttonSize, in: 50...120, step: 5) {
                                Text("按鈕大小")
                            } minimumValueLabel: {
                                Text("小")
                                    .font(.caption)
                            } maximumValueLabel: {
                                Text("大")
                                    .font(.caption)
                            }
                            .onChange(of: buttonSize) { _, newValue in
                                previewButtonSize = newValue
                            }
                        }
                        
                        // 位置調整說明
                        Text("拖動浮動按鈕可以調整位置，位置會自動保存")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                } header: {
                    Text("外觀設定")
                }
                
                Section {
                    Button(action: {
                        // 重置為預設位置
                        positionX = 0.85
                        positionY = 0.85
                        buttonSize = 70
                        previewPositionX = 0.85
                        previewPositionY = 0.85
                        previewButtonSize = 70
                    }) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("重置為預設值")
                        }
                    }
                    .foregroundColor(.blue)
                } header: {
                    Text("重設")
                }
            }
            .navigationTitle("浮動按鈕設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    GabrielFloatingButton()
        .frame(width: 400, height: 800)
        .background(Color.gray.opacity(0.1))
}

