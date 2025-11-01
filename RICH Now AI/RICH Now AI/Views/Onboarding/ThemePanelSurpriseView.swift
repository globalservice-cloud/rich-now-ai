//
//  ThemePanelSurpriseView.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import SwiftUI

struct ThemePanelSurpriseView: View {
    let combinationType: String
    let userName: String
    var onApply: () -> Void
    var onSkip: () -> Void
    
    @State private var showSurprise = false
    @State private var showPanel = false
    @State private var showDescription = false
    @State private var showButtons = false
    
    var body: some View {
        ZStack {
            // 背景漸層
            LinearGradient(
                colors: [Color.safeHex("#1E3A8A", default: .blue), Color.safeHex("#312E81", default: .purple)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // 驚喜標題
                VStack(spacing: 20) {
                    Text("🎁")
                        .font(.system(size: 60))
                        .scaleEffect(showSurprise ? 1.2 : 1.0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.5).repeatForever(autoreverses: true), value: showSurprise)
                    
                    Text("還有一個驚喜！")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .opacity(showSurprise ? 1 : 0)
                        .offset(y: showSurprise ? 0 : 20)
                        .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.3), value: showSurprise)
                    
                    Text("\(userName)，我為你準備了專屬的 \(combinationType) 面板！")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .opacity(showSurprise ? 1 : 0)
                        .offset(y: showSurprise ? 0 : 20)
                        .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.5), value: showSurprise)
                }
                
                // 面板預覽
                if showPanel {
                    VGLAThemePanelPreview(
                        combinationType: combinationType,
                        userName: userName
                    )
                    .transition(.scale.combined(with: .opacity))
                }
                
                // 面板描述
                if showDescription {
                    ThemePanelDescription(combinationType: combinationType)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                // 操作按鈕
                if showButtons {
                    VStack(spacing: 16) {
                        Button(action: onApply) {
                            HStack {
                                Text("✨ 套用我的專屬面板")
                                    .font(.system(size: 18, weight: .semibold))
                                Image(systemName: "arrow.right")
                            }
                            .foregroundColor(Color(hex: "#1E3A8A"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(.white)
                            .cornerRadius(15)
                        }
                        
                        Button(action: onSkip) {
                            Text("稍後再說")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding(.horizontal, 40)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                Spacer()
            }
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        // 第一階段：驚喜標題
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation {
                showSurprise = true
            }
        }
        
        // 第二階段：面板預覽
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showPanel = true
            }
        }
        
        // 第三階段：描述
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation {
                showDescription = true
            }
        }
        
        // 第四階段：按鈕
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            withAnimation {
                showButtons = true
            }
        }
    }
}

// MARK: - VGLA Theme Panel Preview

struct VGLAThemePanelPreview: View {
    let combinationType: String
    let userName: String
    
    @State private var showContent = false
    
    var body: some View {
        VStack(spacing: 20) {
            // 面板標題
            Text("\(combinationType) 專屬面板")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            // 面板預覽
            ZStack {
                // 背景
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: getPanelColors(),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 280, height: 200)
                    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                
                // 面板內容
                VStack(spacing: 16) {
                    // 頭像和歡迎
                    HStack {
                        Circle()
                            .fill(.white.opacity(0.2))
                            .frame(width: 50, height: 50)
                            .overlay(
                                Text(String(userName.prefix(1)))
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("哈囉，\(userName)！")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                            Text("你的 \(combinationType) 專屬面板")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        Spacer()
                    }
                    
                    // 財務健康分數
                    VStack(spacing: 8) {
                        Text("財務健康分數")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                        
                        HStack {
                            Text("--")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                            Text("/ 100")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .opacity(showContent ? 1 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: showContent)
                    
                    // 快速操作
                    HStack(spacing: 12) {
                        ThemeQuickActionButton(icon: "message.fill", title: "對話")
                        ThemeQuickActionButton(icon: "plus.circle.fill", title: "記帳")
                        ThemeQuickActionButton(icon: "chart.bar.fill", title: "報表")
                    }
                    .opacity(showContent ? 1 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.5), value: showContent)
                }
                .padding(20)
            }
        }
        .onAppear {
            withAnimation {
                showContent = true
            }
        }
    }
    
    private func getPanelColors() -> [Color] {
        switch combinationType {
        case "VA":
            return [Color.safeHex("#F59E0B", default: .orange), Color.safeHex("#F97316", default: .orange)] // 橙金漸層
        case "VG":
            return [Color.safeHex("#EC4899", default: .pink), Color.safeHex("#F472B6", default: .pink)] // 粉紅漸層
        case "VL":
            return [Color.safeHex("#3B82F6", default: .blue), Color.safeHex("#60A5FA", default: .blue)] // 藍色漸層
        case "AV":
            return [Color.safeHex("#10B981", default: .green), Color.safeHex("#34D399", default: .green)] // 綠色漸層
        case "AG":
            return [Color.safeHex("#8B5CF6", default: .purple), Color.safeHex("#A78BFA", default: .purple)] // 紫色漸層
        case "AL":
            return [Color.safeHex("#EF4444", default: .red), Color.safeHex("#F87171", default: .red)] // 紅色漸層
        case "GV":
            return [Color.safeHex("#06B6D4", default: .cyan), Color.safeHex("#22D3EE", default: .cyan)] // 青色漸層
        case "GA":
            return [Color.safeHex("#F59E0B", default: .yellow), Color.safeHex("#FBBF24", default: .yellow)] // 金黃漸層
        case "GL":
            return [Color.safeHex("#84CC16", default: .green), Color.safeHex("#A3E635", default: .green)] // 青綠漸層
        case "LV":
            return [Color.safeHex("#6366F1", default: .indigo), Color.safeHex("#818CF8", default: .indigo)] // 靛藍漸層
        case "LA":
            return [Color.safeHex("#F97316", default: .orange), Color.safeHex("#FB923C", default: .orange)] // 橘色漸層
        case "LG":
            return [Color.safeHex("#14B8A6", default: .teal), Color.safeHex("#5EEAD4", default: .teal)] // 青藍漸層
        default:
            return [Color.safeHex("#1E3A8A", default: .blue), Color.safeHex("#312E81", default: .purple)] // 預設藍紫漸層
        }
    }
}

private struct ThemeQuickActionButton: View {
    let icon: String
    let title: String
    
    var body: some View {
        Button(action: {}) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.18))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// QuickActionButton 已移至 FinancialHealthDashboardView.swift

// MARK: - Theme Panel Description

struct ThemePanelDescription: View {
    let combinationType: String
    
    var body: some View {
        VStack(spacing: 16) {
            Text("專為你的 \(combinationType) 特質設計")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            Text(getPanelDescription())
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
            
            // 特色標籤
            HStack(spacing: 12) {
                ForEach(getPanelFeatures(), id: \.self) { feature in
                    Text(feature)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(.white.opacity(0.2))
                        )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    private func getPanelDescription() -> String {
        switch combinationType {
        case "VA":
            return "結合願景思考與行動實踐，適合喜歡有夢想並快速實現的你。面板採用溫暖的橙金配色，激發創造力和執行力。"
        case "VG":
            return "融合願景思考與感性關懷，適合喜歡幫助他人實現夢想的你。面板採用溫馨的粉紅配色，營造溫暖親切的氛圍。"
        case "VL":
            return "結合願景思考與邏輯分析，適合喜歡有遠見並系統規劃的你。面板採用專業的藍色配色，體現理性與智慧。"
        case "AV":
            return "融合行動實踐與願景思考，適合喜歡快速行動並有遠大目標的你。面板採用活力的綠色配色，展現行動力與成長。"
        case "AG":
            return "結合行動實踐與感性關懷，適合喜歡快速行動並關心他人的你。面板採用神秘的紫色配色，體現行動與關懷的平衡。"
        case "AL":
            return "融合行動實踐與邏輯分析，適合喜歡快速行動並有系統規劃的你。面板採用熱情的紅色配色，展現行動力與效率。"
        case "GV":
            return "結合感性關懷與願景思考，適合喜歡幫助他人並有美好願景的你。面板採用清新的青色配色，體現關懷與夢想。"
        case "GA":
            return "融合感性關懷與行動實踐，適合喜歡幫助他人並快速執行的你。面板採用溫暖的金黃配色，展現關懷與行動力。"
        case "GL":
            return "結合感性關懷與邏輯分析，適合喜歡幫助他人並有理性思考的你。面板採用生機的青綠配色，體現關懷與智慧。"
        case "LV":
            return "融合邏輯分析與願景思考，適合喜歡系統思考並有遠大目標的你。面板採用深邃的靛藍配色，體現理性與遠見。"
        case "LA":
            return "結合邏輯分析與行動實踐，適合喜歡系統思考並快速執行的你。面板採用活力的橘色配色，展現邏輯與效率。"
        case "LG":
            return "融合邏輯分析與感性關懷，適合喜歡系統思考並關心他人的你。面板採用清新的青藍配色，體現理性與關懷。"
        default:
            return "專為你的獨特思考模式設計，展現個性化的財務管理體驗。"
        }
    }
    
    private func getPanelFeatures() -> [String] {
        switch combinationType {
        case "VA":
            return ["✨ 創意激發", "⚡ 快速執行", "🎯 目標導向"]
        case "VG":
            return ["💝 溫暖關懷", "🌟 願景引導", "🤝 團隊合作"]
        case "VL":
            return ["🧠 深度思考", "📊 系統分析", "🎯 策略規劃"]
        case "AV":
            return ["⚡ 行動力強", "🌟 願景清晰", "🚀 快速成長"]
        case "AG":
            return ["⚡ 快速行動", "💝 關懷他人", "🤝 團隊協作"]
        case "AL":
            return ["⚡ 高效執行", "🧠 邏輯清晰", "📈 成果導向"]
        case "GV":
            return ["💝 溫暖關懷", "🌟 願景美好", "🤝 助人為樂"]
        case "GA":
            return ["💝 關懷他人", "⚡ 快速行動", "🤝 團隊合作"]
        case "GL":
            return ["💝 溫暖關懷", "🧠 理性思考", "📊 系統規劃"]
        case "LV":
            return ["🧠 深度分析", "🌟 遠大願景", "📊 系統規劃"]
        case "LA":
            return ["🧠 邏輯清晰", "⚡ 高效執行", "📈 成果導向"]
        case "LG":
            return ["🧠 理性思考", "💝 關懷他人", "📊 系統規劃"]
        default:
            return ["✨ 個性化", "🎨 專屬設計", "💎 獨特體驗"]
        }
    }
}

#Preview {
    ThemePanelSurpriseView(
        combinationType: "VA",
        userName: "志明",
        onApply: { print("Apply panel") },
        onSkip: { print("Skip panel") }
    )
}
